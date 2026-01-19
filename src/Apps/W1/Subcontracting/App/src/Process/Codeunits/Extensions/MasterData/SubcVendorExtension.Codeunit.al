// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Vendor;

codeunit 99001531 "Subc. Vendor Extension"
{
    [EventSubscriber(ObjectType::Table, Database::Vendor, OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        if not Rec.IsTemporary() then
            if RunTrigger then begin
                SubcontractorPrice.SetCurrentKey("Vendor No.");
                SubcontractorPrice.SetRange("Vendor No.", Rec."No.");
                if not SubcontractorPrice.IsEmpty() then
                    SubcontractorPrice.DeleteAll(true);
            end;
    end;
}