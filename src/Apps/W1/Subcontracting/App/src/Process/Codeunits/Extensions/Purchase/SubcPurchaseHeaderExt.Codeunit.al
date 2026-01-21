// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 99001533 "Subc. Purchase Header Ext"
{
    var
        SubcSynchronizeManagement: Codeunit "Subc. Synchronize Management";

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterCopyBuyFromVendorFieldsFromVendor, '', false, false)]
    local procedure OnAfterCopyBuyFromVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; xPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Subc. Location Code" := Vendor."Subcontr. Location Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Buy-from Vendor No.", false, false)]
    local procedure OnAfterValidateEvent_BuyFromVendorNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header")
    begin
        SubcSynchronizeManagement.DeleteEnhancedDocumentsByChangeOfVendorNo(Rec, xRec);
    end;
}