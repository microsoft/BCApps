// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;

/// <summary>
/// Contains helper functions to use for automatic configuration.
/// </summary>
codeunit 20422 "Qlty. Auto Configure - Mfg"
{
    var
        ProdLineToTrackingTok: Label 'TRACKINGTOPROD', Locked = true;
        ProdLineToTrackingDescriptionTok: Label 'Tracking Specification to Prod. Order Line', Locked = true;
        ProdJnlToTestTok: Label 'PRODJNLTOTEST', Locked = true;
        ProdJnlToTestDescriptionTok: Label 'Production Output Journal to Test', Locked = true;
        RtngToItemJnlTok: Label 'ROUTINGLINETOITEMJNL', Locked = true;
        RtngToItemJnlDescriptionTok: Label 'Prod. Routing Line to Item Journal Line', Locked = true;
        ProdLineToJnlTok: Label 'PRODLINETOITEMJNL', Locked = true;
        ProdLineToJnlDescriptionTok: Label 'Prod. Order Line to Item Journal Line', Locked = true;
        ProdLineToRoutingTok: Label 'PRODLINETOROUTING', Locked = true;
        ProdLineToRoutingDescriptionTok: Label 'Prod. Order Line to Prod. Rtng.', Locked = true;
        ProdLineToLedgerTok: Label 'PRODLINETOITEMLEDGER', Locked = true;
        ProdLineToLedgerDescriptionTok: Label 'Prod. Order Line to Item Ledger Entry.', Locked = true;
        ProdRoutingToTestTok: Label 'ROUTINGTOTEST', Locked = true;
        ProdRoutingToTestDescriptionTok: Label 'Prod. Order Routing Line to Test', Locked = true;
        LedgerToTestTok: Label 'ITEMLDGEROUTTOTEST', Locked = true;
        LedgerToTestDescriptionTok: Label 'Output Item Ledger to Test', Locked = true;
        AssemblyOutputToTestTok: Label 'ASSEMBLYOUTPUTTOTEST', Locked = true;
        AssemblyOutputToTestDescriptionTok: Label 'Posted Assembly Header to Test', Locked = true;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Auto Configure", OnAfterEnsureAtLeastOneSourceConfiguration, '', false, false)]
    local procedure OnAfterEnsureAtLeastOneSourceConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    begin
        CreateDefaultProductionConfiguration(QltyAutoConfigure);
    end;

    internal procedure CreateDefaultProductionConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    begin
        CreateDefaultProdOrderRoutingLineToTestConfiguration(QltyAutoConfigure);
        CreateDefaultProdOrderLineToProdOrderRoutingConfiguration(QltyAutoConfigure);

        CreateDefaultItemLedgerOutputToTestConfiguration(QltyAutoConfigure);
        CreateDefaultProdOrderLineToItemLedgerConfiguration(QltyAutoConfigure);

        CreateDefaultItemProdJournalToTestConfiguration(QltyAutoConfigure);
        CreateDefaultProdOrderLineToItemJournalLineConfiguration(QltyAutoConfigure);
        CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration(QltyAutoConfigure);
        CreateDefaultTrackingSpecificationToProdConfiguration(QltyAutoConfigure);
        CreateDefaultAssemblyOutputToTestConfiguration(QltyAutoConfigure);
    end;

    local procedure CreateDefaultTrackingSpecificationToProdConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilterAndTrackFlag(
            ProdLineToTrackingTok,
            ProdLineToTrackingDescriptionTok,
            Database::"Tracking Specification",
            Database::"Prod. Order Line",
            QltyInspectSourceConfig,
            'WHERE(Source Type=CONST(5406))',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Subtype"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo(Status),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source ID"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Prod. Order No."),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Source Prod. Order Line"),
            Database::"Prod. Order Line",
            TempProdOrderLine.FieldNo("Line No."),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
               '',
            true);
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempTrackingSpecification.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '',
            true);
    end;

    local procedure CreateDefaultItemProdJournalToTestConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        ConfigFieldPriority: Enum "Qlty. Config. Field Priority";
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilter(
            ProdJnlToTestTok,
            ProdJnlToTestDescriptionTok,
            Database::"Item Journal Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        QltyAutoConfigure.EnsureSourceConfigLine(
        QltyInspectSourceConfig,
        TempItemJournalLine.FieldNo("Order No."),
        Database::"Qlty. Inspection Test Header",
        TempQltyInspectionTestHeader.FieldNo("Source Document No."),
        '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Task No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        QltyAutoConfigure.EnsurePrioritizedSourceConfigLineWithTrackFlag(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '',
            false,
            ConfigFieldPriority::Priority);
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemJournalLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultItemLedgerOutputToTestConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilter(
            LedgerToTestTok,
            LedgerToTestDescriptionTok,
            Database::"Item Ledger Entry",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig,
            'WHERE(Entry Type=FILTER(Output),Order Type=FILTER(Production))');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Order Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Quantity),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Lot No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Lot No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Serial No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Serial No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Package No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Package No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo(Description),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo(Description),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempItemLedgerEntry.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToItemJournalLineConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilter(
            RtngToItemJnlTok,
            RtngToItemJnlDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Routing Reference No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Operation No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemJournalLineConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilter(
            ProdLineToJnlTok,
            ProdLineToJnlDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Journal Line",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Order Line No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Journal Line",
            TempItemJournalLine.FieldNo("Item No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemJournalLine.FieldNo("Variant Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToItemLedgerConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfigWithFilter(
            ProdLineToLedgerTok,
            ProdLineToLedgerDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Item Ledger Entry",
            QltyInspectSourceConfig,
            'WHERE(Status=FILTER(Released))');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Order Line No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Item No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Item Ledger Entry",
            TempItemLedgerEntry.FieldNo("Variant Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
    end;

    local procedure CreateDefaultProdOrderRoutingLineToTestConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfig(
            ProdRoutingToTestTok,
            ProdRoutingToTestDescriptionTok,
            Database::"Prod. Order Routing Line",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig);
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Type"),
            ' ');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo(Status),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Custom 1"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Operation No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Task No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Description"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Description"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderRoutingLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultProdOrderLineToProdOrderRoutingConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfig(
            ProdLineToRoutingTok,
            ProdLineToRoutingDescriptionTok,
            Database::"Prod. Order Line",
            Database::"Prod. Order Routing Line",
            QltyInspectSourceConfig);
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Status"),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Status"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Prod. Order No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Prod. Order No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Routing Reference No."),
            Database::"Prod. Order Routing Line",
            TempProdOrderRoutingLine.FieldNo("Routing Reference No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Line No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document Line No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempProdOrderLine.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
    end;

    local procedure CreateDefaultAssemblyOutputToTestConfiguration(QltyAutoConfigure: Codeunit "Qlty. Auto Configure")
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        QltyAutoConfigure.EnsureSourceConfig(
            AssemblyOutputToTestTok,
            AssemblyOutputToTestDescriptionTok,
            Database::"Posted Assembly Header",
            Database::"Qlty. Inspection Test Header",
            QltyInspectSourceConfig);
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Document No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Location Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Location Code"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Quantity (Base)"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Quantity (Base)"),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Item No."),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Item No."),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo(Description),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo(Description),
            '');
        QltyAutoConfigure.EnsureSourceConfigLine(
            QltyInspectSourceConfig,
            TempPostedAssemblyHeader.FieldNo("Variant Code"),
            Database::"Qlty. Inspection Test Header",
            TempQltyInspectionTestHeader.FieldNo("Source Variant Code"),
            '');
    end;
}