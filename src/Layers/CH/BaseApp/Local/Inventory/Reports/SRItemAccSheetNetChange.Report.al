// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 11505 "SR Item Acc Sheet Net Change"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/SRItemAccSheetNetChange.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Acc Sheet Net Change';
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
            column(SRAccSheetNetChangeCaption; SRAccSheetNetChangeCaptionLbl)
            {
            }
            column(IncreaseCaption; IncreaseCaptionLbl)
            {
            }
            column(StockCaption; StockCaptionLbl)
            {
            }
            column(EntrynoCaption; EntrynoCaptionLbl)
            {
            }
            column(SourceCaption; SourceCaptionLbl)
            {
            }
            column(TextCaption; TextCaptionLbl)
            {
            }
            column(DocCaption; DocCaptionLbl)
            {
            }
            column(PostDatCaption; PostDatCaptionLbl)
            {
            }
            column(DecreaseCaption; DecreaseCaptionLbl)
            {
            }
            column(VarCaption; VarCaptionLbl)
            {
            }
            column(InventoryCaption; InventoryCaptionLbl)
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
                column(Stock; Stock)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(IncreaseQty; IncreaseQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(DecreaseQty; DecreaseQty)
                {
                    DecimalPlaces = 0 : 5;
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
                column(EntryNo_ItemLedgerEntry; "Entry No.")
                {
                }
                column(SourceNo_ItemLedgerEntry; "Source No.")
                {
                }
                column(SourceTypeFormatted; CopyStr(Format("Source Type"), 1, 1))
                {
                }
                column(Description_ItemLedgerEntry; Description)
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
                column(Quantity_ItemLedgerEntry; Quantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(NegQuantity_ItemLedgerEntry; -Quantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Stock_ItemLedgerEntry; Stock)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VariantCode_ItemLedgerEntry; "Variant Code")
                {
                }
                column(LocationCode_ItemLedgerEntry; "Location Code")
                {
                }
                column(PostingDate_ItemLedgerEntry; "Posting Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
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
                column(Stock_Integer; Stock)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(DecreaseQty_Integer; DecreaseQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(IncreaseQty_Integer; IncreaseQty)
                {
                    DecimalPlaces = 0 : 5;
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
        SRAccSheetNetChangeCaptionLbl: Label 'SR Item Acc Sheet Net Change';
        IncreaseCaptionLbl: Label 'Increase';
        StockCaptionLbl: Label 'Stock';
        EntrynoCaptionLbl: Label 'Entryno.';
        SourceCaptionLbl: Label 'Source';
        TextCaptionLbl: Label 'Text';
        DocCaptionLbl: Label 'Doc.';
        PostDatCaptionLbl: Label 'Post. Dat.';
        DecreaseCaptionLbl: Label 'Decrease';
        VarCaptionLbl: Label 'Var.';
        InventoryCaptionLbl: Label 'Inventory';
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
}

