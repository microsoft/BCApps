# Introduction
"Permissions Mock" can be used to mock the permisison sets assignment of the user.

A separate single-instance default test handler starts Permissions Mock before each test procedure or data-driven case when it is not already active. It clears assignments and stops only the scopes it started, including after failures. Its ownership persists across callbacks so skipped tests are cleaned up before the next test or when the codeunit finishes.

The handler runs on both native and legacy test paths without identifying the caller. An already active mock remains owned by its caller, preserving assignments made by AL Test Tool setup subscribers and avoiding duplicate initialization or disposal. Calling `Start()` while mocking is already active preserves existing assignments; use `ClearAssignments()` to reset them explicitly.

`Start()` opens a scope without constructing the permission helper. The first call to `Set()`, `Assign()`, `SetExactPermissionSet()`, or `ClearAssignments()` initializes it. Tests that do not use these operations do not construct or dispose a helper, including when the legacy runner starts and stops the scope through `Codeunit.Run`. `TestPermissions = Disabled` does not prevent explicit use of Permissions Mock.

Check the reference documentation at [https://microsoft.github.io/BCApps](https://microsoft.github.io/BCApps/reference/permissions-mock/Module/Permissions-Mock.html).
