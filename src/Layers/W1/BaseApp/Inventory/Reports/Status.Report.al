// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 706 Status
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/Status.rdlc';
    ApplicationArea = Basic, Suite, Advanced;
    Caption = 'Status';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
            column(AsofStatusDate; StrSubstNo(Text000, Format(StatusDate)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(CostingMethod_Item; "Costing Method")
            {
                IncludeCaption = true;
            }
            column(InvtValue; InvtValue)
            {
                AutoFormatType = 1;
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
            }
            column(StatusCaption; StatusCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(InventoryValuationCaption; InventoryValuationCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(HereofPositiveCaption; HereofPositiveCaptionLbl)
            {
            }
            column(HereofNegativeCaption; HereofNegativeCaptionLbl)
            {
            }
            column(IsAverageCostItem; IsAverageCostItem)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");
                column(PostingDate_ItemLedgerEntry; Format("Posting Date"))
                {
                }
                column(EntryType_ItemLedgerEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }
                column(RemainingQty; RemainingQty)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(UnitCost; UnitCost)
                {
                    AutoFormatType = 2;
                }
                column(InvtValue2; InvtValue)
                {
                    AutoFormatType = 1;
                }
                column(DocumentNo_ItemLedgerEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Description2_Item; Item.Description)
                {
                }
                column(AvgCost; AvgCost)
                {
                    AutoFormatType = 2;
                }

                trigger OnAfterGetRecord()
                begin
                    if Item."Costing Method" = Item."Costing Method"::Average then
                        RemainingQty := Quantity
                    else begin
                        CalcRemainingQty();
                        if RemainingQty = 0 then
                            CurrReport.Skip();
                    end;

                    CalcUnitCost();
                    InvtValue := UnitCost * Abs(RemainingQty);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, StatusDate);
                    SetRange("Drop Shipment", false);

                    Clear(RemainingQty);
                    Clear(InvtValue);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IsAverageCostItem := "Costing Method" = "Costing Method"::Average;
            end;

            trigger OnPreDataItem()
            begin
                Clear(RemainingQty);
                Clear(InvtValue);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Status';
        AboutText = 'Helps you monitor and manage your inventory operations effectively by providing real-time insights into the current state of your inventory. Might allow you to optimize your supply chain processes and reduce cost associated with inventory.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StatusDate; StatusDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status Date';
                        ToolTip = 'Specifies the status date.';

                        trigger OnValidate()
                        begin
                            if StatusDate = 0D then
                                Error(Text001);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StatusDate = 0D then
                StatusDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Posting Date", 0D, StatusDate);
        ValueEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ValueEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
    end;

    var
        ValueEntry: Record "Value Entry";
        StatusDate: Date;
        ItemFilter: Text;
        InvtValue: Decimal;
        UnitCost: Decimal;
        RemainingQty: Decimal;
        AvgCost: Decimal;
        StatusCaptionLbl: Label 'Status';
        PageCaptionLbl: Label 'Page';
        UnitCostCaptionLbl: Label 'Unit Cost';
        PostingDateCaptionLbl: Label 'Posting Date';
        QuantityCaptionLbl: Label 'Quantity';
        InventoryValuationCaptionLbl: Label 'Inventory Valuation';
        TotalCaptionLbl: Label 'Total';
        HereofPositiveCaptionLbl: Label 'Hereof Positive';
        HereofNegativeCaptionLbl: Label 'Hereof Negative';
        IsAverageCostItem: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'As of %1';
#pragma warning restore AA0470
        Text001: Label 'Enter the Status Date';
#pragma warning restore AA0074

    local procedure CalcRemainingQty()
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        RemainingQty := "Item Ledger Entry".Quantity;

        if "Item Ledger Entry".Positive then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.SetCurrentKey(
              "Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
            ItemApplnEntry.SetRange("Inbound Item Entry No.", "Item Ledger Entry"."Entry No.");
            ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            ItemApplnEntry.SetRange("Posting Date", 0D, StatusDate);
            if ItemApplnEntry.Find('-') then
                repeat
                    SumQty(RemainingQty, ItemApplnEntry."Outbound Item Entry No.", ItemApplnEntry.Quantity);
                until ItemApplnEntry.Next() = 0;
        end else begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", "Item Ledger Entry"."Entry No.");
            ItemApplnEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            ItemApplnEntry.SetRange("Posting Date", 0D, StatusDate);
            if ItemApplnEntry.Find('-') then
                repeat
                    SumQty(RemainingQty, ItemApplnEntry."Inbound Item Entry No.", -ItemApplnEntry.Quantity);
                until ItemApplnEntry.Next() = 0;
        end;
    end;

    local procedure SumQty(var RemainingQty: Decimal; EntryNo: Integer; AppliedQty: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        if (ItemLedgEntry.Quantity * AppliedQty < 0) or
           (ItemLedgEntry."Posting Date" > StatusDate)
        then
            exit;

        RemainingQty := RemainingQty + AppliedQty;
    end;

    local procedure CalcUnitCost()
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        UnitCost := 0;

        if ValueEntry.Find('-') then
            repeat
                if ValueEntry."Partial Revaluation" then
                    SumUnitCost(UnitCost, ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)", ValueEntry."Valued Quantity")
                else
                    SumUnitCost(UnitCost, ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)", "Item Ledger Entry".Quantity);
            until ValueEntry.Next() = 0;
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    procedure InitializeRequest(NewStatusDate: Date)
    begin
        StatusDate := NewStatusDate;
    end;
}

