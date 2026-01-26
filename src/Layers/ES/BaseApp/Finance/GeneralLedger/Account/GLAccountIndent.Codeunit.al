// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.GLAccount;

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
    begin
        if not Confirm(
          Text1100000 +
          Text1100001 +
          Text1100002 +
          Text1100003 +
          Text1100004 +
          Text1100005, true)
        then
            exit;

        Indent();
    end;

    var
        GLAcc: Record "G/L Account";
        FindAcc: Record "G/L Account";
        Window: Dialog;
        HidePrintDialog: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1100000: Label 'This function checks the consistency of and completes the Chart of Accounts:\\';
        Text1100001: Label '- Checks that a corresponding heading account exists for every posting account.\';
        Text1100002: Label '- Checks that all accounts comply with the Chart of Account account length requisites.\';
        Text1100003: Label '- Assigns values to the following fields: Income/Balance/Capital, Account Type, Indentation, Totaling and Debit/Credit.\';
        Text1100004: Label '- Checks that an Adjustment Account exists for every account of the Income Statement and Capital types. \\';
        Text1100005: Label 'Do you wish to check the Chart of Accounts?';
        Text1100006: Label 'Checking the Chart of Accounts #1########## @2@@@@@@@@@@@@@';
        Text1100007: Label 'The length of a heading account cannot be greater than 8, account %1';
        Text1100008: Label ' Missing group %1 - Account No. %2';
        Text1100009: Label '..';
        Text1100010: Label ' Missing group %1 - Account No. %2';
        Text1100011: Label 'The length of account %1 cannot be different than the next ones';
        Text1100012: Label 'The Chart of Accounts is correct.';
#pragma warning restore AA0470
#pragma warning restore AA0074

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
        LineCounter: Integer;
        NoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIndent(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text1100006);

        GLAcc.Reset();
        LineCounter := 0;
        NoOfRecords := GLAcc.Count;
        if NoOfRecords <> 0 then
            if GLAcc.Find('-') then
                repeat
                    Window.Update(1, GLAcc."No.");

                    GLAcc.TestField(Name);

                    if StrLen(GLAcc."No.") > 5 then
                        GLAcc."Account Type" := GLAcc."Account Type"::Posting
                    else
                        GLAcc."Account Type" := GLAcc."Account Type"::Heading;

                    if GLAcc."Account Type" = GLAcc."Account Type"::Heading then begin
                        //The length of a heading account cannot be greater than 9
                        if StrLen(GLAcc."No.") > 8 then
                            Error(Text1100007, GLAcc."No.");
                        //a heading account must exist at the previous higher level
                        if StrLen(GLAcc."No.") > 1 then
                            if not FindAcc.Get(CopyStr(GLAcc."No.", 1, StrLen(GLAcc."No.") - 1)) then
                                Error(Text1100008, CopyStr(GLAcc."No.", 1, StrLen(GLAcc."No.") - 1), GLAcc."No.");
                        GLAcc.Totaling := GLAcc."No." + Text1100009 + PadStr(GLAcc."No.", 20 - (StrLen(GLAcc."No.") + 2), '9');
                        GLAcc.Validate(Indentation, StrLen(GLAcc."No.") - 1);
                    end else begin
                        //the corresponding heading account must exist
                        if not FindAcc.Get(CopyStr(GLAcc."No.", 1, 3)) then
                            Error(Text1100010, CopyStr(GLAcc."No.", 1, 3), GLAcc."No.");
                        //a posting account must be the same length as the next
                        FindAcc := GLAcc;
                        if FindAcc.Next() <> 0 then
                            if (FindAcc."Account Type" = FindAcc."Account Type"::Posting) and
                               (StrLen(GLAcc."No.") <> StrLen(FindAcc."No.")) then
                                Error(Text1100011, GLAcc."No.");

                        if CopyStr(GLAcc."No.", 1, 1) in ['6', '7'] then
                            GLAcc."Income/Balance" := GLAcc."Income/Balance"::"Income Statement"
                        else
                            if CopyStr(GLAcc."No.", 1, 1) in ['8', '9'] then
                                GLAcc."Income/Balance" := GLAcc."Income/Balance"::Capital
                            else
                                GLAcc."Income/Balance" := GLAcc."Income/Balance"::"Balance Sheet";

                        if GLAcc."Income/Balance" in [GLAcc."Income/Balance"::"Income Statement", GLAcc."Income/Balance"::Capital] then
                            GLAcc.TestField("Income Stmt. Bal. Acc.")
                        else
                            GLAcc."Income Stmt. Bal. Acc." := '';
                        GLAcc.Indentation := 5;
                    end;

                    GLAcc.Modify();
                    LineCounter := LineCounter + 1;
                    Window.Update(2, Round(LineCounter / NoOfRecords * 10000, 1));
                until GLAcc.Next() = 0;

        Window.Close();
        if not HidePrintDialog then
            Message(Text1100012);

        OnAfterIndent();
    end;

    /// <summary>
    /// Runs the indentation process for Intercompany G/L Accounts with user confirmation.
    /// Updates the indentation levels based on account hierarchy structure.
    /// </summary>
    procedure RunICAccountIndent()
    begin
        if not
          Confirm(
            Text1100000 +
            Text1100001 +
            Text1100002 +
            Text1100003 +
            Text1100004 +
            Text1100005, true)
        then
            exit;

        IndentICAccount();
    end;

    local procedure IndentICAccount()
    var
        ICGLAcc: Record "IC G/L Account";
        LineCounter: Integer;
        NoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIndentICAccount(GLAcc, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text1100006);

        ICGLAcc.Reset();
        LineCounter := 0;
        NoOfRecords := ICGLAcc.Count;
        if NoOfRecords <> 0 then
            if ICGLAcc.Find('-') then
                repeat
                    Window.Update(1, ICGLAcc."No.");

                    ICGLAcc.TestField(Name);

                    if StrLen(ICGLAcc."No.") > 5 then
                        ICGLAcc."Account Type" := ICGLAcc."Account Type"::Posting
                    else
                        ICGLAcc."Account Type" := ICGLAcc."Account Type"::Heading;

                    if ICGLAcc."Account Type" = ICGLAcc."Account Type"::Heading then begin
                        //The length of a heading account cannot be greater than 9
                        if StrLen(ICGLAcc."No.") > 8 then
                            Error(Text1100007, ICGLAcc."No.");
                        //a heading account must exist at the previous higher level
                        if StrLen(ICGLAcc."No.") > 1 then
                            if not FindAcc.Get(CopyStr(ICGLAcc."No.", 1, StrLen(ICGLAcc."No.") - 1)) then
                                Error(Text1100008, CopyStr(ICGLAcc."No.", 1, StrLen(ICGLAcc."No.") - 1), ICGLAcc."No.");
                        ICGLAcc.Validate(Indentation, StrLen(ICGLAcc."No.") - 1);
                    end else begin
                        //the corresponding heading account must exist
                        if not FindAcc.Get(CopyStr(ICGLAcc."No.", 1, 3)) then
                            Error(Text1100010, CopyStr(ICGLAcc."No.", 1, 3), ICGLAcc."No.");
                        //a posting account must be the same length as the next
                        FindAcc := GLAcc;
                        if FindAcc.Next() <> 0 then
                            if (FindAcc."Account Type" = FindAcc."Account Type"::Posting) and
                               (StrLen(ICGLAcc."No.") <> StrLen(FindAcc."No.")) then
                                Error(Text1100011, ICGLAcc."No.");

                        if CopyStr(ICGLAcc."No.", 1, 1) in ['6', '7'] then
                            ICGLAcc."Income/Balance" := ICGLAcc."Income/Balance"::"Income Statement"
                        else
                            ICGLAcc."Income/Balance" := ICGLAcc."Income/Balance"::"Balance Sheet";
                        ICGLAcc.Indentation := 4;
                    end;

                    ICGLAcc.Modify();
                    LineCounter := LineCounter + 1;
                    Window.Update(2, Round(LineCounter / NoOfRecords * 10000, 1));
                until ICGLAcc.Next() = 0;

        Window.Close();
        if not HidePrintDialog then
            Message(Text1100012);
    end;

    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
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

