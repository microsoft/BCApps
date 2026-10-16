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
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsCopiesNonEmptyGuid()
    var
        GovTalkSetup: Record "Gov Talk Setup";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        SourceGuid: Guid;
    begin
        GovTalkSetup.DeleteAll();
        SourceGuid := CreateGuid();
        GovTalkSetup.Id := 'GUID';
        GovTalkSetup.Password := SourceGuid;
        GovTalkSetup.Insert();

        GovTalkHelperProcedures.TransferFields(Database::"Gov Talk Setup", GovTalkSetup.FieldNo(Password), GovTalkSetup.FieldNo("Vendor ID"));

        GovTalkSetup.Get('GUID');
        Assert.AreEqual(SourceGuid, GovTalkSetup."Vendor ID", 'A non-empty source GUID must be copied to the target field.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsSkipsEmptyGuid()
    var
        GovTalkSetup: Record "Gov Talk Setup";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        TargetGuid: Guid;
    begin
        GovTalkSetup.DeleteAll();
        TargetGuid := CreateGuid();
        GovTalkSetup.Id := 'GUID';
        GovTalkSetup."Vendor ID" := TargetGuid;
        GovTalkSetup.Insert();

        GovTalkHelperProcedures.TransferFields(Database::"Gov Talk Setup", GovTalkSetup.FieldNo(Password), GovTalkSetup.FieldNo("Vendor ID"));

        GovTalkSetup.Get('GUID');
        Assert.AreEqual(TargetGuid, GovTalkSetup."Vendor ID", 'An empty source GUID must not overwrite the target field.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsCopiesNonZeroIntegerAndSkipsZero()
    var
        GovTalkMessage: Record "GovTalk Message";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
    begin
        GovTalkMessage.DeleteAll();
        GovTalkMessage.ReportNo := 'NONZERO';
        GovTalkMessage.PollInterval := 100;
        GovTalkMessage.Insert();
        GovTalkMessage.Init();
        GovTalkMessage.ReportNo := 'ZERO';
        GovTalkMessage."Polling Count" := 200;
        GovTalkMessage.Insert();

        GovTalkHelperProcedures.TransferFields(Database::"GovTalk Message", GovTalkMessage.FieldNo(PollInterval), GovTalkMessage.FieldNo("Polling Count"));

        GovTalkMessage.Get(GovTalkMessage.ReportConfigCode, 'NONZERO');
        Assert.AreEqual(100, GovTalkMessage."Polling Count", 'A non-zero source value must be copied to the target field.');
        GovTalkMessage.Get(GovTalkMessage.ReportConfigCode, 'ZERO');
        Assert.AreEqual(200, GovTalkMessage."Polling Count", 'A zero source value must not overwrite the target field.');
    end;
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
