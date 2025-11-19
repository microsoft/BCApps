# Out-of-the-box Power BI reports for Business Central

## Contributing

Any contribution has to verify manually that the E2E tests run successfully, since the pipeline at the moment of creating a PR in this repository will not include them.

If you contribution includes E2E API tests add them in the appropiate E2E test codeunit. Only add tests in the E2E codeunits if they require web service calls.

To run locally the E2E tests, prepare a Business Central instance with no users (Windows authentication) and use the 130451 "Test Runner - Isol. Disabled" codeunit.