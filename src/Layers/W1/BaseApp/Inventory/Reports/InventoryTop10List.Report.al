// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using System.Utilities;

report 711 "Inventory - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryTop10List.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Top 10 List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                WindowDialog.Update(1, "No.");
                CalcFields("Sales (LCY)", Inventory);
                if ("Sales (LCY)" = 0) and (Inventory = 0) and not PrintAlsoIfZeroReq then
                    CurrReport.Skip();

                TempItemAmount.Init();
                TempItemAmount."Item No." := "No.";
                if ShowTypeReq = ShowTypeReq::"Sales (LCY)" then begin
                    TempItemAmount.Amount := "Sales (LCY)";
                    TempItemAmount."Amount 2" := Inventory;
                end else begin
                    TempItemAmount.Amount := Inventory;
                    TempItemAmount."Amount 2" := "Sales (LCY)";
                end;
                if ShowSortingReq = ShowSortingReq::Largest then begin
                    TempItemAmount.Amount := -TempItemAmount.Amount;
                    TempItemAmount."Amount 2" := -TempItemAmount."Amount 2";
                end;
                TempItemAmount.Insert();
                if (NoOfRecordsToPrintReq = 0) or (i < NoOfRecordsToPrintReq) then
                    i := i + 1
                else begin
                    TempItemAmount.Find('+');
                    TempItemAmount.Delete();
                end;

                TotalItemSales += "Sales (LCY)";
                TotalItemBalance += Inventory;
            end;

            trigger OnPreDataItem()
            begin
                WindowDialog.Open(SortingItemsTxt);
                TempItemAmount.DeleteAll();
                i := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(STRSUBSTNO_Text001_ItemDateFilter_; StrSubstNo(PeriodInfoTxt, ItemDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text002_Sequence_Heading_; StrSubstNo(RankedAccordingTxt, Sequence, Heading))
            {
            }
            column(PrintAlsoIfZero; PrintAlsoIfZeroReq)
            {
            }
            column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo(TableFiltersTxt, Item.TableCaption(), ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(STRSUBSTNO_Text003_Heading_; StrSubstNo(PortionOfTxt, Heading))
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Item__No__; Item."No.")
            {
            }
            column(Item_Description; Item.Description)
            {
            }
            column(Item__Sales__LCY__; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
            }
            column(Item_Inventory; Item.Inventory)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BarText; BarText)
            {
            }
            column(Item__Sales__LCY___Control24; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
            }
            column(ItemSales; ItemSales)
            {
                AutoFormatType = 1;
            }
            column(QtyOnHand; QtyOnHand)
            {
                DecimalPlaces = 0 : 5;
            }
            column(SalesAmountPct; SalesAmountPct)
            {
                AutoFormatType = 1;
                DecimalPlaces = 1 : 1;
            }
            column(QtyOnHandPct; QtyOnHandPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(TotalItemBalance; TotalItemBalance)
            {
            }
            column(TotalItemSales; TotalItemSales)
            {
            }
            column(Inventory___Top_10_ListCaption; Inventory___Top_10_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_Caption; This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl)
            {
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
            }
            column(Item__No__Caption; Item.FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; Item.FieldCaption(Description))
            {
            }
            column(Item__Sales__LCY__Caption; Item.FieldCaption("Sales (LCY)"))
            {
            }
            column(Item_InventoryCaption; Item_InventoryCaptionLbl)
            {
            }
            column(Item__Sales__LCY___Control24Caption; Item__Sales__LCY___Control24CaptionLbl)
            {
            }
            column(ItemSalesCaption; ItemSalesCaptionLbl)
            {
            }
            column(SalesAmountPctCaption; SalesAmountPctCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempItemAmount.Find('-') then
                        CurrReport.Break();
                    if ShowSortingReq = ShowSortingReq::Largest then
                        MaxAmount := -TempItemAmount.Amount
                    else begin
                        ItemAmount2 := TempItemAmount;
                        if TempItemAmount.Next(NoOfRecordsToPrintReq - 1) > 0 then;
                        MaxAmount := TempItemAmount.Amount;
                        TempItemAmount := ItemAmount2;
                    end;
                end else
                    if TempItemAmount.Next() = 0 then
                        CurrReport.Break();
                Item.Get(TempItemAmount."Item No.");
                Item.CalcFields("Sales (LCY)", Inventory);
                if ShowSortingReq = ShowSortingReq::Largest then begin
                    TempItemAmount.Amount := -TempItemAmount.Amount;
                    TempItemAmount."Amount 2" := -TempItemAmount."Amount 2";
                end;
                if (MaxAmount > 0) and (TempItemAmount.Amount > 0) then
                    BarText := CopyStr(PadStr('', Round(TempItemAmount.Amount / MaxAmount * 45, 1), '*'), 1, 50)
                else
                    BarText := '';
                if ShowSortingReq = ShowSortingReq::Largest then begin
                    TempItemAmount.Amount := -TempItemAmount.Amount;
                    TempItemAmount."Amount 2" := -TempItemAmount."Amount 2";
                end;
            end;

            trigger OnPreDataItem()
            begin
                WindowDialog.Close();
                ItemSales := Item."Sales (LCY)";
                QtyOnHand := Item.Inventory;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Top 10 List';
        AboutText = 'Review a summary of items with the highest or lowest sales or Inventory within a selected period to assist with purchase planning. You can choose to display more than 10 Items';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowSorting; ShowSortingReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Largest,Smallest';
                        ToolTip = 'Specifies if you want a report on the items that have the highest sales; select the Smallest option if you want a report on the items that have the lowest sales.';
                    }
                    field(ShowType; ShowTypeReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Sales (LCY),Inventory';
                        ToolTip = 'Specifies if you want a report on item sales; select the Inventory option if you want a report on the items'' inventory.';
                    }
                    field(NoOfRecordsToPrint; NoOfRecordsToPrintReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the number of items to be shown in the report.';
                    }
                    field(PrintAlsoIfZero; PrintAlsoIfZeroReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Items Not on Inventory or Not Sold';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want items that are not on hand or have not been sold to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrintReq = 0 then
                NoOfRecordsToPrintReq := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        ItemDateFilter := Item.GetFilter("Date Filter");
        Sequence := LowerCase(Format(SelectStr(ShowSortingReq + 1, Text004Txt)));
        Heading := Format(SelectStr(ShowTypeReq + 1, Text005Txt));
    end;

    var
        TempItemAmount: Record "Item Amount" temporary;
        ItemAmount2: Record "Item Amount";
        WindowDialog: Dialog;
        ItemFilter: Text;
        ItemDateFilter: Text;
        Sequence: Text;
        Heading: Text[30];
        ShowSortingReq: Option Largest,Smallest;
        ShowTypeReq: Option "Sales (LCY)",Inventory;
        NoOfRecordsToPrintReq: Integer;
        PrintAlsoIfZeroReq: Boolean;
        ItemSales: Decimal;
        QtyOnHand: Decimal;
        SalesAmountPct: Decimal;
        QtyOnHandPct: Decimal;
        MaxAmount: Decimal;
        BarText: Text[50];
        i: Integer;
        TotalItemSales: Decimal;
        TotalItemBalance: Decimal;

        SortingItemsTxt: Label 'Sorting items    #1##########', Comment = '%1 - progress bar';
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;
        RankedAccordingTxt: Label 'Ranked according to %1 %2', Comment = '%1 - Sequence, %2 - Heading';
        PortionOfTxt: Label 'Portion of %1', Comment = '%1 - heading';
        Text004Txt: Label 'Largest,Smallest';
        Text005Txt: Label 'Sales (LCY),Inventory';
        Inventory___Top_10_ListCaptionLbl: Label 'Inventory - Top 10 List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl: Label 'This report also includes items not on inventory or that are not sold.';
        Integer_NumberCaptionLbl: Label 'Rank';
        Item_InventoryCaptionLbl: Label 'Inventory';
        Item__Sales__LCY___Control24CaptionLbl: Label 'Total';
        ItemSalesCaptionLbl: Label 'Total Sales';
        SalesAmountPctCaptionLbl: Label '% of Total Sales';

    procedure InitializeRequest(NewShowSorting: Option; NewShowType: Option; NewNoOfRecordsToPrint: Integer; NewPrintAlsoIfZero: Boolean)
    begin
        ShowSortingReq := NewShowSorting;
        ShowTypeReq := NewShowType;
        NoOfRecordsToPrintReq := NewNoOfRecordsToPrint;
        PrintAlsoIfZeroReq := NewPrintAlsoIfZero;
    end;
}

