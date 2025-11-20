// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;

page 345 Reconciliation
{
    Caption = 'Reconciliation';
    DataCaptionExpression = Heading;
    Editable = false;
    PageType = List;
    SourceTable = "G/L Account Net Change";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account';
                    ToolTip = 'Specifies the bank account that is being reconciled.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Net Change in Jnl."; Rec."Net Change in Jnl.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net change that will occur on the bank when you post the journal.';
                }
                field("Balance after Posting"; Rec."Balance after Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance after Posting';
                    ToolTip = 'Specifies the current balance on the bank account.';
                }
            }
        }
    }

    actions
    {
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";

    protected var
        Heading: Code[10];

    procedure SetGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.Copy(NewGenJnlLine);
        Heading := GenJnlLine."Journal Batch Name";
        Rec.DeleteAll();
        GLAcc.SetCurrentKey("Reconciliation Account");
        GLAcc.SetRange("Reconciliation Account", true);
        if GLAcc.Find('-') then
            repeat
                InsertGLAccNetChange();
            until GLAcc.Next() = 0;

        if GenJnlLine.Find('-') then
            repeat
                SaveNetChange(
                  GenJnlLine."Account Type", GenJnlLine."Account No.",
                  Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."VAT %" / 100)));
                SaveNetChange(
                  GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.",
                  -Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."Bal. VAT %" / 100)));
            until GenJnlLine.Next() = 0;

        OnAfterSetGenJnlLine(Rec, GenJnlLine);
        if Rec.Find('-') then;
    end;

    local procedure SaveNetChange(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; NetChange: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveNetChange(Rec, GenJnlLine, AccType.AsInteger(), AccNo, NetChange, IsHandled);
        if IsHandled then
            exit;

        if AccNo = '' then
            exit;
        case AccType of
            GenJnlLine."Account Type"::"G/L Account":
                if not Rec.Get(AccNo) then
                    exit;
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    if AccNo <> BankAcc."No." then begin
                        BankAcc.Get(AccNo);
                        BankAcc.TestField("Bank Acc. Posting Group");
                        BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("G/L Account No.");
                    end;
                    AccNo := BankAccPostingGr."G/L Account No.";
                    OnSaveNetChangeOnAfterSetAccNo(GenJnlLine, BankAccPostingGr, AccNo);
                    if not Rec.Get(AccNo) then begin
                        GLAcc.Get(AccNo);
                        InsertGLAccNetChange();
                    end;
                end;
            else
                exit;
        end;

        Rec."Net Change in Jnl." := Rec."Net Change in Jnl." + NetChange;
        Rec."Balance after Posting" := Rec."Balance after Posting" + NetChange;
        OnSaveNetChangeOnBeforeModify(Rec, GenJnlLine, AccType, AccNo, NetChange);
        Rec.Modify();
    end;

    procedure InsertGLAccNetChange()
    begin
        GLAcc.CalcFields("Balance at Date");
        Rec.Init();
        Rec."No." := GLAcc."No.";
        Rec.Name := GLAcc.Name;
        Rec."Balance after Posting" := GLAcc."Balance at Date";
        OnBeforeGLAccountNetChange(Rec, GLAcc);
        Rec.Insert();

        OnAfterInsertGLAccNetChange(Rec, GLAcc);
    end;

    procedure ReturnGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change")
    var
        OldGLAccountNetChange: Record "G/L Account Net Change";
    begin
        OldGLAccountNetChange := Rec;
        Rec.FindSet();
        repeat
            GLAccountNetChange.Init();
            GLAccountNetChange := Rec;
            GLAccountNetChange.Insert();
        until Rec.Next() = 0;

        Rec := OldGLAccountNetChange;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLine(var GLAccountNetChange: Record "G/L Account Net Change"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGLAccNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Integer; AccNo: Code[20]; var NetChange: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSaveNetChangeOnBeforeModify(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; NetChange: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSaveNetChangeOnAfterSetAccNo(var GenJournalLine: Record "Gen. Journal Line"; var BankAccountPostingGroup: Record "Bank Account Posting Group"; AccNo: Code[20])
    begin
    end;
}

