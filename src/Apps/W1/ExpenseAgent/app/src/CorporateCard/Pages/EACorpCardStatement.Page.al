// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7444 "EA Corp Card Statement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Statement';
    PageType = Document;
    SourceTable = "EA Corp Card Statement";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the corporate card provider that issued the statement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the statement identifier assigned by the provider.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the date of the provider statement.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the first transaction date covered by the statement.';
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the last transaction date covered by the statement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the currency of the provider statement.';
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the total amount reported by the provider.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the provider statement is open or validated.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';

                field("Transaction Total"; Rec."Transaction Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the statement lines.';
                }
                field("Matched Transactions"; Rec."Matched Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of statement lines linked to imported corporate card transactions.';
                }
                field("Imported Transactions"; Rec."Imported Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total number of statement lines.';
                }
                field("Settlement Entry No."; Rec."Settlement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement that includes this statement.';
                }
                field(SettlementStatus; SettlementStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Settlement Status';
                    ToolTip = 'Specifies the current status of the settlement that includes this statement.';
                }
                field(ReconciledTransactions; ReconciledTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconciled Transactions';
                    ToolTip = 'Specifies the number of statement transactions matched to valid corporate card bank account ledger entries.';
                }
                field(UnreconciledTransactions; UnreconciledTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unreconciled Transactions';
                    ToolTip = 'Specifies the number of statement transactions without a valid corporate card bank account ledger entry.';
                }
                field(ReconciledAmount; ReconciledAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = "Currency Code";
                    Caption = 'Reconciled Amount';
                    ToolTip = 'Specifies the amount represented by reconciled statement transactions.';
                }
                field(UnreconciledAmount; UnreconciledAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = "Currency Code";
                    Caption = 'Unreconciled Amount';
                    ToolTip = 'Specifies the amount represented by unreconciled statement transactions.';
                }
            }
            group(Reconciliation)
            {
                Caption = 'Reconciliation';

                field("Closed At"; Rec."Closed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation of the statement was closed.';
                }
                field("Closed By User ID"; Rec."Closed By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who closed reconciliation of the statement.';
                }
                field("Previous Closed At"; Rec."Previous Closed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the previous reconciliation closure occurred.';
                }
                field("Previous Closed By User ID"; Rec."Previous Closed By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who completed the previous reconciliation closure.';
                }
                field("Prev. Reconciled Transactions"; Rec."Prev. Reconciled Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reconciled transaction count captured before invalidation.';
                }
                field("Prev. Reconciled Amount"; Rec."Prev. Reconciled Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reconciled amount captured before invalidation.';
                }
                field("Reconciliation Invalidated At"; Rec."Reconciliation Invalidated At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation was invalidated.';
                }
                field("Reconciliation Invalidated By"; Rec."Reconciliation Invalidated By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who invalidated reconciliation.';
                }
                field("Recon. Invalidation Reason"; Rec."Recon. Invalidation Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies why reconciliation must be performed again.';
                }
            }
            part(Transactions; "EA Corp Card Statement Trans")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Statement Entry No." = field("Statement Entry No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateStatement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Validate Statement';
                Enabled = Rec.Status = Rec.Status::Imported;
                Image = Approve;
                ToolTip = 'Validates import completeness, statement identity, dates, currency, total, and expense matching.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    CorpCardStatementMgt.ValidateStatement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reopen)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reopen';
                Enabled = CanCloseReconciliation;
                Image = ReOpen;
                ToolTip = 'Reopens the validated statement so that it can be corrected.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    CorpCardStatementMgt.ReopenStatement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenSettlement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Settlement';
                Image = Payment;
                ToolTip = 'Opens the settlement that includes this statement.';

                trigger OnAction()
                var
                    CorpCardSettlement: Record "EA Corp Card Settlement";
                begin
                    Rec.CalcFields("Settlement Entry No.");
                    if Rec."Settlement Entry No." = 0 then
                        Error(NoSettlementErr);

                    CorpCardSettlement.Get(Rec."Settlement Entry No.");
                    Page.RunModal(Page::"EA Corp Card Settlement", CorpCardSettlement);
                end;
            }
            action(CloseReconciliation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close Reconciliation';
                Enabled = Rec.Status = Rec.Status::Validated;
                Image = ClosePeriod;
                ToolTip = 'Verifies every statement transaction and the posted settlement entries, then closes the statement period.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    if not Confirm(CloseReconciliationQst, false, Rec."Statement No.") then
                        exit;

                    CorpCardStatementMgt.CloseStatement(Rec);
                    UpdateReconciliationSummary();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Validation)
                {
                    Caption = 'Validation';
                    ShowAs = SplitButton;

                    actionref(ValidateStatement_Promoted; ValidateStatement)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref(CloseReconciliation_Promoted; CloseReconciliation)
                {
                }
            }
            group(Category_Statement)
            {
                Caption = 'Statement';

                actionref(OpenSettlement_Promoted; OpenSettlement)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateReconciliationSummary();
    end;

    local procedure UpdateReconciliationSummary()
    var
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        SettlementStatus2: Enum "EA Corp Card Settle Status";
    begin
        CorpCardStatementMgt.GetReconciliationSummary(
            Rec, ReconciledTransactions, ReconciledAmount,
            UnreconciledTransactions, UnreconciledAmount, SettlementStatus2);
        CanCloseReconciliation := Rec.Status in [Rec.Status::Validated, Rec.Status::ReconciliationRequired];
        Rec.CalcFields("Settlement Entry No.");
        if Rec."Settlement Entry No." = 0 then
            SettlementStatusText := ''
        else
            SettlementStatusText := Format(SettlementStatus2);
    end;

    var
        CloseReconciliationQst: Label 'Do you want to close reconciliation for corporate card statement %1?', Comment = '%1 = statement number';
        CanCloseReconciliation: Boolean;
        NoSettlementErr: Label 'The statement is not included in a settlement.';
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        ReconciledTransactions: Integer;
        UnreconciledTransactions: Integer;
        SettlementStatusText: Text[30];
}
