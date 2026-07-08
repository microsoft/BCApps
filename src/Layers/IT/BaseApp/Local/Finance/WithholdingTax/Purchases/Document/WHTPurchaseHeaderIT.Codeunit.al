// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;

codeunit 12201 "WHT Purchase Header IT"
{
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";

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

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidateBuyFromVendorNoOnAfterUpdateBuyFromCont', '', true, false)]
    local procedure OnValidateBuyFromVendorNoOnAfterUpdateBuyFromCont(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor)
    begin
        PurchWithhContribution.CreateRecord(PurchaseHeader, Vendor);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Document Date', true, false)]
    local procedure DocumentDateOnAfterValidateEvent(var Rec: Record "Purchase Header"; xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        PurchWithhContribution.UpdateDateRelatedWithPurchHeaderDocDate(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeShowPostedDocsToPrintCreatedMsg', '', true, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchWithhContribution.DeleteRecByPurchHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitInsert', '', true, false)]
    local procedure OnAfterInitInsert(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; var Vendor: Record Vendor)
    begin
        PurchWithhContribution.CreateRecord(Rec, Vendor);
    end;

}