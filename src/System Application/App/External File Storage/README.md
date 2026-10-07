# External File Storage Module for Business Central
Provides an API that lets you connect external cloud storage accounts to Business Central, allowing users to access files stored outside of Business Central.

## Main Components

### File Account
A file account holds the information needed to access an external storage service from Business Central.

## Optional destination context

Connectors may implement `External File Storage Context` without changing the original connector interface. `External File Storage.GetDestinationContext` returns a fingerprint of the provider's versioned, secret-free descriptor and a persistent account change generation. Providers must describe every destination-affecting setting and interpretation, and must not authenticate or make network calls.

`LockAccount = true` is only for a short local transaction. Never hold that lock across HTTP. The capability describes a configured namespace at a point in time; it does **not** provide an immutable remote object, resolved transport, conditional-delete operation, or a remote-deletion concurrency fence.

`File Scenario.IsSpecificFileAccountAssigned` checks only an exact scenario-to-account-ID/connector assignment without account enumeration or default fallback. Its optional `LockAssignment` retains update isolation through the caller's short local transaction; it must not be used around a network transfer. Account availability and destination context require separate validation. The internal scenario table remains encapsulated.
