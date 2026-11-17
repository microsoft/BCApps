# Introduction
"Permissions Mock" can be used to mock the permisison sets assignment of the user.

On platform 30, Permissions Mock registers a default test handler. It starts automatically before each test procedure or data-driven case and clears assignments between tests, including after failures. Skipped tests are cleaned up before the next test or when the codeunit finishes.

The native test runner uses this handler. When AL Test Tool starts Permissions Mock through its legacy lifecycle, the handler defers to that runner, preserving assignments made by its setup subscribers and avoiding duplicate initialization or disposal. Calling `Start()` while mocking is already active preserves existing assignments; use `ClearAssignments()` to reset them explicitly.

Check the reference documentation at [https://microsoft.github.io/BCApps](https://microsoft.github.io/BCApps/reference/permissions-mock/Module/Permissions-Mock.html).
