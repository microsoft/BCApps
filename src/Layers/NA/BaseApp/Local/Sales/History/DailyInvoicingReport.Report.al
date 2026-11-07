// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;
using System.Utilities;

report 10050 "Daily Invoicing Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/History/DailyInvoicingReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Daily Invoicing Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Currency; Currency)
        {
            DataItemTableView = sorting(Code);

            trigger OnAfterGetRecord()
            begin
                TempCurrency := Currency;
                TempCurrency.Insert();
            end;

            trigger OnPreDataItem()
            begin
                if UseCurrency then begin
                    Clear(TempCurrency);
                    TempCurrency.Insert();
                end else
                    CurrReport.Break();
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            PrintOnlyIfDetail = true;
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
            column(IncludeInvoices; IncludeInvoices)
            {
            }
            column(IncludeCreditMemos; IncludeCreditMemos)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(TempCurrency_TABLENAME__________TempCurrency_Code; TempCurrency.TableName + ': ' + TempCurrency.Code)
            {
            }
            column(TempCurrency_Description; TempCurrency.Description)
            {
            }
            column(TempCurrency_Code_Control1020000; TempCurrency.Code)
            {
            }
            column(UseCurrency; UseCurrency)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Daily_Invoicing_ReportCaption; Daily_Invoicing_ReportCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem("Sales Invoice Header"; "Sales Invoice Header")
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Posting Date", "Bill-to Customer No.", "Salesperson Code", "Payment Terms Code";
                RequestFilterHeading = 'Sales Invoice';
                column(Sales_Invoice_Header__No__; "No.")
                {
                }
                column(Sales_Invoice_Header__Posting_Date_; "Posting Date")
                {
                }
                column(Sales_Invoice_Header__Bill_to_Customer_No__; "Bill-to Customer No.")
                {
                }
                column(Sales_Invoice_Header__Bill_to_Name_; "Bill-to Name")
                {
                }
                column(Sales_Invoice_Header__Payment_Terms_Code_; "Payment Terms Code")
                {
                }
                column(Sales_Invoice_Header__Salesperson_Code_; "Salesperson Code")
                {
                }
                column(Sales_Invoice_Header_Amount; Amount)
                {
                }
                column(SalesTax; SalesTax)
                {
                }
                column(Sales_Invoice_Header__Amount_Including_VAT_; "Amount Including VAT")
                {
                }
                column(Sales_Invoice_Header_Amount_Control49; Amount)
                {
                }
                column(SalesTax_Control50; SalesTax)
                {
                }
                column(Sales_Invoice_Header__Amount_Including_VAT__Control51; "Amount Including VAT")
                {
                }
                column(TempCurrency_Code; TempCurrency.Code)
                {
                }
                column(Sales_Invoice_Header__No__Caption; Sales_Invoice_Header__No__CaptionLbl)
                {
                }
                column(Sales_Invoice_Header__Posting_Date_Caption; Sales_Invoice_Header__Posting_Date_CaptionLbl)
                {
                }
                column(Sales_Invoice_Header__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(Sales_Invoice_Header__Bill_to_Name_Caption; FieldCaption("Bill-to Name"))
                {
                }
                column(Sales_Invoice_Header__Payment_Terms_Code_Caption; FieldCaption("Payment Terms Code"))
                {
                }
                column(Sales_Invoice_Header__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
                {
                }
                column(Sales_Invoice_Header_AmountCaption; FieldCaption(Amount))
                {
                }
                column(SalesTaxCaption; SalesTaxCaptionLbl)
                {
                }
                column(Sales_Invoice_Header__Amount_Including_VAT_Caption; FieldCaption("Amount Including VAT"))
                {
                }
                column(Total_of_all_InvoicesCaption; Total_of_all_InvoicesCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if IncludeInvoices then begin
                        CalcFields(Amount, "Amount Including VAT");
                        SalesTax := "Amount Including VAT" - Amount;
                        TotalAmtExclTax := TotalAmtExclTax + Amount;
                        TotalSalesTax := TotalSalesTax + SalesTax;
                        TotalAmtInclTax := TotalAmtInclTax + "Amount Including VAT";
                    end else
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if not IncludeInvoices then
                        CurrReport.Break();

                    if UseCurrency then
                        SetRange("Currency Code", TempCurrency.Code);
                end;
            }
            dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
            {
                DataItemTableView = sorting("No.");
                column(Sales_Cr_Memo_Header__No__; "No.")
                {
                }
                column(Sales_Cr_Memo_Header__Posting_Date_; "Posting Date")
                {
                }
                column(Sales_Cr_Memo_Header__Bill_to_Customer_No__; "Bill-to Customer No.")
                {
                }
                column(Sales_Cr_Memo_Header__Bill_to_Name_; "Bill-to Name")
                {
                }
                column(Sales_Cr_Memo_Header__Applies_to_Doc__No__; "Applies-to Doc. No.")
                {
                }
                column(Sales_Cr_Memo_Header__Salesperson_Code_; "Salesperson Code")
                {
                }
                column(Sales_Cr_Memo_Header_Amount; Amount)
                {
                }
                column(SalesTax_Control60; SalesTax)
                {
                }
                column(Sales_Cr_Memo_Header__Amount_Including_VAT_; "Amount Including VAT")
                {
                }
                column(Sales_Cr_Memo_Header_Amount_Control62; Amount)
                {
                }
                column(SalesTax_Control63; SalesTax)
                {
                }
                column(Sales_Cr_Memo_Header__Amount_Including_VAT__Control64; "Amount Including VAT")
                {
                }
                column(TempCurrency_Code_Control4; TempCurrency.Code)
                {
                }
                column(TotalAmtExclTax; TotalAmtExclTax)
                {
                }
                column(TotalSalesTax; TotalSalesTax)
                {
                }
                column(TotalAmtInclTax; TotalAmtInclTax)
                {
                }
                column(TempCurrency_Code_Control5; TempCurrency.Code)
                {
                }
                column(Sales_Cr_Memo_Header__No__Caption; Sales_Cr_Memo_Header__No__CaptionLbl)
                {
                }
                column(Cr__Memo_DateCaption; Cr__Memo_DateCaptionLbl)
                {
                }
                column(Sales_Cr_Memo_Header__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(Sales_Cr_Memo_Header__Bill_to_Name_Caption; FieldCaption("Bill-to Name"))
                {
                }
                column(Sales_Cr_Memo_Header__Applies_to_Doc__No__Caption; FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Sales_Cr_Memo_Header__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
                {
                }
                column(Sales_Cr_Memo_Header_AmountCaption; FieldCaption(Amount))
                {
                }
                column(SalesTax_Control60Caption; SalesTax_Control60CaptionLbl)
                {
                }
                column(Sales_Cr_Memo_Header__Amount_Including_VAT_Caption; FieldCaption("Amount Including VAT"))
                {
                }
                column(Total_of_all_Credit_MemosCaption; Total_of_all_Credit_MemosCaptionLbl)
                {
                }
                column(Grand_Total_of_all_Invoices_and_Credit_MemosCaption; Grand_Total_of_all_Invoices_and_Credit_MemosCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if IncludeCreditMemos then begin
                        CalcFields(Amount, "Amount Including VAT");
                        SalesTax := "Amount Including VAT" - Amount;
                        TotalAmtExclTax := TotalAmtExclTax - Amount;
                        TotalSalesTax := TotalSalesTax - SalesTax;
                        TotalAmtInclTax := TotalAmtInclTax - "Amount Including VAT";
                    end else
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if IncludeCreditMemos then begin
                        if UseCurrency then
                            SetRange("Currency Code", TempCurrency.Code);
                        "Sales Invoice Header".CopyFilter("Posting Date", "Posting Date");
                        "Sales Invoice Header".CopyFilter("Bill-to Customer No.", "Bill-to Customer No.");
                        "Sales Invoice Header".CopyFilter("Salesperson Code", "Salesperson Code");
                        "Sales Invoice Header".CopyFilter("Payment Terms Code", "Payment Terms Code");
                        "Sales Invoice Header".CopyFilter("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
                        "Sales Invoice Header".CopyFilter("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
                        "Sales Invoice Header".CopyFilter("Sell-to Customer No.", "Sell-to Customer No.");
                        "Sales Invoice Header".CopyFilter("Location Code", "Location Code");
                        "Sales Invoice Header".CopyFilter("Tax Area Code", "Tax Area Code");
                        "Sales Invoice Header".CopyFilter("Responsibility Center", "Responsibility Center");
                    end else
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if UseCurrency then
                    if Number = 1 then
                        TempCurrency.Find('-')
                    else
                        TempCurrency.Next();

                TotalAmtExclTax := 0.0;
                TotalSalesTax := 0.0;
                TotalAmtInclTax := 0.0;
            end;

            trigger OnPreDataItem()
            begin
                if UseCurrency then
                    SetRange(Number, 1, TempCurrency.Count)
                else begin
                    SetRange(Number, 1);
                    Clear(TempCurrency);
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
                    field(IncludeInvoices; IncludeInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Invoices';
                        ToolTip = 'Specifies if the report includes invoices.';
                    }
                    field(IncludeCreditMemos; IncludeCreditMemos)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Credit Memos';
                        ToolTip = 'Specifies if the report includes credit memos.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            IncludeInvoices := IncludeInvoices;
            IncludeCreditMemos := IncludeCreditMemos;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        IncludeInvoices := true;
        IncludeCreditMemos := false;
    end;

    trigger OnPreReport()
    begin
        if not (IncludeInvoices or IncludeCreditMemos) then
            Error(Text000);

        CompanyInformation.Get();
        FilterString := "Sales Invoice Header".GetFilters();
        UseCurrency := Currency.Find('-');
    end;

    var
        CompanyInformation: Record "Company Information";
        TempCurrency: Record Currency temporary;
        FilterString: Text;
        SalesTax: Decimal;
        IncludeInvoices: Boolean;
        IncludeCreditMemos: Boolean;
        UseCurrency: Boolean;
        TotalAmtExclTax: Decimal;
        TotalSalesTax: Decimal;
        TotalAmtInclTax: Decimal;
        Text000: Label 'You must Include either Invoices or Credit Memos.';
        Daily_Invoicing_ReportCaptionLbl: Label 'Daily Invoicing Report';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Sales_Invoice_Header__No__CaptionLbl: Label 'Invoice Number';
        Sales_Invoice_Header__Posting_Date_CaptionLbl: Label 'Invoice Date';
        SalesTaxCaptionLbl: Label 'Sales Tax';
        Total_of_all_InvoicesCaptionLbl: Label 'Total of all Invoices';
        Sales_Cr_Memo_Header__No__CaptionLbl: Label 'Cr. Memo Number';
        Cr__Memo_DateCaptionLbl: Label 'Cr. Memo Date';
        SalesTax_Control60CaptionLbl: Label 'Sales Tax';
        Total_of_all_Credit_MemosCaptionLbl: Label 'Total of all Credit Memos';
        Grand_Total_of_all_Invoices_and_Credit_MemosCaptionLbl: Label 'Grand Total of all Invoices and Credit Memos';
}

