// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;

codeunit 6245 "Sust. GL Reverse Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseGLEntryOnAfterInsertGLEntry', '', false, false)]
    local procedure ReverseSustainabilityOnAfterReverseGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
    begin
        SustEntryReverseMgt.ReverseEntriesForGLEntry(GLEntry2."Entry No.");
    end;
}
