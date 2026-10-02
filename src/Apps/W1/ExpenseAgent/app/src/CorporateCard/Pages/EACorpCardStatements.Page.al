// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7443 "EA Corp Card Statements"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Provider Statements';
    CardPageId = "EA Corp Card Statement";
    Editable = false;
    PageType = List;
    SourceTable = "EA Corp Card Statement";
    SourceTableView = sorting("Statement Date") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Statement Entry No."; Rec."Statement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal entry number of the imported statement.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corporate card provider that issued the statement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement identifier assigned by the provider.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the provider statement.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first transaction date covered by the statement.';
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last transaction date covered by the statement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the provider statement.';
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount reported by the provider.';
                }
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the provider statement is open or validated.';
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
                field("Closed At"; Rec."Closed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation of the statement was closed.';
                }
                field("Reconciliation Invalidated At"; Rec."Reconciliation Invalidated At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation was invalidated.';
                }
                field("Recon. Invalidation Reason"; Rec."Recon. Invalidation Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies why reconciliation must be performed again.';
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
        Rec.CalcFields("Settlement Entry No.");
        if Rec."Settlement Entry No." = 0 then
            SettlementStatusText := ''
        else
            SettlementStatusText := Format(SettlementStatus2);
    end;

    var
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        ReconciledTransactions: Integer;
        UnreconciledTransactions: Integer;
        SettlementStatusText: Text[30];
}
