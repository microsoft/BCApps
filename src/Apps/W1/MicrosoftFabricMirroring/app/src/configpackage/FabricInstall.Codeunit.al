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
        // Standard Microsoft BC tables — full curated set for Fabric / Power BI analytics.
        // Per Company is derived automatically by RegisterPackage from Table Metadata.
        TableIds.Add(3);        // Payment Terms
        TableIds.Add(4);        // Currency
        TableIds.Add(9);        // Country/Region
        TableIds.Add(10);       // Shipment Method
        TableIds.Add(13);       // Salesperson/Purchaser
        TableIds.Add(14);       // Location
        TableIds.Add(15);       // G/L Account
        TableIds.Add(17);       // G/L Entry
        TableIds.Add(18);       // Customer
        TableIds.Add(21);       // Cust. Ledger Entry
        TableIds.Add(23);       // Vendor
        TableIds.Add(25);       // Vendor Ledger Entry
        TableIds.Add(27);       // Item
        TableIds.Add(32);       // Item Ledger Entry
        TableIds.Add(36);       // Sales Header
        TableIds.Add(37);       // Sales Line
        TableIds.Add(38);       // Purchase Header
        TableIds.Add(39);       // Purchase Line
        TableIds.Add(79);       // Company Information
        TableIds.Add(84);       // Acc. Schedule Name
        TableIds.Add(85);       // Acc. Schedule Line
        TableIds.Add(90);       // BOM Component
        TableIds.Add(91);       // User Setup
        TableIds.Add(92);       // Customer Posting Group
        TableIds.Add(93);       // Vendor Posting Group
        TableIds.Add(94);       // Inventory Posting Group
        TableIds.Add(95);       // G/L Budget Name
        TableIds.Add(96);       // G/L Budget Entry
        TableIds.Add(98);       // General Ledger Setup
        TableIds.Add(99);       // Item Vendor
        TableIds.Add(110);      // Sales Shipment Header
        TableIds.Add(111);      // Sales Shipment Line
        TableIds.Add(112);      // Sales Invoice Header
        TableIds.Add(113);      // Sales Invoice Line
        TableIds.Add(114);      // Sales Cr.Memo Header
        TableIds.Add(115);      // Sales Cr.Memo Line
        TableIds.Add(120);      // Purch. Rcpt. Header
        TableIds.Add(121);      // Purch. Rcpt. Line
        TableIds.Add(122);      // Purch. Inv. Header
        TableIds.Add(123);      // Purch. Inv. Line
        TableIds.Add(124);      // Purch. Cr. Memo Hdr.
        TableIds.Add(125);      // Purch. Cr. Memo Line
        TableIds.Add(152);      // Resource Group
        TableIds.Add(156);      // Resource
        TableIds.Add(160);      // Res. Capacity Entry
        TableIds.Add(167);      // Job
        TableIds.Add(169);      // Job Ledger Entry
        TableIds.Add(179);      // Reversal Entry
        TableIds.Add(181);      // Posted Gen. Journal Line
        TableIds.Add(182);      // Posted Gen. Journal Batch
        TableIds.Add(184);      // Payment Rec. Related Entry
        TableIds.Add(185);      // Pmt. Rec. Applied-to Entry
        TableIds.Add(186);      // Exch. Rate Adjmt. Ledg. Entry
        TableIds.Add(189);      // VAT Setup
        TableIds.Add(200);      // Work Type
        TableIds.Add(203);      // Res. Ledger Entry
        TableIds.Add(204);      // Unit of Measure
        TableIds.Add(205);      // Resource Unit of Measure
        TableIds.Add(208);      // Job Posting Group
        TableIds.Add(213);      // Alt. Cust. VAT Reg.
        TableIds.Add(220);      // Business Unit
        TableIds.Add(222);      // Ship-to Address
        TableIds.Add(224);      // Order Address
        TableIds.Add(230);      // Source Code
        TableIds.Add(231);      // Reason Code
        TableIds.Add(240);      // Resource Register
        TableIds.Add(241);      // Job Register
        TableIds.Add(242);      // Source Code Setup
        TableIds.Add(246);      // Requisition Line
        TableIds.Add(250);      // Gen. Business Posting Group
        TableIds.Add(251);      // Gen. Product Posting Group
        TableIds.Add(252);      // General Posting Setup
        TableIds.Add(253);      // G/L Entry - VAT Entry Link
        TableIds.Add(254);      // VAT Entry
        TableIds.Add(255);      // VAT Statement Template
        TableIds.Add(256);      // VAT Statement Line
        TableIds.Add(257);      // VAT Statement Name
        TableIds.Add(258);      // Transaction Type
        TableIds.Add(259);      // Transport Method
        TableIds.Add(260);      // Tariff Number
        TableIds.Add(270);      // Bank Account
        TableIds.Add(271);      // Bank Account Ledger Entry
        TableIds.Add(272);      // Check Ledger Entry
        TableIds.Add(281);      // Phys. Inventory Ledger Entry
        TableIds.Add(284);      // Area
        TableIds.Add(285);      // Transaction Specification
        TableIds.Add(287);      // Customer Bank Account
        TableIds.Add(288);      // Vendor Bank Account
        TableIds.Add(289);      // Payment Method
        TableIds.Add(291);      // Shipping Agent
        TableIds.Add(292);      // Reminder Terms
        TableIds.Add(293);      // Reminder Level
        TableIds.Add(294);      // Reminder Text
        TableIds.Add(295);      // Reminder Header
        TableIds.Add(296);      // Reminder Line
        TableIds.Add(297);      // Issued Reminder Header
        TableIds.Add(298);      // Issued Reminder Line
        TableIds.Add(299);      // Reminder Comment Line
        TableIds.Add(300);      // Reminder/Fin. Charge Entry
        TableIds.Add(301);      // Finance Charge Text
        TableIds.Add(302);      // Finance Charge Memo Header
        TableIds.Add(303);      // Finance Charge Memo Line
        TableIds.Add(304);      // Issued Fin. Charge Memo Header
        TableIds.Add(305);      // Issued Fin. Charge Memo Line
        TableIds.Add(306);      // Fin. Charge Comment Line
        TableIds.Add(308);      // No. Series
        TableIds.Add(309);      // No. Series Line
        TableIds.Add(310);      // No. Series Relationship
        TableIds.Add(311);      // Sales & Receivables Setup
        TableIds.Add(312);      // Purchases & Payables Setup
        TableIds.Add(313);      // Inventory Setup
        TableIds.Add(314);      // Resources Setup
        TableIds.Add(315);      // Jobs Setup
        TableIds.Add(317);      // Payable Vendor Ledger Entry
        TableIds.Add(318);      // Tax Area
        TableIds.Add(319);      // Tax Area Line
        TableIds.Add(320);      // Tax Jurisdiction
        TableIds.Add(321);      // Tax Group
        TableIds.Add(322);      // Tax Detail
        TableIds.Add(323);      // VAT Business Posting Group
        TableIds.Add(324);      // VAT Product Posting Group
        TableIds.Add(325);      // VAT Posting Setup
        TableIds.Add(326);      // Tax Setup
        TableIds.Add(330);      // Currency Exchange Rate
        TableIds.Add(333);      // Column Layout Name
        TableIds.Add(334);      // Column Layout
        TableIds.Add(336);      // Tracking Specification
        TableIds.Add(337);      // Reservation Entry
        TableIds.Add(339);      // Item Application Entry
        TableIds.Add(340);      // Customer Discount Group
        TableIds.Add(341);      // Item Discount Group
        TableIds.Add(348);      // Dimension
        TableIds.Add(349);      // Dimension Value
        TableIds.Add(350);      // Dimension Combination
        TableIds.Add(351);      // Dimension Value Combination
        TableIds.Add(352);      // Default Dimension
        TableIds.Add(354);      // Default Dimension Priority
        TableIds.Add(363);      // Analysis View
        TableIds.Add(379);      // Detailed Cust. Ledg. Entry
        TableIds.Add(380);      // Detailed Vendor Ledg. Entry
        TableIds.Add(402);      // Change Log Setup
        TableIds.Add(403);      // Change Log Setup (Table)
        TableIds.Add(404);      // Change Log Setup (Field)
        TableIds.Add(454);      // Approval Entry
        TableIds.Add(455);      // Approval Comment Line
        TableIds.Add(456);      // Posted Approval Entry
        TableIds.Add(457);      // Posted Approval Comment Line
        TableIds.Add(458);      // Overdue Approval Entry
        TableIds.Add(471);      // Job Queue Category
        TableIds.Add(472);      // Job Queue Entry
        TableIds.Add(477);      // Report Inbox
        TableIds.Add(480);      // Dimension Set Entry
        TableIds.Add(570);      // G/L Account Category
        TableIds.Add(840);      // Cash Flow Forecast
        TableIds.Add(841);      // Cash Flow Account
        TableIds.Add(847);      // Cash Flow Forecast Entry
        TableIds.Add(900);      // Assembly Header
        TableIds.Add(901);      // Assembly Line
        TableIds.Add(1001);     // Job Task
        TableIds.Add(1003);     // Job Planning Line
        TableIds.Add(1850);     // MS - Sales Forecast
        TableIds.Add(1851);     // MS - Sales Forecast Parameter
        TableIds.Add(1853);     // MS - Sales Forecast Setup
        TableIds.Add(2224);     // Remit Address
        TableIds.Add(5050);     // Contact
        TableIds.Add(5051);     // Contact Alt. Address
        TableIds.Add(5053);     // Business Relation
        TableIds.Add(5054);     // Contact Business Relation
        TableIds.Add(5058);     // Contact Industry Group
        TableIds.Add(5091);     // Sales Cycle Stage
        TableIds.Add(5092);     // Opportunity
        TableIds.Add(5093);     // Opportunity Entry
        TableIds.Add(5094);     // Close Opportunity Code
        TableIds.Add(5107);     // Sales Header Archive
        TableIds.Add(5108);     // Sales Line Archive
        TableIds.Add(5109);     // Purchase Header Archive
        TableIds.Add(5110);     // Purchase Line Archive
        TableIds.Add(5200);     // Employee
        TableIds.Add(5203);     // Employee Qualification
        TableIds.Add(5207);     // Employee Absence
        TableIds.Add(5222);     // Employee Ledger Entry
        TableIds.Add(5223);     // Detailed Employee Ledger Entry
        TableIds.Add(5404);     // Item Unit of Measure
        TableIds.Add(5405);     // Production Order
        TableIds.Add(5406);     // Prod. Order Line
        TableIds.Add(5407);     // Prod. Order Component
        TableIds.Add(5409);     // Prod. Order Routing Line
        TableIds.Add(5410);     // Prod. Order Capacity Need
        TableIds.Add(5600);     // Fixed Asset
        TableIds.Add(5601);     // FA Ledger Entry
        TableIds.Add(5604);     // FA Posting Type Setup
        TableIds.Add(5606);     // FA Posting Group
        TableIds.Add(5607);     // FA Class
        TableIds.Add(5612);     // FA Depreciation Book
        TableIds.Add(5617);     // FA Register
        TableIds.Add(5644);     // FA Posting Type
        TableIds.Add(5645);     // FA Date Type
        TableIds.Add(5647);     // FA Matrix Posting Type
        TableIds.Add(5714);     // Responsibility Center
        TableIds.Add(5722);     // Item Category
        TableIds.Add(5740);     // Transfer Header
        TableIds.Add(5741);     // Transfer Line
        TableIds.Add(5744);     // Transfer Shipment Header
        TableIds.Add(5745);     // Transfer Shipment Line
        TableIds.Add(5746);     // Transfer Receipt Header
        TableIds.Add(5747);     // Transfer Receipt Line
        TableIds.Add(5767);     // Warehouse Activity Line
        TableIds.Add(5777);     // Item Reference
        TableIds.Add(5800);     // Item Charge
        TableIds.Add(5802);     // Value Entry
        TableIds.Add(5832);     // Capacity Ledger Entry
        TableIds.Add(5896);     // Inventory Adjmt. Entry (Order)
        TableIds.Add(5900);     // Service Header
        TableIds.Add(5902);     // Service Line
        TableIds.Add(5940);     // Service Item
        TableIds.Add(5990);     // Service Shipment Header
        TableIds.Add(5991);     // Service Shipment Line
        TableIds.Add(5992);     // Service Invoice Header
        TableIds.Add(5993);     // Service Invoice Line
        TableIds.Add(5994);     // Service Cr.Memo Header
        TableIds.Add(5995);     // Service Cr.Memo Line
        TableIds.Add(6210);     // Sustainability Account
        TableIds.Add(6211);     // Sustain. Account Category
        TableIds.Add(6212);     // Sustain. Account Subcategory
        TableIds.Add(6216);     // Sustainability Ledger Entry
        TableIds.Add(6219);     // Sustainability Goal
        TableIds.Add(6226);     // Emission Fee
        TableIds.Add(6505);     // Lot No. Information
        TableIds.Add(6635);     // Return Reason
        TableIds.Add(7132);     // Item Budget Name
        TableIds.Add(7134);     // Item Budget Entry
        TableIds.Add(7160);     // ABC Analysis Setup
        TableIds.Add(7300);     // Zone
        TableIds.Add(7311);     // Warehouse Journal Line
        TableIds.Add(7312);     // Warehouse Entry
        TableIds.Add(7354);     // Bin
        TableIds.Add(7500);     // Item Attribute
        TableIds.Add(7501);     // Item Attribute Value
        TableIds.Add(7505);     // Item Attribute Value Mapping
        TableIds.Add(8019);     // Sub. Contr. Analysis Entry
        TableIds.Add(8052);     // Customer Subscription Contract
        TableIds.Add(8063);     // Vendor Subscription Contract
        TableIds.Add(8066);     // Cust. Sub. Contract Deferral
        TableIds.Add(8072);     // Vend. Sub. Contract Deferral
        TableIds.Add(36951);    // PowerBI Reports Setup
        TableIds.Add(36952);    // 
        TableIds.Add(36953);    // Account Category
        TableIds.Add(36954);    // PowerBI Flat Dim. Set Entry
        TableIds.Add(36955);    // PBI C. Income St. Source Code
        TableIds.Add(99000754); // Work Center
        TableIds.Add(99000756); // Work Center Group
        TableIds.Add(99000757); // Calendar Entry
        TableIds.Add(99000758); // Machine Center
        TableIds.Add(99000763); // Routing Header
        TableIds.Add(99000765); // Manufacturing Setup
        TableIds.Add(99000777); // Routing Link
        TableIds.Add(99000829); // Planning Component
        FabricConfigPackageMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.1', TableIds);
    end;

    var
        GuidedSetupTitleLbl: Label 'Connect to Microsoft Fabric (Preview)';
        GuidedSetupShortTitleLbl: Label 'Fabric Mirroring (Preview)';
        GuidedSetupDescriptionLbl: Label 'Connect your environment to Microsoft Fabric, grant access, and choose the companies and tables to synchronize.';
}
