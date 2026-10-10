// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;

codeunit 8429 "IC Gen. Jnl. Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GenJnlManagement, 'OnAfterGetAccounts', '', true, false)]
    local procedure OnAfterGetAccounts(var GenJournalLine: Record "Gen. Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        ICPartner: Record "IC Partner";
    begin
        if (AccName = '') and (GenJournalLine."Account Type" = GenJournalLine."Account Type"::"IC Partner") and (GenJournalLine."Account No." <> '') then begin
            ICPartner.SetLoadFields(Name);
            if ICPartner.Get(GenJournalLine."Account No.") then
                AccName := ICPartner.Name;
        end;

        if (BalAccName = '') and (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"IC Partner") and (GenJournalLine."Bal. Account No." <> '') then begin
            ICPartner.SetLoadFields(Name);
            if ICPartner.Get(GenJournalLine."Bal. Account No.") then
                BalAccName := ICPartner.Name;
        end;
    end;
}