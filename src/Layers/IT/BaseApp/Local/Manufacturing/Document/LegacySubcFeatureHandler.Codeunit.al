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
using System.Environment;
using System.Environment.Configuration;

codeunit 99008501 "Legacy Subc. Feature Handler"
{
    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    var
        ITMigrationAppIdTok: Label '6d51d1f2-2b87-4e3a-bf5e-c27682fa0320', Locked = true;
        ITMigrationAppNotInstalledErr: Label 'The app "IT Subcontracting Migration" must be installed before you can disable Legacy Subcontracting. Please install the app first and then use the dedicated action "Disable Legacy Subcontracting" to disable Legacy Subcontracting and migrate to the new subcontracting app.';
        SubcontractingAppIdTok: Label '1f32a50d-0057-4b95-b5df-cc04d7e89470', Locked = true;
        SubcontractingAppNotInstalledErr: Label 'The app "Subcontracting App" must be installed before you can disable Legacy Subcontracting. Please install the app first before migrating to the new subcontracting app.';
        OpenSubcontractingTransfersExistErr: Label 'There are still open transfer orders with WIP Items. All subcontracting transfer orders must be completed before disabling Legacy Subcontracting.';
        OpenWIPPurchaseOrdersExistErr: Label 'There are still open subcontracting purchase orders. All subcontracting purchase orders must be completed before disabling Legacy Subcontracting.';
        MigrationNotAllowedInProductionErr: Label 'To help you migrate safely, disabling Legacy Subcontracting and moving to the Subcontracting app is currently limited to sandbox environments. Test the migration in a sandbox copy of this environment first to validate the transition. Production environments will be enabled in a future release.';

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

    local procedure IsMigrationAllowedInCurrentEnvironment(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSandbox());
    end;

    /// <summary>
    /// Checks whether Legacy Subcontracting can be disabled and raises an error if the preconditions are not met.
    /// </summary>
    procedure CheckCanDisableLegacySubcontracting()
    begin
        if not IsMigrationAllowedInCurrentEnvironment() then
            Error(MigrationNotAllowedInProductionErr);

        if OpenSubcontractingTransfersExist() then
            Error(OpenSubcontractingTransfersExistErr);

        if OpenWIPPurchaseLinesExist() then
            Error(OpenWIPPurchaseOrdersExistErr);

        if not IsSubcontractingAppInstalled() then
            Error(SubcontractingAppNotInstalledErr);

        if DatabaseHasLegacySubcontractingData() then
            if not IsITMigrationAppInstalled() then
                Error(ITMigrationAppNotInstalledErr);
    end;

    /// <summary>
    /// Returns whether the database contains Legacy Subcontracting data based on the presence of WIP Item related data in open transfer orders, open purchase orders, or capacity ledger entries.
    /// </summary>
    internal procedure DatabaseHasLegacySubcontractingData(): Boolean
    begin
        if WIPItemCapacityLedgerEntriesExist() then
            exit(true);

        if OpenSubcontractingTransfersExist() then
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
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ManufacturingSetup."Legacy Subcontracting" = Enabled then
            exit;

        if not Enabled then begin
            CheckCanDisableLegacySubcontracting();
            if DatabaseHasLegacySubcontractingData() then
                MigrateData();
        end;

        ManufacturingSetup."Legacy Subcontracting" := Enabled;
        ManufacturingSetup.Modify(true);

        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
        RestartSession();
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

    local procedure OpenSubcontractingTransfersExist(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("WIP Item", true);
        TransferLine.SetFilter("WIP Outstanding Qty.", '<>%1', 0);
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
