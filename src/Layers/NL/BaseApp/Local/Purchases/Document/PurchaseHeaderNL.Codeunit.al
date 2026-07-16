// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;

codeunit 11323 PurchaseHeaderNL
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyPayToVendorFieldsFromVendor', '', false, false)]
    local procedure OnAfterCopyPayToVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; xPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Transaction Mode Code" := Vendor."Transaction Mode Code";
        PurchaseHeader."Bank Account Code" := Vendor."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType', '', false, false)]
    local procedure OnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType(Vendor: Record Vendor; var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; SkipPayToContact: Boolean)
    begin
        PurchaseHeader.Validate("Transaction Mode Code");
    end;
}
