namespace Microsoft.FabricExport;

using System.Environment.Configuration;
using System.Media;

codeunit 48522 "Fabric Install"
{
    Subtype = Install;
    Access = Internal;
    trigger OnInstallAppPerCompany()
    begin
        EnsureMsStdPackage();
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

    internal procedure EnsureMsStdPackage()
    var
        FabricConfigPackageMgt: Codeunit "Fabric Config Package Mgt";
        TableIds: List of [Integer];
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
        FabricConfigPackageMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIds);
    end;

    var
        GuidedSetupTitleLbl: Label 'Connect to Microsoft Fabric';
        GuidedSetupShortTitleLbl: Label 'Fabric Export';
        GuidedSetupDescriptionLbl: Label 'Connect your environment to Microsoft Fabric, grant access, and choose the companies and tables to synchronize.';
}
