// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Utilities;

report 113 "Customer/Item Sales"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer/Item Sales';
    DefaultRenderingLayout = Word;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(PeriodTxt, PeriodText))
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
            {
            }
            column(Customer_TABLECAPTION__________CustFilter; CustFilterHeading)
            {
            }
            column(Value_Entry__TABLECAPTION__________ItemLedgEntryFilter; ValueEntryFilterHeading)
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
#if not CLEAN27
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustFilter; CustFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ItemLedgEntryFilter; ValueEntryFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(Customer_Item_SalesCaption; Customer_Item_SalesCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ValueEntryBuffer__Item_No__Caption; ValueEntryBuffer__Item_No__CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ValueEntryBuffer__Invoiced_Quantity_Caption; ValueEntryBuffer__Invoiced_Quantity_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ValueEntryBuffer__Sales_Amount__Actual___Control44Caption; ValueEntryBuffer__Sales_Amount__Actual___Control44CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ValueEntryBuffer__Discount_Amount__Control45Caption; ValueEntryBuffer__Discount_Amount__Control45CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(Profit_Control46Caption; Profit_Control46CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ProfitPct_Control47Caption; ProfitPct_Control47CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(Customer__Phone_No__Caption; FieldCaption("Phone No."))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(TotalCaption; TotalCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
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
                column(CustNo; Customer."No.")
                {
                }
                column(CustName; Customer.Name)
                {
                }
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
                var
                    Amount: Decimal;
                begin
                    if Number = 1 then
                        TempValueEntryBuffer.Find('-')
                    else
                        TempValueEntryBuffer.Next();

                    Profit :=
                      TempValueEntryBuffer."Sales Amount (Actual)" +
                      TempValueEntryBuffer."Cost Amount (Actual)" +
                      TempValueEntryBuffer."Cost Amount (Non-Invtbl.)";

                    Amount := TempValueEntryBuffer."Sales Amount (Actual)";
                    ProfitPct := CalculateProfitPercent(Amount, Profit);

                    if Item.Get(TempValueEntryBuffer."Item No.") then;

                    SubtotalsAmount += Amount;
                    SubtotalsDiscountAmount += -TempValueEntryBuffer."Discount Amount";
                    SubtotalsProfit += Profit;
                    SubtotalsProfitPercent := CalculateProfitPercent(SubtotalsAmount, SubtotalsProfit);

                    TotalsAmount += Amount;
                    TotalsDiscountAmount += -TempValueEntryBuffer."Discount Amount";
                    TotalsProfit += Profit;
                    TotalsProfitPercent := CalculateProfitPercent(TotalsAmount, TotalsProfit);

                    if not ReportHasData then
                        ReportHasData := not TempValueEntryBuffer.IsEmpty();
                end;

                trigger OnPreDataItem()
                begin
                    TempValueEntryBuffer.Reset();
                    SetRange(Number, 1, TempValueEntryBuffer.Count());
                    Clear(Profit);
                end;
            }
            dataitem(Subtotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(Subtotals_Amount; SubtotalsAmount)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_DiscountAmount; SubtotalsDiscountAmount)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_Profit; SubtotalsProfit)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_ProfitPercent; SubtotalsProfitPercent)
                {
                    AutoFormatType = 1;
                }

                trigger OnPreDataItem()
                begin
                    if TempValueEntryBuffer.IsEmpty() then
                        CurrReport.Break();
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(Profit);
            end;

            trigger OnAfterGetRecord()
            begin
                Clear(SubtotalsAmount);
                Clear(SubtotalsDiscountAmount);
                Clear(SubtotalsProfit);
                Clear(SubtotalsProfitPercent);
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Totals_Amount; TotalsAmount)
            {
                AutoFormatType = 1;
            }
            column(Totals_DiscountAmount; TotalsDiscountAmount)
            {
                AutoFormatType = 1;
            }
            column(Totals_Profit; TotalsProfit)
            {
                AutoFormatType = 1;
            }
            column(Totals_ProfitPercent; TotalsProfitPercent)
            {
                AutoFormatType = 1;
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer/Item Sales';
        AboutText = 'Analyze your item sales per customer to understand sales trends, optimize inventory management and improve marketing efforts. Assess the relationship between discounts, sales amount and volume of sales for each customer/item combination in the given period.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer''s information is printed on a new page if you have chosen two or more customers to be included in the report.';
                    }
                    // Used to set a report header across multiple languages
                    field(RequestPeriodText; PeriodText)
                    {
                        ApplicationArea = All;
                        Caption = 'Period';
                        ToolTip = 'Specifies the Date Period applied to this report.';
                        Visible = false;
                    }
                    // Used to set a report header across multiple languages
                    field(RequestCustFilterHeading; CustFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer Filter';
                        ToolTip = 'Specifies the Customer Filters applied to this report.';
                        Visible = false;
                    }
                    // Used to set a report header across multiple languages
                    field(RequestValueEntryFilterHeading; ValueEntryFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Value Entry Filter';
                        ToolTip = 'Specifies the Value Entry filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Customer Item Sales Excel';
            Type = Excel;
            LayoutFile = './Sales/Reports/CustomerItemSales.xlsx';
        }
        layout(Word)
        {
            Caption = 'Customer Item Sales Word';
            Type = Word;
            LayoutFile = './Sales/Reports/CustomerItemSales.docx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Customer/Item Sales RDLC';
            Type = RDLC;
            LayoutFile = './Sales/Reports/CustomerItemSales.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        CustomerItemSalesLabel = 'Customer/Item Sales';
        CustomerItemSalesPrint = 'Customer Item Sales (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CustomerItemSalesAnalysis = 'Customer Item Sales (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        PeriodCaption = 'Period:';
        CustNoCaption = 'Customer No.';
        CustNameCaption = 'Customer Name';
        ItemNoCaption = 'Item No.';
        ItemDescCaption = 'Item Description';
        UnitOfMeasureCaption = 'Unit of Measure';
        InvoicedQuantityCaption = 'Invoiced Quantity';
        AmountCaption = 'Amount';
        DiscountAmountCaption = 'Discount Amount';
        ProfitCaption = 'Profit';
        ProfitPercentCaption = 'Profit %';
        AllAmountsInLCYCaption = 'All amounts are in LCY';
        TotalLbl = 'Total';
        // About the report labels
        AboutTheReportLabel = 'About the report';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
    end;

    trigger OnPostReport()
    begin
        if Customer.IsEmpty() and GuiAllowed() then
            Error(EmptyReportDatasetTxt);
    end;

    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        CustFilter: Text;
        ValueEntryFilter: Text;
        CustFilterHeading: Text;
        ValueEntryFilterHeading: Text;
        PeriodText: Text;
        PrintOnlyOnePerPageReq: Boolean;
        Profit: Decimal;
        ProfitPct: Decimal;
        SubtotalsAmount: Decimal;
        SubtotalsDiscountAmount: Decimal;
        SubtotalsProfit: Decimal;
        SubtotalsProfitPercent: Decimal;
        TotalsAmount: Decimal;
        TotalsDiscountAmount: Decimal;
        TotalsProfit: Decimal;
        TotalsProfitPercent: Decimal;
        ReportHasData: Boolean;
        EmptyReportDatasetTxt: Label 'There is nothing to print for the selected filters.';
        PeriodTxt: Label 'Period: %1', Comment = '%1 - period text';
#if not CLEAN27
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
#endif

    protected var
        Item: Record Item;
        TempValueEntryBuffer: Record "Value Entry" temporary;

    procedure InitializeRequest(NewPagePerCustomer: Boolean)
    begin
        PrintOnlyOnePerPageReq := NewPagePerCustomer;
    end;

    procedure CalculateProfitPercent(Amount: Decimal; ProfitAmt: Decimal) ProfitPercent: Decimal
    begin
        if Amount <> 0 then
            ProfitPercent := Round((100 * ProfitAmt / Amount), 0.1, '=')
        else
            ProfitPercent := 0;
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        ValueEntryFilter := "Value Entry".GetFilters();
        PeriodText := "Value Entry".GetFilter("Posting Date");

        CustFilterHeading := '';
        ValueEntryFilterHeading := '';
        if CustFilter <> '' then
            CustFilterHeading := Customer.TableCaption + ': ' + CustFilter;
        if ValueEntryFilter <> '' then
            ValueEntryFilterHeading := "Value Entry".TableCaption + ': ' + ValueEntryFilter;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetValueEntryOnBeforeTempValueEntryBufferInsertModify(ValueEntry: Record "Value Entry"; var TempValueEntry: Record "Value Entry" temporary)
    begin
    end;
}

