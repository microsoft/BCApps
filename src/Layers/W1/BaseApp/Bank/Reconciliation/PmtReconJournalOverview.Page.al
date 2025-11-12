// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Telemetry;

page 1291 "Pmt. Recon. Journal Overview"
{
    Caption = 'Payment Reconciliation Journal Overview';
    DataCaptionExpression = Rec."Bank Account No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableView = where("Statement Type" = const("Payment Application"));

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
                    Visible = false;
                }
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the bank account or check ledger entry on the reconciliation line when the Suggest Lines function is used.';
                }
                field("Transaction Text"; Rec."Transaction Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that the customer or vendor entered on that payment transaction that is represented by the journal line.';
                    Width = 40;
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Amount';
                    ToolTip = 'Specifies the amount of the transaction on the bank''s statement shown on this reconciliation line.';
                }
                field(AccountName; Rec.GetAppliedToName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied to Account';
                    Editable = false;
                    ToolTip = 'Specifies the account that the payment is applied to.';

                    trigger OnDrillDown()
                    begin
                        Rec.AppliedToDrillDown();
                    end;
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction on the reconciliation line that has been applied to a bank account or check ledger entry.';
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
                    ToolTip = 'Specifies the difference between the value in the Statement Amount in the Payment Reconciliation Journal field and the value in the Remaining Amount After Posting field in the Payment Application window.';
                    Visible = false;
                }
                field(DescAppliedEntry; AppliedPmtEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Entry Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry that the payment is applied to.';
                }
                field("Applied Entries"; Rec."Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the transaction on the bank''s statement has been applied to one or more bank account or check ledger entries.';
                    Visible = false;
                }
                field(RemainingAmount; RemainingAmountAfterPosting)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Remaining Amount After Posting';
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be paid for the open entry, after you have posted the payment in the Payment Reconciliation Journal window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
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
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Review', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Details', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Custom Sorting', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(ShowNonAppliedLines_Promoted; ShowNonAppliedLines)
                {
                }
                actionref(ShowAllLines_Promoted; ShowAllLines)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not IsBankAccReconInitialized then begin
            BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
            IsBankAccReconInitialized := true;
        end;

        BankAccReconciliation.CalcFields("Total Balance on Bank Account", "Total Unposted Applied Amount", "Total Transaction Amount");
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.GetAppliedPmtData(AppliedPmtEntry, RemainingAmountAfterPosting, StatementToRemAmtDifference, PmtAppliedToTxt);
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KMB', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KMC', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::"Set up");
        Rec.SetFilter(Difference, '<>0');
    end;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        AppliedPmtEntry: Record "Applied Payment Entry";
        PmtAppliedToTxt: Label 'The payment has been applied to (%1) entries.', Comment = '%1 - an integer number';
        IsBankAccReconInitialized: Boolean;
        StatementToRemAmtDifference: Decimal;
        RemainingAmountAfterPosting: Decimal;
}

