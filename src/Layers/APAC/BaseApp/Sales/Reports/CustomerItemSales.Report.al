// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Utilities;

report 113 "Customer/Item Sales"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerItemSales.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer/Item Sales';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(Text000, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(RoundingNO; RoundingNO)
            {
            }
            column(Customer_TABLECAPTION__________CustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(Value_Entry__TABLECAPTION__________ItemLedgEntryFilter; "Value Entry".TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(ItemLedgEntryFilter; ValueEntryFilter)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(ValueEntryBuffer__Sales_Amount__Actual__; TempValueEntryBuffer."Sales Amount (Actual)")
            {
            }
            column(ValueEntryBuffer__Discount_Amount_; -TempValueEntryBuffer."Discount Amount")
            {
            }
            column(Profit; Profit)
            {
                AutoFormatType = 1;
            }
            column(ProfitPct; ProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(Customer_Item_SalesCaption; Customer_Item_SalesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(ValueEntryBuffer__Item_No__Caption; ValueEntryBuffer__Item_No__CaptionLbl)
            {
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
            }
            column(ValueEntryBuffer__Invoiced_Quantity_Caption; ValueEntryBuffer__Invoiced_Quantity_CaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            column(ValueEntryBuffer__Sales_Amount__Actual___Control44Caption; ValueEntryBuffer__Sales_Amount__Actual___Control44CaptionLbl)
            {
            }
            column(ValueEntryBuffer__Discount_Amount__Control45Caption; ValueEntryBuffer__Discount_Amount__Control45CaptionLbl)
            {
            }
            column(Profit_Control46Caption; Profit_Control46CaptionLbl)
            {
            }
            column(ProfitPct_Control47Caption; ProfitPct_Control47CaptionLbl)
            {
            }
            column(Customer__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Source No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Source Type", "Source No.", "Item No.", "Variant Code", "Posting Date") where("Source Type" = const(Customer), "Item Charge No." = const(''), "Expected Cost" = const(false), Adjustment = const(false));
                RequestFilterFields = "Item No.", "Posting Date";

                trigger OnAfterGetRecord()
                var
                    ValueEntry: Record "Value Entry";
                    EntryInBufferExists: Boolean;
                begin
                    TempValueEntryBuffer.Init();
                    TempValueEntryBuffer.SetRange("Item No.", "Item No.");
                    EntryInBufferExists := TempValueEntryBuffer.FindFirst();

                    if not EntryInBufferExists then
                        TempValueEntryBuffer."Entry No." := "Item Ledger Entry No.";
                    TempValueEntryBuffer."Item No." := "Item No.";
                    TempValueEntryBuffer."Invoiced Quantity" += "Invoiced Quantity";
                    TempValueEntryBuffer."Sales Amount (Actual)" += "Sales Amount (Actual)";
                    TempValueEntryBuffer."Cost Amount (Actual)" += "Cost Amount (Actual)";
                    TempValueEntryBuffer."Cost Amount (Non-Invtbl.)" += "Cost Amount (Non-Invtbl.)";
                    TempValueEntryBuffer."Discount Amount" += "Discount Amount";

                    TempItemLedgerEntry.SetRange("Entry No.", "Item Ledger Entry No.");
                    if TempItemLedgerEntry.IsEmpty() then begin
                        TempItemLedgerEntry."Entry No." := "Item Ledger Entry No.";
                        TempItemLedgerEntry.Insert();

                        // Add item charges regardless of their posting date
                        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry No.");
                        ValueEntry.SetFilter("Item Charge No.", '<>%1', '');
                        ValueEntry.CalcSums("Sales Amount (Actual)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)", "Discount Amount");

                        TempValueEntryBuffer."Sales Amount (Actual)" += ValueEntry."Sales Amount (Actual)";
                        TempValueEntryBuffer."Cost Amount (Actual)" += ValueEntry."Cost Amount (Actual)";
                        TempValueEntryBuffer."Cost Amount (Non-Invtbl.)" += ValueEntry."Cost Amount (Non-Invtbl.)";
                        TempValueEntryBuffer."Discount Amount" += ValueEntry."Discount Amount";

                        // Add cost adjustments regardless of their posting date
                        ValueEntry.SetRange("Item Charge No.", '');
                        ValueEntry.SetRange(Adjustment, true);
                        ValueEntry.CalcSums("Cost Amount (Actual)");
                        TempValueEntryBuffer."Cost Amount (Actual)" += ValueEntry."Cost Amount (Actual)";
                    end;

                    OnAfterGetValueEntryOnBeforeTempValueEntryBufferInsertModify("Value Entry", TempValueEntryBuffer);

                    if EntryInBufferExists then
                        TempValueEntryBuffer.Modify()
                    else
                        TempValueEntryBuffer.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempValueEntryBuffer.Reset();
                    TempValueEntryBuffer.DeleteAll();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ValueEntryBuffer__Item_No__; TempValueEntryBuffer."Item No.")
                {
                }
                column(Item_Description; Item.Description)
                {
                }
                column(ValueEntryBuffer__Invoiced_Quantity_; -TempValueEntryBuffer."Invoiced Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ValueEntryBuffer__Sales_Amount__Actual___Control44; TempValueEntryBuffer."Sales Amount (Actual)")
                {
                    AutoFormatType = 1;
                }
                column(ValueEntryBuffer__Discount_Amount__Control45; -TempValueEntryBuffer."Discount Amount")
                {
                    AutoFormatType = 1;
                }
                column(Profit_Control46; Profit)
                {
                    AutoFormatType = 1;
                }
                column(ProfitPct_Control47; ProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempValueEntryBuffer.Find('-')
                    else
                        TempValueEntryBuffer.Next();

                    TempValueEntryBuffer."Sales Amount (Actual)" :=
                      ReportMgmnt.RoundAmount(TempValueEntryBuffer."Sales Amount (Actual)", Rounding);
                    TempValueEntryBuffer."Cost Amount (Actual)" :=
                      ReportMgmnt.RoundAmount(TempValueEntryBuffer."Cost Amount (Actual)", Rounding);
                    TempValueEntryBuffer."Discount Amount" :=
                      ReportMgmnt.RoundAmount(TempValueEntryBuffer."Discount Amount", Rounding);
                    TempValueEntryBuffer."Cost Amount (Non-Invtbl.)" :=
                      ReportMgmnt.RoundAmount(TempValueEntryBuffer."Cost Amount (Non-Invtbl.)", Rounding);
                    TempValueEntryBuffer.Modify();

                    Profit :=
                      TempValueEntryBuffer."Sales Amount (Actual)" +
                      TempValueEntryBuffer."Cost Amount (Actual)" +
                      TempValueEntryBuffer."Cost Amount (Non-Invtbl.)";

                    if Item.Get(TempValueEntryBuffer."Item No.") then;
                end;

                trigger OnPreDataItem()
                begin
                    TempValueEntryBuffer.Reset();
                    SetRange(Number, 1, TempValueEntryBuffer.Count);
                    Clear(Profit);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RoundingNO := Rounding;
                RoundingText := ReportMgmnt.RoundDescription(Rounding);
            end;

            trigger OnPreDataItem()
            begin
                Clear(Profit);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer/Item Sales';
        AboutText = 'Analyse your item sales per customer to understand sales trends, optimise inventory management and improve marketing efforts. Assess the relationship between discounts, sales amount and volume of sales for each customer/item combination in the given period.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer''s information is printed on a new page if you have chosen two or more customers to be included in the report.';
                    }
                    field(AmountsInWhole; Rounding)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
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
        if Customer.IsEmpty() and GuiAllowed() then
            Error(EmptyReportDatasetTxt);
    end;

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        ValueEntryFilter := "Value Entry".GetFilters();
        PeriodText := "Value Entry".GetFilter("Posting Date");
    end;

    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ReportMgmnt: Codeunit "Report Management APAC";
        Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        RoundingText: Text[50];
        CustFilter: Text;
        ValueEntryFilter: Text;
        PeriodText: Text;
        PrintOnlyOnePerPage: Boolean;
        Profit: Decimal;
        ProfitPct: Decimal;
        RoundingNO: Integer;

        Text000: Label 'Period: %1';
        Customer_Item_SalesCaptionLbl: Label 'Customer/Item Sales';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        ValueEntryBuffer__Item_No__CaptionLbl: Label 'Item No.';
        Item_DescriptionCaptionLbl: Label 'Description';
        ValueEntryBuffer__Invoiced_Quantity_CaptionLbl: Label 'Invoiced Quantity';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit of Measure';
        ValueEntryBuffer__Sales_Amount__Actual___Control44CaptionLbl: Label 'Amount';
        ValueEntryBuffer__Discount_Amount__Control45CaptionLbl: Label 'Discount Amount';
        Profit_Control46CaptionLbl: Label 'Profit';
        ProfitPct_Control47CaptionLbl: Label 'Profit %';
        TotalCaptionLbl: Label 'Total';
        EmptyReportDatasetTxt: Label 'There is nothing to print for the selected filters.';

    protected var
        Item: Record Item;
        TempValueEntryBuffer: Record "Value Entry" temporary;

    procedure InitializeRequest(NewPagePerCustomer: Boolean)
    begin
        PrintOnlyOnePerPage := NewPagePerCustomer;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetValueEntryOnBeforeTempValueEntryBufferInsertModify(ValueEntry: Record "Value Entry"; var TempValueEntry: Record "Value Entry" temporary)
    begin
    end;
}
