// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.GLAccount;
using System.Utilities;

/// <summary>
/// Handles Intercompany G/L account indentation and hierarchy management.
/// </summary>
codeunit 8432 "IC G/L Account-Indent"
{
    var
        GLAcc: Record "G/L Account";
#if not CLEAN30
        GLAccountIndent: Codeunit "G/L Account-Indent";
#endif
        Window: Dialog;
        AccNo: array[10] of Code[20];
        ICAccIndentQst: Label 'This function updates the indentation of all the G/L accounts in the chart of accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. \\Do you want to indent the chart of accounts?';
        IndentingProgressMsg: Label 'Indenting the Chart of Accounts #1##########', Comment = '%1 = Account number being processed';
        EndTotalMissingBeginTotalErr: Label 'End-Total %1 is missing a matching Begin-Total.', Comment = '%1 = Account number';

    /// <summary>
    /// Runs the indentation process for Intercompany G/L Accounts with user confirmation.
    /// Updates the indentation levels based on account hierarchy structure.
    /// </summary>
    procedure RunICAccountIndent()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(ICAccIndentQst, true) then
            exit;

        IndentICAccount();
    end;

    local procedure IndentICAccount()
    var
        ICGLAcc: Record "IC G/L Account";
        IsHandled: Boolean;
        i: Integer;
    begin
        IsHandled := false;
        OnBeforeIndentICAccount(GLAcc, IsHandled);
#if not CLEAN30
        GLAccountIndent.RunOnBeforeIndentICAccount(GLAcc, IsHandled);
#endif
        if IsHandled then
            exit;

        i := 0;
        Window.Open(IndentingProgressMsg);
        if ICGLAcc.Find('-') then
            repeat
                Window.Update(1, ICGLAcc."No.");

                if ICGLAcc."Account Type" = ICGLAcc."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          EndTotalMissingBeginTotalErr,
                          ICGLAcc."No.");
                    i := i - 1;
                end;

                ICGLAcc.Validate(Indentation, i);
                ICGLAcc.Modify();

                if ICGLAcc."Account Type" = ICGLAcc."Account Type"::"Begin-Total" then begin
                    i := i + 1;
                    AccNo[i] := ICGLAcc."No.";
                end;
            until ICGLAcc.Next() = 0;
        Window.Close();
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"G/L Account-Indent", 'OnRunICAccountIndent', '', false, false)]
    local procedure OnRunICAccountIndent(var Sender: Codeunit "G/L Account-Indent"; var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        GLAccountIndent := Sender;
        GLAcc := GLAccount;
        RunICAccountIndent();
        GLAccount := GLAcc;
        IsHandled := true;
    end;
#pragma warning restore AL0432
#endif

    /// <summary>
    /// Integration event raised before indenting intercompany accounts during the indentation process.
    /// Allows extensions to customize intercompany account indentation behavior.
    /// </summary>
    /// <param name="GLAcc">Intercompany general ledger account being processed</param>
    /// <param name="IsHandled">Set to true to skip default intercompany indentation logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIndentICAccount(var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;
}
