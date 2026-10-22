// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;

// Follows only invoice/credit-memo posting; it neither completes tasks nor commits the posting transaction.
codeunit 3331 "PA Task Posting"
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
    var
        TaskOutcomes: Codeunit "PA Task Outcome Repository";
    begin
        if PreviewMode or PurchHeader.IsTemporary() then
            exit;
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Invoice:
                if PurchInvHeader."No." <> '' then
                    TaskOutcomes.ReplaceReferences(PurchHeader.RecordId(), PurchInvHeader.RecordId());
            PurchHeader."Document Type"::"Credit Memo":
                if PurchCrMemoHdr."No." <> '' then
                    TaskOutcomes.ReplaceReferences(PurchHeader.RecordId(), PurchCrMemoHdr.RecordId());
        end;
    end;
}
