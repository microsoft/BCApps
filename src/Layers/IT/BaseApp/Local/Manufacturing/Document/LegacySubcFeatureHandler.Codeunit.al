#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Document;
using System.Apps;
using System.Environment.Configuration;

codeunit 99008501 "Legacy Subc. Feature Handler"
{
    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    var
        ITMigrationAppIdTok: Label '6d51d1f2-2b87-4e3a-bf5e-c27682fa0320', Locked = true;
        SubcontractingAppIdTok: Label '1f32a50d-0057-4b95-b5df-cc04d7e89470', Locked = true;
        SubcontractingAppInstalledErr: Label 'Cannot activate legacy subcontracting while the Subcontracting app is installed. Use the Subcontracting app features instead.';
        OpenSubcontractingTransfersExistErr: Label 'There are still open transfer orders with WIP Items. All subcontracting transfer orders must be completed before disabling Legacy Subcontracting.';
        OpenWIPPurchaseOrdersExistErr: Label 'There are still open purchase orders with WIP Items. All purchase orders with WIP Items must be completed before disabling Legacy Subcontracting.';
        InstallSubcontractingAppQst: Label 'The Subcontracting app is required to disable Legacy Subcontracting. Do you want to install it now?';
        InstallITMigrationAppQst: Label 'The IT Subcontracting Migration app is needed to migrate your data. Do you want to install it now?';

    /// <summary>
    /// Returns whether Legacy Subcontracting is enabled in Manufacturing Setup.
    /// </summary>
    internal procedure IsLegacySubcontractingEnabled(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then
            exit(false);
        exit(ManufacturingSetup."Legacy Subcontracting");
    end;

    /// <summary>
    /// Checks whether Legacy Subcontracting can be disabled and raises an error if the preconditions are not met.
    /// When a required app is missing, it offers to install it inline.
    /// </summary>
    procedure CheckCanDisableLegacySubcontracting()
    begin
        CanDisableLegacySubcontracting();
    end;

    /// <summary>
    /// Checks whether Legacy Subcontracting can be disabled and raises an error if the preconditions are not met.
    /// When a required app is missing, it offers to install it inline and returns false so the caller does not disable
    /// Legacy Subcontracting - after the install completes and the session reloads, the user runs the disable action again
    /// (installing one app per run until both are present and migration proceeds).
    /// Returns true only when all prerequisites are met and disabling Legacy Subcontracting can proceed.
    /// </summary>
    internal procedure CanDisableLegacySubcontracting(): Boolean
    begin
        if OpenWIPTransfersExist() then
            Error(OpenSubcontractingTransfersExistErr);

        if OpenWIPPurchaseLinesExist() then
            Error(OpenWIPPurchaseOrdersExistErr);

        if not IsSubcontractingAppInstalled() then begin
            OfferToInstallApp(SubcontractingAppIdTok, InstallSubcontractingAppQst);
            exit(false);
        end;

        if DatabaseHasLegacySubcontractingData() then
            if not IsITMigrationAppInstalled() then begin
                OfferToInstallApp(ITMigrationAppIdTok, InstallITMigrationAppQst);
                exit(false);
            end;

        exit(true);
    end;

    /// <summary>
    /// Offers to install a required app inline. If the user accepts, the app is installed and the session is scheduled to reload.
    /// </summary>
    local procedure OfferToInstallApp(AppId: Text; InstallQst: Text)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        if Confirm(InstallQst, true) then
            ExtensionManagement.InstallMarketplaceExtension(AppId);
    end;

    /// <summary>
    /// Checks whether Legacy Subcontracting can be enabled and raises an error if the preconditions are not met.
    /// </summary>
    procedure CheckCanEnableLegacySubcontracting()
    begin
        if IsSubcontractingAppInstalled() then
            Error(SubcontractingAppInstalledErr);
    end;

    /// <summary>
    /// Returns whether the database contains Legacy Subcontracting data based on the presence of subcontracting purchase orders, subcontracting transfer orders, WIP Item related data, capacity ledger entries, or subcontracting prices.
    /// </summary>
    internal procedure DatabaseHasLegacySubcontractingData(): Boolean
    begin
        if SubcontractingPurchaseOrdersExist() then
            exit(true);

        if SubcontractingTransferOrdersExist() then
            exit(true);

        if WIPItemCapacityLedgerEntriesExist() then
            exit(true);

        if OpenWIPTransfersExist() then
            exit(true);

        if OpenWIPPurchaseLinesExist() then
            exit(true);

        if SubcontractingPricesExist() then
            exit(true);

        if WIPItemProdOrderRoutingLinesExist() then
            exit(true);

        if WIPItemRoutingLinesExist() then
            exit(true);

        exit(false);
    end;

    internal procedure MigrateData()
    begin
        OnMigrationSubcontractingData();
    end;

    internal procedure SetLegacySubcontracting(var ManufacturingSetup: Record "Manufacturing Setup"; Enabled: Boolean)
    begin
        if ManufacturingSetup."Legacy Subcontracting" = Enabled then
            exit;

        if not Enabled then begin
            if not CanDisableLegacySubcontracting() then
                exit;
            if DatabaseHasLegacySubcontractingData() then
                MigrateData();
        end else
            CheckCanEnableLegacySubcontracting();

        ManufacturingSetup."Legacy Subcontracting" := Enabled;
        ManufacturingSetup.Modify(true);

        RefreshApplicationAreaSetup();
        RestartSession();
    end;

    local procedure RefreshApplicationAreaSetup()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ExperienceTier: Text;
    begin
        if ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier) then
            if ExperienceTier = ExperienceTierSetup.FieldCaption(Custom) then
                exit;

        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    local procedure IsSubcontractingAppInstalled() Result: Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        Result := ExtensionManagement.IsInstalledByAppId(SubcontractingAppIdTok);
        OnCheckIsSubcontractingAppInstalled(Result);
        exit(Result);
    end;

    local procedure IsITMigrationAppInstalled() Result: Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        Result := ExtensionManagement.IsInstalledByAppId(ITMigrationAppIdTok);
        OnCheckIsITMigrationAppInstalled(Result);
        exit(Result);
    end;

    local procedure OpenWIPTransfersExist(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("WIP Item", true);
        TransferLine.SetFilter("WIP Outstanding Qty.", '<>%1', 0);
        exit(not TransferLine.IsEmpty());
    end;

    local procedure SubcontractingPurchaseOrdersExist(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>%1', 0);
        exit(not PurchaseLine.IsEmpty());
    end;

    local procedure SubcontractingTransferOrdersExist(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetFilter("Prod. Order No.", '<>%1', '');
        exit(not TransferLine.IsEmpty());
    end;

    local procedure OpenWIPPurchaseLinesExist(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("WIP Item", true);
        exit(not PurchaseLine.IsEmpty());
    end;

#if not CLEAN28
    local procedure WIPItemCapacityLedgerEntriesExist(): Boolean
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetCurrentKey("Subcontr. Purch. Order No.", "Subcontr. Purch. Order Line");
        CapacityLedgerEntry.SetFilter("Subcontractor No.", '<>%1', '');
        CapacityLedgerEntry.SetFilter("Subcontr. Purch. Order No.", '<>%1', '');
        CapacityLedgerEntry.SetFilter("WIP Item Qty.", '<>%1', 0);
        exit(not CapacityLedgerEntry.IsEmpty());
    end;

    local procedure SubcontractingPricesExist(): Boolean
    var
        SubcontractingPrice: Record "Subcontractor Prices";
    begin
        exit(not SubcontractingPrice.IsEmpty());
    end;
#endif

    local procedure WIPItemProdOrderRoutingLinesExist(): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("WIP Item", true);
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        exit(not ProdOrderRoutingLine.IsEmpty());
    end;

    local procedure WIPItemRoutingLinesExist(): Boolean
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("WIP Item", true);
        exit(not RoutingLine.IsEmpty());
    end;

    internal procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;

    [InternalEvent(false)]
    local procedure OnCheckIsITMigrationAppInstalled(var Result: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCheckIsSubcontractingAppInstalled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrationSubcontractingData()
    begin
    end;
}
#endif
