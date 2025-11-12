// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Period;
using System.Security.User;
using System.Utilities;

page 118 "General Ledger Setup"
{
    AdditionalSearchTerms = 'finance setup,general ledger setup,g/l setup';
    ApplicationArea = Basic, Suite;
    Caption = 'General Ledger Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "General Ledger Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which posting to the company books is allowed.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which posting to the company books is allowed.';
                }
                field("Allow Deferral Posting From"; Rec."Allow Deferral Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which deferral posting to the company books is allowed.';
                }
                field("Allow Deferral Posting To"; Rec."Allow Deferral Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which deferral posting to the company books is allowed.';
                }
                field("VAT Reporting Date Usage"; Rec."VAT Reporting Date Usage")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the usage of VAT date.';

                    trigger OnValidate()
                    begin
                        if Rec."VAT Reporting Date Usage" = Rec."VAT Reporting Date Usage"::Disabled then
                            Rec."VAT Reporting Date" := Rec."VAT Reporting Date"::"Posting Date";
                    end;
                }
                group(VATReportingDateGroup)
                {
                    Visible = Rec."VAT Reporting Date Usage" <> Rec."VAT Reporting Date Usage"::Disabled;
                    ShowCaption = false;
                    field("Default VAT Reporting Date"; Rec."VAT Reporting Date")
                    {
                        ApplicationArea = VAT;
                        ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on this setting.';
                    }
                }
                field("Register Time"; Rec."Register Time")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to register users'' time usage defined as the time spent from when a user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded. This setting can be overruled per user by filling in the Register Time field in the User Setup window.';
                }
                field("Local Address Format"; Rec."Local Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format in which addresses must appear on printouts.';
                }
                field("Local Cont. Addr. Format"; Rec."Local Cont. Addr. Format")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
                }
                field("Req.Country/Reg. Code in Addr."; Rec."Req.Country/Reg. Code in Addr.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to clear the Post Code, City, and County fields when the value in the Country/Region Code field is changed.';
                }
                field("Inv. Rounding Precision (LCY)"; Rec."Inv. Rounding Precision (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding invoice amounts in LCY. Examples: 1.00: Round to whole numbers (no decimals - divisible by 1.00), 0.05: Round to a number divisible by 0.05, 0.01: No rounding (ordinary currency decimals). On the Currencies page, you specify how to round invoices in foreign currencies.';
                }
                field("Inv. Rounding Type (LCY)"; Rec."Inv. Rounding Type (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to round invoice amounts. The contents of this field determine whether the invoice amount to be rounded will be rounded up or down to the nearest interval as specified in the Invoice Rounding Precision field. If you select Nearest, digits that are higher than or equal to 5 will be rounded up, and digits that are lower than or equal to 5 will be rounded down.';
                }
                field(AmountRoundingPrecision; Rec."Amount Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Rounding Precision (LCY)';
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. Amounts will be rounded to the nearest digit. Example: To have amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how amounts in foreign currencies are rounded.';
                }
                field(AmountDecimalPlaces; Rec."Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Decimal Places (LCY)';
                    ToolTip = 'Specifies the number of decimal places that are shown for amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. The default setting, 2:2, specifies that all amounts in LCY are shown with a minimum of 2 decimal places and a maximum of 2 decimal places. You can also enter a fixed number, such as 2, which also means that amounts are shown with two decimals. On the Currencies page, you specify how many decimal places to show for amounts in foreign currencies.';
                }
                field(UnitAmountRoundingPrecision; Rec."Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Rounding Precision (LCY)';
                    ToolTip = 'Specifies the size of the interval to be used when rounding unit amounts, item or resource prices per unit, in LCY. Amounts will be rounded to the nearest digit. Example: To have unit amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how unit amounts in foreign currencies are rounded.';
                }
                field(UnitAmountDecimalPlaces; Rec."Unit-Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Decimal Places (LCY)';
                    ToolTip = 'Specifies the number of decimal places that are shown for unit amounts, item or resource prices per unit, in LCY. The default setting, 2:5, specifies that unit amounts will be shown with a minimum of two decimal places and a maximum of five decimal places. You can also enter a fixed number, such as 2, to specify that all unit amounts are shown with two decimal places. On the Currencies page, you specify how many decimal places to show for unit amounts in foreign currencies.';
                }
                field("Allow G/L Acc. Deletion Before"; Rec."Allow G/L Acc. Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if and when general ledger accounts can be deleted. If you enter a date, G/L accounts with entries on or after this date can be deleted only after confirmation by the user. This setting is only valid when "Block Deletion of G/L accounts" is set to No';
                }
                field("Block Deletion of G/L Accounts"; Rec."Block Deletion of G/L Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to prevent users from deleting G/L accounts with ledger entries that are after the date in the Check G/L Acc. Deletion After field. For example, blocking deletion helps you avoid losing financial data that your business should keep due to country regional requirements.';
                }
                field("Check G/L Account Usage"; Rec."Check G/L Account Usage")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you want the program to protect G/L accounts that are used in setup tables from being deleted.';
                }
                field("Mark Cr. Memos as Corrections"; Rec."Mark Cr. Memos as Corrections")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to automatically mark a new credit memo as a corrective entry. Correction flag does not affect how inventory reconciled with general ledger.';
                }
                field("Pmt. Disc. Excl. VAT"; Rec."Pmt. Disc. Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if the payment discount is calculated based on amounts including or excluding VAT.';
                }
                field("Adjust for Payment Disc."; Rec."Adjust for Payment Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to recalculate tax amounts when you post payments that trigger payment discounts.';
                }
                field("Unrealized VAT"; Rec."Unrealized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
                }
                field("Prepayment Unrealized VAT"; Rec."Prepayment Unrealized VAT")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to handle unrealized VAT on prepayments.';
                }
                field("Max. VAT Difference Allowed"; Rec."Max. VAT Difference Allowed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the maximum VAT correction amount allowed for the local currency. For example, if you enter 5 in this field for British Pounds, then you can correct VAT amounts by up to five pounds.';
                }
                field("Tax Invoice Renaming Threshold"; Rec."Tax Invoice Renaming Threshold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that if the amount on a sales invoice or a service invoice exceeds the threshold, then the name of the document is changed to include the words "Tax Invoice", as required by the tax authorities.';
                    Visible = false;
                }
                field("VAT Rounding Type"; Rec."VAT Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the program will round VAT when calculated for the local currency. When you enter an Amount Including VAT in a document, the system first calculates and rounds the Amount Excluding VAT, and then calculates by subtraction the VAT Amount because the total amount has to match the Amount Including VAT entered manually. In that case, the VAT Rounding Type does not apply as the Amount Excluding VAT is already rounded using the Amount Rounding Precision.';
                }
                field("Control VAT Period"; Rec."Control VAT Period")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a way of using VAT Date against VAT Return Periods. If you choose ‘Block posting within closed and warn for released period’, system will not allow postings in closed VAT Return Period, but if the period is not closed, but VAT returns are released or submitted, user will be warned what try to post an entry with VAT Date in this period. If you choose ‘Block posting within closed period’, system will still not allow postings in closed VAT Return Period, but there will be no warnings for release or submitted VAT returns. If you choose ‘Warn when posting in closed period’, system will not block posting entry with VAT Date in the closed VAT return period, but it will show warning message before posting. And if you choose ‘Disabled’ options, system will allow you to post without any control regardless of VAT return or period status.';
                }
                field("Bank Account Nos."; Rec."Bank Account Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bank accounts.';
                }
                field("Bill-to/Sell-to VAT Calc."; Rec."Bill-to/Sell-to VAT Calc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies where the VAT Bus. Posting Group code on an order or invoice is copied from. Bill-to/Pay-to No.: The VAT Bus. Posting Group code on sales invoices and orders is copied from the Bill-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Pay-to Vendor field. Sell-to/Buy-from No. : The VAT Bus. Posting Group code on sales invoices and orders is copied from the Sell-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Buy-from Vendor field.';
                }
                field("Print VAT specification in LCY"; Rec."Print VAT specification in LCY")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that an extra VAT specification in local currency will be included on documents in a foreign currency. This can be used to make tax audits easier when reconciling VAT payables to invoices.';
                }
                field("Show Amounts"; Rec."Show Amounts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies which type of amounts are shown in journals and in ledger entries windows. Amount Only: The Amount and Amount (LCY) fields are shown. Debit/Credit Only: The Debit Amount, Debit Amount (LCY), Credit Amount, and Credit Amount (LCY) fields are shown. All Amounts: All amount fields are shown. ';
                }
                field("Hide Payment Method Code"; Rec."Hide Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if payment method code is shown in sales and purchase documents.';
                }
                field("Hide Company Bank Account"; Rec."Hide Company Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether or not the Company Bank Account can be updated on posted documents.';
                }
                field(PostingPreviewType; Rec."Posting Preview Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the amount of detail to include in the posting preview. Standard gives an overview of entries grouped by type, and you can choose the type of entry to view details. Extended displays the details for G/L entries and VAT entries.';
                }
                field(SEPANonEuroExport; Rec."SEPA Non-Euro Export")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to use SEPA export for journal lines with currencies different from Euro.';
                }
                field(SEPAExportWoBankAccData; Rec."SEPA Export w/o Bank Acc. Data")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if it is possible to use SEPA direct debit export by filling in the Bank Branch No. and Bank Account No. fields instead of the IBAN and SWIFT No. fields on the bank account and customer bank account cards.';
                }
                field("Journal Templ. Name Mandatory"; Rec."Journal Templ. Name Mandatory")
                {
                    ApplicationArea = BasicBE;
                    Importance = Additional;
                    ToolTip = 'Specifies if a journal template and batch names are required when posting general ledger transactions. If you want to have template name in posted documents and entries, you must set this field as TRUE.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        IsJournalTemplatesVisible := Rec."Journal Templ. Name Mandatory";
                        CurrPage.Update();
                    end;
                }
                field(EnableDataCheck; Rec."Enable Data Check")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether Business Central validates the data you enter in documents and journals while you type. For documents, you can turn on the check and messages will be shown in the Document Check FactBox. For journals, messages are always shown in the Journal Check FactBox.';
                }
                field(CheckSourceCurrencyConsistency; Rec."Check Source Curr. Consistency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether Business Central validates the total of general ledger entries source currency amount during posting.';
                }
            }
            group(Control1900309501)
            {
                Caption = 'Dimensions';
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
            }
            group(Currency)
            {
                Caption = 'Currency';

                field("LCY Code"; Rec."LCY Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Local Currency Symbol"; Rec."Local Currency Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the symbol for the local currency that you want to appear on checks and charts, such as $ for USD.';
                }
                field("Local Currency Description"; Rec."Local Currency Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the local currency.';
                }
                field("EMU Currency"; Rec."EMU Currency")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;
                    ToolTip = 'Specifies if LCY is an EMU (Economic and Monetary Union) currency.';
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; Rec."Post with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post general ledger documents in the background.';
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post and print general ledger documents in the background.';
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a notification is sent when posting and printing is successfully completed.';
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Additional Reporting Currency"; Rec."Additional Reporting Currency")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that will be used as an additional reporting currency.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        Confirmed: Boolean;
                    begin
                        if Rec."Additional Reporting Currency" <> xRec."Additional Reporting Currency" then begin
                            if Rec."Additional Reporting Currency" = '' then
                                Confirmed := ConfirmManagement.GetResponseOrDefault(Text002, true)
                            else
                                Confirmed := ConfirmManagement.GetResponseOrDefault(Text003, true);
                            if not Confirmed then
                                Error('');
                        end;
                    end;
                }
                field("VAT Exchange Rate Adjustment"; Rec."VAT Exchange Rate Adjustment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the accounts set up for VAT posting in the VAT Posting Setup window will be adjusted for exchange rate fluctuations.';
                }
                field("Acc. Receivables Category"; Rec."Acc. Receivables Category")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the G/L Account Category that will be used for the Account Receivables accounts.';
                }
                field("Acc. Payables Category"; Rec."Acc. Payables Category")
                {
                    ApplicationArea = Suite;
                    Tooltip = 'Specifies the G/L Account Category that will be used for the Account Payables accounts.';
                }
                group("Financial Reports")
                {
                    Caption = 'Financial Reports';

                    field("Acc. Sched. for Balance Sheet"; Rec."Fin. Rep. for Balance Sheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance Sheet Report';
                    }
                    field("Acc. Sched. for Income Stmt."; Rec."Fin. Rep. for Income Stmt.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Income Statement Report';
                    }
                    field("Acc. Sched. for Cash Flow Stmt"; Rec."Fin. Rep. for Cash Flow Stmt")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Cash Flow Statement Report';
                    }
                    field("Acc. Sched. for Retained Earn."; Rec."Fin. Rep. for Retained Earn.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Retained Earnings Report';
                    }
                    field("Fin. Rep. Bal. Sheet Row"; Rec."Fin. Rep. Bal. Sheet Row")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Row Definition for Balance Sheet';
                    }
                    field("Fin. Rep. Income Stmt. Row"; Rec."Fin. Rep. Income Stmt. Row")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Row Definition for Income Statement';
                    }
                    field("Fin. Rep. Cash Flow Stmt. Row"; Rec."Fin. Rep. Cash Flow Stmt. Row")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Row Definition for Cash Flow Statement';
                    }
                    field("Fin. Rep. Retained Earn. Row"; Rec."Fin. Rep. Retained Earn. Row")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Row Definition for Retained Earnings';
                    }
                    field("Fin. Rep. Bal. Sheet Column"; Rec."Fin. Rep. Bal. Sheet Column")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column Definition for Balance Sheet';
                    }
                    field("Fin. Rep. Net Change Column"; Rec."Fin. Rep. Net Change Column")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column Definition for Net Change';
                    }
                    field("Fin. Rep. Period Type"; Rec."Fin. Rep. Period Type")
                    {
                        Caption = 'Default View by';
#if not CLEAN27
                        Visible = FinancialReportDefaultsEnabled;
#endif
                    }
                    field("Fin. Rep. Neg. Amount Format"; Rec."Fin. Rep. Neg. Amount Format")
                    {
                        Caption = 'Default Negative Amount Format';
#if not CLEAN27
                        Visible = FinancialReportDefaultsEnabled;
#endif
                    }
                    field("Fin. Rep. Company Logo Pos."; Rec."Fin. Rep. Company Logo Pos.")
                    {
                        Caption = 'Default Company Logo Position';
                    }
                }
            }
            group(Application)
            {
                Caption = 'Application';
                field("Appln. Rounding Precision"; Rec."Appln. Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rounding difference that will be allowed when you apply entries in LCY to entries in a different currency.';
                }
                field("Pmt. Disc. Tolerance Warning"; Rec."Pmt. Disc. Tolerance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning will appear every time an application occurs between the dates specified in the Payment Discount Date field and the Pmt. Disc. Tolerance Date field in the General Ledger Setup window.';
                }
                field("Pmt. Disc. Tolerance Posting"; Rec."Pmt. Disc. Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: The payment discount tolerance is posted to a special general ledger account set up for payment tolerance. Payment Discount Amount: The payment discount tolerance is posted as a payment discount.';
                }
                field("Payment Discount Grace Period"; Rec."Payment Discount Grace Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days that a payment or refund can pass the payment discount due date and still receive payment discount.';

                    trigger OnValidate()
                    var
                        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            PaymentToleranceMgt.CalcGracePeriodCVLedgEntry(Rec."Payment Discount Grace Period");
                    end;
                }
                field("Payment Tolerance Warning"; Rec."Payment Tolerance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to display a message when a payment differs from the invoice amount within the specified tolerance, so you can choose how to process it. If you do not enable the message, and a tolerance level is specified, invoices with amounts that are within tolerance will be automatically closed and you cannot choose to leave the remaining amount. Default tolerance levels are specified in the Payment Tolerance % and Max. Payment Tolerance fields, but can also be specified for each customer ledger entry.';
                }
                field("Payment Tolerance Posting"; Rec."Payment Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: Posts the payment tolerance to a special general ledger account set up for payment tolerance. Payment Discount Amount: Posts the payment tolerance as a payment discount.';
                }
                field("Payment Tolerance %"; Rec."Payment Tolerance %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage that a payment or refund is allowed to be less than the amount on the related invoice or credit memo.';
                }
                field("Max. Payment Tolerance Amount"; Rec."Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum allowed amount that a payment or refund can differ from the amount on the related invoice or credit memo.';
                }
                field("App. Dimension Posting"; Rec."App. Dimension Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies dimension source for Realized Gain/Loss application entries.';
                }
            }
            group("Gen. Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = IsJournalTemplatesVisible;

                field("Adjust ARC Jnl. Template Name"; Rec."Adjust ARC Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you want to use for posting adjustment of additional reporting currency.';
                }
                field("Adjust ARC Jnl. Batch Name"; Rec."Adjust ARC Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you want to use for posting adjustment of additional reporting currency.';
                }
                field("Apply Jnl. Template Name"; Rec."Apply Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you want to use for applying customer or vendor ledger entries.';
                }
                field("Apply Jnl. Batch Name"; Rec."Apply Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you want to use for applying customer or vendor ledger entries.';
                }
                field("Job WIP Jnl. Template Name"; Rec."Job WIP Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you want to use for posting project WIP to G/L.';
                }
                field("Job WIP Jnl. Batch Name"; Rec."Job WIP Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you want to use for posting project WIP to G/L.';
                }
                field("Bank Acc. Recon. Template Name"; Rec."Bank Acc. Recon. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you want to use for posting bank account reconciliation.';
                }
                field("Bank Acc. Recon. Batch Name"; Rec."Bank Acc. Recon. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you want to use for posting bank account reconciliation.';
                }
            }
            group("Payroll Transaction Import")
            {
                Caption = 'Payroll Transaction Import';
                Visible = false;
                field("Payroll Trans. Import Format"; Rec."Payroll Trans. Import Format")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the format of the payroll transaction file that can be imported into the General Journal window.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ChangeGlobalDimensions)
                {
                    AccessByPermission = TableData Dimension = M;
                    ApplicationArea = Dimensions;
                    Caption = 'Change Global Dimensions';
                    Ellipsis = true;
                    Image = ChangeDimensions;
                    RunObject = Page "Change Global Dimensions";
                    ToolTip = 'Change one or both of the global dimensions.';
                }
                action("Change Payment &Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Payment &Tolerance';
                    Image = ChangePaymentTolerance;
                    ToolTip = 'Change the maximum payment tolerance and/or the payment tolerance percentage.';

                    trigger OnAction()
                    var
                        Currency: Record Currency;
                        ChangePmtTol: Report "Change Payment Tolerance";
                    begin
                        Currency.Init();
                        ChangePmtTol.SetCurrency(Currency);
                        ChangePmtTol.RunModal();
                    end;
                }
            }
        }
        area(navigation)
        {
            action("Accounting Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Accounting Periods';
                Image = AccountingPeriods;
                RunObject = Page "Accounting Periods";
                ToolTip = 'Set up the number of accounting periods, such as 12 monthly periods, within the fiscal year and specify which period is the start of the new fiscal year.';
            }
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                RunObject = Page Dimensions;
                ToolTip = 'Set up dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action("User Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Setup';
                Image = UserSetup;
                RunObject = Page "User Setup";
                ToolTip = 'Set up users to restrict access to post to the general ledger.';
            }
            action("Cash Flow Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Cash Flow Setup';
                Image = CashFlowSetup;
                RunObject = Page "Cash Flow Setup";
                ToolTip = 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
            }
            action("Bank Export/Import Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Export/Import Setup';
                Image = ImportExport;
                RunObject = Page "Bank Export/Import Setup";
                ToolTip = 'Set up the formats for exporting vendor payments and for importing bank statements.';
            }
            group("General Ledger Posting")
            {
                Caption = 'General Ledger Posting';
                action("General Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    Image = GeneralPostingSetup;
                    RunObject = Page "General Posting Setup";
                    ToolTip = 'Set up combinations of general business and general product posting groups by specifying account numbers for posting of sales and purchase transactions.';
                }
                action("Gen. Business Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Business Posting Groups';
                    Image = GeneralPostingSetup;
                    RunObject = Page "Gen. Business Posting Groups";
                    ToolTip = 'Set up the trade-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
                }
                action("Gen. Product Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Product Posting Groups';
                    Image = GeneralPostingSetup;
                    RunObject = Page "Gen. Product Posting Groups";
                    ToolTip = 'Set up the item-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
                }
            }
            group("VAT Posting")
            {
                Caption = 'VAT Posting';
                action("VAT Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Posting Setup';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Posting Setup";
                    ToolTip = 'Set up how tax must be posted to the general ledger.';
                }
                action("VAT Business Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Business Posting Groups';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Business Posting Groups";
                    ToolTip = 'Set up the trade-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action("VAT Product Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Product Posting Groups';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Product Posting Groups";
                    ToolTip = 'Set up the item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action("VAT Report Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Report Setup';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Report Setup";
                    ToolTip = 'Set up number series and options for the report that you periodically send to the authorities to declare your VAT.';
                }
            }
            group("Bank Posting")
            {
                Caption = 'Bank Posting';
                action("Bank Account Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Posting Groups';
                    Image = BankAccount;
                    RunObject = Page "Bank Account Posting Groups";
                    ToolTip = 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                action("General Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Templates';
                    Image = JournalSetup;
                    RunObject = Page "General Journal Templates";
                    ToolTip = 'Set up templates for the journals that you use for bookkeeping tasks. Templates allow you to work in a journal window that is designed for a specific purpose.';
                }
                action("VAT Statement Templates")
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Statement Templates';
                    Image = VATStatement;
                    RunObject = Page "VAT Statement Templates";
                    ToolTip = 'Set up the reports that you use to settle VAT and report to the customs and tax authorities.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Change Payment &Tolerance_Promoted"; "Change Payment &Tolerance")
                {
                }
                actionref(ChangeGlobalDimensions_Promoted; ChangeGlobalDimensions)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("General Posting Setup_Promoted"; "General Posting Setup")
                {
                }
                actionref("Gen. Business Posting Groups_Promoted"; "Gen. Business Posting Groups")
                {
                }
                actionref("Gen. Product Posting Groups_Promoted"; "Gen. Product Posting Groups")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'General', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Accounting Periods_Promoted"; "Accounting Periods")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("User Setup_Promoted"; "User Setup")
                {
                }
                actionref("Cash Flow Setup_Promoted"; "Cash Flow Setup")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'VAT', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("VAT Statement Templates_Promoted"; "VAT Statement Templates")
                {
                }
                actionref("VAT Posting Setup_Promoted"; "VAT Posting Setup")
                {
                }
                actionref("VAT Business Posting Groups_Promoted"; "VAT Business Posting Groups")
                {
                }
                actionref("VAT Product Posting Groups_Promoted"; "VAT Product Posting Groups")
                {
                }
                actionref("VAT Report Setup_Promoted"; "VAT Report Setup")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("Bank Export/Import Setup_Promoted"; "Bank Export/Import Setup")
                {
                }
                actionref("Bank Account Posting Groups_Promoted"; "Bank Account Posting Groups")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Journal Templates', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref("General Journal Templates_Promoted"; "General Journal Templates")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnClosePage()
    var
        SessionSettings: SessionSettings;
    begin
        if IsShortcutDimensionModified() then
            SessionSettings.RequestSessionUpdate(false);
    end;

    trigger OnInit()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
    end;

    trigger OnOpenPage()
    var
#if not CLEAN27
#pragma warning disable AL0432
        FeatureFinancialReportDef: Codeunit "Feature - Fin. Report Default";
#pragma warning restore AL0432
#endif
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        xGeneralLedgerSetup := Rec;

        IsJournalTemplatesVisible := Rec."Journal Templ. Name Mandatory";

#if not CLEAN27
        FinancialReportDefaultsEnabled := FeatureFinancialReportDef.IsDefaultsFeatureEnabled();
#endif
    end;

    var
        xGeneralLedgerSetup: Record "General Ledger Setup";
        IsJournalTemplatesVisible: Boolean;
#if not CLEAN27
        FinancialReportDefaultsEnabled: Boolean;
#endif

#pragma warning disable AA0074
        Text001: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';
        Text002: Label 'If you delete the additional reporting currency, future general ledger entries are posted in LCY only. Deleting the additional reporting currency does not affect already posted general ledger entries.\\Are you sure that you want to delete the additional reporting currency?';
        Text003: Label 'If you change the additional reporting currency, future general ledger entries are posted in the new reporting currency and in LCY. To enable the additional reporting currency, a batch job opens, and running the batch job recalculates already posted general ledger entries in the new additional reporting currency.\Entries will be deleted in the Analysis View if it is unblocked, and an update will be necessary.\\Are you sure that you want to change the additional reporting currency?';
#pragma warning restore AA0074

    local procedure IsShortcutDimensionModified(): Boolean
    begin
        exit(
          (Rec."Shortcut Dimension 1 Code" <> xGeneralLedgerSetup."Shortcut Dimension 1 Code") or
          (Rec."Shortcut Dimension 2 Code" <> xGeneralLedgerSetup."Shortcut Dimension 2 Code") or
          (Rec."Shortcut Dimension 3 Code" <> xGeneralLedgerSetup."Shortcut Dimension 3 Code") or
          (Rec."Shortcut Dimension 4 Code" <> xGeneralLedgerSetup."Shortcut Dimension 4 Code") or
          (Rec."Shortcut Dimension 5 Code" <> xGeneralLedgerSetup."Shortcut Dimension 5 Code") or
          (Rec."Shortcut Dimension 6 Code" <> xGeneralLedgerSetup."Shortcut Dimension 6 Code") or
          (Rec."Shortcut Dimension 7 Code" <> xGeneralLedgerSetup."Shortcut Dimension 7 Code") or
          (Rec."Shortcut Dimension 8 Code" <> xGeneralLedgerSetup."Shortcut Dimension 8 Code"));
    end;
}
