// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;

codeunit 7033 "Price Source - Cust. Price Gr." implements "Price Source"
{
    var
        CustomerPriceGroup: Record "Customer Price Group";
        ParentErr: Label 'Parent Source No. must be blank for Customer Price Group source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if CustomerPriceGroup.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := CustomerPriceGroup.Code;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if CustomerPriceGroup.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := CustomerPriceGroup.SystemId;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(AmountType = AmountType::Price);
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
        if CustomerPriceGroup.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Customer Price Groups", CustomerPriceGroup) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", CustomerPriceGroup.Code);
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
        PriceSource.Description := CustomerPriceGroup.Description;
        PriceSource."Allow Invoice Disc." := CustomerPriceGroup."Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := CustomerPriceGroup."Allow Line Disc.";
        PriceSource."Price Includes VAT" := CustomerPriceGroup."Price Includes VAT";
        PriceSource."VAT Bus. Posting Gr. (Price)" := CustomerPriceGroup."VAT Bus. Posting Gr. (Price)";

        OnAfterFillAdditionalFields(PriceSource, CustomerPriceGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceSource: Record "Price Source"; CustomerPriceGroup: Record "Customer Price Group")
    begin
    end;
}