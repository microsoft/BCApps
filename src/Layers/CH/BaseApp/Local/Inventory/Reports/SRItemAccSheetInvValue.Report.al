// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 11506 "SR Item Acc Sheet Inv. Value"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/SRItemAccSheetInvValue.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Acc Sheet Inventory Value';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Vendor No.", "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodDateFilterText; Text002 + DateFilterText)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(NewPagePerAccount; NewPagePerAccount)
            {
            }
            column(Description_Item; Description)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ItemAccountSheetCaption; ItemAccountSheetCaptionLbl)
            {
            }
            column(SRIAccSheetInvValueCaption; SRIAccSheetInvValueCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(UnitPriceCaption; UnitPriceCaptionLbl)
            {
            }
            column(InvQtyCaption; InvQtyCaptionLbl)
            {
            }
            column(CostCaption; CostCaptionLbl)
            {
            }
            column(QtyUnitCaption; QtyUnitCaptionLbl)
            {
            }
            column(UnitCaption; UnitCaptionLbl)
            {
            }
            column(VarCaption; VarCaptionLbl)
            {
            }
            column(DocCaption; DocCaptionLbl)
            {
            }
            column(PostDatCaption; PostDatCaptionLbl)
            {
            }
            column(StockValueCaption; StockValueCaptionLbl)
            {
            }
            column(ValuepostedCaption; ValuepostedCaptionLbl)
            {
            }
            dataitem(StartBalanceItemEntry; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Entry Type", "Variant Code", "Location Code", "Source Type", "Source No.", Open;
                column(StartBalanceTxt; StartBalanceTxt)
                {
                }
                column(TotalValueAdjusted; TotalValueAdjusted)
                {
                }
                column(TotalValuePosted; TotalValuePosted)
                {
                }
                column(ItemNo_StartBalanceItemEntry; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcValues(StartBalanceItemEntry);
                end;

                trigger OnPreDataItem()
                begin
                    // Opening balance
                    IncreaseQty := 0;
                    DecreaseQty := 0;
                    Stock := 0;
                    TotalValueAdjusted := 0;
                    TotalValuePosted := 0;

                    SetRange("Item No.", Item."No.");
                    if StartDate > 0D then
                        SetRange("Posting Date", 0D, StartDate - 1)
                    else
                        CurrReport.Break();
                end;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Entry No.");
                column(ItemNo; Item."No.")
                {
                }
                column(SalesAmountActual_ItemLedgerEntry; "Sales Amount (Actual)")
                {
                }
                column(PricePerUnit; PricePerUnit)
                {
                }
                column(InvoicedQuantity_ItemLedgerEntry; "Invoiced Quantity")
                {
                }
                column(CostPerUnit; CostPerUnit)
                {
                }
                column(QtyperUnitofMeasure_ItemLedgerEntry; "Qty. per Unit of Measure")
                {
                }
                column(UnitofMeasureCode_ItemLedgerEntry; "Unit of Measure Code")
                {
                }
                column(VariantCode_ItemLedgerEntry; "Variant Code")
                {
                }
                column(DocumentNo_ItemLedgerEntry; "Document No.")
                {
                }
                column(EntryTypeFormatted; CopyStr(Format("Entry Type"), 1, 1))
                {
                }
                column(PostingDateFormatted; Format("Posting Date"))
                {
                }
                column(CostAmountActual_ItemLedgerEntry; "Cost Amount (Actual)")
                {
                }
                column(ValuePosted; ValuePosted)
                {
                }
                column(ItemNo_ItemLedgerEntry; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Invoiced Quantity" = 0 then
                        CurrReport.Skip();
                    if Quantity = 0 then
                        CurrReport.Skip();

                    CalcValues("Item Ledger Entry");

                    EntryNo := EntryNo + 1;
                end;

                trigger OnPreDataItem()
                begin
                    EntryNo := 0;

                    // Filter from item entry
                    CopyFilters(StartBalanceItemEntry);
                    Item.CopyFilter("Date Filter", "Posting Date");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TotalValuePosted_Integer; TotalValuePosted)
                {
                }
                column(TotalValueAdjusted_Integer; TotalValueAdjusted)
                {
                }
                column(EndBalanceCaption; EndBalanceCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                // Pagebreak except on page 1
                if not (NotFirstPage and NewPagePerAccount) then
                    NotFirstPage := true;
            end;

            trigger OnPreDataItem()
            begin
                // Prepare start and enddate if date filter. Date filter needs start date
                DateFilterText := GetFilter("Date Filter");
                if DateFilterText <> '' then
                    if GetRangeMin("Date Filter") <> 0D then begin
                        StartDate := GetRangeMin("Date Filter");
                        StartBalanceTxt := Text001 + '  ' + Format(StartDate);
                    end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPagePerAccount; NewPagePerAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Account';
                        ToolTip = 'Specifies if you want to print a new page for each account.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        NotFirstPage: Boolean;
        DateFilterText: Text[30];
        StartBalanceTxt: Text[80];
        StartDate: Date;
        NewPagePerAccount: Boolean;
        EntryNo: Integer;
        IncreaseQty: Decimal;
        DecreaseQty: Decimal;
        Stock: Decimal;
        Text001: Label 'Opening balance on ';
        ValuePosted: Decimal;
        PricePerUnit: Decimal;
        CostPerUnit: Decimal;
        TotalValuePosted: Decimal;
        TotalValueAdjusted: Decimal;
        Text002: Label 'Period: ';
        PageCaptionLbl: Label 'Page';
        ItemAccountSheetCaptionLbl: Label 'Item Account Sheet';
        SRIAccSheetInvValueCaptionLbl: Label 'SR Item Acc Sheet Inv. Value';
        AmountCaptionLbl: Label 'Amount';
        UnitPriceCaptionLbl: Label 'Unit Price';
        InvQtyCaptionLbl: Label 'Inv. Qty.';
        CostCaptionLbl: Label 'Cost';
        QtyUnitCaptionLbl: Label 'Qty/Unit';
        UnitCaptionLbl: Label 'Unit';
        VarCaptionLbl: Label 'Var.';
        DocCaptionLbl: Label 'Doc.';
        PostDatCaptionLbl: Label 'Post. Dat.';
        StockValueCaptionLbl: Label 'Stock Value';
        ValuepostedCaptionLbl: Label 'Value posted';
        EndBalanceCaptionLbl: Label 'End Balance';

    [Scope('OnPrem')]
    procedure CalcValues(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        // Increase / decrease qty.
        if ItemLedgerEntry.Quantity > 0 then
            IncreaseQty := IncreaseQty + ItemLedgerEntry.Quantity
        else
            DecreaseQty := DecreaseQty + Abs(ItemLedgerEntry.Quantity);
        Stock := Stock + ItemLedgerEntry.Quantity;
        // Price per unit and amounts
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");
        if ItemLedgerEntry."Invoiced Quantity" <> 0 then begin
            PricePerUnit := ItemLedgerEntry."Sales Amount (Actual)" / ItemLedgerEntry."Invoiced Quantity";
            CostPerUnit := ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry."Invoiced Quantity";
            OnCalcValuesOnAfterCalcPriceAndCostPerUnit(ItemLedgerEntry, PricePerUnit, CostPerUnit);
        end;
        // Value posted
        ValuePosted := 0;
        // ValueEntry.SETCURRENTKEY("Item Ledger Entry No.","Expected Cost","Document No.",
        // "Partial Revaluation","Entry Type","Variance Type",Adjustment);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");

        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Expected Cost", false);

        if ValueEntry.Find('-') then
            repeat
                ValuePosted := ValuePosted + ValueEntry."Cost Posted to G/L";
            until ValueEntry.Next() = 0;

        TotalValuePosted := TotalValuePosted + ValuePosted;
        TotalValueAdjusted := TotalValueAdjusted + ItemLedgerEntry."Cost Amount (Actual)";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcValuesOnAfterCalcPriceAndCostPerUnit(var ItemLedgerEntry: Record "Item Ledger Entry"; var PricePerUnit: Decimal; var CostPerUnit: Decimal)
    begin
    end;
}

