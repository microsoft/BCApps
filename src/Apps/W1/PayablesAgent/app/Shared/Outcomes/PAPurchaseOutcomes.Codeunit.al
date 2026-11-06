// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

// Stateless interpretation of purchase references; Work Item owns the association, Purchasing owns document validity.
codeunit 3340 "PA Purchase Outcomes"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure TryGetFacts(OutcomeId: RecordId; var TempFacts: Record "PA Purchase Outcome Facts" temporary): Boolean
    begin
        exit(TryReadFacts(OutcomeId, false, TempFacts));
    end;

    internal procedure ValidateForRegistration(OutcomeId: RecordId)
    var
        TempFacts: Record "PA Purchase Outcome Facts" temporary;
        InvalidOutcomeErr: Label 'The outcome must be an existing purchase invoice, purchase order, purchase credit memo, posted purchase invoice, or posted purchase credit memo.';
    begin
        if TryReadFacts(OutcomeId, true, TempFacts) then
            if TempFacts.Posted or
               (TempFacts."Document Type" in [TempFacts."Document Type"::Invoice, TempFacts."Document Type"::Order, TempFacts."Document Type"::"Credit Memo"]) then
                exit;
        Error(InvalidOutcomeErr);
    end;

    local procedure TryReadFacts(OutcomeId: RecordId; ForRegistration: Boolean; var TempFacts: Record "PA Purchase Outcome Facts" temporary): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        Clear(TempFacts);
        if ForRegistration then
            PurchaseHeader.ReadIsolation := IsolationLevel::UpdLock;
        case OutcomeId.TableNo of
            Database::"Purchase Header":
                if PurchaseHeader.Get(OutcomeId) then begin
                    TempFacts."Document Type" := PurchaseHeader."Document Type";
                    TempFacts."Document No." := PurchaseHeader."No.";
                    if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                        TempFacts."Vendor Document No." := PurchaseHeader."Vendor Cr. Memo No."
                    else
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
                            TempFacts."Vendor Document No." := PurchaseHeader."Vendor Invoice No.";
                    TempFacts."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
                    TempFacts."Vendor Name" := PurchaseHeader."Buy-from Vendor Name";
                    exit(true);
                end;
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(OutcomeId) then begin
                    TempFacts."Document Type" := TempFacts."Document Type"::Invoice;
                    TempFacts.Posted := true;
                    TempFacts."Document No." := PostedInvoice."No.";
                    TempFacts."Vendor Document No." := PostedInvoice."Vendor Invoice No.";
                    TempFacts."Vendor No." := PostedInvoice."Buy-from Vendor No.";
                    TempFacts."Vendor Name" := PostedInvoice."Buy-from Vendor Name";
                    exit(true);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                if PostedCreditMemo.Get(OutcomeId) then begin
                    TempFacts."Document Type" := TempFacts."Document Type"::"Credit Memo";
                    TempFacts.Posted := true;
                    TempFacts."Document No." := PostedCreditMemo."No.";
                    TempFacts."Vendor Document No." := PostedCreditMemo."Vendor Cr. Memo No.";
                    TempFacts."Vendor No." := PostedCreditMemo."Buy-from Vendor No.";
                    TempFacts."Vendor Name" := PostedCreditMemo."Buy-from Vendor Name";
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
