// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

/// <summary>
/// Handles IC Partner posting for General Journal Lines.
/// Extracted from Gen. Jnl.-Post Line codeunit to separate IC Partner-specific logic.
/// </summary>
codeunit 8411 "IC Gen. Jnl.-Post Line"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostGenJnlLine', '', false, false)]
    local procedure OnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var sender: Codeunit "Gen. Jnl.-Post Line")
    begin
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"IC Partner" then
            PostICPartner(GenJournalLine, sender);
    end;

    local procedure PostICPartner(GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ICPartner: Record "IC Partner";
        AccountNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostICPartner(GenJnlLine, IsHandled);
#if not CLEAN30
        GenJnlPostLine.RunOnBeforePostICPartner(GenJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        if GenJnlLine."Account No." <> ICPartner.Code then
            ICPartner.Get(GenJnlLine."Account No.");
        if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") xor (GenJnlLine.Amount > 0) then begin
            ICPartner.TestField("Receivables Account");
            AccountNo := ICPartner."Receivables Account";
        end else begin
            ICPartner.TestField("Payables Account");
            AccountNo := ICPartner."Payables Account";
        end;

        IsHandled := false;
        OnPostICPartnerOnBeforeCreateGLEntryBalAcc(GenJnlLine, GenJnlPostLine, IsHandled);
#if not CLEAN30
        GenJnlPostLine.RunOnPostICPartnerOnBeforeCreateGLEntryBalAcc(GenJnlLine, GenJnlPostLine.GetNextEntryNo(), IsHandled);
#endif
        if not IsHandled then
            GenJnlPostLine.CreateGLEntryBalAcc(
              GenJnlLine, AccountNo, GenJnlLine."Amount (LCY)", GenJnlLine."Source Currency Amount",
              GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostICPartner(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostICPartnerOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;
}
