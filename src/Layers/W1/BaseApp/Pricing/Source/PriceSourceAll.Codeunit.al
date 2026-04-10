// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;

codeunit 7031 "Price Source - All" implements "Price Source"
{
    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := false;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    begin
        exit(false)
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        PriceSource.InitSource();
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
    end;
}