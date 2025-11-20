// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.FinanceCharge;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;
using System.Telemetry;
using System.Utilities;

page 1290 "Payment Reconciliation Journal"
{
    AutoSplitKey = true;
    Caption = 'Payment Reconciliation Journal';
    DataCaptionExpression = Rec."Bank Account No.";
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableView = where("Statement Type" = const("Payment Application"));
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                FreezeColumn = "Statement Amount";
                ShowCaption = false;
                field("Match Confidence"; Rec."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the quality of the automatic payment application on the journal line.';
                    StyleExpr = ReviewStatusStyleTxt;

                    trigger OnDrillDown()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        if BankPmtApplRule.IsMatchedAutomatically(Rec."Match Confidence".AsInteger(), Rec."Applied Entries") then begin
                            Page.RunModal(Page::"Payment Application Review", BankAccReconciliationLine);
                            exit;
                        end;

                        Rec.DisplayApplication();
                    end;
                }
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
                }
                field("Transaction ID"; Rec."Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the imported bank transaction.';
                    Visible = false;
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Amount';
                    ToolTip = 'Specifies the amount that was paid into the bank account and then imported as a bank statement line represented by the journal line.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                        if not BankAccReconciliation.IsEmpty() then begin
                            BankAccReconciliation.Validate("Statement Ending Balance", 0.0);
                            BankAccReconciliation.Modify();
                        end;
                    end;
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that has been applied to one or more open entries.';
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Unfavorable;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the amount in the Applied Amount field.';
                }
                field(StatementToRemAmtDifference; StatementToRemAmtDifference)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Difference from Remaining Amount';
                    Enabled = false;
                    ToolTip = 'Specifies the difference between the values in the Statement Amount and the Remaining Amount After Posting fields.';
                    Visible = false;
                }
                field(GetAppliedToDocumentNo; Rec.GetAppliedToDocumentNo())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the open entry that the payment is applied to.';
                }
                field(DescAppliedEntry; AppliedPmtEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description on the open entry that the payment is applied to.';
                }
                field(DueDateAppliedEntry; AppliedPmtEntry."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date on the open entry that the payment is applied to.';
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
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the payment application will be posted to when you post the worksheet.';

                    trigger OnValidate()
                    var
                        GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                    begin
                        GenJournalAllocAccMgt.PreventAllocationAccountsFromThisPage(Rec."Account Type");
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the payment application will be posted to when you post the worksheet.';

                    trigger OnValidate()
                    var
                        IsHandled: Boolean;
                    begin
                        CurrPage.Update();

                        IsHandled := false;
                        OnValidateAccountNoOnBeforeTransferRemainingAmountToAccount(Rec, IsHandled);
                        if not IsHandled then
                            if Rec.Difference <> 0 then
                                Rec.TransferRemainingAmountToAccount();
                    end;
                }
                field(PostingDateAppliedEntry; AppliedPmtEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date on the open entry that the payment is applied to.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("AppliedPmtEntry.""Currency Code"""; AppliedPmtEntry."Currency Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Entry Currency Code';
                    ToolTip = 'Specifies the currency code on the open entry that the payment is applied to.';
                    Visible = false;
                }
                field("Match Details"; MatchDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Details';
                    Editable = false;
                    ToolTip = 'Specifies details about the payment application on the journal line.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        if BankPmtApplRule.IsMatchedAutomatically(Rec."Match Confidence".AsInteger(), Rec."Applied Entries") then begin
                            Page.RunModal(Page::"Payment Application Review", BankAccReconciliationLine);
                            exit;
                        end;

                        Rec.DisplayApplication();
                    end;
                }
                field("Applied Entries"; Rec."Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies for a journal line where the payment has been applied, how many entries the payment has been applied to.';
                    Visible = false;
                }
                field(RemainingAmount; RemainingAmountAfterPosting)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Remaining Amount After Posting';
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be paid on the open entry that the payment is applied to.';
                    Visible = false;
                }
                field("Additional Transaction Info"; Rec."Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies additional information on the bank statement line for the payment.';
                    Visible = false;
                    Width = 40;
                }
                field("Related-Party Address"; Rec."Related-Party Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer or vendor who made the payment that is represented by the journal line.';
                    Visible = false;
                    Width = 30;
                }
                field("Related-Party Bank Acc. No."; Rec."Related-Party Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number of the customer or vendor who made the payment.';
                    Visible = false;
                    Width = 20;
                }
                field("Related-Party City"; Rec."Related-Party City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city name of the customer or vendor.';
                    Visible = false;
                    Width = 10;
                }
                field("Related-Party Name"; Rec."Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer or vendor who made the payment that is represented by the journal line.';
                    Visible = false;
                    Width = 30;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up on the General Ledger Setup page.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up om the General Ledger Setup page.';
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
            }

            group(TotalsFooterOuterGroup)
            {
                ShowCaption = false;
                grid(TotalsFooterGroup)
                {
                    ShowCaption = false;
                    Editable = false;
                    GridLayout = columns;

                    grid(TotalLinesGroup)
                    {
                        Caption = 'Lines';
                        GridLayout = Columns;

                        group(ReviewRequiredGroup)
                        {
                            ShowCaption = false;

#if not CLEAN25
                            group("Number of Lines")
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
                            group(LinesWithDifferenceGroup)
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
#endif
                            field(TotalLines; TotalLinesCount)
                            {
                                Caption = 'Number of Lines';
                                ApplicationArea = Basic, Suite;
                                Editable = false;
                                ToolTip = 'Specifies the total number of lines in the journal.';
                            }
                            field(ReviewRequired; LinesForReviewCount)
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = false;
                                Style = StrongAccent;
                                Caption = 'Lines For Review';
                                ToolTip = 'Specifies the number of lines that you should review because they were matched automatically. The matching rule used is marked as Review Required on the Payment Application Rules page.';

                                trigger OnDrillDown()
                                var
                                    BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                                begin
                                    GetLinesForReview(BankAccReconciliationLine);
                                    Page.Run(Page::"Payment Application Review", BankAccReconciliationLine);
                                    CurrPage.Update(false);
                                end;
                            }
                            field(LinesWithDifference; LinesWithDifferenceCount)
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = false;
                                Caption = 'Lines With differences';
                                ToolTip = 'Specifies the number of lines that must be addressed before posting.';

                                trigger OnDrillDown()
                                var
                                    BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                                begin
                                    GetLinesWithDifference(BankAccReconciliationLine);
                                    Page.Run(Page::"Payment Application Review", BankAccReconciliationLine);
                                end;
                            }
                        }
                    }
                    grid(TotalTransactionAmountGroup)
                    {
                        GridLayout = Columns;

                        group(TotalTransactionAmountGroup1)
                        {
                            ShowCaption = false;
                            Editable = false;

#if not CLEAN25
                            group("Transaction Total")
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
                            group(CreditDebit)
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
#endif
                            field(TotalTransactionAmountFixedLayout; BankAccReconciliation."Total Transaction Amount")
                            {
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                Style = Strong;
                                Caption = 'Total Transaction Amount';
                                ToolTip = 'Specifies the sum of values in the Statement Amount field on all the lines on the Payment Reconciliation Journal page.';
                            }
                            field(TotalPaidAmountFixedLayout; BankAccReconciliation."Total Paid Amount")
                            {
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                Caption = 'Total Credit Amount';
                                ToolTip = 'Specifies the sum of values in the Statement Amount field on all the paid lines on the Payment Reconciliation Journal page.';
                            }
                            field(TotalReceivedAmountFixedLayout; BankAccReconciliation."Total Received Amount")
                            {
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                Caption = 'Total Debit Amount';
                                ToolTip = 'Specifies the sum of values in the Statement Amount field on all the received lines on the Payment Reconciliation Journal page.';
                            }
                        }
                    }
                    grid(Balances)
                    {
                        ShowCaption = false;
                        GridLayout = Columns;

                        group(Balances1)
                        {
                            ShowCaption = false;
#if not CLEAN25
                            group(BalanceOnBankAccountGroup)
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
                            group(BalanceOnBankAccountAfterPostingGroup)
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
                            group(StatementEndingBalanceGroup)
                            {
                                Visible = false;
                                ShowCaption = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Rearranging the footer fields.';
                                ObsoleteTag = '25.0';
                            }
#endif
                            field(BalanceOnBankAccountFixedLayout; BankAccReconciliation."Total Balance on Bank Account")
                            {
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                Caption = 'Balance on Bank Account';
                                ToolTip = 'Specifies the balance of the bank account per the last time you reconciled the bank account.';

                                trigger OnDrillDown()
                                begin
                                    BankAccReconciliation.DrillDownOnBalanceOnBankAccount();
                                end;
                            }
                            field(BalanceOnBankAccountAfterPostingFixedLayout; BankAccReconciliation."Total Balance on Bank Account" + BankAccReconciliation."Total Unposted Applied Amount" + AppliedBankAmounts)
                            {
                                Caption = 'Balance After Posting';
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                ToolTip = 'Specifies the total amount that will exist on the bank account as a result of payment applications that you post on the Payment Reconciliation Journal page.';
                            }
                            field(StatementEndingBalanceFixedLayout; StatementEndingBalance)
                            {
                                ApplicationArea = Basic, Suite;
                                AutoFormatType = 1;
                                Editable = false;
                                Caption = 'Statement Ending Balance';
                                ToolTip = 'Specifies the balance on your actual bank account after the bank has processed the payments that you have imported with the bank statement file.';
                            }
                        }
                    }
                }
            }
        }

        area(factboxes)
        {
            part(Control2; "Payment Rec Match Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Account No." = field("Bank Account No."),
                              "Statement No." = field("Statement No."),
                              "Statement Line No." = field("Statement Line No."),
                              "Statement Type" = field("Statement Type"),
                              "Account Type" = field("Account Type"),
                              "Account No." = field("Account No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(ImportBankTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Bank Transactions';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import a file for transaction payments that was made from your bank account and apply the payments to the entry. The file name must end in .csv, .txt, asc, or .xml.';

                    trigger OnAction()
                    var
                        SubscriberInvoked: Boolean;
                    begin
                        OnAfterImportBankTransactions(SubscriberInvoked, Rec);
                        if not SubscriberInvoked then begin
                            BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
                            BankAccReconciliation.ImportBankStatement();
                            if BankAccReconciliation.Find() then;
                        end;
                    end;
                }
                action(ApplyAutomatically)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Automatically';
                    Image = MapAccounts;
                    RunPageOnRec = true;
                    ToolTip = 'Apply payments to their related open entries based on data matches between bank transaction text and entry information.';

                    trigger OnAction()
                    var
                        BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        AppliedPaymentEntry: Record "Applied Payment Entry";
                        ConfirmManagement: Codeunit "Confirm Management";
                        MatchBankPmtAppl: Codeunit "Match Bank Pmt. Appl.";
                        SubscriberInvoked: Boolean;
                        Overwrite: Boolean;
                    begin
                        AppliedPaymentEntry.SetRange("Statement Type", Rec."Statement Type");
                        AppliedPaymentEntry.SetRange("Bank Account No.", Rec."Bank Account No.");
                        AppliedPaymentEntry.SetRange("Statement No.", Rec."Statement No.");
                        AppliedPaymentEntry.SetFilter("Match Confidence", '%1|%2', AppliedPaymentEntry."Match Confidence"::Accepted, AppliedPaymentEntry."Match Confidence"::Manual);

                        if AppliedPaymentEntry.Count > 0 then
                            Overwrite := ConfirmManagement.GetResponseOrDefault(OverwriteExistingMatchesTxt, false)
                        else
                            Overwrite := true;

                        BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
                        OnAtActionApplyAutomatically(BankAccReconciliation, SubscriberInvoked);
                        if not SubscriberInvoked then
                            if Overwrite then
                                CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation)
                            else
                                MatchBankPmtAppl.MatchNoOverwriteOfManualOrAccepted(BankAccReconciliation);
                        CurrPage.Update(false);
                    end;
                }
                group(Action58)
                {
                    Caption = 'Post';
                    Image = Post;
                    action(TestReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Test Report';
                        Image = TestReport;
                        ToolTip = 'Preview the resulting payment reconciliations to see the consequences before you perform the actual posting.';

                        trigger OnAction()
                        var
                            TestReportPrint: Codeunit "Test Report-Print";
                        begin
                            BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
                            TestReportPrint.PrintBankAccRecon(BankAccReconciliation);
                        end;
                    }
                    action(Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Payments and Reconcile Bank Account';
                        Ellipsis = true;
                        Image = PostApplication;
                        ShortCutKey = 'F9';
                        ToolTip = 'Reconcile the bank account for payments that you post with the journal and close related ledger entries.';

                        trigger OnAction()
                        begin
                            InvokePost(false)
                        end;
                    }
                    action(PostPaymentsOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Payments Only';
                        Ellipsis = true;
                        Image = PaymentJournal;
                        ToolTip = 'Post payments but do not close related bank account ledger entries or reconcile the bank account.';

                        trigger OnAction()
                        begin
                            InvokePost(true)
                        end;
                    }
                    action(Preview)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview Posting';
                        Image = ViewPostedOrder;
                        ShortCutKey = 'Ctrl+Alt+F9';
                        ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                        trigger OnAction()
                        var
                            BankAccReconciliation: Record "Bank Acc. Reconciliation";
                            BankAccReconciliationPost: Codeunit "Bank Acc. Reconciliation Post";
                        begin
                            BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
                            BankAccReconciliationPost.Preview(BankAccReconciliation);
                        end;
                    }
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action(FinanceChargeMemo)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Finance Charge Memo';
                    Enabled = FinanceChargeMemoEnabled;
                    Image = FinChargeMemo;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = field("Account No.");
                    RunPageMode = Create;
                    ToolTip = 'Define a memo that includes information about the calculated interest on outstanding balances of an account. You can then send the memo in an email to the customer.';
                }
                action(OpenGenJnl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = GLRegisters;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "General Journal";
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';
                }
                action("Payment Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Journal';
                    Image = PaymentJournal;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Payment Journal";
                    ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
                }
            }
            group("Manual Application")
            {
                Caption = 'Manual Application';
                action(TransferDiffToAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer Difference to Account';
                    Image = TransferToGeneralJournal;
                    ToolTip = 'Specify the balancing account to which you want a non-applicable payment amount on a payment reconciliation journal line to be posted when you post the journal.';

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
                    ToolTip = 'Associate text on payments with debit, credit, and balancing accounts, so payments are posted to the accounts when you post payments. The payments are not applied to invoices or credit memos, and are suited for recurring cash receipts or expenses.';

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
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Manually';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ToolTip = 'Review and apply payments that were applied automatically to wrong open entries or not applied at all.';

                    trigger OnAction()
                    begin
                        Rec.DisplayApplication();
                        Rec.GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
                    end;
                }
            }
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
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.AcceptAppliedPaymentEntriesSelectedLines();
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Applications';
                    Image = Reject;
                    ToolTip = 'Remove a payment application from an entry. This unapplies the payment.';

                    trigger OnAction()
                    var
                        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    begin
                        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                        BankAccReconciliationLine.RejectAppliedPaymentEntriesSelectedLines();
                    end;
                }
            }
            group("Custom Sorting")
            {
                Caption = 'Custom Sorting';
                action(ShowNonAppliedLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Non-Applied Lines';
                    Image = FilterLines;
                    ToolTip = 'Display only payments in the list that have not been applied.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter(Difference, '<>0');
                        CurrPage.Update();
                    end;
                }
                action(ShowAllLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Lines';
                    Image = AllLines;
                    ToolTip = 'Show all payments in the list no matter what their status is.';

                    trigger OnAction()
                    begin
                        Rec.SetRange(Difference);
                        CurrPage.Update();
                    end;
                }
                action(SortForReviewDescending)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sort for Review Descending';
                    Image = MoveDown;
                    ToolTip = 'Sort the lines in ascending order.';

                    trigger OnAction()
                    begin
                        UpdateSorting(false);
                    end;
                }
                action(SortForReviewAscending)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sort for Review Ascending';
                    Image = MoveUp;
                    ToolTip = 'Sort the lines in descending order.';

                    trigger OnAction()
                    begin
                        UpdateSorting(true);
                    end;
                }
            }
        }
        area(navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
                    BankAccReconciliation.ShowDocDim();
                    CurrPage.SaveRecord();
                end;
            }
            action(LineDimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Line Dimensions';
                Image = Dimensions;
                ToolTip = 'View or edit the line dimensions sets that are set up for the current line.';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                end;
            }
            action("Bank Account Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Card';
                Image = BankAccount;
                RunObject = Page "Payment Bank Account Card";
                RunPageLink = "No." = field("Bank Account No.");
                ToolTip = 'View or edit information about the bank account that is related to the payment reconciliation journal.';
            }
            group(Details)
            {
                Caption = 'Details';
                action(ShowBankTransactionDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Transaction Details';
                    Image = ExternalDocument;
                    RunObject = Page "Bank Statement Line Details";
                    RunPageLink = "Data Exch. No." = field("Data Exch. Entry No."),
                                  "Line No." = field("Data Exch. Line No.");
                    ToolTip = 'View the values that exist in an imported bank statement file for the selected line.';
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Statement Type")), Enum::"Edit in Excel Filter Type"::Equal, Format(Rec."Statement Type"), Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Bank Account No.")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Bank Account No.", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Statement No.")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Statement No.", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Payment Reconciliation Journal", EditInExcelFilters);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ImportBankTransactions_Promoted; ImportBankTransactions)
                {
                }
                actionref(ApplyAutomatically_Promoted; ApplyAutomatically)
                {
                }
                group(Category_Category9)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 8.';
                    ShowAs = SplitButton;

                    actionref(PostPaymentsOnly_Promoted; PostPaymentsOnly)
                    {
                    }
                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                }
                group(Category_Category5)
                {
                    Caption = 'Review', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(Accept_Promoted; Accept)
                    {
                    }
                    actionref(Reject_Promoted; Reject)
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manual Application', Comment = 'Generated from the PromotedActionCategories property index 3.';

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
            group(Category_Category6)
            {
                Caption = 'Details', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Show', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(ShowNonAppliedLines_Promoted; ShowNonAppliedLines)
                {
                }
                actionref(ShowAllLines_Promoted; ShowAllLines)
                {
                }
                actionref(SortForReviewDescending_Promoted; SortForReviewDescending)
                {
                }
                actionref(SortForReviewAscending_Promoted; SortForReviewAscending)
                {
                }
            }
            group(Category_Category10)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 9.';

                actionref(ShowBankTransactionDetails_Promoted; ShowBankTransactionDetails)
                {
                }
                actionref(LineDimensions_Promoted; LineDimensions)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(EditInExcel_Promoted; EditInExcel)
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
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedAmountSum: Decimal;
    begin
        InitializeBankAccRecon();

        FinanceChargeMemoEnabled := Rec."Account Type" = Rec."Account Type"::Customer;
        BankAccReconciliation.CalcFields("Total Balance on Bank Account", "Total Unposted Applied Amount", "Total Transaction Amount",
          "Total Applied Amount", "Total Outstd Bank Transactions", "Total Outstd Payments",
          "Total Paid Amount", "Total Received Amount");
        AppliedBankAmounts := CalcAppliedBankAccountLines();

        UpdateBalanceAfterPostingStyleExpr();

        TestIfFiltershaveBeenRemovedWithRefreshAndClose();
        StatementEndingBalance := '-';
        if BankAccReconciliation."Statement Ending Balance" <> 0 then
            StatementEndingBalance := Format(BankAccReconciliation."Statement Ending Balance");

        GetLinesForReview(BankAccReconciliationLine);
        LinesForReviewCount := BankAccReconciliationLine.Count();
        BankAccReconciliationLine.CalcSums("Applied Amount");
        AppliedAmountSum := BankAccReconciliationLine."Applied Amount";
        CLEAR(BankAccReconciliationLine);
        GetLinesWithDifference(BankAccReconciliationLine);
        LinesWithDifferenceCount := BankAccReconciliationLine.Count();

        TotalLinesCount := Rec.Count();

        UpdateLinesForReviewNotification(AppliedAmountSum);

        UpdateEmptyListNotification();
        UpdateNumberSeriesNotification();
    end;

    local procedure CalcAppliedBankAccountLines(): Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", Rec."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetRange("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
        BankAccReconciliationLine.SetFilter("Account No.", '<>%1', Rec."Bank Account No.");
        BankAccReconciliationLine.CalcSums("Applied Amount");
        exit(BankAccReconciliationLine."Applied Amount");
    end;

    trigger OnAfterGetRecord()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        MatchDetails := PaymentMatchingDetails.MergeMessages(Rec);

        if CurrentClientType() in [ClientType::OData, ClientType::ODataV4, ClientType::SOAP, ClientType::Api] then
            Rec.GetAppliedPmtData(AppliedPmtEntry, PmtAppliedToTxt)
        else
            Rec.GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
        Rec.ShowShortcutDimCode(ShortcutDimCode);

        ReviewStatusStyleTxt := GetReviewStatusStyle(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
        AppliedPmtEntry.Init();
        StatementToRemAmtDifference := 0;
        RemainingAmountAfterPosting := 0;
    end;

    trigger OnOpenPage()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        ServerSetting: Codeunit "Server Setting";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KM9', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KMA', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::"Set up");
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        PageClosedByPosting := false;

        SetDimensionsVisibility();
        ReviewScoreFilter := BankPmtApplRule.GetReviewRequiredScoreFilter();

        StatementEndingBalance := '-';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        BankAccReconciliationTest: Record "Bank Acc. Reconciliation";
    begin
        InitializeBankAccRecon();
        if BankAccReconciliationTest.get(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.") then begin
            BankAccReconciliation.Validate("Statement Ending Balance", 0.0);
            BankAccReconciliation.Modify();
        end;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        BankAccReconciliationTest: Record "Bank Acc. Reconciliation";
    begin
        InitializeBankAccRecon();
        if BankAccReconciliationTest.get(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.") then begin
            BankAccReconciliation.Validate("Statement Ending Balance", 0.0);
            BankAccReconciliation.Modify();
        end;
    end;

    local procedure GetReviewStatusStyle(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Text
    begin
        if (BankAccReconciliationLine."Match Confidence" in [Rec."Match Confidence"::Accepted, Rec."Match Confidence"::Manual]) then
            exit('Favorable');

        exit('Standard');
    end;

    local procedure InitializeBankAccRecon()
    begin
        if not IsBankAccReconInitialized then begin
            BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
            IsBankAccReconInitialized := true;
        end;
    end;

    local procedure GetLinesForReview(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        SetBankAccReconciliationFilter(BankAccReconciliationLine);
        MatchBankPayments.GetLinesForReview(BankAccReconciliationLine, ReviewScoreFilter);
    end;

    local procedure GetLinesWithDifference(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        SetBankAccReconciliationFilter(BankAccReconciliationLine);
        BankAccReconciliationLine.SetFilter(Difference, '<>0');
    end;

    local procedure SetBankAccReconciliationFilter(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
    end;

    local procedure UpdateEmptyListNotification()
    var
        ImportTransactionsNotification: Notification;
    begin
        ImportTransactionsNotification.Id := GetImportTransactionsNotificationId();
        ImportTransactionsNotification.Recall();
        if not Rec.BankStatementLinesListIsEmpty(Rec."Statement No.", Rec."Statement Type".AsInteger(), Rec."Bank Account No.") then
            exit;

        ImportTransactionsNotification.Message := ListEmptyMsg;
        ImportTransactionsNotification.Scope := NotificationScope::LocalScope;
        ImportTransactionsNotification.Send();
    end;

    local procedure UpdateLinesForReviewNotification(AppliedAmountSum: Decimal)
    var
        LinesForReviewNotification: Notification;
    begin
        LinesForReviewNotification.Id := GetLinesForReviewNotificationId();
        LinesForReviewNotification.Recall();

        if (AppliedAmountSum = 0) or not (LinesForReviewCount > 0) then
            exit;

        if not HasApplRulesWithConfidenseAndReviewRequired() then
            exit;

        LinesForReviewNotification.Message := LinesForReviewNotificationMsg;
        LinesForReviewNotification.Scope := NotificationScope::LocalScope;
        LinesForReviewNotification.SetData(Rec.FieldName("Statement No."), Rec."Statement No.");
        LinesForReviewNotification.SetData(Rec.FieldName("Statement Type"), Format(Rec."Statement Type"));
        LinesForReviewNotification.SetData(Rec.FieldName("Bank Account No."), Rec."Bank Account No.");
        LinesForReviewNotification.SetData('ReviewScoreFilter', ReviewScoreFilter);
        LinesForReviewNotification.AddAction(LinesForReviewDifferenceActionLbl, CODEUNIT::"Match Bank Payments", 'OpenLinesForReviewPage');
        LinesForReviewNotification.Send();
    end;

    local procedure UpdateNumberSeriesNotification()
    var
        BankAccount: Record "Bank Account";
        MyNotifications: Record "My Notifications";
        MatchBankPayments: Codeunit "Match Bank Payments";
        NumberSeriesNotification: Notification;
    begin
        NumberSeriesNotification.Id := MatchBankPayments.GetNumberSeriesNotificationId();
        NumberSeriesNotification.Recall();

        if not MyNotifications.IsEnabled(NumberSeriesNotification.Id) then
            exit;

        if BankAccount.Get(BankAccReconciliation."Bank Account No.") then
            if BankAccount."Pmt. Rec. No. Series" <> '' then
                exit;

        NumberSeriesNotification.Message := NoNumberSeriesMsg;
        NumberSeriesNotification.Scope := NotificationScope::LocalScope;
        NumberSeriesNotification.SetData(Rec.FieldName("Bank Account No."), BankAccReconciliation."Bank Account No.");
        NumberSeriesNotification.AddAction(ShowDetailsTxt, CODEUNIT::"Match Bank Payments", 'OpenBankAccountCard');
        NumberSeriesNotification.AddAction(DisableNotificationTxt, CODEUNIT::"Match Bank Payments", 'DisableNotification');
        NumberSeriesNotification.Send();
    end;

    local procedure HasApplRulesWithConfidenseAndReviewRequired(): Boolean
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.SetRange("Match Confidence", Rec."Match Confidence");
        BankPmtApplRule.SetRange("Review Required", true);

        exit(not BankPmtApplRule.IsEmpty());
    end;

    local procedure GetImportTransactionsNotificationId(): Guid
    begin
        exit('eeef0bbe-94d9-44ab-ba93-e3c5c4c07e5b');
    end;

    local procedure GetLinesForReviewNotificationId(): Guid
    begin
        exit('aeef0bbe-94d9-44ab-ba93-e3c5c4c07e4a');
    end;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        AppliedPmtEntry: Record "Applied Payment Entry";
        MatchDetails: Text;
        PmtAppliedToTxt: Label 'The payment has been applied to %1 entries.', Comment = '%1=integer value for number of entries';
        StatementToRemAmtDifference: Decimal;
        FinanceChargeMemoEnabled: Boolean;
        RemainingAmountAfterPosting: Decimal;
        OverwriteExistingMatchesTxt: Label 'Overwriting previous applications will not affect Accepted and Manual ones.\\Chose Yes to overwrite, or No to apply only new entries.';
        BalanceAfterPostingStyleExpr: Text;
        ReviewStatusStyleTxt: Text;
        LinesForReviewCount: Integer;
        LinesWithDifferenceCount: Integer;
        PageMustCloseMsg: Label 'The Payment Reconciliation Journal page has been closed because the connection was suspended.';
        PageClosedByPosting: Boolean;
        AppliedBankAmounts: Decimal;
        IsSaaSExcelAddinEnabled: Boolean;
        ReviewScoreFilter: Text;
        TotalLinesCount: Integer;
        ListEmptyMsg: Label 'No bank transaction lines exist. Choose the Import Bank Transactions action to fill in the lines from a file, or enter lines manually.';
        LinesForReviewNotificationMsg: Label 'One or more lines must be reviewed before posting, because they were matched automatically with rules that require review.', Comment = '%1 number of lines for review';
        LinesForReviewDifferenceActionLbl: Label 'Review applications';
        NoNumberSeriesMsg: Label 'You can specify a number series for this journal. Open the bank account card and choose a number series in the Payment Reconciliation No. Series field.';
        ShowDetailsTxt: Label 'Open bank account card';
        DisableNotificationTxt: Label 'Don''t show this again';
        WouldYouLikeToRunMapTexttoAccountAgainQst: Label 'Do you want to re-apply the text to account mapping rules to all lines in the bank statement?';
        StatementEndingBalance: Text;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        IsBankAccReconInitialized: Boolean;

    local procedure UpdateSorting(IsAscending: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentMatchingDetails: Record "Payment Matching Details";
        AppliedPaymentEntry2: Record "Applied Payment Entry";
        AmountDifference: Decimal;
        ScoreRange: Integer;
        SubscriberInvoked: Boolean;
    begin
        BankAccReconciliationLine.SetRange("Statement Type", Rec."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetAutoCalcFields("Match Confidence");

        if BankAccReconciliationLine.FindSet() then begin
            repeat
                ScoreRange := 10000;
                BankAccReconciliationLine."Sorting Order" := BankAccReconciliationLine."Match Confidence".AsInteger() * ScoreRange;

                // Update sorting for same match confidence based onother criteria
                Rec.GetAppliedPmtData(AppliedPaymentEntry2, RemainingAmountAfterPosting, AmountDifference, PmtAppliedToTxt);

                ScoreRange := ScoreRange / 10;
                if AmountDifference <> 0 then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                ScoreRange := ScoreRange / 10;
                if Rec.Difference <> 0 then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                ScoreRange := ScoreRange / 10;
                if PaymentMatchingDetails.MergeMessages(Rec) <> '' then
                    BankAccReconciliationLine."Sorting Order" -= ScoreRange;

                BankAccReconciliationLine.Modify();
            until BankAccReconciliationLine.Next() = 0;

            OnUpdateSorting(BankAccReconciliation, SubscriberInvoked);
            if not SubscriberInvoked then
                Rec.SetCurrentKey("Sorting Order");
            Rec.Ascending(IsAscending);

            CurrPage.Update(false);
            Rec.FindFirst();
        end;
    end;

    local procedure InvokePost(OnlyPayments: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconPostYesNo: Codeunit "Bank Acc. Recon. Post (Yes/No)";
    begin
        BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
        BankAccReconciliation."Post Payments Only" := OnlyPayments;

        OnBeforeInvokePost(BankAccReconciliation);

        if BankAccReconPostYesNo.BankAccReconPostYesNo(BankAccReconciliation) then begin
            Rec.Reset();
            PageClosedByPosting := true;
            CurrPage.Close();
        end;
    end;

    local procedure UpdateBalanceAfterPostingStyleExpr()
    begin
        if BankAccReconciliation."Statement Ending Balance" = 0 then begin
            BalanceAfterPostingStyleExpr := 'Standard';
            exit;
        end;

        if BankAccReconciliation."Total Balance on Bank Account" + BankAccReconciliation."Total Unposted Applied Amount" + AppliedBankAmounts <> BankAccReconciliation."Statement Ending Balance" then
            BalanceAfterPostingStyleExpr := 'Unfavorable'
        else
            BalanceAfterPostingStyleExpr := 'Favorable';
    end;

    local procedure TestIfFiltershaveBeenRemovedWithRefreshAndClose()
    begin
        Rec.FilterGroup := 2;
        if not PageClosedByPosting then
            if Rec.GetFilter("Bank Account No.") + Rec.GetFilter("Statement Type") + Rec.GetFilter("Statement No.") = '' then begin
                Message(PageMustCloseMsg);
                CurrPage.Close();
            end;
        Rec.FilterGroup := 0;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAtActionApplyAutomatically(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var SubscriberInvoked: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnUpdateSorting(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var SubscriberInvoked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterImportBankTransactions(var SubscriberInvoked: Boolean; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvokePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountNoOnBeforeTransferRemainingAmountToAccount(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;
}

