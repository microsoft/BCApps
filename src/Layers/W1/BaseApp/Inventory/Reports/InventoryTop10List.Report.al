// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using System.Utilities;

report 711 "Inventory - Top 10 List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Top 10 List';
    DefaultRenderingLayout = Excel;
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

            column(PrintAlsoIfZero; PrintAlsoIfZeroReq)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Item__No__; Item."No.")
            {
                IncludeCaption = true;
            }
            column(Item_Description; Item.Description)
            {
                IncludeCaption = true;
            }
            column(Item__Sales__LCY__; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
                IncludeCaption = true;
            }
            column(Item_Inventory; Item.Inventory)
            {
                DecimalPlaces = 0 : 5;
                IncludeCaption = true;
            }
            column(ItemSales; ItemSales)
            {
                AutoFormatType = 1;
            }
            column(QtyOnHand; QtyOnHand)
            {
                DecimalPlaces = 0 : 5;
            }
            column(TotalItemBalance; TotalItemBalance)
            {
            }
            column(TotalItemSales; TotalItemSales)
            {
            }
#if not CLEAN28
            column(STRSUBSTNO_Text001_ItemDateFilter_; StrSubstNo(PeriodInfoTxt, ItemDateFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(STRSUBSTNO_Text002_Sequence_Heading_; StrSubstNo(RankedAccordingTxt, Sequence, Heading))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo(TableFiltersTxt, Item.TableCaption(), ItemFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemFilter; ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(STRSUBSTNO_Text003_Heading_; StrSubstNo(PortionOfTxt, Heading))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(BarText; BarText)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item__Sales__LCY___Control24; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(SalesAmountPct; SalesAmountPct)
            {
                AutoFormatType = 1;
                DecimalPlaces = 1 : 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(QtyOnHandPct; QtyOnHandPct)
            {
                DecimalPlaces = 1 : 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Inventory___Top_10_ListCaption; Inventory___Top_10_ListCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_Caption; This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item__No__Caption; Item.FieldCaption("No."))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item_DescriptionCaption; Item.FieldCaption(Description))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item__Sales__LCY__Caption; Item.FieldCaption("Sales (LCY)"))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item_InventoryCaption; Item_InventoryCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item__Sales__LCY___Control24Caption; Item__Sales__LCY___Control24CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemSalesCaption; ItemSalesCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(SalesAmountPctCaption; SalesAmountPctCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif

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
                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item Filters applied to this report.';
                        Visible = false;
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

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory Top 10 List Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InventoryTop10List.xlsx';
            Summary = 'Built in layout for the Inventory Top 10 List Excel report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Inventory Top 10 List RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryTop10List.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by an Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Inventory Top 10 List RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        InventoryTop10ListLbl = 'Inventory Top 10 List';
        InventoryTop10ListPrintLbl = 'Inv. Top 10 List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InventoryTop10ListAnalysisLbl = 'Inv. Top 10 List (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        RankLbl = 'Rank';
        RankAccordingToLbl = 'Rank according to ';
        TotalSalesLbl = 'Total Sales';
        PercentOfTotalSalesLbl = '% of Total Sales';
        IncludeNonInventoryItemsLbl = 'This report also includes items not on inventory or that are not sold.';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
    }

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
    end;

    var
        TempItemAmount: Record "Item Amount" temporary;
        ItemAmount2: Record "Item Amount";
        WindowDialog: Dialog;
        ItemFilter: Text;
        ItemFilterHeading: Text;
#if not CLEAN28
        ItemDateFilter: Text;
        Sequence: Text;
        Heading: Text[30];
#endif
        ShowSortingReq: Option Largest,Smallest;
        ShowTypeReq: Option "Sales (LCY)",Inventory;
        NoOfRecordsToPrintReq: Integer;
        PrintAlsoIfZeroReq: Boolean;
        ItemSales: Decimal;
        QtyOnHand: Decimal;
#if not CLEAN28
        SalesAmountPct: Decimal;
        QtyOnHandPct: Decimal;
#endif
        MaxAmount: Decimal;
        BarText: Text[50];
        i: Integer;
        TotalItemSales: Decimal;
        TotalItemBalance: Decimal;

        SortingItemsTxt: Label 'Sorting items    #1##########', Comment = '%1 - progress bar';
#if not CLEAN28
        Text004Txt: Label 'Largest,Smallest';
        Text005Txt: Label 'Sales (LCY),Inventory';
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;
        RankedAccordingTxt: Label 'Ranked according to %1 %2', Comment = '%1 - Sequence, %2 - Heading';
        PortionOfTxt: Label 'Portion of %1', Comment = '%1 - heading';
        Inventory___Top_10_ListCaptionLbl: Label 'Inventory - Top 10 List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl: Label 'This report also includes items not on inventory or that are not sold.';
        Integer_NumberCaptionLbl: Label 'Rank';
        Item_InventoryCaptionLbl: Label 'Inventory';
        Item__Sales__LCY___Control24CaptionLbl: Label 'Total';
        ItemSalesCaptionLbl: Label 'Total Sales';
        SalesAmountPctCaptionLbl: Label '% of Total Sales';
#endif

    procedure InitializeRequest(NewShowSorting: Option; NewShowType: Option; NewNoOfRecordsToPrint: Integer; NewPrintAlsoIfZero: Boolean)
    begin
        ShowSortingReq := NewShowSorting;
        ShowTypeReq := NewShowType;
        NoOfRecordsToPrintReq := NewNoOfRecordsToPrint;
        PrintAlsoIfZeroReq := NewPrintAlsoIfZero;
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ItemFilter := Item.GetFilters();
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter;
#if not CLEAN28
        ItemDateFilter := Item.GetFilter("Date Filter");
        Sequence := LowerCase(Format(SelectStr(ShowSortingReq + 1, Text004Txt)));
        Heading := Format(SelectStr(ShowTypeReq + 1, Text005Txt));
#endif
    end;
}

