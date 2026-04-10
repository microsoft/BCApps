// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Handles the posting phase of reversal operations by creating correcting ledger entries.
/// Integrates with the posting engine to create offsetting transactions and manages G/L register creation.
/// </summary>
/// <remarks>
/// Extensibility: Integration events for custom posting logic and G/L register printing customization.
/// Dependencies: Gen. Jnl.-Post Batch codeunit, G/L Register management, and Deferral posting integration.
/// </remarks>
codeunit 179 "Reversal-Post"
{
    TableNo = "Reversal Entry";

    trigger OnRun()
    var
        GLReg: Record "G/L Register";
        GenJnlTemplate: Record "Gen. Journal Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
        GenJnlPostReverse: Codeunit "Gen. Jnl.-Post Reverse";
        Txt: Text[1024];
        WarningText: Text[250];
        Number: Integer;
        Handled: Boolean;
    begin
        OnBeforeOnRun(Rec);
        Rec.Reset();
        Rec.SetRange("Entry Type", Rec."Entry Type"::"Fixed Asset");
        if Rec.FindFirst() then
            WarningText := Text007;
        Rec.SetRange("Entry Type");
        if PrintRegister then
            Txt := Text004 + WarningText + '\' + Text005
        else
            Txt := Text004 + WarningText + '\' + Text002;

        OnRunOnAfterCreateTxt(PrintRegister, Txt, WarningText);

        if not Rec.FindFirst() then
            Error(Text006);

        if not HideDialog then
            if not Confirm(Txt, false) then
                exit;

        Handled := false;
        OnRunOnAfterConfirm(Rec, Handled, PrintRegister, HideDialog);
        if Handled then
            exit;

        ReversalEntry := Rec;
        if Rec."Reversal Type" = Rec."Reversal Type"::Transaction then
            ReversalEntry.SetReverseFilter(Rec."Transaction No.", Rec."Reversal Type")
        else
            ReversalEntry.SetReverseFilter(Rec."G/L Register No.", Rec."Reversal Type");
        OnRunOnBeforeCheckEntries(Rec);
        ReversalEntry.CheckEntries();
        Rec.Get(1);
        if Rec."Reversal Type" = Rec."Reversal Type"::Register then
            Number := Rec."G/L Register No."
        else
            Number := Rec."Transaction No.";
        if not ReversalEntry.VerifyReversalEntries(Rec, Number, Rec."Reversal Type") then
            Error(Text008);
        GenJnlPostReverse.Reverse(ReversalEntry, Rec);
        if PrintRegister then begin
            GenJnlTemplate.Validate(Type);
            if GenJnlTemplate."Posting Report ID" <> 0 then
                if GLReg.FindLast() then begin
                    GLReg.SetRecFilter();
                    OnBeforeGLRegPostingReportPrint(GenJnlTemplate."Posting Report ID", false, false, GLReg, Handled);
                    if not Handled then
                        REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
                end;
        end;
        OnRunOnBeforeDeleteAll(Rec, Number);
        Rec.DeleteAll();
        PostedDeferralHeader.DeleteForDoc("Deferral Document Type"::"G/L".AsInteger(), ReversalEntry."Document No.", '', 0, '');
        if not HideDialog then
            Message(Text003);
    end;

    var
        ReversalEntry: Record "Reversal Entry";
        PrintRegister: Boolean;
        HideDialog: Boolean;

#pragma warning disable AA0074
        Text002: Label 'Do you want to reverse the entries?';
        Text003: Label 'The entries were successfully reversed.';
        Text004: Label 'To reverse these entries, correcting entries will be posted.';
        Text005: Label 'Do you want to reverse the entries and print the report?';
        Text006: Label 'There is nothing to reverse.';
        Text007: Label '\There are one or more FA Ledger Entries. You should consider using the fixed asset function Cancel Entries.';
        Text008: Label 'Changes have been made to posted entries after the window was opened.\Close and reopen the window to continue.';
#pragma warning restore AA0074

    /// <summary>
    /// Sets whether to print the G/L register after posting reversal entries.
    /// </summary>
    /// <param name="NewPrintRegister">True to print G/L register after posting, false otherwise</param>
    procedure SetPrint(NewPrintRegister: Boolean)
    begin
        PrintRegister := NewPrintRegister;
    end;

    /// <summary>
    /// Sets whether to hide confirmation dialogs during reversal posting.
    /// </summary>
    /// <param name="NewHideDialog">True to hide dialogs, false to show confirmation prompts</param>
    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    /// <summary>
    /// Integration event raised before printing the G/L register posting report, allowing customization of report settings.
    /// </summary>
    /// <param name="ReportID">Report ID that can be modified by subscribers</param>
    /// <param name="ReqWindow">Whether to show the report request window</param>
    /// <param name="SystemPrinter">Whether to use the system printer</param>
    /// <param name="GLRegister">G/L register record being printed</param>
    /// <param name="Handled">Set to true to skip standard report printing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLRegPostingReportPrint(var ReportID: Integer; ReqWindow: Boolean; SystemPrinter: Boolean; var GLRegister: Record "G/L Register"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the reversal posting process, allowing preprocessing of reversal entries.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record being processed</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before deleting reversal entries after successful posting.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record being deleted</param>
    /// <param name="Number">Transaction or register number being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeDeleteAll(var ReversalEntry: Record "Reversal Entry"; Number: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after user confirmation, allowing custom handling of the reversal process.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record being processed</param>
    /// <param name="Handled">Set to true to skip standard processing</param>
    /// <param name="PrintRegister">Whether to print G/L register after posting</param>
    /// <param name="HideDialog">Whether dialogs are hidden during processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterConfirm(var ReversalEntry: Record "Reversal Entry"; var Handled: Boolean; PrintRegister: Boolean; HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after creating confirmation text, allowing customization of user messages.
    /// </summary>
    /// <param name="PrintRegister">Whether G/L register will be printed</param>
    /// <param name="Txt">Confirmation message text that can be modified</param>
    /// <param name="WarningText">Warning message text</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCreateTxt(PrintRegister: Boolean; var Txt: Text[1024]; WarningText: Text[250])
    begin
    end;

    /// <summary>
    /// Integration event raised before validating reversal entries, allowing custom pre-validation logic.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record being validated</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckEntries(var ReversalEntry: Record "Reversal Entry")
    begin
    end;
}

