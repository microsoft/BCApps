// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Bank.Payment;
using System.Utilities;

codeunit 11424 "Calc. G/L Acc. Where-Used NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnAfterFillTableBuffer', '', false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    var
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        CalcGLAccWhereUsed.AddTable(TableBuffer, Database::"Transaction Mode");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnShowExtensionPage', '', false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    var
        TransactionMode: Record "Transaction Mode";
    begin
        if GLAccountWhereUsed."Table ID" <> Database::"Transaction Mode" then
            exit;

        Evaluate(TransactionMode."Account Type", GLAccountWhereUsed."Key 1");
        TransactionMode.Code := CopyStr(GLAccountWhereUsed."Key 2", 1, MaxStrLen(TransactionMode.Code));
        Page.Run(0, TransactionMode);
    end;
}
