// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 99001555 "Subc. ProdOrderCreateBind"
{
    EventSubscriberInstance = Manual;

    var
        SubcontractingPurchaseLine: Record "Purchase Line";

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeCheckRoutingNoNotBlank, '', false, false)]
    local procedure "Prod. Order Routing Line_OnBeforeCheckRoutingNoNotBlank"(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subcontracting Management", OnBeforeGetSubcontractor, '', false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
        GetSubcontractorForPurchaseProvision(Vendor, HasSubcontractor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subc. Calc. Prod. Order Ext.", OnAfterTransferSubcontractingFieldsBOMComponent, '', false, false)]
    local procedure "Sub. Calc. Prod. Order Ext._OnAfterTransferSubcontractingFieldsBOMComponent"(var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
        TransferSubcontractingFieldsBOMComponentForPurchaseProvision(ProdOrderComponent);
    end;

    procedure SetSubcontractingPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        SubcontractingPurchaseLine := PurchaseLine;
    end;

    local procedure TransferSubcontractingFieldsBOMComponentForPurchaseProvision(var ProdOrderComponent: Record "Prod. Order Component")
    var
        SubcManagementSetup: Record "Subc. Management Setup";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        ComponentsLocationCode: Code[10];
    begin
        SubcManagementSetup.SetLoadFields("Rtng. Link Code Purch. Prov.");
        SubcManagementSetup.Get();
        if (ProdOrderComponent."Routing Link Code" <> SubcManagementSetup."Rtng. Link Code Purch. Prov.") or
           (ProdOrderComponent."Subcontracting Type" <> "Subcontracting Type"::Transfer) then
            exit;

        ComponentsLocationCode := SubcontractingManagement.GetComponentsLocationCode(SubcontractingPurchaseLine);

        ProdOrderComponent.Validate("Location Code", ComponentsLocationCode);
        ProdOrderComponent."Orig. Location Code" := '';
    end;

    local procedure GetSubcontractorForPurchaseProvision(var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
        if SubcontractingPurchaseLine."Buy-from Vendor No." = '' then
            exit;
        Vendor.Get(SubcontractingPurchaseLine."Buy-from Vendor No.");
        IsHandled := true;
        HasSubcontractor := true;
    end;
}