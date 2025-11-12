// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;

page 5135 "Customer Link"
{
    Caption = 'Customer Link';
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
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number assigned to the contact in the Customer, Vendor, or Bank Account table. This field is only valid for contacts recorded as customer, vendor or bank accounts.';
                }
                field(CurrMasterFields; CurrMasterFields)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Current Master Fields';
                    OptionCaption = 'Contact,Customer';
                    ToolTip = 'Specifies which fields should be used to prioritize in case there is conflicting information in fields common to the contact card and the bank account card.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (Rec."No." <> '') and (CloseAction = ACTION::LookupOK) then begin
            ContBusRel := Rec;
            ContBusRel.Insert(true);
            OnQueryClosePageOnAfterContBusRelInsert(CurrMasterFields, ContBusRel);

            case CurrMasterFields of
                CurrMasterFields::Contact:
                    begin
                        Cont.Get(ContBusRel."Contact No.");
                        UpdateCustVendBank.UpdateCustomer(Cont, ContBusRel);
                    end;
                CurrMasterFields::Customer:
                    begin
                        Cust.Get(ContBusRel."No.");
                        UpdateContFromCust.OnModify(Cust);
                    end;
            end;
        end;
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        UpdateContFromCust: Codeunit "CustCont-Update";

    protected var
        CurrMasterFields: Option Contact,Customer;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnAfterContBusRelInsert(CurrMasterFields: Option Contact,Customer; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;
}

