// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;
using System.Reflection;

codeunit 346 "Purch. Line CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GlobalPurchaseHeader: Record "Purchase Header";
        GlobalField: Record "Field";

    procedure GetPurchaseLineCaptionClass(var PurchaseLine: Record "Purchase Line"; FieldNumber: Integer): Text
    var
        Caption: Text;
        IsHandled: Boolean;
    begin
        if (GlobalPurchaseHeader."Document Type" <> PurchaseLine."Document Type") or
           (GlobalPurchaseHeader."No." <> PurchaseLine."Document No.")
        then
            if not GlobalPurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
                Clear(GlobalPurchaseHeader);

        OnGetPurchaseLineCaptionClass(GlobalPurchaseHeader, PurchaseLine, FieldNumber, IsHandled, Caption);
        if IsHandled then
            exit(Caption);

        case FieldNumber of
            PurchaseLine.FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(DATABASE::"Purchase Line", FieldNumber)));
            else begin
                if GlobalPurchaseHeader."Prices Including VAT" then
                    exit('2,1,' + GetFieldCaption(DATABASE::"Purchase Line", FieldNumber));
                exit('2,0,' + GetFieldCaption(DATABASE::"Purchase Line", FieldNumber));
            end;
        end;
    end;

    local procedure GetFieldCaption(TableNumber: Integer; FieldNumber: Integer): Text
    begin
        if (GlobalField.TableNo <> TableNumber) or (GlobalField."No." <> FieldNumber) then
            GlobalField.Get(TableNumber, FieldNumber);
        exit(GlobalField."Field Caption");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchaseLineCaptionClass(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var IsHandled: Boolean; var Caption: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterChangePricesIncludingVAT', '', true, true)]
    local procedure PurchaseHeaderChangedPricesIncludingVAT(var PurchaseHeader: Record "Purchase Header")
    begin
        GlobalPurchaseHeader := PurchaseHeader;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType', '', true, true)]
    local procedure UpdatePurchLineFieldsCaptionOnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType(Vendor: Record Vendor; var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header")
    begin
        GlobalPurchaseHeader := PurchaseHeader;
    end;

}

