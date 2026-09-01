// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;

tableextension 31077 "Contact CZC" extends Contact
{
    internal procedure FindVendor(var Vendor: Record Vendor): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactBusinessRelationFound: Boolean;
    begin
        Clear(Vendor);

        if Rec.Type = Rec.Type::Person then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Vendor, Rec."No.");

        if not ContactBusinessRelationFound then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Vendor, Rec."Company No.");

        if not ContactBusinessRelationFound then
            exit(false);

        exit(Vendor.Get(ContactBusinessRelation."No."));
    end;
}