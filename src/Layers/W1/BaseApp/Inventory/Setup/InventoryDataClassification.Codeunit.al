// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing.ActionMessage;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1764 "Inventory-Data Classification"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyTables()
    begin
        ClassifyTables();
    end;

    local procedure ClassifyTables()
    begin
        ClassifyInventoryPeriodEntry();
        ClassifyMyItem();
        ClassifyAnalysisSelectedDimension();
        ClassifyItemAnalysisViewBudgEntry();
        ClassifyItemAnalysisViewEntry();
        ClassifyItemApplicationEntryHistory();
        ClassifyItemApplicationEntry();
        ClassifyItemBudgetEntry();
        ClassifyInventoryEventBuffer();
        ClassifyItemRegister();
        ClassifyItemLedgerEntry();
        ClassifyItemTracingBuffer();
        ClassifyItem();
        ClassifyManufacturingUserTemplate();
#if CLEAN26
        ClassifyCapacityLedgerEntry();
#endif
        ClassifyPhysInventoryLedgerEntry();
        ClassifyRequisitionLine();
        ClassifyReservationEntry();
        ClassifyValueEntry();
        ClassifyInventoryPageData();
        ClassifyTimelineEvent();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Location);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Translation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Journal Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Journal Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"BOM Component");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Vendor");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Journal Batch");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Req. Wksh. Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Requisition Wksh. Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transaction Type");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transport Method");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Tariff Number");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Amount");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Area);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transaction Specification");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Territory);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Tracking Specification");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Discount Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Availability at Date");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Item Journal");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Item Journal Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Item Templ.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Variant");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Unit of Measure");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Planning Error Log");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Substitution");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Substitution Condition");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Reference");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Nonstock Item");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Nonstock Item Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Manufacturer);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::Purchasing);
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Category");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Route");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Shipment Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Shipment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Receipt Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Receipt Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Stockkeeping Unit");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Stockkeeping Unit Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Responsibility Center");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Charge");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Posting Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Period");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"G/L - Item Ledger Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Availability Calc. Overview");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Report Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Average Cost Calc. Overview");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"BOM Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Memoized Result");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Availability by Date");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"BOM Warning Log");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Tracking Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Tracking Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Serial No. Information");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Lot No. Information");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Package No. Information");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Tracking Comment");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Field Value");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Report Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Line Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Type");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Column Template");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Column");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Budget Name");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Analysis View");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Order Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Order Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Record Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Record Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Order Hdr");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Order Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Record Hdr");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Record Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd. Phys. Invt. Tracking");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Order Tracking");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Exp. Invt. Order Tracking");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Pstd.Exp.Invt.Order.Tracking");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Count Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Document Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Receipt Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Receipt Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Document Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Shipment Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Invt. Shipment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Direct Trans. Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Direct Trans. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Analysis View Filter");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Allocation Policy");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reservation Wksh. Batch");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reservation Wksh. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reservation Worksheet Log");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Item Selection");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Phys. Invt. Counting Period");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attribute");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attribute Value");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attribute Translation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attr. Value Translation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attribute Value Selection");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Attribute Value Mapping");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Planning Component");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Availability Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Planning Assignment");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Profile");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Untracked Planning Element");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Order Promising Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Order Promising Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Entry/Exit Point");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Entry Summary");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Report Chart Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Analysis Report Chart Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Transfer Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Avg. Cost Adjmt. Entry Point");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Post Value Entry to G/L");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Report Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Inventory Adjmt. Entry (Order)");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Cost Adj. Item Bucket");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Cost Adjmt. Action Message");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Cost Adjustment Detailed Log");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Cost Adjustment Log");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Cost Adjustment Trace Log");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Entry Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Value Entry Relation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Action Message Entry");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Picture Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Availability Info. Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Unplanned Demand");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Timeline Event Change");
    end;

    local procedure ClassifyInventoryEventBuffer()
    var
        DummyInventoryEventBuffer: Record "Inventory Event Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Event Buffer";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryEventBuffer.FieldNo("Source Line ID"));
    end;

    local procedure ClassifyItemTracingBuffer()
    var
        DummyItemTracingBuffer: Record "Item Tracing Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Tracing Buffer";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemTracingBuffer.FieldNo("Record Identifier"));
    end;

    local procedure ClassifyInventoryPeriodEntry()
    var
        DummyInventoryPeriodEntry: Record "Inventory Period Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Period Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Closing Item Register No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Creation Time"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Creation Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyInventoryPeriodEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Ending Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPeriodEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyMyItem()
    var
        DummyMyItem: Record "My Item";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Item";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyItem.FieldNo("User ID"));
    end;

    local procedure ClassifyAnalysisSelectedDimension()
    var
        DummyAnalysisSelectedDimension: Record "Analysis Selected Dimension";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Analysis Selected Dimension";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyAnalysisSelectedDimension.FieldNo("User ID"));
    end;

    local procedure ClassifyItemAnalysisViewBudgEntry()
    var
        DummyItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Analysis View Budg. Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Cost Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Sales Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 3 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 2 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Dimension 1 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Budget Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Analysis View Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewBudgEntry.FieldNo("Analysis Area"));
    end;

    local procedure ClassifyItemAnalysisViewEntry()
    var
        DummyItemAnalysisViewEntry: Record "Item Analysis View Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Analysis View Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Expected)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Sales Amount (Expected)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Non-Invtbl.)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Cost Amount (Actual)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Sales Amount (Actual)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Invoiced Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Item Ledger Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 3 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 2 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Dimension 1 Value Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Analysis View Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemAnalysisViewEntry.FieldNo("Analysis Area"));
    end;

    local procedure ClassifyItemBudgetEntry()
    var
        DummyItemBudgetEntry: Record "Item Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Budget Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 3 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemBudgetEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Sales Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Cost Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo(Date));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Budget Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Analysis Area"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyItemApplicationEntryHistory()
    var
        DummyItemApplicationEntryHistory: Record "Item Application Entry History";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Application Entry History";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Output Completely Invd. Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Deleted By User"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Deleted Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Last Modified By User"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Last Modified Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemApplicationEntryHistory.FieldNo("Created By User"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Creation Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Transferred-from Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Primary Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Outbound Item Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Inbound Item Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Item Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntryHistory.FieldNo("Cost Application"));
    end;

    local procedure ClassifyItemApplicationEntry()
    var
        DummyItemApplicationEntry: Record "Item Application Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Application Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Outbound Entry is Updated"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Output Completely Invd. Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemApplicationEntry.FieldNo("Last Modified By User"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Last Modified Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemApplicationEntry.FieldNo("Created By User"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Creation Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Transferred-from Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Outbound Item Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Inbound Item Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Item Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemApplicationEntry.FieldNo("Cost Application"));
    end;

    local procedure ClassifyReservationEntry()
    var
        DummyReservationEntry: Record "Reservation Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reservation Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Lot No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("New Serial No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item Tracking"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Correction));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Lot No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Quantity Invoiced (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. to Invoice (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. to Handle (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Warranty Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Appl.-to Item Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Planning Flexibility"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Suppressed Action Msg."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Binding));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReservationEntry.FieldNo("Changed By"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Appl.-from Item Entry"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReservationEntry.FieldNo("Created By"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Serial No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Shipment Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Expected Receipt Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Ref. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Prod. Order Line"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Subtype"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Transferred from Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Creation Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Disallow Cancellation"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Reservation Status"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Quantity (Base)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReservationEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyPhysInventoryLedgerEntry()
    var
        DummyPhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Phys. Inventory Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Phys Invt Counting Period Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Phys Invt Counting Period Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Last Item Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Qty. (Phys. Inventory)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Qty. (Calculated)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Salespers./Purch. Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Unit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Inventory Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPhysInventoryLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyTimelineEvent()
    var
        DummyTimelineEvent: Record "Timeline Event";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Timeline Event";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyTimelineEvent.FieldNo("Source Line ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyTimelineEvent.FieldNo("Source Document ID"));
    end;

    local procedure ClassifyInventoryPageData()
    var
        DummyInventoryPageData: Record "Inventory Page Data";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Inventory Page Data";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPageData.FieldNo("Source Line ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyInventoryPageData.FieldNo("Source Document ID"));
    end;

    local procedure ClassifyValueEntry()
    var
        DummyValueEntry: Record "Value Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Value Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Exp. Cost Posted to G/L (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Expected Cost Posted to G/L"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Non-Invtbl.)(ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Expected) (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Non-Invtbl.)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Expected)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Sales Amount (Expected)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Purchase Amount (Expected)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Purchase Amount (Actual)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Capacity Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Adjustment));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Variance Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valuation Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Inventoriable));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Partial Revaluation"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Return Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valued By Average Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Charge No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Expected Cost"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Order Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost per Unit (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Posted to G/L (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Actual) (ACY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Gen. Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Gen. Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Drop Shipment"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Posted to G/L"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost Amount (Actual)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Applies-to Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyValueEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Discount Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Salespers./Purch. Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Average Cost Exception"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Sales Amount (Actual)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Job Task No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Cost per Unit"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Invoiced Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Valued Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Inventory Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item Ledger Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyValueEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyRequisitionLine()
    var
        DummyRequisitionLine: Record "Requisition Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Requisition Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyRequisitionLine.FieldNo("User ID"));
    end;

    local procedure ClassifyItemRegister()
    var
        DummyItemRegister: Record "Item Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Register";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItemRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyItemLedgerEntry()
    var
        DummyItemLedgerEntry: Record "Item Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Item Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Serial No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Purchasing Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Nonstock));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Category Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Out-of-Stock Substitution"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Originally Ordered Var. Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Originally Ordered No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Reference No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Prod. Order Comp. Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Assemble to Order"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Return Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Shipped Qty. Not Returned"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Correction));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Applied Entry to Adjust"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Last Invoice Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Completely Invoiced"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Order No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transaction Specification"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Area));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry/Exit Point"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transport Method"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Transaction Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Drop Shipment"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Derived from Blanket Order"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Source Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Open));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Applies-to Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job Purchase"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job Task No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Job No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Invoiced Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Remaining Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Warranty Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item Tracking"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Location Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Source No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyItemLedgerEntry.FieldNo("Lot No."));
    end;

    local procedure ClassifyItem()
    var
        DummyItem: Record Item;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Item;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyItem.FieldNo("Application Wksh. User ID"));
    end;

    local procedure ClassifyManufacturingUserTemplate()
    var
        DummyManufacturingUserTemplate: Record "Manufacturing User Template";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Manufacturing User Template";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyManufacturingUserTemplate.FieldNo("User ID"));
    end;

#if CLEAN26
    local procedure ClassifyCapacityLedgerEntry()
    var
        DummyCapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Subcontracting));

        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Variant Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Item No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Completely Invoiced"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Qty. per Cap. Unit of Measure"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Cap. Unit of Measure Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Order Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Invoiced Quantity"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Quantity));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCapacityLedgerEntry.FieldNo("Entry No."));
    end;
#endif
}
