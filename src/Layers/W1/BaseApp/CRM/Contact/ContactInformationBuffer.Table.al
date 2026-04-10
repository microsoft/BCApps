// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 5049 "Contact Information Buffer"
{
    Caption = 'Contact Information Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact Id"; Guid)
        {
            Caption = 'Contact Id';
            NotBlank = true;
        }
        field(2; "Related Id"; Guid)
        {
            Caption = 'Related Id';
            NotBlank = true;
        }
        field(3; "Related Type"; Enum "Contact Business Relation Link To Table")
        {
            Caption = 'Related Type';
            NotBlank = true;
        }
        field(4; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
        }
        field(5; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(6; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
        }
    }

    keys
    {
        key(PK; "Contact Id")
        {
            Clustered = true;
        }
    }

    procedure LoadDataFromFilters(RelatedIdFilter: Text; RelatedTypeFilter: Text)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record "Contact";
        ContactBusunessRelationLinkToTable: Enum "Contact Business Relation Link To Table";
    begin
        Evaluate(ContactBusunessRelationLinkToTable, RelatedTypeFilter);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusunessRelationLinkToTable);

        case ContactBusunessRelationLinkToTable of
            ContactBusunessRelationLinkToTable::Customer:
                begin
                    Customer.GetBySystemId(RelatedIdFilter);
                    ContactBusinessRelation.SetRange("No.", Customer."No.");
                end;
            ContactBusunessRelationLinkToTable::Vendor:
                begin
                    Vendor.GetBySystemId(RelatedIdFilter);
                    ContactBusinessRelation.SetRange("No.", Vendor."No.");
                end;
        end;

        if ContactBusinessRelation.FindFirst() then begin
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
            if Contact.IsEmpty() then begin
                Contact.SetRange("Company No.");
                Contact.SetRange("No.", ContactBusinessRelation."Contact No.");
            end;
            if Contact.FindSet() then
                repeat
                    Clear(Rec);
                    Rec."Contact Id" := Contact.SystemId;
                    Rec."Contact No." := Contact."No.";
                    Rec."Contact Name" := Contact.Name;
                    Rec."Contact Type" := Contact.Type;
                    case ContactBusinessRelation."Link to Table" of
                        ContactBusinessRelation."Link to Table"::Customer:
                            begin
                                Rec."Related Id" := Customer.SystemId;
                                Rec."Related Type" := Rec."Related Type"::Customer;
                            end;
                        ContactBusinessRelation."Link to Table"::Vendor:
                            begin
                                Rec."Related Id" := Vendor.SystemId;
                                Rec."Related Type" := Rec."Related Type"::Vendor;
                            end;
                    end;
                    Rec.Insert();
                until Contact.Next() = 0;
        end;
    end;
}
