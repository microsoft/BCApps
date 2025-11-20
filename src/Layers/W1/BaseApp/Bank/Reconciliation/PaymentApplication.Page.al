// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;
using System.IO;

page 1292 "Payment Application"
{
    Caption = 'Payment Application';
    DelayedInsert = true;
    DeleteAllowed = false;
    PageType = Worksheet;
    SourceTable = "Payment Application Proposal";
    SourceTableTemporary = true;
    SourceTableView = sorting("Sorting Order")
                      order(ascending);

    layout
    {
        area(content)
        {
            group(PaymentInformation)
            {
                Caption = 'Payment Information';
                field(PaymentStatus; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Status';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the application status of the payment, including information about the match confidence of payments that are applied automatically.';
                }
                field(TransactionDate; BankAccReconLine."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when the payment was recorded in the bank account.';
                }
                field(TransactionAmount; BankAccReconLine."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Amount';
                    Editable = false;
                    ToolTip = 'Specifies the payment amount that was recorded on the electronic bank account.';
                }
                field(BankAccReconLineDescription; BankAccReconLine."Transaction Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Text';
                    Editable = false;
                    ToolTip = 'Specifies the text that was entered on the payment when the payment was made to the electronic bank account.';
                }
            }
            group("Open Entries")
            {
                Caption = 'Open Entries';
                repeater(Control28)
                {
                    Caption = 'Open Entries';
                    field(AppliedAmount; Rec."Applied Amt. Incl. Discount")
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Applied Amount';
                        Style = Strong;
                        StyleExpr = true;
                        ToolTip = 'Specifies the payment amount, excluding the value in the Applied Pmt. Discount field, that is applied to the open entry.';

                        trigger OnValidate()
                        begin
                            UpdateAfterChangingApplication();
                        end;
                    }
                    field(Applied; Rec.Applied)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies that the payment specified on the header of the Payment Application window is applied to the open entry.';

                        trigger OnValidate()
                        begin
                            UpdateAfterChangingApplication();
                        end;
                    }
                    field(RemainingAmountAfterPosting; Rec.GetRemainingAmountAfterPostingValue())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remaining Amount After Posting';
                        ToolTip = 'Specifies the amount that remains to be paid for the open entry after you have posted the payment in the Payment Reconciliation Journal window.';
                    }
                    field("Applies-to Entry No."; Rec."Applies-to Entry No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the number of the customer or vendor ledger entry that the payment will be applied to when you post the payment reconciliation journal line.';

                        trigger OnDrillDown()
                        begin
                            Rec.AppliesToEntryNoDrillDown();
                        end;
                    }
                    field("Due Date"; Rec."Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the due date of the open entry.';
                    }
                    field("Document Type"; Rec."Document Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the type of document that is related to the open entry.';
                    }
                    field("Document No."; Rec."Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the number of the document that is related to the open entry.';
                    }
                    field("External Document No."; Rec."External Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the description of the open entry.';
                    }
                    field("Remaining Amount"; Rec."Remaining Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the amount that remains to be paid for the open entry.';
                        Visible = false;
                    }
                    field("Remaining Amt. Incl. Discount"; Rec."Remaining Amt. Incl. Discount")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the amount that remains to be paid for the open entry, minus any granted payment discount.';
                    }
                    field("Pmt. Disc. Due Date"; Rec."Pmt. Disc. Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pmt. Discount Date';
                        ToolTip = 'Specifies the date on which the remaining amount on the open entry must be paid to grant a discount.';

                        trigger OnValidate()
                        begin
                            UpdateAfterChangingApplication();
                        end;
                    }
                    field("Pmt. Disc. Tolerance Date"; Rec."Pmt. Disc. Tolerance Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for payment discount tolerance to be granted.';
                        Visible = false;
                    }
                    field("Remaining Pmt. Disc. Possible"; Rec."Remaining Pmt. Disc. Possible")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remaining Pmt. Discount Possible';
                        ToolTip = 'Specifies how much discount you can grant for the payment if you apply it to the open entry.';

                        trigger OnValidate()
                        begin
                            UpdateAfterChangingApplication();
                        end;
                    }
                    field(AccountName; Rec.GetAccountName())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the account that the payment is applied to in the Payment Reconciliation Journal window.';

                        trigger OnDrillDown()
                        begin
                            Rec.AccountNameDrillDown();
                        end;
                    }
                    field("Account Type"; Rec."Account Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = LineEditable;
                        ToolTip = 'Specifies the type of account that the payment application will be posted to when you post the payment reconciliation journal.';
                    }
                    field("Account No."; Rec."Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = LineEditable;
                        ToolTip = 'Specifies the account number the payment application will be posted to when you post the payment reconciliation journal.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord();
                        end;
                    }
                    field("Posting Date"; Rec."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the posting date of the open entry.';
                        Visible = false;
                    }
                    field("Match Confidence"; Rec."Match Confidence")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the quality of the match between the payment and the open entry for payment application purposes.';
                    }
                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Entry Currency Code';
                        ToolTip = 'Specifies the currency code of the open entry.';
                        Visible = false;
                    }
                }
            }
            group(Control5)
            {
                ShowCaption = false;
                field(TotalAppliedAmount; BankAccReconLine."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Applied Amount';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the values in the Applied Amount field on lines in the Payment Application window.';
                }
                field(TotalRemainingAmount; BankAccReconLine."Statement Amount" - BankAccReconLine."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    StyleExpr = RemAmtToApplyStyleExpr;
                    ToolTip = 'Specifies how much of the payment amount remains to be applied to open entries in the Payment Application window.';
                }
            }
        }
        area(factboxes)
        {
            part(Control2; "Payment-to-Entry Match")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = field("Bank Account No."),
                              "Statement No." = field("Statement No."),
                              "Statement Line No." = field("Statement Line No."),
                              "Statement Type" = field("Statement Type"),
                              "Account Type" = field("Account Type"),
                              "Account No." = field("Account No."),
                              "Applies-to Entry No." = field("Applies-to Entry No."),
                              "Match Confidence" = field("Match Confidence"),
                              Quality = field(Quality);
            }
            part(Control1; "Additional Match Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = field("Bank Account No."),
                              "Statement No." = field("Statement No."),
                              "Statement Line No." = field("Statement Line No."),
                              "Statement Type" = field("Statement Type");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Details)
            {
                Caption = 'Details';
                action(ShowBankTransactionDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Transaction Details';
                    Image = ExternalDocument;
                    ToolTip = 'View the bank statement details for the selected line. The details include the values that exist in an imported bank statement file.';

                    trigger OnAction()
                    var
                        DataExchField: Record "Data Exch. Field";
                    begin
                        DataExchField.SetRange("Data Exch. No.", BankAccReconLine."Data Exch. Entry No.");
                        DataExchField.SetRange("Line No.", BankAccReconLine."Data Exch. Line No.");
                        PAGE.Run(PAGE::"Bank Statement Line Details", DataExchField);
                    end;
                }
            }
        }
        area(processing)
        {
            group(Review)
            {
                Caption = 'Review';
                action(Accept)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accept Applications';
                    Image = Approve;
                    ToolTip = 'Accept a payment application after reviewing it or manually applying it to entries. This closes the payment application and sets the Match Confidence to Accepted.';

                    trigger OnAction()
                    begin
                        if BankAccReconLine.Difference * BankAccReconLine."Applied Amount" > 0 then
                            if BankAccReconLine."Account Type" = BankAccReconLine."Account Type"::"Bank Account" then
                                Error(ExcessiveAmountErr, BankAccReconLine.Difference);

                        BankAccReconLine.AcceptApplication();
                        CurrPage.Close();
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Applications';
                    Image = Reject;
                    ToolTip = 'Remove a payment application from an entry. This unapplies the payment.';

                    trigger OnAction()
                    begin
                        if Confirm(RemoveApplicationsQst) then
                            Rec.RemoveApplications();
                    end;
                }
            }
            group(Show)
            {
                Caption = 'Show';
                action(AllOpenEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All Open Entries';
                    Image = ViewDetails;
                    ToolTip = 'Show all open entries that the payment can be applied to.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Applied);
                        Rec.SetRange("Account Type");
                        Rec.SetRange("Account No.");
                        Rec.SetRange(Type, Rec.Type::"Bank Account Ledger Entry", Rec.Type::"Check Ledger Entry");

                        if Rec.FindFirst() then;
                    end;
                }
                action(SortEntriesBasedOnProbability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Entries';
                    Image = Suggest;
                    Visible = SortEntriesBasedOnProbabilityVisible;
                    ToolTip = 'Sort the list based on the probability that it is a match.';

                    trigger OnAction()
                    var
                        GetBankStmtLineCandidates: Codeunit "Get Bank Stmt. Line Candidates";
                    begin
                        Rec.Reset();
                        Rec.DeleteAll();
                        Rec.TransferFromBankAccReconLine(BankAccReconLine);

                        GetBankStmtLineCandidates.SetSuggestEntries(true);
                        GetBankStmtLineCandidates.Run(Rec);
                        Rec.SetCurrentKey("Sorting Order", "Stmt To Rem. Amount Difference");
                        Rec.Ascending(true);

                        if Rec.FindFirst() then;
                        CurrPage.Update();
                    end;
                }
                action(RelatedPartyOpenEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related-Party Open Entries';
                    Image = ViewDocumentLine;
                    ToolTip = 'Show only open entries that are specifically for the related party in the Account No. field. This limits the list to those open entries that are most likely to relate to the payment.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Applied);

                        BankAccReconLine.Get(
                          BankAccReconLine."Statement Type", BankAccReconLine."Bank Account No.",
                          BankAccReconLine."Statement No.", BankAccReconLine."Statement Line No.");

                        if BankAccReconLine."Account No." <> '' then begin
                            Rec.SetRange("Account No.", BankAccReconLine."Account No.");
                            Rec.SetRange("Account Type", BankAccReconLine."Account Type");
                        end;
                        Rec.SetRange(Type, Rec.Type::"Bank Account Ledger Entry", Rec.Type::"Check Ledger Entry");

                        if Rec.FindFirst() then;
                    end;
                }
                action(AppliedEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Entries';
                    Image = ViewRegisteredOrder;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Applied, true);
                        Rec.SetRange("Account Type");
                        Rec.SetRange("Account No.");
                        Rec.SetRange(Type, Rec.Type::"Bank Account Ledger Entry", Rec.Type::"Check Ledger Entry");

                        if Rec.FindFirst() then;
                    end;
                }
                action(AllOpenBankTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All Open Bank Transactions';
                    Image = ViewPostedOrder;
                    ToolTip = 'View all open bank entries that the payment can be applied to.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Applied);
                        Rec.SetRange("Account Type", Rec."Account Type"::"Bank Account");
                        Rec.SetRange("Account No.");
                        Rec.SetRange(Type, Rec.Type::"Bank Account Ledger Entry");

                        if Rec.FindFirst() then;
                    end;
                }
                action(AllOpenPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All Open Payments';
                    Image = ViewCheck;
                    ToolTip = 'Show all open checks that the payment can be applied to.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Applied);
                        Rec.SetRange("Account Type", Rec."Account Type"::"Bank Account");
                        Rec.SetRange("Account No.");
                        Rec.SetRange(Type, Rec.Type::"Check Ledger Entry");
                        if Rec.FindFirst() then;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Accept_Promoted; Accept)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Show', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(RelatedPartyOpenEntries_Promoted; RelatedPartyOpenEntries)
                {
                }
                actionref(AllOpenBankTransactions_Promoted; AllOpenBankTransactions)
                {
                }
                actionref(AllOpenEntries_Promoted; AllOpenEntries)
                {
                }
                actionref(AppliedEntries_Promoted; AppliedEntries)
                {
                }
                actionref(AllOpenPayments_Promoted; AllOpenPayments)
                {
                }
                actionref(SortEntriesBasedOnProbability_Promoted; SortEntriesBasedOnProbability)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateTotals();
        LineEditable := Rec."Applies-to Entry No." = 0;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.TransferFromBankAccReconLine(BankAccReconLine);
    end;

    trigger OnOpenPage()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        GetBankStmtLineCandidates: Codeunit "Get Bank Stmt. Line Candidates";
        StartTime: DateTime;
        TImePassed: Duration;
        OpeningPageDuration: Duration;
    begin

        BankPmtApplSettings.GetOrInsert();
        if not BankPmtApplSettings."Apply Man. Disable Suggestions" then
            StartTime := CurrentDateTime();

        SortEntriesBasedOnProbabilityVisible := BankPmtApplSettings."Apply Man. Disable Suggestions";

        CODEUNIT.Run(CODEUNIT::"Get Bank Stmt. Line Candidates", Rec);
        Rec.SetCurrentKey("Sorting Order", "Stmt To Rem. Amount Difference");
        Rec.Ascending(true);
        if BankAccReconLine."Account No." <> '' then begin
            Rec.SetRange("Account No.", BankAccReconLine."Account No.");
            Rec.SetRange("Account Type", BankAccReconLine."Account Type");
        end;
        if Rec.FindFirst() then;

        if not BankPmtApplSettings."Apply Man. Disable Suggestions" then begin
            TimePassed := CurrentDateTime - StartTime;
            OpeningPageDuration := 1000 * 10;

            if TimePassed > OpeningPageDuration then
                GetBankStmtLineCandidates.ShowDisableAutomaticSuggestionsNotification();
        end;
    end;

    var
        RemAmtToApplyStyleExpr: Text;
        RemoveApplicationsQst: Label 'Are you sure you want to remove all applications?';
        Status: Text;
        AppliedManuallyStatusTxt: Label 'Applied Manually';
        NoApplicationStatusTxt: Label 'Not Applied';
#pragma warning disable AA0470
        AppliedAutomaticallyStatusTxt: Label 'Applied Automatically - Match Confidence: %1';
#pragma warning restore AA0470
        AcceptedStatusTxt: Label 'Accepted';
        LineEditable: Boolean;
        SortEntriesBasedOnProbabilityVisible: Boolean;
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';

    protected var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";

    procedure SetBankAccReconcLine(NewBankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconLine := NewBankAccReconLine;
        Rec.TransferFromBankAccReconLine(NewBankAccReconLine);

        OnSetBankAccReconcLine(BankAccReconLine);
    end;

    local procedure UpdateTotals()
    begin
        BankAccReconLine.Get(
          BankAccReconLine."Statement Type", BankAccReconLine."Bank Account No.",
          BankAccReconLine."Statement No.", BankAccReconLine."Statement Line No.");

        BankAccReconLine.CalcFields("Match Confidence");
        case BankAccReconLine."Match Confidence" of
            BankAccReconLine."Match Confidence"::None:
                Status := NoApplicationStatusTxt;
            BankAccReconLine."Match Confidence"::Accepted:
                Status := AcceptedStatusTxt;
            BankAccReconLine."Match Confidence"::Manual:
                Status := AppliedManuallyStatusTxt;
            else
                Status := StrSubstNo(AppliedAutomaticallyStatusTxt, BankAccReconLine."Match Confidence");
        end;

        UpdateRemAmtToApplyStyle();
    end;

    local procedure UpdateRemAmtToApplyStyle()
    begin
        if BankAccReconLine."Statement Amount" = BankAccReconLine."Applied Amount" then
            RemAmtToApplyStyleExpr := 'Favorable'
        else
            RemAmtToApplyStyleExpr := 'Unfavorable';
    end;

    local procedure UpdateAfterChangingApplication()
    begin
        BankAccReconLine.SetManualApplication();
        UpdateToSystemMatchConfidence();
        UpdateTotals();
    end;

    local procedure UpdateToSystemMatchConfidence()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if (Rec."Match Confidence" = Rec."Match Confidence"::Accepted) or (Rec."Match Confidence" = Rec."Match Confidence"::Manual) then
            Rec."Match Confidence" := Enum::"Bank Rec. Match Confidence".FromInteger(BankPmtApplRule.GetMatchConfidence(Rec.Quality));
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnSetBankAccReconcLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}

