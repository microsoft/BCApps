// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;

// Follows only invoice/credit-memo posting; it neither completes tasks nor commits the posting transaction.
codeunit 3331 "PA Task Posting"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EmptyPreviousOutcomeErr: Label 'An existing outcome reference is required for replacement.';
        InvalidOutcomeErr: Label 'The outcome must be an existing purchase invoice, purchase order, purchase credit memo, posted purchase invoice, or posted purchase credit memo.';
        AgentEDocumentServiceTok: Label 'AGENT', Locked = true;

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
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
    begin
        if PreviousOutcome.TableNo = 0 then
            Error(EmptyPreviousOutcomeErr);
        ValidateOutcome(PostedOutcome);
        if PreviousOutcome = PostedOutcome then
            exit;

        StoredTask.SetRange(Outcome, PreviousOutcome);
        StoredTask.ModifyAll(Outcome, PostedOutcome);
        EDocument.SetRange("Document Record ID", PreviousOutcome);
        if EDocument.FindSet(true) then
            repeat
                if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                    EDocument."Document Record ID" := PostedOutcome;
                    EDocument.Modify();
                end;
            until EDocument.Next() = 0;
    end;

    local procedure ValidateOutcome(OutcomeRecordId: RecordId)
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchaseHeader.ReadIsolation := IsolationLevel::UpdLock;
        case OutcomeRecordId.TableNo of
            Database::"Purchase Header":
                if PurchaseHeader.Get(OutcomeRecordId) then
                    if PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::"Credit Memo"] then
                        exit;
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(OutcomeRecordId) then
                    exit;
            Database::"Purch. Cr. Memo Hdr.":
                if PostedCreditMemo.Get(OutcomeRecordId) then
                    exit;
        end;
        Error(InvalidOutcomeErr);
    end;
}
