// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;

page 1348 "Employee Link"
{
    Caption = 'Employee Link';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Contact Business Relation";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Employee No.';
                    ToolTip = 'Specifies the number assigned to the contact in the Customer, Vendor, Bank Account, or Employee table. This field is only valid for contacts recorded as customer, vendor, bank accounts or employees.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        CustVendBankUpdate: Codeunit "CustVendBank-Update";
    begin
        if (Rec."No." <> '') and (CloseAction = ACTION::LookupOK) then begin
            Rec.TestField("No.");
            ContBusRel := Rec;
            ContBusRel.Insert(true);
            Contact.Get(ContBusRel."Contact No.");
            CustVendBankUpdate.UpdateEmployee(Contact, ContBusRel);
        end;
    end;
}

