// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 6950 "Expense Report Details"
{
    DefaultRenderingLayout = "ExpenseReportDetails.rdlc";
    Caption = 'Expense Report Details';
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Expense Report Header"; "Expense Report Header")
        {
            RequestFilterFields = "No.";

            column(No_; "No.")
            {
            }
            column(ExpenseUserNo; "Expense User No.")
            {
            }
            column(ExpenseUserName; "Expense User Name")
            {
            }
            column(Status; Status)
            {
            }
            column(Submitted_Date; DT2Date("Submission DateTime"))
            {
            }
            column(Expense_Report_Date; "Expense Report Date")
            {
            }
            column(Description; Description)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(CompanyAddress6; CompanyAddress[6])
            {
            }
            column(CompanyAddress7; CompanyAddress[7])
            {
            }
            column(CompanyAddress8; CompanyAddress[8])
            {
            }
            column(ReportMonth; Format("Expense Report Date", 0, '<Month Text> <Year4>'))
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(ExpenseUserNoLbl; "Expense Report Header".FieldCaption("Expense User No."))
            {
            }
            column(ExpenseUserNameLbl; "Expense Report Header".FieldCaption("Expense User Name"))
            {
            }
            column(StatusLbl; "Expense Report Header".FieldCaption(Status))
            {
            }
            column(SubmittedDateLbl; SubmittedDateLbl)
            {
            }
            column(ReportTitleLbl; ReportTitleLbl)
            {
            }
            column(ExpenseCategoryLbl; "Expense Report Line".FieldCaption("Expense Category"))
            {
            }
            column(ExpenseDateLbl; "Expense Report Line".FieldCaption("Expense Date"))
            {
            }
            column(MerchantLbl; "Expense Report Line".FieldCaption("Merchant Name"))
            {
            }
            column(PaymentMethodLbl; "Expense Report Line".FieldCaption("Payment Method Code"))
            {
            }
            column(AmountLbl; "Expense Report Line".FieldCaption(Amount))
            {
            }
            column(CurrencyLbl; "Expense Report Line".FieldCaption("Expense Currency Code"))
            {
            }
            column(ExpenseCurrencyRateLbl; ExchangeRateLbl)
            {
            }
            column(AmountLCYLbl; "Expense Report Line".FieldCaption("Amount (LCY)"))
            {
            }
            column(ReimbursableAmountLCYLbl; "Expense Report Line".FieldCaption("Reimbursable Amount (LCY)"))
            {
            }
            column(ProjectNoLbl; "Expense Report Line".FieldCaption("Job No."))
            {
            }
            column(BillableLbl; "Expense Report Line".FieldCaption(Billable))
            {
            }
            column(DescriptionLbl; "Expense Report Line".FieldCaption(Description))
            {
            }
            column(AdditionalInformationLbl; "Expense Report Line".FieldCaption("Additional Information"))
            {
            }
            column(JustificationLbl; "Expense Report Line".FieldCaption(Justification))
            {
            }
            column(Page_Lbl; PageLbl)
            {
            }
            dataitem("Expense Report Line"; "Expense Report Line")
            {
                DataItemLink = "Document No." = field("No.");

                column(Expense_Category; "Expense Category")
                {
                }
                column(Expense_Date; "Expense Date")
                {
                }
                column(Merchant; "Merchant Name")
                {
                }
                column(Payment_Method; "Payment Method Code")
                {
                }
                column(Amount; Amount)
                {
                }
                column(Currency_Code; "Expense Currency Code")
                {
                }
                column(Exchange_Rate; CurrencyExchangeRate)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Amount_LCY; "Amount (LCY)")
                {
                }
                column(Reimbursable_Amount_LCY; "Reimbursable Amount (LCY)")
                {
                }
                column(Project_No_; "Job No.")
                {
                }
                column(Billable; Billable)
                {
                }
                column(Line_Description; Description)
                {
                }
                column(Additional_Information; "Additional Information")
                {
                }
                column(Justification; Justification)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CurrencyExchangeRate := 0;

                    if "Expense Currency Factor" <> 0 then
                        CurrencyExchangeRate := 1 / "Expense Currency Factor"
                end;
            }
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Show Details"; ShowDetails)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies whether to show additional details in the report.';
                    }
                }
            }
        }
    }
    rendering
    {
        layout("ExpenseReportDetails.rdlc")
        {
            Type = RDLC;
            Caption = 'Expense Report Details';
            LayoutFile = 'src/ExpenseReport/Reports/ExpenseReportDetails.rdlc';
            Summary = 'Detailed expense report with lines and amounts.';
        }
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
    end;

    var
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        CompanyAddress: array[8] of Text[100];
        ShowDetails: Boolean;
        CurrencyExchangeRate: Decimal;
        PageLbl: Label 'Page';
        SubmittedDateLbl: Label 'Submitted Date';
        ReportTitleLbl: Label 'Expense Report';
        ExchangeRateLbl: Label 'Exchange Rate';
}