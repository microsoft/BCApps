// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Foundation.Reporting;
using System.Telemetry;

page 379 "Bank Acc. Reconciliation"
{
    Caption = 'Bank Acc. Reconciliation';
    PageType = ListPlus;
    SaveValues = false;
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableView = where("Statement Type" = const("Bank Reconciliation"));
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BankAccountNo; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                    Editable = BankAccountNoIsEditable;

                    trigger OnValidate()
                    var
                        BankAccReconciliationLine: record "Bank Acc. Reconciliation Line";
                    begin
                        if BankAccReconciliationLine.BankStatementLinesListIsEmpty(Rec."Statement No.", Rec."Statement Type".AsInteger(), Rec."Bank Account No.") then
                            CreateEmptyListNotification();

                        if not WarnIfOngoingBankReconciliations(Rec."Bank Account No.") then
                            Error('');
                        CurrPage.ApplyBankLedgerEntries.Page.AssignBankAccReconciliation(Rec);
                        BankAccountNoIsEditable := false;
                        CheckBankAccLedgerEntriesAlreadyMatched();
                        CurrPage.Update(false);
                    end;
                }
                field(StatementNo; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement No.';
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field(StatementDate; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Date';
                    ToolTip = 'Specifies the date on the bank account statement.';
                    trigger OnValidate()
                    begin
                        CurrPage.ApplyBankLedgerEntries.Page.SetBankRecDateFilter(Rec.MatchCandidateFilterDate());
                    end;
                }
                field(BalanceLastStatement; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance Last Statement';
                    ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                }
                field(StatementEndingBalance; Rec."Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Ending Balance';
                    ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                part(StmtLine; "Bank Acc. Reconciliation Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Statement Lines';
                    SubPageLink = "Bank Account No." = field("Bank Account No."),
                                  "Statement No." = field("Statement No.");
                }
                part(ApplyBankLedgerEntries; "Apply Bank Acc. Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Ledger Entries';
                    SubPageLink = "Bank Account No." = field("Bank Account No."),
                                  Open = const(true),
                                  "Statement Status" = filter(Open | "Bank Acc. Entry Applied" | "Check Entry Applied");
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
        area(navigation)
        {
            group("&Recon.")
            {
                Caption = '&Recon.';
                Image = BankAccountRec;
                action("&Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Bank Account Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record that is being processed on the journal line.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    ToolTip = 'Create bank account ledger entries suggestions and enter them automatically.';

                    trigger OnAction()
                    var
                        IsHandled: Boolean;
                    begin
                        RecallEmptyListNotification();
                        IsHandled := false;
                        OnActionSuggestLinesOnBeforeSuggestBankAccReconLines(Rec, IsHandled);
                        if IsHandled then
                            exit;
                        SuggestBankAccReconLines.SetStmt(Rec);
                        SuggestBankAccReconLines.RunModal();
                        Clear(SuggestBankAccReconLines);
                    end;
                }
                action(ShowReversedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Reversed Entries';
                    Ellipsis = true;
                    Image = ReverseLines;
                    ToolTip = 'Include reversed bank account ledger entries in the list of suggestions.';

                    trigger OnAction()
                    begin
                        RecallEmptyListNotification();
                        CurrPage.ApplyBankLedgerEntries.Page.ShowReversed();
                    end;
                }
                action(HideReversedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hide Reversed Entries';
                    Ellipsis = true;
                    Image = FilterLines;
                    ToolTip = 'Hide unmatched reversed bank account ledger entries up to the statement date.';

                    trigger OnAction()
                    begin
                        RecallEmptyListNotification();
                        CurrPage.ApplyBankLedgerEntries.Page.HideReversed();
                    end;
                }
                action("Transfer to General Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer to General Journal';
                    Ellipsis = true;
                    Image = TransferToGeneralJournal;
                    ToolTip = 'Transfer the lines from the current window to the general journal.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        TempBankAccReconciliationLine.Setrange(Difference, 0);
                        TempBankAccReconciliationLine.DeleteAll();
                        TempBankAccReconciliationLine.Setrange(Difference);
                        if TempBankAccReconciliationLine.IsEmpty() then
                            error(NoBankAccReconcilliationLineWithDiffSellectedErr);
                        TransBankRecToGenJnl.SetBankAccReconLine(TempBankAccReconciliationLine);
                        TransBankRecToGenJnl.SetBankAccRecon(Rec);
                        TransBankRecToGenJnl.Run();
                    end;
                }
                action(ChangeStatementNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Statement No.';
                    Ellipsis = true;
                    Image = ChangeTo;
                    ToolTip = 'Change the statement number of the bank account reconciliation. Typically, this is used when you have created a new reconciliation to correct a mistake, and you want to use the same statement number.';

                    trigger OnAction()
                    var
                        BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        BankAccReconciliationCard: Page "Bank Acc. Reconciliation";
                    begin
                        BankAccReconciliation := Rec;
                        Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
                        if Rec."Statement No." <> BankAccReconciliation."Statement No." then begin
                            BankAccReconciliationCard.SetRecord(BankAccReconciliation);
                            BankAccReconciliationCard.Run();
                            CurrPage.Close();
                        end;
                    end;
                }
            }
            group("Ba&nk")
            {
                Caption = 'Ba&nk';
                action(ImportBankStatement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Bank Statement';
                    Image = Import;
                    ToolTip = 'Import electronic bank statements from your bank to populate with data about actual bank transactions.';

                    trigger OnAction()
                    begin
                        CurrPage.Update();
                        Rec.ImportBankStatement();
                        CheckStatementDate();
                        RecallEmptyListNotification();
                    end;
                }
            }
            group("M&atching")
            {
                Caption = 'M&atching';
                action(MatchAutomatically)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Automatically';
                    Image = MapAccounts;
                    ToolTip = 'Automatically search for and match bank statement lines.';

                    trigger OnAction()
                    begin
                        Rec.SetRange("Statement Type", Rec."Statement Type");
                        Rec.SetRange("Bank Account No.", Rec."Bank Account No.");
                        Rec.SetRange("Statement No.", Rec."Statement No.");
                        REPORT.Run(REPORT::"Match Bank Entries", true, true, Rec);
                    end;
                }
                action(MatchManually)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Manually';
                    Image = CheckRulesSyntax;
                    ToolTip = 'Manually match selected lines in both panes to link each bank statement line to one or more related bank account ledger entries.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
                        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        CurrPage.ApplyBankLedgerEntries.PAGE.GetSelectedRecords(TempBankAccountLedgerEntry);
                        if ConfirmSelectedEntriesWithExternalMatchForModification(TempBankAccountLedgerEntry) then
                            MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
                    end;
                }
                action(RemoveMatch)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Match';
                    Image = RemoveContacts;
                    ToolTip = 'Remove selection of matched bank statement lines.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
                        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        CurrPage.ApplyBankLedgerEntries.PAGE.GetSelectedRecords(TempBankAccountLedgerEntry);
                        if ConfirmSelectedEntriesWithExternalMatchForModification(TempBankAccountLedgerEntry) then
                            MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
                    end;
                }
                action(MatchDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Details';
                    Image = ViewDetails;
                    ToolTip = 'Show matching details about the selected bank statement line.';

                    trigger OnAction()
                    var
                        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
                    begin
                        CurrPage.StmtLine.PAGE.GetSelectedRecords(TempBankAccReconciliationLine);
                        if TempBankAccReconciliationLine."Applied Entries" > 0 then
                            Page.Run(Page::"Bank Rec. Line Match Details", TempBankAccReconciliationLine);
                    end;
                }
                action(All)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All';
                    Image = AddWatch;
                    ToolTip = 'Show all bank statement lines.';

                    trigger OnAction()
                    begin
                        CurrPage.StmtLine.PAGE.ToggleMatchedFilter(false);
                        CurrPage.ApplyBankLedgerEntries.Page.ShowAll();
                    end;
                }
                action(NotMatched)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Nonmatched';
                    Image = AddWatch;
                    ToolTip = 'Show all bank statement lines that have not yet been matched.';

                    trigger OnAction()
                    begin
                        CurrPage.StmtLine.PAGE.ToggleMatchedFilter(true);
                        CurrPage.ApplyBankLedgerEntries.Page.ShowNonMatched();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("&Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the resulting bank account reconciliations to see the consequences before you perform the actual posting.';

                    trigger OnAction()
                    var
                        BankAccRecTestRepVisible: Codeunit "Bank Acc.Rec.Test Rep. Visible";
                    begin
                        // To configure the report and log troubleshooting telemetry we bind subscribers.
                        // the report is not directly configurable since it uses ReportSelections
                        BindSubscription(BankAccRecTestRepVisible);
                        TestReportPrint.PrintBankAccRecon(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    RunObject = Codeunit "Bank Acc. Recon. Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        BankAccRecTestRepVisible: Codeunit "Bank Acc.Rec.Test Rep. Visible";
                        BankAccReconPostPrint: Codeunit "Bank Acc. Recon. Post+Print";
                    begin
                        BindSubscription(BankAccRecTestRepVisible);
                        BankAccReconPostPrint.Run(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Transfer to General Journal_Promoted"; "Transfer to General Journal")
                {
                }
                actionref(SuggestLines_Promoted; SuggestLines)
                {
                }
                group(Category_Category6)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PostAndPrint_Promoted; PostAndPrint)
                    {
                    }
                    actionref("&Test Report_Promoted"; "&Test Report")
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ImportBankStatement_Promoted; ImportBankStatement)
                {
                }
                actionref("&Card_Promoted"; "&Card")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Matching', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(MatchManually_Promoted; MatchManually)
                {
                }
                actionref(MatchAutomatically_Promoted; MatchAutomatically)
                {
                }
                actionref(RemoveMatch_Promoted; RemoveMatch)
                {
                }
                actionref(MatchDetails_Promoted; MatchDetails)
                {
                }
            }
            group(Category_Show)
            {
                Caption = 'Show';

                actionref(All_Promoted; All)
                {
                }
                actionref(ShowReversedEntries_Promoted; ShowReversedEntries)
                {
                }
                actionref(HideReversedEntries_Promoted; HideReversedEntries)
                {
                }
                actionref(NotMatched_Promoted; NotMatched)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000JLL', Rec.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000JM9', Rec.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::"Set up");
        CreateEmptyListNotification();

        if (Rec."Bank Account No." <> '') then begin
            BankAccountNoIsEditable := false;
            CheckBankAccLedgerEntriesAlreadyMatched();
            CurrPage.ApplyBankLedgerEntries.Page.AssignBankAccReconciliation(Rec);
            CurrPage.ApplyBankLedgerEntries.Page.SetBankRecDateFilter(Rec.MatchCandidateFilterDate());
        end
        else
            BankAccountNoIsEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNumber: Code[20];
    begin
        if (Rec."Bank Account No." <> '') then
            exit;
        if BankAccount.FindSet() then begin
            BankAccountNumber := BankAccount."No.";
            if BankAccount.Next() = 0 then begin
                Rec."Statement Type" := BankAccReconciliation."Statement Type"::"Bank Reconciliation";
                Rec.Validate("Bank Account No.", BankAccountNumber);
                BankAccountNoIsEditable := false;
            end;
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        RecallEmptyListNotification();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if UpdatedBankAccountLESystemId <> Rec.SystemId then begin
            UpdatedBankAccountLESystemId := Rec.SystemId;
            CurrPage.ApplyBankLedgerEntries.Page.SetBankRecDateFilter(Rec.MatchCandidateFilterDate());
        end;

        CurrPage.ApplyBankLedgerEntries.Page.AssignBankAccReconciliation(Rec);
    end;

    local procedure GetImportBankStatementNotificatoinId(): Guid
    begin
        exit('aa54bf06-b8b9-420d-a4a8-1f55a3da3e2a');
    end;

    local procedure CreateEmptyListNotification()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ImportBankStatementNotification: Notification;
    begin
        ImportBankStatementNotification.Id := GetImportBankStatementNotificatoinId();
        if ImportBankStatementNotification.Recall() then;
        if not BankAccReconciliationLine.BankStatementLinesListIsEmpty(Rec."Statement No.", Rec."Statement Type".AsInteger(), Rec."Bank Account No.") then
            exit;

        ImportBankStatementNotification.Message := ListEmptyMsg;
        ImportBankStatementNotification.Scope := NotificationScope::LocalScope;
        ImportBankStatementNotification.Send();
    end;

    local procedure RecallEmptyListNotification()
    var
        ImportBankStatementNotification: Notification;
    begin
        ImportBankStatementNotification.Id := GetImportBankStatementNotificatoinId();
        if ImportBankStatementNotification.Recall() then;
    end;

    local procedure CheckStatementDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetFilter("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetFilter("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetCurrentKey("Transaction Date");
        BankAccReconciliationLine.Ascending := false;
        if BankAccReconciliationLine.FindFirst() then begin
            BankAccReconciliation.GetBySystemId(Rec.SystemId);
            if BankAccReconciliation."Statement Date" = 0D then begin
                if Confirm(StrSubstNo(StatementDateEmptyMsg, Format(BankAccReconciliationLine."Transaction Date"))) then begin
                    Rec."Statement Date" := BankAccReconciliationLine."Transaction Date";
                    Rec.Modify();
                end;
            end else
                if BankAccReconciliation."Statement Date" < BankAccReconciliationLine."Transaction Date" then
                    Message(ImportedLinesAfterStatementDateMsg);
            CurrPage.ApplyBankLedgerEntries.Page.SetBankRecDateFilter(BankAccReconciliation.MatchCandidateFilterDate());
        end;
    end;

    local procedure WarnIfOngoingBankReconciliations(BankAccountNoCode: Code[20]): Boolean
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNoCode);
        BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        if not BankAccReconciliation.FindSet() then
            exit(true);
        repeat
            if BankAccReconciliation."Statement No." <> Rec."Statement No." then
                exit(Dialog.Confirm(StrSubstNo(IgnoreExistingBankAccReconciliationAndContinueQst)));
        until BankAccReconciliation.Next() = 0;
        exit(true);
    end;

    local procedure ConfirmSelectedEntriesWithExternalMatchForModification(var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary): Boolean
    var
        ReturnValue: Boolean;
    begin
        TempBankAccountLedgerEntry.SetFilter("Statement No.", '<> %1 & <> ''''', Rec."Statement No.");
        if TempBankAccountLedgerEntry.IsEmpty() then
            ReturnValue := true
        else begin
            ReturnValue := Confirm(ModifyBankAccLedgerEntriesForModificationQst, false);
            if ReturnValue then
                Session.LogMessage('0000JLM', '', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Rec.GetBankReconciliationTelemetryFeatureName());
        end;

        TempBankAccountLedgerEntry.SetRange("Statement No.");
        TempBankAccountLedgerEntry.FindSet();
        exit(ReturnValue);
    end;

    local procedure CheckBankAccLedgerEntriesAlreadyMatched()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetFilter("Statement No.", '<> %1 & <> ''''', Rec."Statement No.");
        BankAccountLedgerEntry.SetFilter("Statement Status", '<> Closed');
        if (Rec."Statement Date" <> 0D) then
            BankAccountLedgerEntry.SetFilter("Posting Date", '<= %1', Rec."Statement Date");

        if not BankAccountLedgerEntry.IsEmpty() then
            Message(ExistingBankAccReconciliationAndContinueMsg);
    end;

    var
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
        TransBankRecToGenJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
        TestReportPrint: Codeunit "Test Report-Print";
        BankAccountNoIsEditable: Boolean;
        ListEmptyMsg: Label 'No bank statement lines exist. Choose the Import Bank Statement action to fill in the lines from a file, or enter lines manually.';
        ImportedLinesAfterStatementDateMsg: Label 'There are lines on the imported bank statement with dates that are after the statement date.';
        StatementDateEmptyMsg: Label 'The bank account reconciliation does not have a statement date. %1 is the latest date on a line. Do you want to use that date for the statement?', Comment = '%1 - statement date';
        NoBankAccReconcilliationLineWithDiffSellectedErr: Label 'Select the bank statement lines that have differences to transfer to the general journal.';
        UpdatedBankAccountLESystemId: Guid;
        IgnoreExistingBankAccReconciliationAndContinueQst: Label 'There are ongoing reconciliations for this bank account. \\Do you want to continue?';
        ExistingBankAccReconciliationAndContinueMsg: Label 'There are ongoing reconciliations for this bank account in which entries are matched.';
        ModifyBankAccLedgerEntriesForModificationQst: Label 'One or more of the selected entries have been matched on another bank account reconciliation.\\Do you want to continue?';

    [IntegrationEvent(false, false)]
    local procedure OnActionSuggestLinesOnBeforeSuggestBankAccReconLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var IsHandled: Boolean)
    begin
    end;
}
