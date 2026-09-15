// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;

codeunit 5827 "Invt. Post G/L Src. Curr. Sub."
{
    EventSubscriberInstance = Manual;

    // Bound by "Inventory Posting To G/L".PostGenJnlLine only. Gen. Journal Line carries Source Currency Code = ACY so Gen. Jnl.-Post Line.GLCalcAddCurrency forwards the pre-summed buffer ACY into G/L Entry."Additional-Currency Amount" (no FX-drift round-trip). G/L Entry must not, however, advertise a Source Currency for inventory-cost postings.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLEntry', '', false, false)]
    local procedure SuppressSourceCurrencyOnGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrAmount: Decimal; UseAddCurrAmount: Boolean; var CurrencyFactor: Decimal)
    begin
        GLEntry."Source Currency Code" := '';
        GLEntry."Source Currency Amount" := 0;
    end;
}
