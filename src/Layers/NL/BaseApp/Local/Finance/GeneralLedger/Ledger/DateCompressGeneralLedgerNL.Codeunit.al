// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

codeunit 11334 "Date Compress G/L NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Report, Report::"Date Compress General Ledger", 'OnSummarizeEntryOnBeforeGLEntryDelete', '', false, false)]
    local procedure OnSummarizeEntryOnBeforeGLEntryDelete(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    begin
        NewGLEntry."Remaining Amount" += GLEntry."Remaining Amount";
    end;
}
