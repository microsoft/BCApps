codeunit 103528 "Test - Purchase Pricing"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103528);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        Test1();
        Test2();
        Test3();
        Test4();
        Test6();
        Test8();
        Test9();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;
        CurrTest: Text[30];
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
#if not CLEAN25        
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif
        ReqLine: Record "Requisition Line";
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Vend: Record Customer;
        Item: Record Item;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        PurchaseSetup.Get();
        PurchaseSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchaseSetup.Modify(true);

        GLUtil.SetAddCurr('USD', 100, 64.8824, 0.01, 0.001);

        InsertItem('A', 'PCS', Item."Costing Method"::FIFO, 22.22, 22.22, 'PCS', 1, 'M-T-S');
        InsertItem('B', 'PCS', Item."Costing Method"::Standard, 333.33, 333.33, 'PCS', 1, '');
        InsertItem('C', 'PCS', Item."Costing Method"::FIFO, 4444.44, 4444.44, 'BOX', 3, '');
        INVTUtil.InsertItemVariant('C', 'VAR');
        InsertItem('D', 'PCS', Item."Costing Method"::FIFO, 4444.44, 4444.44, 'BOX', 3, '');
        INVTUtil.InsertItemVariant('D', 'VAR');

        InsertSKU('A', 'BLUE', '', 25);
        InsertSKU('D', '', 'VAR', 4450);
        InsertSKU('D', 'BLUE', 'VAR', 4500);

        Vend.Get('20000');
        Vend.Validate("Location Code", '');
        Vend.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure Test1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'P.1';

        PPUtil.InsertPurchPrice('10000', 'A', 0D, 0D, 0, '', '', '', 22);
        PPUtil.InsertPurchPrice('10000', 'A', 20020301D, 20020501D, 0, '', '', '', 20);
        PPUtil.InsertPurchPrice('10000', 'A', 20020401D, 20020401D, 0, '', '', '', 18);
        PPUtil.InsertPurchPrice('10000', 'A', 20020601D, 0D, 0, '', '', '', 14);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 22);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', 'BLUE', '', 22);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 20);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 18);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020601D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 14);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 22.22);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', 'BLUE', '', 25);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'P.2';

        PPUtil.InsertPurchPrice('20000', 'A', 0D, 0D, 5, '', '', '', 10);
        PPUtil.InsertPurchPrice('20000', 'A', 0D, 0D, 10, '', '', '', 8);
        PPUtil.InsertPurchPrice('20000', 'A', 20010101D, 20010101D, 5, '', '', '', 11);
        PPUtil.InsertPurchPrice('20000', 'A', 20020401D, 20020401D, 0, '', '', '', 6);
        PPUtil.InsertPurchPrice('20000', 'A', 20020401D, 20020401D, 5, '', '', '', 4);
        PPUtil.InsertPurchPrice('20000', 'A', 20020401D, 20020401D, 10, '', '', '', 2);
        PPUtil.InsertPurchPrice('20000', 'B', 0D, 0D, 0, 'USD', '', '', 500);
        PPUtil.InsertPurchPrice('20000', 'B', 0D, 0D, 100, 'USD', '', '', 430);
        PPUtil.InsertPurchPrice('20000', 'B', 20020401D, 20020401D, 0, 'USD', '', '', 465);
        PPUtil.InsertPurchPrice('20000', 'B', 20020401D, 20020401D, 5, 'USD', '', '', 455);
        PPUtil.InsertPurchPrice('20000', 'B', 20020401D, 20020401D, 10, 'USD', '', '', 430);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 0, '', 'BOX', '', 13200);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 0, 'USD', 'BOX', '', 20000);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 12900);
        PPUtil.InsertPurchPrice('20000', 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 13050);
        PPUtil.InsertPurchPrice('20000', 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 19500);
        PPUtil.InsertPurchPrice('20000', 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 19200);
        PPUtil.InsertPurchPrice('20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 18900);
        PPUtil.InsertPurchPrice('20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 17000);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', 22.22);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', 25);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', 8);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', '', 4444.44);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', '', 4444.44);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 'VAR', 4450);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', 'VAR', 4500);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', '', '', 13200);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', 'BLUE', 'VAR', 13200);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', 12900);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', 6);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', 6);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', 4);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', 4);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', 2);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', '', 4444.44);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', '', 4444.44);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 'VAR', 4450);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', 'VAR', 4500);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', '', '', 13050);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', 'BLUE', 'VAR', 13050);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', '', 13050);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', 12900);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020101D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', 22.22);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', 8);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', 'USD', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', 34.247);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', 38.531);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', 15.413);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', 15.413);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', 12.33);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', '', 6849.993);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', '', 6849.993);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 'VAR', 6858.563);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', 'VAR', 6935.625);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', '', '', 20000);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', 'BLUE', 'VAR', 20000);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', '', 20000);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', 20000);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', 'USD', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', 9.248);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', 9.248);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', 6.165);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', 6.165);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', 3.083);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 2, '', '', '', 465);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 100, '', '', '', 430);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', '', 6849.993);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', '', 6849.993);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 'VAR', 6858.563);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', 'BLUE', 'VAR', 6935.625);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', '', '', 19500);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', 'BLUE', 'VAR', 19500);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', '', 18900);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', 'VAR', 17000);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        item: Record Item;
        SKU: Record "Stockkeeping Unit";
#if not CLEAN25
        PurchPrice: Record "Purchase Price";
        FromPurchPrice: Record "Purchase Price";
#else
        PriceListLine: Record "Price List Line";
        FromPriceListLine: Record "Price List Line";
#endif
        PurchHeader: array[5] of Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        FromPurchInvNo: Code[20];
        FromPurchCrMemoNo: Code[20];
        i: Integer;
        DirectUnitCost: array[29] of Decimal;
    begin
        CurrTest := 'P.3';

        item.Get('A');
        item.Validate("Last Direct Cost", 10.1);
        item.Modify(true);

        item.Get('B');
        item.Validate("Last Direct Cost", 30.3);
        item.Validate("Standard Cost", 33);
        item.Validate("Costing Method", item."Costing Method"::Standard);
        item.Modify(true);

        item.Get('D');
        item.Validate("Last Direct Cost", 40.4);
        item.Modify(true);

        SKU.Get('BLUE', 'A', '');
        SKU.Validate("Last Direct Cost", 11.11);
        SKU.Modify(true);

        InsertSKU('B', 'BLUE', '', 30.3);
        SKU.Get('BLUE', 'B', '');
        SKU.Validate("Standard Cost", 33);
        SKU.Modify(true);
#if not CLEAN25
        FromPurchPrice.SetRange("Vendor No.", '20000');
        FromPurchPrice.Find('-');
        repeat
            PPUtil.InsertPurchPrice(
              '30000', FromPurchPrice."Item No.", FromPurchPrice."Starting Date", FromPurchPrice."Ending Date",
              FromPurchPrice."Minimum Quantity", FromPurchPrice."Currency Code", FromPurchPrice."Unit of Measure Code", FromPurchPrice."Variant Code", FromPurchPrice."Direct Unit Cost");
        until FromPurchPrice.Next() = 0;
#else
        FromPriceListLine.SetRange("Source Type", "Price Source Type"::Vendor);
        FromPriceListLine.SetRange("Source No.", '20000');
        FromPriceListLine.Find('-');
        repeat
            PPUtil.InsertPurchPrice(
              '30000', FromPriceListLine."Asset No.", FromPriceListLine."Starting Date", FromPriceListLine."Ending Date",
              FromPriceListLine."Minimum Quantity", FromPriceListLine."Currency Code", FromPriceListLine."Unit of Measure Code", FromPriceListLine."Variant Code", FromPriceListLine."Direct Unit Cost");
        until FromPriceListLine.Next() = 0;
#endif

        for i := 1 to 5 do
            InsertPurchHeader(PurchHeader[i], PurchLine, "Purchase Document Type".FromInteger(i), '30000', '', 20020301D);

        DirectUnitCost[1] := 10.1;
        DirectUnitCost[2] := 10;
        DirectUnitCost[3] := 8;
        DirectUnitCost[4] := 11.11;
        DirectUnitCost[5] := 10;
        DirectUnitCost[6] := 30.3;
        DirectUnitCost[7] := 30.3;
        DirectUnitCost[8] := 40.4;
        DirectUnitCost[9] := 13200;
        DirectUnitCost[10] := 12900;
        DirectUnitCost[11] := 10.1;
        DirectUnitCost[12] := 10;
        DirectUnitCost[13] := 8;
        DirectUnitCost[14] := 11.11;
        DirectUnitCost[15] := 10;
        DirectUnitCost[16] := 30.3;
        DirectUnitCost[17] := 30.3;
        DirectUnitCost[18] := 40.4;
        DirectUnitCost[19] := 13200;
        DirectUnitCost[20] := 12900;
        DirectUnitCost[21] := 10;
        DirectUnitCost[22] := 10.25;

        DirectUnitCost[23] := 8.25;
        DirectUnitCost[24] := 7.5;
        DirectUnitCost[25] := 10;
        DirectUnitCost[26] := 10.25;
        DirectUnitCost[27] := 13200;
        DirectUnitCost[28] := 4;


        for i := 1 to 5 do begin
            Clear(PurchLine);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', DirectUnitCost[1]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', DirectUnitCost[2]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', DirectUnitCost[3]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', DirectUnitCost[4]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', DirectUnitCost[5]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'B', 2, '', '', '', DirectUnitCost[6]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'B', 5, '', 'BLUE', '', DirectUnitCost[7]);
            PurchLine.Validate("Direct Unit Cost", 35);
            PurchLine.Modify(true);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', '', DirectUnitCost[8]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 2, 'BOX', '', '', DirectUnitCost[9]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', DirectUnitCost[10]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -2, '', '', '', DirectUnitCost[11]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -5, '', '', '', DirectUnitCost[12]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -10, '', '', '', DirectUnitCost[13]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -2, '', 'BLUE', '', DirectUnitCost[14]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -5, '', 'BLUE', '', DirectUnitCost[15]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'B', -2, '', '', '', DirectUnitCost[16]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'B', -5, '', 'BLUE', '', DirectUnitCost[17]);
            PurchLine.Validate("Direct Unit Cost", 35);
            PurchLine.Modify(true);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -2, 'PCS', '', '', DirectUnitCost[18]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -2, 'BOX', '', '', DirectUnitCost[19]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -100, 'BOX', '', '', DirectUnitCost[20]);
        end;

        PurchLine.SetRange(PurchLine."Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader[PurchLine."Document Type"::Order.AsInteger()]."No.");
        PurchLine.Find('-');
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 5, 0);
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 5, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, -5, 0);

        PPUtil.PostPurchase(PurchHeader[PurchLine."Document Type"::Order.AsInteger()], true, false);

        PurchLine.Find('-');
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 3, 3);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 1, 1);
        UpdateQtyToRcvAndInv(PurchLine, 3, 3);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, -1, -1);
        UpdateQtyToRcvAndInv(PurchLine, -3, -3);

        PPUtil.PostPurchase(PurchHeader[PurchLine."Document Type"::Order.AsInteger()], true, true);

        FromPurchInvNo := GLUtil.GetLastDocNo(PurchaseSetup."Posted Invoice Nos.");

#if not CLEAN25
        GetPurchPrice(PurchPrice, '30000', 'A', 0D, 5, '', '', '');
        UpdatePurchPrice(PurchPrice, '30000', 'A', 0D, 0D, 3, '', '', '', 10.25);

        GetPurchPrice(PurchPrice, '30000', 'A', 0D, 10, '', '', '');
        UpdatePurchPrice(PurchPrice, '30000', 'A', 0D, 0D, 10, '', '', '', 8.25);

        PPUtil.InsertPurchPrice('30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        GetPurchPrice(PurchPrice, '30000', 'A', 20020401D, 5, '', '', '');
        UpdatePurchPrice(PurchPrice, '30000', 'A', 20020401D, 0D, 5, '', '', '', 4);

        GetPurchPrice(PurchPrice, '30000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePurchPrice(PurchPrice, '30000', 'D', 0D, 0D, 100, '', '', '', 12900);

        GetPurchPrice(PurchPrice, '30000', 'D', 20020401D, 5, 'USD', 'BOX', '');
        PurchPrice.Delete(true);
        CopyAllPricesToPriceListLines();
#else
        GetPurchPrice(PriceListLine, '30000', 'A', 0D, 5, '', '', '');
        UpdatePurchPrice(PriceListLine, '30000', 'A', 0D, 0D, 3, '', '', '', 10.25);

        GetPurchPrice(PriceListLine, '30000', 'A', 0D, 10, '', '', '');
        UpdatePurchPrice(PriceListLine, '30000', 'A', 0D, 0D, 10, '', '', '', 8.25);

        PPUtil.InsertPurchPrice('30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        GetPurchPrice(PriceListLine, '30000', 'A', 20020401D, 5, '', '', '');
        UpdatePurchPrice(PriceListLine, '30000', 'A', 20020401D, 0D, 5, '', '', '', 4);

        GetPurchPrice(PriceListLine, '30000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePurchPrice(PriceListLine, '30000', 'D', 0D, 0D, 100, '', '', '', 12900);

        GetPurchPrice(PriceListLine, '30000', 'D', 20020401D, 5, 'USD', 'BOX', '');
        PPUtil.AllowEditingActivePrice(true);
        PriceListLine.Delete(true);
        PPUtil.AllowEditingActivePrice(false);
#endif

        WorkDate := 20020402D;

        for i := 1 to 5 do begin
            ResetLastDirectCost('A', 10);

            PurchHeader[i].Find();
            PurchHeader[i].SetHideValidationDialog(true);
            ReleasePurchDoc.Reopen(PurchHeader[i]);
            PurchLine.SetRange(PurchLine."Document Type", PurchHeader[i]."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader[i]."No.");
            PurchLine.Find('+');

            if i = PurchLine."Document Type"::"Credit Memo".AsInteger() then begin
                PurchHeader[i].Validate("Posting Date", WorkDate());
                PurchHeader[i].Modify(true);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', DirectUnitCost[21]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', DirectUnitCost[28]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', DirectUnitCost[28]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 20, '', '', '', DirectUnitCost[28]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', DirectUnitCost[21]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', DirectUnitCost[28]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', DirectUnitCost[27]);
                PPUtil.PostPurchase(PurchHeader[i], true, true);
                FromPurchCrMemoNo := GLUtil.GetLastDocNo(PurchaseSetup."Posted Credit Memo Nos.");
            end else begin
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', DirectUnitCost[21]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', DirectUnitCost[22]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', DirectUnitCost[23]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 20, '', '', '', DirectUnitCost[24]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', 'BLUE', '', DirectUnitCost[25]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', 'BLUE', '', DirectUnitCost[26]);
                InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', DirectUnitCost[27]);
                if i = PurchLine."Document Type"::"Blanket Order".AsInteger() then begin
                    CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchHeader[i]);
                    PurchHeader[i].Get(PurchHeader[i]."Document Type"::Order, GLUtil.GetLastDocNo(PurchaseSetup."Order Nos."));
                end;
                PPUtil.PostPurchase(PurchHeader[i], true, true);
            end;
        end;

        DirectUnitCost[7] := 35;
        DirectUnitCost[17] := 35;

        PurchInvHeader.SetRange("No.", FromPurchInvNo, GLUtil.GetLastDocNo(PurchaseSetup."Posted Invoice Nos."));
        PurchInvHeader.Find('-');
        repeat
            PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            PurchInvLine.Find('-');
            repeat
                TestNumVal(
                  PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Direct Unit Cost"),
                  PurchInvLine."Direct Unit Cost", DirectUnitCost[PurchInvLine."Line No." / 10000]);
            until PurchInvLine.Next() = 0;
        until PurchInvHeader.Next() = 0;

        PurchCrMemoHeader.SetRange("No.", FromPurchCrMemoNo, GLUtil.GetLastDocNo(PurchaseSetup."Posted Credit Memo Nos."));
        PurchCrMemoHeader.Find('-');
        repeat
            PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
            PurchCrMemoLine.Find('-');
            repeat
                if item."No." = 'B' then
                    TestNumVal(
                      PurchCrMemoHeader.TableName, PurchCrMemoLine."Document No.", PurchCrMemoLine.FieldName("Direct Unit Cost"),
                      PurchCrMemoLine."Direct Unit Cost", DirectUnitCost[PurchCrMemoLine."Line No." / 10000]);
            until PurchCrMemoLine.Next() = 0;
        until PurchCrMemoHeader.Next() = 0;

        WorkDate := 20020401D;
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        DirectUnitCost: array[2] of Decimal;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchPrice: Record "Purchase Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        FromPurchInvNo: Code[20];
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        CurrTest := 'P.4';

        DirectUnitCost[1] := 10;
        DirectUnitCost[2] := 12900;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', DirectUnitCost[1]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', DirectUnitCost[2]);
#if not CLEAN25
        PurchPrice.Get('A', '20000', 0D, '', '', '', 5);
        PurchPrice.Validate("Direct Unit Cost", 10.5);
        PurchPrice.Modify(true);

        PurchPrice.Get('D', '20000', 0D, '', '', 'BOX', 100);
        PurchPrice.Validate("Direct Unit Cost", 12900.5);
        PurchPrice.Modify(true);
        CopyAllPricesToPriceListLines();
#else
        PPUtil.AllowEditingActivePrice(true);
        GetPurchPrice(PriceListLine, '20000', 'A', 0D, 5, '', '', '');
        PriceListLine.Validate("Direct Unit Cost", 10.5);
        PriceListLine.Modify(true);

        GetPurchPrice(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '');
        PriceListLine.Validate("Direct Unit Cost", 12900.5);
        PriceListLine.Modify(true);
        PPUtil.AllowEditingActivePrice(false);
#endif

        PurchLine.SetRange(PurchLine."Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        UpdateQtyToShipAndInvoice(PurchLine, 1, 0);
        UpdateQtyToShipAndInvoice(PurchLine, 1, 0);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchLine.Find('-');
        UpdateQtyToShipAndInvoice(PurchLine, 0, 1);
        UpdateQtyToShipAndInvoice(PurchLine, 0, 1);

        PPUtil.PostPurchase(PurchHeader, false, true);

        FromPurchInvNo := GLUtil.GetLastDocNo(PurchaseSetup."Posted Invoice Nos.");

        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvHeader.SetRange("No.", FromPurchInvNo, GLUtil.GetLastDocNo(PurchaseSetup."Posted Invoice Nos."));
        PurchInvHeader.Find('-');
        repeat
            PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            PurchInvLine.Find('-');
            repeat
                TestNumVal(
                  PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Direct Unit Cost"),
                  PurchInvLine."Direct Unit Cost", DirectUnitCost[PurchInvLine."Line No." / 10000]);
            until PurchInvLine.Next() = 0;
        until PurchInvHeader.Next() = 0;
#if not CLEAN25
        PurchPrice.Get('A', '20000', 0D, '', '', '', 5);
        PurchPrice.Validate("Direct Unit Cost", 10);
        PurchPrice.Modify(true);

        PurchPrice.Get('D', '20000', 0D, '', '', 'BOX', 100);
        PurchPrice.Validate("Direct Unit Cost", 12900);
        PurchPrice.Modify(true);
        CopyAllPricesToPriceListLines();
#else
        GetPurchPrice(PriceListLine, '20000', 'A', 0D, 5, '', '', '');
        PriceListLine.Validate("Direct Unit Cost", 10);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);

        GetPurchPrice(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '');
        PriceListLine.Validate("Direct Unit Cost", 12900);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
#endif
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchPrice: Record "Purchase Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        DirectUnitCost: array[5] of Decimal;
        i: Integer;
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := 'P.6';

        DirectUnitCost[1] := 6;
        DirectUnitCost[2] := 4;
        DirectUnitCost[3] := 2;
        DirectUnitCost[4] := 13050;
        DirectUnitCost[5] := 12900;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', '', DirectUnitCost[1]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', '', DirectUnitCost[2]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', '', DirectUnitCost[3]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', '', DirectUnitCost[4]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', '', DirectUnitCost[5]);

        PPUtil.PostPurchase(PurchHeader, true, false);

        DirectUnitCost[3] := 1.5;

        PurchHeader.Find();
        ReleasePurchDoc.Reopen(PurchHeader);
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 30000);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost[3]);
        PurchLine.Modify(true);
#if not CLEAN25
        PurchPrice.Get('A', '20000', 20020401D, '', '', '', 0);
        PurchPrice.Validate("Direct Unit Cost", 6.5);
        PurchPrice.Modify(true);

        PurchPrice.Get('D', '20000', 20020401D, '', '', 'BOX', 0);
        PurchPrice.Validate("Direct Unit Cost", 12900.5);
        PurchPrice.Modify(true);
        CopyAllPricesToPriceListLines();
#else
        PPUtil.AllowEditingActivePrice(true);
        GetPurchPrice(PriceListLine, '20000', 'A', 20020401D, 0, '', '', '');
        PriceListLine.Validate("Direct Unit Cost", 6.5);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);

        GetPurchPrice(PriceListLine, '20000', 'D', 20020401D, 0, '', 'BOX', '');
        PriceListLine.Validate("Direct Unit Cost", 12900.5);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
        PPUtil.AllowEditingActivePrice(false);
#endif

        PurchHeader.Find();
        PurchRcptLine.SetRange("Document No.", PurchHeader."Last Receiving No.");
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '20000', '', 20020401D);
        PurchGetReceipt.SetPurchHeader(PurchHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvLine.SetRange("Document No.", GLUtil.GetLastDocNo(PurchaseSetup."Posted Invoice Nos."));
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.Find('-');
        i := 1;
        repeat
            TestNumVal(
              PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Direct Unit Cost"),
              PurchInvLine."Direct Unit Cost", DirectUnitCost[i]);
            i += 1;
        until PurchInvLine.Next() = 0;
#if not CLEAN25
        PurchPrice.Get('A', '20000', 20020401D, '', '', '', 0);
        PurchPrice.Validate("Direct Unit Cost", 6);
        PurchPrice.Modify(true);

        PurchPrice.Get('D', '20000', 0D, '', '', 'BOX', 100);
        PurchPrice.Validate("Direct Unit Cost", 12900);
        PurchPrice.Modify(true);
        CopyAllPricesToPriceListLines();
#else
        PPUtil.AllowEditingActivePrice(true);
        GetPurchPrice(PriceListLine, '20000', 'A', 20020401D, 0, '', '', '');
        PriceListLine.Validate("Direct Unit Cost", 6);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);

        GetPurchPrice(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '');
        PriceListLine.Validate("Direct Unit Cost", 12900);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
        PPUtil.AllowEditingActivePrice(false);
#endif
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchPrice: Record "Purchase Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        CurrTest := 'P.8';
#if not CLEAN25
        if PurchPrice.Get('D', '20000', 0D, '', 'VAR', '', 1) then
            PurchPrice.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 1, '', '', 'VAR', 4000);

        if PurchPrice.Get('D', '20000', 0D, '', 'VAR', 'BOX', 1) then
            PurchPrice.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 11000);

        if PurchPrice.Get('A', '20000', 0D, '', '', '', 5) then
            PurchPrice.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'A', 0D, 0D, 5, '', '', '', 10);

        if PurchPrice.Get('D', '20000', 0D, '', '', 'BOX', 100) then
            PurchPrice.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 12900);
        CopyAllPricesToPriceListLines();
#else
        PPUtil.AllowEditingActivePrice(true);
        if GetPurchPrice(PriceListLine, '20000', 'D', 0D, 1, '', '', 'VAR') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 1, '', '', 'VAR', 4000);

        if GetPurchPrice(PriceListLine, '20000', 'D', 0D, 1, '', 'BOX', 'VAR') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 11000);

        if GetPurchPrice(PriceListLine, '20000', 'A', 0D, 5, '', '', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'A', 0D, 0D, 5, '', '', '', 10);

        if GetPurchPrice(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchPrice('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 12900);
        PPUtil.AllowEditingActivePrice(false);
#endif

        Item.Get('A');
        Item.Validate("Last Direct Cost", 5.55);
        Item.Modify(true);

        SKU.Get('BLUE', 'A', '');
        SKU.Validate("Last Direct Cost", 6.66);
        SKU.Modify(true);

        Item.Get('D');
        Item.Validate("Last Direct Cost", 777.77);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', '', 5.55);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 1, 'BOX', '', '', 13200);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 5, '', '', 'PCS', 10);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'BOX', 12900);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 5, 'BLUE', '', 'PCS', 10);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'PCS', 777.77);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 1, 'BLUE', '', '', 6.66);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 5, 'BLUE', '', 'PCS', 10);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', '', 'BOX', 13200);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', 'VAR', 'PCS', 4000);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', 'VAR', 'BOX', 11000);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', 'VAR', 'BOX', 11000);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', '', 'BOX', 13200);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'BOX', 12900);
    end;

    [Scope('OnPrem')]
    procedure Test9()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
        CarryOutAM: Report "Carry Out Action Msg. - Plan.";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FromPurchOrderNo: Code[10];
    begin
        CurrTest := 'P.9';

        Item.Get('A');
        Item2 := Item;
        Item2.Validate("No.", 'A2');
        Item2.Validate("Vendor No.", '10000');
        Item2.Insert(true);
        INVTUtil.InsertItemUOM(Item2."No.", 'PCS', 1);
        Item2.Validate("Base Unit of Measure", 'PCS');
        Item2.Validate("Reordering Policy", Item2."Reordering Policy"::"Lot-for-Lot");
        Item2.Modify(true);

        PPUtil.InsertPurchPrice('10000', 'A2', 0D, 0D, 5, '', '', '', 4.25);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 2, '', '', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 2, '', 'BLUE', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 5, '', 'BLUE', '', 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 2, '', '', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 2, '', 'BLUE', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A2', 5, '', 'BLUE', '', 0);

        CalcPlan.SetTemplAndWorksheet('Planning', 'DEFAULT', true);
        CalcPlan.InitializeRequest(20010101D, 20030101D, false);
        CalcPlan.SetTableView(Item2);
        CalcPlan.UseRequestPage := false;
        CalcPlan.RunModal();

        ReqLine."Worksheet Template Name" := 'PLANNING';
        ReqLine."Journal Batch Name" := 'DEFAULT';
        CarryOutAM.SetReqWkshLine(ReqLine);
        CarryOutAM.InitializeRequest(2, 1, 1, 1);
        FromPurchOrderNo := GLUtil.GetLastDocNo(PurchaseSetup."Order Nos.");
        CarryOutAM.SetTableView(ReqLine);
        CarryOutAM.UseRequestPage := false;
        CarryOutAM.RunModal();

        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Find('+');

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 10000);
        TestNumVal(
          PurchHeader.TableName, PurchLine."Document No.", PurchLine.FieldName("Direct Unit Cost"),
          PurchLine."Direct Unit Cost", 10.1);

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 20000);
        TestNumVal(
          PurchHeader.TableName, PurchLine."Document No.", PurchLine.FieldName("Direct Unit Cost"),
          PurchLine."Direct Unit Cost", 10);
    end;

    local procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; CostingMethod: Enum "Costing Method"; DirectUnitCost: Decimal; LastDirectCost: Decimal; PurchUOM: Code[20]; BaseQtyPerPurchUOM: Decimal; ReqMethodCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        if PurchUOM <> BaseUOM then begin
            INVTUtil.InsertItemUOM(Item."No.", PurchUOM, BaseQtyPerPurchUOM);
            Item.Validate("Purch. Unit of Measure", PurchUOM);
        end;

        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", DirectUnitCost);
        Item.Validate("Last Direct Cost", LastDirectCost);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        if ReqMethodCode = 'M-T-S' then begin
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
            Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
            Item.Validate("Include Inventory", true);
        end;
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSKU(ItemNo: Code[10]; LocCode: Code[10]; VarCode: Code[10]; LastDirectCost: Decimal)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.Init();
        SKU.Validate("Item No.", ItemNo);
        SKU.Validate("Location Code", LocCode);
        SKU.Validate("Variant Code", VarCode);
        SKU.Insert(true);
        SKU.Validate("Last Direct Cost", LastDirectCost);
        SKU.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[20]; Date: Date)
    begin
        WorkDate := Date;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
    end;

    local procedure InsertAndTestPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; LocCode: Code[10]; VarCode: Code[20]; ExpectedDirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate(Quantity, Qty);
        if LocCode <> PurchLine."Location Code" then
            PurchLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> PurchLine."Unit of Measure Code") then
            PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Validate("Variant Code", VarCode);
        PurchLine.Modify(true);

        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Direct Unit Cost"), PurchLine."Direct Unit Cost", ExpectedDirectUnitCost);
    end;

    local procedure TestNumVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Decimal; ExpectedValue: Decimal)
    begin
        if Value <> ExpectedValue then
            error('x');
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    local procedure UpdateQtyToShipAndInvoice(var PurchLine: Record "Purchase Line"; QtyToReceive: Decimal; QtyToInv: Decimal)
    begin
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Validate("Qty. to Invoice", QtyToInv);
        PurchLine.Modify(true);
        PurchLine.Next();
    end;

    local procedure EditAndTestPurchLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal; LocCode: Code[20]; VarCode: Code[20]; UOMCode: Code[20]; DirectUnitCost: Decimal)
    begin
        if ItemNo <> PurchLine."No." then
            PurchLine.Validate("No.", ItemNo);
        if Qty <> PurchLine.Quantity then
            PurchLine.Validate(Quantity, Qty);
        if VarCode <> PurchLine."Variant Code" then
            PurchLine.Validate("Variant Code", VarCode);
        if LocCode <> PurchLine."Location Code" then
            PurchLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> PurchLine."Unit of Measure Code") then
            PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Modify(true);

        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Direct Unit Cost"), PurchLine."Direct Unit Cost", DirectUnitCost);

        PurchLine.Next();
    end;

    local procedure UpdateQtyToRcvAndInv(var PurchLine: Record "Purchase Line"; QtyToRcv: Decimal; QtyToInv: Decimal)
    begin
        PurchLine.Validate("Qty. to Receive", QtyToRcv);
        PurchLine.Validate("Qty. to Invoice", QtyToInv);
        PurchLine.Modify(true);
        PurchLine.Next();
    end;

    [Scope('OnPrem')]
    procedure GetPurchPrice(var PriceListLine: Record "Price List Line"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        PriceListLine.Reset();
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Source Type", "Price Source Type"::Vendor);
        PriceListLine.SetRange("Source No.", VendorNo);
        PriceListLine.SetRange("Starting Date", StartDate);
        PriceListLine.SetRange("Currency Code", CurrencyCode);
        PriceListLine.SetRange("Variant Code", VarCode);
        PriceListLine.SetRange("Unit of Measure Code", UOMCode);
        PriceListLine.SetRange("Minimum Quantity", MinQty);
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        exit(PriceListLine.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchPrice(var PriceListLine: Record "Price List Line"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; DirectUnitCost: Decimal)
    begin
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Source No.", VendorNo);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Variant Code", VarCode);
        PriceListLine.Validate("Unit of Measure Code", UOMCode);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        if EndDate <> PriceListLine."Ending Date" then
            PriceListLine.Validate("Ending Date", EndDate);
        if DirectUnitCost <> PriceListLine."Direct Unit Cost" then
            PriceListLine.Validate("Direct Unit Cost", DirectUnitCost);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

#if not CLEAN25
    [Scope('OnPrem')]
    procedure GetPurchPrice(var PurchPrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        exit(
          PurchPrice.Get(
            ItemNo,
            VendorNo,
            StartDate,
            CurrencyCode,
            VarCode,
            UOMCode,
            MinQty));
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchPrice(var Purchprice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; DirectUnitCost: Decimal)
    begin
        Purchprice.Rename(
            ItemNo,
            VendorNo,
            StartDate,
            CurrencyCode,
            VarCode,
            UOMCode,
            MinQty);
        if EndDate <> Purchprice."Ending Date" then
            Purchprice.Validate("Ending Date", EndDate);
        if DirectUnitCost <> Purchprice."Direct Unit Cost" then
            Purchprice.Validate("Direct Unit Cost", DirectUnitCost);
        Purchprice.Modify(true)
    end;
#endif

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Line Type"; CustNo: Code[20]; CurrencyCode: Code[20]; Date: Date)
    begin
        WorkDate := Date;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure InsertAndTestSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Costing Method"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; LocCode: Code[10]; VarCode: Code[20]; ExpectedUnitPrice: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        if LocCode <> SalesLine."Location Code" then
            SalesLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> SalesLine."Unit of Measure Code") then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Validate("Variant Code", VarCode);
        SalesLine.Modify(true);

        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Unit Price"), SalesLine."Unit Price", ExpectedUnitPrice);
    end;

    [Scope('OnPrem')]
    procedure ResetLastDirectCost(ItemNo: Code[10]; LastDirectCost: Decimal)
    var
        item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        item.Get(ItemNo);
        SKU.Get('BLUE', 'A', '');
        item."Last Direct Cost" := LastDirectCost;
        SKU."Last Direct Cost" := LastDirectCost;
        item.Modify(true);
        SKU.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;

#if not CLEAN25
    local procedure CopyAllPricesToPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
    begin
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
    end;
#endif
}

