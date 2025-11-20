// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;

page 5137 "Bank Account Link"
{
    Caption = 'Bank Account Link';
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
                    Caption = 'Bank Account No.';
                    ToolTip = 'Specifies the number assigned to the contact in the Customer, Vendor, or Bank Account table. This field is only valid for contacts recorded as customer, vendor or bank accounts.';
                }
                field(CurrMasterFields; CurrMasterFields)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Current Master Fields';
                    OptionCaption = 'Contact,Bank';
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
            Rec.TestField("No.");
            ContBusRel := Rec;
            ContBusRel.Insert(true);
            OnQueryClosePageOnAfterContBusRelInsert(CurrMasterFields, ContBusRel);
            case CurrMasterFields of
                CurrMasterFields::Contact:
                    begin
                        Cont.Get(ContBusRel."Contact No.");
                        UpdateCustVendBank.UpdateBankAccount(Cont, ContBusRel);
                    end;
                CurrMasterFields::Bank:
                    begin
                        BankAcc.Get(ContBusRel."No.");
                        UpdateContFromBank.OnModify(BankAcc);
                    end;
            end;
        end;
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        BankAcc: Record "Bank Account";
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        UpdateContFromBank: Codeunit "BankCont-Update";
        CurrMasterFields: Option Contact,Bank;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnAfterContBusRelInsert(CurrMasterFields: Option Contact,Bank; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;
}

