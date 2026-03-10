// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Displays outstanding bank transactions that require reconciliation.
/// Shows unmatched bank entries and provides interface for manual matching.
/// </summary>
page 1284 "Outstanding Bank Transactions"
{
    Caption = 'Outstanding Bank Transactions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Outstanding Bank Transaction";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = DocumentNoIndent;
                IndentationControls = "External Document No.";
                ShowAsTree = true;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Applied; Rec.Applied)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Indentation; Rec.Indentation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level of indentation for the transaction. Indented transactions usually indicate deposits.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number for this transaction.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoIndent := Rec.Indentation;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    var
        OutstandingBankTrxTxt: Label 'Outstanding Bank Transactions';
        OutstandingPaymentTrxTxt: Label 'Outstanding Payment Transactions';
        DocumentNoIndent: Integer;

    procedure SetRecords(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary)
    begin
        Rec.Copy(TempOutstandingBankTransaction, true);
    end;

    procedure SetPageCaption(TransactionType: Option)
    begin
        if TransactionType = Rec.Type::"Bank Account Ledger Entry" then
            CurrPage.Caption(OutstandingBankTrxTxt)
        else
            CurrPage.Caption(OutstandingPaymentTrxTxt);
    end;
}

