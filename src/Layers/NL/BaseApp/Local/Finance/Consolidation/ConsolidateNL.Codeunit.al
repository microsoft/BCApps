// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 11425 "Consolidate NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Consolidate, 'OnClearPreviousConsolidationOnBeforeModifyConsolidGLEntry', '', false, false)]
    local procedure ClearLocalizedGLEntryFields(var ConsolidGLEntry: Record "G/L Entry")
    begin
        ConsolidGLEntry."Remaining Amount" := 0;
        ConsolidGLEntry.Open := false;
    end;
}
