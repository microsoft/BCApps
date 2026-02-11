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
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

/// <summary>
/// Contains helper functions for automatic configuration.
/// </summary>
codeunit 20402 "Qlty. Auto Configure"
{
    var
        BasicDefaultRecordsConfiguredMsg: Label 'Basic default configuration records have been configured. If you have previously adjusted those defaults then they have not been replaced.';
        DefaultQltyInspectionNoSeriesTok: Label 'QltyDEFAULT', MaxLength = 20, Locked = true;
        DefaultQltyInspectionNoSeriesLabelTxt: Label 'Quality Inspection Default', MaxLength = 100;
        DefaultSeriesStartingNoTok: Label 'QI00000001', MaxLength = 20, Locked = true;
        DefaultResult0InProgressCodeTok: Label 'INPROGRESS', MaxLength = 20, Locked = true;
        DefaultResult0InProgressDescriptionTxt: Label 'In Progress', MaxLength = 100;
        DefaultResult0InProgressConditionNumberTok: Label '', MaxLength = 500, Locked = true;
        DefaultResult0InProgressConditionTextTok: Label '', MaxLength = 500, Locked = true;
        DefaultResult0InProgressConditionBooleanTok: Label '', MaxLength = 500, Locked = true;
        DefaultResult1FailCodeTok: Label 'FAIL', MaxLength = 20, Locked = true;
        DefaultResult1FailDescriptionTxt: Label 'Fail', MaxLength = 100;
        DefaultResult1FailConditionNumberTok: Label '<>0', MaxLength = 500, Locked = true;
        DefaultResult1FailConditionTextTok: Label '<>''''', MaxLength = 500, Locked = true;
        DefaultResult1FailConditionBooleanTok: Label 'No', MaxLength = 500, Locked = true;
        DefaultResult2PassCodeTok: Label 'PASS', MaxLength = 20, Locked = true;
        DefaultResult2PassDescriptionTxt: Label 'Pass', MaxLength = 100;
        DefaultResult2PassConditionNumberTok: Label '<>0', MaxLength = 500, Locked = true;
        DefaultResult2PassConditionTextTok: Label '<>''''', MaxLength = 500, Locked = true;
        DefaultResult2PassConditionBooleanTok: Label 'Yes', MaxLength = 500, Locked = true;
        WarehouseEntryToInspectTok: Label 'WHSEENTRYTOINSPECT', MaxLength = 20, Locked = true;
        WarehouseEntryToInspectDescriptionTxt: Label 'Warehouse Entry to Inspection', MaxLength = 100;
        WarehouseJournalToInspectTok: Label 'WHSEJNLTOINSPECT', MaxLength = 20, Locked = true;
        WarehouseJournalToInspectDescriptionTxt: Label 'Warehouse Journal to Inspection', MaxLength = 100;
        SalesLineToTrackingTok: Label 'TRACKINGTOSALES', MaxLength = 20, Locked = true;
        SalesLineToTrackingDescriptionTxt: Label 'Tracking Specification to Sales Line', MaxLength = 100;
        WhseReceiptToPurchLineTok: Label 'WRTOPURCH', MaxLength = 20, Locked = true;
        WhseReceiptToPurchLineDescriptionTxt: Label 'Whse. Receipt to Purchase Line', MaxLength = 100;
        ProdLineToTrackingTok: Label 'TRACKINGTOPROD', MaxLength = 20, Locked = true;
        ProdLineToTrackingDescriptionTxt: Label 'Tracking Specification to Prod. Order Line', MaxLength = 100;
        PurchLineToTrackingTok: Label 'TRACKINGTOPURCH', MaxLength = 20, Locked = true;
        PurchLineToTrackingDescriptionTxt: Label 'Tracking Specification to Purchase Line', MaxLength = 100;
        WhseReceiptToSalesLineTok: Label 'WRTOSALESRET', MaxLength = 20, Locked = true;
        WhseReceiptToSalesLineDescriptionTxt: Label 'Whse. Receipt to Sales Return', MaxLength = 100;
        WhseJournalToPurchLineTok: Label 'WJNLTOPURCH', MaxLength = 20, Locked = true;
        WhseJournalToPurchLineDescriptionTxt: Label 'Whse. Journal to Purchase Line', MaxLength = 100;
        WhseJournalToSalesLineTok: Label 'WJNLTOSALES', MaxLength = 20, Locked = true;
        WhseJournalToSalesLineDescriptionTxt: Label 'Whse. Journal to Sales Line', MaxLength = 100;
        TrackingSpecToInspectTok: Label 'TRACKINGSPEC', MaxLength = 20, Locked = true;
        TrackingSpecToInspectDescriptionTxt: Label 'Tracking Specification to Inspection', MaxLength = 100;
        PurchLineToInspectTok: Label 'PURCHTOINSPECT', MaxLength = 20, Locked = true;
        PurchLineToInspectDescriptionTxt: Label 'Purchase Line to Inspection', MaxLength = 100;
        SalesLineToInspectTok: Label 'SALESTOINSPECT', MaxLength = 20, Locked = true;
        SalesLineToInspectDescriptionTxt: Label 'Sales Order to Inspection', MaxLength = 100;
        SalesReturnLineToInspectTok: Label 'SALESRETURNTOINSPECT', MaxLength = 20, Locked = true;
        SalesReturnLineToInspectDescriptionTxt: Label 'Sales Return to Inspection', MaxLength = 100;
        ProdJnlToInspectTok: Label 'PRODJNLTOINSPECT', MaxLength = 20, Locked = true;
        ProdJnlToInspectDescriptionTxt: Label 'Production Output Journal to Inspection', MaxLength = 100;
        LedgerToInspectTok: Label 'ITEMLDGROUTINSPECT', MaxLength = 20, Locked = true;
        LedgerToInspectDescriptionTxt: Label 'Output Item Ledger to Inspection', MaxLength = 100;
        RtngToItemJnlTok: Label 'ROUTINGLINETOITEMJNL', MaxLength = 20, Locked = true;
        RtngToItemJnlDescriptionTxt: Label 'Prod. Routing Line to Item Journal Line', MaxLength = 100;
        ProdLineToJnlTok: Label 'PRODLINETOITEMJNL', MaxLength = 20, Locked = true;
        ProdLineToJnlDescriptionTxt: Label 'Prod. Order Line to Item Journal Line', MaxLength = 100;
        ProdLineToRoutingTok: Label 'PRODLINETOROUTING', MaxLength = 20, Locked = true;
        ProdLineToRoutingDescriptionTxt: Label 'Prod. Order Line to Prod. Rtng.', MaxLength = 100;
        InTransLineToInspectTok: Label 'TRANSRECPTINSPECT', MaxLength = 20, Locked = true;
        InTransLineToInspectDescriptionTxt: Label 'Inbound Transfer Line to Inspection', MaxLength = 100;
        ProdLineToLedgerTok: Label 'PRODLINETOITEMLEDGER', MaxLength = 20, Locked = true;
        ProdLineToLedgerDescriptionTxt: Label 'Prod. Order Line to Item Ledger Entry.', MaxLength = 100;
        ProdRoutingToInspectTok: Label 'ROUTINGTOINSPECT', MaxLength = 20, Locked = true;
        ProdRoutingToInspectDescriptionTxt: Label 'Prod. Order Routing Line to Inspection', MaxLength = 100;
        AssemblyOutputToInspectTok: Label 'ASMOUTPUTTOINSPECT', MaxLength = 20, Locked = true;
        AssemblyOutputToInspectDescriptionTxt: Label 'Posted Assembly Header to Inspection', MaxLength = 100;

    internal procedure GetDefaultPassResult(): Text
    begin
        exit(DefaultResult2PassCodeTok);
    end;

    internal procedure EnsureBasicSetupExists(ShowMessage: Boolean)
    begin
        EnsureSetupRecordExists();
        EnsureResultExists();
        EnsureAtLeastOneSourceConfigurationExist(true);

        if ShowMessage then
            Message(BasicDefaultRecordsConfiguredMsg);
    end;

    local procedure EnsureSetupRecordExists()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.WritePermission() then
            exit;

        if not QltyManagementSetup.Get() then
            QltyManagementSetup.Insert();

        Commit();

        if QltyManagementSetup."Quality Inspection Nos." = '' then
            if CreateDefaultQltyInspectionNoSeries(QltyManagementSetup) then
                QltyManagementSetup.Modify();
    end;

    /// <summary>
    /// If it's possible to create a default Quality Inspection No. Series, then do so.
    /// Only do this if the Quality Inspection No. Series is blank however.
    /// </summary>
    local procedure CreateDefaultQltyInspectionNoSeries(var QltyManagementSetup: Record "Qlty. Management Setup") DidSomething: Boolean;
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        AlreadyCreated: Boolean;
    begin
        if QltyManagementSetup."Quality Inspection Nos." <> '' then
            exit;

        if not NoSeries.WritePermission() then
            exit;
        if not NoSeriesLine.WritePermission() then
            exit;

        if not NoSeries.Get(DefaultQltyInspectionNoSeriesTok) then begin
            NoSeries.Init();
            NoSeries.Code := DefaultQltyInspectionNoSeriesTok;
            NoSeries.Description := CopyStr(DefaultQltyInspectionNoSeriesLabelTxt, 1, MaxStrLen(NoSeries.Description));
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

        if (DidSomething or AlreadyCreated) and (QltyManagementSetup."Quality Inspection Nos." = '') then begin
            QltyManagementSetup."Quality Inspection Nos." := NoSeries.Code;
            DidSomething := true;
        end;
    end;

    local procedure EnsureResultExists()
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        if not QltyInspectionResult.IsEmpty() then
            exit;

        EnsureSingleResultExists(
            DefaultResult0InProgressCodeTok,
            DefaultResult0InProgressDescriptionTxt,
            false,
            0,
            DefaultResult0InProgressConditionNumberTok,
            DefaultResult0InProgressConditionTextTok,
            DefaultResult0InProgressConditionBooleanTok,
            false);
        EnsureSingleResultExists(
            DefaultResult1FailCodeTok,
            DefaultResult1FailDescriptionTxt,
            false,
            1,
            DefaultResult1FailConditionNumberTok,
            DefaultResult1FailConditionTextTok,
            DefaultResult1FailConditionBooleanTok,
            true);
        EnsureSingleResultExists(
            DefaultResult2PassCodeTok,
            DefaultResult2PassDescriptionTxt,
            true,
            2,
            DefaultResult2PassConditionNumberTok,
            DefaultResult2PassConditionTextTok,
            DefaultResult2PassConditionBooleanTok,
            true);
    end;

    local procedure EnsureSingleResultExists(ResultCode: Text; ResultDescription: Text; IsPromoted: Boolean; EvaluationOrderLowestFirstHighestLast: Integer; DefaultNumericalCondition: Text; DefaultTextCondition: Text; DefaultBooleanCondition: Text; AllowFinish: Boolean)
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        if not QltyInspectionResult.Get(CopyStr(ResultCode, 1, MaxStrLen(QltyInspectionResult.Code))) then begin
            QltyInspectionResult.Init();
            QltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(QltyInspectionResult.Code));
            QltyInspectionResult.Description := CopyStr(ResultDescription, 1, MaxStrLen(QltyInspectionResult.Description));
            QltyInspectionResult."Evaluation Sequence" := EvaluationOrderLowestFirstHighestLast;
            QltyInspectionResult."Default Number Condition" := CopyStr(DefaultNumericalCondition, 1, MaxStrLen(QltyInspectionResult."Default Number Condition"));
            QltyInspectionResult."Default Text Condition" := CopyStr(DefaultTextCondition, 1, MaxStrLen(QltyInspectionResult."Default Text Condition"));
            QltyInspectionResult."Default Boolean Condition" := CopyStr(DefaultBooleanCondition, 1, MaxStrLen(QltyInspectionResult."Default Boolean Condition"));
            if IsPromoted then
                QltyInspectionResult."Result Visibility" := QltyInspectionResult."Result Visibility"::Promoted;
            QltyInspectionResult.AutoSetResultCategoryFromName();
            QltyInspectionResult."Finish Allowed" := AllowFinish ? QltyInspectionResult."Finish Allowed"::"Allow Finish" : QltyInspectionResult."Finish Allowed"::"Do Not Allow Finish";
            QltyInspectionResult.Insert(true);
        end else begin
            QltyInspectionResult."Finish Allowed" := AllowFinish ? QltyInspectionResult."Finish Allowed"::"Allow Finish" : QltyInspectionResult."Finish Allowed"::"Do Not Allow Finish";
            QltyInspectionResult.Modify();
        end;
    end;

    /// <summary>
    /// If there is already at least enabled configuration then this will not do anything.
    /// Otherwise it will assume an empty system and create default purchase receipt configuration.
    /// </summary>
    /// <param name="ForceAll"></param>
    internal procedure EnsureAtLeastOneSourceConfigurationExist(ForceAll: Boolean)
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        QltyInspectSourceConfig.SetRange(Enabled, true);
        if not ForceAll then
            if not QltyInspectSourceConfig.IsEmpty() then
                exit;

        CreateDefaultTrackingSpecificationToInspectConfiguration();
        CreateDefaultProductionAndAssemblyConfiguration();
        CreateDefaultReceivingConfiguration();
        CreateDefaultWarehousingConfiguration();
    end;

    local procedure CreateDefaultTrackingSpecificationToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        QltyConfigTestPriority: Enum "Qlty. Config. Test Priority";
    begin
        EnsureSourceConfigWithFilterExists(
            TrackingSpecToInspectTok,
            TrackingSpecToInspectDescriptionTxt,
            Database::"Tracking Specification",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsurePrioritizedSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '',
            false,
            QltyConfigTestPriority::Priority);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProductionAndAssemblyConfiguration()
    begin
        CreateDefaultProdOrderRoutingLineToInspectConfiguration();
        CreateDefaultProdOrderLineToProdOrderRoutingConfiguration();

        CreateDefaultItemLedgerOutputToInspectConfiguration();
        CreateDefaultProdOrderLineToItemLedgerConfiguration();

        CreateDefaultItemProdJournalToInspectConfiguration();
        CreateDefaultProdOrderLineToItemJournalLineConfiguration();
        CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration();
        CreateDefaultTrackingSpecificationToProdConfiguration();
        CreateDefaultAssemblyOutputToInspectConfiguration();
    end;

    local procedure CreateDefaultReceivingConfiguration()
    begin
        CreateDefaultPurchaseLineToInspectConfiguration();
        CreateDefaultSalesLineToInspectConfiguration();
        CreateDefaultSalesReturnLineToInspectConfiguration();
        CreateDefaultTrackingSpecificationToInspectConfiguration();
        CreateDefaultTrackingSpecificationToPurchaseConfiguration();
        CreateDefaultTrackingSpecificationToSalesConfiguration();
        CreateDefaultWarehouseReceiptLineToPurchConfiguration();
        CreateDefaultWarehouseReceiptLineToSalesConfiguration();
        CreateDefaultWarehouseJournalLineToPurchConfiguration();
        CreateDefaultWarehouseJournalLineToSalesConfiguration();
        CreateDefaultTransferLineReceiptToInspectConfiguration();
    end;

    internal procedure CreateDefaultWarehousingConfiguration()
    begin
        CreateDefaultWarehouseEntryToInspectConfiguration();
        CreateDefaultWarehouseJournalLineToInspectConfiguration();
    end;

    local procedure CreateDefaultWarehouseEntryToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            WarehouseEntryToInspectTok,
            WarehouseEntryToInspectDescriptionTxt,
            Database::"Warehouse Entry",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Whse. Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Source No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo(Quantity),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseEntry.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultWarehouseJournalLineToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            WarehouseJournalToInspectTok,
            WarehouseJournalToInspectDescriptionTxt,
            Database::"Warehouse Journal Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Whse. Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Absolute, Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultTrackingSpecificationToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlagExists(
            SalesLineToTrackingTok,
            SalesLineToTrackingDescriptionTxt,
            Database::"Tracking Specification",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Ref. No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Line No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '',
            true);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultTrackingSpecificationToProdConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlagExists(
            ProdLineToTrackingTok,
            ProdLineToTrackingDescriptionTxt,
            Database::"Tracking Specification",
            Database::"Prod. Order Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(5406))',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo(Status),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Prod. Order No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Prod. Order Line"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Line No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
               '',
            true);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultTrackingSpecificationToPurchaseConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        EnsureSourceConfigWithFilterAndTrackFlagExists(
            PurchLineToTrackingTok,
            PurchLineToTrackingDescriptionTxt,
            Database::"Tracking Specification",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Ref. No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
               '',
            true);
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
               '',
            true);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultWarehouseJournalLineToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            WhseJournalToSalesLineTok,
            WhseJournalToSalesLineDescriptionTxt,
            Database::"Warehouse Journal Line",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Line No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultWarehouseJournalLineToPurchConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            WhseJournalToPurchLineTok,
            WhseJournalToPurchLineDescriptionTxt,
            Database::"Warehouse Journal Line",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Source Line No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Qty. (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultWarehouseReceiptLineToSalesConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            WhseReceiptToSalesLineTok,
            WhseReceiptToSalesLineDescriptionTxt,
            Database::"Warehouse Receipt Line",
            Database::"Sales Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(37))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Subtype"),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source No."),
            Database::"Sales Line",
            TempSalesLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLineExists(
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
        EnsureSourceConfigWithFilterExists(
            WhseReceiptToPurchLineTok,
            WhseReceiptToPurchLineDescriptionTxt,
            Database::"Warehouse Receipt Line",
            Database::"Purchase Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(39))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Subtype"),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document Type"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempWarehouseReceiptLine.FieldNo("Source Line No."),
            Database::"Purchase Line",
            TempPurchaseLine.FieldNo("Line No."),
            '');
    end;

    local procedure CreateDefaultPurchaseLineToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            PurchLineToInspectTok,
            PurchLineToInspectDescriptionTxt,
            Database::"Purchase Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Type=FILTER(Item))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPurchaseLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultSalesLineToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            SalesLineToInspectTok,
            SalesLineToInspectDescriptionTxt,
            Database::"Sales Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Document Type=FILTER(Order),Type=FILTER(Item))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Qty. to Ship (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempSalesLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultSalesReturnLineToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempReturnSalesLine: Record "Sales Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            SalesReturnLineToInspectTok,
            SalesReturnLineToInspectDescriptionTxt,
            Database::"Sales Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Document Type=FILTER(Return Order),Type=FILTER(Item))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Return Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempReturnSalesLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultItemProdJournalToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        QltyConfigTestPriority: Enum "Qlty. Config. Test Priority";
    begin
        EnsureSourceConfigWithFilterExists(
            ProdJnlToInspectTok,
            ProdJnlToInspectDescriptionTxt,
            Database::"Item Journal Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Order No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Task No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsurePrioritizedSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '',
            false,
            QltyConfigTestPriority::Priority);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultItemLedgerOutputToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            LedgerToInspectTok,
            LedgerToInspectDescriptionTxt,
            Database::"Item Ledger Entry",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Quantity),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Lot No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Lot No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Serial No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Serial No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Package No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Package No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Description),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo(Description),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            RtngToItemJnlTok,
            RtngToItemJnlDescriptionTxt,
            Database::"Prod. Order Routing Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing Reference No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Operation No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            ProdLineToJnlTok,
            ProdLineToJnlDescriptionTxt,
            Database::"Prod. Order Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemJournalLine.FieldNo("Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemLedgerConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            ProdLineToLedgerTok,
            ProdLineToLedgerDescriptionTxt,
            Database::"Prod. Order Line",
            Database::"Item Ledger Entry",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigExists(
            ProdRoutingToInspectTok,
            ProdRoutingToInspectDescriptionTxt,
            Database::"Prod. Order Routing Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Type"),
            ' ');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Custom 1"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Task No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToProdOrderRoutingConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigExists(
            ProdLineToRoutingTok,
            ProdLineToRoutingDescriptionTxt,
            Database::"Prod. Order Line",
            Database::"Prod. Order Routing Line",
            QltyInspectSourceConfig);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Status"),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Status"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing Reference No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultTransferLineReceiptToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempTransferline: Record "Transfer Line" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigWithFilterExists(
            InTransLineToInspectTok,
            InTransLineToInspectDescriptionTxt,
            Database::"Transfer Line",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig,
            'WHERE(Type=FILTER(Item))');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Document No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Line No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document Line No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Qty. to Receive (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Transfer-to Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempTransferline.FieldNo("Description"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Description"),
            '');
    end;

    local procedure CreateDefaultAssemblyOutputToInspectConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        EnsureSourceConfigExists(
            AssemblyOutputToInspectTok,
            AssemblyOutputToInspectDescriptionTxt,
            Database::"Posted Assembly Header",
            Database::"Qlty. Inspection Header",
            QltyInspectSourceConfig);
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Location Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Location Code"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Item No."),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo(Description),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo(Description),
            '');
        EnsureSourceConfigLineExists(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Header",
            TempQltyInspectionHeader.FieldNo("Source Variant Code"),
            '');
    end;

    local procedure EnsureSourceConfigExists(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.")
    begin
        EnsureSourceConfigWithTrackFlagExists(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            false);
    end;

    local procedure EnsureSourceConfigWithTrackFlagExists(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; TrackingOnly: Boolean)
    begin
        EnsureSourceConfigWithFilterAndTrackFlagExists(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            '',
            TrackingOnly);
    end;

    local procedure EnsureSourceConfigWithFilterExists(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFilter: Text)
    begin
        EnsureSourceConfigWithFilterAndTrackFlagExists(
            Name,
            Description,
            FromTable,
            ToTable,
            QltyInspectSourceConfig,
            FromFilter,
            false);
    end;

    local procedure EnsureSourceConfigWithFilterAndTrackFlagExists(Name: Text; Description: Text; FromTable: Integer; ToTable: Integer; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFilter: Text; TrackingOnly: Boolean)
    begin
        QltyInspectSourceConfig.Reset();
        if not QltyInspectSourceConfig.Get(CopyStr(Name, 1, MaxStrLen(QltyInspectSourceConfig.Code))) then begin
            QltyInspectSourceConfig.Init();
            QltyInspectSourceConfig.Code := CopyStr(Name, 1, MaxStrLen(QltyInspectSourceConfig.Code));
            QltyInspectSourceConfig.Description := CopyStr(Description, 1, MaxStrLen(QltyInspectSourceConfig.Description));
            QltyInspectSourceConfig."From Table Filter" := CopyStr(FromFilter, 1, MaxStrLen(QltyInspectSourceConfig."From Table Filter"));
            QltyInspectSourceConfig.Validate("From Table No.", FromTable);
            if ToTable = Database::"Qlty. Inspection Header" then
                QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::Inspection
            else
                if TrackingOnly then
                    QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::"Item Tracking"
                else
                    QltyInspectSourceConfig."To Type" := QltyInspectSourceConfig."To Type"::"Chained table";

            QltyInspectSourceConfig.Validate("To Table No.", ToTable);
            QltyInspectSourceConfig.Insert();
        end;
    end;

    local procedure EnsureSourceConfigLineExists(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text)
    begin
        EnsureSourceConfigLineWithTrackFlagExists(
            QltyInspectSourceConfig,
            FromField,
            ToTable,
            ToField,
            OptionalOverrideDisplay,
            false);
    end;

    local procedure EnsureSourceConfigLineWithTrackFlagExists(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text; TrackingOnly: Boolean)
    var
        QltyConfigTestPriority: Enum "Qlty. Config. Test Priority";
    begin
        EnsurePrioritizedSourceConfigLineWithTrackFlagExists(QltyInspectSourceConfig, FromField, ToTable, ToField, OptionalOverrideDisplay, TrackingOnly, QltyConfigTestPriority::Normal);
    end;

    local procedure EnsurePrioritizedSourceConfigLineWithTrackFlagExists(QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromField: Integer; ToTable: Integer; ToField: Integer; OptionalOverrideDisplay: Text; TrackingOnly: Boolean; QltyConfigTestPriority: Enum "Qlty. Config. Test Priority")
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

            if ToTable = Database::"Qlty. Inspection Header" then
                QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::Inspection
            else
                if TrackingOnly then
                    QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::"Item Tracking"
                else
                    QltyInspectSrcFldConf."To Type" := QltyInspectSrcFldConf."To Type"::"Chained table";

            QltyInspectSrcFldConf."To Table No." := ToTable;
            QltyInspectSrcFldConf."To Field No." := ToField;
            QltyInspectSrcFldConf."Display As" := CopyStr(OptionalOverrideDisplay, 1, MaxStrLen(QltyInspectSrcFldConf."Display As"));
            QltyInspectSrcFldConf."Priority Test" := QltyConfigTestPriority;
            QltyInspectSrcFldConf.Insert();
        end;
    end;
}
