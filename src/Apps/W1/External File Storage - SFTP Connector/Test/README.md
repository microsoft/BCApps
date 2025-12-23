# External File Storage - SFTP Connector Tests

This extension contains automated tests for the External File Storage - SFTP Connector app.

## Overview

The test suite validates the functionality of the SFTP connector implementation for Business Central's External File Storage framework. It ensures that SFTP accounts can be properly registered, managed, and operated within the system.

## Test Coverage

### Account Management Tests

- **TestMultipleAccountsCanBeRegistered**: Verifies that multiple SFTP accounts can be registered and retrieved correctly. Tests the ability to create up to 3 accounts and validate their persistence through the `GetAccounts` method.

- **TestShowAccountInformation**: Validates that account information is correctly displayed in the account page, ensuring all fields (name, hostname, username, port, fingerprints, and base folder path) are properly rendered.

### Environment Management Tests

- **TestEnviromentCleanupDisablesAccounts**: Ensures that when an environment is copied, all SFTP accounts are automatically disabled as a security measure. This test verifies the `OnAfterCopyEnvironmentPerCompany` trigger functionality.

## Test Structure

### Source Files

- **ExtSFTPConnectorTest.Codeunit.al**: Main test codeunit containing all test scenarios
- **mocks/ExtSFTPAccountMock.Codeunit.al**: Mock implementation for test data generation

### Test Helpers

The test suite includes several helper procedures:

- `Initialize()`: Cleans up test data before each test
- `SetBasicAccount()`: Generates randomized test account data using the Any library
- `AccountRegisterPageHandler()`: Modal page handler for account registration
- `AccountShowPageHandler()`: Page handler for account information verification

## Dependencies

- **External File Storage - SFTP Connector**: The main application being tested
- **Library Assert**: Assertion library for test validation
- **Any**: Random test data generation library
- **System Application Test Library**: System-level test utilities

## Running the Tests

These tests are designed to run in a Business Central test environment with the following attributes:

- Subtype: Test
- TestPermissions: Disabled
- TransactionModel: AutoRollback (for most tests)

## Notes

- All tests use randomized data to ensure independence and repeatability
- Tests follow the Given-When-Then pattern for clarity
- Transaction rollback ensures tests don't affect the database state
