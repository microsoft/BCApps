codeunit 103301 "WMS Set Global Preconditions"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        if AutoDeleteOldData then
            DeleteOldData()
        else
            case StrMenu('Delete old data,Keep old data', 1) of
                0:
                    exit;
                1:
                    DeleteOldData();
            end;
        SetupAccountingPeriods();
        MaintGenPostSetup();
        SetupCostCodes();
        MaintInvtSetup();
        MaintTransferRoutes();
        SetupUser();
        MaintLocation();
        SetupZoneBin();
        MaintZoneBin();
        MaintItemTrackCode();
        MaintServGroup();
        SetupFilters();
        MaintSaleReceiveSetup();
        MaintPurchPayableSetup();
        MaintWhseSetup();
        SetupItemJnlBatch();
        SetupWhseJnlBatch();
        SetupWkshTemplate();
        SetupWkshName();
        SetupMovementWkshName();
        CreateWMSItems();
        CreateWorkCenter();
        MaintQASetup();
        ResetNoSeries();
        WorkDate(20011125D);
    end;

    var
        AutoDeleteOldData: Boolean;
        iU: Integer;
        UnitOfMeasure: array[10] of Code[10];
        QtyPerUnitOfMeasure: array[10] of Decimal;
        iV: Integer;
        VariantCode: array[10] of Code[10];
        iS: Integer;
        SKULocationCode: array[10] of Code[10];
        SKUVariantCode: array[10] of Code[10];
        SKUStdCost: array[10] of Decimal;
        SKUValid: array[10] of Boolean;
        Text000: Label '%1 Worksheet';

    local procedure DeleteOldData()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        AverageCostAdjustment: Record "Avg. Cost Adjmt. Entry Point";
        BankAccountLedgEntry: Record "Bank Account Ledger Entry";
        BinContent: Record "Bin Content";
        CalendarEntry: Record "Calendar Entry";
        CampaignEntry: Record "Campaign Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DefDim: Record "Default Dimension";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        FALedgEntry: Record "FA Ledger Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        ValueEntryRelation: Record "Value Entry Relation";
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemApplEntry: Record "Item Application Entry";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemRegister: Record "Item Register";
        OrderAdjmtEntry: Record "Inventory Adjmt. Entry (Order)";
        ItemTrkgComnt: Record "Item Tracking Comment";
        ItemVariant: Record "Item Variant";
        JobJnlLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobEntryNo: Record "Job Entry No.";
        JobLedgEntry: Record "Job Ledger Entry";
        JobRegister: Record "Job Register";
        ItemEntryRelation: Record "Item Entry Relation";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        PostInvPickHdr: Record "Posted Invt. Pick Header";
        PostInvPickLine: Record "Posted Invt. Pick Line";
        PostInvPutAwayHdr: Record "Posted Invt. Put-away Header";
        PostInvPutAwayLine: Record "Posted Invt. Put-away Line";
        PostWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        PostWhseActivityLine: Record "Registered Whse. Activity Line";
        PriceListLine: Record "Price List Line";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHdr: Record "Production BOM Header";
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdOrder: Record "Production Order";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutLine: Record "Prod. Order Routing Line";
        PurchChargeAssignLine: Record "Item Charge Assignment (Purch)";
        PurchComntLine: Record "Purch. Comment Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchHdr: Record "Purchase Header";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchLine: Record "Purchase Line";
        PurchRcptHdr: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResEntry: Record "Reservation Entry";
        ResJnlLine: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        ResRegister: Record "Resource Register";
        ReturnRcptHdr: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        ReturnShipHdr: Record "Return Shipment Header";
        ReturnShipLine: Record "Return Shipment Line";
        ReturnRelatedDoc: Record "Returns-Related Document";
        RoutingHdr: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SalesChargeAssignLine: Record "Item Charge Assignment (Sales)";
        SalesComntLine: Record "Sales Comment Line";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHdr: Record "Sales Header";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesShptHdr: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransHdr: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransRcptHdr: Record "Transfer Receipt Header";
        TransRcptLine: Record "Transfer Receipt Line";
        TransShptHdr: Record "Transfer Shipment Header";
        TransShptLine: Record "Transfer Shipment Line";
        ValuEntry: Record "Value Entry";
        VATEntry: Record "VAT Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WhseEntry: Record "Warehouse Entry";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseRequest: Record "Warehouse Request";
        WhseRegister: Record "Warehouse Register";
        WhseRcptHdr: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseRcptHdrPosted: Record "Posted Whse. Receipt Header";
        WhseRcptLinePosted: Record "Posted Whse. Receipt Line";
        WhseShipHdr: Record "Warehouse Shipment Header";
        WhseShipLine: Record "Warehouse Shipment Line";
        WhseShipHdrPosted: Record "Posted Whse. Shipment Header";
        WhseShipLinePosted: Record "Posted Whse. Shipment Line";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePutAwayOrderHdr: Record "Whse. Internal Put-away Header";
        WhsePutAwayOrderLine: Record "Whse. Internal Put-away Line";
        WhsePickOrderHdr: Record "Whse. Internal Pick Header";
        WhsePickOrderLine: Record "Whse. Internal Pick Line";
        Bin: Record Bin;
        WhseItemTrackLine: Record "Whse. Item Tracking Line";
        WhseItemEntryRel: Record "Whse. Item Entry Relation";
        TrackingSpec: Record "Tracking Specification";
        ServItem: Record "Service Item";
        ServHeader: Record "Service Header";
        ServLine: Record "Service Item Line";
        LotNoInfo: Record "Lot No. Information";
        ReqLine: Record "Requisition Line";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GlEntryVatEntrylink: Record "G/L Entry - VAT Entry Link";
        PlanningAssignment: Record "Planning Assignment";
    begin
        AnalysisViewBudgetEntry.DeleteAll();
        AnalysisViewEntry.DeleteAll();
        AverageCostAdjustment.DeleteAll();
        BankAccountLedgEntry.DeleteAll();
        BinContent.DeleteAll();
        CalendarEntry.DeleteAll();
        CampaignEntry.DeleteAll();
        CustLedgEntry.DeleteAll();
        DefDim.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();
        FALedgEntry.DeleteAll();
        GLBudgetEntry.DeleteAll();
        GLEntry.DeleteAll();
        GLItemLedgRelation.DeleteAll();
        GLRegister.DeleteAll();
        InsCoverageLedgEntry.DeleteAll();
        ItemAnalysisView.DeleteAll();
        ItemAnalysisViewFilter.DeleteAll();
        ItemAnalysisViewEntry.DeleteAll();
        ItemAnalysisViewBudgEntry.DeleteAll();
        ItemApplEntry.DeleteAll();
        ItemJnlLine.DeleteAll();
        ItemLedgEntry.DeleteAll();
        ItemRegister.DeleteAll();
        ItemTrkgComnt.DeleteAll();
        ItemVariant.DeleteAll();
        OrderAdjmtEntry.DeleteAll();
        JobTask.DeleteAll();
        JobPlanningLine.DeleteAll();
        JobWIPEntry.DeleteAll();
        JobWIPGLEntry.DeleteAll();
        JobEntryNo.DeleteAll();
        JobJnlLine.DeleteAll();
        JobRegister.DeleteAll();
        JobLedgEntry.DeleteAll();
        JobRegister.DeleteAll();
        MaintenanceLedgEntry.DeleteAll();
        PhysInvtLedgEntry.DeleteAll();
        PostInvPickHdr.DeleteAll();
        PostInvPickLine.DeleteAll();
        PostInvPutAwayHdr.DeleteAll();
        PostInvPutAwayLine.DeleteAll();
        PostWhseActivityHdr.DeleteAll();
        PostWhseActivityLine.DeleteAll();
        PriceListLine.DeleteAll();
        ProdBOMLine.DeleteAll();
        ProdBOMHdr.DeleteAll();
        ProdForecastEntry.DeleteAll();
        ProdOrder.DeleteAll();
        ProdOrderCapNeed.DeleteAll();
        ProdOrderComp.DeleteAll();
        ProdOrderLine.DeleteAll();
        ProdOrderRoutLine.DeleteAll();
        PurchChargeAssignLine.DeleteAll();
        PurchComntLine.DeleteAll();
        PurchCrMemoHdr.DeleteAll();
        PurchCrMemoLine.DeleteAll();
        PurchHdr.DeleteAll();
        PurchInvHdr.DeleteAll();
        PurchInvLine.DeleteAll();
        PurchLine.DeleteAll();
        PurchRcptHdr.DeleteAll();
        PurchRcptLine.DeleteAll();
        ResCapacityEntry.DeleteAll();
        ResEntry.DeleteAll();
        ResJnlLine.DeleteAll();
        ResLedgEntry.DeleteAll();
        ResRegister.DeleteAll();
        ReturnRcptHdr.DeleteAll();
        ReturnRcptLine.DeleteAll();
        ReturnShipHdr.DeleteAll();
        ReturnShipLine.DeleteAll();
        ReturnRelatedDoc.DeleteAll();
        RoutingHdr.DeleteAll();
        RoutingLine.DeleteAll();
        CapLedgEntry.DeleteAll();
        SalesChargeAssignLine.DeleteAll();
        SalesComntLine.DeleteAll();
        SalesCrMemoHdr.DeleteAll();
        SalesCrMemoLine.DeleteAll();
        SalesHdr.DeleteAll();
        SalesInvHdr.DeleteAll();
        SalesInvLine.DeleteAll();
        SalesLine.DeleteAll();
        SalesShptHdr.DeleteAll();
        SalesShptLine.DeleteAll();
        StockkeepingUnit.DeleteAll();
        TransHdr.DeleteAll();
        TransLine.DeleteAll();
        TransRcptHdr.DeleteAll();
        TransRcptLine.DeleteAll();
        TransShptHdr.DeleteAll();
        TransShptLine.DeleteAll();
        ValuEntry.DeleteAll();
        VATEntry.DeleteAll();
        VendLedgEntry.DeleteAll();
        WhseActivityHdr.DeleteAll();
        WhseActivityLine.DeleteAll();
        WhseEntry.DeleteAll();
        WhseCrossDockOpportunity.DeleteAll();
        WhseJnlLine.DeleteAll();
        WhseRegister.DeleteAll();
        WhseRequest.DeleteAll();
        WhseRegister.DeleteAll();
        WhseRcptHdr.DeleteAll();
        WhseRcptLine.DeleteAll();
        WhseRcptHdrPosted.DeleteAll();
        WhseRcptLinePosted.DeleteAll();
        WhseShipHdr.DeleteAll();
        WhseShipLine.DeleteAll();
        WhseShipHdrPosted.DeleteAll();
        WhseShipLinePosted.DeleteAll();
        WhsePutAwayRequest.DeleteAll();
        WhsePickRequest.DeleteAll();
        WhseWorksheetLine.DeleteAll();
        WhseWorksheetTemplate.DeleteAll();
        WhseWorksheetName.DeleteAll();
        WhsePutAwayOrderHdr.DeleteAll();
        WhsePutAwayOrderLine.DeleteAll();
        WhsePickOrderHdr.DeleteAll();
        WhsePickOrderLine.DeleteAll();
        ValueEntryRelation.DeleteAll();
        ItemEntryRelation.DeleteAll();
        WhseItemTrackLine.DeleteAll();
        WhseItemEntryRel.DeleteAll();
        TrackingSpec.DeleteAll();
        ServItem.DeleteAll();
        ServHeader.DeleteAll();
        ServLine.DeleteAll();
        LotNoInfo.DeleteAll();
        ReqLine.DeleteAll();
        Bin.ModifyAll(Empty, true);
        Bin.ModifyAll("Block Movement", 0);
        PostValueEntryToGL.DeleteAll();
        GLItemLedgRelation.DeleteAll();
        GlEntryVatEntrylink.DeleteAll();
        PlanningAssignment.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetupAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        StartingDate: Date;
        EndingDate: Date;
    begin
        AccountingPeriod.DeleteAll();
        StartingDate := 19990101D;
        EndingDate := 20020201D;

        while StartingDate <= EndingDate do begin
            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", StartingDate);
            if (Date2DMY(StartingDate, 1) = 1) and
               (Date2DMY(StartingDate, 2) = 1)
            then begin
                AccountingPeriod."New Fiscal Year" := true;
                if StartingDate = 19990101D then
                    AccountingPeriod."Date Locked" := true;

                if StartingDate = 20000101D then
                    AccountingPeriod."Date Locked" := true;
                AccountingPeriod."Average Cost Calc. Type" :=
                  AccountingPeriod."Average Cost Calc. Type"::Item;
                AccountingPeriod."Average Cost Period" :=
                  AccountingPeriod."Average Cost Period"::Day;
            end;
            if Date2DMY(StartingDate, 3) = 1999 then begin
                AccountingPeriod.Closed := true;
                AccountingPeriod."Date Locked" := true;
            end;
            AccountingPeriod.Insert();
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
    end;

    local procedure MaintGenPostSetup()
    var
        GenPostSetup: Record "General Posting Setup";
    begin
        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Account", '');
            GenPostSetup.Validate("Purch. Credit Memo Account", '');
            GenPostSetup.Validate("Sales Account", '');
            GenPostSetup.Validate("Sales Credit Memo Account", '');
            GenPostSetup.Modify();
        end;
    end;

    local procedure SetupCostCodes()
    begin
        MaintCostCode('GPS', 'German Parcel Service', 'RAW MAT', 'VAT25');
        MaintCostCode('INSURANCE', 'Lloyd''s', 'RETAIL', 'VAT10');
        MaintCostCode('UPS', 'United Parcel Service', 'RETAIL', 'VAT25');
    end;

    local procedure MaintCostCode(NewCode: Code[10]; NewDescription: Text[50]; NewGenProdPostGrp: Code[10]; NewVATProdPostGrp: Code[10])
    var
        CostCode: Record "Item Charge";
    begin
        CostCode.Validate("No.", NewCode);
        if not CostCode.Insert(true) then;

        CostCode.Validate(Description, NewDescription);
        CostCode.Validate("Gen. Prod. Posting Group", NewGenProdPostGrp);
        CostCode.Validate("VAT Prod. Posting Group", NewVATProdPostGrp);
        CostCode.Modify(true);
    end;

    local procedure MaintInvtSetup()
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        InvtSetup.Validate("Expected Cost Posting to G/L", false);
        InvtSetup.Validate("Automatic Cost Posting", false);
        InvtSetup."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant";
        InvtSetup.Validate("Location Mandatory", false);
        InvtSetup.Validate("Automatic Cost Adjustment", InvtSetup."Automatic Cost Adjustment"::Never);
        InvtSetup."Average Cost Period" := InvtSetup."Average Cost Period"::Day;
        InvtSetup.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InvtSetup);
    end;

    [Scope('OnPrem')]
    procedure MaintTransferRoutes()
    var
        TransRoute: Record "Transfer Route";
    begin
        TransRoute.Init();
        TransRoute."Transfer-from Code" := 'BLUE';
        TransRoute."Transfer-to Code" := 'RED';
        TransRoute."In-Transit Code" := 'OWN LOG.';
        if not TransRoute.Insert() then
            TransRoute.Modify();
        TransRoute.Init();
        TransRoute."Transfer-from Code" := 'GREEN';
        TransRoute."Transfer-to Code" := 'WHITE';
        TransRoute."In-Transit Code" := '';
        if not TransRoute.Insert() then
            TransRoute.Modify();
    end;

    local procedure MaintServGroup()
    var
        ServItemGroup: Record "Service Item Group";
    begin
        ServItemGroup.Get('DESKTOP');
        ServItemGroup.Validate("Create Service Item", false);
        ServItemGroup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupUser()
    var
        NewEmployee: Record "Warehouse Employee";
    begin
        NewEmployee."User ID" := 'ADMIN';
        NewEmployee."Location Code" := 'WHITE';
        NewEmployee.Default := true;
        if not NewEmployee.Insert(true) then;
        NewEmployee.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupZoneBin()
    var
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", 'SILVER');
        Zone.SetRange(Code, 'PRODUCTION');
        if Zone.Find('-') then begin
            Zone."Bin Type Code" := 'QC';
            Zone.Modify(true);
        end;

        Zone.Reset();
        Zone.SetRange("Location Code", 'WHITE');
        Zone.SetRange(Code, 'BULK');
        if Zone.Find('-') then begin
            Zone."Bin Type Code" := 'PUT AWAY';
            Zone.Modify(true);
        end;
        Zone.SetRange(Code, 'PRODUCTION');
        if Zone.Find('-') then begin
            Zone."Bin Type Code" := 'QC';
            Zone.Modify(true);
        end;

        Bin.SetRange("Location Code", 'WHITE');
        Bin.SetRange(Code, 'W-07-0001');
        if Bin.Find('-') then begin
            Bin.SetUpNewLine();
            Bin.Validate("Bin Ranking", 110);
            Bin.Modify(true);
        end;
        Bin.SetRange(Code, 'W-07-0002');
        if Bin.Find('-') then begin
            Bin.SetUpNewLine();
            Bin.Validate("Bin Ranking", 100);
            Bin.Modify(true);
        end;
        Bin.SetRange(Code, 'W-07-0003');
        if Bin.Find('-') then begin
            Bin.SetUpNewLine();
            Bin.Validate("Bin Ranking", 40);
            Bin.Modify(true);
        end;

        Bin.Reset();
        Bin.SetRange("Location Code", 'White');
        Bin.SetRange("Zone Code", 'Bulk');
        if Bin.Find('-') then
            repeat
                Bin.SetUpNewLine();
                Bin.Modify(true);
            until Bin.Next() = 0;

        Bin.Reset();
        Bin.SetFilter("Location Code", '%1|%2', 'SILVER', 'WHITE');
        if Bin.Find('-') then
            repeat
                Bin."Warehouse Class Code" := '';
                Bin.Modify(true);
            until Bin.Next() = 0;
    end;

    local procedure MaintLocation()
    var
        Location: Record Location;
    begin
        Location.Get('BLUE');
        Location.Validate("Use As In-Transit", false);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Bin Mandatory", false);
        Location.Validate("Require Receive", false);
        Location.Validate("Require Shipment", false);
        Location.Validate("Require Put-away", false);
        Location.Validate("Require Pick", false);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Adjustment Bin Code", '');
        Evaluate(Location."Outbound Whse. Handling Time", '0' + 'D');
        Evaluate(Location."Inbound Whse. Handling Time", '0' + 'D');
        Location.Modify(true);

        Location.Get('GREEN');
        Location.Validate("Use As In-Transit", false);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Bin Mandatory", false);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Adjustment Bin Code", '');
        Evaluate(Location."Outbound Whse. Handling Time", '0' + 'D');
        Evaluate(Location."Inbound Whse. Handling Time", '0' + 'D');
        Location.Modify(true);

        Location.Get('SILVER');
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Require Receive", false);
        Location.Validate("Require Shipment", false);
        Location.Validate("Require Put-away", false);
        Location.Validate("Require Pick", false);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Default Bin Selection", 1);
        Location.Modify(true);

        Location.Get('WHITE');
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Directed Put-away and Pick", true);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Open Shop Floor Bin Code", 'W-07-0001');
        Location.Validate("To-Production Bin Code", 'W-07-0002');
        Location.Validate("From-Production Bin Code", 'W-07-0003');
        Location.Validate("Receipt Bin Code", 'W-08-0001');
        Location.Validate("Shipment Bin Code", 'W-09-0001');
        Location.Validate("Cross-Dock Bin Code", 'W-14-0001');
        Location.Validate("Adjustment Bin Code", 'W-11-0001');
        Location.Validate("Bin Capacity Policy", 0);
        Location."Use ADCS" := false;
        Evaluate(Location."Outbound Whse. Handling Time", '0' + 'D');
        Evaluate(Location."Inbound Whse. Handling Time", '0' + 'D');
        Location.Modify(true);
        //Set default values for location WHITE
        SetupLocation('STD', true, false, false, false, 0);

        Location.Get('RED');
        Location.Validate("Use As In-Transit", false);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Bin Mandatory", false);
        Location.Validate("Require Receive", false);
        Location.Validate("Require Shipment", false);
        Location.Validate("Require Put-away", false);
        Location.Validate("Require Pick", false);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Adjustment Bin Code", '');
        Evaluate(Location."Outbound Whse. Handling Time", '0' + 'D');
        Evaluate(Location."Inbound Whse. Handling Time", '0' + 'D');
        Location.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintZoneBin()
    var
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        Bin.Get('BLUE', 'A1');
        Bin."Bin Type Code" := '';
        Bin."Zone Code" := '';
        Bin.Modify(true);

        Zone.Reset();
        Zone.SetRange("Location Code", 'BLUE');
        Zone.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure MaintItemTrackCode()
    var
        ItemTrackCode: Record "Item Tracking Code";
    begin
        ItemTrackCode.Get('SNALL');
        ItemTrackCode.Validate("Man. Warranty Date Entry Reqd.", false);
        ItemTrackCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackCode.Validate("Strict Expiration Posting", false);
        ItemTrackCode.Validate("SN Specific Tracking", true);
        ItemTrackCode.Validate("SN Warehouse Tracking", true);
        ItemTrackCode.Modify(true);
        ItemTrackCode.Get('LOTALL');
        ItemTrackCode.Validate("Man. Warranty Date Entry Reqd.", false);
        ItemTrackCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackCode.Validate("Strict Expiration Posting", false);
        ItemTrackCode.Validate("Lot Specific Tracking", true);
        ItemTrackCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackCode."Lot Info. Inbound Must Exist" := false;
        ItemTrackCode."Lot Info. Outbound Must Exist" := false;
        ItemTrackCode.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupLocation(NewPutAwayTemplate: Code[10]; NewAllowBreakBulk: Boolean; NewUsePutAwayWorksheet: Boolean; NewCreateEmptyPutAwayLine: Boolean; NewCreateEmptyPickLine: Boolean; NewDefEquipmentAssign: Option)
    var
        Location: Record Location;
    begin
        Location.Get('WHITE');
        Location.Validate("Put-away Template Code", NewPutAwayTemplate);
        Location.Validate("Allow Breakbulk", NewAllowBreakBulk);
        Location.Validate("Use Put-away Worksheet", NewUsePutAwayWorksheet);
        Location.Validate("Always Create Put-away Line", NewCreateEmptyPutAwayLine);
        Location.Validate("Always Create Pick Line", NewCreateEmptyPickLine);
        Location.Validate("Special Equipment", NewDefEquipmentAssign);
        Location.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupFilters()
    begin
        MaintFilters(0, 'VEND30000', 'Vendor No. 30000', false, '30000', '', '', '', '');
        MaintFilters(0, 'RECVGREEN', 'Receive from Location GREEN', false, '', '', 'GREEN', 'Own Log.', '');
        MaintFilters(0, 'VEND10000', 'Vendor No. 10000', false, '10000', '', '', '', '');
        MaintFilters(0, 'RECEIVEBLU', 'Receive from Location BLUE', false, '', '', 'BLUE', 'Own Log.', '');
        MaintFilters(0, 'CUST30000', 'Customer No. 30000', false, '', '30000', '', '', '');
        MaintFilters(1, 'VEND30000', 'Vendor No. 30000', false, '30000', '', '', '', '');
        MaintFilters(1, 'VEND10000', 'Vendor No. 10000', false, '10000', '', '', '', '');
        MaintFilters(1, 'SHIPGREEN', 'Ship to Location GREEN', false, '', '', '', 'Own Log.', 'GREEN');
        MaintFilters(1, 'SHIPBLU', 'Ship to Location BLUE', false, '', '', '', 'Own Log.', 'Blue');
        MaintFilters(1, 'CUST30000', 'Customer No. 30000', false, '', '30000', '', '', '');
    end;

    [Scope('OnPrem')]
    procedure MaintFilters(NewType: Option; NewCode: Code[10]; NewDescription: Text[30]; NewDoNotFillQtytoHandle: Boolean; NewBuyFromVendorNoFilter: Code[100]; NewSellToCustomerNoFilter: Code[100]; NewTransferFromCodeFilter: Code[100]; NewInTransitCodeFilter: Code[100]; NewTransferToCodeFilter: Code[100])
    var
        WhseSourceFilter: Record "Warehouse Source Filter";
    begin
        WhseSourceFilter.Init();
        WhseSourceFilter.Validate(Type, NewType);
        WhseSourceFilter.Validate(Code, NewCode);
        WhseSourceFilter.Validate(Description, NewDescription);
        WhseSourceFilter.Validate("Do Not Fill Qty. to Handle", NewDoNotFillQtytoHandle);
        WhseSourceFilter.Validate("Buy-from Vendor No. Filter", NewBuyFromVendorNoFilter);
        WhseSourceFilter.Validate("Sell-to Customer No. Filter", NewSellToCustomerNoFilter);
        WhseSourceFilter.Validate("Transfer-from Code Filter", NewTransferFromCodeFilter);
        WhseSourceFilter.Validate("In-Transit Code Filter", NewInTransitCodeFilter);
        WhseSourceFilter.Validate("Transfer-to Code Filter", NewTransferToCodeFilter);
        if not WhseSourceFilter.Insert(true) then
            WhseSourceFilter.Modify(true);
    end;

    local procedure MaintSaleReceiveSetup()
    var
        SaleReceiveSetup: Record "Sales & Receivables Setup";
    begin
        SaleReceiveSetup.Get();
        SaleReceiveSetup.Validate("Calc. Inv. Discount", false);
        SaleReceiveSetup.Validate("Exact Cost Reversing Mandatory", false);
        SaleReceiveSetup.Validate("Credit Warnings", SaleReceiveSetup."Credit Warnings"::"No Warning");
        SaleReceiveSetup.Validate("Stockout Warning", false);
        SaleReceiveSetup.Modify(true);
    end;

    local procedure MaintPurchPayableSetup()
    var
        PurchPayableSetup: Record "Purchases & Payables Setup";
    begin
        PurchPayableSetup.Get();
        PurchPayableSetup.Validate("Calc. Inv. Discount", false);
        PurchPayableSetup.Validate("Exact Cost Reversing Mandatory", false);
        PurchPayableSetup."Discount Posting" := PurchPayableSetup."Discount Posting"::"All Discounts";
        PurchPayableSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchPayableSetup.Modify(true);
    end;

    local procedure MaintWhseSetup()
    var
        WhseSetup: Record "Warehouse Setup";
    begin
        WhseSetup.Get();
        WhseSetup.Validate("Receipt Posting Policy", WhseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WhseSetup.Validate("Shipment Posting Policy", WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WhseSetup.Modify(true);
    end;

    local procedure SetupItemJnlBatch()
    begin
        MaintItemJnlBatch('ITEM', 'DEFAULT', 'Default Journal');
        MaintItemJnlBatch('RECLASS', 'DEFAULT', 'Default Journal');
        MaintItemJnlBatch('REVAL', 'DEFAULT', 'Default Journal');
    end;

    local procedure MaintItemJnlBatch(NewJnlTmplName: Code[10]; NewName: Code[10]; NewDescription: Text[50])
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch.Validate("Journal Template Name", NewJnlTmplName);
        ItemJnlBatch.Validate(Name, NewName);
        ItemJnlBatch.Validate(Description, NewDescription);
        if not ItemJnlBatch.Insert(true) then
            ItemJnlBatch.Modify(true);
    end;

    local procedure SetupWhseJnlBatch()
    begin
        MaintWhseJnlBatch('ADJMT', 'DEFAULT', 'Default Journal', 'WHITE');
        MaintWhseJnlBatch('RECLASS', 'DEFAULT', 'Default Journal', 'WHITE');
        MaintWhseJnlBatch('PHYSINVT', 'DEFAULT', 'Default Journal', 'WHITE');
    end;

    local procedure MaintWhseJnlBatch(NewJnlTmplName: Code[10]; NewName: Code[10]; NewDescription: Text[50]; NewLocationCode: Code[10])
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        WhseJnlBatch.Init();
        WhseJnlBatch.Validate("Journal Template Name", NewJnlTmplName);
        WhseJnlBatch.Validate(Name, NewName);
        WhseJnlBatch.Validate(Description, NewDescription);
        WhseJnlBatch.SetupNewBatch();
        WhseJnlBatch.Validate("Location Code", NewLocationCode);
        if not WhseJnlBatch.Insert(true) then
            WhseJnlBatch.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupWkshTemplate()
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        FormTemplate: Integer;
    begin
        for FormTemplate := 0 to 2 do begin
            WhseWkshTemplate.Init();
            WhseWkshTemplate.Validate(Type, FormTemplate);
            WhseWkshTemplate.Validate("Page ID");
            WhseWkshTemplate.Name := Format(WhseWkshTemplate.Type, MaxStrLen(WhseWkshTemplate.Name));
            WhseWkshTemplate.Description := StrSubstNo(Text000, WhseWkshTemplate.Type);
            WhseWkshTemplate.Insert();
        end;
    end;

    local procedure SetupWkshName()
    begin
        MaintWkshName('PICK', 'DEFAULT', 'Default Journal', 'GREEN');
        MaintWkshName('PUT-AWAY', 'DEFAULT', 'Default Journal', 'GREEN');
        MaintWkshName('PICK', 'DEFAULT', 'Default Journal', 'SILVER');
        MaintWkshName('PUT-AWAY', 'DEFAULT', 'Default Journal', 'SILVER');
        MaintWkshName('MOVEMENT', 'DEFAULT', 'Default Journal', 'WHITE');
        MaintWkshName('PICK', 'DEFAULT', 'Default Journal', 'WHITE');
        MaintWkshName('PUT-AWAY', 'DEFAULT', 'Default Journal', 'WHITE');
    end;

    local procedure MaintWkshName(NewWkshTmplName: Code[10]; NewName: Code[10]; NewDescription: Text[50]; NewLocationCode: Code[10])
    var
        WhseWkshName: Record "Whse. Worksheet Name";
    begin
        WhseWkshName.Init();
        WhseWkshName.Validate("Worksheet Template Name", NewWkshTmplName);
        WhseWkshName.Validate(Name, NewName);
        WhseWkshName.Validate(Description, NewDescription);
        WhseWkshName.Validate("Location Code", NewLocationCode);
        if not WhseWkshName.Insert(true) then
            WhseWkshName.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupMovementWkshName()
    var
        WkshName: Record "Whse. Worksheet Name";
        Location: Record Location;
    begin
        Location.Get('BLUE');
        if Location."Bin Mandatory" then
            MaintWkshName('MOVEMENT', 'DEFAULT', 'Default Journal', 'BLUE')
        else
            if WkshName.Get('MOVEMENT', 'DEFAULT', 'BLUE') then
                WkshName.Delete();
    end;

    local procedure CreateWMSItems()
    var
        Item: Record Item;
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        Clear(Item);
        Item."No." := 'A_TEST';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 1.5;
        Item."Gross Weight" := 1.6;
        Item."Unit Volume" := 2.0;
        Item.Description := 'FIFO_1.5_1.6_2';
        Item."Item Category Code" := 'MISC';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 13);
        InsertItemVariant('11');
        InsertItemVariant('12');
        InsertSKU('Red', '');
        InsertSKU('Blue', '');
        MaintItem(Item);
        MaintItemSize('A_TEST', 'PCS', 1, 2, 1);
        MaintItemSize('A_TEST', 'PALLET', 1, 26, 1);

        Clear(Item);
        Item."No." := 'B_TEST';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::LIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Net Weight" := 2.0;
        Item."Gross Weight" := 3.0;
        Item."Unit Volume" := 4.0;
        Item.Description := 'LIFO_2_3_4';
        Item."Item Category Code" := 'MISC';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 10);
        InsertItemVariant('21');
        InsertItemVariant('22');
        MaintItem(Item);
        MaintItemSize('B_TEST', 'PCS', 2, 2, 1);
        MaintItemSize('B_TEST', 'PALLET', 20, 2, 1);

        Clear(Item);
        Item."No." := 'C_TEST';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 5.0;
        Item."Gross Weight" := 5.1;
        Item."Unit Volume" := 7.5;
        Item.Description := 'Average_5_5.1_7.5';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 5);
        InsertItemVariant('31');
        InsertItemVariant('32');
        InsertSKU('GREEN', '31');
        InsertSKU('SILVER', '31');
        MaintItem(Item);
        MaintItemSize('C_TEST', 'PCS', 5, 0.75, 2);
        MaintItemSize('C_TEST', 'PALLET', 5, 3.75, 2);

        Clear(Item);
        Item."No." := 'S_TEST';
        Item."Base Unit of Measure" := 'PALLET';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 1.5;
        Item."Gross Weight" := 2.1;
        Item."Unit Volume" := 4.0;
        Item.Description := 'FIFO_1.5_1.1_4';
        InsertUnitOfMeasure('PALLET', 1);
        InsertUnitOfMeasure('PCS', 0.25);
        InsertItemVariant('41');
        InsertItemVariant('42');
        MaintItem(Item);
        MaintItemSize('S_TEST', 'PALLET', 5, 3, 2);
        MaintItemSize('S_TEST', 'PCS', 5, 0.75, 2);

        Clear(Item);
        Item."No." := 'F_TEST_BACKFLUSH';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Net Weight" := 5.5;
        Item."Gross Weight" := 5.99;
        Item."Unit Volume" := 3.9;
        Item.Description := 'Backward flushed w/o picking';
        Item."Flushing Method" := Item."Flushing Method"::Backward;
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 47);
        MaintItem(Item);
        MaintItemSize('F_TEST_BACKFLUSH', 'PCS', 0.9, 1, 0.8);
        MaintItemSize('F_TEST_BACKFLUSH', 'PALLET', 5.1, 5.2, 5.3);

        Clear(Item);
        Item."No." := 'F_TEST_BACKFLUSHPICK';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Net Weight" := 5.1;
        Item."Gross Weight" := 5.15;
        Item."Unit Volume" := 3.88;
        Item.Description := 'Backward flushed w picking';
        Item."Flushing Method" := Item."Flushing Method"::"Pick + Backward";
        InsertUnitOfMeasure('PCS', 1);
        InsertItemVariant('F1');
        MaintItem(Item);
        MaintItemSize('F_TEST_BACKFLUSHPICK', 'PCS', 0.89, 0.99, 0.79);

        Clear(Item);
        Item."No." := 'F_TEST_FORWFLUSHPICK';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 0.55;
        Item."Gross Weight" := 0.85;
        Item."Unit Volume" := 1.6;
        Item.Description := 'Forward flushed w picking';
        Item."Flushing Method" := Item."Flushing Method"::"Pick + Forward";
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('F_TEST_FORWFLUSHPICK', 'PCS', 3.4, 1, 2.3);

        Clear(Item);
        Item."No." := 'T_TEST';
        Item."Item Tracking Code" := 'SNALL';
        Item."Serial Nos." := 'SN1';
        Item."Lot Nos." := 'LOT';
        Item."Base Unit of Measure" := 'BOX';
        Item."Costing Method" := Item."Costing Method"::Specific;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 5.0;
        Item."Gross Weight" := 6.0;
        Item."Unit Volume" := 1.0;
        Item.Description := 'TRACKING_Specific_50_60_10';
        Item."Purch. Unit of Measure" := 'BOX';
        Item."Sales Unit of Measure" := 'BOX';
        InsertUnitOfMeasure('BOX', 1);
        InsertItemVariant('T1');
        InsertItemVariant('T2');
        InsertSKU('Blue', '');
        InsertSKU('WHITE', '');
        MaintItem(Item);
        MaintItemSize('T_TEST', 'BOX', 1, 1, 1);

        Clear(Item);
        Item."No." := 'L_TEST';
        Item."Item Tracking Code" := 'LOTALL';
        Item."Serial Nos." := 'SN1';
        Item."Lot Nos." := 'LOT';
        Item."Base Unit of Measure" := 'BOX';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'MISC';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 4.0;
        Item."Gross Weight" := 6.0;
        Item."Unit Volume" := 2.0;
        Item.Description := 'TRACKING_Specific_4_6_2';
        InsertUnitOfMeasure('BOX', 1);
        MaintItem(Item);
        MaintItemSize('L_TEST', 'BOX', 1, 1, 1);

        Clear(Item);
        Item."No." := 'N_TEST';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'MISC';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 2.0;
        Item."Gross Weight" := 2.0;
        Item."Unit Volume" := 2.0;
        Item.Description := 'Nonstock_Standard_20_25_15';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('N_TEST', 'PCS', 2, 1, 1);

        InsertProdBOMHdr('D_Prod', 'Product D', 'PCS');
        InsertProdBOMLine('D_Prod', 10000, ProdBOMLine.Type::Item, 'C_Test', '32', 0.5);
        ModifyProdBOMHdr('D_Prod', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'D_Prod';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'WIP item D_Prod';
        Item."Net Weight" := 2.5;
        Item."Gross Weight" := 2.55;
        Item."Unit Volume" := 3.75;
        Item."Production BOM No." := 'D_Prod';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 11);
        MaintItemSize('D_Prod', 'PCS', 2.5, 0.75, 2);
        MaintItemSize('D_Prod', 'PALLET', 2.5, 8.25, 2);
        MaintItem(Item);

        InsertProdBOMHdr('E_Prod', 'Product E', 'PCS');
        InsertProdBOMLine('E_Prod', 10000, ProdBOMLine.Type::Item, 'D_Prod', '', 1.5);
        InsertProdBOMLine('E_Prod', 20000, ProdBOMLine.Type::Item, 'A_TEST', '12', 1.3);
        InsertProdBOMLine('E_Prod', 30000, ProdBOMLine.Type::Item, 'B_TEST', '', 1.25);
        ModifyProdBOMHdr('E_Prod', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'E_Prod';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'FINISHED';
        Item.Description := 'WIP item E_Prod';
        Item."Net Weight" := 3.75;
        Item."Gross Weight" := 4.01;
        Item."Unit Volume" := 3.75;
        Item."Production BOM No." := 'E_Prod';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 9);
        MaintItemSize('D_Prod', 'PCS', 2.5, 0.75, 2);
        MaintItemSize('D_Prod', 'PALLET', 2.5, 8.25, 2);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '1120';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'Spokes';
        Item."Flushing Method" := Item."Flushing Method"::Forward;
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItemSize('1120', 'PCS', 0, 0, 0);
        MaintItem(Item);

        InsertProdBOMHdr('F_PROD', 'Product F', 'PCS');
        InsertProdBOMLine('F_PROD', 10000, ProdBOMLine.Type::Item, 'F_TEST_BACKFLUSH', '', 2.5);
        InsertProdBOMLine('F_PROD', 20000, ProdBOMLine.Type::Item, 'T_TEST', 'T2', 1.25);
        InsertProdBOMLine('F_PROD', 30000, ProdBOMLine.Type::Item, 'F_TEST_FORWFLUSHPICK', '', 2);
        InsertProdBOMLine('F_PROD', 40000, ProdBOMLine.Type::Item, 'F_TEST_BACKFLUSHPICK', 'F1', 5);
        InsertProdBOMLine('F_PROD', 50000, ProdBOMLine.Type::Item, '1120', '', 1);
        ModifyProdBOMHdr('F_PROD', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'F_PROD';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'FINISHED';
        Item.Description := 'Item F_PROD';
        Item."Net Weight" := 4.75;
        Item."Gross Weight" := 5.9;
        Item."Unit Volume" := 4.11;
        Item."Production BOM No." := 'F_PROD';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 7);
        MaintItemSize('F_PROD', 'PCS', 1.2, 1.4, 1.6);
        MaintItemSize('F_PROD', 'PALLET', 2.5, 8.1, 2.2);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '1000';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'FINISHED';
        Item.Description := 'Bicycle';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('1000', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '70000';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'Side Panel';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('70000', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '80001';
        Item."Item Tracking Code" := 'SNALL';
        Item."Serial Nos." := 'SN1';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'Computer III 533 MHz';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('80001', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '80002';
        Item."Item Tracking Code" := 'LOTALL';
        Item."Lot Nos." := 'LOT';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'Computer III 600 MHz';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 35);
        InsertSKU('Blue', '');
        InsertSKU('WHITE', '');
        MaintItem(Item);
        MaintItemSize('80002', 'PCS', 0, 0, 0);
        MaintItemSize('80002', 'PALLET', 0, 0, 0);

        Clear(Item);
        Item."No." := '80003';
        Item."Item Tracking Code" := 'SNALL';
        Item."Serial Nos." := 'SN1';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'Computer III 733 MHz';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('80003', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '80102-T';
        Item."Item Tracking Code" := 'SNALL';
        Item."Serial Nos." := 'SN1';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := '17" M780 Monitor';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('80102-T', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '80216-T';
        Item."Item Tracking Code" := 'LOTALL';
        Item."Lot Nos." := 'LOT';
        Item."Base Unit of Measure" := 'PCS';
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'Ethernet Cable';
        Item."Purch. Unit of Measure" := 'PCS';
        Item."Sales Unit of Measure" := 'PCS';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
        MaintItemSize('80216-T', 'PCS', 0, 0, 0);

        Clear(Item);
        Item."No." := '80100';
        Item."Base Unit of Measure" := 'BOX';
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'Printing Paper';
        InsertUnitOfMeasure('BOX', 1);
        InsertUnitOfMeasure('PACK', 0.2);
        InsertUnitOfMeasure('PALLET', 32);
        Item."Purch. Unit of Measure" := 'PALLET';
        Item."Sales Unit of Measure" := 'PACK';
        Item."Put-away Unit of Measure Code" := '';
        MaintItem(Item);
        MaintItemSize('80100', 'BOX', 0, 0, 0);
        MaintItemSize('80100', 'PACK', 0, 0, 0);
        MaintItemSize('80100', 'PALLET', 0, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure CreateCopiedWMSItem(OldItemNo: Code[20]; NewItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("No.");
        if (Item.Get(NewItemNo)) then
            Item.Delete(true);
        Item.Get(OldItemNo);
        Item.Rename(NewItemNo);
    end;

    local procedure InsertUnitOfMeasure(NewCode: Code[10]; NewQty: Decimal)
    begin
        iU := iU + 1;
        if iU > ArrayLen(UnitOfMeasure) then
            exit;
        UnitOfMeasure[iU] := NewCode;
        QtyPerUnitOfMeasure[iU] := NewQty;
    end;

    local procedure InsertItemVariant(NewCode: Code[10])
    begin
        iV := iV + 1;
        if iV > ArrayLen(VariantCode) then
            exit;
        VariantCode[iV] := NewCode;
    end;

    local procedure InsertSKU(NewLocationCode: Code[10]; NewVariantCode: Code[10])
    begin
        iS := iS + 1;
        if iS > ArrayLen(SKULocationCode) then
            exit;
        SKULocationCode[iS] := NewLocationCode;
        SKUVariantCode[iS] := NewVariantCode;
        SKUValid[iS] := true;
    end;

    [Scope('OnPrem')]
    procedure InsertProdBOMHdr(NewNo: Code[20]; NewDescription: Text[30]; NewUnitOfMeasureCode: Code[10])
    var
        ProdBOMHdr: Record "Production BOM Header";
    begin
        ProdBOMHdr.Init();
        ProdBOMHdr.Validate("No.", NewNo);
        ProdBOMHdr.Validate(Description, NewDescription);
        ProdBOMHdr.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        if not ProdBOMHdr.Insert() then
            ProdBOMHdr.Modify();
    end;

    [Scope('OnPrem')]
    procedure ModifyProdBOMHdr(NewNo: Code[20]; NewStatus: Enum "BOM Status")
    var
        ProdBOMHdr: Record "Production BOM Header";
    begin
        ProdBOMHdr.Get(NewNo);
        ProdBOMHdr.Validate(Status, NewStatus);
        ProdBOMHdr.Modify();
    end;

    [Scope('OnPrem')]
    procedure InsertProdBOMLine(NewProdBomNo: Code[20]; NewLineNo: Integer; NewType: Enum "Production BOM Line Type"; NewNo: Code[20]; NewVariant: Code[10]; NewQuantityPer: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.Init();
        ProdBOMLine.Validate("Production BOM No.", NewProdBomNo);
        ProdBOMLine.Validate("Line No.", NewLineNo);
        ProdBOMLine.Validate(Type, NewType);
        ProdBOMLine.Validate("No.", NewNo);
        ProdBOMLine.Validate("Variant Code", NewVariant);
        ProdBOMLine.Validate("Quantity per", NewQuantityPer);
        ProdBOMLine.Insert();
    end;

    local procedure MaintItem(NewItem: Record Item)
    var
        Item: Record Item;
    begin
        Clear(Item);
        Item.Validate("No.", NewItem."No.");
        if not Item.Insert(true) then;

        for iU := 1 to ArrayLen(UnitOfMeasure) do
            if UnitOfMeasure[iU] <> '' then
                MaintUnitOfMeasure(Item."No.", UnitOfMeasure[iU], QtyPerUnitOfMeasure[iU]);
        Clear(UnitOfMeasure);
        Clear(QtyPerUnitOfMeasure);
        iU := 0;

        Item.Validate("Item Tracking Code", NewItem."Item Tracking Code");
        Item.Validate("Serial Nos.", NewItem."Serial Nos.");
        Item.Validate("Lot Nos.", NewItem."Lot Nos.");
        Item.Validate("Base Unit of Measure", NewItem."Base Unit of Measure");
        Item.Validate("Gen. Prod. Posting Group", NewItem."Gen. Prod. Posting Group");
        Item.Validate("Inventory Posting Group", NewItem."Inventory Posting Group");
        Item.Validate("Net Weight", NewItem."Net Weight");
        Item.Validate("Gross Weight", NewItem."Gross Weight");
        Item.Validate("Unit Volume", NewItem."Unit Volume");
        Item.Validate(Description, NewItem.Description);
        Item.Validate("Routing No.", NewItem."Routing No.");
        Item.Validate("Flushing Method", NewItem."Flushing Method");
        Item.Validate("Production BOM No.", NewItem."Production BOM No.");
        Item.Validate("Item Category Code", NewItem."Item Category Code");
        Item.Validate("Costing Method", NewItem."Costing Method");
        Item.Validate("Purch. Unit of Measure", NewItem."Purch. Unit of Measure");
        Item.Validate("Sales Unit of Measure", NewItem."Sales Unit of Measure");
        Item.Validate("Put-away Unit of Measure Code", NewItem."Put-away Unit of Measure Code");
        Item.Modify(true);

        for iV := 1 to ArrayLen(VariantCode) do
            if VariantCode[iV] <> '' then
                MaintVariantCode(Item."No.", VariantCode[iV]);
        Clear(VariantCode);
        iV := 0;

        for iS := 1 to ArrayLen(SKULocationCode) do
            if SKUValid[iS] then
                MaintStockKeepUnit(Item."No.", SKULocationCode[iS], SKUVariantCode[iS], SKUStdCost[iS]);
        Clear(SKULocationCode);
        Clear(SKUVariantCode);
        Clear(SKUValid);
        iS := 0;
    end;

    local procedure MaintUnitOfMeasure(NewItemNo: Code[20]; NewCode: Code[10]; NewQty: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.Validate("Item No.", NewItemNo);
        ItemUnitOfMeasure.Validate(Code, NewCode);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", NewQty);
        if not ItemUnitOfMeasure.Insert(true) then
            ItemUnitOfMeasure.Modify(true);
    end;

    local procedure MaintVariantCode(NewItemNo: Code[20]; NewCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Validate("Item No.", NewItemNo);
        ItemVariant.Validate(Code, NewCode);
        if not ItemVariant.Insert(true) then
            ItemVariant.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintStockKeepUnit(NewItemNo: Code[20]; NewLocationCode: Code[10]; NewVariantCode: Code[10]; NewStdCost: Decimal)
    var
        StockKeepUnit: Record "Stockkeeping Unit";
    begin
        StockKeepUnit.Validate("Item No.", NewItemNo);
        StockKeepUnit.Validate("Location Code", NewLocationCode);
        StockKeepUnit.Validate("Variant Code", NewVariantCode);
        if NewStdCost <> 0 then
            StockKeepUnit.Validate("Standard Cost", NewStdCost);
        if not StockKeepUnit.Insert(true) then
            StockKeepUnit.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintItemSize(NewItemNo: Code[20]; NewCode: Code[10]; NewLength: Decimal; NewWidth: Decimal; NewHeigth: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetRange("Item No.", NewItemNo);
        ItemUnitOfMeasure.SetRange(Code, NewCode);
        if ItemUnitOfMeasure.FindFirst() then begin
            ItemUnitOfMeasure.Validate(Length, NewLength);
            ItemUnitOfMeasure.Validate(Width, NewWidth);
            ItemUnitOfMeasure.Validate(Height, NewHeigth);
            ItemUnitOfMeasure.CalcWeight();
            if not ItemUnitOfMeasure.Insert(true) then
                ItemUnitOfMeasure.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateWorkCenter()
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter."No." := '100';
        WorkCenter.Name := 'Assembly';
        WorkCenter."Work Center Group Code" := '1';
        WorkCenter."Direct Unit Cost" := 1.2;
        WorkCenter."Unit of Measure Code" := 'Minutes';
        WorkCenter."Shop Calendar Code" := '1';
        WorkCenter."Gen. Prod. Posting Group" := 'MANUFACT';
        MaintWorkCenter(WorkCenter);

        Clear(WorkCenter);
        WorkCenter."No." := '400';
        WorkCenter.Name := 'Machine department';
        WorkCenter."Work Center Group Code" := '2';
        WorkCenter."Direct Unit Cost" := 2.5;
        WorkCenter."Unit of Measure Code" := 'Minutes';
        WorkCenter."Shop Calendar Code" := '2';
        WorkCenter."Gen. Prod. Posting Group" := 'MANUFACT';
        MaintWorkCenter(WorkCenter);
    end;

    [Scope('OnPrem')]
    procedure MaintWorkCenter(NewWorkCenter: Record "Work Center")
    var
        WorkCenter: Record "Work Center";
    begin
        Clear(WorkCenter);
        WorkCenter.Validate("No.", NewWorkCenter."No.");
        if not WorkCenter.Insert(true) then;

        WorkCenter.Validate(Name, NewWorkCenter.Name);
        WorkCenter.Validate("Work Center Group Code", NewWorkCenter."Work Center Group Code");
        WorkCenter.Validate("Direct Unit Cost", NewWorkCenter."Direct Unit Cost");
        WorkCenter.Validate("Unit of Measure Code", NewWorkCenter."Unit of Measure Code");
        WorkCenter.Validate("Shop Calendar Code", NewWorkCenter."Shop Calendar Code");
        WorkCenter.Validate("Gen. Prod. Posting Group", NewWorkCenter."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintQASetup()
    var
        QASetup: Record "Whse. QA Setup";
    begin
        if not QASetup.Get() then begin
            Clear(QASetup);
            QASetup.Validate("Use Hardcoded Reference", true);
            QASetup.Validate("Test Results Path", TemporaryPath);
            QASetup.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure ResetNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Record "No. Series";
    begin
        NoSeriesLine.Reset();
        if NoSeriesLine.Find('-') then
            repeat
                NoSeriesLine.Validate("Last No. Used", '');
                NoSeriesLine.Validate("Last Date Used", 0D);
                NoSeriesLine.Modify();
                NoSeriesLine.SetRange("Series Code", NoSeriesLine."Series Code");
                NoSeriesLine.SetFilter("Line No.", '<>%1', NoSeriesLine."Line No.");
                NoSeriesLine.DeleteAll();
                NoSeriesLine.SetRange("Series Code");
                NoSeriesLine.SetRange("Line No.");
            until NoSeriesLine.Next() = 0;
        NoSeries.ModifyAll("Manual Nos.", true);
    end;

    [Scope('OnPrem')]
    procedure SetAutoDeleteOldData()
    begin
        AutoDeleteOldData := true;
    end;
}

