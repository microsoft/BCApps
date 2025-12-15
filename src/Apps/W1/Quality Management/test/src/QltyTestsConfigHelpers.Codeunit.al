// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139975 "Qlty. Tests - Config Helpers"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure GetArbitraryMaximumRecursion()
    var
        QltyConfigHelpers: Codeunit "Qlty. Configuration Helpers";
    begin
        // [SCENARIO] Verify the maximum recursion depth limit

        // [GIVEN] A quality management system with recursion limits

        // [WHEN] GetArbitraryMaximumRecursion is called
        // [THEN] The function returns 20 as the maximum recursion depth
        Initialize();
        LibraryAssert.AreEqual(20, QltyConfigHelpers.GetArbitraryMaximumRecursion(), '20 levels of recursion maximum are expected');
    end;

    [Test]
    procedure GetDefaultMaximumRowsFieldLookup_Defined()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Get maximum rows for field lookup when configured

        Initialize();

        // [GIVEN] Quality Management Setup with Max Rows Field Lookups set to 2
        QltyTestsUtility.EnsureSetup();

        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 2;
        QltyManagementSetup.Modify();

        // [WHEN] GetDefaultMaximumRowsFieldLookup is called
        // [THEN] The function returns the configured value of 2
        LibraryAssert.AreEqual(2, QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup(), 'simple maximum');
    end;

    [Test]
    procedure GetDefaultMaximumRowsFieldLookup_Undefined()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Get maximum rows for field lookup when not configured

        Initialize();

        // [GIVEN] Quality Management Setup with Max Rows Field Lookups set to 0
        QltyTestsUtility.EnsureSetup();

        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 0;
        QltyManagementSetup.Modify();

        // [WHEN] GetDefaultMaximumRowsFieldLookup is called
        // [THEN] The function returns the default value of 100
        LibraryAssert.AreEqual(100, QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup(), 'simple maximum');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;
}
