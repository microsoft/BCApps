// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Ledger;

codeunit 5603 "FA Get Balance Account"
{

    trigger OnRun()
    begin
    end;

    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";

#pragma warning disable AA0074
        Text000: Label 'Do you want to insert a line for the balancing account that is related to the selected lines?';
#pragma warning restore AA0074

    procedure InsertAcc(var GenJnlLine: Record "Gen. Journal Line")
    begin
        ClearAll();
        if GenJnlLine.Count > 1 then
            if not Confirm(Text000) then
                exit;
        if GenJnlLine.Find('+') then
            repeat
                FAInsertGLAcc.GetBalAcc(GenJnlLine);
            until GenJnlLine.Next(-1) = 0;
    end;

    procedure InsertAccWithBalAccountInfo(var GenJnlLine: Record "Gen. Journal Line"; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        ClearAll();
        if GenJnlLine.Count > 1 then
            if not Confirm(Text000) then
                exit;
        if GenJnlLine.Find('+') then
            repeat
                FAInsertGLAcc.GetBalAccWithBalAccountInfo(GenJnlLine, BalAccountType, BalAccountNo);
            until GenJnlLine.Next(-1) = 0;
    end;
}

