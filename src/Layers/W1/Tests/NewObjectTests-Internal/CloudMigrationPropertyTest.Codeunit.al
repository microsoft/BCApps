codeunit 135160 "Cloud Migration Property Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplicateDataProperty()
    var
        ALCloudMigration: DotNet ALCloudMigration;
        ListOfTablesToMigrate: List of [Integer];
    begin
        // [SCENARIO] Test that developers do not forget to set the ReplciateData=false property. Only tables that should be cloud migrated from OnPrem should be included.
        // [GIVEN] Cloud migration is enabled
        EnableCloudMigration();

        // [WHEN] The list of tables to cloud migrate is updated
        ALCloudMigration.UpdateCloudMigrationStatus();

        // [THEN] Only expected tables are updated
        GetTablesThatShouldBeCloudMigrated(ListOfTablesToMigrate);
        VerifyOnlyTablesThatShouldBeMigratedAreIncluded(ListOfTablesToMigrate);
    end;

    local procedure EnableCloudMigration()
    var
        IntelligentCloudStatus: Record "Intelligent Cloud Status";
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        if not IntelligentCloud.Get() then
            IntelligentCloud.Insert();

        IntelligentCloud.Get();
        IntelligentCloud.Enabled := true;
        IntelligentCloud.Modify();

        IntelligentCloudStatus.DeleteAll();
    end;

    local procedure VerifyOnlyTablesThatShouldBeMigratedAreIncluded(var ListOfTablesToMigrate: List of [Integer])
    var
        IntelligentCloudStatus: Record "Intelligent Cloud Status";
        TableMetadata: Record "Table Metadata";
        Assert: Codeunit Assert;
        UnexpectedTables: Text;
    begin
        IntelligentCloudStatus.SetRange(IntelligentCloudStatus."Replicate Data", true);
        IntelligentCloudStatus.FindSet();
        repeat
            if not (ListOfTablesToMigrate.Contains(IntelligentCloudStatus."Table Id")) then begin
                TableMetadata.Get(IntelligentCloudStatus."Table Id");
                if (TableMetadata.Name <> 'Certificate') and
                   (TableMetadata.Name <> 'G/L Accounts Equivalence Tool')
                then
                    UnexpectedTables += TableMetadata.Name + ';';
            end;
        until IntelligentCloudStatus.Next() = 0;

        Assert.AreEqual('', UnexpectedTables, 'New tables have been found for cloud migration. Please make sure that the table should be cloud migrated. If yes update the list of included tables below. If no exclude the table by setting ReplicateData property to false.');
    end;

    local procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    var
        CloudMigCountryTables: Codeunit "Cloud Mig Country Tables";
    begin
        ListOfTablesToMigrate.Add(Database::"Alloc. Acc. Manual Override");
        ListOfTablesToMigrate.Add(Database::"Alloc. Account Distribution");
        ListOfTablesToMigrate.Add(Database::"Allocation Account");
        ListOfTablesToMigrate.Add(Database::"Allocation Line");
        ListOfTablesToMigrate.Add(Database::"Allowed Language");
        ListOfTablesToMigrate.Add(Database::"Dispute Status");
        ListOfTablesToMigrate.Add(Database::"Job Journal Template");
        ListOfTablesToMigrate.Add(Database::"Job Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Job Planning Line - Calendar");
        ListOfTablesToMigrate.Add(Database::"Job Planning Line Invoice");
        ListOfTablesToMigrate.Add(Database::"Job Planning Line");
        ListOfTablesToMigrate.Add(Database::"Job Planning Line Archive");
        ListOfTablesToMigrate.Add(Database::"Job Posting Group");
        ListOfTablesToMigrate.Add(Database::"Job Queue Category");
        ListOfTablesToMigrate.Add(Database::"Job Queue Entry Buffer");
        ListOfTablesToMigrate.Add(Database::"Job Register");
        ListOfTablesToMigrate.Add(Database::"Job Responsibility");
        ListOfTablesToMigrate.Add(Database::"Job Task Dimension");
        ListOfTablesToMigrate.Add(Database::"Job Task");
        ListOfTablesToMigrate.Add(Database::"Job Task Archive");
        ListOfTablesToMigrate.Add(Database::"Job Usage Link");
        ListOfTablesToMigrate.Add(Database::"Job WIP Entry");
        ListOfTablesToMigrate.Add(Database::"Job WIP G/L Entry");
        ListOfTablesToMigrate.Add(Database::"Job WIP Method");
        ListOfTablesToMigrate.Add(Database::"Job WIP Total");
        ListOfTablesToMigrate.Add(Database::"Job WIP Warning");
        ListOfTablesToMigrate.Add(Database::"Job");
        ListOfTablesToMigrate.Add(Database::"Job Archive");
        ListOfTablesToMigrate.Add(Database::"Jobs Setup");
        ListOfTablesToMigrate.Add(Database::"Language");
        ListOfTablesToMigrate.Add(Database::"Last Used Chart");
        ListOfTablesToMigrate.Add(Database::"License Agreement");
        ListOfTablesToMigrate.Add(Database::"Line Fee Note on Report Hist.");
        ListOfTablesToMigrate.Add(Database::"Load Buffer");
        ListOfTablesToMigrate.Add(Database::"Loaner Entry");
        ListOfTablesToMigrate.Add(Database::"Loaner");
        ListOfTablesToMigrate.Add(Database::"Location");
        ListOfTablesToMigrate.Add(Database::"Logged Segment");
        ListOfTablesToMigrate.Add(Database::"Lot No. Information");
        ListOfTablesToMigrate.Add(Database::"Machine Center");
        ListOfTablesToMigrate.Add(Database::"Mailing Group");
        ListOfTablesToMigrate.Add(Database::"Main Asset Component");
        ListOfTablesToMigrate.Add(Database::"Maintenance Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Maintenance Registration");
        ListOfTablesToMigrate.Add(Database::"Maintenance");
        ListOfTablesToMigrate.Add(Database::"Man. Integration Table Mapping");
        ListOfTablesToMigrate.Add(Database::"Man. Int. Field Mapping");
        ListOfTablesToMigrate.Add(Database::"Manufacturer");
        ListOfTablesToMigrate.Add(Database::"Manufacturing Comment Line");
        ListOfTablesToMigrate.Add(Database::"Manufacturing Cue");
        ListOfTablesToMigrate.Add(Database::"Manufacturing Setup");
        ListOfTablesToMigrate.Add(Database::"Manufacturing User Template");
        ListOfTablesToMigrate.Add(Database::"Marketing Setup");
        ListOfTablesToMigrate.Add(Database::"Memoized Result");
        ListOfTablesToMigrate.Add(Database::"Miniform Function Group");
        ListOfTablesToMigrate.Add(Database::"Miniform Function");
        ListOfTablesToMigrate.Add(Database::"Miniform Header");
        ListOfTablesToMigrate.Add(Database::"Miniform Line");
        ListOfTablesToMigrate.Add(Database::"Misc. Article Information");
        ListOfTablesToMigrate.Add(Database::"Misc. Article");
        ListOfTablesToMigrate.Add(Database::"My Account");
        ListOfTablesToMigrate.Add(Database::"My Customer");
        ListOfTablesToMigrate.Add(Database::"My Item");
        ListOfTablesToMigrate.Add(Database::"My Job");
        ListOfTablesToMigrate.Add(Database::"My Notifications");
        ListOfTablesToMigrate.Add(Database::"My Time Sheets");
        ListOfTablesToMigrate.Add(Database::"My Vendor");
        ListOfTablesToMigrate.Add(Database::"Named Forward Link");
        ListOfTablesToMigrate.Add(Database::"Nationality");
        ListOfTablesToMigrate.Add(Database::"No. Series Line");
        ListOfTablesToMigrate.Add(Database::"No. Series Relationship");
        ListOfTablesToMigrate.Add(Database::"No. Series");
        ListOfTablesToMigrate.Add(Database::"Nonstock Item Setup");
        ListOfTablesToMigrate.Add(Database::"Nonstock Item");
        ListOfTablesToMigrate.Add(Database::"Notification Context");
        ListOfTablesToMigrate.Add(Database::"O365 Getting Started");
        ListOfTablesToMigrate.Add(Database::"OCR Service Document Template");
        ListOfTablesToMigrate.Add(Database::"OCR Service Setup");
        ListOfTablesToMigrate.Add(Database::"Office Add-in Context");
        ListOfTablesToMigrate.Add(Database::"Office Contact Details");
        ListOfTablesToMigrate.Add(Database::"Office Document Selection");
        ListOfTablesToMigrate.Add(Database::"Office Invoice");
        ListOfTablesToMigrate.Add(Database::"Office Job Journal");
        ListOfTablesToMigrate.Add(Database::"Office Suggested Line Item");
        ListOfTablesToMigrate.Add(Database::"Online Bank Acc. Link");
        ListOfTablesToMigrate.Add(Database::"Online Map Parameter Setup");
        ListOfTablesToMigrate.Add(Database::"Online Map Setup");
        ListOfTablesToMigrate.Add(Database::"Opportunity Entry");
        ListOfTablesToMigrate.Add(Database::"Opportunity");
        ListOfTablesToMigrate.Add(Database::"Order Address");
        ListOfTablesToMigrate.Add(Database::"Order Promising Line");
        ListOfTablesToMigrate.Add(Database::"Order Promising Setup");
        ListOfTablesToMigrate.Add(Database::"Order Tracking Entry");
        ListOfTablesToMigrate.Add(Database::"Organizational Level");
        ListOfTablesToMigrate.Add(Database::"Outstanding Bank Transaction");
        ListOfTablesToMigrate.Add(Database::"Overdue Approval Entry");
        ListOfTablesToMigrate.Add(Database::"Over-Receipt Code");
        ListOfTablesToMigrate.Add(Database::"Package No. Information");
        ListOfTablesToMigrate.Add(Database::"Page Action Provider Test");
        ListOfTablesToMigrate.Add(Database::"Page Provider Summary Test");
        ListOfTablesToMigrate.Add(Database::"Page Provider Summary Test2");
        ListOfTablesToMigrate.Add(Database::"Page Provider Summary Test3");
        ListOfTablesToMigrate.Add(Database::"Payable Employee Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Payable Vendor Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Payment Application Proposal");
        ListOfTablesToMigrate.Add(Database::"Payment Export Data");
        ListOfTablesToMigrate.Add(Database::"Payment Export Remittance Text");
        ListOfTablesToMigrate.Add(Database::"Payment Jnl. Export Error Text");
        ListOfTablesToMigrate.Add(Database::"Payment Matching Details");
        ListOfTablesToMigrate.Add(Database::"Payment Method Translation");
        ListOfTablesToMigrate.Add(Database::"Payment Method");
        ListOfTablesToMigrate.Add(Database::"Payment Registration Setup");
        ListOfTablesToMigrate.Add(Database::"Payment Reporting Argument");
        ListOfTablesToMigrate.Add(Database::"Payment Service Setup");
        ListOfTablesToMigrate.Add(Database::"Payment Term Translation");
        ListOfTablesToMigrate.Add(Database::"Payment Terms");
        ListOfTablesToMigrate.Add(Database::"Payroll Setup");
        ListOfTablesToMigrate.Add(Database::"Phys. Inventory Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Comment Line");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Count Buffer");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Counting Period");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Item Selection");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Order Header");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Order Line");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Record Header");
        ListOfTablesToMigrate.Add(Database::"Phys. Invt. Record Line");
        ListOfTablesToMigrate.Add(Database::"Invt. Order Tracking");
        ListOfTablesToMigrate.Add(Database::"Picture Entity");
        ListOfTablesToMigrate.Add(Database::"Planning Assignment");
        ListOfTablesToMigrate.Add(Database::"Planning Component");
        ListOfTablesToMigrate.Add(Database::"Planning Error Log");
        ListOfTablesToMigrate.Add(Database::"Planning Routing Line");
        ListOfTablesToMigrate.Add(Database::"Positive Pay Detail");
        ListOfTablesToMigrate.Add(Database::"Positive Pay Entry Detail");
        ListOfTablesToMigrate.Add(Database::"Positive Pay Entry");
        ListOfTablesToMigrate.Add(Database::"Positive Pay Footer");
        ListOfTablesToMigrate.Add(Database::"Positive Pay Header");
        ListOfTablesToMigrate.Add(Database::"Post Code");
        ListOfTablesToMigrate.Add(Database::"Post Value Entry to G/L");
        ListOfTablesToMigrate.Add(Database::"Posted Approval Comment Line");
        ListOfTablesToMigrate.Add(Database::"Posted Approval Entry");
        ListOfTablesToMigrate.Add(Database::"Posted Assemble-to-Order Link");
        ListOfTablesToMigrate.Add(Database::"Posted Assembly Header");
        ListOfTablesToMigrate.Add(Database::"Posted Assembly Line");
        ListOfTablesToMigrate.Add(Database::"Posted Deferral Header");
        ListOfTablesToMigrate.Add(Database::"Posted Deferral Line");
        ListOfTablesToMigrate.Add(Database::"Posted Docs. With No Inc. Buf.");
        ListOfTablesToMigrate.Add(Database::"Posted Gen. Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Posted Gen. Journal Line");
        ListOfTablesToMigrate.Add(Database::"Posted Invt. Pick Header");
        ListOfTablesToMigrate.Add(Database::"Posted Invt. Pick Line");
        ListOfTablesToMigrate.Add(Database::"Posted Invt. Put-away Header");
        ListOfTablesToMigrate.Add(Database::"Posted Invt. Put-away Line");
        ListOfTablesToMigrate.Add(Database::"Posted Payment Recon. Hdr");
        ListOfTablesToMigrate.Add(Database::"Posted Payment Recon. Line");
        ListOfTablesToMigrate.Add(Database::"Posted Whse. Receipt Header");
        ListOfTablesToMigrate.Add(Database::"Posted Whse. Receipt Line");
        ListOfTablesToMigrate.Add(Database::"Posted Whse. Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Posted Whse. Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Price Calculation Setup");
        ListOfTablesToMigrate.Add(Database::"Price List Header");
        ListOfTablesToMigrate.Add(Database::"Price List Line");
        ListOfTablesToMigrate.Add(Database::"Price Worksheet Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Capacity Need");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Comment Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Comp. Cmt Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Component");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Routing Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Routing Personnel");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Routing Tool");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Rtng Comment Line");
        ListOfTablesToMigrate.Add(Database::"Prod. Order Rtng Qlty Meas.");
        ListOfTablesToMigrate.Add(Database::"Production BOM Comment Line");
        ListOfTablesToMigrate.Add(Database::"Production BOM Header");
        ListOfTablesToMigrate.Add(Database::"Production BOM Line");
        ListOfTablesToMigrate.Add(Database::"Production BOM Version");
        ListOfTablesToMigrate.Add(Database::"Production Forecast Entry");
        ListOfTablesToMigrate.Add(Database::"Production Forecast Name");
        ListOfTablesToMigrate.Add(99000789); // Database::"Production Matrix BOM Entry");
        ListOfTablesToMigrate.Add(Database::"Production Matrix BOM Line");
        ListOfTablesToMigrate.Add(Database::"Production Order");
        ListOfTablesToMigrate.Add(Database::"Profile Designer Diagnostic");
        ListOfTablesToMigrate.Add(Database::"Profile Import");
        ListOfTablesToMigrate.Add(Database::"Profile Questionnaire Header");
        ListOfTablesToMigrate.Add(Database::"Profile Questionnaire Line");
        ListOfTablesToMigrate.Add(Database::"Pstd.Exp.Invt.Order.Tracking");
        ListOfTablesToMigrate.Add(Database::"Pstd. Phys. Invt. Order Hdr");
        ListOfTablesToMigrate.Add(Database::"Pstd. Phys. Invt. Order Line");
        ListOfTablesToMigrate.Add(Database::"Pstd. Phys. Invt. Record Hdr");
        ListOfTablesToMigrate.Add(Database::"Pstd. Phys. Invt. Record Line");
        ListOfTablesToMigrate.Add(Database::"Pstd. Phys. Invt. Tracking");
        ListOfTablesToMigrate.Add(Database::"Purch. Comment Line Archive");
        ListOfTablesToMigrate.Add(Database::"Purch. Comment Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Cr. Memo Hdr.");
        ListOfTablesToMigrate.Add(Database::"Purch. Cr. Memo Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Inv. Entity Aggregate");
        ListOfTablesToMigrate.Add(Database::"Purch. Inv. Header");
        ListOfTablesToMigrate.Add(Database::"Purch. Inv. Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Rcpt. Header");
        ListOfTablesToMigrate.Add(Database::"Purch. Rcpt. Line");
        ListOfTablesToMigrate.Add(Database::"Purchase Cue");
        ListOfTablesToMigrate.Add(Database::"Purchase Discount Access");
        ListOfTablesToMigrate.Add(Database::"Purchase Header Archive");
        ListOfTablesToMigrate.Add(Database::"Purchase Header");
        ListOfTablesToMigrate.Add(Database::"Purchase Line Archive");
        ListOfTablesToMigrate.Add(Database::"Purchase Line");
        ListOfTablesToMigrate.Add(Database::"Purchase Prepayment %");
        ListOfTablesToMigrate.Add(Database::"Purchase Price Access");
        ListOfTablesToMigrate.Add(Database::"Purchases & Payables Setup");
        ListOfTablesToMigrate.Add(Database::"Purchasing");
        ListOfTablesToMigrate.Add(Database::"Put-away Template Header");
        ListOfTablesToMigrate.Add(Database::"Put-away Template Line");
        ListOfTablesToMigrate.Add(Database::"Qualification");
        ListOfTablesToMigrate.Add(Database::"Quality Measure");
        ListOfTablesToMigrate.Add(Database::"Rating");
        ListOfTablesToMigrate.Add(Database::"Reason Code");
        ListOfTablesToMigrate.Add(Database::"Receivables-Payables Buffer");
        ListOfTablesToMigrate.Add(Database::"Record Set Definition");
        ListOfTablesToMigrate.Add(Database::"Record Set Tree");
        ListOfTablesToMigrate.Add(Database::"Recorded Event Buffer");
        ListOfTablesToMigrate.Add(Database::"Referenced XML Schema");
        ListOfTablesToMigrate.Add(Database::"Registered Absence");
        ListOfTablesToMigrate.Add(Database::"Registered Invt. Movement Hdr.");
        ListOfTablesToMigrate.Add(Database::"Registered Invt. Movement Line");
        ListOfTablesToMigrate.Add(Database::"Registered Whse. Activity Hdr.");
        ListOfTablesToMigrate.Add(Database::"Registered Whse. Activity Line");
        ListOfTablesToMigrate.Add(Database::"Relationship Mgmt. Cue");
        ListOfTablesToMigrate.Add(Database::"Relative");
        ListOfTablesToMigrate.Add(Database::"Reminder Attachment Text");
        ListOfTablesToMigrate.Add(Database::"Reminder Attachment Text Line");
        ListOfTablesToMigrate.Add(Database::"Reminder Comment Line");
        ListOfTablesToMigrate.Add(Database::"Reminder Email Text");
        ListOfTablesToMigrate.Add(Database::"Reminder Header");
        ListOfTablesToMigrate.Add(Database::"Reminder Level");
        ListOfTablesToMigrate.Add(Database::"Reminder Line");
        ListOfTablesToMigrate.Add(Database::"Reminder Terms Translation");
        ListOfTablesToMigrate.Add(Database::"Reminder Terms");
        ListOfTablesToMigrate.Add(Database::"Reminder Action Group");
        ListOfTablesToMigrate.Add(Database::"Reminder Action");
        ListOfTablesToMigrate.Add(Database::"Create Reminders Setup");
        ListOfTablesToMigrate.Add(Database::"Issue Reminders Setup");
        ListOfTablesToMigrate.Add(Database::"Send Reminders Setup");
        ListOfTablesToMigrate.Add(Database::"Reminder Automation Error");
        ListOfTablesToMigrate.Add(Database::"Reminder Action Group Log");
        ListOfTablesToMigrate.Add(Database::"Reminder Action Log");
        ListOfTablesToMigrate.Add(Database::"Reminder Text");
        ListOfTablesToMigrate.Add(Database::"Reminder/Fin. Charge Entry");
        ListOfTablesToMigrate.Add(Database::"Remit Address");
        ListOfTablesToMigrate.Add(Database::"Repair Status");
        ListOfTablesToMigrate.Add(Database::"Report Inbox");
        ListOfTablesToMigrate.Add(Database::"Report Selection Warehouse");
        ListOfTablesToMigrate.Add(Database::"Report Selections");
        ListOfTablesToMigrate.Add(Database::"Req. Wksh. Template");
        ListOfTablesToMigrate.Add(Database::"Requisition Line");
        ListOfTablesToMigrate.Add(Database::"Requisition Wksh. Name");
        ListOfTablesToMigrate.Add(Database::"Res. Availability Buffer");
        ListOfTablesToMigrate.Add(Database::"Res. Capacity Entry");
        ListOfTablesToMigrate.Add(Database::"Res. Gr. Availability Buffer");
        ListOfTablesToMigrate.Add(Database::"Res. Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Res. Journal Line");
        ListOfTablesToMigrate.Add(Database::"Res. Journal Template");
        ListOfTablesToMigrate.Add(Database::"Res. Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Reservation Entry");
        ListOfTablesToMigrate.Add(Database::"Reservation Wksh. Batch");
        ListOfTablesToMigrate.Add(Database::"Reservation Wksh. Line");
        ListOfTablesToMigrate.Add(Database::"Reservation Worksheet Log");
        ListOfTablesToMigrate.Add(Database::"Resolution Code");
        ListOfTablesToMigrate.Add(Database::"Resource Group");
        ListOfTablesToMigrate.Add(Database::"Resource Location");
        ListOfTablesToMigrate.Add(Database::"Resource Register");
        ListOfTablesToMigrate.Add(Database::"Resource Service Zone");
        ListOfTablesToMigrate.Add(Database::"Resource Skill");
        ListOfTablesToMigrate.Add(Database::"Resource Unit of Measure");
        ListOfTablesToMigrate.Add(Database::"Resource");
        ListOfTablesToMigrate.Add(Database::"Resources Setup");
        ListOfTablesToMigrate.Add(Database::"Responsibility Center");
        ListOfTablesToMigrate.Add(Database::"Restricted Record");
        ListOfTablesToMigrate.Add(Database::"Retention Period");
        ListOfTablesToMigrate.Add(Database::"Retention Policy Setup Line");
        ListOfTablesToMigrate.Add(Database::"Retention Policy Setup Line");
        ListOfTablesToMigrate.Add(Database::"Retention Policy Setup");
        ListOfTablesToMigrate.Add(Database::"Return Reason");
        ListOfTablesToMigrate.Add(Database::"Return Receipt Header");
        ListOfTablesToMigrate.Add(Database::"Return Receipt Line");
        ListOfTablesToMigrate.Add(Database::"Return Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Return Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Returns-Related Document");
        ListOfTablesToMigrate.Add(Database::"Reversal Entry");
        ListOfTablesToMigrate.Add(Database::"Rlshp. Mgt. Comment Line");
        ListOfTablesToMigrate.Add(Database::"RM Matrix Management");
        ListOfTablesToMigrate.Add(Database::"Rounding Method");
        ListOfTablesToMigrate.Add(Database::"Routing Comment Line");
        ListOfTablesToMigrate.Add(Database::"Routing Header");
        ListOfTablesToMigrate.Add(Database::"Routing Line");
        ListOfTablesToMigrate.Add(Database::"Routing Link");
        ListOfTablesToMigrate.Add(Database::"Routing Personnel");
        ListOfTablesToMigrate.Add(Database::"Routing Quality Measure");
        ListOfTablesToMigrate.Add(Database::"Routing Tool");
        ListOfTablesToMigrate.Add(Database::"Routing Version");
        ListOfTablesToMigrate.Add(Database::"Sales & Receivables Setup");
        ListOfTablesToMigrate.Add(Database::"Sales by Cust. Grp.Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Sales Comment Line Archive");
        ListOfTablesToMigrate.Add(Database::"Sales Comment Line");
        ListOfTablesToMigrate.Add(Database::"Sales Cr.Memo Header");
        ListOfTablesToMigrate.Add(Database::"Sales Cr.Memo Line");
        ListOfTablesToMigrate.Add(Database::"Sales Cue");
        ListOfTablesToMigrate.Add(Database::"Sales Cycle Stage");
        ListOfTablesToMigrate.Add(Database::"Sales Cycle");
        ListOfTablesToMigrate.Add(Database::"Sales Discount Access");
        ListOfTablesToMigrate.Add(Database::"Sales Header Archive");
        ListOfTablesToMigrate.Add(Database::"Sales Header");
        ListOfTablesToMigrate.Add(Database::"Sales Invoice Entity Aggregate");
        ListOfTablesToMigrate.Add(Database::"Sales Invoice Header");
        ListOfTablesToMigrate.Add(Database::"Sales Invoice Line");
        ListOfTablesToMigrate.Add(Database::"Sales Line Archive");
        ListOfTablesToMigrate.Add(Database::"Sales Line");
        ListOfTablesToMigrate.Add(Database::"Sales Planning Line");
        ListOfTablesToMigrate.Add(Database::"Sales Prepayment %");
        ListOfTablesToMigrate.Add(Database::"Sales Price Access");
        ListOfTablesToMigrate.Add(Database::"Sales Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Sales Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Salesperson/Purchaser");
        ListOfTablesToMigrate.Add(Database::"Salutation Formula");
        ListOfTablesToMigrate.Add(Database::"Salutation");
        ListOfTablesToMigrate.Add(Database::"Saved Segment Criteria Line");
        ListOfTablesToMigrate.Add(Database::"Saved Segment Criteria");
        ListOfTablesToMigrate.Add(Database::"SB Owner Cue");
        ListOfTablesToMigrate.Add(Database::"Scrap");
        ListOfTablesToMigrate.Add(Database::"Segment Criteria Line");
        ListOfTablesToMigrate.Add(Database::"Segment Header");
        ListOfTablesToMigrate.Add(Database::"Segment History");
        ListOfTablesToMigrate.Add(Database::"Segment Interaction Language");
        ListOfTablesToMigrate.Add(Database::"Segment Line");
        ListOfTablesToMigrate.Add(Database::"Segment Wizard Filter");
        ListOfTablesToMigrate.Add(Database::"Selected Dimension");
        ListOfTablesToMigrate.Add(Database::"Sent Email");
        ListOfTablesToMigrate.Add(Database::"SEPA Direct Debit Mandate");
        ListOfTablesToMigrate.Add(Database::"Serial No. Information");
        ListOfTablesToMigrate.Add(Database::"Serv. Price Adjustment Detail");
        ListOfTablesToMigrate.Add(Database::"Serv. Price Group Setup");
        ListOfTablesToMigrate.Add(Database::"Service Comment Line Archive");
        ListOfTablesToMigrate.Add(Database::"Service Comment Line");
        ListOfTablesToMigrate.Add(Database::"Service Connection");
        ListOfTablesToMigrate.Add(Database::"Service Contract Account Group");
        ListOfTablesToMigrate.Add(Database::"Service Contract Header");
        ListOfTablesToMigrate.Add(Database::"Service Contract Line");
        ListOfTablesToMigrate.Add(Database::"Service Contract Template");
        ListOfTablesToMigrate.Add(Database::"Service Cost");
        ListOfTablesToMigrate.Add(Database::"Service Cr.Memo Header");
        ListOfTablesToMigrate.Add(Database::"Service Cr.Memo Line");
        ListOfTablesToMigrate.Add(Database::"Service Cue");
        ListOfTablesToMigrate.Add(Database::"Service Document Log");
        ListOfTablesToMigrate.Add(Database::"Service Document Register");
        ListOfTablesToMigrate.Add(Database::"Service Email Queue");
        ListOfTablesToMigrate.Add(Database::"Service Header Archive");
        ListOfTablesToMigrate.Add(Database::"Service Header");
        ListOfTablesToMigrate.Add(Database::"Service Hour");
        ListOfTablesToMigrate.Add(Database::"Service Invoice Header");
        ListOfTablesToMigrate.Add(Database::"Service Invoice Line");
        ListOfTablesToMigrate.Add(Database::"Service Item Component");
        ListOfTablesToMigrate.Add(Database::"Service Item Group");
        ListOfTablesToMigrate.Add(Database::"Service Item Line Archive");
        ListOfTablesToMigrate.Add(Database::"Service Item Line");
        ListOfTablesToMigrate.Add(Database::"Service Item Log");
        ListOfTablesToMigrate.Add(Database::"Service Item Trend Buffer");
        ListOfTablesToMigrate.Add(Database::"Service Item");
        ListOfTablesToMigrate.Add(Database::"Service Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Service Line Price Adjmt.");
        ListOfTablesToMigrate.Add(Database::"Service Line Archive");
        ListOfTablesToMigrate.Add(Database::"Service Line");
        ListOfTablesToMigrate.Add(Database::"Service Mgt. Setup");
        ListOfTablesToMigrate.Add(Database::"Service Order Allocation");
        ListOfTablesToMigrate.Add(Database::"Service Order Allocat. Archive");
        ListOfTablesToMigrate.Add(Database::"Service Order Type");
        ListOfTablesToMigrate.Add(Database::"Service Price Adjustment Group");
        ListOfTablesToMigrate.Add(Database::"Service Price Group");
        ListOfTablesToMigrate.Add(Database::"Service Register");
        ListOfTablesToMigrate.Add(Database::"Service Shelf");
        ListOfTablesToMigrate.Add(Database::"Service Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Service Shipment Item Line");
        ListOfTablesToMigrate.Add(Database::"Service Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Service Status Priority Setup");
        ListOfTablesToMigrate.Add(Database::"Service Zone");
        ListOfTablesToMigrate.Add(Database::"Sheet Definition Line");
        ListOfTablesToMigrate.Add(Database::"Sheet Definition Name");
        ListOfTablesToMigrate.Add(Database::"Shipment Method Translation");
        ListOfTablesToMigrate.Add(Database::"Shipment Method");
        ListOfTablesToMigrate.Add(Database::"Shipping Agent Services");
        ListOfTablesToMigrate.Add(Database::"Shipping Agent");
        ListOfTablesToMigrate.Add(Database::"Ship-to Address");
        ListOfTablesToMigrate.Add(Database::"Shop Calendar Holiday");
        ListOfTablesToMigrate.Add(Database::"Shop Calendar Working Days");
        ListOfTablesToMigrate.Add(Database::"Shop Calendar");
        ListOfTablesToMigrate.Add(Database::"Skill Code");
        ListOfTablesToMigrate.Add(Database::"Sorting Table");
        ListOfTablesToMigrate.Add(Database::"Source Code Setup");
        ListOfTablesToMigrate.Add(Database::"Source Code");
        ListOfTablesToMigrate.Add(Database::"Special Equipment");
        ListOfTablesToMigrate.Add(Database::"Standard Address");
        ListOfTablesToMigrate.Add(Database::"Standard Cost Worksheet Name");
        ListOfTablesToMigrate.Add(Database::"Standard Cost Worksheet");
        ListOfTablesToMigrate.Add(Database::"Standard Customer Sales Code");
        ListOfTablesToMigrate.Add(Database::"Standard General Journal Line");
        ListOfTablesToMigrate.Add(Database::"Standard General Journal");
        ListOfTablesToMigrate.Add(Database::"Standard Item Journal Line");
        ListOfTablesToMigrate.Add(Database::"Standard Item Journal");
        ListOfTablesToMigrate.Add(Database::"Standard Purchase Code");
        ListOfTablesToMigrate.Add(Database::"Standard Purchase Line");
        ListOfTablesToMigrate.Add(Database::"Standard Sales Code");
        ListOfTablesToMigrate.Add(Database::"Standard Sales Line");
        ListOfTablesToMigrate.Add(Database::"Standard Service Code");
        ListOfTablesToMigrate.Add(Database::"Standard Service Item Gr. Code");
        ListOfTablesToMigrate.Add(Database::"Standard Service Line");
        ListOfTablesToMigrate.Add(Database::"Standard Task Description");
        ListOfTablesToMigrate.Add(Database::"Standard Task Personnel");
        ListOfTablesToMigrate.Add(Database::"Standard Task Quality Measure");
        ListOfTablesToMigrate.Add(Database::"Standard Task Tool");
        ListOfTablesToMigrate.Add(Database::"Standard Task");
        ListOfTablesToMigrate.Add(Database::"Standard Text");
        ListOfTablesToMigrate.Add(Database::"Standard Vendor Purchase Code");
        ListOfTablesToMigrate.Add(Database::"Stockkeeping Unit Comment Line");
        ListOfTablesToMigrate.Add(Database::"Stockkeeping Unit");
        ListOfTablesToMigrate.Add(Database::"Stop");
        ListOfTablesToMigrate.Add(Database::"Substitution Condition");
        ListOfTablesToMigrate.Add(Database::"SWIFT Code");
        ListOfTablesToMigrate.Add(Database::"Symptom Code");
        ListOfTablesToMigrate.Add(Database::"Table Config Template");
        ListOfTablesToMigrate.Add(Database::"Table Filter");
        ListOfTablesToMigrate.Add(Database::"Tariff Number");
        ListOfTablesToMigrate.Add(Database::"Tax Area Line");
        ListOfTablesToMigrate.Add(Database::"Tax Area Translation");
        ListOfTablesToMigrate.Add(Database::"Tax Area");
        ListOfTablesToMigrate.Add(Database::"Tax Detail");
        ListOfTablesToMigrate.Add(Database::"Tax Group");
        ListOfTablesToMigrate.Add(Database::"Tax Jurisdiction Translation");
        ListOfTablesToMigrate.Add(Database::"Tax Jurisdiction");
        ListOfTablesToMigrate.Add(Database::"Tax Setup");
        ListOfTablesToMigrate.Add(Database::"Team Member Cue");
        ListOfTablesToMigrate.Add(Database::"Team Salesperson");
        ListOfTablesToMigrate.Add(Database::"Team");
        ListOfTablesToMigrate.Add(Database::"Temp Integration Field Mapping");
        ListOfTablesToMigrate.Add(Database::"TempStack");
        ListOfTablesToMigrate.Add(Database::"Territory");
        ListOfTablesToMigrate.Add(Database::"Text-to-Account Mapping");
        ListOfTablesToMigrate.Add(Database::"Time Series Forecast");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Cmt. Line Archive");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Comment Line");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Detail Archive");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Detail");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Header Archive");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Header");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Line Archive");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Line");
        ListOfTablesToMigrate.Add(Database::"Time Sheet Posting Entry");
        ListOfTablesToMigrate.Add(Database::"Timeline Event Change");
        ListOfTablesToMigrate.Add(Database::"Timeline Event");
        ListOfTablesToMigrate.Add(Database::"To-do Interaction Language");
        ListOfTablesToMigrate.Add(Database::"To-do");
        ListOfTablesToMigrate.Add(Database::"Total Value Insured");
        ListOfTablesToMigrate.Add(Database::"Tracking Specification");
        ListOfTablesToMigrate.Add(Database::"Trailing Sales Orders Setup");
        ListOfTablesToMigrate.Add(Database::"Transaction Specification");
        ListOfTablesToMigrate.Add(Database::"Transaction Type");
        ListOfTablesToMigrate.Add(Database::"Transfer Header");
        ListOfTablesToMigrate.Add(Database::"Transfer Line");
        ListOfTablesToMigrate.Add(Database::"Transfer Receipt Header");
        ListOfTablesToMigrate.Add(Database::"Transfer Receipt Line");
        ListOfTablesToMigrate.Add(Database::"Transfer Route");
        ListOfTablesToMigrate.Add(Database::"Transfer Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Transfer Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Transformation Rule");
        ListOfTablesToMigrate.Add(Database::"Transport Method");
        ListOfTablesToMigrate.Add(Database::"Trial Balance Cache Info");
        ListOfTablesToMigrate.Add(Database::"Trial Balance Cache");
        ListOfTablesToMigrate.Add(Database::"Trial Balance Setup");
        ListOfTablesToMigrate.Add(Database::"Troubleshooting Header");
        ListOfTablesToMigrate.Add(Database::"Troubleshooting Line");
        ListOfTablesToMigrate.Add(Database::"Troubleshooting Setup");
        ListOfTablesToMigrate.Add(Database::"Union");
        ListOfTablesToMigrate.Add(Database::"Unit Group");
        ListOfTablesToMigrate.Add(Database::"Unit of Measure Translation");
        ListOfTablesToMigrate.Add(Database::"Unit of Measure");
        ListOfTablesToMigrate.Add(Database::"Unlinked Attachment");
        ListOfTablesToMigrate.Add(Database::"Unplanned Demand");
        ListOfTablesToMigrate.Add(Database::"Untracked Planning Element");
        ListOfTablesToMigrate.Add(Database::"User Setup");
        ListOfTablesToMigrate.Add(Database::"User Task");
        ListOfTablesToMigrate.Add(Database::"User Time Register");
        ListOfTablesToMigrate.Add(Database::"Value Entry Relation");
        ListOfTablesToMigrate.Add(Database::"Value Entry");
        ListOfTablesToMigrate.Add(Database::"VAT Reporting Code");
        ListOfTablesToMigrate.Add(Database::"VAT Amount Line");
        ListOfTablesToMigrate.Add(Database::"VAT Assisted Setup Bus. Grp.");
        ListOfTablesToMigrate.Add(Database::"VAT Assisted Setup Templates");
        ListOfTablesToMigrate.Add(Database::"VAT Business Posting Group");
        ListOfTablesToMigrate.Add(Database::"VAT Clause by Doc. Type Trans.");
        ListOfTablesToMigrate.Add(Database::"VAT Clause by Doc. Type");
        ListOfTablesToMigrate.Add(Database::"VAT Clause Translation");
        ListOfTablesToMigrate.Add(Database::"VAT Clause");
        ListOfTablesToMigrate.Add(Database::"VAT Entry");
        ListOfTablesToMigrate.Add(Database::"VAT Posting Setup");
        ListOfTablesToMigrate.Add(Database::"VAT Product Posting Group");
        ListOfTablesToMigrate.Add(Database::"VAT Rate Change Conversion");
        ListOfTablesToMigrate.Add(Database::"VAT Rate Change Log Entry");
        ListOfTablesToMigrate.Add(Database::"VAT Rate Change Setup");
        ListOfTablesToMigrate.Add(Database::"VAT Reg. No. Srv Config");
        ListOfTablesToMigrate.Add(Database::"VAT Reg. No. Srv. Template");
        ListOfTablesToMigrate.Add(Database::"VAT Registration Log Details");
        ListOfTablesToMigrate.Add(Database::"VAT Registration Log");
        ListOfTablesToMigrate.Add(Database::"VAT Registration No. Format");
        ListOfTablesToMigrate.Add(Database::"VAT Report Archive");
        ListOfTablesToMigrate.Add(Database::"VAT Report Error Log");
        ListOfTablesToMigrate.Add(Database::"VAT Report Header");
        ListOfTablesToMigrate.Add(Database::"VAT Report Line Relation");
        ListOfTablesToMigrate.Add(Database::"VAT Report Line");
        ListOfTablesToMigrate.Add(Database::"VAT Report Setup");
        ListOfTablesToMigrate.Add(Database::"VAT Reports Configuration");
        ListOfTablesToMigrate.Add(Database::"VAT Return Period");
        ListOfTablesToMigrate.Add(Database::"VAT Setup Posting Groups");
        ListOfTablesToMigrate.Add(Database::"VAT Statement Line");
        ListOfTablesToMigrate.Add(Database::"VAT Statement Name");
        ListOfTablesToMigrate.Add(Database::"VAT Statement Report Line");
        ListOfTablesToMigrate.Add(Database::"VAT Statement Template");
        ListOfTablesToMigrate.Add(Database::"VAT Setup");
        ListOfTablesToMigrate.Add(Database::"Alt. Cust. VAT Reg.");
        ListOfTablesToMigrate.Add(Database::"VAT Posting Parameters");
        ListOfTablesToMigrate.Add(Database::"Vendor Amount");
        ListOfTablesToMigrate.Add(Database::"Vendor Bank Account");
        ListOfTablesToMigrate.Add(Database::"Vendor Invoice Disc.");
        ListOfTablesToMigrate.Add(Database::"Vendor Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Vendor Posting Group");
        ListOfTablesToMigrate.Add(Database::"Vendor Purchase Buffer");
        ListOfTablesToMigrate.Add(Database::"Vendor Templ.");
        ListOfTablesToMigrate.Add(Database::"Vendor");
        ListOfTablesToMigrate.Add(Database::"Warehouse Activity Header");
        ListOfTablesToMigrate.Add(Database::"Warehouse Activity Line");
        ListOfTablesToMigrate.Add(Database::"Warehouse Basic Cue");
        ListOfTablesToMigrate.Add(Database::"Warehouse Class");
        ListOfTablesToMigrate.Add(Database::"Warehouse Comment Line");
        ListOfTablesToMigrate.Add(Database::"Warehouse Employee");
        ListOfTablesToMigrate.Add(Database::"Warehouse Entry");
        ListOfTablesToMigrate.Add(Database::"Warehouse Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Warehouse Journal Line");
        ListOfTablesToMigrate.Add(Database::"Warehouse Journal Template");
        ListOfTablesToMigrate.Add(Database::"Warehouse Reason Code");
        ListOfTablesToMigrate.Add(Database::"Warehouse Receipt Header");
        ListOfTablesToMigrate.Add(Database::"Warehouse Receipt Line");
        ListOfTablesToMigrate.Add(Database::"Warehouse Register");
        ListOfTablesToMigrate.Add(Database::"Warehouse Request");
        ListOfTablesToMigrate.Add(Database::"Warehouse Setup");
        ListOfTablesToMigrate.Add(Database::"Warehouse Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Warehouse Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Warehouse Source Filter");
        ListOfTablesToMigrate.Add(Database::"Warehouse WMS Cue");
        ListOfTablesToMigrate.Add(Database::"Warehouse Worker WMS Cue");
        ListOfTablesToMigrate.Add(Database::"Warranty Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Web Source");
        ListOfTablesToMigrate.Add(Database::"WF Event/Response Combination");
        ListOfTablesToMigrate.Add(Database::"Where Used Base Calendar");
        ListOfTablesToMigrate.Add(Database::"Where-Used Line");
        ListOfTablesToMigrate.Add(Database::"Whse. Cross-Dock Opportunity");
        ListOfTablesToMigrate.Add(Database::"Whse. Internal Pick Header");
        ListOfTablesToMigrate.Add(Database::"Whse. Internal Pick Line");
        ListOfTablesToMigrate.Add(Database::"Whse. Internal Put-away Header");
        ListOfTablesToMigrate.Add(Database::"Whse. Internal Put-away Line");
        ListOfTablesToMigrate.Add(Database::"Whse. Item Entry Relation");
        ListOfTablesToMigrate.Add(Database::"Whse. Item Tracking Line");
        ListOfTablesToMigrate.Add(Database::"Whse. Pick Request");
        ListOfTablesToMigrate.Add(Database::"Whse. Put-away Request");
        ListOfTablesToMigrate.Add(Database::"Whse. Worksheet Line");
        ListOfTablesToMigrate.Add(Database::"Whse. Worksheet Name");
        ListOfTablesToMigrate.Add(Database::"Whse. Worksheet Template");
        ListOfTablesToMigrate.Add(Database::"Word Template");
        ListOfTablesToMigrate.Add(Database::"Work Center Group");
        ListOfTablesToMigrate.Add(Database::"Work Center");
        ListOfTablesToMigrate.Add(Database::"Work Shift");
        ListOfTablesToMigrate.Add(Database::"Work Type");
        ListOfTablesToMigrate.Add(Database::"Workflow - Record Change");
        ListOfTablesToMigrate.Add(Database::"Workflow - Table Relation");
        ListOfTablesToMigrate.Add(Database::"Workflow Category");
        ListOfTablesToMigrate.Add(Database::"Workflow Event Queue");
        ListOfTablesToMigrate.Add(Database::"Workflow Event");
        ListOfTablesToMigrate.Add(Database::"Workflow Record Change Archive");
        ListOfTablesToMigrate.Add(Database::"Workflow Response");
        ListOfTablesToMigrate.Add(Database::"Workflow Rule");
        ListOfTablesToMigrate.Add(Database::"Workflow Step Argument Archive");
        ListOfTablesToMigrate.Add(Database::"Workflow Step Argument");
        ListOfTablesToMigrate.Add(Database::"Workflow Step Instance Archive");
        ListOfTablesToMigrate.Add(Database::"Workflow Step Instance");
        ListOfTablesToMigrate.Add(Database::"Workflow Step");
        ListOfTablesToMigrate.Add(Database::"Workflow Table Relation Value");
        ListOfTablesToMigrate.Add(Database::"Workflow User Group Member");
        ListOfTablesToMigrate.Add(Database::"Workflow User Group");
        ListOfTablesToMigrate.Add(Database::"Workflow Webhook Entry");
        ListOfTablesToMigrate.Add(Database::"Workflow Webhook Notification");
        ListOfTablesToMigrate.Add(Database::"Workflow Webhook Subscription");
        ListOfTablesToMigrate.Add(Database::"Workflow");
        ListOfTablesToMigrate.Add(Database::"Work-Hour Template");
        ListOfTablesToMigrate.Add(Database::"XML Schema Element");
        ListOfTablesToMigrate.Add(Database::"XML Schema Restriction");
        ListOfTablesToMigrate.Add(Database::"XML Schema");
        ListOfTablesToMigrate.Add(Database::"Zone");
        ListOfTablesToMigrate.Add(Database::"Custom Report Layout");
        ListOfTablesToMigrate.Add(Database::"Feature Data Update Status");
        ListOfTablesToMigrate.Add(Database::"Feature Data Update Status");
        ListOfTablesToMigrate.Add(Database::"Image Analysis Setup");
        ListOfTablesToMigrate.Add(Database::"Page Usage State");
        ListOfTablesToMigrate.Add(Database::"Printer Selection");
        ListOfTablesToMigrate.Add(Database::"Report Layout Selection");
        ListOfTablesToMigrate.Add(Database::"Report List Translation");
        ListOfTablesToMigrate.Add(Database::"Tenant Feature Key");
        ListOfTablesToMigrate.Add(Database::"Tenant Media");
        ListOfTablesToMigrate.Add(Database::"Tenant Media Set");
        ListOfTablesToMigrate.Add(Database::"Tenant Media Thumbnails");

        // internal tables
        ListOfTablesToMigrate.Add(8703); // Database::"Feature Uptake"

        // Obsoleted tables
#if not CLEANSCHEMA25
        ListOfTablesToMigrate.Add(8452); // Database::"Advanced Intrastat Checklist"
        ListOfTablesToMigrate.Add(5358); // Database::"CDS Failed Option Mapping"
        ListOfTablesToMigrate.Add(262); // Database::"Intrastat Jnl. Batch"
        ListOfTablesToMigrate.Add(263); // Database::"Intrastat Jnl. Line"
        ListOfTablesToMigrate.Add(261); // Database::"Intrastat Jnl. Template"
        ListOfTablesToMigrate.Add(247); // Database::"Intrastat Setup"
#endif
#if not CLEANSCHEMA27
        ListOfTablesToMigrate.Add(5381); // Database::"Man. Integration Field Mapping"
        ListOfTablesToMigrate.Add(12145); // Database::"No. Series Line Sales"
        ListOfTablesToMigrate.Add(12146); // Database::"No. Series Line Purchase"
        ListOfTablesToMigrate.Add(500); // Database::"Deposits Page Setup"
#endif
#if not CLEANSCHEMA28
        ListOfTablesToMigrate.Add(1012); // Database::"Job Resource Price"
        ListOfTablesToMigrate.Add(1014); // Database::"Job G/L Account Price"
        ListOfTablesToMigrate.Add(1013); // Database::"Job Item Price"
        ListOfTablesToMigrate.Add(1315); // Database::"Purch. Price Line Disc. Buff."
        ListOfTablesToMigrate.Add(7014); // Database::"Purchase Line Discount"
        ListOfTablesToMigrate.Add(7012); // Database::"Purchase Price"
        ListOfTablesToMigrate.Add(202); // Database::"Resource Cost"
        ListOfTablesToMigrate.Add(335); // Database::"Resource Price Change"
        ListOfTablesToMigrate.Add(201); // Database::"Resource Price"
        ListOfTablesToMigrate.Add(7004); // Database::"Sales Line Discount"
        ListOfTablesToMigrate.Add(1304); // Database::"Sales Price and Line Disc Buff"
        ListOfTablesToMigrate.Add(7023); // Database::"Sales Price Worksheet"
        ListOfTablesToMigrate.Add(7002); // Database::"Sales Price"
#if CLEAN25
        ListOfTablesToMigrate.Add(6418); // Database::"FS Connection Setup"
#endif
#endif
        // AL Costing
        ListOfTablesToMigrate.Add(103405); // Database::"Required Input Data");
        ListOfTablesToMigrate.Add(103336); // Database::"BW Bin Content Ref"
        ListOfTablesToMigrate.Add(103330); // Database::"BW Item Journal Line Ref."
        ListOfTablesToMigrate.Add(103333); // Database::"BW Item Ledger Entry Ref"
        ListOfTablesToMigrate.Add(103342); //Database::"BW Item Register Ref"
        ListOfTablesToMigrate.Add(103344); // Database::"BW P. Invt. Pick Line Ref"
        ListOfTablesToMigrate.Add(103343); // Database::"BW P. Invt. Put-away Line Ref"
        ListOfTablesToMigrate.Add(103338); // Database::"BW Posted Whse. Rcpt Line Ref"
        ListOfTablesToMigrate.Add(103340); // Database::"BW Posted Whse. Shpmt Line Ref"
        ListOfTablesToMigrate.Add(103335); // Database::"BW Warehouse Activity Line Ref"
        ListOfTablesToMigrate.Add(103332); // Database::"BW Warehouse Entry Ref"
        ListOfTablesToMigrate.Add(103331); // Database::"BW Warehouse Journal Line Ref"
        ListOfTablesToMigrate.Add(103337); // Database::"BW Warehouse Receipt Line Ref"
        ListOfTablesToMigrate.Add(103334); // Database::"BW Warehouse Request Ref"
        ListOfTablesToMigrate.Add(103339); // Database::"BW Warehouse Shipment Line Ref"
        ListOfTablesToMigrate.Add(103341); // Database::"BW Whse. Worksheet Line Ref"
        ListOfTablesToMigrate.Add(103408); // Database::"G/L Entry Ref."
        ListOfTablesToMigrate.Add(103409); // Database::"Item Journal Line Ref."
        ListOfTablesToMigrate.Add(103412); // Database::"Item Ref."
        ListOfTablesToMigrate.Add(103406); // Database::"Item Ledger Entry Ref."
        ListOfTablesToMigrate.Add(103410); // Database::"Ledger Entry Dim. Ref."
        ListOfTablesToMigrate.Add(103411); // Database::"Purchase Header Ref."
        ListOfTablesToMigrate.Add(103498); // Database::"QA Setup"
        ListOfTablesToMigrate.Add(103413); // Database::"SKU Ref."
        ListOfTablesToMigrate.Add(103497); // Database::"Temp. Reference Data"
        ListOfTablesToMigrate.Add(103402); // Database::"Test Case"
        ListOfTablesToMigrate.Add(103404); // Database::"Test Iteration"
        ListOfTablesToMigrate.Add(103001); // Database::"Testscript Result"
        ListOfTablesToMigrate.Add(103002); // Database::"Testscript Setup"
        ListOfTablesToMigrate.Add(103401); // Database::"Use Case"
        ListOfTablesToMigrate.Add(103407); // Database::"Value Entry Ref."
        ListOfTablesToMigrate.Add(103304); // Database::"Whse. QA Setup"
        ListOfTablesToMigrate.Add(103305); // Database::"Whse. Temp. Reference Data"
        ListOfTablesToMigrate.Add(103301); //Database::"Whse. Test Case"
        ListOfTablesToMigrate.Add(103302); //Database::"Whse. Test Iteration"
        ListOfTablesToMigrate.Add(103303); //Database::"Whse. Testscript Result"
        ListOfTablesToMigrate.Add(103300); // Database::"Whse. Use Case"
        ListOfTablesToMigrate.Add(103314); // Database::"WMS Bin Content Ref"
        ListOfTablesToMigrate.Add(103315); // Database::"WMS Item Journal Line Ref"
        ListOfTablesToMigrate.Add(103311); // Database::"WMS Item Ledger Entry Ref"
        ListOfTablesToMigrate.Add(103317); // Database::"WMS Posted Whse. Rcpt Line Ref"
        ListOfTablesToMigrate.Add(103319); // Database::"WMS Posted Whse. Shpt Line Ref"
        ListOfTablesToMigrate.Add(103321); // Database::"WMS Prod. Order Component Ref"
        ListOfTablesToMigrate.Add(103322); // Database::"WMS Reservation Entry Ref"
        ListOfTablesToMigrate.Add(103323); // Database::"WMS Tracking Specification Ref"
        ListOfTablesToMigrate.Add(103310); // Database::"WMS Warehouse Entry Ref"
        ListOfTablesToMigrate.Add(103312); // Database::"WMS Warehouse Journal Line Ref"
        ListOfTablesToMigrate.Add(103316); // Database::"WMS Warehouse Receipt Line Ref"
        ListOfTablesToMigrate.Add(103313); // Database::"WMS Whse. Activity Line Ref"
        ListOfTablesToMigrate.Add(103318); // Database::"WMS Whse. Shipment Line Ref"
        ListOfTablesToMigrate.Add(103320); // Database::"WMS Whse. Worksheet Line Ref"
        ListOfTablesToMigrate.Add(103403); // Database::"_Testscript Result"

        // Internal tables
        ListOfTablesToMigrate.Add(7201); // Database::"CDS Coupled Business Unit"
        ListOfTablesToMigrate.Add(7202); // Database::"CDS Environment"
        ListOfTablesToMigrate.Add(1992); // Database::"Checklist Item Role"
        ListOfTablesToMigrate.Add(1993); // Database::"Checklist Item User"
        ListOfTablesToMigrate.Add(9701); // Database::"Cue Setup"
        ListOfTablesToMigrate.Add(8887); // Database::"Email Connector Logo"
        ListOfTablesToMigrate.Add(8901); // Database::"Email Error"
        ListOfTablesToMigrate.Add(8904); // Database::"Email Message Attachment"
        ListOfTablesToMigrate.Add(8900); // Database::"Email Message"
        ListOfTablesToMigrate.Add(8903); // Database::"Email Recipient"
        ListOfTablesToMigrate.Add(8909); // Database::"Email Related Record"
        ListOfTablesToMigrate.Add(8906); // Database::"Email Scenario"
        ListOfTablesToMigrate.Add(8912); // Database::"Email Rate Limit"
        ListOfTablesToMigrate.Add(8930); // Database::"Email View Policy"
        ListOfTablesToMigrate.Add(1750); // Database::"Fields Sync Status"
        ListOfTablesToMigrate.Add(4151); // Database::"Persistent Blob"
        ListOfTablesToMigrate.Add(4690); // Database::"Recurrence Schedule"
        ListOfTablesToMigrate.Add(3903); // Database::"Retention Policy Allowed Table"
        ListOfTablesToMigrate.Add(3905); // Database::"Retention Policy Log Entry"
        ListOfTablesToMigrate.Add(3712); // Database::"Translation"
        ListOfTablesToMigrate.Add(9999); // Database::"Upgrade Tags"
        ListOfTablesToMigrate.Add(9989); // Database::"Word Template Field"
        ListOfTablesToMigrate.Add(9990); // Database::"Word Templates Related Table"
        ListOfTablesToMigrate.Add(9987); // Database::"Word Templates Table"

        // E-Document
        ListOfTablesToMigrate.Add(6121); // Database::"E-Document"
        ListOfTablesToMigrate.Add(6103); // Database::"E-Document Service"

        // Other tables
        ListOfTablesToMigrate.Add(Database::"Acc. Sched. Cell Value");
        ListOfTablesToMigrate.Add(Database::"Acc. Sched. Chart Setup Line");
        ListOfTablesToMigrate.Add(Database::"Acc. Sched. KPI Web Srv. Line");
        ListOfTablesToMigrate.Add(Database::"Acc. Sched. KPI Web Srv. Setup");
        ListOfTablesToMigrate.Add(Database::"Acc. Schedule Line");
        ListOfTablesToMigrate.Add(Database::"Acc. Schedule Name");
        ListOfTablesToMigrate.Add(Database::"Account Schedules Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Accounting Period");
        ListOfTablesToMigrate.Add(Database::"Accounting Services Cue");
        ListOfTablesToMigrate.Add(Database::"Action Message Entry");
        ListOfTablesToMigrate.Add(Database::"Activity Step");
        ListOfTablesToMigrate.Add(Database::"Activity");
        ListOfTablesToMigrate.Add(Database::"ADCS User");
        ListOfTablesToMigrate.Add(Database::"Additional Fee Setup");
        ListOfTablesToMigrate.Add(Database::"Administration Cue");
        ListOfTablesToMigrate.Add(Database::"Aged Report Entity");
        ListOfTablesToMigrate.Add(Database::"Allocation Policy");
        ListOfTablesToMigrate.Add(Database::"Alternative Address");
        ListOfTablesToMigrate.Add(Database::"Alt. Customer Posting Group");
        ListOfTablesToMigrate.Add(Database::"Alt. Vendor Posting Group");
        ListOfTablesToMigrate.Add(Database::"Alt. Employee Posting Group");
        ListOfTablesToMigrate.Add(Database::"Analysis by Dim. Parameters");
        ListOfTablesToMigrate.Add(Database::"Analysis by Dim. User Param.");
        ListOfTablesToMigrate.Add(Database::"Analysis Column Template");
        ListOfTablesToMigrate.Add(Database::"Analysis Column");
        ListOfTablesToMigrate.Add(Database::"Analysis Field Value");
        ListOfTablesToMigrate.Add(Database::"Analysis Line Template");
        ListOfTablesToMigrate.Add(Database::"Analysis Line");
        ListOfTablesToMigrate.Add(Database::"Analysis Report Chart Line");
        ListOfTablesToMigrate.Add(Database::"Analysis Report Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Analysis Report Name");
        ListOfTablesToMigrate.Add(Database::"Analysis Selected Dimension");
        ListOfTablesToMigrate.Add(Database::"Analysis Type");
        ListOfTablesToMigrate.Add(Database::"Analysis View Budget Entry");
        ListOfTablesToMigrate.Add(Database::"Analysis View Entry");
        ListOfTablesToMigrate.Add(Database::"Analysis View Filter");
        ListOfTablesToMigrate.Add(Database::"Analysis View");
        ListOfTablesToMigrate.Add(Database::"API Data Upgrade");
        ListOfTablesToMigrate.Add(Database::"API Entities Setup");
        ListOfTablesToMigrate.Add(Database::"API Extension Upload");
        ListOfTablesToMigrate.Add(Database::"Applied Payment Entry");
        ListOfTablesToMigrate.Add(Database::"Approval Comment Line");
        ListOfTablesToMigrate.Add(Database::"Approval Entry");
        ListOfTablesToMigrate.Add(Database::"Approval Workflow Wizard");
        ListOfTablesToMigrate.Add(Database::"Area");
        ListOfTablesToMigrate.Add(Database::"Assemble-to-Order Link");
        ListOfTablesToMigrate.Add(Database::"Assembly Comment Line");
        ListOfTablesToMigrate.Add(Database::"Assembly Header");
        ListOfTablesToMigrate.Add(Database::"Assembly Line");
        ListOfTablesToMigrate.Add(Database::"Assembly Setup");
        ListOfTablesToMigrate.Add(Database::"Attachment");
        ListOfTablesToMigrate.Add(Database::"Attendee");
        ListOfTablesToMigrate.Add(Database::"Autocomplete Address");
        ListOfTablesToMigrate.Add(Database::"Availability at Date");
        ListOfTablesToMigrate.Add(Database::"Availability Calc. Overview");
        ListOfTablesToMigrate.Add(Database::"Average Cost Calc. Overview");
        ListOfTablesToMigrate.Add(Database::"Avg. Cost Adjmt. Entry Point");
        ListOfTablesToMigrate.Add(Database::"Azure AD Mgt. Setup");
        ListOfTablesToMigrate.Add(Database::"Bank Acc. Rec. Match Buffer");
        ListOfTablesToMigrate.Add(Database::"Bank Acc. Reconciliation Line");
        ListOfTablesToMigrate.Add(Database::"Bank Acc. Reconciliation");
        ListOfTablesToMigrate.Add(Database::"Bank Account Balance Buffer");
        ListOfTablesToMigrate.Add(Database::"Bank Account Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Bank Account Posting Group");
        ListOfTablesToMigrate.Add(Database::"Bank Account Statement Line");
        ListOfTablesToMigrate.Add(Database::"Bank Account Statement");
        ListOfTablesToMigrate.Add(Database::"Bank Account");
        ListOfTablesToMigrate.Add(Database::"Bank Clearing Standard");
        ListOfTablesToMigrate.Add(Database::"Bank Export/Import Setup");
        ListOfTablesToMigrate.Add(Database::"Bank Pmt. Appl. Rule");
        ListOfTablesToMigrate.Add(Database::"Bank Pmt. Appl. Settings");
        ListOfTablesToMigrate.Add(Database::"Bank Stmt Multiple Match Line");
        ListOfTablesToMigrate.Add(Database::"Base Calendar Change");
        ListOfTablesToMigrate.Add(Database::"Base Calendar");
        ListOfTablesToMigrate.Add(Database::"Batch Processing Parameter");
        ListOfTablesToMigrate.Add(Database::"Batch Processing Session Map");
        ListOfTablesToMigrate.Add(Database::"Bin Content");
        ListOfTablesToMigrate.Add(Database::"Bin Creation Wksh. Name");
        ListOfTablesToMigrate.Add(Database::"Bin Creation Wksh. Template");
        ListOfTablesToMigrate.Add(Database::"Bin Creation Worksheet Line");
        ListOfTablesToMigrate.Add(Database::"Bin Template");
        ListOfTablesToMigrate.Add(Database::"Bin Type");
        ListOfTablesToMigrate.Add(Database::"Bin");
        ListOfTablesToMigrate.Add(Database::"BOM Component");
        ListOfTablesToMigrate.Add(Database::"BOM Warning Log");
        ListOfTablesToMigrate.Add(Database::"Booking Mgr. Setup");
        ListOfTablesToMigrate.Add(Database::"Booking Service Mapping");
        ListOfTablesToMigrate.Add(Database::"Booking Sync");
        ListOfTablesToMigrate.Add(Database::"Business Chart Map");
        ListOfTablesToMigrate.Add(Database::"Business Relation");
        ListOfTablesToMigrate.Add(Database::"Business Unit Information");
        ListOfTablesToMigrate.Add(Database::"Business Unit Setup");
        ListOfTablesToMigrate.Add(Database::"Business Unit");
        ListOfTablesToMigrate.Add(Database::"Calendar Absence Entry");
        ListOfTablesToMigrate.Add(Database::"Calendar Entry");
        ListOfTablesToMigrate.Add(Database::"Campaign Entry");
        ListOfTablesToMigrate.Add(Database::"Campaign Status");
        ListOfTablesToMigrate.Add(Database::"Campaign Target Group");
        ListOfTablesToMigrate.Add(Database::"Campaign");
        ListOfTablesToMigrate.Add(Database::"Cancelled Document");
        ListOfTablesToMigrate.Add(Database::"Capacity Constrained Resource");
        ListOfTablesToMigrate.Add(Database::"Capacity Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Capacity Unit of Measure");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Account Comment");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Account");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Availability Buffer");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Azure AI Buffer");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Forecast Entry");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Forecast");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Manual Expense");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Manual Revenue");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Report Selection");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Setup");
        ListOfTablesToMigrate.Add(Database::"Cash Flow Worksheet Line");
        ListOfTablesToMigrate.Add(Database::"Cause of Absence");
        ListOfTablesToMigrate.Add(Database::"Cause of Inactivity");
        ListOfTablesToMigrate.Add(Database::"CDS Connection Setup");
        ListOfTablesToMigrate.Add(Database::"Certificate of Supply");
        ListOfTablesToMigrate.Add(Database::"Change Global Dim. Header");
        ListOfTablesToMigrate.Add(Database::"Change Global Dim. Log Entry");
        ListOfTablesToMigrate.Add(Database::"Chart Definition");
        ListOfTablesToMigrate.Add(Database::"Check Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Close Opportunity Code");
        ListOfTablesToMigrate.Add(Database::"Column Layout Name");
        ListOfTablesToMigrate.Add(Database::"Column Layout");
        ListOfTablesToMigrate.Add(Database::"Comment Line");
        ListOfTablesToMigrate.Add(Database::"Comment Line Archive");
        ListOfTablesToMigrate.Add(Database::"Communication Method");
        ListOfTablesToMigrate.Add(Database::"Company Information");
        ListOfTablesToMigrate.Add(Database::"Company Size");
        ListOfTablesToMigrate.Add(Database::"Confidential Information");
        ListOfTablesToMigrate.Add(Database::"Confidential");
        ListOfTablesToMigrate.Add(Database::"Consolidation Account");
        ListOfTablesToMigrate.Add(Database::"Cont. Duplicate Search String");
        ListOfTablesToMigrate.Add(Database::"Contact Alt. Addr. Date Range");
        ListOfTablesToMigrate.Add(Database::"Contact Alt. Address");
        ListOfTablesToMigrate.Add(Database::"Contact Business Relation");
        ListOfTablesToMigrate.Add(Database::"Contact Duplicate");
        ListOfTablesToMigrate.Add(Database::"Contact Industry Group");
        ListOfTablesToMigrate.Add(Database::"Contact Job Responsibility");
        ListOfTablesToMigrate.Add(Database::"Contact Mailing Group");
        ListOfTablesToMigrate.Add(Database::"Contact Profile Answer");
        ListOfTablesToMigrate.Add(Database::"Contact Value");
        ListOfTablesToMigrate.Add(Database::"Contact Web Source");
        ListOfTablesToMigrate.Add(Database::"Contact");
        ListOfTablesToMigrate.Add(Database::"Contract Change Log");
        ListOfTablesToMigrate.Add(Database::"Contract Gain/Loss Entry");
        ListOfTablesToMigrate.Add(Database::"Contract Group");
        ListOfTablesToMigrate.Add(Database::"Contract Trend Buffer");
        ListOfTablesToMigrate.Add(Database::"Contract/Service Discount");
        ListOfTablesToMigrate.Add(Database::"Copy Gen. Journal Parameters");
        ListOfTablesToMigrate.Add(Database::"Copy Item Buffer");
        ListOfTablesToMigrate.Add(Database::"Copy Item Parameters");
        ListOfTablesToMigrate.Add(Database::"Cost Accounting Setup");
        ListOfTablesToMigrate.Add(Database::"Cost Adj. Item Bucket");
        ListOfTablesToMigrate.Add(Database::"Cost Adjustment Detailed Log");
        ListOfTablesToMigrate.Add(Database::"Cost Adjustment Log");
        ListOfTablesToMigrate.Add(Database::"Cost Adjustment Trace Log");
        ListOfTablesToMigrate.Add(Database::"Cost Allocation Source");
        ListOfTablesToMigrate.Add(Database::"Cost Allocation Target");
        ListOfTablesToMigrate.Add(Database::"Cost Budget Entry");
        ListOfTablesToMigrate.Add(Database::"Cost Budget Name");
        ListOfTablesToMigrate.Add(Database::"Cost Budget Register");
        ListOfTablesToMigrate.Add(Database::"Cost Center");
        ListOfTablesToMigrate.Add(Database::"Cost Entry");
        ListOfTablesToMigrate.Add(Database::"Cost Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Cost Journal Line");
        ListOfTablesToMigrate.Add(Database::"Cost Journal Template");
        ListOfTablesToMigrate.Add(Database::"Cost Object");
        ListOfTablesToMigrate.Add(Database::"Cost Register");
        ListOfTablesToMigrate.Add(Database::"Cost Type");
        ListOfTablesToMigrate.Add(Database::"Country/Region Translation");
        ListOfTablesToMigrate.Add(Database::"Country/Region");
        ListOfTablesToMigrate.Add(Database::"Credit Trans Re-export History");
        ListOfTablesToMigrate.Add(Database::"Credit Transfer Entry");
        ListOfTablesToMigrate.Add(Database::"Credit Transfer Register");
        ListOfTablesToMigrate.Add(Database::"CRM Annotation Buffer");
        ListOfTablesToMigrate.Add(Database::"CRM Annotation Coupling");
        ListOfTablesToMigrate.Add(Database::"CRM Connection Setup");
        ListOfTablesToMigrate.Add(Database::"CRM Full Synch. Review Line");
        ListOfTablesToMigrate.Add(Database::"CRM Integration Record");
        ListOfTablesToMigrate.Add(Database::"CRM Option Mapping");
        ListOfTablesToMigrate.Add(Database::"CRM Post Buffer");
        ListOfTablesToMigrate.Add(Database::"CRM Redirect");
        ListOfTablesToMigrate.Add(Database::"CRM Synch Status");
        ListOfTablesToMigrate.Add(Database::"CRM Synch. Conflict Buffer");
        ListOfTablesToMigrate.Add(Database::"CRM Synch. Job Status Cue");
        ListOfTablesToMigrate.Add(Database::"Cues And KPIs Test 1 Cue");
        ListOfTablesToMigrate.Add(Database::"Cues And KPIs Test 2 Cue");
        ListOfTablesToMigrate.Add(Database::"Curr. Exch. Rate Update Setup");
        ListOfTablesToMigrate.Add(Database::"Currency Amount");
        ListOfTablesToMigrate.Add(Database::"Currency Exchange Rate");
        ListOfTablesToMigrate.Add(Database::"Currency for Fin. Charge Terms");
        ListOfTablesToMigrate.Add(Database::"Currency for Reminder Level");
        ListOfTablesToMigrate.Add(Database::"Currency");
        ListOfTablesToMigrate.Add(Database::"Current Salesperson");
        ListOfTablesToMigrate.Add(Database::"Cust. Invoice Disc.");
        ListOfTablesToMigrate.Add(Database::"Cust. Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Custom Address Format Line");
        ListOfTablesToMigrate.Add(Database::"Custom Address Format");
        ListOfTablesToMigrate.Add(Database::"Custom Report Selection");
        ListOfTablesToMigrate.Add(Database::"Customer Amount");
        ListOfTablesToMigrate.Add(Database::"Customer Bank Account");
        ListOfTablesToMigrate.Add(Database::"Customer Discount Group");
        ListOfTablesToMigrate.Add(Database::"Customer Posting Group");
        ListOfTablesToMigrate.Add(Database::"Customer Price Group");
        ListOfTablesToMigrate.Add(Database::"Customer Sales Buffer");
        ListOfTablesToMigrate.Add(Database::"Customer Templ.");
        ListOfTablesToMigrate.Add(Database::"Customer");
        ListOfTablesToMigrate.Add(Database::"Customized Calendar Change");
        ListOfTablesToMigrate.Add(Database::"Customized Calendar Entry");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Column Def");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Def");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Field Grouping");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Field Mapping Buf.");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Field Mapping");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Line Def");
        ListOfTablesToMigrate.Add(Database::"Data Exch. Mapping");
        ListOfTablesToMigrate.Add(Database::"Data Exchange Type");
        ListOfTablesToMigrate.Add(Database::"Data Migration Setup");
        ListOfTablesToMigrate.Add(Database::"Data Privacy Entities");
        ListOfTablesToMigrate.Add(Database::"Data Privacy Records");
        ListOfTablesToMigrate.Add(Database::"Date Compr. Register");
        ListOfTablesToMigrate.Add(Database::"Default Dimension Priority");
        ListOfTablesToMigrate.Add(Database::"Default Dimension");
        ListOfTablesToMigrate.Add(Database::"Deferral Header Archive");
        ListOfTablesToMigrate.Add(Database::"Deferral Header");
        ListOfTablesToMigrate.Add(Database::"Deferral Line Archive");
        ListOfTablesToMigrate.Add(Database::"Deferral Line");
        ListOfTablesToMigrate.Add(Database::"Deferral Posting Buffer");
        ListOfTablesToMigrate.Add(Database::"Deferral Template");
        ListOfTablesToMigrate.Add(Database::"Delivery Sorter");
        ListOfTablesToMigrate.Add(Database::"Depreciation Book");
        ListOfTablesToMigrate.Add(Database::"Depreciation Table Header");
        ListOfTablesToMigrate.Add(Database::"Depreciation Table Line");
        ListOfTablesToMigrate.Add(Database::"Designer Diagnostic");
        ListOfTablesToMigrate.Add(Database::"Detailed Cust. Ledg. Entry");
        ListOfTablesToMigrate.Add(Database::"Detailed Employee Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Detailed Vendor Ledg. Entry");
        ListOfTablesToMigrate.Add(Database::"Dim Correct Selection Criteria");
        ListOfTablesToMigrate.Add(Database::"Dim Correction Blocked Setup");
        ListOfTablesToMigrate.Add(Database::"Dim Correction Change");
        ListOfTablesToMigrate.Add(Database::"Dim Correction Entry Log");
        ListOfTablesToMigrate.Add(Database::"Dim Correction Set Buffer");
        ListOfTablesToMigrate.Add(Database::"Dim. Value per Account");
        ListOfTablesToMigrate.Add(Database::"Dimension Combination");
        ListOfTablesToMigrate.Add(Database::"Dimension Correction");
        ListOfTablesToMigrate.Add(Database::"Dimension Set Entry");
        ListOfTablesToMigrate.Add(Database::"Dimension Set ID Filter Line");
        ListOfTablesToMigrate.Add(Database::"Dimension Set Tree Node");
        ListOfTablesToMigrate.Add(Database::"Dimension Translation");
        ListOfTablesToMigrate.Add(Database::"Dimension Value Combination");
        ListOfTablesToMigrate.Add(Database::"Dimension Value");
        ListOfTablesToMigrate.Add(Database::"Dimension");
        ListOfTablesToMigrate.Add(Database::"Dimensions Field Map");
        ListOfTablesToMigrate.Add(Database::"Dimensions Template");
        ListOfTablesToMigrate.Add(Database::"Direct Debit Collection Entry");
        ListOfTablesToMigrate.Add(Database::"Direct Debit Collection");
        ListOfTablesToMigrate.Add(Database::"Direct Trans. Header");
        ListOfTablesToMigrate.Add(Database::"Direct Trans. Line");
        ListOfTablesToMigrate.Add(Database::"Doc. Exch. Service Setup");
        ListOfTablesToMigrate.Add(Database::"Document Attachment");
        ListOfTablesToMigrate.Add(Database::"Document Search Result");
        ListOfTablesToMigrate.Add(Database::"Document Sending Profile");
        ListOfTablesToMigrate.Add(Database::"Dtld. Price Calculation Setup");
        ListOfTablesToMigrate.Add(Database::"Duplicate Search String Setup");
        ListOfTablesToMigrate.Add(Database::"Dynamic Request Page Entity");
        ListOfTablesToMigrate.Add(Database::"Dynamic Request Page Field");
        ListOfTablesToMigrate.Add(Database::"ECSL VAT Report Line Relation");
        ListOfTablesToMigrate.Add(Database::"ECSL VAT Report Line");
        ListOfTablesToMigrate.Add(Database::"Electronic Document Format");
        ListOfTablesToMigrate.Add(Database::"Email Item");
        ListOfTablesToMigrate.Add(Database::"Email Inbox");
        ListOfTablesToMigrate.Add(Database::"Email Outbox");
        ListOfTablesToMigrate.Add(Database::"Email Parameter");
        ListOfTablesToMigrate.Add(8890); // Database:: Email Retry
        ListOfTablesToMigrate.Add(Database::"Email Scenario Attachments");
        ListOfTablesToMigrate.Add(Database::"Employee Absence");
        ListOfTablesToMigrate.Add(Database::"Employee Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Employee Posting Group");
        ListOfTablesToMigrate.Add(Database::"Employee Qualification");
        ListOfTablesToMigrate.Add(Database::"Employee Relative");
        ListOfTablesToMigrate.Add(Database::"Employee Statistics Group");
        ListOfTablesToMigrate.Add(Database::"Employee Templ.");
        ListOfTablesToMigrate.Add(Database::"Employee");
        ListOfTablesToMigrate.Add(Database::"Employment Contract");
        ListOfTablesToMigrate.Add(Database::"Entry/Exit Point");
        ListOfTablesToMigrate.Add(Database::"Error Message Register");
        ListOfTablesToMigrate.Add(Database::"Error Message");
        ListOfTablesToMigrate.Add(Database::"Exch. Rate Adjmt. Ledg. Entry");
        ListOfTablesToMigrate.Add(Database::"Exch. Rate Adjmt. Reg.");
        ListOfTablesToMigrate.Add(Database::"Exchange Folder");
        ListOfTablesToMigrate.Add(Database::"Exchange Service Setup");
        ListOfTablesToMigrate.Add(Database::"Exchange Sync");
        ListOfTablesToMigrate.Add(Database::"Exp. Invt. Order Tracking");
        ListOfTablesToMigrate.Add(Database::"Extended Text Header");
        ListOfTablesToMigrate.Add(Database::"Extended Text Line");
        ListOfTablesToMigrate.Add(Database::"FA Allocation");
        ListOfTablesToMigrate.Add(Database::"FA Class");
        ListOfTablesToMigrate.Add(Database::"FA Date Type");
        ListOfTablesToMigrate.Add(Database::"FA Depreciation Book");
        ListOfTablesToMigrate.Add(Database::"FA Journal Batch");
        ListOfTablesToMigrate.Add(Database::"FA Journal Line");
        ListOfTablesToMigrate.Add(Database::"FA Journal Setup");
        ListOfTablesToMigrate.Add(Database::"FA Journal Template");
        ListOfTablesToMigrate.Add(Database::"FA Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"FA Location");
        ListOfTablesToMigrate.Add(Database::"FA Matrix Posting Type");
        ListOfTablesToMigrate.Add(Database::"FA Posting Group");
        ListOfTablesToMigrate.Add(Database::"FA Posting Type Setup");
        ListOfTablesToMigrate.Add(Database::"FA Posting Type");
        ListOfTablesToMigrate.Add(Database::"FA Reclass. Journal Batch");
        ListOfTablesToMigrate.Add(Database::"FA Reclass. Journal Line");
        ListOfTablesToMigrate.Add(Database::"FA Reclass. Journal Template");
        ListOfTablesToMigrate.Add(Database::"FA Register");
        ListOfTablesToMigrate.Add(Database::"FA Setup");
        ListOfTablesToMigrate.Add(Database::"FA Subclass");
        ListOfTablesToMigrate.Add(Database::"Family Line");
        ListOfTablesToMigrate.Add(Database::"Family");
        ListOfTablesToMigrate.Add(Database::"Fault Area");
        ListOfTablesToMigrate.Add(Database::"Fault Area/Symptom Code");
        ListOfTablesToMigrate.Add(Database::"Fault Code");
        ListOfTablesToMigrate.Add(Database::"Fault Reason Code");
        ListOfTablesToMigrate.Add(Database::"Fault/Resol. Cod. Relationship");
        ListOfTablesToMigrate.Add(Database::"Filed Service Contract Header");
        ListOfTablesToMigrate.Add(Database::"Filed Contract Line");
        ListOfTablesToMigrate.Add(Database::"Filed Serv. Contract Cmt. Line");
        ListOfTablesToMigrate.Add(Database::"Filed Contract Service Hour");
        ListOfTablesToMigrate.Add(Database::"Filed Contract/Serv. Discount");
        ListOfTablesToMigrate.Add(Database::"Fin. Charge Comment Line");
        ListOfTablesToMigrate.Add(Database::"Finance Charge Interest Rate");
        ListOfTablesToMigrate.Add(Database::"Finance Charge Memo Header");
        ListOfTablesToMigrate.Add(Database::"Finance Charge Memo Line");
        ListOfTablesToMigrate.Add(Database::"Finance Charge Terms");
        ListOfTablesToMigrate.Add(Database::"Finance Charge Text");
        ListOfTablesToMigrate.Add(Database::"Finance Cue");
        ListOfTablesToMigrate.Add(Database::"Financial Report");
        ListOfTablesToMigrate.Add(Database::"Financial Report Export Log");
        ListOfTablesToMigrate.Add(Database::"Financial Report Recipient");
        ListOfTablesToMigrate.Add(Database::"Financial Report Schedule");
        ListOfTablesToMigrate.Add(Database::"Financial Report User Filters");
        ListOfTablesToMigrate.Add(Database::"Fin. Report Excel Template");
        ListOfTablesToMigrate.Add(Database::"Fixed Asset");
#if not CLEAN25
        ListOfTablesToMigrate.Add(Database::"FS Connection Setup");
#endif
        ListOfTablesToMigrate.Add(Database::"G/L - Item Ledger Relation");
        ListOfTablesToMigrate.Add(Database::"G/L Acc. Balance Buffer");
        ListOfTablesToMigrate.Add(Database::"G/L Acc. Balance/Budget Buffer");
        ListOfTablesToMigrate.Add(Database::"G/L Account (Analysis View)");
        ListOfTablesToMigrate.Add(Database::"G/L Account Source Currency");
        ListOfTablesToMigrate.Add(Database::"G/L Account Category");
        ListOfTablesToMigrate.Add(Database::"G/L Account Where-Used");
        ListOfTablesToMigrate.Add(Database::"G/L Account");
        ListOfTablesToMigrate.Add(Database::"G/L Budget Entry");
        ListOfTablesToMigrate.Add(Database::"G/L Budget Name");
        ListOfTablesToMigrate.Add(Database::"G/L Entry - VAT Entry Link");
        ListOfTablesToMigrate.Add(Database::"G/L Entry");
        ListOfTablesToMigrate.Add(Database::"G/L Register");
        ListOfTablesToMigrate.Add(Database::"Gen. Business Posting Group");
        ListOfTablesToMigrate.Add(Database::"Gen. Jnl. Allocation");
        ListOfTablesToMigrate.Add(Database::"Gen. Jnl. Dim. Filter");
        ListOfTablesToMigrate.Add(Database::"Gen. Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Gen. Journal Line");
        ListOfTablesToMigrate.Add(Database::"Gen. Journal Template");
        ListOfTablesToMigrate.Add(Database::"Gen. Product Posting Group");
        ListOfTablesToMigrate.Add(Database::"General Ledger Setup");
        ListOfTablesToMigrate.Add(Database::"General Posting Setup");
        ListOfTablesToMigrate.Add(Database::"Generic Chart Filter");
        ListOfTablesToMigrate.Add(Database::"Generic Chart Query Column");
        ListOfTablesToMigrate.Add(Database::"Generic Chart Setup");
        ListOfTablesToMigrate.Add(Database::"Generic Chart Y-Axis");
        ListOfTablesToMigrate.Add(Database::"Geolocation");
        ListOfTablesToMigrate.Add(Database::"Grounds for Termination");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Jnl. Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Purch. Header");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Purch. Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Sales Header");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Sales Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Inbox Trans.");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Jnl. Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Purch. Hdr");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Purch. Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Sales Header");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Sales Line");
        ListOfTablesToMigrate.Add(Database::"Handled IC Outbox Trans.");
        ListOfTablesToMigrate.Add(Database::"HR Confidential Comment Line");
        ListOfTablesToMigrate.Add(Database::"Human Resource Comment Line");
        ListOfTablesToMigrate.Add(Database::"Human Resource Unit of Measure");
        ListOfTablesToMigrate.Add(Database::"Human Resources Setup");
        ListOfTablesToMigrate.Add(Database::"IC Comment Line");
        ListOfTablesToMigrate.Add(Database::"IC Dimension Value");
        ListOfTablesToMigrate.Add(Database::"IC Dimension");
        ListOfTablesToMigrate.Add(Database::"IC Document Dimension");
        ListOfTablesToMigrate.Add(Database::"IC G/L Account");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Jnl. Line");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Purchase Header");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Purchase Line");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Sales Header");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Sales Line");
        ListOfTablesToMigrate.Add(Database::"IC Inbox Transaction");
        ListOfTablesToMigrate.Add(Database::"IC Inbox/Outbox Jnl. Line Dim.");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Jnl. Line");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Purchase Header");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Purchase Line");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Sales Header");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Sales Line");
        ListOfTablesToMigrate.Add(Database::"IC Outbox Transaction");
        ListOfTablesToMigrate.Add(Database::"IC Partner");
        ListOfTablesToMigrate.Add(Database::"IC Setup");
        ListOfTablesToMigrate.Add(Database::"Import G/L Transaction");
        ListOfTablesToMigrate.Add(Database::"Incoming Document Attachment");
        ListOfTablesToMigrate.Add(Database::"Incoming Document");
        ListOfTablesToMigrate.Add(Database::"Incoming Documents Setup");
        ListOfTablesToMigrate.Add(Database::"Industry Group");
        ListOfTablesToMigrate.Add(Database::"Ins. Coverage Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Insurance Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Insurance Journal Line");
        ListOfTablesToMigrate.Add(Database::"Insurance Journal Template");
        ListOfTablesToMigrate.Add(Database::"Insurance Register");
        ListOfTablesToMigrate.Add(Database::"Insurance Type");
        ListOfTablesToMigrate.Add(Database::"Insurance");
        ListOfTablesToMigrate.Add(Database::"Int. Table Config Template");
        ListOfTablesToMigrate.Add(Database::"Integration Field Mapping");
        ListOfTablesToMigrate.Add(Database::"Integration Table Mapping");
        ListOfTablesToMigrate.Add(Database::"Inter. Log Entry Comment Line");
        ListOfTablesToMigrate.Add(Database::"Interaction Group");
        ListOfTablesToMigrate.Add(Database::"Interaction Log Entry");
        ListOfTablesToMigrate.Add(Database::"Interaction Merge Data");
        ListOfTablesToMigrate.Add(Database::"Interaction Template Setup");
        ListOfTablesToMigrate.Add(Database::"Interaction Template");
        ListOfTablesToMigrate.Add(Database::"Interaction Tmpl. Language");
        ListOfTablesToMigrate.Add(Database::"Intermediate Data Import");
        ListOfTablesToMigrate.Add(Database::"Internal Movement Header");
        ListOfTablesToMigrate.Add(Database::"Internal Movement Line");
        ListOfTablesToMigrate.Add(Database::"Invalidated Dim Correction");
        ListOfTablesToMigrate.Add(Database::"Inventory Adjmt. Entry (Order)");
        ListOfTablesToMigrate.Add(Database::"Inventory Comment Line");
        ListOfTablesToMigrate.Add(Database::"Inventory Page Data");
        ListOfTablesToMigrate.Add(Database::"Inventory Period Entry");
        ListOfTablesToMigrate.Add(Database::"Inventory Period");
        ListOfTablesToMigrate.Add(Database::"Inventory Posting Group");
        ListOfTablesToMigrate.Add(Database::"Inventory Posting Setup");
        ListOfTablesToMigrate.Add(Database::"Inventory Profile");
        ListOfTablesToMigrate.Add(Database::"Inventory Report Entry");
        ListOfTablesToMigrate.Add(Database::"Inventory Report Header");
        ListOfTablesToMigrate.Add(Database::"Inventory Setup");
        ListOfTablesToMigrate.Add(Database::"Invoiced Booking Item");
        ListOfTablesToMigrate.Add(Database::"Invt. Document Header");
        ListOfTablesToMigrate.Add(Database::"Invt. Document Line");
        ListOfTablesToMigrate.Add(Database::"Invt. Receipt Header");
        ListOfTablesToMigrate.Add(Database::"Invt. Receipt Line");
        ListOfTablesToMigrate.Add(Database::"Invt. Shipment Header");
        ListOfTablesToMigrate.Add(Database::"Invt. Shipment Line");
        ListOfTablesToMigrate.Add(Database::"Issued Fin. Charge Memo Header");
        ListOfTablesToMigrate.Add(Database::"Issued Fin. Charge Memo Line");
        ListOfTablesToMigrate.Add(Database::"Issued Reminder Header");
        ListOfTablesToMigrate.Add(Database::"Issued Reminder Line");
        ListOfTablesToMigrate.Add(Database::"Item Amount");
        ListOfTablesToMigrate.Add(Database::"Item Analysis View Budg. Entry");
        ListOfTablesToMigrate.Add(Database::"Item Analysis View Entry");
        ListOfTablesToMigrate.Add(Database::"Item Analysis View Filter");
        ListOfTablesToMigrate.Add(Database::"Item Analysis View");
        ListOfTablesToMigrate.Add(Database::"Item Application Entry History");
        ListOfTablesToMigrate.Add(Database::"Item Application Entry");
        ListOfTablesToMigrate.Add(Database::"Item Attr. Value Translation");
        ListOfTablesToMigrate.Add(Database::"Item Attribute Translation");
        ListOfTablesToMigrate.Add(Database::"Item Attribute Value Mapping");
        ListOfTablesToMigrate.Add(Database::"Item Attribute Value Selection");
        ListOfTablesToMigrate.Add(Database::"Item Attribute Value");
        ListOfTablesToMigrate.Add(Database::"Item Attribute");
        ListOfTablesToMigrate.Add(Database::"Item Availability Buffer");
        ListOfTablesToMigrate.Add(Database::"Item Availability by Date");
        ListOfTablesToMigrate.Add(Database::"Item Availability Line");
        ListOfTablesToMigrate.Add(Database::"Item Budget Entry");
        ListOfTablesToMigrate.Add(Database::"Item Budget Name");
        ListOfTablesToMigrate.Add(Database::"Item Category");
        ListOfTablesToMigrate.Add(Database::"Item Charge Assignment (Purch)");
        ListOfTablesToMigrate.Add(Database::"Item Charge Assignment (Sales)");
        ListOfTablesToMigrate.Add(Database::"Item Charge");
        ListOfTablesToMigrate.Add(Database::"Item Discount Group");
        ListOfTablesToMigrate.Add(Database::"Item Entry Relation");
        ListOfTablesToMigrate.Add(Database::"Item Identifier");
        ListOfTablesToMigrate.Add(Database::"Item Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Item Journal Line");
        ListOfTablesToMigrate.Add(Database::"Item Journal Template");
        ListOfTablesToMigrate.Add(Database::"Item Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Item Reference");
        ListOfTablesToMigrate.Add(Database::"Item Register");
        ListOfTablesToMigrate.Add(Database::"Item Substitution");
        ListOfTablesToMigrate.Add(Database::"Item Templ.");
        ListOfTablesToMigrate.Add(Database::"Item Tracking Code");
        ListOfTablesToMigrate.Add(Database::"Item Tracking Comment");
        ListOfTablesToMigrate.Add(Database::"Item Translation");
        ListOfTablesToMigrate.Add(Database::"Item Turnover Buffer");
        ListOfTablesToMigrate.Add(Database::"Item Unit of Measure");
        ListOfTablesToMigrate.Add(Database::"Item Variant");
        ListOfTablesToMigrate.Add(Database::"Item Vendor");
        ListOfTablesToMigrate.Add(Database::"Item");
        ListOfTablesToMigrate.Add(Database::"Job Cue");
        ListOfTablesToMigrate.Add(Database::"Job Entry No.");
        ListOfTablesToMigrate.Add(Database::"Job Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Job Journal Line");
        ListOfTablesToMigrate.Add(Database::"Job Journal Quantity");

        CloudMigCountryTables.GetTablesThatShouldBeCloudMigrated(ListOfTablesToMigrate);
    end;
}