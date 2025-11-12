#pragma warning disable AA0215
codeunit 103002 "Set Global Preconditions"
#pragma warning restore AA0215
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        DeleteOldData();
        ResetNoSeries();
        MaintRevalJnlBatch();
    end;

    local procedure DeleteOldData()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        AverageCostAdjustment: Record "Avg. Cost Adjmt. Entry Point";
        BankAccountLedgEntry: Record "Bank Account Ledger Entry";
        CalendarEntry: Record "Calendar Entry";
        CampaignEntry: Record "Campaign Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DefDim: Record "Default Dimension";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        FALedgEntry: Record "FA Ledger Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLEntry: Record "G/L Entry";
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
        GLRegister: Record "G/L Register";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        Item: Record Item;
        ItemApplEntry: Record "Item Application Entry";
        ItemDiscGrp: Record "Item Discount Group";
        ItemJnlLine: Record "Item Journal Line";
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemRegister: Record "Item Register";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        JobJnlLine: Record "Job Journal Line";
        JobLedgEntry: Record "Job Ledger Entry";
        JobRegister: Record "Job Register";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobEntryNo: Record "Job Entry No.";
        MachCenter: Record "Machine Center";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        PriceListLine: Record "Price List Line";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdOrder: Record "Production Order";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Purchasing: Record Purchasing;
        PurchChargeAssignLine: Record "Item Charge Assignment (Purch)";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
        PurchPrice: Record "Purchase Price";
#endif
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReqLine: Record "Requisition Line";
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResEntry: Record "Reservation Entry";
        ResJnlLine: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        ResRegister: Record "Resource Register";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        ReturnShipHeader: Record "Return Shipment Header";
        ReturnShipLine: Record "Return Shipment Line";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        RtngLine: Record "Routing Line";
        SalesChargeAssignLine: Record "Item Charge Assignment (Sales)";
        SalesCommentLine: Record "Sales Comment Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
#endif
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        SKU: Record "Stockkeeping Unit";
        TransHdr: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransRcptHdr: Record "Transfer Receipt Header";
        TransRcptLine: Record "Transfer Receipt Line";
        TransShptHdr: Record "Transfer Shipment Header";
        TransShptLine: Record "Transfer Shipment Line";
        ValueEntry: Record "Value Entry";
        ValueEntryRelation: Record "Value Entry Relation";
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WorkCenter: Record "Work Center";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        PlanningAssignment: Record "Planning Assignment";
    begin
        AnalysisViewBudgetEntry.DeleteAll();
        AnalysisViewEntry.DeleteAll();
        AverageCostAdjustment.DeleteAll();
        BankAccountLedgEntry.DeleteAll();
        CalendarEntry.DeleteAll();
        CampaignEntry.DeleteAll();
        CapLedgEntry.DeleteAll();
        CustLedgEntry.DeleteAll();
        DefDim.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();
        FALedgEntry.DeleteAll();
        GLBudgetEntry.DeleteAll();
        GLEntry.DeleteAll();
        GLItemLedgerRelation.DeleteAll();
        GLRegister.DeleteAll();
        InsCoverageLedgEntry.DeleteAll();
        Item.DeleteAll();
        ItemApplEntry.DeleteAll();
        ItemDiscGrp.DeleteAll();
        ItemJnlLine.DeleteAll();
        ItemEntryRelation.DeleteAll();
        ItemLedgEntry.DeleteAll();
        ItemRegister.DeleteAll();
        ItemUnitOfMeasure.DeleteAll();
        ItemVariant.DeleteAll();
        JobJnlLine.DeleteAll();
        JobRegister.DeleteAll();
        JobLedgEntry.DeleteAll();
        JobRegister.DeleteAll();
        JobTask.DeleteAll();
        JobPlanningLine.DeleteAll();
        JobWIPEntry.DeleteAll();
        JobWIPGLEntry.DeleteAll();
        JobEntryNo.DeleteAll();
        MachCenter.DeleteAll();
        MaintenanceLedgEntry.DeleteAll();
        PhysInvtLedgEntry.DeleteAll();
        PriceListLine.DeleteAll();
        ProdBOMLine.DeleteAll();
        ProdBOMHeader.DeleteAll();
        ProdBOMVersion.DeleteAll();
        ProdForecastEntry.DeleteAll();
        ProdOrder.DeleteAll();
        ProdOrderCapNeed.DeleteAll();
        ProdOrderComp.DeleteAll();
        ProdOrderLine.DeleteAll();
        ProdOrderRoutingLine.DeleteAll();
        Purchasing.DeleteAll();
        PurchChargeAssignLine.DeleteAll();
        PurchCommentLine.DeleteAll();
        PurchCrMemoHdr.DeleteAll();
        PurchCrMemoLine.DeleteAll();
        PurchHeader.DeleteAll();
        PurchInvHeader.DeleteAll();
        PurchInvLine.DeleteAll();
        PurchLine.DeleteAll();
#if not CLEAN25
        PurchLineDisc.DeleteAll();
        PurchPrice.DeleteAll();
#endif
        PurchRcptHeader.DeleteAll();
        PurchRcptLine.DeleteAll();
        ReqLine.DeleteAll();
        ResCapacityEntry.DeleteAll();
        ResEntry.DeleteAll();
        ResJnlLine.DeleteAll();
        ResLedgEntry.DeleteAll();
        ResRegister.DeleteAll();
        ReturnRcptHeader.DeleteAll();
        ReturnRcptLine.DeleteAll();
        ReturnShipHeader.DeleteAll();
        ReturnShipLine.DeleteAll();
        RtngHeader.DeleteAll();
        RtngVersion.DeleteAll();
        RtngLine.DeleteAll();
        SalesChargeAssignLine.DeleteAll();
        SalesCommentLine.DeleteAll();
        SalesCrMemoHeader.DeleteAll();
        SalesCrMemoLine.DeleteAll();
        SalesHeader.DeleteAll();
        SalesInvHeader.DeleteAll();
        SalesInvLine.DeleteAll();
        SalesLine.DeleteAll();
#if not CLEAN25
        SalesLineDisc.DeleteAll();
        SalesPrice.DeleteAll();
#endif
        SalesShptHeader.DeleteAll();
        SalesShptLine.DeleteAll();
        SKU.DeleteAll();
        TransHdr.DeleteAll();
        TransLine.DeleteAll();
        TransRcptHdr.DeleteAll();
        TransRcptLine.DeleteAll();
        TransShptHdr.DeleteAll();
        TransShptLine.DeleteAll();
        ValueEntry.DeleteAll();
        ValueEntryRelation.DeleteAll();
        VATEntry.DeleteAll();
        VendLedgEntry.DeleteAll();
        WhseActivityHdr.DeleteAll();
        WorkCenter.DeleteAll();
        PostValueEntryToGL.DeleteAll();
        GLEntryVATEntryLink.DeleteAll();
        PlanningAssignment.DeleteAll();
        DeleteNumberSequence(Database::"Item Register");
        DeleteNumberSequence(Database::"Item Ledger Entry");
        DeleteNumberSequence(Database::"Item Application Entry");
        DeleteNumberSequence(Database::"Value Entry");
    end;

    local procedure DeleteNumberSequence(TableNo: integer)
    var
        Name: Text;
    begin
#pragma warning disable AA0217
        Name := StrSubstNo('TableSeq%1', TableNo);
        if NumberSequence.Exists(Name) then
            NumberSequence.Delete(Name);
        Name := StrSubstNo('PreviewTableSeq%1', TableNo);
        if NumberSequence.Exists(Name) then
            NumberSequence.Delete(Name);
#pragma warning restore AA0217
    end;

    [Scope('OnPrem')]
    procedure ResetNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
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
    end;

    local procedure MaintRevalJnlBatch()
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch.Validate("Journal Template Name", 'REVAL');
        ItemJnlBatch.Validate(Name, 'DEFAULT');
        ItemJnlBatch.Validate("No. Series", 'IJNL-REVAL');
        if not ItemJnlBatch.Insert(true) then
            ItemJnlBatch.Modify(true);
    end;
}

