// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;

/// <summary>
/// Manages reconciliation number assignment for check ledger entries.
/// Links check entries to bank reconciliation statements during processing.
/// </summary>
codeunit 376 "Check Entry Set Recon.-No."
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        BLEMissmatchErr: Label 'Bank Ledger Entry has %1 %2, but Bank Reconciliation Line has %3.', Comment = '%1 - Either "Statement No." or "Statement Line No.", %2 - A number, %3 - a number';
#pragma warning disable AA0470
        CannotBeErr: Label 'cannot be %1';
#pragma warning restore AA0470

    /// <summary>
    /// Toggles reconciliation number assignment for a check ledger entry.
    /// Links or unlinks the check entry from the bank reconciliation line.
    /// </summary>
    /// <param name="CheckLedgEntry">The check ledger entry to process.</param>
    /// <param name="BankAccReconLine">The bank reconciliation line to link to.</param>
    /// <param name="ChangeAmount">Whether to adjust the statement amount based on the applied amount.</param>
    procedure ToggleReconNo(var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; ChangeAmount: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeToggleReconNo(CheckLedgEntry, BankAccReconLine, ChangeAmount, IsHandled);
        if IsHandled then
            exit;

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();
        BankAccReconLine.Find();
        if CheckLedgEntry."Statement No." = '' then begin
            SetReconNo(CheckLedgEntry, BankAccReconLine);
            BankAccReconLine."Applied Amount" := BankAccReconLine."Applied Amount" - CheckLedgEntry.Amount;
            BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
        end else begin
            RemoveReconNo(CheckLedgEntry, BankAccReconLine, true);
            BankAccReconLine."Applied Amount" := BankAccReconLine."Applied Amount" + CheckLedgEntry.Amount;
            BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
        end;
        if BankAccReconLine."Applied Entries" = 1 then
            BankAccReconLine."Check No." := CheckLedgEntry."Check No."
        else
            BankAccReconLine."Check No." := '';
        if ChangeAmount then
            BankAccReconLine.Validate("Statement Amount", BankAccReconLine."Applied Amount")
        else
            BankAccReconLine.Validate("Statement Amount");
        BankAccReconLine.Modify();
    end;

    /// <summary>
    /// Assigns a reconciliation number to a check ledger entry.
    /// Creates the connection between the check and bank reconciliation line.
    /// </summary>
    /// <param name="CheckLedgEntry">The check ledger entry to set reconciliation number for.</param>
    /// <param name="BankAccReconLine">The bank reconciliation line providing the reconciliation details.</param>
    procedure SetReconNo(var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        CheckLedgEntry.TestField(Open, true);
        if (CheckLedgEntry."Statement Status" <> CheckLedgEntry."Statement Status"::Open) and
           (CheckLedgEntry."Statement Status" <>
            CheckLedgEntry."Statement Status"::"Check Entry Applied")
        then
            CheckLedgEntry.FieldError(
              "Statement Status", StrSubstNo(CannotBeErr, CheckLedgEntry."Statement Status"));
        CheckLedgEntry.TestField("Statement No.", '');
        CheckLedgEntry.TestField("Statement Line No.", 0);
        if not (CheckLedgEntry."Entry Status" in
                [CheckLedgEntry."Entry Status"::Posted, CheckLedgEntry."Entry Status"::"Financially Voided"])
        then
            CheckLedgEntry.FieldError(
              "Entry Status", StrSubstNo(CannotBeErr, CheckLedgEntry."Entry Status"));
        CheckLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::"Check Entry Applied";
        CheckLedgEntry."Statement No." := BankAccReconLine."Statement No.";
        CheckLedgEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        CheckLedgEntry.Modify();

        BankAccLedgEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        BankAccLedgEntry.TestField(Open, true);
        if (BankAccLedgEntry."Statement Status" <> BankAccLedgEntry."Statement Status"::Open) and
           (BankAccLedgEntry."Statement Status" <>
            BankAccLedgEntry."Statement Status"::"Check Entry Applied")
        then
            BankAccLedgEntry.FieldError(
              "Statement Status", StrSubstNo(CannotBeErr, BankAccLedgEntry."Statement Status"));
        BankAccLedgEntry.TestField("Statement No.", '');
        BankAccLedgEntry.TestField("Statement Line No.", 0);
        BankAccLedgEntry."Statement Status" :=
          BankAccLedgEntry."Statement Status"::"Check Entry Applied";
        BankAccLedgEntry."Statement No." := BankAccReconLine."Statement No.";
        BankAccLedgEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        BankAccLedgEntry.Modify();
    end;

    /// <summary>
    /// Removes reconciliation number from a check ledger entry.
    /// Disconnects the check entry from the bank reconciliation line.
    /// </summary>
    /// <param name="CheckLedgEntry">The check ledger entry to remove reconciliation number from.</param>
    /// <param name="BankAccReconLine">The bank reconciliation line to disconnect from.</param>
    /// <param name="Test">Whether to validate removal conditions.</param>
    procedure RemoveReconNo(var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; Test: Boolean)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry.TestField(Open, true);
        if Test then begin
            CheckLedgEntry.TestField(
              "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
            CheckLedgEntry.TestField("Statement No.", BankAccReconLine."Statement No.");
            CheckLedgEntry.TestField("Statement Line No.", BankAccReconLine."Statement Line No.");
        end;
        CheckLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::Open;
        CheckLedgEntry."Statement No." := '';
        CheckLedgEntry."Statement Line No." := 0;
        CheckLedgEntry.Modify();

        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry2.SetRange(
          "Bank Account Ledger Entry No.", CheckLedgEntry."Bank Account Ledger Entry No.");
        CheckLedgEntry2.SetRange(
          "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
        if CheckLedgEntry2.IsEmpty() then begin
            BankAccLedgEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
            BankAccLedgEntry.TestField(Open, true);
            if Test then begin
                BankAccLedgEntry.TestField(
                  "Statement Status", BankAccLedgEntry."Statement Status"::"Check Entry Applied");
                if BankAccLedgEntry."Statement No." <> BankAccReconLine."Statement No." then
                    if BankAccLedgEntry."Statement No." <> '' then // For Bank Rec's from 20.x and downwards
                        Error(BLEMissmatchErr, BankAccLedgEntry.FieldCaption("Statement No."), BankAccLedgEntry."Statement No.", BankAccReconLine."Statement No.");

                if BankAccLedgEntry."Statement Line No." <> BankAccReconLine."Statement Line No." then
                    if BankAccLedgEntry."Statement Line No." <> 0 then // For Bank Rec's from 20.x and downwards
                        Error(BLEMissmatchErr, BankAccLedgEntry.FieldCaption("Statement Line No."), BankAccLedgEntry."Statement Line No.", BankAccReconLine."Statement Line No.");
            end;
            BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Open;
            BankAccLedgEntry."Statement No." := '';
            BankAccLedgEntry."Statement Line No." := 0;
            BankAccLedgEntry.Modify();
        end;
    end;

    /// <summary>
    /// Removes application from a check ledger entry.
    /// Clears reconciliation references and updates related bank reconciliation line.
    /// </summary>
    /// <param name="CheckLedgerEntry">The check ledger entry to remove application from.</param>
    procedure RemoveApplication(var CheckLedgerEntry: Record "Check Ledger Entry")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        CheckLedgerEntry.LockTable();
        BankAccReconLine.LockTable();

        if not BankAccReconLine.Get(
            BankAccReconLine."Statement Type"::"Bank Reconciliation",
            CheckLedgerEntry."Bank Account No.",
            CheckLedgerEntry."Statement No.", CheckLedgerEntry."Statement Line No.")
        then
            exit;

        BankAccReconLine.TestField("Statement Type", BankAccReconLine."Statement Type"::"Bank Reconciliation");
        RemoveReconNo(CheckLedgerEntry, BankAccReconLine, true);

        BankAccReconLine."Applied Amount" += CheckLedgerEntry.Amount;
        BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
        BankAccReconLine."Check No." := '';
        BankAccReconLine.Validate("Statement Amount");
        BankAccReconLine.Modify();

        DeletePaymentMatchDetails(BankAccReconLine);
    end;

    local procedure DeletePaymentMatchDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        PaymentMatchingDetails.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToggleReconNo(var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ChangeAmount: Boolean; var IsHandled: Boolean)
    begin
    end;

}

