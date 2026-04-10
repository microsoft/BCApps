// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;

codeunit 7038 "Price Source - Contact" implements "Price Source"
{
    var
        Contact: Record Contact;
        ParentErr: Label 'Parent Source No. must be blank for Contact source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Contact.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Contact."No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Contact.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Contact.SystemId;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    var
        xPriceSource: Record "Price Source";
    begin
        xPriceSource := PriceSource;
        if Contact.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Contact List", Contact) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Contact."No.");
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        if PriceSource."Parent Source No." <> '' then
            Error(ParentErr);
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := Contact.Name;
        OnAfterFillAdditionalFields(PriceSource, Contact);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Source List", 'OnBeforeAddChildren', '', false, false)]
    local procedure AddChildren(var Sender: Codeunit "Price Source List"; PriceSource: Record "Price Source"; var TempChildPriceSource: Record "Price Source" temporary);
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        if PriceSource."Source Type" = "Price Source Type"::Contact then begin
            ContactBusinessRelation.SetLoadFields("No.");
            ContactBusinessRelation.SetRange("Contact No.", PriceSource."Source No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            if ContactBusinessRelation.FindSet() then
                repeat
                    Customer.SetLoadFields("No.", "Customer Price Group", "Customer Disc. Group");
                    if Customer.Get(ContactBusinessRelation."No.") then begin
                        Customer.ToPriceSource(TempChildPriceSource);
                        Sender.Add(TempChildPriceSource);
                        CustomerPriceGroup.SetLoadFields(Code);
                        if CustomerPriceGroup.Get(Customer."Customer Price Group") then begin
                            CustomerPriceGroup.ToPriceSource(TempChildPriceSource);
                            Sender.Add(TempChildPriceSource);
                        end;
                        CustomerDiscountGroup.SetLoadFields(Code);
                        if CustomerDiscountGroup.Get(Customer."Customer Disc. Group") then begin
                            CustomerDiscountGroup.ToPriceSource(TempChildPriceSource);
                            Sender.Add(TempChildPriceSource);
                        end;
                    end;
                until ContactBusinessRelation.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceSource: Record "Price Source"; Contact: Record Contact)
    begin
    end;
}