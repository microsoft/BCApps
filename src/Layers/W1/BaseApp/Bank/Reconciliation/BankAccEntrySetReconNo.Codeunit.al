// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;

/// <summary>
/// Manages the application of bank reconciliation lines to bank account and check ledger entries.
/// Handles the assignment of reconciliation statement numbers to matched entries, supports various
/// matching relationships (one-to-one, one-to-many, many-to-one), and maintains data integrity
/// during the reconciliation process. Validates entry states and manages reconciliation buffers.
/// </summary>
/// <remarks>
/// Core functionality includes entry application with relationship validation, reconciliation
/// number assignment for tracking matched entries, buffer management for complex matching scenarios,
/// and state validation to ensure data consistency. Supports both automatic and manual matching
/// workflows with comprehensive error handling and validation checks.
/// </remarks>
codeunit 375 "Bank Acc. Entry Set Recon.-No."
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        CheckLedgEntry: Record "Check Ledger Entry";
        LineCount: Integer;
        LineNumber: Integer;
        AppliedAmount: Decimal;
        UninitializedLineCountTxt: Label 'Uninitialized line count.', Locked = true;
        UnexpectedLineNumberTxt: Label 'Unexpected line number.', Locked = true;
        CategoryTxt: Label 'Reconciliation', Locked = true;
        CorruptStateOptionsTok: Label 'Yes to all,Yes,No';
        BankAccountLedgerEntryInvalidStateErr: Label 'Cannot apply the statement line to bank account ledger entry %1 because its statement status is %2. Choose another bank account ledger entry.', Comment = '%1 - Ledger entry number; %2 - Statement status, option caption';
        CheckLedgerEntryInvalidStateErr: Label 'Cannot apply the statement line to check ledger entry %1 because its statement status is %2. Choose another check ledger entry.', Comment = '%1 - Ledger entry number; %2 - Statement status, option caption';
        BankAccountLedgerEntryInvalidStateQst: Label 'No statement lines have been applied to bank account ledger entry %1, but its statement status is %2. Do you want to apply the statement line to it?', Comment = '%1 - Ledger entry number; %2 - Statement status, option caption';
        CheckLedgerEntryInvalidStateQst: Label 'No statement lines have been applied to check ledger entry %1, but its statement status is %2. Do you want to apply the statement line to it?', Comment = '%1 - Ledger entry number; %2 - Statement status, option caption';
        CLEMissmatchErr: Label 'Check Ledger Entry has %1 %2, but Bank Reconciliation Line has %3.', Comment = '%1 - Either "Statement No." or "Statement Line No.", %2 - A number, %3 - a number';
        IgnoreCorruptState: Boolean;

    /// <summary>
    /// Applies bank reconciliation lines to bank account ledger entries with the specified relationship type.
    /// Manages the matching process for different reconciliation scenarios including one-to-one, one-to-many,
    /// and many-to-one relationships. Updates applied amounts, reconciliation numbers, and maintains
    /// relationship integrity throughout the application process.
    /// </summary>
    /// <param name="BankAccReconLine">Bank reconciliation line to apply to ledger entries.</param>
    /// <param name="BankAccLedgEntry">Bank account ledger entry to match with the reconciliation line.</param>
    /// <param name="Relation">Type of relationship for the application (One-to-One, One-to-Many, Many-to-One).</param>
    /// <returns>True if the application was successful; false if constraints prevent the application.</returns>
    procedure ApplyEntries(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry"; Relation: Option "One-to-One","One-to-Many","Many-to-One"): Boolean
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        NextMatchID: Integer;
        RemainingAmount: Decimal;
    begin
        OnBeforeApplyEntries(BankAccReconLine, BankAccLedgEntry, Relation);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();
        BankAccReconLine.Find();

        case Relation of
            Relation::"One-to-One":
                begin
                    if BankAccReconLine."Applied Entries" > 0 then
                        exit(false);
                    if BankAccLedgEntry.IsApplied() then
                        exit(false);

                    BankAccReconLine."Ready for Application" := true;
                    SetReconNo(BankAccLedgEntry, BankAccReconLine);
                    BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
            Relation::"One-to-Many":
                begin
                    if BankAccLedgEntry.IsApplied() then
                        exit(false);

                    BankAccReconLine."Ready for Application" := true;
                    SetReconNo(BankAccLedgEntry, BankAccReconLine);
                    BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
            Relation::"Many-to-One":
                begin
                    if (BankAccReconLine."Applied Entries" > 0) then
                        exit(false); //Many-to-many is not supported

                    if LineCount = 0 then begin
                        Session.LogMessage('0000GQE', UninitializedLineCountTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                        exit(false);
                    end;

                    LineNumber += 1;
                    if LineNumber > LineCount then begin
                        Session.LogMessage('0000GQF', UnexpectedLineNumberTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                        exit(false);
                    end;

                    NextMatchID := GetNextMatchID(BankAccReconLine, BankAccLedgEntry);
                    BankAccRecMatchBuffer.Init();
                    BankAccRecMatchBuffer."Ledger Entry No." := BankAccLedgEntry."Entry No.";
                    BankAccRecMatchBuffer."Statement No." := BankAccReconLine."Statement No.";
                    BankAccRecMatchBuffer."Statement Line No." := BankAccReconLine."Statement Line No.";
                    BankAccRecMatchBuffer."Bank Account No." := BankAccReconLine."Bank Account No.";
                    BankAccRecMatchBuffer."Match ID" := NextMatchID;
                    BankAccRecMatchBuffer.Insert();

                    BankAccReconLine."Ready for Application" := true;
                    if BankAccLedgEntry."Statement Line No." <> -1 then begin
                        SetReconNo(BankAccLedgEntry, BankAccReconLine);
                        BankAccLedgEntry."Statement Line No." := -1;
                        BankAccLedgEntry.Modify();
                    end;

                    if LineNumber < LineCount then begin
                        BankAccReconLine."Applied Amount" := BankAccReconLine."Statement Amount";
                        AppliedAmount += BankAccReconLine."Applied Amount";
                    end else begin
                        RemainingAmount := BankAccLedgEntry."Remaining Amount" - AppliedAmount;
                        BankAccReconLine."Applied Amount" := RemainingAmount;
                    end;

                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
        end;

        OnAfterApplyEntries(BankAccReconLine, BankAccLedgEntry, Relation);

        exit(true);
    end;

    /// <summary>
    /// Sets the line count for tracking purposes during the reconciliation process.
    /// Used internally to maintain counters for multi-line reconciliation operations.
    /// </summary>
    /// <param name="NewLineCount">The line count value to set for tracking reconciliation operations.</param>
    procedure SetLineCount(NewLineCount: Integer)
    begin
        LineCount := NewLineCount;
    end;

    /// <summary>
    /// Sets the line number for internal tracking during reconciliation operations.
    /// Used to maintain state information for complex matching scenarios.
    /// </summary>
    /// <param name="NewLineNumber">The line number value to set for tracking purposes.</param>
    internal procedure SetLineNumber(NewLineNumber: Integer)
    begin
        LineNumber := NewLineNumber;
    end;

    /// <summary>
    /// Sets the applied amount for tracking during reconciliation operations.
    /// Maintains running totals of amounts applied in multi-entry matching scenarios.
    /// </summary>
    /// <param name="NewAppliedAmount">The applied amount value to set for tracking purposes.</param>
    internal procedure SetAppliedAmount(NewAppliedAmount: Integer)
    begin
        AppliedAmount := NewAppliedAmount;
    end;

    local procedure GetNextMatchID(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankAccLedgEntry: Record "Bank Account Ledger Entry"): Integer
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconLine."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccLedgEntry."Entry No.");
        if BankAccRecMatchBuffer.FindLast() then
            exit(BankAccRecMatchBuffer."Match ID");

        BankAccRecMatchBuffer.Reset();
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconLine."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccRecMatchBuffer.SetCurrentKey("Match ID");
        BankAccRecMatchBuffer.Ascending(true);

        if BankAccRecMatchBuffer.FindLast() then
            exit(BankAccRecMatchBuffer."Match ID" + 1)
        else
            exit(1);
    end;

    local procedure RemoveManyToOneMatch(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccLedgEntry."Entry No.");
        if BankAccRecMatchBuffer.FindSet() then
            repeat
                BankAccReconLine.SetRange("Statement Line No.", BankAccRecMatchBuffer."Statement Line No.");
                BankAccReconLine.SetRange("Statement No.", BankAccRecMatchBuffer."Statement No.");
                BankAccReconLine.SetRange("Bank Account No.", BankAccRecMatchBuffer."Bank Account No.");
                RemoveReconNo(BankAccLedgEntry, BankAccReconLine, false);
                if BankAccReconLine.FindFirst() then begin
                    BankAccReconLine."Applied Amount" := 0;
                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                    DeletePaymentMatchDetails(BankAccReconLine);
                end
            until BankAccRecMatchBuffer.Next() = 0;

        BankAccRecMatchBuffer.DeleteAll();
    end;

    /// <summary>
    /// Removes applications for bank account ledger entries that participate in many-to-one matching relationships.
    /// Handles the cleanup of multiple bank reconciliation lines that were matched to a single ledger entry,
    /// updating applied amounts, entry counts, and removing associated payment matching details.
    /// </summary>
    /// <param name="BankAccLedgEntry">Bank account ledger entry to remove from many-to-one matches.</param>
    /// <remarks>
    /// This procedure processes all reconciliation lines that reference the specified ledger entry,
    /// removes their reconciliation numbers, updates their applied amounts and entry counts,
    /// and deletes associated matching buffers and payment matching details.
    /// </remarks>
    procedure RemoveApplication(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        OnBeforeRemoveApplication(BankAccLedgEntry);

        RemoveManyToOneMatch(BankAccLedgEntry);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();

        if BankAccReconLine.Get(
             BankAccReconLine."Statement Type"::"Bank Reconciliation",
             BankAccLedgEntry."Bank Account No.",
             BankAccLedgEntry."Statement No.", BankAccLedgEntry."Statement Line No.")
        then begin
            BankAccReconLine.TestField("Statement Type", BankAccReconLine."Statement Type"::"Bank Reconciliation");
            RemoveReconNo(BankAccLedgEntry, BankAccReconLine, true);

            BankAccReconLine."Applied Amount" -= BankAccLedgEntry."Remaining Amount";
            BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
            BankAccReconLine.Validate("Statement Amount");
            ModifyBankAccReconLine(BankAccReconLine);
            DeletePaymentMatchDetails(BankAccReconLine);
        end;

        OnAfterRemoveApplication(BankAccLedgEntry);
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

    local procedure ModifyBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        OnBeforeModifyBankAccReconLine(BankAccReconciliationLine);
        BankAccReconciliationLine.Modify();
    end;

    /// <summary>
    /// Assigns reconciliation statement numbers to bank account and check ledger entries.
    /// Validates entry states, handles corrupt statement statuses, and updates both bank account
    /// and associated check ledger entries with statement information for proper reconciliation tracking.
    /// </summary>
    /// <param name="BankAccLedgEntry">Bank account ledger entry to assign reconciliation number to.</param>
    /// <param name="BankAccReconLine">Bank reconciliation line containing statement information to assign.</param>
    /// <remarks>
    /// Performs comprehensive validation including open status, empty statement fields, and valid bank account.
    /// Handles corrupt statement statuses with user confirmation when GUI is available.
    /// Updates both bank account ledger entries and associated check ledger entries with statement numbers.
    /// </remarks>
    procedure SetReconNo(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        CorruptStateStrMenuSelection: Integer;
    begin
        BankAccLedgEntry.TestField(Open, true);
        BankAccLedgEntry.TestField("Statement No.", '');
        BankAccLedgEntry.TestField("Statement Line No.", 0);
        BankAccLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        if BankAccLedgEntry."Statement Status" = BankAccLedgEntry."Statement Status"::Closed then
            Error(BankAccountLedgerEntryInvalidStateErr, BankAccLedgEntry."Entry No.", Format(BankAccLedgEntry."Statement Status"));
        // this confirm is introduced because there can be ledger entries whose statement status is corrupt because of a bug with undo bank account statement
        if BankAccLedgEntry."Statement Status" <> BankAccLedgEntry."Statement Status"::Open then begin
            if not GuiAllowed then
                Error(BankAccountLedgerEntryInvalidStateErr, BankAccLedgEntry."Entry No.", Format(BankAccLedgEntry."Statement Status"));
            if not IgnoreCorruptState then begin
                CorruptStateStrMenuSelection := Dialog.StrMenu(CorruptStateOptionsTok, 1, StrSubstNo(BankAccountLedgerEntryInvalidStateQst, BankAccLedgEntry."Entry No.", Format(BankAccLedgEntry."Statement Status")));
                if CorruptStateStrMenuSelection = 3 then
                    Error('');
                IgnoreCorruptState := (CorruptStateStrMenuSelection = 1);
            end;
        end;
        BankAccLedgEntry."Statement Status" :=
          BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied";
        BankAccLedgEntry."Statement No." := BankAccReconLine."Statement No.";
        BankAccLedgEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        BankAccLedgEntry.Modify();

        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if CheckLedgEntry.Find('-') then
            repeat
                CheckLedgEntry.TestField("Statement No.", '');
                CheckLedgEntry.TestField("Statement Line No.", 0);
                if CheckLedgEntry."Statement Status" = CheckLedgEntry."Statement Status"::Closed then
                    Error(CheckLedgerEntryInvalidStateErr, CheckLedgEntry."Entry No.", Format(CheckLedgEntry."Statement Status"));
                // this confirm is introduced because there can be ledger entries whose statement status is corrupt because of a bug with undo bank account statement
                if CheckLedgEntry."Statement Status" <> CheckLedgEntry."Statement Status"::Open then begin
                    if not GuiAllowed then
                        Error(CheckLedgerEntryInvalidStateErr, CheckLedgEntry."Entry No.", Format(CheckLedgEntry."Statement Status"));
                    if not IgnoreCorruptState then begin
                        CorruptStateStrMenuSelection := Dialog.StrMenu(CorruptStateOptionsTok, 1, StrSubstNo(CheckLedgerEntryInvalidStateQst, CheckLedgEntry."Entry No.", Format(CheckLedgEntry."Statement Status")));
                        if CorruptStateStrMenuSelection = 3 then
                            Error('');
                        IgnoreCorruptState := (CorruptStateStrMenuSelection = 1);
                    end;
                end;
                CheckLedgEntry."Statement Status" :=
                  CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied";
                CheckLedgEntry."Statement No." := BankAccReconLine."Statement No.";
                CheckLedgEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
                CheckLedgEntry.Modify();
            until CheckLedgEntry.Next() = 0;

        OnAfterSetReconNo(BankAccLedgEntry);
    end;

    /// <summary>
    /// Removes reconciliation statement numbers from bank account and check ledger entries.
    /// Clears statement status, statement numbers, and line numbers from both bank account
    /// and associated check ledger entries to revert them to an open, unreconciled state.
    /// </summary>
    /// <param name="BankAccLedgEntry">Bank account ledger entry to remove reconciliation number from.</param>
    /// <param name="BankAccReconLine">Bank reconciliation line containing statement information for validation.</param>
    /// <param name="Test">Whether to perform validation tests on statement numbers and line numbers.</param>
    /// <remarks>
    /// When Test is true, validates that entry statement numbers and line numbers match the reconciliation line.
    /// Handles backward compatibility for reconciliations from version 20.x and earlier.
    /// Updates both bank account and check ledger entries to reset their reconciliation state.
    /// </remarks>
    procedure RemoveReconNo(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; Test: Boolean)
    begin
        BankAccLedgEntry.TestField(Open, true);
        if Test then begin
            BankAccLedgEntry.TestField("Statement No.", BankAccReconLine."Statement No.");
            BankAccLedgEntry.TestField("Statement Line No.", BankAccReconLine."Statement Line No.");
            BankAccLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        end;

        BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Open;
        BankAccLedgEntry."Statement No." := '';
        BankAccLedgEntry."Statement Line No." := 0;
        BankAccLedgEntry.Modify();

        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if CheckLedgEntry.Find('-') then
            repeat
                if Test then begin
                    if CheckLedgEntry."Statement No." <> BankAccReconLine."Statement No." then
                        if CheckLedgEntry."Statement No." <> '' then // For Bank Rec's from 20.x and downwards
                            Error(CLEMissmatchErr, CheckLedgEntry.FieldCaption("Statement No."), CheckLedgEntry."Statement No.", BankAccReconLine."Statement No.");

                    if CheckLedgEntry."Statement Line No." <> BankAccReconLine."Statement Line No." then
                        if CheckLedgEntry."Statement Line No." <> 0 then // For Bank Rec's from 20.x and downwards
                            Error(CLEMissmatchErr, CheckLedgEntry.FieldCaption("Statement Line No."), CheckLedgEntry."Statement Line No.", BankAccReconLine."Statement Line No.");
                end;
                CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::Open;
                CheckLedgEntry."Statement No." := '';
                CheckLedgEntry."Statement Line No." := 0;
                CheckLedgEntry.Modify();
            until CheckLedgEntry.Next() = 0;

        OnAfterRemoveReconNo(BankAccLedgEntry, Test);
    end;

    /// <summary>
    /// Integration event raised before applying bank reconciliation entries to ledger entries.
    /// Allows subscribers to perform custom validation or modifications before the application process begins.
    /// </summary>
    /// <param name="BankAccReconciliationLine">Bank reconciliation line being applied.</param>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry being matched.</param>
    /// <param name="Relation">Type of relationship for the application (One-to-One, One-to-Many).</param>
    /// <summary>
    /// Event raised before applying bank reconciliation entries to ledger entries.
    /// </summary>
    /// <param name="BankAccReconciliationLine">The bank reconciliation line being applied.</param>
    /// <param name="BankAccountLedgerEntry">The bank account ledger entry being matched.</param>
    /// <param name="Relation">The type of relationship being applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var Relation: Option "One-to-One","One-to-Many")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully applying bank reconciliation entries to ledger entries.
    /// Allows subscribers to perform post-application processing, logging, or additional updates.
    /// </summary>
    /// <param name="BankAccReconciliationLine">Bank reconciliation line that was applied.</param>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry that was matched.</param>
    /// <param name="Relation">Type of relationship that was applied (One-to-One, One-to-Many).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var Relation: Option "One-to-One","One-to-Many")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying a bank reconciliation line.
    /// Allows subscribers to perform custom validation or field updates before the line is saved.
    /// </summary>
    /// <param name="BankAccReconciliationLine">Bank reconciliation line about to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before removing an application from a bank account ledger entry.
    /// Allows subscribers to perform custom validation or pre-processing before application removal.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry from which application will be removed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveApplication(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully removing an application from a bank account ledger entry.
    /// Allows subscribers to perform post-removal processing, cleanup, or additional updates.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry from which application was removed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRemoveApplication(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully setting a reconciliation number on a bank account ledger entry.
    /// Allows subscribers to perform post-assignment processing, notifications, or additional updates.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry that received the reconciliation number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReconNo(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully removing a reconciliation number from a bank account ledger entry.
    /// Allows subscribers to perform post-removal processing, auditing, or cleanup operations.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry from which reconciliation number was removed.</param>
    /// <param name="Test">Whether validation tests were performed during the removal process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRemoveReconNo(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; Test: Boolean)
    begin
    end;
}

