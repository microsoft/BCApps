// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.GLAccount;
using System.Utilities;

/// <summary>
/// Manages hierarchical indentation of general ledger accounts in the chart of accounts structure.
/// Provides functionality to automatically indent accounts based on Begin-Total and End-Total relationships and update totaling ranges.
/// </summary>
/// <remarks>
/// Key functions: Chart of accounts indentation, totaling range calculation, hierarchical structure validation.
/// Updates account indentation levels and totaling fields based on Begin-Total/End-Total account structure.
/// Validates proper nesting of account hierarchies and prevents invalid indentation configurations.
/// </remarks>
codeunit 3 "G/L Account-Indent"
{

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(GLAccIndentQst, true) then
            exit;

        Indent();
    end;

    var
        GLAcc: Record "G/L Account";
        Window: Dialog;
        AccNo: array[10] of Code[20];
        i: Integer;

        GLAccIndentQst: Label 'This function updates the indentation of all the G/L accounts in the chart of accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. The Totaling for each End-total is also updated.\\Do you want to indent the chart of accounts?';
        ICAccIndentQst: Label 'This function updates the indentation of all the G/L accounts in the chart of accounts. All accounts between a Begin-Total and the matching End-Total are indented one level. \\Do you want to indent the chart of accounts?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Indenting the Chart of Accounts #1##########';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ArrayExceededErr: Label 'You can only indent %1 levels for accounts of the type Begin-Total.', Comment = '%1 = A number bigger than 1';

    /// <summary>
    /// Processes all general ledger accounts to update indentation levels and totaling ranges based on account hierarchy.
    /// Automatically calculates indentation for accounts between Begin-Total and End-Total markers and updates totaling fields.
    /// </summary>
    /// <remarks>
    /// Validates proper nesting of Begin-Total and End-Total account pairs.
    /// Updates indentation field and totaling ranges for End-Total accounts.
    /// Supports up to 10 levels of account hierarchy indentation.
    /// Displays progress window during processing of large chart of accounts.
    /// </remarks>
    procedure Indent()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIndent(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text004);

        if GLAcc.Find('-') then
            repeat
                Window.Update(1, GLAcc."No.");

                if GLAcc."Account Type" = GLAcc."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text005,
                          GLAcc."No.");
                    GLAcc.Totaling := AccNo[i] + '..' + GLAcc."No.";
                    i := i - 1;
                end;

                GLAcc.Validate(Indentation, i);
                GLAcc.Modify();

                if GLAcc."Account Type" = GLAcc."Account Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(AccNo) then
                        Error(ArrayExceededErr, ArrayLen(AccNo));
                    AccNo[i] := GLAcc."No.";
                end;
            until GLAcc.Next() = 0;

        Window.Close();

        OnAfterIndent();
    end;

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
    begin
        IsHandled := false;
        OnBeforeIndentICAccount(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text004);
        if ICGLAcc.Find('-') then
            repeat
                Window.Update(1, ICGLAcc."No.");

                if ICGLAcc."Account Type" = ICGLAcc."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text005,
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

    /// <summary>
    /// Integration event raised after completing the chart of accounts indentation process.
    /// Allows extensions to perform additional processing after indentation is complete.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIndent()
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the chart of accounts indentation process.
    /// Allows extensions to override or supplement the indentation logic.
    /// </summary>
    /// <param name="GLAcc">General ledger account record being processed</param>
    /// <param name="IsHandled">Set to true to skip default indentation logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIndent(var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

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

