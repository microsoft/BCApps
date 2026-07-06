// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;

codeunit 12201 "WHT Purchase Header IT"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterCopyPayToVendorFieldsFromVendor', '', true, false)]
    local procedure OnAfterCopyPayToVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; xPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Individual Person" := Vendor."Individual Person";
        PurchaseHeader.Resident := Vendor.Resident;
        PurchaseHeader."First Name" := Vendor."First Name";
        PurchaseHeader."Last Name" := Vendor."Last Name";
        PurchaseHeader."Date of Birth" := Vendor."Date of Birth";
        PurchaseHeader."Birth City" := Vendor."Birth City";
        PurchaseHeader."Tax Representative Type" := Vendor."Tax Representative Type";
        PurchaseHeader."Tax Representative No." := Vendor."Tax Representative No.";
    end;

}