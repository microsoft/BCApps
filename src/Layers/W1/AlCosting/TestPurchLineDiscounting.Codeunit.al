codeunit 103529 "Test - Purch. Line Discounting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103529);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        Test1();
        Test2();
        Test3();
        Test4();
        Test6();
        Test8();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        ReleasePurchDoc: Codeunit "Release Purchase Document";
#if not CLEAN25
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif
        CurrTest: Text[30];
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Vend: Record Vendor;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        GLUtil.SetAddCurr('USD', 100, 64.8824, 0.01, 0.001);

        InsertItem('A', 'PCS', 22.22, 'PCS', 1, false);
        InsertItem('B', 'PCS', 333.33, 'PCS', 1, true);
        InsertItem('C', 'PCS', 4444.44, 'BOX', 3, false);
        INVTUtil.InsertItemVariant('C', 'VAR');
        InsertItem('D', 'PCS', 4444.44, 'BOX', 3, false);
        INVTUtil.InsertItemVariant('D', 'VAR');

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

        PPUtil.InsertPurchLineDisc('10000', 'C', 0D, 0D, 0, '', '', '', 0.2);
        PPUtil.InsertPurchLineDisc('10000', 'C', 20020301D, 20020501D, 0, '', '', '', 0.4);
        PPUtil.InsertPurchLineDisc('10000', 'C', 20020401D, 20020401D, 0, '', '', '', 0.6);
        PPUtil.InsertPurchLineDisc('10000', 'C', 20020601D, 0D, 0, '', '', '', 0.8);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, 'BOX', '', 0.2);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, 'BOX', '', 0.4);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, 'BOX', '', 0.6);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020601D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, 'BOX', '', 0.8);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, 'BOX', '', 0);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'P.2';

        PPUtil.InsertPurchLineDisc('20000', 'A', 0D, 0D, 5, '', '', '', 2);
        PPUtil.InsertPurchLineDisc('20000', 'A', 0D, 0D, 10, '', '', '', 4);
        PPUtil.InsertPurchLineDisc('20000', 'A', 20010101D, 20010101D, 5, '', '', '', 3.33);
        PPUtil.InsertPurchLineDisc('20000', 'A', 20020401D, 20020401D, 0, '', '', '', 8);
        PPUtil.InsertPurchLineDisc('20000', 'A', 20020401D, 20020401D, 5, '', '', '', 10);
        PPUtil.InsertPurchLineDisc('20000', 'A', 20020401D, 20020401D, 10, '', '', '', 12);
        PPUtil.InsertPurchLineDisc('20000', 'B', 0D, 0D, 0, 'USD', '', '', 3);
        PPUtil.InsertPurchLineDisc('20000', 'B', 0D, 0D, 100, 'USD', '', '', 6);
        PPUtil.InsertPurchLineDisc('20000', 'B', 20020401D, 20020401D, 0, 'USD', '', '', 9);
        PPUtil.InsertPurchLineDisc('20000', 'B', 20020401D, 20020401D, 5, 'USD', '', '', 12);
        PPUtil.InsertPurchLineDisc('20000', 'B', 20020401D, 20020401D, 10, 'USD', '', '', 15);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 0, '', 'BOX', '', 1.25);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 0, 'USD', 'BOX', '', 2.5);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 3.75);
        PPUtil.InsertPurchLineDisc('20000', 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 3.5);
        PPUtil.InsertPurchLineDisc('20000', 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 6.25);
        PPUtil.InsertPurchLineDisc('20000', 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 7.5);
        PPUtil.InsertPurchLineDisc('20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 8.75);
        PPUtil.InsertPurchLineDisc('20000', 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 10);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', 2);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', 4);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 3, 'PCS', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 3, 'BOX', '', 1.25);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', 3.75);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', 8);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', 12);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', 3.5);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', 3.75);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20010101D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', 3.33);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', 4);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', 'USD', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', 2);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', 4);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 2, '', '', 3);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 100, '', '', 6);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 2, 'PCS', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', 2.5);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', 2.5);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', 'USD', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', 8);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', 12);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 2, '', '', 9);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 100, '', '', 15);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 3, 'PCS', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 3, 'BOX', '', 6.25);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', 8.75);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 10, 'BOX', 'VAR', 10);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 9, 'BOX', 'VAR', 7.5);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        PurchHeader: array[5] of Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
        FromPurchLineDisc: Record "Purchase Line Discount";
#else
        PriceListLine: Record "Price List Line";
        FromPriceListLine: Record "Price List Line";
#endif
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        LineDisc: array[18] of Decimal;
        i: Integer;
        FromPurchInvNo: Code[20];
        FromPurchCrMemoNo: Code[20];
    begin
        CurrTest := 'P.3';
#if not CLEAN25
        FromPurchLineDisc.SetRange("Vendor No.", '20000');
        FromPurchLineDisc.Find('-');
        repeat
            PPUtil.InsertPurchLineDisc(
              '30000', FromPurchLineDisc."Item No.", FromPurchLineDisc."Starting Date", FromPurchLineDisc."Ending Date",
              FromPurchLineDisc."Minimum Quantity", FromPurchLineDisc."Currency Code", FromPurchLineDisc."Unit of Measure Code", FromPurchLineDisc."Variant Code", FromPurchLineDisc."Line Discount %");
        until FromPurchLineDisc.Next() = 0;
#else
        FromPriceListLine.SetRange("Source No.", '20000');
        FromPriceListLine.Find('-');
        repeat
            PPUtil.InsertPurchLineDisc(
              '30000', FromPriceListLine."Asset No.", FromPriceListLine."Starting Date", FromPriceListLine."Ending Date",
              FromPriceListLine."Minimum Quantity", FromPriceListLine."Currency Code", FromPriceListLine."Unit of Measure Code", FromPriceListLine."Variant Code", FromPriceListLine."Line Discount %");
        until FromPriceListLine.Next() = 0;
#endif

        for i := 1 to 5 do
            InsertPurchHeader(PurchHeader[i], PurchLine, "Purchase Document Type".FromInteger(i), '30000', '', 20020301D);

        LineDisc[1] := 0;
        LineDisc[2] := 2;
        LineDisc[3] := 4;
        LineDisc[4] := 0;
        LineDisc[5] := 1.25;
        LineDisc[6] := 3.75;
        LineDisc[7] := 0;
        LineDisc[8] := 2;
        LineDisc[9] := 4;
        LineDisc[10] := 0;
        LineDisc[11] := 1.25;
        LineDisc[12] := 3.75;
        LineDisc[13] := 2;
        LineDisc[14] := 4.25;
        LineDisc[15] := 7.5;
        LineDisc[16] := 1.25;
        LineDisc[17] := 3.75;
        LineDisc[18] := 3.5;

        for i := 1 to 5 do begin
            Clear(PurchLine);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 2, '', '', LineDisc[1]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', '', LineDisc[2]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 10, '', '', LineDisc[3]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 3, 'PCS', '', LineDisc[4]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 3, 'BOX', '', LineDisc[5]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[6]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -2, '', '', LineDisc[7]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -5, '', '', LineDisc[8]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', -10, '', '', LineDisc[9]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -3, 'PCS', '', LineDisc[10]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -3, 'BOX', '', LineDisc[11]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', -100, 'BOX', '', LineDisc[12]);
        end;

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader[PurchLine."Document Type"::Order.AsInteger()]."No.");
        PurchLine.Find('-');
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 5, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 5, 0);
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
        UpdateQtyToRcvAndInv(PurchLine, 3, 3);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, 0, 0);
        UpdateQtyToRcvAndInv(PurchLine, -1, -1);
        UpdateQtyToRcvAndInv(PurchLine, -3, -3);

        PPUtil.PostPurchase(PurchHeader[PurchLine."Document Type"::Order.AsInteger()], true, true);

        FromPurchInvNo := GLUtil.GetLastDocNo(PurchSetup."Posted Invoice Nos.");

#if not CLEAN25
        GetPurchLineDisc(PurchLineDisc, '30000', 'A', 0D, 5, '', '', '');
        UpdatePuchLineDisc(PurchLineDisc, '30000', 'A', 0D, 0D, 3, '', '', '', 2);

        GetPurchLineDisc(PurchLineDisc, '30000', 'A', 0D, 10, '', '', '');
        UpdatePuchLineDisc(PurchLineDisc, '30000', 'A', 0D, 0D, 10, '', '', '', 4.25);

        PPUtil.InsertPurchLineDisc('30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        GetPurchLineDisc(PurchLineDisc, '30000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePuchLineDisc(PurchLineDisc, '30000', 'D', 0D, 0D, 100, '', '', '', 3.75);

        GetPurchLineDisc(PurchLineDisc, '30000', 'D', 20020401D, 5, 'USD', 'BOX', '');
        PurchLineDisc.Delete(true);
        CopyAllDiscountsToPriceListLines();
#else
        GetPurchLineDisc(PriceListLine, '30000', 'A', 0D, 5, '', '', '');
        UpdatePuchLineDisc(PriceListLine, '30000', 'A', 0D, 0D, 3, '', '', '', 2);

        GetPurchLineDisc(PriceListLine, '30000', 'A', 0D, 10, '', '', '');
        UpdatePuchLineDisc(PriceListLine, '30000', 'A', 0D, 0D, 10, '', '', '', 4.25);

        PPUtil.InsertPurchLineDisc('30000', 'A', 0D, 0D, 20, '', '', '', 7.5);

        GetPurchLineDisc(PriceListLine, '30000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePuchLineDisc(PriceListLine, '30000', 'D', 0D, 0D, 100, '', '', '', 3.75);

        GetPurchLineDisc(PriceListLine, '30000', 'D', 20020401D, 5, 'USD', 'BOX', '');
        PPUtil.AllowEditingActivePrice(true);
        PriceListLine.Delete(true);
        PPUtil.AllowEditingActivePrice(false);
#endif

        for i := 1 to 5 do begin
            PurchHeader[i].Find();
            PurchHeader[i].SetHideValidationDialog(true);
            ReleasePurchDoc.Reopen(PurchHeader[i]);
            PurchLine.SetRange("Document Type", PurchHeader[i]."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader[i]."No.");
            PurchLine.Find('+');
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 5, '', '', LineDisc[13]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 10, '', '', LineDisc[14]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'A', 20, '', '', LineDisc[15]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 5, 'BOX', '', LineDisc[16]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[17]);
            InsertAndTestPurchLine(PurchHeader[i], PurchLine, PurchLine.Type::Item, 'D', 5, 'BOX', '', LineDisc[11]);

            if i = PurchLine."Document Type"::"Blanket Order".AsInteger() then begin
                CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchHeader[i]);
                PurchHeader[i].Get(PurchHeader[i]."Document Type"::Order, GLUtil.GetLastDocNo(PurchSetup."Order Nos."));
            end;
            PPUtil.PostPurchase(PurchHeader[i], true, true);
            if i = PurchLine."Document Type"::"Credit Memo".AsInteger() then
                FromPurchCrMemoNo := GLUtil.GetLastDocNo(PurchSetup."Posted Credit Memo Nos.");
        end;

        PurchInvHeader.SetRange("No.", FromPurchInvNo, GLUtil.GetLastDocNo(PurchSetup."Posted Invoice Nos."));
        PurchInvHeader.FindSet();
        repeat
            PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            PurchInvLine.SetRange("Line No.", 10000, 170000);
            PurchInvLine.FindSet();
            repeat
                TestNumVal(
                  PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Line Discount %"),
                  PurchInvLine."Line Discount %", LineDisc[PurchInvLine."Line No." / 10000]);
            until PurchInvLine.Next() = 0;
        until PurchInvHeader.Next() = 0;

        PurchCrMemoHeader.SetRange("No.", FromPurchCrMemoNo, GLUtil.GetLastDocNo(PurchSetup."Posted Credit Memo Nos."));
        PurchCrMemoHeader.FindSet();
        repeat
            PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
            PurchCrMemoLine.SetRange("Line No.", 10000, 170000);
            PurchCrMemoLine.Find('-');
            repeat
                TestNumVal(
                  PurchCrMemoHeader.TableName, PurchCrMemoLine."Document No.", PurchCrMemoLine.FieldName("Line Discount %"),
                  PurchCrMemoLine."Line Discount %", LineDisc[PurchCrMemoLine."Line No." / 10000]);
            until PurchCrMemoLine.Next() = 0;
        until PurchCrMemoHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        FromPurchInvNo: Code[20];
        LineDisc: array[2] of Decimal;
    begin
        CurrTest := 'P.4';

        LineDisc[1] := 2;
        LineDisc[2] := 3.75;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', LineDisc[1]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[2]);

#if not CLEAN25
        GetPurchLineDisc(PurchLineDisc, '20000', 'A', 0D, 5, '', '', '');
        UpdatePuchLineDisc(PurchLineDisc, '20000', 'A', 0D, 0D, 5, '', '', '', 2.5);

        GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePuchLineDisc(PurchLineDisc, '20000', 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);
        CopyAllDiscountsToPriceListLines();
#else
        GetPurchLineDisc(PriceListLine, '20000', 'A', 0D, 5, '', '', '');
        UpdatePuchLineDisc(PriceListLine, '20000', 'A', 0D, 0D, 5, '', '', '', 2.5);

        GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '');
        UpdatePuchLineDisc(PriceListLine, '20000', 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);
#endif

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);
        UpdateQtyToRcvAndInv(PurchLine, 1, 0);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchLine.Find('-');
        UpdateQtyToRcvAndInv(PurchLine, 0, 1);
        UpdateQtyToRcvAndInv(PurchLine, 0, 1);

        PPUtil.PostPurchase(PurchHeader, false, true);

        FromPurchInvNo := GLUtil.GetLastDocNo(PurchSetup."Posted Invoice Nos.");

        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvHeader.SetRange("No.", FromPurchInvNo, GLUtil.GetLastDocNo(PurchSetup."Posted Invoice Nos."));
        PurchInvHeader.Find('-');
        repeat
            PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            PurchInvLine.Find('-');
            repeat
                TestNumVal(
                  PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Line Discount %"),
                  PurchInvLine."Line Discount %", LineDisc[PurchInvLine."Line No." / 10000]);
            until PurchInvLine.Next() = 0;
        until PurchInvHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        GetReceipt: Codeunit "Purch.-Get Receipt";
        LineDisc: array[5] of Decimal;
        i: Integer;
    begin
        CurrTest := 'P.6';

        LineDisc[1] := 8;
        LineDisc[2] := 10;
        LineDisc[3] := 12;
        LineDisc[4] := 3.5;
        LineDisc[5] := 3.95;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, '', '', LineDisc[1]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 5, '', '', LineDisc[2]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 10, '', '', LineDisc[3]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 90, 'BOX', '', LineDisc[4]);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[5]);

        PPUtil.PostPurchase(PurchHeader, true, false);

        LineDisc[3] := 25;

        PurchHeader.Find();
        ReleasePurchDoc.Reopen(PurchHeader);
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 30000);
        PurchLine.Validate("Line Discount %", LineDisc[3]);
        PurchLine.Modify(true);

#if not CLEAN25
        GetPurchLineDisc(PurchLineDisc, '20000', 'A', 20020401D, 0, '', '', '');
        UpdatePuchLineDisc(PurchLineDisc, '20000', 'A', 20020401D, 20020401D, 0, '', '', '', 8.5);
        CopyAllDiscountsToPriceListLines();
#else
        GetPurchLineDisc(PriceListLine, '20000', 'A', 20020401D, 0, '', '', '');
        UpdatePuchLineDisc(PriceListLine, '20000', 'A', 20020401D, 20020401D, 0, '', '', '', 8.5);
#endif

        PurchHeader.Find();
        PurchRcptLine.SetRange("Document No.", PurchHeader."Last Receiving No.");
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '20000', '', 20020401D);
        GetReceipt.SetPurchHeader(PurchHeader);
        GetReceipt.CreateInvLines(PurchRcptLine);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvLine.SetRange("Document No.", GLUtil.GetLastDocNo(PurchSetup."Posted Invoice Nos."));
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.Find('-');
        i := 1;
        repeat
            TestNumVal(
              PurchInvHeader.TableName, PurchInvLine."Document No.", PurchInvLine.FieldName("Line Discount %"),
              PurchInvLine."Line Discount %", LineDisc[i]);
            i += 1;
        until PurchInvLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        PurchLineDisc: Record "Purchase Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
    begin
        CurrTest := 'P.8';

#if not CLEAN25
        if GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 1, '', '', 'VAR') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 1, '', '', 'VAR', 20.25);

        if GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 1, '', 'BOX', 'VAR') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 20.75);

        if GetPurchLineDisc(PurchLineDisc, '20000', 'A', 0D, 5, '', '', '') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'A', 0D, 0D, 5, '', '', '', 2.5);

        if GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 0, '', 'BOX', '') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 0, '', 'BOX', '', 1.25);

        if GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 5, '', 'BOX', '') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 5, '', 'BOX', '', 3.8);

        if GetPurchLineDisc(PurchLineDisc, '20000', 'D', 0D, 100, '', 'BOX', '') then
            PurchLineDisc.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);
#else
        PPUtil.AllowEditingActivePrice(true);
        if GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 1, '', '', 'VAR') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 1, '', '', 'VAR', 20.25);

        if GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 1, '', 'BOX', 'VAR') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 20.75);

        if GetPurchLineDisc(PriceListLine, '20000', 'A', 0D, 5, '', '', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'A', 0D, 0D, 5, '', '', '', 2.5);

        if GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 0, '', 'BOX', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 0, '', 'BOX', '', 1.25);

        if GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 5, '', 'BOX', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 5, '', 'BOX', '', 3.8);

        if GetPurchLineDisc(PriceListLine, '20000', 'D', 0D, 100, '', 'BOX', '') then
            PriceListLine.Delete(true);
        PPUtil.InsertPurchLineDisc('20000', 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);
        PPUtil.AllowEditingActivePrice(false);
#endif

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 'PCS', '', 0);
        InsertAndTestPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'D', 1, 'BOX', '', 1.25);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 5, '', '', 'PCS', 2.5);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'BOX', 3.95);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'A', 5, 'BLUE', '', 'PCS', 2.5);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'PCS', 0);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', '', 'BOX', 3.8);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', 'VAR', 'PCS', 20.25);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', 'VAR', 'BOX', 20.75);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', 'VAR', 'BOX', 20.75);

        PurchLine.Find('-');
        EditAndTestPurchLine(PurchLine, 'D', 5, '', '', 'BOX', 3.8);
        EditAndTestPurchLine(PurchLine, 'D', 100, '', '', 'BOX', 3.95);
    end;

    [Scope('OnPrem')]
    procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; LastDirCost: Decimal; PurchUOM: Code[10]; BaseQtyPerPurchUOM: Decimal; AllowInvDisc: Boolean)
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

        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Last Direct Cost", LastDirCost);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Modify(true);
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

    [Scope('OnPrem')]
    procedure InsertAndTestPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; VarCode: Code[20]; ExpectedLineDisc: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate(Quantity, Qty);
        if UOMCode <> '' then
            PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Validate("Variant Code", VarCode);
        PurchLine.Modify(true);

        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Line Discount %"), PurchLine."Line Discount %", ExpectedLineDisc);
    end;

    local procedure UpdateQtyToRcvAndInv(var PurchLine: Record "Purchase Line"; QtyToRcv: Decimal; QtyToInv: Decimal)
    begin
        PurchLine.Validate("Qty. to Receive", QtyToRcv);
        PurchLine.Validate("Qty. to Invoice", QtyToInv);
        PurchLine.Modify(true);
        PurchLine.Next();
    end;

    local procedure EditAndTestPurchLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal; LocCode: Code[20]; VarCode: Code[20]; UOMCode: Code[20]; ExpectedValue: Decimal)
    begin
        if ItemNo <> PurchLine."No." then
            PurchLine.Validate("No.", ItemNo);
        if Qty <> PurchLine.Quantity then
            PurchLine.Validate(Quantity, Qty);
        if VarCode <> PurchLine."Variant Code" then
            PurchLine.Validate("Variant Code", VarCode);
        if LocCode <> PurchLine."Location Code" then
            PurchLine.Validate("Location Code", LocCode);
        if UOMCode <> PurchLine."Unit of Measure Code" then
            PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Modify(true);

        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Line Discount %"), PurchLine."Line Discount %", ExpectedValue);

        PurchLine.Next();
    end;

    [Scope('OnPrem')]
    procedure GetPurchLineDisc(var PriceListLine: Record "Price List Line"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        PriceListLine.Reset();
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", VarCode);
        PriceListLine.SetRange("Source Type", "Price Source Type"::Vendor);
        PriceListLine.SetRange("Source No.", VendorNo);
        PriceListLine.SetRange("Starting Date", StartDate);
        PriceListLine.SetRange("Currency Code", CurrencyCode);
        PriceListLine.SetRange("Unit of Measure Code", UOMCode);
        PriceListLine.SetRange("Minimum Quantity", MinQty);
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Discount);
        exit(PriceListLine.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure UpdatePuchLineDisc(var PriceListLine: Record "Price List Line"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    begin
        PriceListLine.Status := "Price Status"::Draft;
        PriceListLine.Validate("Asset No.", ItemNo);
        PriceListLine.Validate("Variant Code", VarCode);
        PriceListLine.Validate("Source No.", VendorNo);
        PriceListLine.Validate("Starting Date", StartDate);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Unit of Measure Code", UOMCode);
        PriceListLine.Validate("Minimum Quantity", MinQty);
        if EndDate <> PriceListLine."Ending Date" then
            PriceListLine.Validate("Ending Date", EndDate);
        if LineDiscPct <> PriceListLine."Line Discount %" then
            PriceListLine.Validate("Line Discount %", LineDiscPct);
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

#if not CLEAN25
    [Scope('OnPrem')]
    procedure GetPurchLineDisc(var PurchLineDisc: Record "Purchase Line Discount"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]): Boolean
    begin
        exit(
          PurchLineDisc.Get(
            ItemNo,
            VendorNo,
            StartDate,
            CurrencyCode,
            VarCode,
            UOMCode,
            MinQty));
    end;

    [Scope('OnPrem')]
    procedure UpdatePuchLineDisc(var PurchLineDisc: Record "Purchase Line Discount"; VendorNo: Code[20]; ItemNo: Code[20]; StartDate: Date; EndDate: Date; MinQty: Decimal; CurrencyCode: Code[10]; UOMCode: Code[20]; VarCode: Code[20]; LineDiscPct: Decimal)
    begin
        PurchLineDisc.Rename(
            ItemNo,
            VendorNo,
            StartDate,
            CurrencyCode,
            VarCode,
            UOMCode,
            MinQty);
        if EndDate <> PurchLineDisc."Ending Date" then
            PurchLineDisc.Validate("Ending Date", EndDate);
        if LineDiscPct <> PurchLineDisc."Line Discount %" then
            PurchLineDisc.Validate("Line Discount %", LineDiscPct);
        PurchLineDisc.Modify(true)
    end;
#endif

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

#if not CLEAN25
    local procedure CopyAllDiscountsToPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
    end;
#endif
}

