codeunit 103526 "Test - Sales Pricing"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103526);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        Test1();
        Test2();
        Test3();
        Test4();
        Test6();
        Test7();
        Test8();
        Test10();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        SRUtil: Codeunit SRUtil;
        GetShipment: Codeunit "Sales-Get Shipment";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
#if not CLEAN25
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif
        CurrTest: Text[30];
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Cust: Record Customer;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Modify(true);

        GLUtil.SetAddCurr('USD', 100, 64.8824, 0.01, 0.001);

        InsertItem('A', 'PCS', 22.22, 10, 'PCS', 1);
        InsertItem('B', 'PCS', 333.33, 0, 'PCS', 1);
        InsertItem('C', 'PCS', 4444.44, 0, 'BOX', 3);
        INVTUtil.InsertItemVariant('C', 'VAR');
        InsertItem('D', 'PCS', 4444.44, 0, 'BOX', 3);
        INVTUtil.InsertItemVariant('D', 'VAR');

        SRUtil.InsertCustPriceGrp('CPG1', false, '', true, true);
        SRUtil.InsertCustDiscGrp('CDG1');

        Cust.Get('10000');
        Cust.Validate("Customer Price Group", 'CPG1');
        Cust.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure Test1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#endif
    begin
        CurrTest := 'S.1';
#if not CLEAN25
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '10000', 'A', 0D, 0D, 0, '', '', '', 22.21);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '10000', 'A', 20020301D, 20020501D, 0, '', '', '', 20);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '10000', 'A', 20020401D, 20020401D, 0, '', '', '', 18);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '10000', 'A', 20020601D, 0D, 0, '', '', '', 14);

        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG1', 'B', 0D, 0D, 0, '', '', '', 333.31);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG1', 'B', 20020301D, 20020501D, 0, '', '', '', 330);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG1', 'B', 20020401D, 20020401D, 0, '', '', '', 320);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG1', 'B', 20020601D, 0D, 0, '', '', '', 300);

        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'C', 0D, 0D, 0, '', '', '', 4444.41);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'C', 20020301D, 20020501D, 0, '', '', '', 4440);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'C', 20020401D, 20020401D, 0, '', '', '', 4430);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'C', 20020601D, 0D, 0, '', '', '', 4410);
#else
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '10000', 'A', 0D, 0D, 0, '', '', '', 22.21);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '10000', 'A', 20020301D, 20020501D, 0, '', '', '', 20);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '10000', 'A', 20020401D, 20020401D, 0, '', '', '', 18);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '10000', 'A', 20020601D, 0D, 0, '', '', '', 14);

        SRUtil.InsertSalesPrice("Price Source Type"::"Customer Price Group", 'CPG1', 'B', 0D, 0D, 0, '', '', '', 333.31);
        SRUtil.InsertSalesPrice("Price Source Type"::"Customer Price Group", 'CPG1', 'B', 20020301D, 20020501D, 0, '', '', '', 330);
        SRUtil.InsertSalesPrice("Price Source Type"::"Customer Price Group", 'CPG1', 'B', 20020401D, 20020401D, 0, '', '', '', 320);
        SRUtil.InsertSalesPrice("Price Source Type"::"Customer Price Group", 'CPG1', 'B', 20020601D, 0D, 0, '', '', '', 300);

        SRUtil.InsertSalesPrice("Price Source Type"::"All Customers", '', 'C', 0D, 0D, 0, '', '', '', 4444.41);
        SRUtil.InsertSalesPrice("Price Source Type"::"All Customers", '', 'C', 20020301D, 20020501D, 0, '', '', '', 4440);
        SRUtil.InsertSalesPrice("Price Source Type"::"All Customers", '', 'C', 20020401D, 20020401D, 0, '', '', '', 4430);
        SRUtil.InsertSalesPrice("Price Source Type"::"All Customers", '', 'C', 20020601D, 0D, 0, '', '', '', 4410);
#endif

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 22.21);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 333.31);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 13333.23);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 20);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 330);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 13320);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 18);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 320);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 13290);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020601D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 14);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 300);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 13230);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 22.22);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 333.33);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 13290);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#endif
    begin
        CurrTest := 'S.2';
#if not CLEAN25
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 0D, 0D, 5, '', '', '', 10);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 0D, 0D, 10, '', '', '', 8);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 20010101D, 20010101D, 5, '', '', '', 11);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 20020401D, 20020401D, 0, '', '', '', 6);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 20020401D, 20020401D, 5, '', '', '', 4);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 20020401D, 20020401D, 10, '', '', '', 2);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'B', 0D, 0D, 0, 'USD', '', '', 500);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'B', 0D, 0D, 100, 'USD', '', '', 430);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'B', 20020401D, 20020401D, 0, 'USD', '', '', 465);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'B', 20020401D, 20020401D, 5, 'USD', '', '', 455);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'B', 20020401D, 20020401D, 10, 'USD', '', '', 430);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 0D, 0D, 0, '', 'BOX', '', 13200);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 0D, 0D, 0, 'USD', 'BOX', '', 20000);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 0D, 0D, 100, '', 'BOX', '', 12900);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 13050);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 19500);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 19200);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 18900);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 17000);
#else
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 0D, 0D, 5, '', '', '', 10);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 0D, 0D, 10, '', '', '', 8);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 20010101D, 20010101D, 5, '', '', '', 11);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 20020401D, 20020401D, 0, '', '', '', 6);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 20020401D, 20020401D, 5, '', '', '', 4);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 20020401D, 20020401D, 10, '', '', '', 2);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'B', 0D, 0D, 0, 'USD', '', '', 500);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'B', 0D, 0D, 100, 'USD', '', '', 430);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'B', 20020401D, 20020401D, 0, 'USD', '', '', 465);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'B', 20020401D, 20020401D, 5, 'USD', '', '', 455);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'B', 20020401D, 20020401D, 10, 'USD', '', '', 430);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 0D, 0D, 0, '', 'BOX', '', 13200);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 0D, 0D, 0, 'USD', 'BOX', '', 20000);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 0D, 0D, 100, '', 'BOX', '', 12900);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 13050);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 19500);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 19200);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 18900);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 17000);
#endif

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 22.22);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 8);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', 4444.44);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'BOX', '', 13200);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 12900);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 6);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 4);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 2);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 90, 'BOX', '', 13050);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 12900);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20010101D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 22.22);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 8);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', 'USD', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 34.247);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 15.413);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 12.33);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 500);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 100, '', '', 430);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', 6849.993);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'BOX', '', 20000);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 20000);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', 'USD', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 9.248);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 6.165);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 3.083);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 465);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 100, '', '', 430);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', 6849.993);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'BOX', '', 19500);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 18900);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 10, 'BOX', 'VAR', 17000);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        PriceListLine: Record "Price List Line";
        SalesHeader: array[5] of Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#endif
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        UnitPrice: array[16] of Decimal;
        i: Integer;
        FromSalesInvNo: Code[20];
        FromSalesCrMemoNo: Code[20];
    begin
        CurrTest := 'S.3';
#if not CLEAN25
        Clear(SalesPrice);

        SalesPrice.SetRange("Sales Code", '20000');
        SalesPrice.Find('-');
        repeat
            SRUtil.InsertSalesPrice(
              SalesPrice."Sales Type"::Customer, '30000', SalesPrice."Item No.", SalesPrice."Starting Date", SalesPrice."Ending Date",
              SalesPrice."Minimum Quantity", SalesPrice."Currency Code", SalesPrice."Unit of Measure Code", SalesPrice."Variant Code", SalesPrice."Unit Price");
        until SalesPrice.Next() = 0;
#else
        PriceListLine.SetRange("Source Type", "Price Source Type"::Customer);
        PriceListLine.SetRange("Source No.", '20000');
        PriceListLine.Find('-');
        repeat
            SRUtil.InsertSalesPrice(
              PriceListLine."Source Type"::Customer, '30000', PriceListLine."Asset No.", PriceListLine."Starting Date", PriceListLine."Ending Date",
              PriceListLine."Minimum Quantity", PriceListLine."Currency Code", PriceListLine."Unit of Measure Code", PriceListLine."Variant Code", PriceListLine."Unit Price");
        until PriceListLine.Next() = 0;
#endif

        for i := 1 to 5 do
            InsertSalesHeader(SalesHeader[i], SalesLine, "Sales Document Type".FromInteger(i), '30000', '', 20020301D);

        UnitPrice[1] := 22.22;
        UnitPrice[2] := 10;
        UnitPrice[3] := 8;
        UnitPrice[4] := 4444.44;
        UnitPrice[5] := 13200;
        UnitPrice[6] := 12900;
        UnitPrice[7] := 22.22;
        UnitPrice[8] := 10;
        UnitPrice[9] := 8;
        UnitPrice[10] := 4444.44;
        UnitPrice[11] := 13200;
        UnitPrice[12] := 12900;
        UnitPrice[13] := 10;
        UnitPrice[14] := 8.25;
        UnitPrice[15] := 7.5;
        UnitPrice[16] := 13200;

        for i := 1 to 5 do begin
            Clear(SalesLine);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 2, '', '', UnitPrice[1]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 5, '', '', UnitPrice[2]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 10, '', '', UnitPrice[3]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', UnitPrice[4]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 2, 'BOX', '', UnitPrice[5]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', UnitPrice[6]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -2, '', '', UnitPrice[7]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -5, '', '', UnitPrice[8]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -10, '', '', UnitPrice[9]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -2, 'PCS', '', UnitPrice[10]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -2, 'BOX', '', UnitPrice[11]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -100, 'BOX', '', UnitPrice[12]);
        end;

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader[SalesLine."Document Type"::Order.AsInteger()]."No.");
        SalesLine.Find('-');
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 5, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 5, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, -5, 0);

        SRUtil.PostSales(SalesHeader[SalesLine."Document Type"::Order.AsInteger()], true, false);

        SalesLine.Find('-');
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 3, 3);
        UpdateQtyToShipAndInvoice(SalesLine, 1, 1);
        UpdateQtyToShipAndInvoice(SalesLine, 1, 1);
        UpdateQtyToShipAndInvoice(SalesLine, 3, 3);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 0);
        UpdateQtyToShipAndInvoice(SalesLine, -1, -1);
        UpdateQtyToShipAndInvoice(SalesLine, -3, -3);

        SRUtil.PostSales(SalesHeader[SalesLine."Document Type"::Order.AsInteger()], true, true);

        FromSalesInvNo := GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos.");
#if not CLEAN25
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '30000', 0D, '', '', '', 5);
        SalesPrice.Rename('A', SalesPrice."Sales Type"::Customer, '30000', 0D, '', '', '', 3);

        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '30000', 0D, '', '', '', 10);
        SalesPrice.Validate("Unit Price", 8.25);
        SalesPrice.Modify(true);

        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '30000', 20020401D, '', '', '', 5);
        SalesPrice.Validate("Ending Date", 20030401D);
        SalesPrice.Modify(true);

        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '30000', 20020401D, '', '', '', 5);
        SalesPrice.Validate("Ending Date", 0D);
        SalesPrice.Modify(true);

        SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '30000', 0D, '', '', 'BOX', 100);
        SalesPrice.Rename('D', SalesPrice."Sales Type"::Customer, '30000', 0D, '', '', '', 100);

        SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '30000', 20020401D, 'USD', '', 'BOX', 5);
        SalesPrice.Delete();

        PriceListLine.Reset();
        PriceListLine.DeleteAll();
        SalesPrice.Reset();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
#else
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', '', 5);
        PriceListLine."Minimum Quantity" := 3;
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', '', 10);
        PriceListLine."Unit Price" := 8.25;
        PriceListLine.Modify(true);

        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::Customer, '30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 20020401D, '', '', '', 5);
        PriceListLine."Ending Date" := 20030401D;
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 20020401D, '', '', '', 5);
        PriceListLine."Ending Date" := 0D;
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', 'BOX', 100);
        PriceListLine."Unit of Measure Code" := '';
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 20020401D, 'USD', '', 'BOX', 5);
        PriceListLine.Delete();
#endif

        for i := 1 to 5 do begin
            SalesHeader[i].Find();
            ReleaseSalesDoc.Reopen(SalesHeader[i]);
            SalesLine.SetRange("Document Type", SalesHeader[i]."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader[i]."No.");
            SalesLine.Find('+');
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 5, '', '', UnitPrice[13]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 10, '', '', UnitPrice[14]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 20, '', '', UnitPrice[15]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', UnitPrice[16]);
            if i = SalesLine."Document Type"::"Blanket Order".AsInteger() then begin
                CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader[i]);
                SalesHeader[i].Get(SalesHeader[i]."Document Type"::Order, GLUtil.GetLastDocNo(SalesSetup."Order Nos."));
            end;
            SRUtil.PostSales(SalesHeader[i], true, true);
            if i = SalesLine."Document Type"::"Credit Memo".AsInteger() then
                FromSalesCrMemoNo := GLUtil.GetLastDocNo(SalesSetup."Posted Credit Memo Nos.");
        end;

        SalesInvHeader.SetRange("No.", FromSalesInvNo, GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos."));
        SalesInvHeader.Find('-');
        repeat
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.Find('-');
            repeat
                TestNumVal(
                  SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Unit Price"),
                  SalesInvLine."Unit Price", UnitPrice[SalesInvLine."Line No." / 10000]);
            until SalesInvLine.Next() = 0;
        until SalesInvHeader.Next() = 0;

        SalesCrMemoHeader.SetRange("No.", FromSalesCrMemoNo, GLUtil.GetLastDocNo(SalesSetup."Posted Credit Memo Nos."));
        SalesCrMemoHeader.Find('-');
        repeat
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
            SalesCrMemoLine.Find('-');
            repeat
                TestNumVal(
                  SalesCrMemoHeader.TableName, SalesCrMemoLine."Document No.", SalesCrMemoLine.FieldName("Unit Price"),
                  SalesCrMemoLine."Unit Price", UnitPrice[SalesCrMemoLine."Line No." / 10000]);
            until SalesCrMemoLine.Next() = 0;
        until SalesCrMemoHeader.Next() = 0;

    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        FromSalesInvNo: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        CurrTest := 'S.4';

        UnitPrice[1] := 10;
        UnitPrice[2] := 12900;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', UnitPrice[1]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', UnitPrice[2]);
#if not CLEAN25
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '20000', 0D, '', '', '', 5);
        SalesPrice.Validate("Unit Price", 10.5);
        SalesPrice.Modify(true);

        SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 100);
        SalesPrice.Validate("Unit Price", 12900.5);
        SalesPrice.Modify(true);
#else
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', '', 5);
        PriceListLine."Unit Price" := 10.5;
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 100);
        PriceListLine."Unit Price" := 12900.5;
        PriceListLine.Modify(true);
#endif

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        UpdateQtyToShipAndInvoice(SalesLine, 1, 0);
        UpdateQtyToShipAndInvoice(SalesLine, 1, 0);

        SRUtil.PostSales(SalesHeader, true, false);

        SalesLine.Find('-');
        UpdateQtyToShipAndInvoice(SalesLine, 0, 1);
        UpdateQtyToShipAndInvoice(SalesLine, 0, 1);

        SRUtil.PostSales(SalesHeader, false, true);

        FromSalesInvNo := GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos.");

        SRUtil.PostSales(SalesHeader, true, true);

        SalesInvHeader.SetRange("No.", FromSalesInvNo, GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos."));
        SalesInvHeader.Find('-');
        repeat
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.Find('-');
            repeat
                TestNumVal(
                  SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Unit Price"),
                  SalesInvLine."Unit Price", UnitPrice[SalesInvLine."Line No." / 10000]);
            until SalesInvLine.Next() = 0;
        until SalesInvHeader.Next() = 0;
#if not CLEAN25
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '20000', 0D, '', '', '', 5);
        SalesPrice.Validate("Unit Price", 10);
        SalesPrice.Modify(true);

        SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 100);
        SalesPrice.Validate("Unit Price", 12900);
        SalesPrice.Modify(true);
#else
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', '', 5);
        PriceListLine."Unit Price" := 10;
        PriceListLine.Modify(true);

        GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 100);
        PriceListLine."Unit Price" := 12900;
        PriceListLine.Modify(true);

#endif
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        UnitPrice: array[5] of Decimal;
        i: Integer;
    begin
        CurrTest := 'S.6';

        UnitPrice[1] := 6;
        UnitPrice[2] := 4;
        UnitPrice[3] := 2;
        UnitPrice[4] := 13050;
        UnitPrice[5] := 12900;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', UnitPrice[1]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', UnitPrice[2]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', UnitPrice[3]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 90, 'BOX', '', UnitPrice[4]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', UnitPrice[5]);

        SRUtil.PostSales(SalesHeader, true, false);

        UnitPrice[3] := 1.5;

        SalesHeader.Find();
        ReleaseSalesDoc.Reopen(SalesHeader);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
        SalesLine.Validate("Unit Price", UnitPrice[3]);
        SalesLine.Modify(true);
#if not CLEAN25
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '20000', 20020401D, '', '', '', 0);
        SalesPrice.Validate("Unit Price", 6.5);
        SalesPrice.Modify(true);
#else
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 20020401D, '', '', '', 0);
        PriceListLine."Unit Price" := 6.5;
        PriceListLine.Modify(true);
#endif

        SalesHeader.Find();
        SalesShptLine.SetRange("Document No.", SalesHeader."Last Shipping No.");
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '20000', '', 20020401D);
        GetShipment.SetSalesHeader(SalesHeader);
        GetShipment.CreateInvLines(SalesShptLine);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesInvLine.SetRange("Document No.", GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos."));
        SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
        SalesInvLine.Find('-');
        i := 1;
        repeat
            TestNumVal(
              SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Unit Price"),
              SalesInvLine."Unit Price", UnitPrice[i]);
            i += 1;
        until SalesInvLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test7()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        UnitPrice: array[5] of Decimal;
    begin
        CurrTest := 'S.7';

        UnitPrice[1] := 22.22;
        UnitPrice[2] := 8;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', UnitPrice[1]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 100, '', '', UnitPrice[2]);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesInvLine.SetRange("Document No.", GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos."));
        SalesInvLine.Find('-');
        TestNumVal(
          SalesInvLine.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Amount"),
          SalesInvLine."Line Amount", 44.44);
        SalesInvLine.Next();
        TestNumVal(
          SalesInvLine.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Amount"),
          SalesInvLine."Line Amount", 800);
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
    begin
        CurrTest := 'S.8';
#if not CLEAN25
        if SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '20000', 0D, '', 'VAR', '', 1) then
            SalesPrice.Delete(true);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 0D, 0D, 1, '', '', 'VAR', 4000);

        if SalesPrice.Get('D', SalesPrice."Sales Type"::Customer, '20000', 0D, '', 'VAR', 'BOX', 1) then
            SalesPrice.Delete(true);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 11000);
#else
        if GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', 'VAR', '', 1) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::Customer, '20000', 'D', 0D, 0D, 1, '', '', 'VAR', 4000);

        if GetSalesPrice(PriceListLine, 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', 'VAR', 'BOX', 1) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::Customer, '20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 11000);
#endif

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 22.22);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 1, 'BOX', '', 13200);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'A', 5, '', '', 'PCS', 10);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'BOX', 12900);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'A', 5, 'BLUE', '', 'PCS', 10);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'PCS', 4444.44);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', '', 'BOX', 13200);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', 'VAR', 'PCS', 4000);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', 'VAR', 'BOX', 11000);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', 'VAR', 'BOX', 11000);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', '', 'BOX', 13200);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'BOX', 12900);
    end;

    [Scope('OnPrem')]
    procedure Test10()
    var
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        ItemJnlLine: Record "Item Journal Line";
    begin
        CurrTest := 'S.10';
#if not CLEAN25
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'A', 20010101D, 20040101D, 10, '', '', '', 18);
#else
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'A', 20010101D, 20040101D, 10, '', '', '', 18);
#endif

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 2, 22.22);
        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 5, 20);

        ItemJnlLine.Validate(Quantity);
        TestNumVal('After Validate:', ItemJnlLine."Line No.", ItemJnlLine.FieldName("Unit Amount"), ItemJnlLine."Unit Amount", 20);

        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 10, 18);
    end;

    local procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; UnitPrice: Decimal; UnitCost: Decimal; SalesUOM: Code[20]; BaseQtyPerSalesUOM: Decimal)
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        if SalesUOM <> BaseUOM then begin
            INVTUtil.InsertItemUOM(Item."No.", SalesUOM, BaseQtyPerSalesUOM);
            Item.Validate("Sales Unit of Measure", SalesUOM);
        end;

        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Modify(true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CurrencyCode: Code[20]; Date: Date)
    begin
        WorkDate := Date;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure InsertAndTestSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; VarCode: Code[20]; ExpectedUnitPrice: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        if (UOMCode <> '') and (UOMCode <> SalesLine."Unit of Measure Code") then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Validate("Variant Code", VarCode);
        SalesLine.Modify(true);

        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Unit Price"), SalesLine."Unit Price", ExpectedUnitPrice);
    end;

    local procedure EditAndTestSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal; LocCode: Code[20]; VarCode: Code[20]; UOMCode: Code[20]; ExpectedUnitPrice: Decimal)
    begin
        if ItemNo <> SalesLine."No." then
            SalesLine.Validate("No.", ItemNo);
        if Qty <> SalesLine.Quantity then
            SalesLine.Validate(Quantity, Qty);
        if VarCode <> SalesLine."Variant Code" then
            SalesLine.Validate("Variant Code", VarCode);
        if LocCode <> SalesLine."Location Code" then
            SalesLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> SalesLine."Unit of Measure Code") then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Modify(true);

        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Unit Price"), SalesLine."Unit Price", ExpectedUnitPrice);

        SalesLine.Next();
    end;

    local procedure UpdateQtyToShipAndInvoice(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInv: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInv);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure InsertAndTestItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; PostDate: Date; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; ExpectedUnitAmount: Decimal)
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Line No." += 10000;
        ItemJnlLine.Validate("Posting Date", PostDate);
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Insert(true);

        TestNumVal('', ItemJnlLine."Line No.", ItemJnlLine.FieldName("Unit Amount"), ItemJnlLine."Unit Amount", ExpectedUnitAmount);
    end;

    local procedure TestNumVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Decimal; ExpectedValue: Decimal)
    begin
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
#if CLEAN25
    local procedure GetSalesPrice(var PriceListLine: Record "Price List Line"; "Item No.": code[20]; "Sales Type": Option; "Sales Code": Code[20]; "Starting Date": Date; "Currency Code": Code[10]; "Variant Code": Code[10]; "Unit of Measure Code": Code[10]; "Minimum Quantity": Decimal): Boolean;
    begin
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", "Item No.");
        PriceListLine.SetRange("Source Type", "Sales Type");
        PriceListLine.SetRange("Source No.", "Sales Code");
        PriceListLine.SetRange("Starting Date", "Starting Date");
        PriceListLine.SetRange("Currency Code", "Currency Code");
        PriceListLine.SetRange("Variant Code", "Variant Code");
        PriceListLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        PriceListLine.SetRange("Minimum Quantity", "Minimum Quantity");
        exit(PriceListLine.FindFirst())
    end;
#endif
}
