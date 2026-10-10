// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Setup;

codeunit 8446 "IC Purchase Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterUpdateItemReference', '', false, false)]
    local procedure OnAfterUpdateItemReference(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.UpdateICPartner();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateVendorItemNo', '', false, false)]
    local procedure OnAfterValidateVendorItemNo(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader := PurchaseLine.GetPurchHeader();
        if PurchaseHeader."Send IC Document" and
           (PurchaseLine."IC Partner Ref. Type" = PurchaseLine."IC Partner Ref. Type"::"Vendor Item No.")
        then
            PurchaseLine."IC Partner Reference" := PurchaseLine."Vendor Item No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeGetJnlTemplateName', '', false, false)]
    local procedure OnBeforeGetJnlTemplateName(var PurchaseLine: Record "Purchase Line"; var JnlTemplateName: Code[10]; var IsHandled: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        if PurchaseLine."IC Partner Code" = '' then
            exit;

        IsHandled := true;
        PurchSetup.Get();
        if PurchaseLine.IsCreditDocType() then begin
            PurchSetup.TestField("IC Purch. Cr. Memo Templ. Name");
            JnlTemplateName := PurchSetup."IC Purch. Cr. Memo Templ. Name";
        end else begin
            PurchSetup.TestField("IC Purch. Invoice Templ. Name");
            JnlTemplateName := PurchSetup."IC Purch. Invoice Templ. Name";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Reference Management", 'OnAfterValidatePurchaseReferenceNo', '', false, false)]
    local procedure OnAfterValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
        PurchaseLine.UpdateICPartner();
    end;
}
