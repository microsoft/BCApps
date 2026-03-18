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

/// <summary>
/// Setup page for configuring core General Ledger parameters including posting permissions, currency settings, VAT handling, and dimension management.
/// Provides access to critical financial system configuration affecting all accounting transactions and reporting.
/// </summary>
/// <remarks>
/// Key configuration areas: posting date controls, VAT settings, currency precision, dimension setup, job queue integration.
/// Critical system setup affecting all financial transactions, reporting, and compliance requirements.
/// Includes advanced features for additional reporting currency, unrealized VAT, and automated posting processes.
/// </remarks>
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
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Posting From DateFormula"; Rec."Allow Posting From DateFormula")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a date formula to calculate the earliest date, relative to the workdate, on which posting to the company books is allowed.';
                }
                field("Allow Posting To DateFormula"; Rec."Allow Posting To DateFormula")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a date formula to calculate the latest date on which posting to the company books is allowed.';
                }
                field("Allow Deferral Posting From"; Rec."Allow Deferral Posting From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Deferral Posting To"; Rec."Allow Deferral Posting To")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Reporting Date Usage"; Rec."VAT Reporting Date Usage")
                {
                    ApplicationArea = VAT;

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
                    }
                }
                field("Register Time"; Rec."Register Time")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("Local Address Format"; Rec."Local Address Format")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Local Cont. Addr. Format"; Rec."Local Cont. Addr. Format")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Req.Country/Reg. Code in Addr."; Rec."Req.Country/Reg. Code in Addr.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                }
                field(AmountDecimalPlaces; Rec."Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Decimal Places (LCY)';
                }
                field(UnitAmountRoundingPrecision; Rec."Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Rounding Precision (LCY)';
                }
                field(UnitAmountDecimalPlaces; Rec."Unit-Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Decimal Places (LCY)';
                }
                field("Allow G/L Acc. Deletion Before"; Rec."Allow G/L Acc. Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Block Deletion of G/L Accounts"; Rec."Block Deletion of G/L Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Check G/L Account Usage"; Rec."Check G/L Account Usage")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Mark Cr. Memos as Corrections"; Rec."Mark Cr. Memos as Corrections")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pmt. Disc. Excl. VAT"; Rec."Pmt. Disc. Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Adjust for Payment Disc."; Rec."Adjust for Payment Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Unrealized VAT"; Rec."Unrealized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Prepayment Unrealized VAT"; Rec."Prepayment Unrealized VAT")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Max. VAT Difference Allowed"; Rec."Max. VAT Difference Allowed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Tax Invoice Renaming Threshold"; Rec."Tax Invoice Renaming Threshold")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Rounding Type"; Rec."VAT Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Control VAT Period"; Rec."Control VAT Period")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a way of using VAT Date against VAT Return Periods. If you choose ‘Block posting within closed and warn for released period’, system will not allow postings in closed VAT Return Period, but if the period is not closed, but VAT returns are released or submitted, user will be warned what try to post an entry with VAT Date in this period. If you choose ‘Block posting within closed period’, system will still not allow postings in closed VAT Return Period, but there will be no warnings for release or submitted VAT returns. If you choose ‘Warn when posting in closed period’, system will not block posting entry with VAT Date in the closed VAT return period, but it will show warning message before posting. And if you choose ‘Disabled’ options, system will allow you to post without any control regardless of VAT return or period status.';
                }
                field("Bank Account Nos."; Rec."Bank Account Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bill-to/Sell-to VAT Calc."; Rec."Bill-to/Sell-to VAT Calc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Print VAT specification in LCY"; Rec."Print VAT specification in LCY")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                }
                field("Hide Company Bank Account"; Rec."Hide Company Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(PostingPreviewType; Rec."Posting Preview Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(SEPANonEuroExport; Rec."SEPA Non-Euro Export")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(SEPAExportWoBankAccData; Rec."SEPA Export w/o Bank Acc. Data")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Journal Templ. Name Mandatory"; Rec."Journal Templ. Name Mandatory")
                {
                    ApplicationArea = BasicBE;
                    Importance = Additional;
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
                }
                field(CheckSourceCurrencyConsistency; Rec."Check Source Curr. Consistency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
            }
            group(Control1900309501)
            {
                Caption = 'Dimensions';
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
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
                }
                field("Local Currency Description"; Rec."Local Currency Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EMU Currency"; Rec."EMU Currency")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; Rec."Post with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Additional Reporting Currency"; Rec."Additional Reporting Currency")
                {
                    ApplicationArea = Suite;

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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default View by';
#if not CLEAN27
                        Visible = FinancialReportDefaultsEnabled;
#endif
                    }
                    field("Fin. Rep. Neg. Amount Format"; Rec."Fin. Rep. Neg. Amount Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default Negative Amount Format';
#if not CLEAN27
                        Visible = FinancialReportDefaultsEnabled;
#endif
                    }
                    field("Fin. Rep. Company Logo Pos."; Rec."Fin. Rep. Company Logo Pos.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default Company Logo Position';
                    }
                    field(DefaultFinancialReportStatus; Rec.DefaultFinancialReportStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default Status';
                    }
                }
            }
            group(Application)
            {
                Caption = 'Application';
                field("Appln. Rounding Precision"; Rec."Appln. Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pmt. Disc. Tolerance Warning"; Rec."Pmt. Disc. Tolerance Warning")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pmt. Disc. Tolerance Posting"; Rec."Pmt. Disc. Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Discount Grace Period"; Rec."Payment Discount Grace Period")
                {
                    ApplicationArea = Basic, Suite;

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
                }
                field("Payment Tolerance Posting"; Rec."Payment Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Tolerance %"; Rec."Payment Tolerance %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Max. Payment Tolerance Amount"; Rec."Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("App. Dimension Posting"; Rec."App. Dimension Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Gen. Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = IsJournalTemplatesVisible;

                field("Adjust ARC Jnl. Template Name"; Rec."Adjust ARC Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Adjust ARC Jnl. Batch Name"; Rec."Adjust ARC Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Apply Jnl. Template Name"; Rec."Apply Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Apply Jnl. Batch Name"; Rec."Apply Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job WIP Jnl. Template Name"; Rec."Job WIP Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job WIP Jnl. Batch Name"; Rec."Job WIP Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Acc. Recon. Template Name"; Rec."Bank Acc. Recon. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Acc. Recon. Batch Name"; Rec."Bank Acc. Recon. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Payroll Transaction Import")
            {
                Caption = 'Payroll Transaction Import';
                Visible = false;
                field("Payroll Trans. Import Format"; Rec."Payroll Trans. Import Format")
                {
                    ApplicationArea = Suite;
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
