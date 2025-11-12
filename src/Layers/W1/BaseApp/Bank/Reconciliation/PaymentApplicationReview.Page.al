// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

page 1287 "Payment Application Review"
{
    PageType = Card;
    SourceTable = "Bank Acc. Reconciliation Line";
    RefreshOnActivate = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(ReviewApplication)
            {
                Caption = 'Review Payment Application';

                group(TransactionDetails)
                {
                    Caption = 'Transaction Details';

                    field("Transaction Date"; Rec."Transaction Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the date when the payment represented by the journal line was recorded in the bank account.';
                    }

                    field("Transaction Text"; Rec."Transaction Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the text that the customer or vendor entered on that payment transaction that is represented by the journal line.';
                        Width = 40;
                        MultiLine = true;
                    }

                    field("Statement Amount"; Rec."Statement Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transaction Amount';
                        ToolTip = 'Specifies the amount that was paid into the bank account and then imported as a bank statement line represented by the journal line.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord();
                            CurrPage.Update(false)
                        end;
                    }

                    group(BankStatementDetails)
                    {
                        ShowCaption = false;
                        Caption = 'Show Bank Statement Details';
                        Visible = HasPaymentFile;

                        field("Bank Statement Details"; 'Show Bank Statement Details')
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Bank Statement Details';
                            ShowCaption = false;
                            ToolTip = 'View the content of the imported bank statement file, such as account number, posting date, and amounts.';

                            trigger OnDrillDown()
                            begin
                                if HasPaymentFile then
                                    Page.Run(Page::"Bank Statement Line Details", DataExchField);
                            end;
                        }
                    }
                }

                group(AppliedTo)
                {
                    Caption = 'Applied To';

                    group(ReviewRequired)
                    {
                        ShowCaption = false;
                        Caption = 'Review Required';
                        Visible = ReviewRequiredVisible;
                        Editable = false;

                        field("Review Required"; ReviewRequiredTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Caption = 'Review Required';
                            ToolTip = 'Specifies if the journal line must be reviewed, as prescribed by the payment application rule used.';
                            Style = Ambiguous;
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                Page.Run(Page::"Payment Application Rules", BankPmtApplRule);
                            end;
                        }
                    }

                    group(LineNotApplied)
                    {
                        ShowCaption = false;
                        Visible = LineNotAppliedVisible;
                        Editable = false;

                        field("Line Not Applied"; LineNotAppliedLbl)
                        {
                            Caption = 'Line Not Applied';
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Style = Ambiguous;
                            Editable = false;
                            Tooltip = 'Specifies if the line is applied.';
                        }
                    }

                    field("Account Type"; Rec."Account Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of account that the payment application will be posted to when you post the payment reconciliation journal.';
                    }

                    field("Account No."; Rec."Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the account number that the payment application will be posted to when you post the payment reconciliation journal.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update();
                            if Rec.Difference <> 0 then
                                Rec.TransferRemainingAmountToAccount();
                        end;
                    }

                    field(AccountName; Rec.GetAppliedToName())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer or vendor that the payment is applied to.';

                        trigger OnDrillDown()
                        begin
                            Rec.AppliedToDrillDown();
                        end;
                    }

                    field(GetAppliedToDocumentNo; Rec.GetAppliedToDocumentNo())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number of the open ledger entry that the payment is applied to.';

                        trigger OnDrillDown()
                        begin
                            Rec.ShowAppliedToEntries();
                        end;
                    }

                    group(RemainingAmount)
                    {
                        ShowCaption = false;
                        Editable = false;
                        field("Remaining Amount"; RemainingAmountAfterPosting)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Remaining Amount After Posting';
                            ToolTip = 'Specifies the amount that remains to be paid on the open entry that the payment is applied to.';
                        }
                    }

                    field("Difference"; StatementToRemAmtDifference)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Difference';
                        Editable = false;
                        ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the amount in the Applied Amount field.';
                    }

                    group(StatusDifference)
                    {
                        ShowCaption = false;
                        Visible = DifferenceVisible;
                        Caption = 'Status Difference';
                        field("DifferenceToReconcile"; DifferenceToReconcileLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Caption = 'Status Difference';
                            Style = Attention;
                            ToolTip = 'Specifies if the difference between the amount in the Statement Amount field needs to be reconciled.';
                        }
                    }
                }
            }

            group(MatchDetails)
            {
                Caption = 'Match Details';
                Visible = IsMatchedAutomatically;
                Editable = false;
                field(MatchConfidence; BankPmtApplRule."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Confidence';
                    ToolTip = 'Specifies the quality of the match between the bank statement line and the open ledger entry.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Payment Application Rules", BankPmtApplRule);
                    end;
                }

                group(ReledatedParty)
                {
                    Caption = 'Related Party';
                    field(RelatedPatryMatchedOverview; RelatedPartyMatchedText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Related Party Matched';
                        Editable = false;
                        Enabled = RelatedPartyMatchDetailsEnabled;
                        ToolTip = 'Specifies if information about the business partner on the bank statement line matches with the name on the open ledger entry.';

                        trigger OnDrillDown()
                        begin
                            Message(RelatedPartyMatchInfoText);
                        end;
                    }
                }

                group(DocExtDocNoMatchedGroup)
                {
                    Caption = 'Document Number';
                    field(DocExtDocNoMatchedOverview; DocumentMatchedText)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = DocumentMatchDetailsEnabled;
                        Caption = 'Document No./Ext. Document No. Matched';
                        Editable = false;
                        ToolTip = 'Specifies if text on the bank statement line matches with text in the Document No. and/or External Document No. fields on the open ledger entry.';

                        trigger OnDrillDown()
                        begin
                            Message(DocumentMatchInfoText);
                        end;
                    }

                    field(DocExtDocNumber; Rec.GetAppliedToDocumentNo())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Number';
                        Editable = false;
                        ToolTip = 'Specifies the document number that the payment was applied to.';

                        trigger OnDrillDown()
                        begin
                            Rec.ShowAppliedToEntries();
                        end;
                    }
                }

                group(DirectDebitGroup)
                {
                    Caption = 'Direct Debit';
                    Visible = DirectDebitMatched;
                    field(DirectDebit; DirectDebitMatchedText)
                    {
                        Visible = DirectDebitMatched;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Direct Debit Collect. Matched';
                        Editable = false;
                        ToolTip = 'Specifies if information about a direct debit collection on the bank statement line matches with the open ledger entry.';
                    }
                }

                group(AmountMatchingDetails)
                {
                    Caption = 'Amount Matching Details';
                    field(AmountMatchText; AmountMatchText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Incl. Tolerance Matched:';
                        ToolTip = 'Specifies how many open ledger entries match the amount on the bank statement line.';
                    }

                    field(AccountNameReview; Rec.GetAppliedToName())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Open Ledger Entries for';
                        ToolTip = 'Specifies the number of open ledger entries for the customer or vendor.';

                        trigger OnDrillDown()
                        begin
                            Rec.OpenAccountPage(Rec."Account Type".AsInteger(), Rec."Account No.");
                        end;
                    }

                    field(NoOfLedgerEntriesWithinAmount; NoOfLedgerEntriesWithinAmountTolerance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Within Amount Tolerance';
                        Editable = false;
                        ToolTip = 'Specifies the number of open ledger entries where the payment amount is within the payment tolerance of the amount.';

                        trigger OnDrillDown()
                        begin
                            Rec.DrillDownOnNoOfLedgerEntriesWithinAmountTolerance();
                        end;
                    }

                    field(NoOfLedgerEntriesOutsideAmount; NoOfLedgerEntriesOutsideAmountTolerance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Outside Amount Tolerance';
                        Editable = false;
                        ToolTip = 'Specifies the number of open ledger entries where the payment amount is outside of the payment tolerance amount.';

                        trigger OnDrillDown()
                        begin
                            Rec.DrillDownOnNoOfLedgerEntriesOutsideOfAmountTolerance();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(Accept)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accept Application';
                    Image = Approve;
                    Enabled = not LineNotAppliedVisible;
                    ToolTip = 'Accept an automatic payment application after reviewing it or manually applying it. This closes the payment application and sets the Match Confidence field to Accepted.';

                    trigger OnAction()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.AcceptAppliedPaymentEntriesSelectedLines();
                        Rec.Next();
                    end;
                }

                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Application';
                    Image = Reject;
                    Enabled = not LineNotAppliedVisible;
                    ToolTip = 'Remove a payment application from a ledger entry. This unapplies the payment.';

                    trigger OnAction()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.RejectAppliedPaymentEntriesSelectedLines();
                    end;
                }

                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Manually';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ToolTip = 'Review and apply payments that were applied automatically to wrong open ledger entries or not applied at all.';

                    trigger OnAction()
                    var
                    begin
                        Rec.DisplayApplication();
                        Rec.GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
                    end;
                }

                action(TransferDiffToAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer Difference to Account';
                    Image = TransferToGeneralJournal;
                    ToolTip = 'Specify the balancing account that you want a non-applicable payment amount on a payment reconciliation journal line to be posted to when you post the journal.';

                    trigger OnAction()
                    var
                        TempGenJournalLine: Record "Gen. Journal Line" temporary;
                        MatchBankPayments: Codeunit "Match Bank Payments";
                    begin
                        MatchBankPayments.TransferDiffToAccount(Rec, TempGenJournalLine)
                    end;
                }

                action(AddMappingRule)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Map Text to Account';
                    Image = Add;
                    ToolTip = 'Associate text on payments with debit, credit, or balancing accounts so that payments are posted to the accounts when you post payments. The payments are not applied to invoices or credit memos, and are suited for recurring cash receipts or expenses.';

                    trigger OnAction()
                    var
                        TextToAccMapping: Record "Text-to-Account Mapping";
                        MatchBankPayments: Codeunit "Match Bank Payments";
                    begin
                        TextToAccMapping.InsertRecFromBankAccReconciliationLine(Rec);

                        Commit();
                        if Confirm(WouldYouLikeToRunMapTexttoAccountAgainQst) then
                            MatchBankPayments.RerunTextMapper(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Accept_Promoted; Accept)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(ApplyEntries_Promoted; ApplyEntries)
                {
                }
                actionref(TransferDiffToAccount_Promoted; TransferDiffToAccount)
                {
                }
                actionref(AddMappingRule_Promoted; AddMappingRule)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        TotalNumberOfRecordsToReview := Rec.Count();
        CurrentRecordToReview := 0;
        CurrPage.Caption(PageCaptionLbl);
        Clear(VisitedKeys);
    end;

    trigger OnAfterGetRecord()
    var
        TempReviewBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        ClearGlobals();
        Rec.CalcFields("Match Confidence", "Match Quality");
        HasPaymentFile := Rec.GetPaymentFile(DataExchField);
        Rec.GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
        CurrentRecordToReview := VisitedKeys.IndexOf(Rec."Statement Line No.");
        if (CurrentRecordToReview < 1) then begin
            VisitedKeys.Add(Rec."Statement Line No.");
            CurrentRecordToReview := VisitedKeys.Count();
        end;

        DifferenceVisible := (Rec.Difference <> 0) and (Rec."Applied Entries" > 0);
        LineNotAppliedVisible := Rec."Applied Entries" = 0;
        TotalNumberOfRecordsToReview := Rec.Count();
        IsMatchedAutomatically := MatchBankPayments.IsMatchedAutomatically(Rec, BankPmtApplRule);
        MatchBankPayments.GetMatchPaymentDetailsInfo(Rec, BankPmtApplRule, IsMatchedAutomatically, RelatedPartyMatchedText, AmountMatchText, DocumentMatchedText, DirectDebitMatchedText, DirectDebitMatched, NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance, RelatedPartyMatchInfoText, DocumentMatchInfoText);
        DocumentMatchDetailsEnabled := DocumentMatchInfoText <> '';
        RelatedPartyMatchDetailsEnabled := RelatedPartyMatchInfoText <> '';

        if IsMatchedAutomatically then begin
            TempReviewBankPmtApplRule.Copy(BankPmtApplRule);
            TempReviewBankPmtApplRule.Insert();
            TempReviewBankPmtApplRule.SetFilter(Score, BankPmtApplRule.GetReviewRequiredScoreFilter());
            ReviewRequiredVisible := not TempReviewBankPmtApplRule.IsEmpty();
        end;

        ReviewRequiredTxt := StrSubstNo(ReviewRequiredLbl, Format(Rec."Match Confidence"));

        if TotalNumberOfRecordsToReview > 1 then
            CurrPage.Caption(PageCaptionLbl + StrSubstNo(RemainingRecordToReviewPageCaptionLbl, TotalNumberOfRecordsToReview))
        else
            CurrPage.Caption(PageCaptionLbl);
    end;

    local procedure ClearGlobals()
    begin
        Clear(BankPmtApplRule);
        Clear(NoOfLedgerEntriesWithinAmountTolerance);
        Clear(NoOfLedgerEntriesOutsideAmountTolerance);
        Clear(RelatedPartyMatchedText);
        Clear(AmountMatchText);
        Clear(DocumentMatchedText);
        Clear(DirectDebitMatchedText);
        Clear(DirectDebitMatched);
        Clear(IsMatchedAutomatically);
        Clear(DocumentMatchDetailsEnabled);
        Clear(RelatedPartyMatchDetailsEnabled);
        Clear(RelatedPartyMatchInfoText);
        Clear(DocumentMatchInfoText);
    end;

    var
        AppliedPmtEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        DataExchField: Record "Data Exch. Field";
        VisitedKeys: List of [Integer];
        HasPaymentFile: Boolean;
        LineNotAppliedVisible: Boolean;
        DifferenceVisible: Boolean;
        ReviewRequiredVisible: Boolean;
        RemainingAmountAfterPosting: Decimal;
        StatementToRemAmtDifference: Decimal;
        PmtAppliedToTxt: Text;
        ReviewRequiredTxt: Text;
        RelatedPartyMatchDetailsEnabled: Boolean;
        IsMatchedAutomatically: Boolean;
        TotalNumberOfRecordsToReview: Integer;
        CurrentRecordToReview: Integer;
        PageCaptionLbl: Label 'Payment Application Review';
        LineNotAppliedLbl: Label 'The payment is not applied to any entries.';
        ReviewRequiredLbl: Label 'Matched Automatically - Confidence: %1. Review is required for this rule.', Comment = '%1 - Matching confidence, can be None, Low, Medium, High';
        DifferenceToReconcileLbl: Label 'The difference must be resolved before you can post.';
        RemainingRecordToReviewPageCaptionLbl: Label ' - %1 Remaining', Comment = 'Text before is Payment Application Review - Remaining - %1. %1 is the total number of lines.';
        WouldYouLikeToRunMapTexttoAccountAgainQst: Label 'Do you want to re-apply the text to account mapping rules to all lines in the bank statement?';

    protected var
        AmountMatchText: Text;
        DirectDebitMatchedText: Text;
        DirectDebitMatched: Boolean;
        DocumentMatchDetailsEnabled: Boolean;
        DocumentMatchedText: Text;
        DocumentMatchInfoText: Text;
        RelatedPartyMatchedText: Text;
        RelatedPartyMatchInfoText: Text;
        NoOfLedgerEntriesWithinAmountTolerance: Integer;
        NoOfLedgerEntriesOutsideAmountTolerance: Integer;
}
