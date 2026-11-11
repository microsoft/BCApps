// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

#pragma warning disable AS0088
codeunit 7000147 "Vendor Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterInitInvoiceDiscCode', '', true, false)]
    local procedure OnAfterInitInvoiceDiscCode(var Vendor: Record Vendor)
    begin
        Vendor."Payment Days Code" := Vendor."No.";
        Vendor."Non-Paymt. Periods Code" := Vendor."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnApplyTemplateOnAfterCopyFields', '', true, false)]
    local procedure OnApplyTemplateOnAfterCopyFields(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ."; UpdateExistingValues: Boolean)
    begin
        if VendorTempl."Payment Days Code" <> '' then
            Vendor."Payment Days Code" := VendorTempl."Payment Days Code";
        if VendorTempl."Non-Paymt. Periods Code" <> '' then
            Vendor."Non-Paymt. Periods Code" := VendorTempl."Non-Paymt. Periods Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnFillFieldExclusionListOnAfterAddFields', '', true, false)]
    local procedure OnFillFieldExclusionListOnAfterAddFields(var FieldExclusionList: List of [Integer])
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        FieldExclusionList.Add(VendorTempl.FieldNo("Payment Days Code"));
        FieldExclusionList.Add(VendorTempl.FieldNo("Non-Paymt. Periods Code"));
    end;
}
