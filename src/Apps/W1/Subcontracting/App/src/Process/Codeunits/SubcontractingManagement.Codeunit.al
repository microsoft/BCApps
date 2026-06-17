// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 99001505 "Subcontracting Management"
{
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'Update cancelled.';
        UpdateIsCanceledErr: Label 'The update is canceled.';
        WorkCenterVendorDoesntExistErr: Label 'Subcontractor %1 on Work Center %2 does not exist.', Comment = 'Parameter %1 - subcontractor/vendor number, %2 - work center number.';
        PurchOrderExistErr: Label 'The currently selected component %1 is already used in Purchase Order %2. Therefore, it is not permitted to change the %3 field.', Comment = '%1=Item No, %2=Purchase Order No, %3=Field Caption';
        HasManufacturingSetup: Boolean;

    procedure ChangeLocationOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        case ProdOrderComponent."Component Supply Method" of
            "Component Supply Method"::"Consignment at Vendor",
            "Component Supply Method"::"Vendor-Supplied":
                if (VendorSubcontrLocation <> '') and (ProdOrderComponent."Location Code" <> VendorSubcontrLocation) then
                    ProdOrderComponent.Validate("Location Code", VendorSubcontrLocation);

            "Component Supply Method"::"Transfer to Vendor",
            "Component Supply Method"::Empty:
                begin
                    if (ProdOrderComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        ProdOrderComponent.Validate("Location Code", OriginalLocationCode);
                        ProdOrderComponent."Subc. Original Location Code" := '';
                    end;
                    if (ProdOrderComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        ProdOrderComponent.Validate("Bin Code", OriginalBinCode);
                        ProdOrderComponent."Subc. Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure ChangeLocationOnPlanningComponent(var PlanningComponent: Record "Planning Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        case PlanningComponent."Component Supply Method" of
            "Component Supply Method"::"Consignment at Vendor",
            "Component Supply Method"::"Vendor-Supplied":
                if (VendorSubcontrLocation <> '') and (PlanningComponent."Location Code" <> VendorSubcontrLocation) then
                    PlanningComponent.Validate("Location Code", VendorSubcontrLocation);

            "Component Supply Method"::"Transfer to Vendor",
            "Component Supply Method"::Empty:
                begin
                    if (PlanningComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        PlanningComponent.Validate("Location Code", OriginalLocationCode);
                        PlanningComponent."Orig. Location Code" := '';
                    end;
                    if (PlanningComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        PlanningComponent.Validate("Bin Code", OriginalBinCode);
                        PlanningComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure DelLocationLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ConfirmManagement: Codeunit "Confirm Management";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if not ProdOrderComponent.IsEmpty() then begin
            ProdOrderComponent.FindSet();
            if ShowMsg then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                    Error(UpdateIsCancelledErr);

            ProdOrderLine.SetLoadFields("Item No.", "Variant Code", "Location Code");
            ProdOrderLine.Get(ProdOrderRoutingLine.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
            PlanningGetParameters.AtSKU(
              StockkeepingUnit,
              ProdOrderLine."Item No.",
              ProdOrderLine."Variant Code",
              ProdOrderLine."Location Code");
            repeat
                ProdOrderComponent.Validate("Location Code", StockkeepingUnit."Components at Location");
                ProdOrderComponent.Modify();
            until ProdOrderComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure GetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
        HasSubcontractor, IsHandled : Boolean;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(false);

#endif
        OnBeforeGetSubcontractor(WorkCenterNo, Vendor, HasSubcontractor, IsHandled);//DO NOT DELETE
        if IsHandled then
            exit(HasSubcontractor);

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(WorkCenterNo);
        if WorkCenter."Subcontractor No." <> '' then begin
            Vendor.SetLoadFields("Subc. Location Code");
            if not Vendor.Get(WorkCenter."Subcontractor No.") then
                Error(WorkCenterVendorDoesntExistErr, WorkCenter."Subcontractor No.", WorkCenter."No.");
            Vendor.TestField("Subc. Location Code");
            exit(true);
        end;
        exit(false);
    end;

    procedure UpdateSubcontractorPriceForRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if IsSubcontracting(RequisitionLine."Work Center No.") then
            RequisitionLine.UpdateSubcontractorPrice();
    end;

    procedure UpdateLinkedComponentsAfterRoutingTransfer(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderRoutingLine.Type <> "Capacity Type"::"Work Center" then
            exit;

        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit;

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(RoutingLine."Work Center No.");
        if WorkCenter."Subcontractor No." = '' then
            exit;

        UpdLinkedComponents(ProdOrderRoutingLine, false);
    end;

    procedure UpdateComponentSupplyMethodForPlanningComponent(var PlanningComponent: Record "Planning Component")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        Vendor: Record Vendor;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PlanningComponent."Routing Link Code" = '' then
            exit;

        PlanningRoutingLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PlanningRoutingLine.SetRange("Routing Link Code", PlanningComponent."Routing Link Code");
        PlanningRoutingLine.SetRange(Type, "Capacity Type"::"Work Center");
        if not PlanningRoutingLine.IsEmpty() then begin
            PlanningRoutingLine.SetLoadFields("No.");
            PlanningRoutingLine.FindFirst();

            if not GetSubcontractor(PlanningRoutingLine."No.", Vendor) then
                Clear(Vendor);
            if PlanningComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"] then
                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
            OrigLocationCode := PlanningComponent."Orig. Location Code";
            OrigBinCode := PlanningComponent."Orig. Bin Code";

            ChangeLocationOnPlanningComponent(PlanningComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

            PlanningComponent.Modify();
        end;
    end;

    procedure UpdateComponentSupplyMethodForProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        ProdOrderCompFound: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        PurchOrderNo: Code[20];
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;

        ProdOrderLine.SetLoadFields("Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        ProdOrderRoutingLine.SetLoadFields("Prod. Order No.", Type, "No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
            PurchaseLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
            PurchaseLine.SetLoadFields(SystemId);
            if PurchaseLine.FindSet() then
                repeat
                    if PurchOrderNo <> PurchaseLine."Document No." then begin
                        PurchOrderNo := PurchaseLine."Document No.";
                        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
                        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
                        PurchaseLine2.SetRange(Type, "Purchase Line Type"::Item);
                        PurchaseLine2.SetRange("No.", ProdOrderComponent."Item No.");
                        ProdOrderCompFound := not PurchaseLine2.IsEmpty();
                    end;
                until (PurchaseLine.Next() = 0) or ProdOrderCompFound;
            if ProdOrderCompFound then
                Error(PurchOrderExistErr, ProdOrderComponent."Item No.", PurchOrderNo, ProdOrderComponent.FieldCaption(ProdOrderComponent."Component Supply Method"));

            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then begin
                if not GetSubcontractor(ProdOrderRoutingLine."No.", Vendor) then
                    Clear(Vendor);

                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
                if not (ProdOrderComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"]) then
                    Clear(VendorSubcontractingLocationCode);
                OrigLocationCode := ProdOrderComponent."Subc. Original Location Code";
                OrigBinCode := ProdOrderComponent."Subc. Orig. Bin Code";

                ChangeLocationOnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                ProdOrderComponent.Modify();
            end;
        end;
    end;

    procedure UpdLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        Subcontracting: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if ProdOrderComponent.FindSet() then begin
            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then
                Subcontracting := GetSubcontractor(ProdOrderRoutingLine."No.", Vendor);

            if Subcontracting then begin
                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
                if ShowMsg then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                        Error(UpdateIsCanceledErr);
                repeat
                    if not (ProdOrderComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"]) then
                        Clear(VendorSubcontractingLocationCode);
                    OrigLocationCode := ProdOrderComponent."Subc. Original Location Code";
                    OrigBinCode := ProdOrderComponent."Subc. Orig. Bin Code";

                    ChangeLocationOnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                    ProdOrderComponent.Modify();
                until ProdOrderComponent.Next() = 0;

                if ShowMsg then
                    Message(SuccessfullyUpdatedMsg);
            end;
        end;
    end;

    /// <summary>
    /// Gets the location code for production order components based on the setup field "Subc. Default Comp. Location".
    /// The location code is retrieved from the purchase line, company information, or manufacturing setup.
    /// </summary>
    /// <returns>The components location code.</returns>
    procedure GetComponentsLocationCode(PurchaseLine: Record "Purchase Line"): Code[10]
    var
        CompanyInformation: Record "Company Information";
        ComponentsLocationCode: Code[10];
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');

#endif
        GetManufacturingSetup();
        ManufacturingSetup.TestField("Subc. Default Comp. Location");

        case ManufacturingSetup."Subc. Default Comp. Location" of
            "Components at Location"::Purchase:
                begin
                    PurchaseLine.TestField("Location Code");
                    ComponentsLocationCode := PurchaseLine."Location Code";
                end;
            "Components at Location"::Company:
                begin
                    CompanyInformation.SetLoadFields("Location Code");
                    CompanyInformation.Get();
                    CompanyInformation.TestField("Location Code");
                    ComponentsLocationCode := CompanyInformation."Location Code";
                end;
            "Components at Location"::Manufacturing:
                begin
                    ManufacturingSetup.SetLoadFields("Components at Location");
                    ManufacturingSetup.Get();
                    ManufacturingSetup.TestField("Components at Location");
                    ComponentsLocationCode := ManufacturingSetup."Components at Location";
                end;
        end;

        exit(ComponentsLocationCode);
    end;

    internal procedure IsSubcontractingPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>%1', 0);
        exit(not PurchaseLine.IsEmpty());
    end;

    internal procedure IsSubcontractingPurchaseLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit((PurchaseLine."Prod. Order No." <> '') and (PurchaseLine."Prod. Order Line No." <> 0));
    end;

    local procedure GetManufacturingSetup()
    begin
        if HasManufacturingSetup then
            exit;
        HasManufacturingSetup := ManufacturingSetup.Get();
    end;

    local procedure IsSubcontracting(WorkCenterNo: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(WorkCenterNo) then
            exit(WorkCenter."Subcontractor No." <> '')
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
    end;
}
