# Introduction
"Permissions Mock" can be used to mock the permisison sets assignment of the user.

When installed, the app initializes its helper before each native test procedure and data-driven case if mocking is not already active. It disposes only helpers started by this automatic lifecycle, including during normal failure or codeunit unwinding after skipped tests. Helpers owned by the regular Test Runner or explicit callers are not stopped by the automatic lifecycle. Explicit `Start`, `Stop`, and the legacy `OnRun` toggle retain control of their own lifecycle. The platform does not allow nested test-codeunit execution in the same session. No persistent user or company permission assignments are changed.

Check the reference documentation at [https://microsoft.github.io/BCApps](https://microsoft.github.io/BCApps/reference/permissions-mock/Module/Permissions-Mock.html).
