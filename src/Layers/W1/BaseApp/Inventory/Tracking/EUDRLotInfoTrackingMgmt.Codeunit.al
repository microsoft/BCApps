// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Purchases.Document;

codeunit 6504 "EUDR Lot Info. Tracking Mgmt"
{
    SingleInstance = true;

    var
        CurrentCountryRegionCode: Code[10];

    internal procedure SetCountryRegionCode(TrackingSpecification: Record "Tracking Specification")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if TrackingSpecification."Source Type" = 0 then
            exit;

        if TrackingSpecification."Source Type" <> Database::"Purchase Line" then begin
            ClearCountryRegionCode();
            exit;
        end;

        if PurchaseHeader.Get(Enum::"Purchase Document Type".FromInteger(TrackingSpecification."Source Subtype"), TrackingSpecification."Source ID") then
            CurrentCountryRegionCode := PurchaseHeader."Buy-from Country/Region Code";
    end;

    internal procedure GetCurrentCountryRegionCode(): Code[10]
    begin
        exit(CurrentCountryRegionCode);
    end;

    internal procedure ClearCountryRegionCode()
    begin
        Clear(CurrentCountryRegionCode);
    end;
}