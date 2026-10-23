// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;

codeunit 8427 "IC Gen. Jnl.-Show Card"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Show Card", 'OnBeforeRun', '', true, false)]
    local procedure OnBeforeRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        if GenJournalLine."Account Type" <> GenJournalLine."Account Type"::"IC Partner" then
            exit;

        ICPartner.Code := GenJournalLine."Account No.";
        Page.Run(Page::"IC Partner Card", ICPartner);
        IsHandled := true;
    end;
}