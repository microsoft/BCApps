# Helpers

Stateless utility codeunits for JSON parsing, hashing, base64 validation, and basic math used throughout the Shopify Connector.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyJsonHelper.Codeunit.al` (most used), `Codeunits/ShpfyHash.Codeunit.al`
- **Key patterns**: dot-separated token paths for nested JSON traversal, overloaded procedures accepting both JsonToken and JsonObject

## Structure

- `Codeunits/ShpfyJsonHelper.Codeunit.al` -- JSON navigation and typed value extraction (~1050 lines)
- `Codeunits/ShpfyHash.Codeunit.al` -- custom hash computation for text, streams, and item/variant images
- `Codeunits/ShpfyBase64.Codeunit.al` -- regex-based base64 string validation
- `Codeunits/ShpfyMath.Codeunit.al` -- Max(DateTime) and Min(BigInteger) helpers

## Key concepts

- All codeunits are `Access = Internal`. ShpfyJsonHelper and ShpfyMath are `SingleInstance = true`.
- **Token paths** use dot-delimited strings (e.g., `"order.customer.name"`) to walk nested JSON objects. Every `GetValueAs*` method splits on `.` and walks each segment via `JToken.AsObject().Get()`.
- ShpfyJsonHelper provides `GetValueAs{Text,Decimal,BigInteger,Boolean,Date,DateTime,...}` families, each with JToken and JObject overloads. MaxLength variants use `CopyStr` to truncate.
- `GetValueIntoField` and `GetValueIntoFieldWithValidation` map JSON values directly onto record fields via RecordRef/FieldRef, dispatching by `FieldType`. The validation variant calls `FieldRef.Validate()` to trigger AL field-level triggers.
- `GetValueAsDate` accounts for timezone offsets using the company's post code time zone, falling back to raw UTC conversion.
