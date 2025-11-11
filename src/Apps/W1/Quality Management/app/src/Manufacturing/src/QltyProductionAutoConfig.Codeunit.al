// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;

/// <summary>
/// Contains production-related automatic configuration for Quality Management.
/// </summary>
codeunit 20422 "Qlty. Production Auto Config."
{
    var
        ProdLineToTrackingTok: Label 'TRACKINGTOPROD', Locked = true;
        ProdLineToTrackingDescriptionTok: Label 'Tracking Specification to Production Order Line', Locked = true;
        ProdJnlToTestTok: Label 'PRODJNLTOTEST', Locked = true;
        ProdJnlToTestDescriptionTok: Label 'Production Journal to Test', Locked = true;
        LedgerToTestTok: Label 'LEDGERTOTEST', Locked = true;
        LedgerToTestDescriptionTok: Label 'Output Ledger to Test', Locked = true;
        RtngToItemJnlTok: Label 'RTNGTOITEMJNL', Locked = true;
        RtngToItemJnlDescriptionTok: Label 'Prod. Order Routing Line to Item Journal Line', Locked = true;
        ProdLineToJnlTok: Label 'PRODLINETOJNL', Locked = true;
        ProdLineToJnlDescriptionTok: Label 'Prod. Order Line to Item Journal Line', Locked = true;
        ProdLineToRoutingTok: Label 'PRODLINETOROUTING', Locked = true;
        ProdLineToRoutingDescriptionTok: Label 'Prod. Order Line to Prod. Order Routing Line', Locked = true;
        ProdLineToLedgerTok: Label 'PRODLINETOLEDGER', Locked = true;
        ProdLineToLedgerDescriptionTok: Label 'Prod. Order Line to Item Ledger', Locked = true;
        ProdRoutingToTestTok: Label 'PRODROUTINGTOTEST', Locked = true;
        ProdRoutingToTestDescriptionTok: Label 'Prod. Order Routing Line to Test', Locked = true;

    /// <summary>
    /// Creates default production-related configuration.
    /// </summary>
    internal procedure CreateDefaultProductionConfiguration()
    begin
        CreateDefaultTrackingSpecificationToProdConfiguration();
        CreateDefaultItemProdJournalToTestConfiguration();
        CreateDefaultItemLedgerOutputToTestConfiguration();
        CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration();
        CreateDefaultProdOrderLineToItemJournalLineConfiguration();
        CreateDefaultProdOrderLineToItemLedgerConfiguration();
        CreateDefaultProdOrderRoutingLineToTestConfiguration();
        CreateDefaultProdOrderLineToProdOrderRoutingConfiguration();
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
            TempTrackingSpecification.FieldNo("Source Ref. No."),
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
            TempItemJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Output Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        EnsurePrioritizedSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '',
            false,
            ConfigFieldPriority::Priority);
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
            TempItemLedgerEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            RtngToItemJnlTok,
            RtngToItemJnlDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Operation No."),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemJournalLineConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdLineToJnlTok,
            ProdLineToJnlDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            '');
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
    end;

    local procedure CreateDefaultProdOrderLineToItemLedgerConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdLineToLedgerTok,
            ProdLineToLedgerDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Ledger Entry",
            QltyInspectSourceConfig,
            '');
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
    end;

    local procedure CreateDefaultProdOrderRoutingLineToTestConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdRoutingToTestTok,
            ProdRoutingToTestDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Task No."),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToProdOrderRoutingConfiguration()
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        EnsureSourceConfigWithFilter(
            ProdLineToRoutingTok,
            ProdLineToRoutingDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Prod. Order Routing Line",
            QltyInspectSourceConfig,
            '');
        EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo(Status),
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
    end;

    local procedure EnsureSourceConfigWithFilter(SourceConfigCode: Text; SourceConfigDescription: Text; FromTableID: Integer; ToTableID: Integer; var OutQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; TableViewString: Text)
    begin
        EnsureSourceConfigWithFilterAndTrackFlag(SourceConfigCode, SourceConfigDescription, FromTableID, ToTableID, OutQltyInspectSourceConfig, TableViewString, false);
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

    local procedure EnsureSourceConfigLine(var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFieldNo: Integer; ToTableID: Integer; ToFieldNo: Integer; FieldFilter: Text)
    var
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        EnsurePrioritizedSourceConfigLineWithTrackFlag(QltyInspectSourceConfig, FromFieldNo, ToTableID, ToFieldNo, FieldFilter, false, ConfigFieldPriority::Normal);
    end;

    local procedure EnsureSourceConfigLineWithTrackFlag(var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromFieldNo: Integer; ToTableID: Integer; ToFieldNo: Integer; FieldFilter: Text; IsForTrackingSpecification: Boolean)
    var
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        EnsurePrioritizedSourceConfigLineWithTrackFlag(QltyInspectSourceConfig, FromFieldNo, ToTableID, ToFieldNo, FieldFilter, IsForTrackingSpecification, ConfigFieldPriority::Normal);
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
    /// Event subscriber that creates production configurations when the base app creates default configurations.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Auto Configure", 'OnAfterEnsureAtLeastOneSourceConfiguration', '', false, false)]
    local procedure OnAfterEnsureAtLeastOneSourceConfiguration(ForceAll: Boolean)
    begin
        CreateDefaultProductionConfiguration();
    end;
}
