// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using System.Environment.Configuration;
using System.Telemetry;

codeunit 20579 "Subc. Feature Telemetry"
{
    Access = Internal;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        SubcontractingTok: Label 'Subcontracting', Locked = true;

    internal procedure LogUptake(FeatureUptakeStatus: Enum "Feature Uptake Status")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if FeatureUptakeStatus = FeatureUptakeStatus::Undiscovered then
            exit;

        // Backfill through the same instance; Feature Telemetry prevents state regression.
        FeatureTelemetry.LogUptake('0001Q7N', SubcontractingTok, Enum::"Feature Uptake Status"::Discovered);
        if FeatureUptakeStatus = FeatureUptakeStatus::Discovered then
            exit;

        FeatureTelemetry.LogUptake('0001Q7O', SubcontractingTok, Enum::"Feature Uptake Status"::"Set up");
        if FeatureUptakeStatus = FeatureUptakeStatus::"Set up" then
            exit;

        FeatureTelemetry.LogUptake('0001Q7P', SubcontractingTok, Enum::"Feature Uptake Status"::Used);
    end;

    internal procedure LogWorksheetOpened()
    begin
        if IsSetup() then
            LogUptake(Enum::"Feature Uptake Status"::"Set up")
        else
            LogUptake(Enum::"Feature Uptake Status"::Discovered);
    end;

    internal procedure IsSetup(): Boolean
    var
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
        if not WorkCenter.IsEmpty() then
            exit(true);

        SubcontractorPrice.SetFilter("Vendor No.", '<>%1', '');
        SubcontractorPrice.SetFilter("Item No.", '<>%1', '');
        if not SubcontractorPrice.IsEmpty() then
            exit(true);

        exit(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"));
    end;

    internal procedure LogPurchaseOrderLineCreated(PurchaseLine: Record "Purchase Line")
    begin
        if IsSubcontractingPurchaseOrderLine(PurchaseLine) then
            LogUptake(Enum::"Feature Uptake Status"::Used);
    end;

    internal procedure IsSubcontractingPurchaseOrderLine(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        if PurchaseLine.IsTemporary() then
            exit(false);
        if (PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order) or
           (PurchaseLine.Type <> PurchaseLine.Type::Item) or (PurchaseLine."No." = '') or
           (PurchaseLine.Quantity <= 0) or (PurchaseLine."Prod. Order No." = '') or
           (PurchaseLine."Operation No." = '')
        then
            exit(false);

        ProdOrderRoutingLine.SetLoadFields("Work Center No.");
        if not ProdOrderRoutingLine.Get(
            "Production Order Status"::Released, PurchaseLine."Prod. Order No.",
            PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            exit(false);

        WorkCenter.SetLoadFields("Subcontractor No.");
        if not WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
            exit(false);
        exit(WorkCenter."Subcontractor No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertWorkCenter(var Rec: Record "Work Center")
    begin
        LogWorkCenterSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyWorkCenter(var Rec: Record "Work Center")
    begin
        LogWorkCenterSetup(Rec);
    end;

    local procedure LogWorkCenterSetup(WorkCenter: Record "Work Center")
    begin
        if WorkCenter.IsTemporary() or (WorkCenter."Subcontractor No." = '') then
            exit;

        LogUptake(Enum::"Feature Uptake Status"::"Set up");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Subcontractor Price", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertSubcontractorPrice(var Rec: Record "Subcontractor Price")
    begin
        LogSubcontractorPriceSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Subcontractor Price", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifySubcontractorPrice(var Rec: Record "Subcontractor Price")
    begin
        LogSubcontractorPriceSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Subcontractor Price", OnAfterRenameEvent, '', false, false)]
    local procedure OnAfterRenameSubcontractorPrice(var Rec: Record "Subcontractor Price")
    begin
        LogSubcontractorPriceSetup(Rec);
    end;

    local procedure LogSubcontractorPriceSetup(SubcontractorPrice: Record "Subcontractor Price")
    begin
        if SubcontractorPrice.IsTemporary() or
           (SubcontractorPrice."Vendor No." = '') or (SubcontractorPrice."Item No." = '')
        then
            exit;

        LogUptake(Enum::"Feature Uptake Status"::"Set up");
    end;
}
