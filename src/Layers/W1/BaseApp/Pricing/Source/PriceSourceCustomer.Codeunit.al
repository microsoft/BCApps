// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;

codeunit 7032 "Price Source - Customer" implements "Price Source"
{
    var
        Customer: Record Customer;
        ParentErr: Label 'Parent Source No. must be blank for Customer source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Customer.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Customer."No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    var
        Ishandled: Boolean;
    begin
        OnBeforeGetId(PriceSource, Ishandled);
        if Ishandled then
            exit;
        if Customer.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Customer.SystemId;
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
        if Customer.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Customer Lookup", Customer) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Customer."No.");
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
        exit(PriceSource."Source No.");
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := Customer.Name;
        PriceSource."Currency Code" := Customer."Currency Code";
        PriceSource."Allow Line Disc." := Customer."Allow Line Disc.";
        PriceSource."Price Includes VAT" := Customer."Prices Including VAT";
        PriceSource."VAT Bus. Posting Gr. (Price)" := Customer."VAT Bus. Posting Group";

        OnAfterFillAdditionalFields(PriceSource, Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Source List", 'OnBeforeAddChildren', '', false, false)]
    local procedure AddChildren(var Sender: Codeunit "Price Source List"; PriceSource: Record "Price Source"; var TempChildPriceSource: Record "Price Source" temporary);
    var
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        if PriceSource."Source Type" = "Price Source Type"::Customer then begin
            Customer.SetLoadFields("No.", "Customer Price Group", "Customer Disc. Group");
            if Customer.Get(PriceSource."Source No.") then begin
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
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceSource: Record "Price Source"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetId(var PriceSource: Record "Price Source"; var IsHandled: Boolean)
    begin
    end;
}