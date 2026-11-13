// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Reporting;
using System.TestLibraries.Utilities;

codeunit 144035 "UT REP Purchase Sales GovTalk"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CurrentSaveValuesId: Integer;

    [Test]
    [HandlerFunctions('ECSalesListReportRPH')]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageFieldsBasicApplicationArea()
    begin
        // [FEATURE] [ECSL] [Application Area] [UI] [UT]
        // [SCENARIO 331168] ReportLayout and "Create XML File" fields are enabled on EC Sales List Request page when Application Area = #basic
        Initialize();

        // [GIVEN] Enabled Application Area = #basic setup
        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        // [WHEN] Run "EC Sales List" report
        // [THEN] ReportLayout and "Create XML File" fields are enabled (check in RPH)
        REPORT.Run(REPORT::"EC Sales List");
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ECSalesListReportRPH')]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageFieldsSuiteApplicationArea()
    begin
        // [FEATURE] [ECSL] [Application Area] [UI] [UT]
        // [SCENARIO 331168] ReportLayout and "Create XML File" fields are enabled on EC Sales List Request page when Application Area = #suite
        Initialize();
        // [GIVEN] Enabled Application Area = #suite setup
        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        // [WHEN] Run "EC Sales List" report
        // [THEN] ReportLayout and "Create XML File" fields are enabled (check in RPH)
        REPORT.Run(REPORT::"EC Sales List");
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListReportRPH(var ECSalesList: TestRequestPage "EC Sales List")
    begin
        Assert.IsTrue(ECSalesList."Create XML File GB".Visible(), '');
        Assert.IsTrue(ECSalesList."Create XML File GB".Enabled(), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();

    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

}
