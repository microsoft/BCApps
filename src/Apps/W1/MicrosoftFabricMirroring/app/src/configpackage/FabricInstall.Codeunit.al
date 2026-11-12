namespace Microsoft.FabricExport;

using System.Environment.Configuration;
using System.Fabric;
using System.Media;
using System.Upgrade;

codeunit 48522 "Fabric Install"
{
    Subtype = Install;
    Access = Internal;
    trigger OnInstallAppPerCompany()
    var
        FabricUpgrade: Codeunit "Fabric Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if EnsureMicrosoftPackages() then
            if not UpgradeTag.HasUpgradeTag(FabricUpgrade.GetLegacyPackageMigrationTag()) then
                UpgradeTag.SetUpgradeTag(FabricUpgrade.GetLegacyPackageMigrationTag());
        RegisterGuidedSetup();
    end;

    local procedure RegisterGuidedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        GuidedExperience.InsertAssistedSetup(GuidedSetupTitleLbl, GuidedSetupShortTitleLbl, GuidedSetupDescriptionLbl, 10,
            ObjectType::Page, Page::"Fabric Platform Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Connect, '');
    end;

    internal procedure EnsureMicrosoftPackages(): Boolean
    begin
        RegisterMicrosoftPackages();
        exit(MigrateLegacyMicrosoftPackage());
    end;

    internal procedure RegisterMicrosoftPackages()
    var
        FabricConfigPackageMgt: Codeunit "Fabric Config Package Mgt";
        FinanceTableIds: List of [Integer];
        InventoryTableIds: List of [Integer];
        InventoryValuationTableIds: List of [Integer];
        ManufacturingTableIds: List of [Integer];
        ProjectsTableIds: List of [Integer];
        PurchaseTableIds: List of [Integer];
        SalesTableIds: List of [Integer];
        SubscriptionBillingTableIds: List of [Integer];
        SustainabilityTableIds: List of [Integer];
    begin
        FinanceTableIds.Add(15);
        FinanceTableIds.Add(17);
        FinanceTableIds.Add(18);
        FinanceTableIds.Add(21);
        FinanceTableIds.Add(23);
        FinanceTableIds.Add(25);
        FinanceTableIds.Add(95);
        FinanceTableIds.Add(96);
        FinanceTableIds.Add(98);
        FinanceTableIds.Add(112);
        FinanceTableIds.Add(122);
        FinanceTableIds.Add(348);
        FinanceTableIds.Add(379);
        FinanceTableIds.Add(380);
        FinanceTableIds.Add(570);
        FinanceTableIds.Add(36951);
        FinanceTableIds.Add(36952);
        FinanceTableIds.Add(36953);
        FinanceTableIds.Add(36954);
        FinanceTableIds.Add(36955);

        InventoryTableIds.Add(14);
        InventoryTableIds.Add(18);
        InventoryTableIds.Add(23);
        InventoryTableIds.Add(27);
        InventoryTableIds.Add(32);
        InventoryTableIds.Add(37);
        InventoryTableIds.Add(39);
        InventoryTableIds.Add(98);
        InventoryTableIds.Add(246);
        InventoryTableIds.Add(348);
        InventoryTableIds.Add(900);
        InventoryTableIds.Add(901);
        InventoryTableIds.Add(1003);
        InventoryTableIds.Add(5406);
        InventoryTableIds.Add(5407);
        InventoryTableIds.Add(5722);
        InventoryTableIds.Add(5741);
        InventoryTableIds.Add(5767);
        InventoryTableIds.Add(5802);
        InventoryTableIds.Add(5902);
        InventoryTableIds.Add(7160);
        InventoryTableIds.Add(7300);
        InventoryTableIds.Add(7311);
        InventoryTableIds.Add(7312);
        InventoryTableIds.Add(7354);
        InventoryTableIds.Add(36951);
        InventoryTableIds.Add(36952);
        InventoryTableIds.Add(36954);
        InventoryTableIds.Add(99000829);

        InventoryValuationTableIds.Add(14);
        InventoryValuationTableIds.Add(27);
        InventoryValuationTableIds.Add(98);
        InventoryValuationTableIds.Add(348);
        InventoryValuationTableIds.Add(5722);
        InventoryValuationTableIds.Add(5802);
        InventoryValuationTableIds.Add(36951);
        InventoryValuationTableIds.Add(36952);
        InventoryValuationTableIds.Add(36954);

        ManufacturingTableIds.Add(14);
        ManufacturingTableIds.Add(27);
        ManufacturingTableIds.Add(32);
        ManufacturingTableIds.Add(98);
        ManufacturingTableIds.Add(348);
        ManufacturingTableIds.Add(5405);
        ManufacturingTableIds.Add(5406);
        ManufacturingTableIds.Add(5407);
        ManufacturingTableIds.Add(5409);
        ManufacturingTableIds.Add(5410);
        ManufacturingTableIds.Add(5722);
        ManufacturingTableIds.Add(5802);
        ManufacturingTableIds.Add(5832);
        ManufacturingTableIds.Add(5896);
        ManufacturingTableIds.Add(36951);
        ManufacturingTableIds.Add(36952);
        ManufacturingTableIds.Add(36954);
        ManufacturingTableIds.Add(99000754);
        ManufacturingTableIds.Add(99000756);
        ManufacturingTableIds.Add(99000757);
        ManufacturingTableIds.Add(99000758);
        ManufacturingTableIds.Add(99000763);
        ManufacturingTableIds.Add(99000765);
        ManufacturingTableIds.Add(99000777);

        ProjectsTableIds.Add(15);
        ProjectsTableIds.Add(18);
        ProjectsTableIds.Add(27);
        ProjectsTableIds.Add(39);
        ProjectsTableIds.Add(98);
        ProjectsTableIds.Add(156);
        ProjectsTableIds.Add(167);
        ProjectsTableIds.Add(169);
        ProjectsTableIds.Add(348);
        ProjectsTableIds.Add(1001);
        ProjectsTableIds.Add(1003);
        ProjectsTableIds.Add(5722);
        ProjectsTableIds.Add(36951);
        ProjectsTableIds.Add(36952);
        ProjectsTableIds.Add(36954);

        PurchaseTableIds.Add(13);
        PurchaseTableIds.Add(14);
        PurchaseTableIds.Add(15);
        PurchaseTableIds.Add(23);
        PurchaseTableIds.Add(27);
        PurchaseTableIds.Add(32);
        PurchaseTableIds.Add(38);
        PurchaseTableIds.Add(39);
        PurchaseTableIds.Add(98);
        PurchaseTableIds.Add(122);
        PurchaseTableIds.Add(123);
        PurchaseTableIds.Add(124);
        PurchaseTableIds.Add(125);
        PurchaseTableIds.Add(156);
        PurchaseTableIds.Add(167);
        PurchaseTableIds.Add(348);
        PurchaseTableIds.Add(5722);
        PurchaseTableIds.Add(5802);
        PurchaseTableIds.Add(5832);
        PurchaseTableIds.Add(6635);
        PurchaseTableIds.Add(7132);
        PurchaseTableIds.Add(7134);
        PurchaseTableIds.Add(36951);
        PurchaseTableIds.Add(36952);
        PurchaseTableIds.Add(36954);

        SalesTableIds.Add(13);
        SalesTableIds.Add(14);
        SalesTableIds.Add(15);
        SalesTableIds.Add(18);
        SalesTableIds.Add(27);
        SalesTableIds.Add(32);
        SalesTableIds.Add(36);
        SalesTableIds.Add(37);
        SalesTableIds.Add(98);
        SalesTableIds.Add(112);
        SalesTableIds.Add(113);
        SalesTableIds.Add(114);
        SalesTableIds.Add(115);
        SalesTableIds.Add(156);
        SalesTableIds.Add(167);
        SalesTableIds.Add(169);
        SalesTableIds.Add(348);
        SalesTableIds.Add(5050);
        SalesTableIds.Add(5091);
        SalesTableIds.Add(5092);
        SalesTableIds.Add(5093);
        SalesTableIds.Add(5094);
        SalesTableIds.Add(5722);
        SalesTableIds.Add(5802);
        SalesTableIds.Add(6635);
        SalesTableIds.Add(7132);
        SalesTableIds.Add(7134);
        SalesTableIds.Add(36951);
        SalesTableIds.Add(36952);
        SalesTableIds.Add(36954);

        SubscriptionBillingTableIds.Add(13);
        SubscriptionBillingTableIds.Add(18);
        SubscriptionBillingTableIds.Add(23);
        SubscriptionBillingTableIds.Add(27);
        SubscriptionBillingTableIds.Add(98);
        SubscriptionBillingTableIds.Add(348);
        SubscriptionBillingTableIds.Add(5722);
        SubscriptionBillingTableIds.Add(8019);
        SubscriptionBillingTableIds.Add(8052);
        SubscriptionBillingTableIds.Add(8063);
        SubscriptionBillingTableIds.Add(8066);
        SubscriptionBillingTableIds.Add(8072);
        SubscriptionBillingTableIds.Add(36951);
        SubscriptionBillingTableIds.Add(36952);
        SubscriptionBillingTableIds.Add(36954);

        SustainabilityTableIds.Add(9);
        SustainabilityTableIds.Add(98);
        SustainabilityTableIds.Add(348);
        SustainabilityTableIds.Add(5200);
        SustainabilityTableIds.Add(5203);
        SustainabilityTableIds.Add(5207);
        SustainabilityTableIds.Add(5222);
        SustainabilityTableIds.Add(5223);
        SustainabilityTableIds.Add(5714);
        SustainabilityTableIds.Add(6210);
        SustainabilityTableIds.Add(6211);
        SustainabilityTableIds.Add(6212);
        SustainabilityTableIds.Add(6216);
        SustainabilityTableIds.Add(6219);
        SustainabilityTableIds.Add(6226);
        SustainabilityTableIds.Add(36951);
        SustainabilityTableIds.Add(36952);
        SustainabilityTableIds.Add(36954);

        FabricConfigPackageMgt.RegisterPackage('MS-FIN', 'Microsoft Finance', '1.0', FinanceTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-INV', 'Microsoft Inventory', '1.0', InventoryTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-INV-VAL', 'Microsoft Inventory Valuation', '1.0', InventoryValuationTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-MFG', 'Microsoft Manufacturing', '1.0', ManufacturingTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-PROJ', 'Microsoft Projects', '1.0', ProjectsTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-PUR', 'Microsoft Purchase', '1.0', PurchaseTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-SALES', 'Microsoft Sales', '1.0', SalesTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-SUB-BILL', 'Microsoft Subscription Billing', '1.0', SubscriptionBillingTableIds);
        FabricConfigPackageMgt.RegisterPackage('MS-SUST', 'Microsoft Sustainability', '1.0', SustainabilityTableIds);
    end;

    internal procedure MigrateLegacyMicrosoftPackage(): Boolean
    var
        LegacyPackage: Record "Fabric Config Package";
        PackageCodes: List of [Code[20]];
    begin
        if not LegacyPackage.Get('MS-STD') then
            exit(true);

        PackageCodes.Add('MS-FIN');
        PackageCodes.Add('MS-INV');
        PackageCodes.Add('MS-INV-VAL');
        PackageCodes.Add('MS-MFG');
        PackageCodes.Add('MS-PROJ');
        PackageCodes.Add('MS-PUR');
        PackageCodes.Add('MS-SALES');
        PackageCodes.Add('MS-SUB-BILL');
        PackageCodes.Add('MS-SUST');
        exit(MigrateLegacyPackage(LegacyPackage, PackageCodes));
    end;

    local procedure MigrateLegacyPackage(var LegacyPackage: Record "Fabric Config Package"; PackageCodes: List of [Code[20]]): Boolean
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPackageMgt: Codeunit "Fabric Config Package Mgt";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        TableIds: List of [Integer];
        Dimensions: Dictionary of [Text, Text];
        PackageCode: Code[20];
        RequiredTableCount: Integer;
    begin
        if not LegacyPackage.Active then begin
            LegacyPackage.Delete(true);
            exit(true);
        end;

        TenantFabricTables.LockTable();
        foreach PackageCode in PackageCodes do begin
            PackageLine.SetRange("Package Code", PackageCode);
            if PackageLine.FindSet() then
                repeat
                    if not TableIds.Contains(PackageLine."Table ID") then
                        TableIds.Add(PackageLine."Table ID");
                until PackageLine.Next() = 0;
        end;

        // A shortage must leave the legacy selection intact so migration can be retried.
        RequiredTableCount := GetMigrationTableCount(LegacyPackage, TableIds);
        if RequiredTableCount > FabricPlatformMgt.MaxTableCount() then begin
            Dimensions := Telemetry.GetDimensions();
            Dimensions.Add('PackageCode', LegacyPackage.Code);
            Dimensions.Add('RequiredTableCount', Format(RequiredTableCount));
            Dimensions.Add('MaxTableCount', Format(FabricPlatformMgt.MaxTableCount()));
            Session.LogMessage('0000WCC', 'Legacy config package migration deferred: the replacement packages would exceed the table export limit. The legacy package remains unchanged.',
                Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
            exit(false);
        end;

        // Retained rows must have replacement claims before their legacy claim is released.
        foreach PackageCode in PackageCodes do begin
            PackageLine.SetRange("Package Code", PackageCode);
            if PackageLine.FindSet() then
                repeat
                    if TenantFabricTables.Get(PackageLine."Table ID") then
                        FabricPlatformMgt.ClaimTable(PackageLine."Table ID", "Fabric Table Claim Source"::Package, PackageCode);
                until PackageLine.Next() = 0;
        end;
        if LegacyPackage.Active then
            FabricConfigPackageMgt.Deactivate(LegacyPackage);
        LegacyPackage.Delete(true);

        foreach PackageCode in PackageCodes do
            ActivatePackageIfNeeded(PackageCode);
        exit(true);
    end;

    local procedure GetMigrationTableCount(LegacyPackage: Record "Fabric Config Package"; TableIds: List of [Integer]) RequiredTableCount: Integer
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        TableId: Integer;
    begin
        RequiredTableCount := FabricPlatformMgt.SelectedTableCount();
        foreach TableId in TableIds do
            if not TenantFabricTables.Get(TableId) then
                RequiredTableCount += 1;

        if not LegacyPackage.Active then
            exit;

        PackageLine.SetRange("Package Code", LegacyPackage.Code);
        if PackageLine.FindSet() then
            repeat
                if not TableIds.Contains(PackageLine."Table ID") then
                    if TenantFabricTables.Get(PackageLine."Table ID") then
                        if not FabricPlatformMgt.IsClaimedByOthers(PackageLine."Table ID", "Fabric Table Claim Source"::Package, LegacyPackage.Code) then
                            RequiredTableCount -= 1;
            until PackageLine.Next() = 0;
    end;

    local procedure ActivatePackageIfNeeded(PackageCode: Code[20])
    var
        Package: Record "Fabric Config Package";
        FabricConfigPackageMgt: Codeunit "Fabric Config Package Mgt";
    begin
        if not Package.Get(PackageCode) then
            exit;
        if not Package.Active then
            FabricConfigPackageMgt.Activate(Package);
    end;

    var
        GuidedSetupTitleLbl: Label 'Connect to Microsoft Fabric (Preview)';
        GuidedSetupShortTitleLbl: Label 'Fabric Mirroring (Preview)';
        GuidedSetupDescriptionLbl: Label 'Connect your environment to Microsoft Fabric, grant access, and choose the companies and tables to synchronize.';
}
