// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using System.Utilities;

report 713 "Inventory - Customer Sales"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Customer Sales';
    DefaultRenderingLayout = Word;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReportHeader; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(0));
#if not CLEAN27
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            column(PeriodText; PeriodText)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
        }
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "No. 2", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", "Source No.", "Posting Date", "Source Type") where("Source Type" = const(Customer));
                RequestFilterFields = "Posting Date", "Source No.";
                dataitem("Integer"; "Integer")
                {
                    column(SourceNo_ItemLedgEntry; TempValueEntryBuf."Source No.")
                    {
                        IncludeCaption = true;
                    }
                    column(CustName; GetCustName(TempValueEntryBuf."Source No."))
                    {
                    }
                    column(InvQty_ItemLedgEntry; -TempValueEntryBuf."Invoiced Quantity")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(SalesAmtActual_ItemLedgEntry; TempValueEntryBuf."Sales Amount (Actual)")
                    {
                        IncludeCaption = true;
                        AutoFormatType = 1;
                    }
                    column(Profit_ItemLedgEntry; TempValueEntryBuf."Sales Amount (Expected)")
                    {
                        IncludeCaption = true;
                        AutoFormatType = 1;
                    }
                    column(DiscountAmount; -TempValueEntryBuf."Purchase Amount (Expected)")
                    {
                        AutoFormatType = 1;
                    }
                    column(ProfitPct_ItemLedgEntry; ProfitPct)
                    {
                        DecimalPlaces = 1 : 1;
                    }
                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TempValueEntryBuf.FindFirst()

                        else
                            TempValueEntryBuf.Next();

                        ProfitPct := 0;
                        if TempValueEntryBuf."Sales Amount (Actual)" <> 0 then
                            ProfitPct := TempValueEntryBuf."Sales Amount (Expected)" / TempValueEntryBuf."Sales Amount (Actual)" * 100;
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempValueEntryBuf.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempValueEntryBuf.Reset();
                        SetRange(Number, 1, TempValueEntryBuf.Count());
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if IsNewGroup() then
                        AddReportLine(ValueEntryBuf);

                    IncrLineAmounts(ValueEntryBuf, "Item Ledger Entry");

                    if IsLastEntry() then
                        AddReportLine(ValueEntryBuf);

                    if not ReportHasData then
                        ReportHasData := true;
                end;

                trigger OnPreDataItem()
                begin
                    LastItemLedgEntryNo := GetLastItemLedgerEntryNo("Item Ledger Entry");
                    Clear(ValueEntryBuf);
                    ReportLineNo := 0;
                end;
            }
            dataitem(SubTotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SubTotals_InvQty; SubtotalsInvQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubTotals_SalesAmtActual; SubtotalsSalesAmtActual)
                {
                    DecimalPlaces = 2 : 2;
                }
                column(SubTotals_DiscountAmount; SubtotalsDiscountAmount)
                {
                    DecimalPlaces = 2 : 2;
                }
                column(SubTotals_Profit; SubtotalsItemProfit)
                {
                    DecimalPlaces = 2 : 2;
                }
                column(SubTotals_ProfitPct; SubtotalsItemProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(SubTotals_Description; Item.Description)
                {
                }
                trigger OnPreDataItem()
                begin
                    if TempValueEntryBuf2.IsEmpty() then
                        CurrReport.Break();

                    SubtotalsInvQty := 0;
                    SubtotalsSalesAmtActual := 0;
                    SubtotalsDiscountAmount := 0;
                    SubtotalsItemProfit := 0;
                    SubtotalsItemProfitPct := 0;

                    TempValueEntryBuf2.Reset();
                    if TempValueEntryBuf2.FindSet() then
                        repeat
                            SubtotalsInvQty += (-TempValueEntryBuf2."Invoiced Quantity");
                            SubtotalsSalesAmtActual += TempValueEntryBuf2."Sales Amount (Actual)";
                            SubtotalsDiscountAmount += (-TempValueEntryBuf2."Purchase Amount (Expected)");
                            SubtotalsItemProfit += TempValueEntryBuf2."Sales Amount (Expected)";
                        until TempValueEntryBuf2.Next() = 0;
                    if SubtotalsSalesAmtActual <> 0 then
                        SubtotalsItemProfitPct := SubtotalsItemProfit / SubtotalsSalesAmtActual * 100;
                end;

                trigger OnAfterGetRecord()
                begin
                    TotalsSalesAmtActual += SubtotalsSalesAmtActual;
                    TotalsDiscountAmount += SubtotalsDiscountAmount;
                    TotalsProfit += SubtotalsItemProfit;
                end;

                trigger OnPostDataItem()
                begin
                    TempValueEntryBuf2.DeleteAll();
                end;
            }
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Totals_SalesAmtActual; TotalsSalesAmtActual)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Totals_DiscountAmount; TotalsDiscountAmount)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Totals_Profit; TotalsProfit)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Totals_ProfitPct; TotalsProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();

                if TotalsSalesAmtActual <> 0 then
                    TotalsProfitPct := TotalsProfit / TotalsSalesAmtActual * 100;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Customer Sales';
        AboutText = 'Analyse your customer sales per item to understand sales trends, optimise inventory management and improve marketing efforts. Assess the relationship between discounts, sales amount and volume of sales for each customer/item combination in the given period.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Visible = false;
                    Caption = 'Options';
                    field(PostingDateFilter; PostingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date Filter';
                    }
                }
            }
        }

        actions
        {
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            PostingDateFilter := "Item Ledger Entry".GetFilter("Posting Date");
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory Customer Sales Excel';
            LayoutFile = '.\Inventory\Reports\InventoryCustomerSales.xlsx';
            Type = Excel;
        }
        layout(Word)
        {
            Caption = 'Inventory Customer Sales Word';
            LayoutFile = '.\Inventory\Reports\InventoryCustomerSales.docx';
            Type = Word;
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Inventory Customer Sales RDLC';
            Type = RDLC;
            LayoutFile = '.\Inventory\Reports\InventoryCustomerSales.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DataRetrieved = 'Data retrieved:';
        InventoryCustomerSales = 'Inventory - Customer Sales';
        InventoryCustomerSalesPrint = 'Inventory - Cust. Sales (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvCustomerSalesAnalysis = 'Inv. - Cust. Sales (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        CustomerNoLabel = 'Customer No.';
        CustNameLabel = 'Name';
        InvQtyLabel = 'Invoiced Quantity';
        AmountLabel = 'Amount';
        DiscountAmtLabel = 'Discount Amount';
        ProfitLabel = 'Profit';
        ProfitPctLabel = 'Profit %';
#if not CLEAN27
        ReportTitle = 'Inventory - Customer Sales';
        Page = 'Page';
        CustomerNo = 'Customer No.';
        Name = 'Name';
        InvoicedQty = 'Invoiced Quantity';
        Amount = 'Amount';
        DiscountAmt = 'Discount Amount';
        Profit = 'Profit';
        ProfitPct = 'Profit %';
        Total = 'Total';
#endif
    }

    trigger OnPreReport()
    begin
        ItemFilter := GetTableFilters(Item.TableCaption(), Item.GetFilters);
        ItemLedgEntryFilter := GetTableFilters("Item Ledger Entry".TableCaption(), "Item Ledger Entry".GetFilters);
        PeriodText := StrSubstNo(PeriodInfoTxt, "Item Ledger Entry".GetFilter("Posting Date"));
    end;

    var
        ValueEntryBuf: Record "Value Entry";
        TempValueEntryBuf: Record "Value Entry" temporary;
        TempValueEntryBuf2: Record "Value Entry" temporary;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;
        PostingDateFilter: Text;
        LastItemLedgEntryNo: Integer;
        ReportLineNo: Integer;
        ProfitPct: Decimal;
        SubtotalsInvQty: Decimal;
        SubtotalsSalesAmtActual: Decimal;
        SubtotalsDiscountAmount: Decimal;
        SubtotalsItemProfit: Decimal;
        SubtotalsItemProfitPct: Decimal;
        TotalsSalesAmtActual: Decimal;
        TotalsDiscountAmount: Decimal;
        TotalsProfit: Decimal;
        TotalsProfitPct: Decimal;
        ReportHasData: Boolean;
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;

    local procedure CalcDiscountAmount(ItemLedgerEntryNo: Integer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.CalcSums("Discount Amount");
        exit(ValueEntry."Discount Amount");
    end;

    local procedure GetLastItemLedgerEntryNo(var ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    var
        LastItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LastItemLedgerEntry.Copy(ItemLedgerEntry);
        if LastItemLedgerEntry.FindLast() then
            exit(LastItemLedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure IncrLineAmounts(var ValueEntryBuf2: Record "Value Entry"; CurrItemLedgerEntry: Record "Item Ledger Entry")
    var
        Profit: Decimal;
        DiscountAmount: Decimal;
    begin
        CurrItemLedgerEntry.CalcFields("Sales Amount (Actual)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
        Profit := CurrItemLedgerEntry."Sales Amount (Actual)" + CurrItemLedgerEntry."Cost Amount (Actual)" + CurrItemLedgerEntry."Cost Amount (Non-Invtbl.)";
        DiscountAmount := CalcDiscountAmount(CurrItemLedgerEntry."Entry No.");

        if ValueEntryBuf2."Item No." = '' then begin
            ValueEntryBuf2.Init();
            ValueEntryBuf2."Item No." := CurrItemLedgerEntry."Item No.";
            ValueEntryBuf2."Source No." := CurrItemLedgerEntry."Source No.";
        end;
        ValueEntryBuf2."Invoiced Quantity" += CurrItemLedgerEntry."Invoiced Quantity";
        ValueEntryBuf2."Sales Amount (Actual)" += CurrItemLedgerEntry."Sales Amount (Actual)";
        ValueEntryBuf2."Sales Amount (Expected)" += Profit;
        ValueEntryBuf2."Purchase Amount (Expected)" += DiscountAmount;
    end;

    local procedure AddReportLine(var ValueEntryBuf2: Record "Value Entry")
    begin
        TempValueEntryBuf := ValueEntryBuf2;
        ReportLineNo += 1;
        TempValueEntryBuf."Entry No." := ReportLineNo;
        TempValueEntryBuf.Insert();
        TempValueEntryBuf2.Init();
        TempValueEntryBuf2.TransferFields(TempValueEntryBuf);
        TempValueEntryBuf2.Insert();
        Clear(ValueEntryBuf2);
    end;

    local procedure IsNewGroup(): Boolean
    begin
        exit(("Item Ledger Entry"."Source No." <> ValueEntryBuf."Source No.") and (ValueEntryBuf."Source No." <> ''));
    end;

    local procedure IsLastEntry(): Boolean
    begin
        exit("Item Ledger Entry"."Entry No." = LastItemLedgEntryNo);
    end;

    local procedure GetCustName(CustNo: Code[20]): Text[100]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustNo) then
            exit(Customer.Name);
        exit('');
    end;

    local procedure GetTableFilters(TableName: Text; Filters: Text): Text
    begin
        if Filters <> '' then
            exit(StrSubstNo(TableFiltersTxt, TableName, Filters));
        exit('');
    end;
}

