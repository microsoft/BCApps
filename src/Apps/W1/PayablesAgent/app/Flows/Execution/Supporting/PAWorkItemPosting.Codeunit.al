// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;

// Set-level outcome maintenance follows posting; no task completion, attachments, title updates or commits.
codeunit 3331 "PA Work Item Posting"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterFinalizePostingOnBeforeCommit, '', false, false)]
    local procedure OnBeforePostingCommit(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PreviewMode: Boolean)
    begin
        FollowPostedOutcome(PurchHeader, PurchInvHeader, PurchCrMemoHdr, PreviewMode);
    end;

    internal procedure FollowPostedOutcome(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PreviewMode: Boolean)
    begin
        if PreviewMode or PurchHeader.IsTemporary() then
            exit;
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Invoice:
                if PurchInvHeader."No." <> '' then
                    ReplaceReferences(PurchHeader.RecordId(), PurchInvHeader.RecordId());
            PurchHeader."Document Type"::"Credit Memo":
                if PurchCrMemoHdr."No." <> '' then
                    ReplaceReferences(PurchHeader.RecordId(), PurchCrMemoHdr.RecordId());
        end;
    end;

    local procedure ReplaceReferences(PreviousOutcome: RecordId; PostedOutcome: RecordId)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        DraftBasedWorkItem: Codeunit "PA Draft Based Work Item";
        PurchaseOutcomes: Codeunit "PA Purchase Outcomes";
        EmptyPreviousOutcomeErr: Label 'An existing outcome reference is required for replacement.';
    begin
        if PreviousOutcome.TableNo = 0 then
            Error(EmptyPreviousOutcomeErr);
        PurchaseOutcomes.ValidateForRegistration(PostedOutcome);
        if PreviousOutcome = PostedOutcome then
            exit;
        StoredWorkItem.SetRange(Outcome, PreviousOutcome);
        StoredWorkItem.ModifyAll(Outcome, PostedOutcome);
        DraftBasedWorkItem.ReplaceOutcomeReferences(PreviousOutcome, PostedOutcome);
    end;
}
