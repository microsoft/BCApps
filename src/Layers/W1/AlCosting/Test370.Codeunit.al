codeunit 103512 "Test 370"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // E1_STD (0.33)
    //   S1_AVG (3.23)
    //     S2_AVG (2.77)
    //       P2_FIFO (2.77)
    //     P3_FIFO (0.46)
    //   P1_FIFO (2.22)
    //   S2_AVG (2.77)
    //     P2_FIFO (2.77)
    // 
    // E1_AVG (1.32)
    //   S1_FIFO (0.66)
    //     S2_FIFO (0.33)
    //       P2_STD (0.33)
    //     P3_STD (0.33)
    //   P1_STD (0.33)
    //   S2_FIFO (0.33)
    //     P2_STD (0.33)
    // 
    // E1_FIFO (3.22)
    //   S1_STD (0.67)
    //     S2_STD (0.33)
    //       P2_AVG (2.77)
    //     P3_AVG (0.46)
    //   P1_AVG (2.22)
    //   S2_STD (0.33)
    //     P2_AVG (2.77)
    // 
    // Due to the way rounding is handled for average costing derivation of 0.01 for some values are acceptable.


    trigger OnRun()
    var
        Item: Record Item;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103512);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();

        StandardScenario(Item."Costing Method"::Standard, Item."Costing Method"::Average, Item."Costing Method"::FIFO);
        StandardScenario(Item."Costing Method"::Average, Item."Costing Method"::FIFO, Item."Costing Method"::Standard);
        StandardScenario(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, Item."Costing Method"::Average);
        ValidateResult();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        PPUtil: Codeunit PPUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        NoOfEItem: Decimal;
        EItemNo: array[10] of Code[20];
        SItemNo: array[10] of Code[20];
        PItemNo: array[10] of Code[20];
        ShowScriptResult: Boolean;

    local procedure SetPreconditions()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkDate := 20010101D;
        NoOfEItem := 0.33333;
        InvtSetup.ModifyAll("Automatic Cost Posting", false);
        GLUtil.SetRndgPrec(0.01, 0.00001);
        GLUtil.SetAddCurr('EUR', 10, 3, 0.01, 0.00001);
        PurchSetup.ModifyAll("Ext. Doc. No. Mandatory", false, true);
        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
    end;

    local procedure StandardScenario(ECostingMethod: Enum "Costing Method"; SCostingMethod: Enum "Costing Method"; PCostingMethod: Enum "Costing Method")
    begin
        MakeItemNo('E', ECostingMethod, EItemNo);
        MakeItemNo('S', SCostingMethod, SItemNo);
        MakeItemNo('P', PCostingMethod, PItemNo);

        CreateItemAndPBOMs(ECostingMethod, SCostingMethod, PCostingMethod);
        CreatePurchOrder();
        PostAllPurchaseOrders(true, false);
        CreatePACPostings();
        PostAllPurchaseOrders(false, true);
        CreatePurchOrder();
        PostAllPurchaseOrders(true, true);
        CreatePACPostings();

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
    end;

    local procedure CreateItemAndPBOMs(ECostingMethod: Enum "Costing Method"; SCostingMethod: Enum "Costing Method"; PCostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
    begin
        INVTUtil.CreateBasisItem(PItemNo[2], false, Item, PCostingMethod, 1);

        MFGUtil.InsertPBOMHeader(SItemNo[2], ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, PItemNo[2], '', 1, true);
        INVTUtil.CreateBasisItem(SItemNo[2], true, Item, SCostingMethod, 1);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        INVTUtil.CreateBasisItem(PItemNo[3], false, Item, PCostingMethod, 1);

        MFGUtil.InsertPBOMHeader(SItemNo[1], ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, SItemNo[2], '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, PItemNo[3], '', 1, false);
        INVTUtil.CreateBasisItem(SItemNo[1], true, Item, SCostingMethod, 1);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        INVTUtil.CreateBasisItem(PItemNo[1], false, Item, PCostingMethod, 1);

        MFGUtil.InsertPBOMHeader(EItemNo[1], ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, SItemNo[1], '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, PItemNo[1], '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, SItemNo[2], '', 1, false);
        INVTUtil.CreateBasisItem(EItemNo[1], true, Item, ECostingMethod, 1);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        INVTUtil.CalcStandardCost('');
    end;

    local procedure CreatePurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", PItemNo[1]);
        PurchLine.Validate(Quantity, 9 * NoOfEItem);
        PurchLine.Validate("Direct Unit Cost", 6.67259);
        PurchLine.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", PItemNo[2]);
        PurchLine.Validate(Quantity, 2 * 9 * NoOfEItem);
        PurchLine.Validate("Direct Unit Cost", 8.31451);
        PurchLine.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", PItemNo[3]);
        PurchLine.Validate(Quantity, 9 * NoOfEItem);
        PurchLine.Validate("Direct Unit Cost", 1.38066);
        PurchLine.Modify(true);
    end;

    local procedure CreatePACPostings()
    var
        NoOfProdOrder: Integer;
        NoOfLinePerProdOrder: Integer;
    begin
        for NoOfProdOrder := 1 to 2 do
            for NoOfLinePerProdOrder := 1 to 2 do begin
                CreatePACPosting(SItemNo[2], NoOfProdOrder, NoOfLinePerProdOrder);
                CreatePACPosting(SItemNo[2], NoOfProdOrder, NoOfLinePerProdOrder);
                CreatePACPosting(SItemNo[1], NoOfProdOrder, NoOfLinePerProdOrder);
                CreatePACPosting(EItemNo[1], NoOfProdOrder, NoOfLinePerProdOrder);
            end;
    end;

    local procedure ValidateResult()
    begin
        ValidateNetChange('2120', 105.92, 353.42);
        ValidateNetChange('7270', 0.38, 0.18);
        ValidateNetChange('7291', -444.3, -1480.98);
        ValidateNetChange('7293', 124.1, 413.66);
        ValidateNetChange('7890', 213.9, 713.72);
    end;

    local procedure ValidateNetChange(AccountNo: Code[20]; Amount: Decimal; AmountACY: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 %2', GLAccount."No.", GLAccount.Name),
          GLUtil.GetGLBalanceAtDate(AccountNo, WorkDate(), false), Amount);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 %2 (ACY)', GLAccount."No.", GLAccount.Name),
          GLUtil.GetGLBalanceAtDate(AccountNo, WorkDate(), true), AmountACY);
    end;

    local procedure CreatePACPosting(ItemNo: Code[20]; NoOfProdOrder: Integer; NoOfLinePerProdOrder: Integer)
    var
        ProdOrder: Record "Production Order";
        i: Integer;
    begin
        for i := 1 to NoOfProdOrder do begin
            ReleaseProdOrder(ProdOrder, ItemNo, NoOfEItem, NoOfLinePerProdOrder);
            MFGUtil.PostOutput(ProdOrder, ItemNo, NoOfEItem);
            MFGUtil.CalcAndPostConsump(WorkDate(), 0, '');
            FinishProdOrders(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReleaseProdOrder(var ProdOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; NoOfLinePerProdOrder: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        i: Integer;
    begin
        MFGUtil.CreateRelProdOrder(ProdOrder, '', ItemNo, Quantity);
        if NoOfLinePerProdOrder > 1 then begin
            ProdOrderLine.SetRange(Status, ProdOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderLine.DeleteAll(true);
            for i := 1 to NoOfLinePerProdOrder do
                CreateProdOrderLine(ProdOrder, ProdOrderLine, ItemNo, Quantity, i = 1);
            CalcRoutingsAndComponents(ProdOrder);
        end;
    end;

    local procedure CreateProdOrderLine(ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; Quantity: Decimal; IsFirstLine: Boolean)
    begin
        if IsFirstLine then
            Clear(ProdOrderLine);
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        GLUtil.IncrLineNo(ProdOrderLine."Line No.");
        ProdOrderLine.Insert(true);
        ProdOrderLine.Validate("Item No.", ItemNo);
        ProdOrderLine.Validate(Quantity, Quantity);
        ProdOrderLine.Modify(true);
    end;

    local procedure CalcRoutingsAndComponents(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalcProdOrder: Codeunit "Calculate Prod. Order";
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.Find('-') then
            repeat
                ProdOrderLine."Due Date" := ProdOrder."Due Date";
                ProdOrderLine."Ending Date" := ProdOrder."Due Date";
                CalcProdOrder.Calculate(ProdOrderLine, 1, true, true, false, true);
            until ProdOrderLine.Next() = 0;
    end;

    local procedure FinishProdOrders(SetAscending: Boolean)
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Ascending(SetAscending);
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        if ProdOrder.Find('-') then
            repeat
                MFGUtil.FinishProdOrder(ProdOrder."No.");
            until ProdOrder.Next() = 0;
    end;

    local procedure MakeItemNo(Prefix: Code[1]; CostingMethod: Enum "Costing Method"; var ItemNo: array[10] of Code[20])
    var
        Item: Record Item;
        Suffix: Code[4];
        i: Integer;
    begin
        case CostingMethod of
            Item."Costing Method"::FIFO:
                Suffix := 'FIFO';
            Item."Costing Method"::LIFO:
                Suffix := 'LIFO';
            Item."Costing Method"::Specific:
                Suffix := 'SPEC';
            Item."Costing Method"::Average:
                Suffix := 'AVG';
            Item."Costing Method"::Standard:
                Suffix := 'STD';
        end;
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := StrSubstNo('%1%2_%3', Prefix, i, Suffix);
    end;

    [Scope('OnPrem')]
    procedure PostAllPurchaseOrders(Rcv: Boolean; Inv: Boolean)
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        if PurchHeader.Find('-') then
            repeat
                PPUtil.PostPurchase(PurchHeader, Rcv, Inv)
            until PurchHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
}

