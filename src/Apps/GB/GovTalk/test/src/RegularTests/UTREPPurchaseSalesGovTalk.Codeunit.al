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
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        PartId: Guid;
    begin
        ECSLVATReportLine.DeleteAll();
        ECSLVATReportLine."Report No." := 'GOVTALK-MIGRATION';
        ECSLVATReportLine."Line No." := 1;
        ECSLVATReportLine.Insert();
        PartId := CreateGuid();
        SourceRecRef.GetTable(ECSLVATReportLine);
        SourceFieldRef := SourceRecRef.Field(10501);
        SourceFieldRef.Value := PartId;
        SourceRecRef.Modify();
        SourceRecRef.Close();

        GovTalkHelperProcedures.TransferFields(Database::"ECSL VAT Report Line", 10501, ECSLVATReportLine.FieldNo("XML Part Id GB"));

        ECSLVATReportLine.FindFirst();
        Assert.AreEqual(PartId, ECSLVATReportLine."XML Part Id GB", 'The legacy XML part ID must be migrated.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsSkipsEmptyGuid()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        PartId: Guid;
    begin
        ECSLVATReportLine.DeleteAll();
        PartId := CreateGuid();
        ECSLVATReportLine."Report No." := 'GOVTALK-MIGRATION';
        ECSLVATReportLine."Line No." := 1;
        ECSLVATReportLine."XML Part Id GB" := PartId;
        ECSLVATReportLine.Insert();

        GovTalkHelperProcedures.TransferFields(Database::"ECSL VAT Report Line", 10501, ECSLVATReportLine.FieldNo("XML Part Id GB"));

        ECSLVATReportLine.FindFirst();
        Assert.AreEqual(PartId, ECSLVATReportLine."XML Part Id GB", 'An empty legacy XML part ID must not overwrite the target.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsCopiesNonZeroIntegerAndSkipsZero()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
    begin
        VATReportsConfiguration.DeleteAll();
        VATReportsConfiguration."VAT Report Version" := 'NONZERO';
        VATReportsConfiguration.Insert();
        SourceRecRef.GetTable(VATReportsConfiguration);
        SourceFieldRef := SourceRecRef.Field(10500);
        SourceFieldRef.Value := 100;
        SourceRecRef.Modify();
        SourceRecRef.Close();
        VATReportsConfiguration.Init();
        VATReportsConfiguration."VAT Report Version" := 'ZERO';
        VATReportsConfiguration."Content Max Lines GB" := 200;
        VATReportsConfiguration.Insert();

        GovTalkHelperProcedures.TransferFields(Database::"VAT Reports Configuration", 10500, VATReportsConfiguration.FieldNo("Content Max Lines GB"));

        VATReportsConfiguration.Get(VATReportsConfiguration."VAT Report Type", 'NONZERO');
        Assert.AreEqual(100, VATReportsConfiguration."Content Max Lines GB", 'The legacy content maximum lines must be migrated.');
        VATReportsConfiguration.Get(VATReportsConfiguration."VAT Report Type", 'ZERO');
        Assert.AreEqual(200, VATReportsConfiguration."Content Max Lines GB", 'A zero legacy value must not overwrite the target.');
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
