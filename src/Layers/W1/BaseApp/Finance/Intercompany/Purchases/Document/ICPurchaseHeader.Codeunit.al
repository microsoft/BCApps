// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

codeunit 8445 "IC Purchase Header"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidateBuyFromVendorNoOnValidateBuyFromVendorNoOnBeforeValidatePayToVendor', '', true, false)]
    local procedure OnValidateBuyFromVendorNoOnValidateBuyFromVendorNoOnBeforeValidatePayToVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader."Buy-from IC Partner Code" := Vendor."IC Partner Code";
        PurchaseHeader."Send IC Document" := (PurchaseHeader."Buy-from IC Partner Code" <> '') and (PurchaseHeader."IC Direction" = PurchaseHeader."IC Direction"::Outgoing);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidatePayToVendorNoOnBeforeRecallModifyAddressNotification', '', true, false)]
    local procedure OnValidatePayToVendorNoOnBeforeRecallModifyAddressNotification(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader."Pay-to IC Partner Code" := Vendor."IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterUpdatePurchHeaderWhenCopyFromPurchHeader', '', true, false)]
    local procedure OnAfterUpdatePurchHeaderWhenCopyFromPurchHeader(var PurchaseHeader: Record "Purchase Header"; var OriginalPurchaseHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From")
    begin
        PurchaseHeader."IC Status" := PurchaseHeader."IC Status"::New;
    end;
}
