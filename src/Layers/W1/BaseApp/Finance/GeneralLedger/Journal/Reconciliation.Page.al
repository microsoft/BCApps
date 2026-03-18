// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Provides reconciliation analysis for G/L accounts affected by journal entries before posting.
/// Shows account balances, net changes from journal entries, and projected balances for verification purposes.
/// </summary>
/// <remarks>
/// Account reconciliation and balance verification page for journal posting preview. Displays current balances,
/// pending changes from journal entries, and resulting projected balances to assist with posting validation.
/// Key features: Balance verification, net change analysis, posting impact preview, account reconciliation support.
/// Integration: Used from journal pages for reconciliation analysis and balance verification before posting.
/// </remarks>
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
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Net Change in Jnl."; Rec."Net Change in Jnl.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Balance after Posting"; Rec."Balance after Posting")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance after Posting';
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

    /// <summary>
    /// Sets the general journal line context for reconciliation processing.
    /// Initializes reconciliation data based on the provided journal line and creates net change records for reconciliation accounts.
    /// </summary>
    /// <param name="NewGenJnlLine">The general journal line to use as context for reconciliation calculations.</param>
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

    /// <summary>
    /// Inserts G/L account net change record for reconciliation processing.
    /// Creates a new reconciliation record based on the current G/L account with balance information.
    /// </summary>
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

    /// <summary>
    /// Returns G/L Account net change records from the reconciliation page back to the calling process.
    /// Copies reconciliation data modifications back to the provided GLAccountNetChange record.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account Net Change record to populate with reconciliation results.</param>
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

    /// <summary>
    /// Integration event that occurs after setting the general journal line context for reconciliation.
    /// Allows customization of reconciliation data initialization and G/L Account net change processing.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account net change record being initialized.</param>
    /// <param name="GenJnlLine">The general journal line providing context for reconciliation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLine(var GLAccountNetChange: Record "G/L Account Net Change"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event that occurs after inserting a G/L Account net change record for reconciliation.
    /// Allows additional processing after creating reconciliation records from G/L Account data.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account net change record that was inserted.</param>
    /// <param name="GLAccount">The source G/L Account used to create the net change record.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGLAccNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Integration event that occurs before creating a G/L Account net change record from G/L Account data.
    /// Allows customization of reconciliation record initialization before insertion.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account net change record being prepared for insertion.</param>
    /// <param name="GLAccount">The source G/L Account providing data for the net change record.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeGLAccountNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GLAccount: Record "G/L Account")
    begin
    end;

    /// <summary>
    /// Integration event that occurs before saving net change amounts during reconciliation processing.
    /// Allows custom handling of net change calculation and validation before record modification.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account net change record being updated.</param>
    /// <param name="GenJnlLine">The journal line contributing to the net change.</param>
    /// <param name="AccType">Integer representing the account type (deprecated, use enum version).</param>
    /// <param name="AccNo">Account number being processed for net change.</param>
    /// <param name="NetChange">Net change amount being applied to the reconciliation record.</param>
    /// <param name="IsHandled">Set to true to skip standard net change saving processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNetChange(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Integer; AccNo: Code[20]; var NetChange: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that occurs before modifying G/L Account net change records during net change saving.
    /// Allows customization of reconciliation record updates before final modification.
    /// </summary>
    /// <param name="GLAccountNetChange">The G/L Account net change record being modified.</param>
    /// <param name="GenJnlLine">The journal line providing net change data.</param>
    /// <param name="AccType">Account type enum indicating the type of account being processed.</param>
    /// <param name="AccNo">Account number being processed for net change updates.</param>
    /// <param name="NetChange">Net change amount being applied to the record.</param>
    [IntegrationEvent(true, false)]
    local procedure OnSaveNetChangeOnBeforeModify(var GLAccountNetChange: Record "G/L Account Net Change"; GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; NetChange: Decimal)
    begin
    end;

    /// <summary>
    /// Integration event that occurs after setting account number during net change saving operations.
    /// Allows custom processing after account number assignment for bank account reconciliation.
    /// </summary>
    /// <param name="GenJournalLine">The journal line being processed for account number assignment.</param>
    /// <param name="BankAccountPostingGroup">Bank account posting group related to the account number.</param>
    /// <param name="AccNo">Account number that was set during the operation.</param>
    [IntegrationEvent(true, false)]
    local procedure OnSaveNetChangeOnAfterSetAccNo(var GenJournalLine: Record "Gen. Journal Line"; var BankAccountPostingGroup: Record "Bank Account Posting Group"; AccNo: Code[20])
    begin
    end;
}

