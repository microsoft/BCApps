// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Sales.Pricing;

codeunit 7013 "Price Source Group - Customer" implements "Price Source Group"
{
    var
        SalesSourceType: Enum "Sales Price Source Type";

    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := SalesSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType.AsInteger()))
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::Customer);
    end;
}