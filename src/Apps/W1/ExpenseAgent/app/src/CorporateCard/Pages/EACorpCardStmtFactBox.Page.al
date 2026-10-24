// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7429 "EA Corp Card Stmt. FactBox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statement Reconciliation';
    Editable = false;
    PageType = CardPart;
    SourceTable = "EA Corp Card Statement";

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
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
                    AutoFormatExpression = Rec."Currency Code";
                    Caption = 'Reconciled Amount';
                    ToolTip = 'Specifies the amount represented by reconciled statement transactions.';
                }
                field(UnreconciledAmount; UnreconciledAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                    Caption = 'Unreconciled Amount';
                    ToolTip = 'Specifies the amount represented by unreconciled statement transactions.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        SettlementStatus: Enum "EA Corp Card Settle Status";
    begin
        Clear(ReconciledTransactions);
        Clear(ReconciledAmount);
        Clear(UnreconciledTransactions);
        Clear(UnreconciledAmount);
        Clear(SettlementStatusText);
        if Rec."Statement Entry No." = 0 then
            exit;

        CorpCardStatementMgt.GetReconciliationSummary(
            Rec, ReconciledTransactions, ReconciledAmount,
            UnreconciledTransactions, UnreconciledAmount, SettlementStatus);
        Rec.CalcFields("Settlement Entry No.");
        if Rec."Settlement Entry No." <> 0 then
            SettlementStatusText := Format(SettlementStatus);
    end;

    var
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        ReconciledTransactions: Integer;
        UnreconciledTransactions: Integer;
        SettlementStatusText: Text[30];
}
