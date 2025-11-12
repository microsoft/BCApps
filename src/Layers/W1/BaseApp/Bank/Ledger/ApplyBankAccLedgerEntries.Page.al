// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// List part page for selecting and applying bank account ledger entries during bank reconciliation.
/// Provides filtering, selection, and balance calculation functionality for matching bank statement lines
/// with posted bank account transactions during the reconciliation process.
/// </summary>
page 381 "Apply Bank Acc. Ledger Entries"
{
    Caption = 'Apply Bank Acc. Ledger Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Account Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(LineApplied; StatementNoLineApplied <> '')
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied';
                    Editable = false;
                    ToolTip = 'Specifies if the bank account ledger entry has been applied to its related bank transaction.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the document type on the bank account entry. The document type will be Payment, Refund, or the field will be blank.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the document number on the bank account entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the description of the bank account entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the amount of the entry denominated in the applicable foreign currency.';
                    Visible = AmountVisible;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the amount that remains to be applied to. The amount is denominated in the applicable foreign currency.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the amount on the bank account entry has been fully applied to, or if there is a remaining amount that must be applied to.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the bank ledger entry is positive.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Statement Status"; Rec."Statement Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the statement status of the bank account ledger entry.';
                    Visible = false;
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account statement that the ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied.';
                    Visible = false;
                }
                field("Statement Line No."; Rec."Statement Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement line that has been applied to by this ledger entry line.';
                    Visible = false;
                }
                field("Check Ledger Entries"; Rec."Check Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check ledger entries that are associated with the bank account ledger entry.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
            }
            group(Control7)
            {
                ShowCaption = false;
                label(Control15)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Caption = ' ';
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the balance of the bank account since the last posting, including any amount in the Total on Outstanding Checks field.';
                }
                field(CheckBalance; CheckBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total on Outstanding Checks';
                    Editable = false;
                    ToolTip = 'Specifies the part of the bank account balance that consists of posted check ledger entries. The amount in this field is a subset of the amount in the Balance field under the right pane in the Bank Acc. Reconciliation window.';

                    trigger OnDrillDown()
                    var
                        CheckLedgerEntry: Record "Check Ledger Entry";
                    begin
                        if BankAccount."No." = '' then
                            exit;

                        CheckLedgerEntry.FilterGroup(2);
                        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
                        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
                        CheckLedgerEntry.SetFilter("Statement Status", '<>%1', CheckLedgerEntry."Statement Status"::Closed);
                        CheckLedgerEntry.SetFilter("Posting Date", '<=%1', BankAccReconciliation."Statement Date");
                        CheckLedgerEntry.FilterGroup(0);
                        if not CheckLedgerEntry.IsEmpty() then
                            Page.Run(Page::"Check Ledger Entries", CheckLedgerEntry);
                    end;
                }
                field(BalanceToReconcile; BalanceToReconcile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance To Reconcile';
                    Editable = false;
                    ToolTip = 'Specifies the balance of the bank account since the last posting, excluding any amount in the Total on Outstanding Checks field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetUserInteractions();
        CalcBalance();
        ApplyControledFilters();
    end;

    trigger OnAfterGetRecord()
    begin
        StatementNoLineApplied := Rec.GetAppliedStatementNo();
        SetUserInteractions();
    end;

    trigger OnInit()
    begin
        AmountVisible := true;
        SetUserInteractions();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SetUserInteractions();
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility();
    end;

    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        StyleTxt: Text;
        StatementNoLineApplied: Code[20];
        Balance: Decimal;
        CheckBalance: Decimal;
        BalanceToReconcile: Decimal;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
        ShowingReversed: Boolean;
        ShowingNonMatched: Boolean;

    /// <summary>
    /// Retrieves bank account ledger entries selected by the user for application.
    /// Copies selected entries to a temporary table for further processing during reconciliation.
    /// </summary>
    /// <param name="TempBankAccountLedgerEntry">Temporary table to receive the selected entries.</param>
    procedure GetSelectedRecords(var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSelectedRecords(Rec, TempBankAccountLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        CurrPage.SetSelectionFilter(BankAccountLedgerEntry);
        if BankAccountLedgerEntry.FindSet() then
            repeat
                TempBankAccountLedgerEntry := BankAccountLedgerEntry;
                TempBankAccountLedgerEntry.Insert();
            until BankAccountLedgerEntry.Next() = 0;
    end;

    /// <summary>
    /// Sets user interaction styling based on the application status of entries.
    /// Updates visual styling to indicate applied, mismatched, or unmatched entries.
    /// </summary>
    procedure SetUserInteractions()
    begin
        StyleTxt := '';
        if StatementNoLineApplied = '' then
            exit;
        if StatementNoLineApplied = BankAccReconciliation."Statement No." then
            StyleTxt := 'Favorable'
        else
            StyleTxt := 'AttentionAccent';
    end;

    /// <summary>
    /// Shows all available bank account ledger entries for reconciliation without filtering.
    /// Resets filters and displays the complete set of entries for the bank account.
    /// </summary>
    procedure ShowAll()
    begin
        Rec.Reset();
        ShowingNonMatched := false;
        if BankAccReconciliation.Get(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.") then;
        ApplyDateFilter(BankAccReconciliation.MatchCandidateFilterDate());
        ApplyControledFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Filters the list to show only bank account ledger entries that have not been matched to statement lines.
    /// Useful for identifying outstanding transactions during reconciliation.
    /// </summary>
    procedure ShowNonMatched()
    begin
        ShowingNonMatched := true;
        ApplyControledFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Shows reversed bank account ledger entries in the reconciliation list.
    /// Includes previously hidden reversed entries for complete transaction visibility.
    /// </summary>
    procedure ShowReversed()
    begin
        ShowingReversed := true;
        ApplyControledFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Hides reversed bank account ledger entries from the reconciliation list.
    /// Excludes reversed entries to focus on active transactions for reconciliation.
    /// </summary>
    procedure HideReversed()
    begin
        ShowingReversed := false;
        ApplyControledFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Applies date-based filtering to show entries within the bank reconciliation date range.
    /// Filters entries to optimize reconciliation matching by focusing on relevant date periods.
    /// </summary>
    /// <param name="StatementDate">Statement date to use for filtering criteria.</param>
    procedure SetBankRecDateFilter(StatementDate: Date)
    begin
        ApplyDateFilter(StatementDate);
        CurrPage.Update(false);
    end;

    local procedure ApplyDateFilter(StatementDate: Date)
    begin
        if StatementDate = 0D then
            Rec.SetRange("Posting Date")
        else
            Rec.SetRange("Posting Date", 0D, StatementDate);
    end;

    local procedure ApplyControledFilters()
    begin
        ApplyPartFilters();
        if ShowingNonMatched then begin
            Rec.SetRange("Statement Status", Rec."Statement Status"::Open);
            Rec.SetRange("Statement No.", '');
            Rec.SetRange("Statement Line No.", 0);
        end
        else begin
            Rec.SetRange("Statement No.");
            Rec.SetRange("Statement Line No.");
        end;

        if not ShowingReversed then
            Rec.SetRange(Reversed, false)
        else
            Rec.SetRange(Reversed);
        OnAfterApplyControledFilters(Rec);
    end;

    local procedure ApplyPartFilters()
    begin
        Rec.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        Rec.SetRange(Open, true);
        Rec.SetFilter("Statement Status", '%1|%2|%3', Rec."Statement Status"::Open, Rec."Statement Status"::"Bank Acc. Entry Applied", Rec."Statement Status"::"Check Entry Applied");
    end;

    local procedure CalcBalance()
    begin
        if BankAccount.Get(Rec."Bank Account No.") then begin
            BankAccount.CalcFields(Balance, "Total on Checks");
            Balance := BankAccount.Balance;
            CheckBalance := CalcOutstandingChecks(BankAccReconciliation."Statement Date");
            BalanceToReconcile := CalcBalanceToReconcile();
        end;
    end;

    local procedure CalcOutstandingChecks(StatementEndingDate: Date): Decimal
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        TotalOutstanding: Decimal;
    begin
        if BankAccount."No." = '' then
            exit(0);

        CheckLedgerEntry.SetLoadFields("Bank Account No.", "Entry Status", "Statement Status", "Posting Date");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
        CheckLedgerEntry.SetFilter("Statement Status", '<>%1', CheckLedgerEntry."Statement Status"::Closed);
        CheckLedgerEntry.SetFilter("Posting Date", '<=%1', StatementEndingDate);
        CheckLedgerEntry.CalcSums(Amount);
        TotalOutstanding := CheckLedgerEntry.Amount;

        exit(TotalOutstanding);
    end;

    local procedure CalcBalanceToReconcile(): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.CopyFilters(Rec);
        BankAccountLedgerEntry.CalcSums(Amount);
        exit(BankAccountLedgerEntry.Amount);
    end;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;

    /// <summary>
    /// Associates the page with a specific bank account reconciliation record.
    /// Sets up filtering and context for the reconciliation process.
    /// </summary>
    /// <param name="NewBankAccReconciliation">Bank account reconciliation record to associate with the page.</param>
    procedure AssignBankAccReconciliation(var NewBankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        BankAccReconciliation := NewBankAccReconciliation;
        ApplyControledFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Integration event raised after applying controlled filters to the bank account ledger entries.
    /// Allows subscribers to modify or extend the filtering logic for reconciliation scenarios.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyControledFilters(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before collecting selected records for reconciliation processing.
    /// Allows subscribers to customize selection logic or handle records differently.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Source bank account ledger entry being processed.</param>
    /// <param name="TempBankAccountLedgerEntry">Temporary table receiving selected entries.</param>
    /// <param name="IsHandled">Set to true to skip standard selection processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSelectedRecords(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

