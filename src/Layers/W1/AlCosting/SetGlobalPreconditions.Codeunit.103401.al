#pragma warning disable AA0215
codeunit 103401 "_Set Global Preconditions"
#pragma warning restore AA0215
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
        MaintGLAccount();
        MaintInvPostingSetup();
        MaintDimValueCombination();
        MaintDimCombination();
        SetupGeneralLedgerSetup();
        SetupCurrency();
        SetupCurrExchRate();
        SetAddRepCurr();
        SetupCostCodes();
        MaintInvtSetup();
        MaintSaleReceiveSetup();
        MaintPurchPayableSetup();
        SetupItemJnlBatch();
        MaintLocation();
        CreateCETAFItems();
        MaintQASetup();
        MaintCustInvDisc();
        ResetNoSeries();
        WorkDate(20010125D);
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
        SKUNewUnitCostCost: array[10] of Decimal;
        SKUValid: array[10] of Boolean;

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
        ItemAnalysisView: Record "Item Analysis View";
        ItemApplEntry: Record "Item Application Entry";
        ItemJnlLine: Record "Item Journal Line";
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemRegister: Record "Item Register";
        OrderAdjmtEntry: Record "Inventory Adjmt. Entry (Order)";
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
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchChargeAssignLine: Record "Item Charge Assignment (Purch)";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResEntry: Record "Reservation Entry";
        ResJnlLine: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        ResRegister: Record "Resource Register";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        ReturnShipHeader: Record "Return Shipment Header";
        ReturnShipLine: Record "Return Shipment Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SalesChargeAssignLine: Record "Item Charge Assignment (Sales)";
        SalesCommentLine: Record "Sales Comment Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransHdr: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransRcptHdr: Record "Transfer Receipt Header";
        TransRcptLine: Record "Transfer Receipt Line";
        TransShptHdr: Record "Transfer Shipment Header";
        TransShptLine: Record "Transfer Shipment Line";
        TrackSpec: Record "Tracking Specification";
        ValueEntry: Record "Value Entry";
        ValueEntryRelation: Record "Value Entry Relation";
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InventoryPeriod: Record "Inventory Period";
        InventoryPeriodEntry: Record "Inventory Period Entry";
#if not CLEAN25
        SalesLineDiscount: Record "Sales Line Discount";
#endif
        PriceListLine: Record "Price List Line";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GlEntryVatEntrylink: Record "G/L Entry - VAT Entry Link";
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
        ItemAnalysisView.DeleteAll();
        ItemApplEntry.DeleteAll();
        ItemJnlLine.DeleteAll();
        ItemEntryRelation.DeleteAll();
        ItemLedgEntry.DeleteAll();
        ItemRegister.DeleteAll();
        ItemUnitOfMeasure.DeleteAll();
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
        ProdBOMLine.DeleteAll();
        ProdBOMHeader.DeleteAll();
        ProdForecastEntry.DeleteAll();
        ProdOrder.DeleteAll();
        ProdOrderComp.DeleteAll();
        ProdOrderLine.DeleteAll();
        ProdOrderRoutingLine.DeleteAll();
        PurchChargeAssignLine.DeleteAll();
        PurchCommentLine.DeleteAll();
        PurchCrMemoHdr.DeleteAll();
        PurchCrMemoLine.DeleteAll();
        PurchHeader.DeleteAll();
        PurchInvHeader.DeleteAll();
        PurchInvLine.DeleteAll();
        PurchLine.DeleteAll();
        PurchRcptHeader.DeleteAll();
        PurchRcptLine.DeleteAll();
        ResCapacityEntry.DeleteAll();
        ResEntry.DeleteAll();
        ResJnlLine.DeleteAll();
        ResLedgEntry.DeleteAll();
        ResRegister.DeleteAll();
        ReturnRcptHeader.DeleteAll();
        ReturnRcptLine.DeleteAll();
        ReturnShipHeader.DeleteAll();
        ReturnShipLine.DeleteAll();
        RoutingHeader.DeleteAll();
        RoutingLine.DeleteAll();
        SalesChargeAssignLine.DeleteAll();
        SalesCommentLine.DeleteAll();
        SalesCrMemoHeader.DeleteAll();
        SalesCrMemoLine.DeleteAll();
        SalesHeader.DeleteAll();
        SalesInvHeader.DeleteAll();
        SalesInvLine.DeleteAll();
        SalesLine.DeleteAll();
        SalesShptHeader.DeleteAll();
        SalesShptLine.DeleteAll();
        StockkeepingUnit.DeleteAll();
        TrackSpec.DeleteAll();
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
        WhseActivityLine.DeleteAll();
        InventoryPeriodEntry.DeleteAll();
        InventoryPeriod.DeleteAll();
#if not CLEAN25
        SalesLineDiscount.DeleteAll();
#endif
        PriceListLine.DeleteAll();
        PostValueEntryToGL.DeleteAll();
        GLItemLedgRelation.DeleteAll();
        GlEntryVatEntrylink.DeleteAll();
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

    [Scope('OnPrem')]
    procedure SetupGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetupCurrency()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        MaintCurrency('DEM', '9330', '9340', '9310', '9320', 0.00001);

        Cust.Get('49858585');
        Cust.Validate("Currency Code", 'DEM');
        Cust.Modify(true);

        Vend.Get('49989898');
        Vend.Validate("Currency Code", 'DEM');
        Vend.Modify(true);
    end;

    local procedure MaintCurrency(CurrencyCode: Code[10]; RealGLGainsAcc: Code[20]; RealGLLossesAcc: Code[20]; ResidGainsAcc: Code[20]; ResidLossesAcc: Code[20]; UnitAmountRndPrecision: Decimal)
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then begin
            Currency.Validate(Code, CurrencyCode);
            Currency.Insert(true);
        end;
        Currency.Validate("Realized G/L Gains Account", RealGLGainsAcc);
        Currency.Validate("Realized G/L Losses Account", RealGLLossesAcc);
        Currency.Validate("Residual Gains Account", ResidGainsAcc);
        Currency.Validate("Residual Losses Account", ResidLossesAcc);
        Currency.Validate("Unit-Amount Rounding Precision", UnitAmountRndPrecision);
        Currency.Modify(true);
    end;

    local procedure SetupCurrExchRate()
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        MaintCurrExchRate(
          19990101D, 'DEM', 'EUR', 1.95583, 1, 1.95583, 1, CurrExchRate."Fix Exchange Rate Amount"::Both);
        MaintCurrExchRate(
          19990101D, 'EUR', '', 1, 0.6458, 1, 0.6458, CurrExchRate."Fix Exchange Rate Amount"::Currency);
        MaintCurrExchRate(
          19990101D, 'USD', '', 100, 70.4783, 100, 70.4783, CurrExchRate."Fix Exchange Rate Amount"::Currency);
    end;

    local procedure MaintCurrExchRate(StartingDate: Date; CurrencyCode: Code[10]; RelCurrCode: Code[10]; ExchRateAmt: Decimal; RelExchRateAmt: Decimal; AdjExchRateAmt: Decimal; RelAdjExchRateAmt: Decimal; FixExchRateAmt: Enum "Fix Exch. Rate Amount Type")
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Validate("Starting Date", StartingDate);
        CurrExchRate.Validate("Currency Code", CurrencyCode);
        if not CurrExchRate.Insert(true) then;

        CurrExchRate.Validate("Relational Currency Code", RelCurrCode);
        CurrExchRate.Validate("Exchange Rate Amount", ExchRateAmt);
        CurrExchRate.Validate("Relational Exch. Rate Amount", RelExchRateAmt);
        CurrExchRate.Validate("Adjustment Exch. Rate Amount", AdjExchRateAmt);
        CurrExchRate.Validate("Relational Adjmt Exch Rate Amt", RelAdjExchRateAmt);
        CurrExchRate.Validate("Fix Exchange Rate Amount", FixExchRateAmt);
        CurrExchRate.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetAddRepCurr()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Additional Reporting Currency" := 'DEM';
        GLSetup."Unit-Amount Rounding Precision" := 0.00001;
        GLSetup.Modify();
    end;

    local procedure SetupCostCodes()
    begin
        MaintCostCode('GPS', 'German Parcel Service', 'RAW MAT', 'VAT25');
        MaintCostCode('INSURANCE', 'Lloyds', 'RETAIL', 'VAT10');
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
        InvtSetup."Average Cost Period" := InvtSetup."Average Cost Period"::Day;
        InvtSetup.Validate("Location Mandatory", false);
        InvtSetup."Automatic Cost Adjustment" := InvtSetup."Automatic Cost Adjustment"::Never;
        InvtSetup.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InvtSetup);
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
        SaleReceiveSetup.Validate("Shipment on Invoice", true);
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

    local procedure SetupItemJnlBatch()
    begin
        MaintItemJnlBatch('REVAL', 'DEFAULT', 'Default Journal');
        MaintItemJnlBatch('RECLASS', 'DEFAULT', 'Default Journal');
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

    local procedure MaintLocation()
    var
        Location: Record Location;
    begin
        Location.Get('BLUE');
        Location."Bin Mandatory" := false;
        Location.Modify(true);

        if Location.Get('BLUES') then
            Location.Delete();
    end;

    local procedure CreateCETAFItems()
    var
        Item: Record Item;
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        Clear(Item);
        Item."No." := '1_FI_RE';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 12.33333;
        Item."Last Direct Cost" := 13.77777;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 11.11;
        Item."Gross Weight" := 12.12;
        Item."Unit Volume" := 13.13;
        Item.Description := 'FIFO_RETAIL_RESALE_UM13';
        InsertItemVariant('11');
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 13);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '2_LI_RA';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 22.33333;
        Item."Last Direct Cost" := 23.77777;
        Item."Costing Method" := Item."Costing Method"::LIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Net Weight" := 21.21;
        Item."Gross Weight" := 22.22;
        Item."Unit Volume" := 23.23;
        Item.Description := 'LIFO_RAWMAT_RAWMAT_UM3';
        InsertItemVariant('21');
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 3);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '3_SP_RE';
        Item."Item Tracking Code" := 'SNALL';
        Item."Serial Nos." := 'SN1';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 32.34567;
        Item."Last Direct Cost" := 33.45678;
        Item."Costing Method" := Item."Costing Method"::Specific;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 31.31;
        Item."Gross Weight" := 32.32;
        Item."Unit Volume" := 33.33;
        Item.Description := 'SPECI_RETAIL_RESALE_UM17';
        InsertItemVariant('31');
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 17);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '4_AV_RE';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 42.44444;
        Item."Last Direct Cost" := 43.55555;
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Net Weight" := 41.41;
        Item."Gross Weight" := 42.42;
        Item."Unit Volume" := 43.43;
        Item.Description := 'AVERAGE_RETAIL_RESALE_UM5';
        InsertItemVariant('41');
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 5);
        InsertSKU('BLUE', '', 0, 42.44444);
        InsertSKU('RED', '', 0, 42.44444);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '5_ST_RA';
        Item."Base Unit of Measure" := 'PCS';
        Item."Standard Cost" := 52.34567;
        Item."Last Direct Cost" := 53.45678;
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Net Weight" := 51.51;
        Item."Gross Weight" := 52.52;
        Item."Unit Volume" := 53.53;
        Item.Description := 'STD_RAWMAT_RAWMAT_UM11';
        InsertItemVariant('51');
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 11);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '6_AV_OV';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 62.44444;
        Item."Last Direct Cost" := 63.55555;
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item."Overhead Rate" := 3.33;
        Item."Indirect Cost %" := 11.33;
        Item."Net Weight" := 61.61;
        Item."Gross Weight" := 62.62;
        Item."Unit Volume" := 63.63;
        Item.Description := 'AVERAGE_RET_RES_OV_UM5';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 5);
        InsertItemVariant('61');
        InsertItemVariant('62');
        InsertSKU('BLUE', '', 0, 62.44444);
        InsertSKU('BLUE', '61', 0, 62.44444);
        InsertSKU('RED', '', 0, 62.44444);
        InsertSKU('RED', '61', 0, 62.44444);
        MaintItem(Item);

        Clear(Item);
        Item."No." := '7_ST_OV';
        Item."Base Unit of Measure" := 'PCS';
        Item."Standard Cost" := 72.34567;
        Item."Last Direct Cost" := 73.45678;
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item."Overhead Rate" := 2.22;
        Item."Indirect Cost %" := 12.22;
        Item."Net Weight" := 71.71;
        Item."Gross Weight" := 72.72;
        Item."Unit Volume" := 73.73;
        Item.Description := 'STD_RAW_RAW_OV_UM11';
        InsertUnitOfMeasure('PCS', 1);
        InsertUnitOfMeasure('PALLET', 11);
        InsertItemVariant('71');
        InsertItemVariant('72');
        InsertSKU('BLUE', '', 75.55, 0);
        InsertSKU('BLUE', '71', 76.66, 0);
        InsertSKU('RED', '', 77.77, 0);
        InsertSKU('RED', '71', 78.77, 0);
        MaintItem(Item);

        Clear(Item);
        Item."No." := 'C';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 10;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Description := 'WIP basic item';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);

        InsertProdBOMHdr('B', '0,5 C', 'PCS');
        InsertProdBOMLine('B', 10000, ProdBOMLine.Type::Item, 'C', 0.5);
        ModifyProdBOMHdr('B', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'B';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 15;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'WIP item B';
        Item."Production BOM No." := 'B';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);

        InsertProdBOMHdr('A', '1,25 B + 2,3 C', 'PCS');
        InsertProdBOMLine('A', 10000, ProdBOMLine.Type::Item, 'B', 1.25);
        InsertProdBOMLine('A', 20000, ProdBOMLine.Type::Item, 'C', 2.3);
        ModifyProdBOMHdr('A', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'A';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 35;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'WIP item A';
        Item."Production BOM No." := 'A';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);

        InsertProdBOMHdr('D', '1,25 B + 3 4_AV_RE', 'PCS');
        InsertProdBOMLine('D', 10000, ProdBOMLine.Type::Item, 'B', 1.25);
        InsertProdBOMLine('D', 20000, ProdBOMLine.Type::Item, '4_AV_RE', 3);
        ModifyProdBOMHdr('D', ProdBOMHdr.Status::Certified);

        Clear(Item);
        Item."No." := 'D';
        Item."Base Unit of Measure" := 'PCS';
        Item."Unit Cost" := 10;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item."Gen. Prod. Posting Group" := 'RAW MAT';
        Item."Inventory Posting Group" := 'RAW MAT';
        Item.Description := 'WIP item D';
        Item."Production BOM No." := 'D';
        InsertUnitOfMeasure('PCS', 1);
        MaintItem(Item);
    end;

    [Scope('OnPrem')]
    procedure RenameItem(OldItemNo: Code[20]; NewItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("No.");
        if Item.Get(NewItemNo) then
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

    local procedure InsertSKU(NewLocationCode: Code[10]; NewVariantCode: Code[10]; NewStdCost: Decimal; NewUnitCost: Decimal)
    begin
        iS := iS + 1;
        if iS > ArrayLen(SKULocationCode) then
            exit;
        SKULocationCode[iS] := NewLocationCode;
        SKUVariantCode[iS] := NewVariantCode;
        SKUStdCost[iS] := NewStdCost;
        SKUNewUnitCostCost[iS] := NewUnitCost;
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
        ProdBOMHdr.Insert();
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
    procedure InsertProdBOMLine(NewProdBomNo: Code[20]; NewLineNo: Integer; NewType: Enum "Production BOM Line Type"; NewNo: Code[20]; NewQuantityPer: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.Init();
        ProdBOMLine.Validate("Production BOM No.", NewProdBomNo);
        ProdBOMLine.Validate("Line No.", NewLineNo);
        ProdBOMLine.Validate(Type, NewType);
        ProdBOMLine.Validate("No.", NewNo);
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
        Item.Validate("Base Unit of Measure", NewItem."Base Unit of Measure");
        Item.Validate("Standard Cost", NewItem."Standard Cost");
        Item.Validate("Unit Cost", NewItem."Unit Cost");
        Item.Validate("Last Direct Cost", NewItem."Last Direct Cost");
        Item.Validate("Costing Method", NewItem."Costing Method");
        Item.Validate("Gen. Prod. Posting Group", NewItem."Gen. Prod. Posting Group");
        Item.Validate("Inventory Posting Group", NewItem."Inventory Posting Group");
        Item.Validate("Overhead Rate", NewItem."Overhead Rate");
        Item.Validate("Indirect Cost %", NewItem."Indirect Cost %");
        Item.Validate("Net Weight", NewItem."Net Weight");
        Item.Validate("Gross Weight", NewItem."Gross Weight");
        Item.Validate("Unit Volume", NewItem."Unit Volume");
        Item.Validate(Description, NewItem.Description);
        if NewItem."Production BOM No." <> '' then
            Item.Validate("Production BOM No.", NewItem."Production BOM No.");
        Item.Modify(true);

        for iV := 1 to ArrayLen(VariantCode) do
            if VariantCode[iV] <> '' then
                MaintVariantCode(Item."No.", VariantCode[iV]);
        Clear(VariantCode);
        iV := 0;

        for iS := 1 to ArrayLen(SKULocationCode) do
            if SKUValid[iS] then
                MaintStockKeepUnit(Item."No.", SKULocationCode[iS], SKUVariantCode[iS], SKUStdCost[iS], SKUNewUnitCostCost[iS]);
        Clear(SKULocationCode);
        Clear(SKUVariantCode);
        Clear(SKUStdCost);
        Clear(SKUNewUnitCostCost);
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

    local procedure MaintStockKeepUnit(NewItemNo: Code[20]; NewLocationCode: Code[10]; NewVariantCode: Code[10]; NewStdCost: Decimal; NewUnitcost: Decimal)
    var
        StockKeepUnit: Record "Stockkeeping Unit";
    begin
        StockKeepUnit.Validate("Item No.", NewItemNo);
        StockKeepUnit.Validate("Location Code", NewLocationCode);
        StockKeepUnit.Validate("Variant Code", NewVariantCode);
        if not StockKeepUnit.Insert(true) then
            StockKeepUnit.Modify(true);
        if NewStdCost <> 0 then
            StockKeepUnit.Validate("Standard Cost", NewStdCost);
        if NewUnitcost <> 0 then
            StockKeepUnit.Validate("Unit Cost", NewUnitcost);
        StockKeepUnit.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintQASetup()
    var
        QASetup: Record "QA Setup";
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

    local procedure MaintInvPostingSetup()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        if InvPostingSetup.Get('BLUES', 'RAW MAT') then
            InvPostingSetup.Rename('BLUE', 'RAW MAT');

        if InvPostingSetup.Get('BLUE', 'RESALE') then begin
            InvPostingSetup.Validate("Inventory Account", '2110');
            InvPostingSetup.Modify(true);
        end;
    end;

    local procedure MaintGLAccount()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get('2110');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
        GLAccount.Get('2111');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
        GLAccount.Get('2130');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
        GLAccount.Get('7191');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
        GLAccount.Get('7291');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
        GLAccount.Get('5410');
        GLAccount.Validate(Blocked, false);
        GLAccount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure MaintDimValueCombination()
    var
        DimValueCombination: Record "Dimension Value Combination";
    begin
        if DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then
            DimValueCombination.Delete();
    end;

    [Scope('OnPrem')]
    procedure MaintDimCombination()
    var
        DimCombination: Record "Dimension Combination";
    begin
        if DimCombination.Get('AREA', 'DEPARTMENT') then
            DimCombination.Delete();

        if DimCombination.Get('AREA', 'PROJECT') then
            DimCombination.Delete();
    end;

    local procedure MaintCustInvDisc()
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
        Customer: Record Customer;
    begin
        if not CustInvDisc.Get('10000', '', 0) then begin
            CustInvDisc.Init();
            CustInvDisc.Code := '10000';
            CustInvDisc."Currency Code" := '';
            CustInvDisc."Minimum Amount" := 0;
            CustInvDisc.Insert();
        end;
        CustInvDisc."Discount %" := 5;
        if not CustInvDisc.Insert() then
            CustInvDisc.Modify();
        Customer.Get('10000');
        Customer."Allow Line Disc." := true;
        Customer.Modify();
    end;
}

