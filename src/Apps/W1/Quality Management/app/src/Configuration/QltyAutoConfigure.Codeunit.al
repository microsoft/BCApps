// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration;

using Microsoft.Assembly.History;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using System.IO;
using System.Utilities;

/// <summary>
/// Contains helper functions to use for automatic configuration.
/// </summary>
codeunit 20402 "Qlty. Auto Configure"
{
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        DefaultQltyInspectionTestNoSeriesTok: Label 'QltyDEFAULT', Locked = true;
        DefaultQltyInspectionTestNoSeriesLabelTok: Label 'Quality Inspection Test Default', Locked = true;
        DefaultSeriesStartingNoTok: Label 'QI00000001', Locked = true;
        DefaultGrade0InProgressCodeTok: Label 'INPROGRESS', Locked = true;
        DefaultGrade0InProgressDescriptionTok: Label 'In Progress';
        DefaultGrade0InProgressConditionNumberTok: Label '', Locked = true;
        DefaultGrade0InProgressConditionTextTok: Label '', Locked = true;
        DefaultGrade0InProgressConditionBooleanTok: Label '', Locked = true;
        DefaultGrade1FailCodeTok: Label 'FAIL', Locked = true;
        DefaultGrade1FailDescriptionTok: Label 'Fail';
        DefaultGrade1FailConditionNumberTok: Label '<>0', Locked = true;
        DefaultGrade1FailConditionTextTok: Label '<>''''', Locked = true;
        DefaultGrade1FailConditionBooleanTok: Label 'No', Locked = true;
        DefaultGrade2PassCodeTok: Label 'PASS', Locked = true;
        DefaultGrade2PassDescriptionTok: Label 'Pass';
        DefaultGrade2PassConditionNumberTok: Label '<>0', Locked = true;
        DefaultGrade2PassConditionTextTok: Label '<>''''', Locked = true;
        DefaultGrade2PassConditionBooleanTok: Label 'Yes', Locked = true;
        BasicDefaultRecordsConfiguredMsg: Label 'Basic default configuration records have been configured. If you have previously adjusted those defaults then they have not been replaced.';
        WarehouseEntryToTestTok: Label 'WHSEENTRYTOTEST', Locked = true;
        WarehouseEntryToTestDescriptionTok: Label 'Warehouse Entry to Test', Locked = true;
        WarehouseJournalToTestTok: Label 'WHSEJNLTOTEST', Locked = true;
        WarehouseJournalToTestDescriptionTok: Label 'Warehouse Journal to Test', Locked = true;
        SalesLineToTrackingTok: Label 'TRACKINGTOSALES', Locked = true;
        SalesLineToTrackingDescriptionTok: Label 'Tracking Specification to Sales Line', Locked = true;
        WhseReceiptToPurchLineTok: Label 'WRTOPURCH', Locked = true;
        WhseReceiptToPurchLineDescriptionTok: Label 'Whse. Receipt to Purchase Line', Locked = true;
        ProdLineToTrackingTok: Label 'TRACKINGTOPROD', Locked = true;
        ProdLineToTrackingDescriptionTok: Label 'Tracking Specification to Prod. Order Line', Locked = true;
        PurchLineToTrackingTok: Label 'TRACKINGTOPURCH', Locked = true;
        PurchLineToTrackingDescriptionTok: Label 'Tracking Specification to Purchase Line', Locked = true;
        WhseReceiptToSalesLineTok: Label 'WRTOSALESRET', Locked = true;
        WhseReceiptToSalesLineDescriptionTok: Label 'Whse. Receipt to Sales Return', Locked = true;
        WhseJournalToPurchLineTok: Label 'WJNLTOPURCH', Locked = true;
        WhseJournalToPurchLineDescriptionTok: Label 'Whse. Journal to Purchase Line', Locked = true;
        WhseJournalToSalesLineTok: Label 'WJNLTOSALES', Locked = true;
        WhseJournalToSalesLineDescriptionTok: Label 'Whse. Journal to Sales Line', Locked = true;
        TrackingSpecToTestTok: Label 'TRACKINGSPEC', Locked = true;
        TrackingSpecToTestDescriptionTok: Label 'Tracking Specification to Test', Locked = true;
        PurchLineToTestTok: Label 'PURCHTOTEST', Locked = true;
        PurchLineToTestDescriptionTok: Label 'Purchase Line to Test', Locked = true;
        SalesLineToTestTok: Label 'SALESTOTEST', Locked = true;
        SalesLineToTestDescriptionTok: Label 'Sales Order to Test', Locked = true;
        SalesLineToTestFilterTok: Label 'WHERE(Document Type=FILTER(Order),Type=FILTER(Item))', Locked = true;
        SalesReturnLineToTestTok: Label 'SALESRETURNTOTEST', Locked = true;
        SalesReturnLineToTestDescriptionTok: Label 'Sales Return to Test', Locked = true;
        SalesReturnLineToTestFilterTok: Label 'WHERE(Document Type=FILTER(Return Order),Type=FILTER(Item))', Locked = true;
        ProdJnlToTestTok: Label 'PRODJNLTOTEST', Locked = true;
        ProdJnlToTestDescriptionTok: Label 'Production Output Journal to Test', Locked = true;
        LedgerToTestTok: Label 'ITEMLDGEROUTTOTEST', Locked = true;
        LedgerToTestDescriptionTok: Label 'Output Item Ledger to Test', Locked = true;
        RtngToItemJnlTok: Label 'ROUTINGLINETOITEMJNL', Locked = true;
        RtngToItemJnlDescriptionTok: Label 'Prod. Routing Line to Item Journal Line', Locked = true;
        ProdLineToJnlTok: Label 'PRODLINETOITEMJNL', Locked = true;
        ProdLineToJnlDescriptionTok: Label 'Prod. Order Line to Item Journal Line', Locked = true;
        ProdLineToRoutingTok: Label 'PRODLINETOROUTING', Locked = true;
        ProdLineToRoutingDescriptionTok: Label 'Prod. Order Line to Prod. Rtng.', Locked = true;
        InTransLineToTestTok: Label 'TRANSFERRECEIPTTOTEST', Locked = true;
        InTransLineToTestDescriptionTok: Label 'Inbound Transfer Line to Test', Locked = true;
        ProdLineToLedgerTok: Label 'PRODLINETOITEMLEDGER', Locked = true;
        ProdLineToLedgerDescriptionTok: Label 'Prod. Order Line to Item Ledger Entry.', Locked = true;
        ProdRoutingToTestTok: Label 'ROUTINGTOTEST', Locked = true;
        ProdRoutingToTestDescriptionTok: Label 'Prod. Order Routing Line to Test', Locked = true;
        AssemblyOutputToTestTok: Label 'ASSEMBLYOUTPUTTOTEST', Locked = true;
        AssemblyOutputToTestDescriptionTok: Label 'Posted Assembly Header to Test', Locked = true;
        ResourceBasedInstallFileTok: Label 'InstallFiles/PackageQM-EXPRESSDEMO.rapidstart', Locked = true;

    internal procedure GetDefaultPassGrade(): Text
    begin
        exit(DefaultGrade2PassCodeTok);
    end;

    internal procedure EnsureBasicSetup(ShowMessage: Boolean)
    begin
        EnsureSetupRecord();
        EnsureGrades();
        EnsureAtLeastOneSourceConfiguration(true);
        if ShowMessage then
            Message(BasicDefaultRecordsConfiguredMsg);
    end;

    local procedure EnsureGrades()
    begin
        EnsureSingleGrade(
            DefaultGrade0InProgressCodeTok,
            DefaultGrade0InProgressDescriptionTok,
            false,
            0,
            DefaultGrade0InProgressConditionNumberTok,
            DefaultGrade0InProgressConditionTextTok,
            DefaultGrade0InProgressConditionBooleanTok);
        EnsureSingleGrade(
            DefaultGrade1FailCodeTok,
            DefaultGrade1FailDescriptionTok,
            false,
            1,
            DefaultGrade1FailConditionNumberTok,
            DefaultGrade1FailConditionTextTok,
            DefaultGrade1FailConditionBooleanTok);
        EnsureSingleGrade(
            DefaultGrade2PassCodeTok,
            DefaultGrade2PassDescriptionTok,
            true,
            2,
            DefaultGrade2PassConditionNumberTok,
            DefaultGrade2PassConditionTextTok,
            DefaultGrade2PassConditionBooleanTok);
    end;

    local procedure EnsureSingleGrade(GradeCode: Text; GradeDescription: Text; IsPromoted: Boolean; EvaluationOrderLowestFirstHighestLast: Integer; DefaultNumericalCondition: Text; DefaultTextCondition: Text; DefaultBooleanCondition: Text)
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        if QltyInspectionGrade.Get(CopyStr(GradeCode, 1, MaxStrLen(QltyInspectionGrade.Code))) then
            exit;

        QltyInspectionGrade.Init();
        QltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(QltyInspectionGrade.Code));
        QltyInspectionGrade.Description := CopyStr(GradeDescription, 1, MaxStrLen(QltyInspectionGrade.Description));
        QltyInspectionGrade."Evaluation Sequence" := EvaluationOrderLowestFirstHighestLast;
        QltyInspectionGrade."Default Number Condition" := CopyStr(DefaultNumericalCondition, 1, MaxStrLen(QltyInspectionGrade."Default Number Condition"));
        QltyInspectionGrade."Default Text Condition" := CopyStr(DefaultTextCondition, 1, MaxStrLen(QltyInspectionGrade."Default Text Condition"));
        QltyInspectionGrade."Default Boolean Condition" := CopyStr(DefaultBooleanCondition, 1, MaxStrLen(QltyInspectionGrade."Default Boolean Condition"));
        if IsPromoted then
            QltyInspectionGrade."Grade Visibility" := QltyInspectionGrade."Grade Visibility"::Promoted;
        QltyInspectionGrade.AutoSetGradeCategoryFromName();
        QltyInspectionGrade.Insert(true);
    end;

    local procedure EnsureSetupRecord()
    begin
        if not QltyManagementSetup.WritePermission() then
            exit;

        if not QltyManagementSetup.Get() then
            QltyManagementSetup.Insert();

        Commit();

        if QltyManagementSetup."Quality Inspection Test Nos." = '' then
            if CreateDefaultQltyInspectionTestNoSeries(QltyManagementSetup) then
                QltyManagementSetup.Modify();
    end;

    /// <summary>
    /// If there is already at least enabled configuration then this will not do anything.
    /// Otherwise it will assume an empty system and create default purchase receipt configuration.
    /// </summary>
    /// <param name="ForceAll"></param>
    internal procedure EnsureAtLeastOneSourceConfiguration(ForceAll: Boolean)
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        QltyInspectSourceConfig.SetRange(Enabled, true);
        if not ForceAll then
            if not QltyInspectSourceConfig.IsEmpty() then
                exit;

        CreateDefaultTrackingSpecificationToTestConfiguration();
        CreateDefaultProductionConfiguration();
        CreateDefaultReceivingConfiguration();
        CreateDefaultWarehousingConfiguration();
        OnAfterEnsureAtLeastOneSourceConfiguration();
    end;

    /// <summary>
    /// If it's possible to create a default Quality Inspection Test No. Series, then do so.
    /// Only do this if the Quality Inspection Test No. Series is blank however.
    /// </summary>
    local procedure CreateDefaultQltyInspectionTestNoSeries(var ToAlterQltyManagementSetup: Record "Qlty. Management Setup") DidSomething: Boolean;
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        AlreadyCreated: Boolean;
    begin
        if ToAlterQltyManagementSetup."Quality Inspection Test Nos." <> '' then
            exit;

        if not NoSeries.WritePermission() then
            exit;
        if not NoSeriesLine.WritePermission() then
            exit;

        if not NoSeries.Get(DefaultQltyInspectionTestNoSeriesTok) then begin
            NoSeries.Init();
            NoSeries.Code := DefaultQltyInspectionTestNoSeriesTok;
            NoSeries.Description := CopyStr(DefaultQltyInspectionTestNoSeriesLabelTok, 1, MaxStrLen(NoSeries.Description));
            if NoSeries.Insert() then begin
                NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                if not NoSeriesLine.FindFirst() then begin
                    NoSeriesLine.Init();
                    NoSeriesLine."Series Code" := NoSeries.Code;
                    NoSeriesLine."Line No." := 10000;
                    NoSeriesLine.Validate("Starting No.", DefaultSeriesStartingNoTok);
                    DidSomething := NoSeriesLine.Insert();
                end else
                    DidSomething := true;
            end;
        end else
            AlreadyCreated := true;

        if (DidSomething or AlreadyCreated) and (ToAlterQltyManagementSetup."Quality Inspection Test Nos." = '') then begin
            ToAlterQltyManagementSetup."Quality Inspection Test Nos." := NoSeries.Code;
            DidSomething := true;
        end;
    end;

    internal procedure CreateDefaultProductionConfiguration()
    begin
        CreateDefaultProdOrderRoutingLineToTestConfiguration();
        CreateDefaultProdOrderLineToProdOrderRoutingConfiguration();

        CreateDefaultItemLedgerOutputToTestConfiguration();
        CreateDefaultProdOrderLineToItemLedgerConfiguration();

        CreateDefaultItemProdJournalToTestConfiguration();
        CreateDefaultProdOrderLineToItemJournalLineConfiguration();
        CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration();
        CreateDefaultTrackingSpecificationToProdConfiguration();
        CreateDefaultAssemblyOutputToTestConfiguration();
    end;

    internal procedure CreateDefaultWarehousingConfiguration()
    begin
        CreateDefaultWarehouseEntryToTestConfiguration();
        CreateDefaultWarehouseJournalLineToTestConfiguration();
    end;

    local procedure CreateDefaultWarehouseEntryToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WarehouseEntryToTestTok,
            WarehouseEntryToTestDescriptionTok,
            Database::"Warehouse Entry",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Whse. Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Source No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo(Quantity),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultWarehouseJournalLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WarehouseJournalToTestTok,
            WarehouseJournalToTestDescriptionTok,
            Database::"Warehouse Journal Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Whse. Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Absolute, Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
    end;

    internal procedure CreateDefaultReceivingConfiguration()
    begin
        CreateDefaultPurchaseLineToTestConfiguration();
        CreateDefaultSalesLineToTestConfiguration();
        CreateDefaultSalesReturnLineToTestConfiguration();
        CreateDefaultTrackingSpecificationToTestConfiguration();
        CreateDefaultTrackingSpecificationToPurchaseConfiguration();
        CreateDefaultTrackingSpecificationToSalesConfiguration();
        CreateDefaultWarehouseReceiptLineToPurchConfiguration();
        CreateDefaultWarehouseReceiptLineToSalesConfiguration();
        CreateDefaultWarehouseJournalLineToPurchConfiguration();
        CreateDefaultWarehouseJournalLineToSalesConfiguration();
        CreateDefaultTransferLineReceiptToTestConfiguration();
    end;

    local procedure CreateDefaultTrackingSpecificationToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(
            SalesLineToTrackingTok,
            SalesLineToTrackingDescriptionTok,
            Database::"Tracking Specification",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Ref. No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Line No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '',
            true);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultTrackingSpecificationToProdConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(
            ProdLineToTrackingTok,
            ProdLineToTrackingDescriptionTok,
            Database::"Tracking Specification",
            Database::"Prod. Order Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(5406))',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo(Status),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Prod. Order No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Prod. Order Line"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Line No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
               '',
            true);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultTrackingSpecificationToPurchaseConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(
            PurchLineToTrackingTok,
            PurchLineToTrackingDescriptionTok,
            Database::"Tracking Specification",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Ref. No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
               '',
            true);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultWarehouseJournalLineToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WhseJournalToSalesLineTok,
            WhseJournalToSalesLineDescriptionTok,
            Database::"Warehouse Journal Line",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Line No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultWarehouseJournalLineToPurchConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WhseJournalToPurchLineTok,
            WhseJournalToPurchLineDescriptionTok,
            Database::"Warehouse Journal Line",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Line No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultWarehouseReceiptLineToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WhseReceiptToSalesLineTok,
            WhseReceiptToSalesLineDescriptionTok,
            Database::"Warehouse Receipt Line",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Line No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Line No."),
            '');
    end;

    local procedure CreateDefaultWarehouseReceiptLineToPurchConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            WhseReceiptToPurchLineTok,
            WhseReceiptToPurchLineDescriptionTok,
            Database::"Warehouse Receipt Line",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Line No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
            '');
    end;

    local procedure CreateDefaultTrackingSpecificationToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        EnsureSourceConfigWithFilter(
            TrackingSpecToTestTok,
            TrackingSpecToTestDescriptionTok,
            Database::"Tracking Specification",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsurePrioritizedSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            false,
            ConfigFieldPriority::Priority);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultPurchaseLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            PurchLineToTestTok,
            PurchLineToTestDescriptionTok,
            Database::"Purchase Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Type=FILTER(Item))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultSalesLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            SalesLineToTestTok,
            SalesLineToTestDescriptionTok,
            Database::"Sales Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            SalesLineToTestFilterTok);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Qty. to Ship (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultSalesReturnLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempReturnSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            SalesReturnLineToTestTok,
            SalesReturnLineToTestDescriptionTok,
            Database::"Sales Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            SalesReturnLineToTestFilterTok);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Return Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultItemProdJournalToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        EnsureSourceConfigWithFilter(
            ProdJnlToTestTok,
            ProdJnlToTestDescriptionTok,
            Database::"Item Journal Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Task No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsurePrioritizedSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            false,
            ConfigFieldPriority::Priority);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultItemLedgerOutputToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            LedgerToTestTok,
            LedgerToTestDescriptionTok,
            Database::"Item Ledger Entry",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Quantity),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Description),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo(Description),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            RtngToItemJnlTok,
            RtngToItemJnlDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing Reference No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Operation No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdLineToJnlTok,
            ProdLineToJnlDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemJournalLine.FieldNo("Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemLedgerConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdLineToLedgerTok,
            ProdLineToLedgerDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Ledger Entry",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfig(
            ProdRoutingToTestTok,
            ProdRoutingToTestDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Task No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToProdOrderRoutingConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfig(
            ProdLineToRoutingTok,
            ProdLineToRoutingDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Prod. Order Routing Line",
            QltyInspectSourceConfig);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Status"),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Status"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing Reference No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultTransferLineReceiptToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempTransferline: Record "Transfer Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            InTransLineToTestTok,
            InTransLineToTestDescriptionTok,
            Database::"Transfer Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Type=FILTER(Item))');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Document No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Transfer-to Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultAssemblyOutputToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfig(
            AssemblyOutputToTestTok,
            AssemblyOutputToTestDescriptionTok,
            Database::"Posted Assembly Header",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig);
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo(Description),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo(Description),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
    end;

    local procedure EnsureSourceConfig(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.")
    begin
        EnsureSourceConfigWithTrackFlag(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            false);
    end;

    local procedure EnsureSourceConfigWithTrackFlag(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; TrackingOnly: Boolean)
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            '',
            TrackingOnly);
    end;

    local procedure EnsureSourceConfigWithFilter(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFilter: Text)
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            FromFilter,
            false);
    end;

    local procedure EnsureSourceConfigWithFilterAndTrackFlag(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFilter: Text; TrackingOnly: Boolean)
    begin
        QltyInspectSourceConfig.Reset();
        if not QltyInspectSourceConfig.Get(CopyStr(Name, 1, MaxStrLen(QltyInspectSourceConfig.Code))) then begin
            QltyInspectSourceConfig.Init();
            QltyInspectSourceConfig.Code := CopyStr(Name, 1, MaxStrLen(QltyInspectSourceConfig.Code));
            QltyInspectSourceConfig.Description := CopyStr(Description, 1, MaxStrLen(QltyInspectSourceConfig.Description));
            QltyInspectSourceConfig."From Table Filter" := CopyStr(FromFilter, 1, MaxStrLen(QltyInspectSourceConfig."From Table Filter"));
            QltyInspectSourceConfig.Validate("From Table No.", FromTable);
            if ToTable = Database::"Qlty. Inspection Test Header" then
                QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::Test
            else
                if TrackingOnly then
                    QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::"Item Tracking only"
                else
                    QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::"Chained table";

            QltyInspectSourceConfig.Validate("To Table No.", ToTable);
            QltyInspectSourceConfig.Insert();
        end;
    end;

    local procedure EnsureSourceConfigLine(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text)
    begin
        EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            FromField,
            ToTable,
            ToField,
            OptionalOverrideDisplay,
            false);
    end;

    local procedure EnsureSourceConfigLineWithTrackFlag(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text; TrackingOnly: Boolean)
    var
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        EnsurePrioritizedSourceConfigLineWithTrackFlag(QltyInspectSourceConfig, FromField, ToTable, ToField, OptionalOverrideDisplay, TrackingOnly, ConfigFieldPriority::Normal);
    end;

    local procedure EnsurePrioritizedSourceConfigLineWithTrackFlag(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text; TrackingOnly: Boolean; Priority: Enum "Qlty. Config. Field Priority")
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
    begin
        QltyInspectSrcFldConf.SetRange(Code, QltyInspectSourceConfig.Code);
        QltyInspectSrcFldConf.SetRange("From Field No.", FromField);
        QltyInspectSrcFldConf.SetRange("To Table No.", ToTable);
        QltyInspectSrcFldConf.SetRange("To Field No.", ToField);
        if not QltyInspectSrcFldConf.FindFirst() then begin
            QltyInspectSrcFldConf.Init();
            QltyInspectSrcFldConf.Code := QltyInspectSourceConfig.Code;
            QltyInspectSrcFldConf.InitLineNoIfNeeded();
            QltyInspectSrcFldConf."From Table No." := QltyInspectSourceConfig."From Table No.";
            QltyInspectSrcFldConf."From Field No." := FromField;

            if ToTable = Database::"Qlty. Inspection Test Header" then
                QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::Test
            else
                if TrackingOnly then
                    QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::"Item Tracking only"
                else
                    QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::"Chained table";

            QltyInspectSrcFldConf."To Table No." := ToTable;
            QltyInspectSrcFldConf."To Field No." := ToField;
            QltyInspectSrcFldConf."Display As" := CopyStr(OptionalOverrideDisplay, 1, MaxStrLen(QltyInspectSrcFldConf."Display As"));
            QltyInspectSrcFldConf."Priority Field" := Priority;
            QltyInspectSrcFldConf.Insert();
        end;
    end;

    /// <summary>
    /// GuessDoesAppearToBeSetup will guess if the system appears to be setup.
    /// Use this if you need to not just make sure that Quality Inspection is installed but some basic setup has been done.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GuessDoesAppearToBeSetup(): Boolean
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyField: Record "Qlty. Field";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        if QltyInTestGenerationRule.IsEmpty() then
            exit(false);
        if QltyInspectionTemplateHdr.IsEmpty() then
            exit(false);
        if QltyField.IsEmpty() then
            exit(false);
        if QltyInspectionGrade.IsEmpty() then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// GuessDoesAppearToBeUsed will guess if it's used.
    /// Use this if you need to guess if the system is not just probably setup enough, but also appears to have actual usage.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GuessDoesAppearToBeUsed(): Boolean
    var
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
    begin
        exit(QltyInspectionTestLine.Count() > 2);
    end;

    /// <summary>
    /// Apply any settings files from the public endpoint
    /// </summary>
    /// <param name="CurrentCommit">Boolean.</param>
    procedure ApplyGettingStartedData(CurrentCommit: Boolean)
    begin
        if CurrentCommit then
            Commit();
        ApplyConfigurationPackage();
        if CurrentCommit then
            Commit();
    end;

    /// <summary>
    /// Apply the configuration package.
    /// </summary>
    procedure ApplyConfigurationPackage()
    begin
        ApplyConfigurationPackageFromResource(ResourceBasedInstallFileTok);
        UpdateGradeCategoryOnGradesInSystem();
    end;

    local procedure UpdateGradeCategoryOnGradesInSystem()
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        QltyInspectionGrade.SetRange("Grade Category", QltyInspectionGrade."Grade Category"::Uncategorized);
        if QltyInspectionGrade.FindSet(true) then
            repeat
                case QltyInspectionGrade.Code of
                    'PASS', 'GOOD', 'ACCEPTABLE':
                        begin
                            QltyInspectionGrade."Grade Category" := QltyInspectionGrade."Grade Category"::Acceptable;
                            QltyInspectionGrade.Modify(false);
                        end;
                    'FAIL', 'BAD', 'UNACCEPTABLE', 'ERROR', 'REJECT':
                        begin
                            QltyInspectionGrade."Grade Category" := QltyInspectionGrade."Grade Category"::"Not acceptable";
                            QltyInspectionGrade.Modify(false);
                        end;
                end;
            until QltyInspectionGrade.Next() = 0;
    end;

    /// <summary>
    /// Apply the supplied configuration package.
    /// </summary>
    /// <param name="ResourcePath">reference to the internal resource location</param>
    procedure ApplyConfigurationPackageFromResource(ResourcePath: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ConfigPackageImport: Codeunit "Config. Package - Import";
        InStreamFromResource: InStream;
        OutStreamToConfigPackage: OutStream;
    begin
        TempBlob.CreateInStream(InStreamFromResource);
        TempBlob.CreateOutStream(OutStreamToConfigPackage);
        NavApp.GetResource(ResourcePath, InStreamFromResource);
        CopyStream(OutStreamToConfigPackage, InStreamFromResource);
        ConfigPackageImport.ImportAndApplyRapidStartPackageStream(TempBlob);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEnsureAtLeastOneSourceConfiguration()
    begin
    end;
}
