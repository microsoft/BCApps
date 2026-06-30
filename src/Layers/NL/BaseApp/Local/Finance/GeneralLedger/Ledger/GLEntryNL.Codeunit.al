// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

codeunit 11382 "G/L Entry NL"
{

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterUpdateDebitCredit, '', false, false)]
    local procedure OnAfterUpdateDebitCredit(var GLEntry: Record "G/L Entry"; Correction: Boolean)
    begin
        if GLEntry.Open then
             GLEntry."Remaining Amount" := GLEntry.Amount;
    end;
}