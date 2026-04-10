// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Vendor;

codeunit 7035 "Price Source - Vendor" implements "Price Source"
{
    var
        Vendor: Record Vendor;
        ParentErr: Label 'Parent Source No. must be blank for Vendor source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Vendor.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Vendor."No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Vendor.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Vendor.SystemId;
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
        if Vendor.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Vendor Lookup", Vendor) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Vendor."No.");
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
        PriceSource.Description := Vendor.Name;
        PriceSource."Currency Code" := Vendor."Currency Code";
        PriceSource."Price Includes VAT" := Vendor."Prices Including VAT";
        PriceSource."VAT Bus. Posting Gr. (Price)" := Vendor."VAT Bus. Posting Group";
        OnAfterFillAdditionalFields(PriceSource, Vendor);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceSource: Record "Price Source"; Vendor: Record Vendor)
    begin
    end;
}