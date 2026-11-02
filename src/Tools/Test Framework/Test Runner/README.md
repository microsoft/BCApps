Test Runner is used to run the automated tests.

There are two ways to run tests:
- In the UI, open the AL Test Tool page and manually run the tests.
- In the Console, which is suitable for running in CI/CD pipeline. To set this up you must use the ALTestRunner.psm1 file in this module.

When this app is installed, its `DefaultTestHandler` implementation clears the session application area filter before each native test procedure and data-driven test case. This gives direct platform test execution the same unrestricted application area visibility as the regular Test Runner without invoking its unrelated legacy resets. Tests can still set a restrictive application area filter within their own procedure or case. Company application area setup is not changed.

Do mot modify or extend this module. In the future we will move test execution to a platform-based API.

Check the reference documentation at [https://microsoft.github.io/BCApps](https://microsoft.github.io/BCApps/reference/test-runner/Module/Test-Runner.html).