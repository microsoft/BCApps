// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Foundation.Period;

/// <summary>
/// Displays comprehensive statistical information and key performance indicators for bank accounts.
/// Provides summary view of balances, transaction volumes, and period-based analysis.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Read-only statistical view with calculated fields.
/// Features balance summaries, transaction counts, and period-based comparative analysis.
/// </remarks>
page 375 "Bank Account Statistics"
{
    Caption = 'Bank Account Statistics';
    DataCaptionFields = "No.", Name;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group("Balance Group")
            {
                Caption = 'Balance';
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the bank account''s current balance in LCY.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field("Min. Balance"; Rec."Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies a minimum balance for the bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency';
                    Lookup = false;
                    ToolTip = 'Specifies the currency code for the bank account.';
                }
            }
            group("Net Change")
            {
                Caption = 'Net Change';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Period';
                        field("BankAccDateName[1]"; BankAccDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Date Name';
                            ToolTip = 'Specifies the date.';
                        }
                        field("BankAccNetChange[1]"; BankAccNetChange[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[1]"; BankAccNetChangeLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field(Text000; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[2]"; BankAccNetChange[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[2]"; BankAccNetChangeLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field("Placeholder 2"; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[3]"; BankAccNetChange[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[3]"; BankAccNetChangeLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("To Date")
                    {
                        Caption = 'To Date';
                        field("Placeholder 3"; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[4]"; BankAccNetChange[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[4]"; BankAccNetChangeLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                }
            }
            group("Receivable Bills")
            {
                Caption = 'Receivable Bills';
                fixed(Control1903836701)
                {
                    ShowCaption = false;
                    group(Control1900249401)
                    {
                        Caption = 'This Period';
                        field("Posted Receiv. Bills Amt."; Rec."Posted Receiv. Bills Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ToolTip = 'Specifies the amount of the bills, included in the bill groups, posted and delivered to this bank.';
                        }
                        field("Closed Receiv. Bills Amt."; Rec."Closed Receiv. Bills Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ToolTip = 'Specifies the amount of the closed bills delivered to this bank.';
                        }
                        field("TotalHonoredDocs[1]"; TotalHonoredDocs[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Honored Bills Amt.';
                            ToolTip = 'Specifies the amount on honored bills. ';
                        }
                        field("TotalRejectedDocs[1]"; TotalRejectedDocs[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Rejected Bills Amt.';
                            ToolTip = 'Specifies the amount on rejected bills.';
                        }
                        field("DocDiscIntAmt[1]"; DocDiscIntAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Discount Interests Amt.';
                            ToolTip = 'Specifies the amount that relates to interest charged in connection with discount payments.';
                        }
                        field("DocDiscExpAmt[1]"; DocDiscExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Discount Expenses Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection with discount payments.';
                        }
                        field("DocCollExpAmt[1]"; DocCollExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Collection Expenses Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection with collection payments.';
                        }
                        field("DocRejExpAmt[1]"; DocRejExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Rejection Expenses Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection with rejections.';
                        }
                    }
                    group(Control1902148501)
                    {
                        Caption = 'This Year';
                        field(Control1100031; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100032; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredDocs[2]"; TotalHonoredDocs[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedDocs[2]"; TotalRejectedDocs[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscIntAmt[2]"; DocDiscIntAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscExpAmt[2]"; DocDiscExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocCollExpAmt[2]"; DocCollExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocRejExpAmt[2]"; DocRejExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                    }
                    group(Control1906484001)
                    {
                        Caption = 'Last Year';
                        field(Control1100033; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100034; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredDocs[3]"; TotalHonoredDocs[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedDocs[3]"; TotalRejectedDocs[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscIntAmt[3]"; DocDiscIntAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscExpAmt[3]"; DocDiscExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocCollExpAmt[3]"; DocCollExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocRejExpAmt[3]"; DocRejExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                    }
                    group(Control1906936701)
                    {
                        Caption = 'To Date';
                        field(Control1100035; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100036; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredDocs[4]"; TotalHonoredDocs[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedDocs[4]"; TotalRejectedDocs[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscIntAmt[4]"; DocDiscIntAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocDiscExpAmt[4]"; DocDiscExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocCollExpAmt[4]"; DocCollExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("DocRejExpAmt[4]"; DocRejExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                    }
                }
            }
            group(Factoring)
            {
                Caption = 'Factoring';
                fixed(Control1903442601)
                {
                    ShowCaption = false;
                    group(Control1905716001)
                    {
                        Caption = 'This Period';
                        field(Control66; BankAccDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("TotalHonoredInvoices[1]"; TotalHonoredInvoices[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Honored Inv. Amt.';
                            ToolTip = 'Specifies the amount on honored invoices. ';
                        }
                        field("TotalRejectedInvoices[1]"; TotalRejectedInvoices[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Rejected Inv. Amt.';
                            ToolTip = 'Specifies the amount on rejected invoices.';
                        }
                        field("FactDiscIntAmt[1]"; FactDiscIntAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Discount Interests Amt.';
                            ToolTip = 'Specifies the amount that relates to interest charged in connection with discount payments.';
                        }
                        field("RiskFactExpAmt[1]"; RiskFactExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Risked Factoring Exp. Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection risked factoring.';
                        }
                        field("UnriskFactExpAmt[1]"; UnriskFactExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Unrisked Factoring Exp. Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection unrisked factoring.';
                        }
                        field("Post. Receivable Inv. Amt."; Rec."Post. Receivable Inv. Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ToolTip = 'Specifies the amount of the invoices included in bill groups, posted and delivered to this bank.';
                        }
                        field("Clos. Receivable Inv. Amt."; Rec."Clos. Receivable Inv. Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ToolTip = 'Specifies the amount of the closed invoices delivered to this bank.';
                        }
                    }
                    group(Control1905520001)
                    {
                        Caption = 'This Year';
                        field(Control1100048; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredInvoices[2]"; TotalHonoredInvoices[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedInvoices[2]"; TotalRejectedInvoices[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("FactDiscIntAmt[2]"; FactDiscIntAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("RiskFactExpAmt[2]"; RiskFactExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("UnriskFactExpAmt[2]"; UnriskFactExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100038; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100039; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                    group(Control1903594901)
                    {
                        Caption = 'Last Year';
                        field(Control1100049; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredInvoices[3]"; TotalHonoredInvoices[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedInvoices[3]"; TotalRejectedInvoices[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("FactDiscIntAmt[3]"; FactDiscIntAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("RiskFactExpAmt[3]"; RiskFactExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("UnriskFactExpAmt[3]"; UnriskFactExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100044; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100045; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                    group(Control1907930401)
                    {
                        Caption = 'To Date';
                        field(Control1100050; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredInvoices[4]"; TotalHonoredInvoices[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("TotalRejectedInvoices[4]"; TotalRejectedInvoices[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("FactDiscIntAmt[4]"; FactDiscIntAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("RiskFactExpAmt[4]"; RiskFactExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("UnriskFactExpAmt[4]"; UnriskFactExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100046; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100047; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                }
            }
            group("Payable Documents")
            {
                Caption = 'Payable Documents';
                fixed(Control1907778101)
                {
                    ShowCaption = false;
                    group(Control1906168701)
                    {
                        Caption = 'This Period';
                        field(Control91; BankAccDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("TotalHonoredPayableDoc[1]"; TotalHonoredPayableDoc[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Total Honored Amt.';
                            ToolTip = 'Specifies the amount on all honored documents. ';
                        }
                        field("PmtOrdExpAmt[1]"; PmtOrdExpAmt[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Payment Order Expenses Amt.';
                            ToolTip = 'Specifies the amount that relates to commission and charges in connection with payment orders.';
                        }
                        field("Posted Pay. Documents Amt."; Rec."Posted Pay. Documents Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Posted Documents';
                            ToolTip = 'Specifies the value of the pending amount, for payable documents posted to this bank.';
                        }
                        field("Closed Pay. Documents Amt."; Rec."Closed Pay. Documents Amt.")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Closed Documents';
                            ToolTip = 'Specifies the amount of the closed payable documents delivered to this bank.';
                        }
                    }
                    group(Control1907591201)
                    {
                        Caption = 'This Year';
                        field(Control1100053; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredPayableDoc[2]"; TotalHonoredPayableDoc[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("PmtOrdExpAmt[2]"; PmtOrdExpAmt[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100056; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100059; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                    group(Control1904043901)
                    {
                        Caption = 'Last Year';
                        field(Control1100054; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredPayableDoc[3]"; TotalHonoredPayableDoc[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("PmtOrdExpAmt[3]"; PmtOrdExpAmt[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100057; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100060; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                    group(Control1907649801)
                    {
                        Caption = 'To Date';
                        field(Control1100055; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field("TotalHonoredPayableDoc[4]"; TotalHonoredPayableDoc[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field("PmtOrdExpAmt[4]"; PmtOrdExpAmt[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                        }
                        field(Control1100058; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100061; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                }
            }
            group("Bill Groups")
            {
                Caption = 'Bill Groups';
                field(Control1100062; PlaceholderLbl)
                {
                    ApplicationArea = Advanced;
                    Visible = false;
                }
                field(Control1100063; PlaceholderLbl)
                {
                    ApplicationArea = Advanced;
                    Visible = false;
                }
                fixed(Control1903384001)
                {
                    ShowCaption = false;
                    group(Control1905829501)
                    {
                        ShowCaption = false;
                        field("Last Bill Gr. No."; Rec."Last Bill Gr. No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the number of the last posted bill group sent to this bank.';
                        }
                        field("Date of Last Post. Bill Gr."; Rec."Date of Last Post. Bill Gr.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the posting date of the last bill group sent to this bank.';
                        }
                        field("Credit Limit for Discount"; Rec."Credit Limit for Discount")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ToolTip = 'Specifies the credit limit for the discount of bills available at this particular bank.';
                        }
                        field(DocsForDiscRmgAmt; DocsForDiscRmgAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Bills for Disc. Remg. Amt.';
                            ToolTip = 'Specifies remaining amounts on bills for discount.';
                        }
                        field(DocsForCollRmgAmt; DocsForCollRmgAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Bills for Coll. Remg. Amt.';
                            ToolTip = 'Specifies remaining amounts on bills for collection.';
                        }
                    }
                    group(Control1905435401)
                    {
                        ShowCaption = false;
                        field(Control1100064; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100065; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(Control1100066; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                        field(RiskPerc; RiskPerc)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(Control1100067; PlaceholderLbl)
                        {
                            ApplicationArea = Advanced;
                            Visible = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        BankAcc.Copy(Rec);

        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(BankAccDateFilter[1], BankAccDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(BankAccDateFilter[2], BankAccDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(BankAccDateFilter[3], BankAccDateName[3], CurrentDate, -1);
        end;

        BankAcc.SetRange("Date Filter", 0D, CurrentDate);
        BankAcc.CalcFields(Balance, "Balance (LCY)");

        BankAcc.SetRange("Date Filter");
        BankAcc.SetRange("Dealing Type Filter", 1);
        // Discount
        BankAcc.CalcFields("Posted Receiv. Bills Rmg. Amt.");
        DocsForDiscRmgAmt := BankAcc."Posted Receiv. Bills Rmg. Amt.";
        if BankAcc."Credit Limit for Discount" = 0 then
            if DocsForDiscRmgAmt = 0 then
                RiskPerc := 0
            else
                RiskPerc := 100
        else
            RiskPerc := DocsForDiscRmgAmt / BankAcc."Credit Limit for Discount" * 100;

        BankAcc.SetRange("Dealing Type Filter", 0);
        // Collection
        BankAcc.CalcFields("Posted Receiv. Bills Rmg. Amt.", "Posted Pay. Bills Rmg. Amt.", "Posted Pay. Inv. Rmg. Amt.");
        DocsForCollRmgAmt := BankAcc."Posted Receiv. Bills Rmg. Amt.";
        PayableDocsRmgAmt := BankAcc."Posted Pay. Bills Rmg. Amt." + BankAcc."Posted Pay. Inv. Rmg. Amt.";
        for i := 1 to 4 do begin
            BankAcc.SetFilter("Date Filter", BankAccDateFilter[i]);
            BankAcc.CalcFields("Net Change", "Net Change (LCY)");
            BankAccNetChange[i] := BankAcc."Net Change";
            BankAccNetChangeLCY[i] := BankAcc."Net Change (LCY)";
        end;
        BankAcc.SetRange("Date Filter", 0D, CurrentDate);

        for i := 1 to 4 do begin
            BankAcc.SetFilter("Honored/Rejtd. at Date Filter", BankAccDateFilter[i]);
            BankAcc.SetRange("Status Filter", BankAcc."Status Filter"::Honored);
            BankAcc.CalcFields("Closed Receiv. Bills Amt.");
            BankAcc.CalcFields("Posted Receiv. Bills Amt.");
            BankAcc.CalcFields("Clos. Receivable Inv. Amt.");
            BankAcc.CalcFields("Post. Receivable Inv. Amt.");
            BankAcc.CalcFields("Closed Pay. Bills Amt.");
            BankAcc.CalcFields("Posted Pay. Bills Amt.");
            BankAcc.CalcFields("Closed Pay. Invoices Amt.");
            BankAcc.CalcFields("Posted Pay. Invoices Amt.");
            TotalHonoredDocs[i] := BankAcc."Closed Receiv. Bills Amt." + BankAcc."Posted Receiv. Bills Amt.";
            TotalHonoredInvoices[i] := BankAcc."Clos. Receivable Inv. Amt." + BankAcc."Post. Receivable Inv. Amt.";
            TotalHonoredPayableDoc[i] := BankAcc."Closed Pay. Bills Amt." + BankAcc."Closed Pay. Invoices Amt." +
              BankAcc."Posted Pay. Bills Amt." + BankAcc."Posted Pay. Invoices Amt.";
            BankAcc.SetRange("Status Filter", BankAcc."Status Filter"::Rejected);
            BankAcc.CalcFields("Closed Receiv. Bills Amt.");
            BankAcc.CalcFields("Posted Receiv. Bills Amt.");
            BankAcc.CalcFields("Clos. Receivable Inv. Amt.");
            BankAcc.CalcFields("Post. Receivable Inv. Amt.");
            BankAcc.CalcFields("Closed Pay. Bills Amt.");
            BankAcc.CalcFields("Posted Pay. Bills Amt.");
            BankAcc.CalcFields("Closed Pay. Invoices Amt.");
            BankAcc.CalcFields("Posted Pay. Invoices Amt.");
            TotalRejectedInvoices[i] := BankAcc."Clos. Receivable Inv. Amt." + BankAcc."Post. Receivable Inv. Amt.";
            TotalRejectedDocs[i] := BankAcc."Closed Receiv. Bills Amt." + BankAcc."Posted Receiv. Bills Amt.";
            TotalRejectedPayableDoc[i] := BankAcc."Closed Pay. Bills Amt." + BankAcc."Closed Pay. Invoices Amt." +
              BankAcc."Posted Pay. Bills Amt." + BankAcc."Posted Pay. Invoices Amt.";
        end;

        for i := 1 to 4 do begin
            DocCollExpAmt[i] := BankAcc.CollectionFeesTotalAmt(BankAccDateFilter[i]);
            DocDiscExpAmt[i] := BankAcc.ServicesFeesTotalAmt(BankAccDateFilter[i]);
            DocDiscIntAmt[i] := BankAcc.DiscInterestsTotalAmt(BankAccDateFilter[i]);
            DocRejExpAmt[i] := BankAcc.RejExpensesAmt(BankAccDateFilter[i]);
            FactDiscIntAmt[i] := BankAcc.DiscInterestFactTotalAmt(BankAccDateFilter[i]);
            RiskFactExpAmt[i] := BankAcc.RiskFactFeesTotalAmt(BankAccDateFilter[i]);
            UnriskFactExpAmt[i] := BankAcc.UnriskFactFeesTotalAmt(BankAccDateFilter[i]);
            PmtOrdExpAmt[i] := BankAcc.PaymentOrderFeesTotalAmt(BankAccDateFilter[i]);
        end;
    end;

    var
        BankAcc: Record "Bank Account";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        BankAccDateFilter: array[4] of Text[30];
        BankAccDateName: array[4] of Text[30];
        CurrentDate: Date;
        BankAccNetChange: array[4] of Decimal;
        BankAccNetChangeLCY: array[4] of Decimal;
        i: Integer;
        PlaceholderLbl: Label 'Placeholder';
        DocsForDiscRmgAmt: Decimal;
        DocsForCollRmgAmt: Decimal;
        PayableDocsRmgAmt: Decimal;
        DocCollExpAmt: array[4] of Decimal;
        DocDiscIntAmt: array[4] of Decimal;
        DocDiscExpAmt: array[4] of Decimal;
        DocRejExpAmt: array[4] of Decimal;
        TotalHonoredDocs: array[4] of Decimal;
        TotalRejectedDocs: array[4] of Decimal;
        RiskPerc: Decimal;
        TotalHonoredInvoices: array[4] of Decimal;
        TotalRejectedInvoices: array[4] of Decimal;
        FactDiscIntAmt: array[4] of Decimal;
        RiskFactExpAmt: array[4] of Decimal;
        UnriskFactExpAmt: array[4] of Decimal;
        TotalHonoredPayableDoc: array[4] of Decimal;
        TotalRejectedPayableDoc: array[4] of Decimal;
        PmtOrdExpAmt: array[4] of Decimal;
}

