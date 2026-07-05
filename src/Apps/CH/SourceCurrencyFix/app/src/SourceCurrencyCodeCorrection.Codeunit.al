// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.GeneralLedger.Account;

codeunit 11521 "Source Currency Code Corr. CH"
{
    Permissions = tabledata "G/L Account" = r,
                  tabledata "G/L Entry" = rm;

    trigger OnRun()
    var
        UpdatedCount: Integer;
    begin
        if not Confirm(ConfirmCorrectionQst, false) then
            exit;

        UpdatedCount := CorrectSourceCurrencyCode();

        if UpdatedCount = 0 then
            Message(NoEntriesCorrectedMsg)
        else
            Message(EntriesCorrectedMsg, UpdatedCount);
    end;

    var
        ConfirmCorrectionQst: Label 'This will fill the blank Source Currency Code on posted G/L entries that have a Source Currency Amount, using the Source Currency Code of the related G/L account.\\Do you want to continue?';
        NoEntriesCorrectedMsg: Label 'No G/L entries needed correcting.';
        EntriesCorrectedMsg: Label 'The Source Currency Code was updated on %1 G/L entries.', Comment = '%1 = number of updated G/L entries.';

    /// <summary>
    /// Back-fills the blank Source Currency Code on G/L entries that have a non-zero Source Currency
    /// Amount, by copying the Source Currency Code from the related G/L account.
    /// </summary>
    /// <returns>The number of G/L entries that were updated.</returns>
    procedure CorrectSourceCurrencyCode(): Integer
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        UpdatedCount: Integer;
    begin
        GLEntry.SetLoadFields("G/L Account No.", "Source Currency Code", "Source Currency Amount");
        GLEntry.SetFilter("Source Currency Amount", '<>0');
        GLEntry.SetRange("Source Currency Code", '');
        if GLEntry.FindSet(true) then
            repeat
                GLAccount.SetLoadFields("No.", "Source Currency Code");
                if GLAccount.Get(GLEntry."G/L Account No.") then
                    if GLAccount."Source Currency Code" <> '' then begin
                        GLEntry."Source Currency Code" := GLAccount."Source Currency Code";
                        GLEntry.Modify(false);
                        UpdatedCount += 1;
                    end;
            until GLEntry.Next() = 0;

        exit(UpdatedCount);
    end;
}
