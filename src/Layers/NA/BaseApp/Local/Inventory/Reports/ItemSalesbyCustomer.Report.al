// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using System.IO;

report 10145 "Item Sales by Customer"
{
    ApplicationArea = Basic, Suite;
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemSalesbyCustomer.rdlc';
    Caption = 'Item Sales by Customer';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", "Location Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
            column(IncludeReturns; IncludeReturns)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Item_Ledger_Entry__TABLECAPTION__________ItemLedgEntryFilter; "Item Ledger Entry".TableCaption + ': ' + ItemLedgEntryFilter)
            {
            }
            column(SalesText; SalesText)
            {
            }
            column(QtyText; QtyText)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(FIELDCAPTION__Base_Unit_of_Measure_____________Base_Unit_of_Measure_; FieldCaption("Base Unit of Measure") + ': ' + "Base Unit of Measure")
            {
            }
            column(ValueEntry__Sales_Amount__Actual__; ValueEntry."Sales Amount (Actual)")
            {
            }
            column(ValueEntry__Discount_Amount_; ValueEntry."Discount Amount")
            {
            }
            column(Profit; Profit)
            {
            }
            column(ProfitPct; ProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Item_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Item_Sales_by_CustomerCaption; Item_Sales_by_CustomerCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Returns_are_included_in_Sales_Quantities_Caption; Returns_are_included_in_Sales_Quantities_CaptionLbl)
            {
            }
            column(Returns_are_not_included_in_Sales_Quantities_Caption; Returns_are_not_included_in_Sales_Quantities_CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Source_No__Caption; Item_Ledger_Entry__Source_No__CaptionLbl)
            {
            }
            column(Cust_NameCaption; Cust_NameCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Invoiced_Quantity_Caption; "Item Ledger Entry".FieldCaption("Invoiced Quantity"))
            {
            }
            column(ValueEntry__Sales_Amount__Actual___Control29Caption; ValueEntry__Sales_Amount__Actual___Control29CaptionLbl)
            {
            }
            column(ValueEntry__Discount_Amount__Control30Caption; ValueEntry__Discount_Amount__Control30CaptionLbl)
            {
            }
            column(Profit_Control31Caption; Profit_Control31CaptionLbl)
            {
            }
            column(ProfitPct_Control32Caption; ProfitPct_Control32CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Posting Date" = field("Date Filter"), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Entry Type", "Item No.", "Variant Code", "Source Type", "Source No.", "Posting Date") where("Entry Type" = const(Sale), "Source Type" = const(Customer));
                RequestFilterFields = "Source No.";
                column(FIELDCAPTION__Variant_Code_____________Variant_Code_; FieldCaption("Variant Code") + ': ' + "Variant Code")
                {
                }
                column(Item_Ledger_Entry__Source_No__; "Source No.")
                {
                }
                column(Cust_Name; Cust.Name)
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity_; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueEntry__Sales_Amount__Actual___Control29; ValueEntry."Sales Amount (Actual)")
                {
                }
                column(ValueEntry__Discount_Amount__Control30; ValueEntry."Discount Amount")
                {
                }
                column(Profit_Control31; Profit)
                {
                }
                column(ProfitPct_Control32; ProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(ProfitPct_Control7; ProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(Profit_Control8; Profit)
                {
                }
                column(ValueEntry__Discount_Amount__Control9; ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Sales_Amount__Actual___Control19; ValueEntry."Sales Amount (Actual)")
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity__Control39; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Text008_________FIELDCAPTION__Variant_Code_____________Variant_Code_; Text008 + ' ' + FieldCaption("Variant Code") + ': ' + "Variant Code")
                {
                }
                column(Text008_________FIELDCAPTION__Item_No______________Item_No__; Text008 + ' ' + FieldCaption("Item No.") + ': ' + "Item No.")
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity__Control34; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueEntry__Sales_Amount__Actual___Control35; ValueEntry."Sales Amount (Actual)")
                {
                }
                column(ValueEntry__Discount_Amount__Control36; ValueEntry."Discount Amount")
                {
                }
                column(Profit_Control37; Profit)
                {
                }
                column(ProfitPct_Control38; ProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(Item_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Item_Ledger_Entry_Variant_Code; "Variant Code")
                {
                }
                column(Item_Ledger_Entry_Item_No_; "Item No.")
                {
                }
                column(Item_Ledger_Entry_Posting_Date; "Posting Date")
                {
                }
                column(Item_Ledger_Entry_Location_Code; "Location Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not IncludeReturns then
                        if "Document Type" in ["Document Type"::"Sales Credit Memo", "Document Type"::"Sales Return Receipt", "Document Type"::"Service Credit Memo"] then
                            CurrReport.Skip();

                    if ("Source No." <> PrevSourceNo) or ("Variant Code" <> PrevVariantCode) then begin
                        if PrintToExcel then begin
                            CalcProfitPct();
                            if (TotalSalesAmtForSource <> 0) or (TotalInvQtyForSource <> 0) or
                               (TotalDiscAmtForSource <> 0) or (TotalProfitForSource <> 0)
                            then
                                MakeExcelDataBody();
                        end;
                        TotalInvQtyForSource := 0;
                        TotalSalesAmtForSource := 0;
                        TotalDiscAmtForSource := 0;
                        TotalProfitForSource := 0;
                        PrevSourceNo := "Source No.";
                        PrevVariantCode := "Variant Code";
                    end;
                    CalcFields("Cost Amount (Actual)");
                    "Invoiced Quantity" := -"Invoiced Quantity";
                    ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
                    ValueEntry.CalcSums("Sales Amount (Actual)", "Discount Amount");
                    ValueEntry."Discount Amount" := -ValueEntry."Discount Amount";
                    Profit := ValueEntry."Sales Amount (Actual)" + "Item Ledger Entry"."Cost Amount (Actual)";

                    if "Source No." <> '' then
                        Cust.Get("Source No.")
                    else
                        Clear(Cust);
                    TotalInvQtyForSource += "Invoiced Quantity";
                    TotalSalesAmtForSource += ValueEntry."Sales Amount (Actual)";
                    TotalDiscAmtForSource += ValueEntry."Discount Amount";
                    TotalProfitForSource += Profit;
                end;

                trigger OnPostDataItem()
                begin
                    if PrintToExcel then begin
                        CalcProfitPct();
                        if (TotalSalesAmtForSource <> 0) or (TotalInvQtyForSource <> 0) or
                           (TotalDiscAmtForSource <> 0) or (TotalProfitForSource <> 0)
                        then
                            MakeExcelDataBody();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(Profit);
                    if IncludeReturns then
                        SetFilter("Invoiced Quantity", '<>0');

                    ValueEntry.Reset();
                    ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");

                    TotalInvQtyForSource := 0;
                    TotalSalesAmtForSource := 0;
                    TotalDiscAmtForSource := 0;
                    TotalProfitForSource := 0;
                    PrevSourceNo := '';
                    PrevVariantCode := '';
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Sales (Qty.)", "Sales (LCY)");
                if MinSales <> 0 then
                    if "Sales (LCY)" <= MinSales then
                        CurrReport.Skip();
                if MaxSales <> 0 then
                    if "Sales (LCY)" >= MaxSales then
                        CurrReport.Skip();
                if MinQty <> 0 then
                    if "Sales (Qty.)" <= MinQty then
                        CurrReport.Skip();
                if MaxQty <> 0 then
                    if "Sales (Qty.)" >= MaxQty then
                        CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Clear(Profit);
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
                    field(IncludeReturns; IncludeReturns)
                    {
                        Caption = 'Include Returns';
                        ToolTip = 'Specifies if sales tax related to sales returns is included in the report.';
                    }
                    group("Items with Net Sales ($)")
                    {
                        Caption = 'Items with Net Sales ($)';
                        field(MinSales; MinSales)
                        {
                            BlankZero = true;
                            Caption = 'Greater than';
                            ToolTip = 'Specifies a maximum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                        field(MaxSales; MaxSales)
                        {
                            BlankZero = true;
                            Caption = 'Less than';
                            ToolTip = 'Specifies a minimum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                    }
                    group("Items with Net Sales (Qty)")
                    {
                        Caption = 'Items with Net Sales (Qty)';
                        field(MinQty; MinQty)
                        {
                            BlankZero = true;
                            Caption = 'Greater than';
                            ToolTip = 'Specifies a maximum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                        field(MaxQty; MaxQty)
                        {
                            BlankZero = true;
                            Caption = 'Less than';
                            ToolTip = 'Specifies a minimum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                    }
                    field(PrintToExcel; PrintToExcel)
                    {
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
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

    trigger OnPostReport()
    begin
        if PrintToExcel then
            CreateExcelbook();
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        PeriodText := Item.GetFilter("Date Filter");
        Item.SetRange("Date Filter");
        ItemFilter := Item.GetFilters();
        ItemLedgEntryFilter := "Item Ledger Entry".GetFilters();
        if PeriodText = '' then
            SubTitle := Text000
        else
            SubTitle := Text001 + ' ' + PeriodText;
        if MinSales = 0 then
            SalesText := ''
        else
            SalesText := StrSubstNo(Text002, MinSales);
        if MaxSales <> 0 then
            if SalesText = '' then
                SalesText := StrSubstNo(Text003, MaxSales)
            else
                SalesText := SalesText + StrSubstNo(Text004, MaxSales);
        if MinQty = 0 then
            QtyText := ''
        else
            QtyText := StrSubstNo(Text005, MinQty);
        if MaxQty <> 0 then
            if QtyText = '' then
                QtyText := StrSubstNo(Text006, MaxQty)
            else
                QtyText := QtyText + StrSubstNo(Text007, MaxQty);

        if PrintToExcel then
            MakeExcelInfo();
    end;

    var
        Cust: Record Customer;
        CompanyInformation: Record "Company Information";
        ValueEntry: Record "Value Entry";
        ExcelBuf: Record "Excel Buffer" temporary;
        IncludeReturns: Boolean;
        MinSales: Decimal;
        MaxSales: Decimal;
        MinQty: Decimal;
        MaxQty: Decimal;
        SubTitle: Text;
        SalesText: Text[150];
        QtyText: Text[150];
        Profit: Decimal;
        ProfitPct: Decimal;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;
        Text000: Label 'All Sales to Date';
        Text001: Label 'Sales during the Period';
        Text002: Label 'Items with Net Sales of more than $%1';
        Text003: Label 'Items with Net Sales of less than $%1';
        Text004: Label ' and less than $%1';
        Text005: Label 'Items with Net Sales Quantity more than %1';
        Text006: Label 'Items with Net Sales Quantity less than %1';
        Text007: Label ' and less than %1';
        Text008: Label 'Total for';
        Text009: Label 'Returns are included in Sales Quantities.';
        Text010: Label 'Returns are not included in Sales Quantities.';
        Text101: Label 'Data';
        Text102: Label 'Item Sales by Customer';
        Text103: Label 'Company Name';
        Text104: Label 'Report No.';
        Text105: Label 'Report Name';
        Text106: Label 'User ID';
        Text107: Label 'Date / Time';
        Text108: Label 'Item Filters';
        Text109: Label 'Item Ledger Entry Filters';
        Text110: Label 'Profit';
        Text111: Label 'Profit Percent';
        PrintToExcel: Boolean;
        Text112: Label 'Sales Option';
        Text113: Label 'Quantity Option';
        Text114: Label 'Returns Option';
        TotalInvQtyForSource: Decimal;
        TotalSalesAmtForSource: Decimal;
        TotalDiscAmtForSource: Decimal;
        TotalProfitForSource: Decimal;
        PrevSourceNo: Code[20];
        PrevVariantCode: Code[20];
        Item_Sales_by_CustomerCaptionLbl: Label 'Item Sales by Customer';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Returns_are_included_in_Sales_Quantities_CaptionLbl: Label 'Returns are included in Sales Quantities.';
        Returns_are_not_included_in_Sales_Quantities_CaptionLbl: Label 'Returns are not included in Sales Quantities.';
        Item_Ledger_Entry__Source_No__CaptionLbl: Label 'Customer No.';
        Cust_NameCaptionLbl: Label 'Name';
        ValueEntry__Sales_Amount__Actual___Control29CaptionLbl: Label 'Amount';
        ValueEntry__Discount_Amount__Control30CaptionLbl: Label 'Discount Amount';
        Profit_Control31CaptionLbl: Label 'Profit';
        ProfitPct_Control32CaptionLbl: Label 'Profit %';
        Report_TotalCaptionLbl: Label 'Report Total';

    procedure CalcProfitPct()
    begin
        if PrintToExcel then begin
            if TotalSalesAmtForSource <> 0 then
                ProfitPct := Round(TotalProfitForSource / TotalSalesAmtForSource * 100, 0.1)
            else
                ProfitPct := 0;
        end else
            if ValueEntry."Sales Amount (Actual)" <> 0 then
                ProfitPct := Round(Profit / ValueEntry."Sales Amount (Actual)" * 100, 0.1)
            else
                ProfitPct := 0;
    end;

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text103), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text105), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(Text102), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text104), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Item Sales by Customer", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text106), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text107), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today, false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time, false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text112), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(SalesText, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text113), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(QtyText, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text114), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        if IncludeReturns then
            ExcelBuf.AddInfoColumn(Format(Text009), false, false, false, false, '', ExcelBuf."Cell Type"::Text)
        else
            ExcelBuf.AddInfoColumn(Format(Text010), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text108), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(ItemFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text109), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(ItemLedgEntryFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(Item.FieldCaption("No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption("Base Unit of Measure"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("Item Ledger Entry".FieldCaption("Variant Code"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Cust.TableCaption + ' ' + Cust.FieldCaption("No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Cust.TableCaption + ' ' + Cust.FieldCaption(Name), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("Item Ledger Entry".FieldCaption("Invoiced Quantity"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ValueEntry.FieldCaption("Sales Amount (Actual)"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text110), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text111), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ValueEntry.FieldCaption("Discount Amount"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(Item."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item."Base Unit of Measure", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(PrevVariantCode, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Cust."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Cust.Name, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(TotalInvQtyForSource, false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(TotalSalesAmtForSource, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(TotalProfitForSource, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(ProfitPct / 100, false, '', false, false, false, '0.0%', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(TotalDiscAmtForSource, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text101, Text102, CompanyName, UserId);
        Error('');
    end;
}

