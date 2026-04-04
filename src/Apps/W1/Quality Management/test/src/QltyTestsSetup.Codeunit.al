// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Setup;
using System.TestLibraries.Utilities;

codeunit 139973 "Qlty. Tests - Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure InspectionSelectionCriteriaDefaultsToNewestReinspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspSelectionCriteria: Enum "Qlty. Insp. Selection Criteria";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 624745] Inspection Selection Criteria defaults to "Only the newest inspection/re-inspection" on fresh record

        // [GIVEN] No "Qlty. Management Setup" record exists
        QltyManagementSetup.DeleteAll();

        // [WHEN] A new setup record is initialized and inserted
        QltyManagementSetup.Init();
        QltyManagementSetup.Insert();

        // [THEN] "Inspection Selection Criteria" is "Only the newest inspection/re-inspection"
        LibraryAssert.AreEqual(
            QltyInspSelectionCriteria::"Only the newest inspection/re-inspection",
            QltyManagementSetup."Inspection Selection Criteria",
            'Inspection Selection Criteria should default to "Only the newest inspection/re-inspection"');
    end;

    [Test]
    procedure InspectionSelectionCriteriaCanBeSetToExplicitValue()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspSelectionCriteria: Enum "Qlty. Insp. Selection Criteria";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 624745] Inspection Selection Criteria accepts explicit value override

        // [GIVEN] No "Qlty. Management Setup" record exists
        QltyManagementSetup.DeleteAll();

        // [GIVEN] A new setup record "S" is initialized
        QltyManagementSetup.Init();

        // [WHEN] "Inspection Selection Criteria" is set to "Any inspection that matches" on "S"
        QltyManagementSetup."Inspection Selection Criteria" := QltyInspSelectionCriteria::"Any inspection that matches";
        QltyManagementSetup.Insert();

        // [THEN] "Inspection Selection Criteria" is "Any inspection that matches"
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(
            QltyInspSelectionCriteria::"Any inspection that matches",
            QltyManagementSetup."Inspection Selection Criteria",
            'Inspection Selection Criteria should accept explicitly set value');
    end;
}
