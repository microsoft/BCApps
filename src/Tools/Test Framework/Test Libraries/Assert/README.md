This module provides functionality for verifying the values when running a test.

Use this module to do the following:
- Verify the outcome of a test.
- Fail a test, if needed.
- Distinguish between product errors and test failures.

This module must be used in test. Avoid using TESTFIELD, ERROR and other keywords that can be used in production.
By failing the tests by using Assert, the stack trace will indicate that the test has failed, and not the product.

In the test code, name the codeunit Assert instead of LibraryAssert.

This module must not be used outside the test code.

Check the reference documentation at [https://microsoft.github.io/BCApps](https://microsoft.github.io/BCApps/reference/library-assert/Module/Library-Assert.html).

