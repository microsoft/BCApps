# Shopify Connector -- GraphQL module

Type-safe, enum-driven abstraction layer over the Shopify Admin GraphQL API. Contains ~145 codeunits, each implementing the `Shpfy IGraphQL` interface to provide a specific query or mutation with its expected cost.

## Quick reference

- **Tech stack**: AL interface + enum pattern (polymorphic dispatch)
- **Entry point(s)**: `ShpfyGraphQLQueries.Codeunit.al` (query resolver), `ShpfyGraphQLType.Enum.al` (dispatch enum)
- **Key patterns**: Interface-based polymorphism via AL enum `implements`, template parameter substitution with `{{placeholder}}` syntax, SingleInstance rate limiter

## Structure

```
GraphQL/
  Interfaces/
    ShpfyIGraphQL.Interface.al         -- 2-method contract: GetGraphQL(), GetExpectedCost()
  Enums/
    ShpfyGraphQLType.Enum.al           -- ~147 values, each mapping to an implementation codeunit
  Codeunits/
    ShpfyGraphQLQueries.Codeunit.al    -- SingleInstance query resolver with event hooks
    ShpfyGraphQLRateLimit.Codeunit.al  -- SingleInstance token bucket rate limiter
    ShpfyGQL*.Codeunit.al              -- ~143 query/mutation implementations
```

## Documentation

- [docs/architecture.md](docs/architecture.md) -- Interface contract, dispatch pattern, rate limiting, naming conventions

## Key concepts

- Each Shopify API operation is a separate codeunit implementing `Shpfy IGraphQL`
- The `Shpfy GraphQL Type` enum maps enum values to implementation codeunits via AL's `implements` keyword
- `ShpfyGraphQLQueries` resolves enum -> interface -> query text, substitutes `{{parameters}}`, and returns the expected cost
- Rate limiting uses a token bucket model based on Shopify's `extensions.cost.throttleStatus` response
- Pagination follows a `Get*` / `GetNext*` codeunit pair pattern using cursor-based pagination
- 5 internal events on `ShpfyGraphQLQueries` allow intercepting query resolution, parameter substitution, and interface selection
