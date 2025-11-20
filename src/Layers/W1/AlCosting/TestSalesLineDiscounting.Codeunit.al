codeunit 103527 "Test - Sales Line Discounting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103527);
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
        Test11();
        Test12();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
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

        PurchSetup.Get();

        INVTUtil.InsertItemDiscGrp('AGRP');
        INVTUtil.InsertItemDiscGrp('BGRP');
        INVTUtil.InsertItemDiscGrp('CGRP');
        INVTUtil.InsertItemDiscGrp('DGRP');

        InsertItem('A', 'PCS', 22.22, 10, 'PCS', 1, 'AGRP', false);
        InsertItem('B', 'PCS', 333.33, 0, 'PCS', 1, 'BGRP', true);
        InsertItem('C', 'PCS', 4444.44, 0, 'BOX', 3, 'CGRP', false);
        INVTUtil.InsertItemVariant('C', 'VAR');
        InsertItem('D', 'PCS', 4444.44, 0, 'BOX', 3, 'DGRP', true);
        INVTUtil.InsertItemVariant('D', 'VAR');

        SRUtil.InsertCustPriceGrp('CPG00', false, '', false, false);
        SRUtil.InsertCustPriceGrp('CPG01', false, '', false, true);
        SRUtil.InsertCustPriceGrp('CPG10', false, '', true, false);
        SRUtil.InsertCustPriceGrp('CPG11', false, '', true, true);

        SRUtil.InsertCustDiscGrp('CDG1');

        Cust.Get('10000');
        Cust.Validate("Customer Disc. Group", 'CDG1');
        Cust.Modify(true);
    end;

#if CLEAN25
    local procedure AllowEditingActivePrice(Allow: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Editing Active Price" := Allow;
        SalesReceivablesSetup.Modify();
    end;
#endif

    [Scope('OnPrem')]
    procedure Test1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
#endif
    begin
        CurrTest := 'S.1';
#if not CLEAN25
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '10000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 0D, 0D, 0, '', '', '', 0.2);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '10000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020301D, 20020501D, 0, '', '', '', 0.4);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '10000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020401D, 20020401D, 0, '', '', '', 0.6);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '10000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020601D, 0D, 0, '', '', '', 0.8);

        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"Customer Disc. Group", 'CDG1', SalesLineDisc.Type::Item, 'B', 0D, 0D, 0, '', '', '', 1.2);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"Customer Disc. Group", 'CDG1', SalesLineDisc.Type::Item, 'B', 20020301D, 20020501D, 0, '', '', '', 1.4);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"Customer Disc. Group", 'CDG1', SalesLineDisc.Type::Item, 'B', 20020401D, 20020401D, 0, '', '', '', 1.6);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"Customer Disc. Group", 'CDG1', SalesLineDisc.Type::Item, 'B', 20020601D, 0D, 0, '', '', '', 1.8);

        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::"Item Disc. Group", 'CGRP', 0D, 0D, 0, '', '', '', 12);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::"Item Disc. Group", 'CGRP', 20020301D, 20020501D, 0, '', '', '', 14);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::"Item Disc. Group", 'CGRP', 20020401D, 20020401D, 0, '', '', '', 16);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::"Item Disc. Group", 'CGRP', 20020601D, 0D, 0, '', '', '', 18);
#else
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '10000', "Price Asset Type"::"Item Discount Group", 'AGRP', 0D, 0D, 0, '', '', '', 0.2);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '10000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020301D, 20020501D, 0, '', '', '', 0.4);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '10000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020401D, 20020401D, 0, '', '', '', 0.6);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '10000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020601D, 0D, 0, '', '', '', 0.8);

        SRUtil.InsertSalesLineDisc("Price Source Type"::"Customer Disc. Group".AsInteger(), 'CDG1', "Price Asset Type"::Item, 'B', 0D, 0D, 0, '', '', '', 1.2);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"Customer Disc. Group".AsInteger(), 'CDG1', "Price Asset Type"::Item, 'B', 20020301D, 20020501D, 0, '', '', '', 1.4);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"Customer Disc. Group".AsInteger(), 'CDG1', "Price Asset Type"::Item, 'B', 20020401D, 20020401D, 0, '', '', '', 1.6);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"Customer Disc. Group".AsInteger(), 'CDG1', "Price Asset Type"::Item, 'B', 20020601D, 0D, 0, '', '', '', 1.8);

        SRUtil.InsertSalesLineDisc("Price Source Type"::"All Customers".AsInteger(), '', "Price Asset Type"::"Item Discount Group", 'CGRP', 0D, 0D, 0, '', '', '', 12);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"All Customers".AsInteger(), '', "Price Asset Type"::"Item Discount Group", 'CGRP', 20020301D, 20020501D, 0, '', '', '', 14);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"All Customers".AsInteger(), '', "Price Asset Type"::"Item Discount Group", 'CGRP', 20020401D, 20020401D, 0, '', '', '', 16);
        SRUtil.InsertSalesLineDisc("Price Source Type"::"All Customers".AsInteger(), '', "Price Asset Type"::"Item Discount Group", 'CGRP', 20020601D, 0D, 0, '', '', '', 18);
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020201D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0.2);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 1.2);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 12);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0.4);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 1.4);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 14);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0.6);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 1.6);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 16);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '', 20020601D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0.8);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 1.8);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 18);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'BOX', '', 16);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        Cust: Record Customer;
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
#endif
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CurrTest := 'S.2';

        Cust.Get('20000');
        Cust.Validate("Allow Line Disc.", true);
        Cust.Modify(true);
#if not CLEAN25
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 0D, 0D, 5, '', '', '', 2);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 0D, 0D, 10, '', '', '', 4);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20010101D, 20010101D, 5, '', '', '', 3.33);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020401D, 20020401D, 0, '', '', '', 8);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020401D, 20020401D, 5, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 20020401D, 20020401D, 10, '', '', '', 12);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'B', 0D, 0D, 0, 'USD', '', '', 3);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'B', 0D, 0D, 100, 'USD', '', '', 6);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'B', 20020401D, 20020401D, 0, 'USD', '', '', 9);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'B', 20020401D, 20020401D, 5, 'USD', '', '', 12);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'B', 20020401D, 20020401D, 10, 'USD', '', '', 15);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 0, '', 'BOX', '', 1.25);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 0, 'USD', 'BOX', '', 2.5);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 100, '', 'BOX', '', 3.75);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 3.5);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 6.25);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 7.5);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 8.75);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 10);
#else
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 0D, 0D, 5, '', '', '', 2);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 0D, 0D, 10, '', '', '', 4);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20010101D, 20010101D, 5, '', '', '', 3.33);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020401D, 20020401D, 0, '', '', '', 8);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020401D, 20020401D, 5, '', '', '', 10);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::"Item Discount Group", 'AGRP', 20020401D, 20020401D, 10, '', '', '', 12);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'B', 0D, 0D, 0, 'USD', '', '', 3);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'B', 0D, 0D, 100, 'USD', '', '', 6);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'B', 20020401D, 20020401D, 0, 'USD', '', '', 9);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'B', 20020401D, 20020401D, 5, 'USD', '', '', 12);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'B', 20020401D, 20020401D, 10, 'USD', '', '', 15);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 0D, 0D, 0, '', 'BOX', '', 1.25);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 0D, 0D, 0, 'USD', 'BOX', '', 2.5);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 0D, 0D, 100, '', 'BOX', '', 3.75);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 20020401D, 20020401D, 0, '', 'BOX', '', 3.5);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 20020401D, 20020401D, 0, 'USD', 'BOX', '', 6.25);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 20020401D, 20020401D, 5, 'USD', 'BOX', '', 7.5);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', '', 8.75);
        SRUtil.InsertSalesLineDisc("Price Source Type"::Customer.AsInteger(), '20000', "Price Asset Type"::Item, 'D', 20020401D, 20020401D, 10, 'USD', 'BOX', 'VAR', 10);
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        SalesHeader2 := SalesHeader;
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 2);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 4);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'BOX', '', 1.25);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 3.75);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 8);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 12);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 90, 'BOX', '', 3.5);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 3.75);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20010101D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 3.33);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 4);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', 'USD', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 2);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 4);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 3);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 100, '', '', 6);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'BOX', '', 2.5);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 2.5);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', 'USD', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 8);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 10);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 12);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 9);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 100, '', '', 15);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 3, 'BOX', '', 6.25);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', 8.75);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 10, 'BOX', 'VAR', 10);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 9, 'BOX', 'VAR', 7.5);

        Cust.Get('20000');
        Cust.Validate("Allow Line Disc.", false);
        Cust.Modify(true);

        WorkDate := 20020301D;

        SalesHeader2.SetHideValidationDialog(true);
        SalesHeader2.Validate("Sell-to Customer No.", '10000');
        SalesHeader2.Validate("Sell-to Customer No.", '20000');
        SalesLine.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader2."No.");
        SalesLine.Find('-');
        repeat
            SalesLine.Validate("No.");
            TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Line Discount %"), SalesLine."Line Discount %", 0);
        until SalesLine.Next() = 0;

        Cust.Get('20000');
        Cust.Validate("Allow Line Disc.", true);
        Cust.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        SalesHeader: array[5] of Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
        FromSalesLineDisc: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        LineDisc: array[18] of Decimal;
        i: Integer;
        FromSalesInvNo: Code[20];
        FromSalesCrMemoNo: Code[20];
    begin
        CurrTest := 'S.3';
#if not CLEAN25
        FromSalesLineDisc.SetRange("Sales Type", FromSalesLineDisc."Sales Type"::Customer);
        FromSalesLineDisc.SetRange("Sales Code", '20000');
        FromSalesLineDisc.Find('-');
        repeat
            SRUtil.InsertSalesLineDisc(
              FromSalesLineDisc."Sales Type"::Customer, '30000', FromSalesLineDisc.Type, FromSalesLineDisc.Code, FromSalesLineDisc."Starting Date", FromSalesLineDisc."Ending Date",
              FromSalesLineDisc."Minimum Quantity", FromSalesLineDisc."Currency Code", FromSalesLineDisc."Unit of Measure Code", FromSalesLineDisc."Variant Code", FromSalesLineDisc."Line Discount %");
        until FromSalesLineDisc.Next() = 0;
#else
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.SetRange("Source No.", '20000');
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Discount);
        PriceListLine.Find('-');
        repeat
            SRUtil.InsertSalesLineDisc(
              PriceListLine."Source Type"::Customer.AsInteger(), '30000', PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Starting Date", PriceListLine."Ending Date",
              PriceListLine."Minimum Quantity", PriceListLine."Currency Code", PriceListLine."Unit of Measure Code", PriceListLine."Variant Code", PriceListLine."Line Discount %");
        until PriceListLine.Next() = 0;
#endif

        for i := 1 to 5 do
            InsertSalesHeader(SalesHeader[i], SalesLine, "Sales Document Type".FromInteger(i), '30000', '', 20020301D);

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
            Clear(SalesLine);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 2, '', '', LineDisc[1]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 5, '', '', LineDisc[2]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 10, '', '', LineDisc[3]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 2, 'PCS', '', LineDisc[4]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 2, 'BOX', '', LineDisc[5]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[6]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -2, '', '', LineDisc[7]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -5, '', '', LineDisc[8]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', -10, '', '', LineDisc[9]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -2, 'PCS', '', LineDisc[10]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -2, 'BOX', '', LineDisc[11]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', -100, 'BOX', '', LineDisc[12]);
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
        SalesLineDisc.Get(SalesLineDisc.Type::"Item Disc. Group", 'AGRP', SalesLineDisc."Sales Type"::Customer, '30000', 0D, '', '', '', 5);
        SalesLineDisc.Rename(SalesLineDisc.Type::"Item Disc. Group", 'AGRP', SalesLineDisc."Sales Type"::Customer, '30000', 0D, '', '', '', 3);

        SalesLineDisc.Get(SalesLineDisc.Type::"Item Disc. Group", 'AGRP', SalesLineDisc."Sales Type"::Customer, '30000', 0D, '', '', '', 10);
        SalesLineDisc.Validate("Line Discount %", 4.25);
        SalesLineDisc.Modify(true);

        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '30000', SalesLineDisc.Type::"Item Disc. Group", 'AGRP', 0D, 0D, 20, '', '', '', 7.5);

        SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '30000', 0D, '', '', 'BOX', 100);
        SalesLineDisc.Rename(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '30000', 0D, '', '', '', 100);

        SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '30000', 20020401D, 'USD', '', 'BOX', 5);
        SalesLineDisc.Delete();

        CopyAllDiscountsToPriceListLines();
#else
        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::"Item Discount Group".AsInteger(), 'AGRP', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', '', 5);
        PriceListLine."Minimum Quantity" := 3;
        PriceListLine.Modify(true);

        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::"Item Discount Group".AsInteger(), 'AGRP', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', '', 10);
        PriceListLine."Line Discount %" := 4.25;
        PriceListLine.Modify(true);

        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '30000', PriceListLine."Asset Type"::"Item Discount Group", 'AGRP', 0D, 0D, 20, '', '', '', 7.5);

        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 0D, '', '', 'BOX', 100);
        PriceListLine."Unit of Measure Code" := '';
        PriceListLine.Modify(true);

        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '30000', 20020401D, 'USD', '', 'BOX', 5);
        PriceListLine.Delete();
#endif
        commit();
        for i := 1 to 5 do begin
            SalesHeader[i].Find();
            SalesHeader[i].SetHideValidationDialog(true);
            ReleaseSalesDoc.Reopen(SalesHeader[i]);
            SalesLine.SetRange("Document Type", SalesHeader[i]."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader[i]."No.");
            SalesLine.Find('+');
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 5, '', '', LineDisc[13]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 10, '', '', LineDisc[14]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'A', 20, '', '', LineDisc[15]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 5, 'BOX', '', LineDisc[16]);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[17]);
            if i in [SalesLine."Document Type"::Invoice.AsInteger(), SalesLine."Document Type"::"Credit Memo".AsInteger()] then
                SalesHeader[i].Validate("Posting Date", 20020401D)
            else
                SalesHeader[i].Validate("Order Date", 20020401D);
            SalesHeader[i].Modify(true);
            InsertAndTestSalesLine(SalesHeader[i], SalesLine, SalesLine.Type::Item, 'D', 5, 'BOX', '', LineDisc[18]);
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
                  SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Discount %"),
                  SalesInvLine."Line Discount %", LineDisc[SalesInvLine."Line No." / 10000]);
            until SalesInvLine.Next() = 0;
        until SalesInvHeader.Next() = 0;

        SalesCrMemoHeader.SetRange("No.", FromSalesCrMemoNo, GLUtil.GetLastDocNo(SalesSetup."Posted Credit Memo Nos."));
        SalesCrMemoHeader.Find('-');
        repeat
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
            SalesCrMemoLine.Find('-');
            repeat
                TestNumVal(
                  SalesCrMemoHeader.TableName, SalesCrMemoLine."Document No.", SalesCrMemoLine.FieldName("Line Discount %"),
                  SalesCrMemoLine."Line Discount %", LineDisc[SalesCrMemoLine."Line No." / 10000]);
            until SalesCrMemoLine.Next() = 0;
        until SalesCrMemoHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        FromSalesInvNo: Code[20];
        LineDisc: array[2] of Decimal;
    begin
        CurrTest := 'S.4';

        LineDisc[1] := 2;
        LineDisc[2] := 3.75;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', LineDisc[1]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[2]);
#if not CLEAN25
        SalesLineDisc.Get(SalesLineDisc.Type::"Item Disc. Group", 'AGRP', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', '', 5);
        SalesLineDisc.Validate("Line Discount %", 2.5);
        SalesLineDisc.Modify(true);

        SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 100);
        SalesLineDisc.Validate("Line Discount %", 3.95);
        SalesLineDisc.Modify(true);

        CopyAllDiscountsToPriceListLines();
#else
        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::"Item Discount Group".AsInteger(), 'AGRP', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', '', 5);
        PriceListLine."Line Discount %" := 2.5;
        PriceListLine.Modify(true);

        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 100);
        PriceListLine."Line Discount %" := 3.95;
        PriceListLine.Modify(true);
#endif
        commit();
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
                  SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Discount %"),
                  SalesInvLine."Line Discount %", LineDisc[SalesInvLine."Line No." / 10000]);
            until SalesInvLine.Next() = 0;
        until SalesInvHeader.Next() = 0;
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
        SalesLineDisc: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        LineDisc: array[5] of Decimal;
        i: Integer;
    begin
        CurrTest := 'S.6';

        LineDisc[1] := 8;
        LineDisc[2] := 10;
        LineDisc[3] := 12;
        LineDisc[4] := 3.5;
        LineDisc[5] := 3.95;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', LineDisc[1]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', LineDisc[2]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', LineDisc[3]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 90, 'BOX', '', LineDisc[4]);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 100, 'BOX', '', LineDisc[5]);

        SRUtil.PostSales(SalesHeader, true, false);

        LineDisc[3] := 25;

        SalesHeader.Find();
        ReleaseSalesDoc.Reopen(SalesHeader);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
        SalesLine.Validate("Line Discount %", LineDisc[3]);
        SalesLine.Modify(true);
#if not CLEAN25
        SalesLineDisc.Get(SalesLineDisc.Type::"Item Disc. Group", 'AGRP', SalesLineDisc."Sales Type"::Customer, '20000', 20020401D, '', '', '', 0);
        SalesLineDisc.Validate("Line Discount %", 8.5);
        SalesLineDisc.Modify(true);

        CopyAllDiscountsToPriceListLines();
#else
        GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::"Item Discount Group".AsInteger(), 'AGRP', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 20020401D, '', '', '', 0);
        PriceListLine."Line Discount %" := 8.5;
        PriceListLine.Modify(true);
#endif
        commit();
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
              SalesInvHeader.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Discount %"),
              SalesInvLine."Line Discount %", LineDisc[i]);
            i += 1;
        until SalesInvLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test7()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#endif
        SalesInvLine: Record "Sales Invoice Line";
    begin
        CurrTest := 'S.7';
#if not CLEAN25
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::Customer, '20000', 'A', 0D, 0D, 100, '', '', '', 15.5);
#else
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice("Price Source Type"::Customer, '20000', 'A', 0D, 0D, 100, '', '', '', 15.5);
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, '', '', 2.5);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 100, '', '', 4);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesInvLine.SetRange("Document No.", GLUtil.GetLastDocNo(SalesSetup."Posted Invoice Nos."));
        SalesInvLine.Find('-');
        TestNumVal(
          SalesInvLine.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Amount"),
          SalesInvLine."Line Amount", 97.5);
        SalesInvLine.Next();
        TestNumVal(
          SalesInvLine.TableName, SalesInvLine."Document No.", SalesInvLine.FieldName("Line Amount"),
          SalesInvLine."Line Amount", 1488);
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
    begin
        CurrTest := 'S.8';
#if not CLEAN25
        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', 'VAR', '', 1) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 1, '', '', 'VAR', 20.25);

        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', 'VAR', 'BOX', 1) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 20.75);

        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'A', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', '', 5) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'A', 0D, 0D, 5, '', '', '', 2.5);

        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 0) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 1, '', 'BOX', '', 1.25);

        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 5) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 5, '', 'BOX', '', 3.8);

        if SalesLineDisc.Get(SalesLineDisc.Type::Item, 'D', SalesLineDisc."Sales Type"::Customer, '20000', 0D, '', '', 'BOX', 100) then
            SalesLineDisc.Delete(true);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '20000', SalesLineDisc.Type::Item, 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);

        CopyAllDiscountsToPriceListLines();
#else
        AllowEditingActivePrice(true);
        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', 'VAR', '', 1) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'D', 0D, 0D, 1, '', '', 'VAR', 20.25);

        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', 'VAR', 'BOX', 1) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'D', 0D, 0D, 1, '', 'BOX', 'VAR', 20.75);

        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'A', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', '', 5) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'A', 0D, 0D, 5, '', '', '', 2.5);

        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 0) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'D', 0D, 0D, 1, '', 'BOX', '', 1.25);

        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 5) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'D', 0D, 0D, 5, '', 'BOX', '', 3.8);

        if GetSalesDisc(PriceListLine, PriceListLine."Asset Type"::Item.AsInteger(), 'D', PriceListLine."Source Type"::Customer.AsInteger(), '20000', 0D, '', '', 'BOX', 100) then
            PriceListLine.Delete(true);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '20000', PriceListLine."Asset Type"::Item, 'D', 0D, 0D, 100, '', 'BOX', '', 3.95);
        AllowEditingActivePrice(false);
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, 'PCS', '', 0);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 1, 'BOX', '', 1.25);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'A', 5, '', '', 'PCS', 2.5);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'BOX', 3.95);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'A', 5, 'BLUE', '', 'PCS', 2.5);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'PCS', 0);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', '', 'BOX', 3.8);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', 'VAR', 'PCS', 20.25);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', 'VAR', 'BOX', 20.75);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', 'VAR', 'BOX', 20.75);

        SalesLine.Find('-');
        EditAndTestSalesLine(SalesLine, 'D', 5, '', '', 'BOX', 3.8);
        EditAndTestSalesLine(SalesLine, 'D', 100, '', '', 'BOX', 3.95);
    end;

    [Scope('OnPrem')]
    procedure Test10()
    var
#if not CLEAN25
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        ItemJnlLine: Record "Item Journal Line";
    begin
        CurrTest := 'S.10';
#if not CLEAN25
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'A', 20010101D, 20040101D, 10, '', '', '', 18);

        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::Item, 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::"All Customers", '', SalesLineDisc.Type::Item, 'A', 20010101D, 20040101D, 10, '', '', '', 18);
#else
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'A', 20010101D, 20040101D, 10, '', '', '', 18);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::"All Customers".AsInteger(), '', PriceListLine."Asset Type"::Item, 'A', 0D, 0D, 5, '', '', '', 20);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::"All Customers".AsInteger(), '', PriceListLine."Asset Type"::Item, 'A', 20010101D, 20040101D, 10, '', '', '', 18);
#endif
        commit();
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 2, 22.22);
        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 5, 20);
        InsertAndTestItemJnlLine(ItemJnlLine, 20020401D, ItemJnlLine."Entry Type"::Sale, 'A', 10, 18);
    end;

    [Scope('OnPrem')]
    procedure Test11()
    var
#if not CLEAN25
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustPriceGrp: Record "Customer Price Group";
        InvDiscAmt: array[7] of Decimal;
        AllowInvDisc: array[3] of Boolean;
    begin
        CurrTest := 'S.11';

        SetupCustDisc('40000', false, 10);
        SetupCustDisc('50000', true, 10);

        CustPriceGrp.Get('CPG00');
        CustPriceGrp.Validate("Allow Line Disc.", false);
        CustPriceGrp.Validate("Allow Invoice Disc.", false);
        CustPriceGrp.Modify(true);

        CustPriceGrp.Get('CPG01');
        CustPriceGrp.Validate("Allow Line Disc.", false);
        CustPriceGrp.Validate("Allow Invoice Disc.", true);
        CustPriceGrp.Modify(true);

        CustPriceGrp.Get('CPG10');
        CustPriceGrp.Validate("Allow Line Disc.", true);
        CustPriceGrp.Validate("Allow Invoice Disc.", false);
        CustPriceGrp.Modify(true);

        CustPriceGrp.Get('CPG11');
        CustPriceGrp.Validate("Allow Line Disc.", true);
        CustPriceGrp.Validate("Allow Invoice Disc.", true);
        CustPriceGrp.Modify(true);

        SetupItemDisc('A', false);
        SetupItemDisc('B', true);
        SetupItemDisc('C', false);
        SetupItemDisc('D', true);
#if not CLEAN25
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '40000', SalesLineDisc.Type::Item, 'A', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '40000', SalesLineDisc.Type::Item, 'B', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '50000', SalesLineDisc.Type::Item, 'A', 0D, 0D, 0, '', '', '', 11);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '50000', SalesLineDisc.Type::Item, 'B', 0D, 0D, 0, '', '', '', 11);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '40000', SalesLineDisc.Type::Item, 'C', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(SalesLineDisc."Sales Type"::Customer, '50000', SalesLineDisc.Type::Item, 'C', 0D, 0D, 0, '', '', '', 15);

        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'A', 1, 100, false, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'B', 1, 101, false, true, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '50000', 'A', 1, 110, true, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '50000', 'B', 1, 111, true, true, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG00', 'A', 1, 100, false, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG01', 'B', 1, 101, false, true, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG10', 'A', 1, 110, true, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG11', 'A', 1, 111, true, true, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'A', 1, 210, true, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"All Customers", '', 'B', 1, 211, true, true, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'A', 10, 90, false, false, false, '');
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '40000', 0D, '', '', '', 10);
        SalesPrice.Validate("Allow Line Disc.", true);
        SalesPrice.Modify(true);
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '50000', 'B', 10, 90.9, true, true, false, '');
        SalesPrice.Get('B', SalesPrice."Sales Type"::Customer, '50000', 0D, '', '', '', 10);
        SalesPrice.Validate("Allow Line Disc.", false);
        SalesPrice.Modify(true);

        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'A', 20, 80, false, false, false, '');
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '40000', 0D, '', '', '', 20);
        SalesPrice.Validate("Allow Invoice Disc.", true);
        SalesPrice.Modify(true);

        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'B', 10, 90, false, true, false, '');
        SalesPrice.Get('B', SalesPrice."Sales Type"::Customer, '40000', 0D, '', '', '', 10);
        SalesPrice.Validate("Allow Invoice Disc.", false);
        SalesPrice.Modify(true);

        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::"All Customers");
        SalesLineDisc.SetRange(Type, SalesLineDisc.Type::Item);
        SalesLineDisc.SetFilter(Code, '%1|%2|%3', 'A', 'B', 'C');
        SalesLineDisc.DeleteAll(true);

        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"All Customers");
        SalesPrice.SetFilter("Item No.", '%1|%2', 'A', 'B');
        SalesPrice.DeleteAll(true);

        CopyAllPricesToPriceListLines();
        CopyAllDiscountsToPriceListLines();

#else
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '40000', PriceListLine."Asset Type"::Item, 'A', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '40000', PriceListLine."Asset Type"::Item, 'B', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '50000', PriceListLine."Asset Type"::Item, 'A', 0D, 0D, 0, '', '', '', 11);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '50000', PriceListLine."Asset Type"::Item, 'B', 0D, 0D, 0, '', '', '', 11);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '40000', PriceListLine."Asset Type"::Item, 'C', 0D, 0D, 0, '', '', '', 10);
        SRUtil.InsertSalesLineDisc(PriceListLine."Source Type"::Customer.AsInteger(), '50000', PriceListLine."Asset Type"::Item, 'C', 0D, 0D, 0, '', '', '', 15);

        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'A', 1, 100, false, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'B', 1, 101, false, true, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '50000', 'A', 1, 110, true, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '50000', 'B', 1, 111, true, true, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG00', 'A', 1, 100, false, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG01', 'B', 1, 101, false, true, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG10', 'A', 1, 110, true, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG11', 'A', 1, 111, true, true, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'A', 1, 210, true, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"All Customers", '', 'B', 1, 211, true, true, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'A', 10, 90, false, false, false, '');
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '40000', 0D, '', '', '', 10);
        PriceListLine."Allow Line Disc." := true;
        PriceListLine.Modify(true);
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '50000', 'B', 10, 90.9, true, true, false, '');
        GetSalesPrice(PriceListLine, 'B', PriceListLine."Source Type"::Customer.AsInteger(), '50000', 0D, '', '', '', 10);
        PriceListLine."Allow Line Disc." := false;
        PriceListLine.Modify(true);

        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'A', 20, 80, false, false, false, '');
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '40000', 0D, '', '', '', 20);
        PriceListLine."Allow Invoice Disc." := true;
        PriceListLine.Modify(true);

        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'B', 10, 90, false, true, false, '');
        GetSalesPrice(PriceListLine, 'B', PriceListLine."Source Type"::Customer.AsInteger(), '40000', 0D, '', '', '', 10);
        PriceListLine."Allow Invoice Disc." := false;
        PriceListLine.Modify(true);

        AllowEditingActivePrice(true);
        PriceListLine.Reset();
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::"All Customers");
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetFilter("Asset No.", '%1|%2|%3', 'A', 'B', 'C');
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Discount);
        PriceListLine.DeleteAll(true);

        PriceListLine.Reset();
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::"All Customers");
        PriceListLine.SetFilter("Asset No.", '%1|%2', 'A', 'B');
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        PriceListLine.DeleteAll(true);
        AllowEditingActivePrice(false);
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '40000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 10, '', '', 10);
        TestSalesLineUnitPrice(SalesLine, 90);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'PCS', '', 0);
        TestSalesLineUnitPrice(SalesLine, 4444.44);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'D', 1, 'PCS', '', 0);
        TestSalesLineUnitPrice(SalesLine, 4444.44);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 1, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 100);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 20, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 80);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 10, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 90);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 101);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        repeat
            TestSalesLineInvDiscAmt(SalesLine, InvDiscAmt[SalesLine."Line No." / 10000]);
        until SalesLine.Next() = 0;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '50000', '', 20020301D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 10, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 90.9);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, 'PCS', '', 15);
        TestSalesLineUnitPrice(SalesLine, 4444.44);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 1, '', '', 11);
        TestSalesLineUnitPrice(SalesLine, 111);
        SalesLine.Validate("Line Discount %", 20);
        SalesLine.Modify(true);

        Clear(InvDiscAmt);
        AllowInvDisc[1] := true;
        AllowInvDisc[2] := false;
        AllowInvDisc[3] := true;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        repeat
            TestscriptMgt.TestBooleanValue(
              StrSubstNo('%1 %2 %3', CurrTest, SalesLine."Line No.", SalesLine."Document Type", SalesLine."Document No.",
                SalesLine.FieldName("Allow Invoice Disc.")),
              SalesLine."Allow Invoice Disc.", AllowInvDisc[SalesLine."Line No." / 10000]);

            if SalesLine."Line No." = 10000 then
                TestscriptMgt.TestBooleanValue(
                  StrSubstNo('%1 %2 %3', SalesLine."Document Type", SalesLine."Document No.", SalesLine.FieldName("Allow Line Disc.")),
                  SalesLine."Allow Line Disc.", false);
        until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test12()
    var
        CustPriceGrp: Record "Customer Price Group";
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
    begin
        CurrTest := 'S.12';

        CustPriceGrp.Get('CPG00');
        CustPriceGrp.Validate("Price Includes VAT", false);
        CustPriceGrp.Modify(true);

        CustPriceGrp.Get('CPG01');
        CustPriceGrp.Validate("Price Includes VAT", true);
        CustPriceGrp.Validate("VAT Bus. Posting Gr. (Price)", 'DOMESTIC');
        CustPriceGrp.Modify(true);

        Customer.Get('40000');
        Customer.Validate("VAT Bus. Posting Group", 'DOMESTIC');
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);

        Customer.Get('50000');
        Customer.Validate("VAT Bus. Posting Group", 'DOMESTIC');
        Customer.Validate("Prices Including VAT", false);
        Customer.Validate("Customer Price Group", 'CPG00');
        Customer.Modify(true);
#if not CLEAN25
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetFilter("Sales Code", '50000');
        SalesPrice.DeleteAll(true);
#else
        AllowEditingActivePrice(true);
        PriceListLine.Reset();
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.SetFilter("Source No.", '50000');
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        PriceListLine.DeleteAll(true);
        AllowEditingActivePrice(false);
#endif
        Item.Get('A');
        Item.Validate("VAT Prod. Posting Group", 'VAT10');
        Item.Modify(true);

        Item.Get('B');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Modify(true);
#if not CLEAN25
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'A', 2, 100, false, false, true, '');
        SalesPrice.Get('A', SalesPrice."Sales Type"::Customer, '40000', 0D, '', '', '', 2);
        SalesPrice.Validate("Price Includes VAT", false);
        SalesPrice.Modify(true);
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::Customer, '40000', 'B', 2, 101, false, true, true, 'DOMESTIC');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG00', 'A', 2, 100, false, false, false, '');
        InsertAndTestSalesPrice(SalesPrice."Sales Type"::"Customer Price Group", 'CPG01', 'B', 2, 101, false, true, true, 'DOMESTIC');
        CopyAllPricesToPriceListLines();
#else
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'A', 2, 100, false, false, true, '');
        GetSalesPrice(PriceListLine, 'A', PriceListLine."Source Type"::Customer.AsInteger(), '40000', 0D, '', '', '', 2);
        PriceListLine."Price Includes VAT" := false;
        PriceListLine.Modify(true);
        InsertAndTestSalesPrice(PriceListLine."Source Type"::Customer, '40000', 'B', 2, 101, false, true, true, 'DOMESTIC');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG00', 'A', 2, 100, false, false, false, '');
        InsertAndTestSalesPrice(PriceListLine."Source Type"::"Customer Price Group", 'CPG01', 'B', 2, 101, false, true, true, 'DOMESTIC');
#endif
        commit();
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '40000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 110);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 101);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '50000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 2, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 100);

        Customer.Get('50000');
        Customer.Validate("Customer Price Group", 'CPG01');
        Customer.Modify();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '50000', '', 20020401D);
        InsertAndTestSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'B', 2, '', '', 0);
        TestSalesLineUnitPrice(SalesLine, 80.8);
    end;

    local procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; UnitPrice: Decimal; UnitCost: Decimal; SalesUOM: Code[20]; BaseQtyPerSalesUOM: Decimal; ItemDiscGroup: Code[10]; AllowInvDisc: Boolean)
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
        Item.Validate("Item Disc. Group", ItemDiscGroup);
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupCustDisc(CustNo: Code[20]; AllowLineDisc: Boolean; InvDiscPct: Decimal)
    var
        Cust: Record Customer;
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        Cust.Get(CustNo);
        Cust.Validate("Allow Line Disc.", AllowLineDisc);
        Cust.Modify(true);

        if Cust."No." = '40000' then begin
            Cust.Validate("Prices Including VAT", false);
            Cust.Modify(true);
        end;

        CustInvDisc.Validate(Code, Cust."No.");
        CustInvDisc.Validate("Currency Code", '');
        CustInvDisc.Validate("Minimum Amount", 0);
        if CustInvDisc.Find() then
            CustInvDisc.Delete(true);
        CustInvDisc.Validate("Discount %", InvDiscPct);
        CustInvDisc.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SetupItemDisc(ItemNo: Code[20]; AllowInvDisc: Boolean)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertAndTestSalesPrice(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20]; MinQty: Decimal; UnitPrice: Decimal; ExpAllowLineDisc: Boolean; ExpAllowInvDisc: Boolean; ExpPriceInclVAT: Boolean; ExpVATBusPostGrp: Code[20])
    var
#if not CLEAN25
        SalesPrice: Record "Sales Price";
#else
        PriceListLine: Record "Price List Line";
#endif
    begin
        SRUtil.InsertSalesPrice(SalesType, SalesCode, ItemNo, 0D, 0D, MinQty, '', '', '', UnitPrice);
#if not CLEAN25
        SalesPrice.Get(ItemNo, SalesType, SalesCode, 0D, '', '', '', MinQty);
        SalesPrice.Validate("VAT Bus. Posting Gr. (Price)", ExpVATBusPostGrp);
        SalesPrice.Modify(true);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice.FieldName("Allow Line Disc.")),
          SalesPrice."Allow Line Disc.", ExpAllowLineDisc);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice.FieldName("Allow Invoice Disc.")),
          SalesPrice."Allow Invoice Disc.", ExpAllowInvDisc);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice.FieldName("Price Includes VAT")),
          SalesPrice."Price Includes VAT", ExpPriceInclVAT);
        TestscriptMgt.TestTextValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice.FieldName("VAT Bus. Posting Gr. (Price)")),
          SalesPrice."VAT Bus. Posting Gr. (Price)", ExpVATBusPostGrp);
#else
        GetSalesPrice(PriceListLine, ItemNo, SalesType.AsInteger(), SalesCode, 0D, '', '', '', MinQty);
        PriceListLine."VAT Bus. Posting Gr. (Price)" := ExpVATBusPostGrp;
        PriceListLine.Modify(true);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, PriceListLine."Source Type", PriceListLine."Source No.", PriceListLine.FieldName("Allow Line Disc.")),
          PriceListLine."Allow Line Disc.", ExpAllowLineDisc);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, PriceListLine."Source Type", PriceListLine."Source No.", PriceListLine.FieldName("Allow Invoice Disc.")),
          PriceListLine."Allow Invoice Disc.", ExpAllowInvDisc);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, PriceListLine."Source Type", PriceListLine."Source No.", PriceListLine.FieldName("Price Includes VAT")),
          PriceListLine."Price Includes VAT", ExpPriceInclVAT);
        TestscriptMgt.TestTextValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, PriceListLine."Source Type", PriceListLine."Source No.", PriceListLine.FieldName("VAT Bus. Posting Gr. (Price)")),
          PriceListLine."VAT Bus. Posting Gr. (Price)", ExpVATBusPostGrp);
#endif
    end;

    [Scope('OnPrem')]
    procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CurrencyCode: Code[20]; Date: Date)
    begin
        WorkDate := Date;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertAndTestSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; VarCode: Code[20]; ExpectedLineDisc: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        if UOMCode <> '' then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Validate("Variant Code", VarCode);
        SalesLine.Modify(true);

        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Line Discount %"), SalesLine."Line Discount %", ExpectedLineDisc);
    end;

    local procedure UpdateQtyToShipAndInvoice(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInv: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInv);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure EditAndTestSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal; LocCode: Code[20]; VarCode: Code[20]; UOMCode: Code[20]; ExpectedValue: Decimal)
    begin
        if ItemNo <> SalesLine."No." then
            SalesLine.Validate("No.", ItemNo);
        if Qty <> SalesLine.Quantity then
            SalesLine.Validate(Quantity, Qty);
        if VarCode <> SalesLine."Variant Code" then
            SalesLine.Validate("Variant Code", VarCode);
        if LocCode <> SalesLine."Location Code" then
            SalesLine.Validate("Location Code", LocCode);
        if UOMCode <> SalesLine."Unit of Measure Code" then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Modify(true);

        TestSalesLineDiscPct(SalesLine, ExpectedValue);

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

    [Scope('OnPrem')]
    procedure TestSalesLineUnitPrice(var SalesLine: Record "Sales Line"; ExpectedValue: Decimal)
    begin
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Unit Price"), SalesLine."Unit Price", ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestSalesLineDiscPct(var SalesLine: Record "Sales Line"; ExpectedValue: Decimal)
    begin
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Line Discount %"), SalesLine."Line Discount %", ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestSalesLineInvDiscAmt(var SalesLine: Record "Sales Line"; ExpectedValue: Decimal)
    begin
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Inv. Discount Amount"), SalesLine."Inv. Discount Amount", ExpectedValue);
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

#if not CLEAN25
    local procedure CopyAllDiscountsToPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        SalesLineDisc: Record "Sales Line Discount";
    begin
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Discount);
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(SalesLineDisc, PriceListLine);
    end;

    local procedure CopyAllPricesToPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
    begin
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
    end;
#endif
#if CLEAN25
    local procedure GetSalesDisc(var PriceListLine: Record "Price List Line"; Type: Option; "Code": code[20]; "Sales Type": Option; "Sales Code": Code[20]; "Starting Date": Date; "Currency Code": Code[10]; "Variant Code": Code[10]; "Unit of Measure Code": Code[10]; "Minimum Quantity": Decimal): Boolean;
    begin
        PriceListLine.Reset();
        PriceListLine.SetRange("Asset Type", Type);
        PriceListLine.SetRange("Asset No.", Code);
        PriceListLine.SetRange("Source Type", "Sales Type");
        PriceListLine.SetRange("Source No.", "Sales Code");
        PriceListLine.SetRange("Starting Date", "Starting Date");
        PriceListLine.SetRange("Currency Code", "Currency Code");
        PriceListLine.SetRange("Variant Code", "Variant Code");
        PriceListLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        PriceListLine.SetRange("Minimum Quantity", "Minimum Quantity");
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Discount);
        exit(PriceListLine.FindFirst())
    end;

    local procedure GetSalesPrice(var PriceListLine: Record "Price List Line"; "Item No.": code[20]; "Sales Type": Option; "Sales Code": Code[20]; "Starting Date": Date; "Currency Code": Code[10]; "Variant Code": Code[10]; "Unit of Measure Code": Code[10]; "Minimum Quantity": Decimal): Boolean;
    begin
        PriceListLine.Reset();
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", "Item No.");
        PriceListLine.SetRange("Source Type", "Sales Type");
        PriceListLine.SetRange("Source No.", "Sales Code");
        PriceListLine.SetRange("Starting Date", "Starting Date");
        PriceListLine.SetRange("Currency Code", "Currency Code");
        PriceListLine.SetRange("Variant Code", "Variant Code");
        PriceListLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        PriceListLine.SetRange("Minimum Quantity", "Minimum Quantity");
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        exit(PriceListLine.FindFirst())
    end;
#endif
}
