#!/usr/bin/env julia
# Regenerate typed Julia XML-model modules from IEC 62325 XSD files.
#
# Run from the package root: `julia --project gen/regenerate_xml_models.jl`.
#
# Reads the XSD files in `spec/xsd/` and emits one Julia module per XSD
# under `src/xml_models/`. Each module contains:
#
#   - Type aliases for every `<xs:simpleType>` (mapped to Int64, Float64,
#     String, or DateTime based on the XSD `base` attribute; codelist
#     restrictions become `String`).
#   - `Base.@kwdef mutable struct` for every `<xs:complexType>`. Element
#     names containing `.` are converted to `_` to be valid Julia.
#     `minOccurs=0` becomes `Union{Nothing,T}`; `maxOccurs="unbounded"`
#     becomes `Vector{T}`. Complex types with `<xs:simpleContent>` get a
#     `value::T` plus one field per attribute.
#   - A `_parse(::Type{T}, ::EzXML.Node)` method per type that walks the
#     XML DOM and fills fields. Element-name comparison is
#     namespace-agnostic (uses `nodename`, not XPath).
#   - A `parse_document(xml::String)::RootType` entry point that
#     dispatches on the schema's root element.
#
# Output is committed to `src/xml_models/`. Users import via
# `using ENTSOE.XmlModels.Publication_v7_4`. The hand-written DOM
# walkers in `src/conveniences/parsing.jl` remain available as a
# fallback for documents not yet covered by the typed-model layer.

using EzXML: EzXML, readxml, parsexml, root, elements, nodename, nodecontent
using Dates: Dates

# EzXML attribute lookup is dict-style: `haskey(node, "name")` /
# `node["name"]`. Give it a friendlier alias so the generator reads
# naturally — and so the emitted parser code uses the same name.
hasattribute(node, name) = haskey(node, name)

const XS = "http://www.w3.org/2001/XMLSchema"
const SPEC_XSD_DIR = joinpath(dirname(@__DIR__), "spec", "xsd")
const OUTPUT_DIR = joinpath(dirname(@__DIR__), "src", "xml_models")

# ---------------------------------------------------------------------------
# XSD → Julia type mapping for the primitives we care about. Anything not
# in this table falls back to `String`.

const PRIMITIVE_MAP = Dict(
    "xs:string"  => "String",
    "xs:integer" => "Int64",
    "xs:int"     => "Int64",
    "xs:long"    => "Int64",
    "xs:short"   => "Int16",
    "xs:byte"    => "Int8",
    "xs:decimal" => "Float64",
    "xs:double"  => "Float64",
    "xs:float"   => "Float32",
    "xs:boolean" => "Bool",
    "xs:dateTime"=> "DateTime",
    "xs:date"    => "Date",
    "xs:time"    => "String",   # naive Time round-trip is lossy; keep raw
    "xs:duration"=> "String",   # ISO 8601 (e.g. "PT15M") — kept raw
    "xs:NMTOKEN" => "String",
    "xs:anyURI"  => "String",
    "xs:token"   => "String",
)

# Julia keywords + Base symbols that can't appear as field names.
const JULIA_RESERVED = Set([
    "begin", "function", "if", "else", "elseif", "end", "for", "while",
    "do", "let", "return", "type", "struct", "mutable", "abstract",
    "import", "using", "export", "module", "const", "global", "local",
    "macro", "where", "in", "true", "false", "nothing", "missing",
])

# ---------------------------------------------------------------------------
# XSD parsing helpers — namespace-agnostic name matching since the
# schemas use the `xs:` prefix but the `xsd:` prefix appears too.

_local_name(node) = let n = nodename(node); occursin(":", n) ? split(n, ":")[end] : n; end

_xs_children(parent, name) =
    [c for c in elements(parent) if _local_name(c) == name]

_xs_first_child(parent, name) =
    let r = nothing
        for c in elements(parent)
            _local_name(c) == name && (r = c; break)
        end
        r
    end

# Strip the namespace prefix from a type reference. "ecl:CodingSchemeTypeList"
# → ("ecl", "CodingSchemeTypeList"); "xs:string" → ("xs", "string").
function split_typeref(s)
    parts = split(s, ":")
    length(parts) == 2 ? (parts[1], parts[2]) : ("", parts[1])
end

# Sanitise an XSD element / type name into a valid Julia identifier.
# `price.amount` → `price_amount`; `PartyID_String-base` → `PartyID_String_base`;
# reserved words get a trailing underscore.
function sanitize_field(name)
    safe = replace(String(name), '.' => '_', '-' => '_')
    safe in JULIA_RESERVED && (safe *= "_")
    return safe
end

# Same as `sanitize_field` but for use on type names (which appear both
# in declarations and in type-expression positions). Symmetric with the
# field one — kept as a separate function for readability.
sanitize_type(name) = sanitize_field(name)

# ---------------------------------------------------------------------------
# Resolve XSD types to Julia type expressions. `defined_complex` and
# `defined_simple` are the types declared in the *current* schema; cross-
# schema references fall back to `String` for the v1 generator (the
# codelists schema is huge and we don't want to enumerate it yet).

# A type prefix is "local" when it's missing or refers to the XML-Schema
# namespace itself. Any other prefix (`ecl:`, `cl:`, …) is a cross-
# schema reference whose target lives in a different file; we treat
# those as `String` rather than silently aliasing to a same-named local
# definition (which causes `const Foo = Foo` self-references).
const _XSD_PREFIXES = Set(["", "xs", "xsd"])

_is_local_ref(prefix) = prefix in _XSD_PREFIXES

# `defined_complex` and `defined_simple` carry the local-schema type
# inventory; `simple_julia` resolves each `<xs:simpleType>` to its
# underlying Julia primitive (`ID_String` → `"String"`,
# `Position_Integer` → `"Int64"`, etc.).
#
# We inline simple-type aliases at emission time — the generated struct
# fields use the primitive directly (`mRID::String`) instead of the
# wrapper alias (`mRID::ID_String`). This deduplicates ~3 500 `const`
# declarations across the 198 modules and removes a layer of
# indirection users would have to follow.
function julia_type(typeref, defined_complex, defined_simple, simple_julia)
    isempty(typeref) && return "String"
    haskey(PRIMITIVE_MAP, typeref) && return PRIMITIVE_MAP[typeref]
    prefix, local_name = split_typeref(typeref)
    _is_local_ref(prefix) || return "String"
    safe = sanitize_type(local_name)
    safe in defined_complex && return safe
    # Pure simple-type alias → inline the primitive.
    safe in defined_simple  && return get(simple_julia, safe, "String")
    return "String"
end

# ---------------------------------------------------------------------------
# Walk a single XSD and produce the Julia module text.

struct XsdField
    name::String           # Julia identifier
    xml_name::String       # original XSD name (for matching during parse)
    type::String           # Julia type expression (e.g. "Float64")
    optional::Bool         # true ⇒ Union{Nothing, T}
    repeated::Bool         # true ⇒ Vector{T}, default Vector{T}()
    is_attribute::Bool     # true ⇒ pulled from a `node["attr"]` instead of children
end

# Resolve a <xs:simpleType> to its underlying Julia primitive. For a
# `<xs:restriction base="X">` we follow `X`; for a codelist reference
# (e.g. `ecl:MessageTypeList`) we yield `String`.
function resolve_simpletype(st, defined_simple)
    restr = _xs_first_child(st, "restriction")
    restr === nothing && return "String"
    base = hasattribute(restr, "base") ? restr["base"] : ""
    haskey(PRIMITIVE_MAP, base) && return PRIMITIVE_MAP[base]
    prefix, local_base = split_typeref(base)
    # Cross-schema reference (`cl:UnitSymbol`, `ecl:MessageTypeList`, …)
    # collapses to `String` regardless of whether the local schema
    # happens to also define a same-named type.
    _is_local_ref(prefix) || return "String"
    local_base in defined_simple && return sanitize_type(local_base)
    return "String"
end

# Build the field descriptor list for a <xs:complexType>.
function complextype_fields(ct, defined_complex, defined_simple, simple_julia)
    fields = XsdField[]

    # Case A: simpleContent → the type carries a textual value plus
    # attributes. Emit a `value::T` field followed by one field per attr.
    sc = _xs_first_child(ct, "simpleContent")
    if sc !== nothing
        ext = _xs_first_child(sc, "extension")
        if ext !== nothing
            base_ref = hasattribute(ext, "base") ? ext["base"] : "xs:string"
            push!(fields, XsdField(
                "value", "", julia_type(base_ref, defined_complex, defined_simple, simple_julia),
                false, false, false,
            ))
            for attr in _xs_children(ext, "attribute")
                hasattribute(attr, "name") || continue
                attr_name = String(attr["name"])
                attr_type = hasattribute(attr, "type") ? attr["type"] : "xs:string"
                required = hasattribute(attr, "use") && attr["use"] == "required"
                push!(fields, XsdField(
                    sanitize_field(attr_name), attr_name,
                    julia_type(attr_type, defined_complex, defined_simple, simple_julia),
                    !required, false, true,
                ))
            end
        end
        return fields
    end

    # Case B: sequence/all/choice → one Julia field per child element.
    for container_name in ("sequence", "all", "choice")
        container = _xs_first_child(ct, container_name)
        container === nothing && continue
        for el in _xs_children(container, "element")
            hasattribute(el, "name") || continue
            el_name = String(el["name"])
            el_type = hasattribute(el, "type") ? el["type"] : "xs:string"
            jtype = julia_type(el_type, defined_complex, defined_simple, simple_julia)
            min_occ = hasattribute(el, "minOccurs") ?
                parse(Int, el["minOccurs"]) : 1
            max_occ = hasattribute(el, "maxOccurs") ?
                (el["maxOccurs"] == "unbounded" ? typemax(Int) :
                    parse(Int, el["maxOccurs"])) : 1
            push!(fields, XsdField(
                sanitize_field(el_name), el_name, jtype,
                min_occ == 0 && max_occ <= 1,    # optional
                max_occ > 1,                      # repeated
                false,
            ))
        end
    end
    return fields
end

function julia_field_decl(f::XsdField, simple_julia::Dict{String, String})
    if f.repeated
        return "$(f.name)::Vector{$(f.type)} = $(f.type)[]"
    elseif f.optional
        return "$(f.name)::Union{Nothing, $(f.type)} = nothing"
    else
        # Resolve simple-type aliases to their underlying primitive so we
        # can pick a default that works (e.g. `ESMP_DateTime` aliases to
        # `DateTime` — but `DateTime()` is not a method, we need
        # `DateTime(1970)`).
        effective = get(simple_julia, f.type, f.type)
        default = if effective == "String"; "\"\""
        elseif effective in ("Int64", "Int16", "Int8", "Int"); "0"
        elseif effective in ("Float64", "Float32"); "0.0"
        elseif effective == "Bool"; "false"
        elseif effective == "DateTime"; "DateTime(1970)"
        elseif effective == "Date"; "Date(1970)"
        else; "$(f.type)()"   # struct → has a generated kwdef constructor
        end
        return "$(f.name)::$(f.type) = $(default)"
    end
end

# Emit the per-type parser function. Walks <xs:element> children (and
# attributes for simpleContent types), populates the struct.
function emit_parser(io::IO, type_name::AbstractString, fields::Vector{XsdField},
        defined_complex::Set{String}, defined_simple::Set{String},
        simple_julia::Dict{String, String})
    safe = sanitize_type(type_name)
    println(io, "function _parse(::Type{$(safe)}, n::EzXML.Node)")
    println(io, "    out = $(safe)()")
    # Attribute fields first. Resolve type aliases to their underlying
    # primitive before picking the parse call.
    for f in fields
        f.is_attribute || continue
        prim = julia_primitive_for(f.type, defined_simple, simple_julia)
        println(io, "    if hasattribute(n, \"$(f.xml_name)\")")
        println(io, "        out.$(f.name) = $(parse_call(prim))(n[\"$(f.xml_name)\"])")
        println(io, "    end")
    end
    # Value field (from simpleContent) — populated from text content.
    for f in fields
        f.is_attribute && continue
        f.name == "value" && f.xml_name == "" || continue
        prim = julia_primitive_for(f.type, defined_simple, simple_julia)
        println(io, "    out.value = $(parse_call(prim))(strip(nodecontent(n)))")
    end
    # Element fields.
    has_elements = any(!f.is_attribute && f.xml_name != "" for f in fields)
    if has_elements
        println(io, "    for c in elements(n)")
        println(io, "        local nm = nodename(c)")
        first = true
        for f in fields
            (f.is_attribute || f.xml_name == "") && continue
            kw = first ? "if" : "elseif"
            println(io, "        $(kw) nm == \"$(f.xml_name)\"")
            if f.repeated
                println(io, "            push!(out.$(f.name), $(decode_call(f.type, defined_complex, defined_simple, simple_julia)))")
            elseif f.type in defined_complex
                println(io, "            out.$(f.name) = _parse($(f.type), c)")
            else
                println(io, "            out.$(f.name) = $(parse_call(julia_primitive_for(f.type, defined_simple, simple_julia)))(strip(nodecontent(c)))")
            end
            first = false
        end
        println(io, "        end")
        println(io, "    end")
    end
    println(io, "    return out")
    println(io, "end")
    println(io)
end

# `parse_call(julia_type)` returns a Julia expression that decodes a
# String-y value into that type. Always wrapped in `(...)` so that
# `parse_call(t)(arg)` parses as a function application (closures without
# parens are interpreted as lambda bodies — `x -> x(arg)` is wrong).
function parse_call(t)
    t == "String"   && return "String"
    t == "Float64"  && return "(x -> parse(Float64, x))"
    t == "Float32"  && return "(x -> parse(Float32, x))"
    t == "Int64"    && return "(x -> parse(Int64, x))"
    t == "Int16"    && return "(x -> parse(Int16, x))"
    t == "Int8"     && return "(x -> parse(Int8, x))"
    t == "Int"      && return "(x -> parse(Int, x))"
    t == "Bool"     && return "(x -> parse(Bool, x))"
    t == "DateTime" && return "(x -> DateTime(replace(String(x), \"Z\" => \"\")))"
    t == "Date"     && return "(x -> Date(String(x)))"
    # For simple-type aliases (e.g. ID_String → String) the alias parses
    # like the underlying primitive — the caller resolves that before
    # invoking parse_call.
    return "(x -> String(x))"
end

function julia_primitive_for(t, defined_simple, simple_julia)
    t in keys(simple_julia) && return simple_julia[t]
    return t
end

function decode_call(t, defined_complex, defined_simple, simple_julia)
    if t in defined_complex
        return "_parse($(t), c)"
    else
        prim = julia_primitive_for(t, defined_simple, simple_julia)
        return "$(parse_call(prim))(strip(nodecontent(c)))"
    end
end

# ---------------------------------------------------------------------------
# Top-level: process one XSD file and emit one Julia source file.

function generate(xsd_path::AbstractString, out_dir::AbstractString)
    doc = readxml(xsd_path)
    schema = root(doc)
    target_ns = hasattribute(schema, "targetNamespace") ?
        schema["targetNamespace"] : ""

    # Pass 1: collect names so cross-references resolve.
    simple_types = _xs_children(schema, "simpleType")
    complex_types = _xs_children(schema, "complexType")
    defined_simple = Set(String[s["name"] for s in simple_types if hasattribute(s, "name")])
    defined_complex = Set(String[c["name"] for c in complex_types if hasattribute(c, "name")])

    # Pass 1b: resolve simpleType → Julia primitive. Keys are the
    # *sanitized* type names (hyphens replaced with underscores) so
    # downstream lookups via `f.type` (also sanitized) line up.
    simple_julia = Dict{String, String}()
    for st in simple_types
        hasattribute(st, "name") || continue
        simple_julia[sanitize_type(String(st["name"]))] =
            resolve_simpletype(st, defined_simple)
    end

    # Pick the module name from the file: "iec62325-451-3-publication_v7_4.xsd"
    # → "Publication_v7_4". Drop the IEC prefix + family digits.
    base = splitext(basename(xsd_path))[1]
    # File "iec62325-451-3-publication_v7_4.xsd" → module "Publication_v7_4".
    # Also handles `iec62325-451-6a-...` and `iec62325-451-n-...` where
    # the third segment isn't purely numeric. We capitalise the family
    # name's first letter, then sanitise to remove any remaining
    # hyphens (a few XSD filenames have them in the family portion,
    # e.g. `balancing-4-0`).
    module_name = let m = match(r"iec62325-[^-]+-[^-]+-(.+)", base)
        tail = m === nothing ? base : String(m.captures[1])
        sanitize_type(uppercase(tail[1:1]) * tail[2:end])
    end

    # Root element — the one <xs:element> at schema level whose type is
    # a complex type defined in this schema.
    root_el = nothing
    for el in _xs_children(schema, "element")
        hasattribute(el, "type") || continue
        _, lt = split_typeref(el["type"])
        if lt in defined_complex
            root_el = el
            break
        end
    end
    root_type = if root_el === nothing
        first(defined_complex)
    else
        _, lt = split_typeref(root_el["type"])
        lt
    end

    out_path = joinpath(out_dir, "$(module_name).jl")

    io = IOBuffer()
    println(io, "# Auto-generated from $(basename(xsd_path)) — DO NOT EDIT")
    println(io, "# Re-run `gen/regenerate_xml_models.jl` to regenerate.")
    println(io, "# Source schema namespace: $(target_ns)")
    println(io)
    println(io, "module $(module_name)")
    println(io)
    println(io, "using Dates: Dates, DateTime, Date")
    println(io, "using EzXML: EzXML, parsexml, root, elements, nodename, nodecontent")
    println(io)
    println(io, "# EzXML treats attribute lookup as dict-style — `node[\"x\"]` /")
    println(io, "# `haskey(node, \"x\")`. Alias `hasattribute` for readability.")
    println(io, "hasattribute(node, name) = haskey(node, name)")
    println(io)
    println(io, "# ---------------------------------------------------------------------------")
    println(io, "# Complex types (mutable kwdef structs, all fields with safe defaults).")
    println(io, "#")
    println(io, "# Simple-type aliases (e.g. `ID_String`, `Position_Integer`) are inlined")
    println(io, "# to their underlying primitives (`String`, `Int64`, `Float64`, `DateTime`)")
    println(io, "# at codegen time — saves ~3 500 lines of `const X = String` boilerplate")
    println(io, "# across the schema family and removes a layer of indirection. The")
    println(io, "# original XSD simpleType names live in the source schema for reference.")
    println(io)

    # Topologically sort complex types so dependencies come first.
    # Build a dependency graph: T depends on any other complex-type T'
    # that appears as a field type.
    type_deps = Dict{String, Set{String}}()
    type_fields = Dict{String, Vector{XsdField}}()
    for ct in complex_types
        hasattribute(ct, "name") || continue
        name = String(ct["name"])
        fields = complextype_fields(ct, defined_complex, defined_simple, simple_julia)
        type_fields[name] = fields
        type_deps[name] = Set(f.type for f in fields if f.type in defined_complex)
    end

    sorted = String[]
    visited = Set{String}()
    function visit(t)
        t in visited && return
        push!(visited, t)
        for dep in get(type_deps, t, Set{String}())
            visit(dep)
        end
        push!(sorted, t)
    end
    for t in keys(type_fields)
        visit(t)
    end

    for name in sorted
        fields = type_fields[name]
        println(io, "Base.@kwdef mutable struct $(sanitize_type(name))")
        for f in fields
            println(io, "    $(julia_field_decl(f, simple_julia))")
        end
        println(io, "end")
        println(io)
    end

    println(io, "# ---------------------------------------------------------------------------")
    println(io, "# Parsers — walk an EzXML node and fill the corresponding struct.")
    println(io)

    for name in sorted
        emit_parser(io, name, type_fields[name], defined_complex, defined_simple, simple_julia)
    end

    println(io, "# ---------------------------------------------------------------------------")
    println(io, "# Entry point — parse the XML body and return the root document.")
    println(io)
    println(io, "function parse_document(xml::AbstractString)::$(sanitize_type(root_type))")
    println(io, "    return _parse($(sanitize_type(root_type)), root(parsexml(xml)))")
    println(io, "end")
    println(io)
    println(io, "end  # module $(module_name)")

    mkpath(out_dir)
    open(out_path, "w") do f
        write(f, String(take!(io)))
    end
    return out_path
end

# ---------------------------------------------------------------------------
# CLI: walk every XSD in `spec/xsd/` (or a single file if passed as arg).

function main(argv = ARGS)
    files = isempty(argv) ? filter(f -> endswith(f, ".xsd") &&
            !startswith(basename(f), "urn-"),
        readdir(SPEC_XSD_DIR; join = true)) : argv
    isempty(files) && (println("No XSD files found in $(SPEC_XSD_DIR)"); return)

    @info "Regenerating XML models" count = length(files) output = OUTPUT_DIR
    for path in files
        out = generate(path, OUTPUT_DIR)
        @info "  → $(basename(out))"
    end
    @info "Done. $(length(files)) module(s) emitted under $(OUTPUT_DIR)."
end

main(ARGS)
