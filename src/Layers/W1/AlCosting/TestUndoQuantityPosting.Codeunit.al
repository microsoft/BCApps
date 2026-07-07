codeunit 103523 "Test - Undo Quantity Posting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103523);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();
        "Test 2"();
        "Test 3"();
        "Test 4"();
        "Test 5"();
        "Test 6"();
        "Test 7"();
        "Test 9"();
        // "Test 10"; DH: The specification and the script do not agree.

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GenPostSetup: Record "General Posting Setup";
        InvtCostSetup: Record "Inventory Posting Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        INVTUtil: Codeunit INVTUtil;
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        CurrTest: Text[250];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetAddCurr('EUR', 10, 3, 0.01, 0.00001);

        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Modify(true);

        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        InsertItem('A', 'Item A', 'PCS', 50.55, 100.95);
        InsertItem('B', 'Item B', 'BOX', 3.14, 133.14);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenPostSetup: Record "General Posting Setup";
        InvtPostSetup: Record "Inventory Posting Setup";
    begin
        CurrTest := 'Delete - P.1';

        WorkDate := 20010201D;

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);

        WorkDate := GLUtil.GetLastestPostingDate() + 1;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 2, 50.55);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange("Line No.", 10000);
        UndoPurchRcptLine(PurchRcptLine);

        PurchHeader.Find();
        ReleasePurchDoc.Reopen(PurchHeader);
        PurchHeader.Delete(true);

        GenPostSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        ValidateNetChange(GenPostSetup."Invt. Accrual Acc. (Interim)", 0, 0);
        InvtPostSetup.Get(PurchLine."Location Code", PurchLine."Posting Group");
        ValidateNetChange(InvtPostSetup."Inventory Account (Interim)", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure "Test 2"()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        BlnktPurchHeader: Record "Purchase Header";
        BlnktPurchLine: Record "Purchase Line";
    begin
        CurrTest := 'Blanket order - P.6';

        PPUtil.InsertPurchHeader(BlnktPurchHeader, BlnktPurchLine, BlnktPurchHeader."Document Type"::"Blanket Order");
        BlnktPurchHeader.Validate("Buy-from Vendor No.", '30000');
        BlnktPurchHeader.Modify(true);
        InsertPurchLine(BlnktPurchHeader, BlnktPurchLine, BlnktPurchLine.Type::Item, 'A', '', 100, 50.55);
        BlnktPurchLine.Validate("Qty. to Receive", 50);
        BlnktPurchLine.Modify(true);
        InsertPurchLine(BlnktPurchHeader, BlnktPurchLine, BlnktPurchLine.Type::Item, 'B', 'BLUE', 1000, 50.55);
        BlnktPurchLine.Validate("Qty. to Receive", 500);
        BlnktPurchLine.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", BlnktPurchHeader);

        PurchHeader.Get(PurchHeader."Document Type"::Order, GLUtil.GetLastDocNo(PurchSetup."Order Nos."));
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate("Qty. to Receive", 10);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 100);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchLine.Find('-');
        PurchLine.Validate("Qty. to Receive", 20);
        PurchLine.Validate("Qty. to Invoice", 20);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 200);
        PurchLine.Validate("Qty. to Invoice", 200);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchLine.Find('-');
        PurchLine.Validate("Qty. to Receive", 20);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 200);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000');
        UndoPurchRcptLine(PurchRcptLine);

        BlnktPurchLine.SetRange("Document Type", BlnktPurchHeader."Document Type");
        BlnktPurchLine.SetRange("Document No.", BlnktPurchHeader."No.");
        BlnktPurchLine.Find('-');
        BlnktPurchLine.Validate("Qty. to Receive", 50);
        BlnktPurchLine.Modify(true);
        BlnktPurchLine.Next();
        BlnktPurchLine.Validate("Qty. to Receive", 500);
        BlnktPurchLine.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", BlnktPurchHeader);

        PurchHeader2.Get(PurchHeader2."Document Type"::Order, GLUtil.GetLastDocNo(PurchSetup."Order Nos."));
        PPUtil.PostPurchase(PurchHeader2, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader2."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000');
        UndoPurchRcptLine(PurchRcptLine);

        PPUtil.PostPurchase(PurchHeader2, true, true);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000');
        UndoPurchRcptLine(PurchRcptLine);

        PPUtil.PostPurchase(PurchHeader, true, true);

        BlnktPurchLine.Find('-');
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Quantity Received")),
          BlnktPurchLine."Quantity Received", 100);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Quantity Invoiced")),
          BlnktPurchLine."Quantity Invoiced", 100);
        BlnktPurchLine.Next();
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Quantity Received")),
          BlnktPurchLine."Quantity Received", 1000);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Quantity Invoiced")),
          BlnktPurchLine."Quantity Invoiced", 1000);

        BlnktPurchHeader.Find();
        ReleasePurchDoc.Reopen(BlnktPurchHeader);
        BlnktPurchHeader.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure "Test 3"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := 'Full/Partial - P.7';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 1, 50.55);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 'BLUE', 3.5, 50.55);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', '', 10, 3.14);
        PurchLine.Validate("Qty. to Receive", 5);
        PurchLine.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 'BLUE', -5, 3.14);
        PurchLine.Validate("Qty. to Receive", -5);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000|30000|40000');
        UndoPurchRcptLine(PurchRcptLine);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 0.5);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 4);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Receive", 0);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '20000');
        UndoPurchRcptLine(PurchRcptLine);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is deleted', CurrTest, PurchHeader."No."),
          not PurchHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure "Test 4"()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'Item Charge Assignment - P.8';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 1, 50.55);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', '', 1, 3.14);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', '', 1, 50.55);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          PurchLine."Document Type", PurchLine."Document No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000');
        UndoPurchRcptLine(PurchRcptLine);
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        ReleasePurchDoc.PerformManualReopen(PurchHeader);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', '', 1, 50.55);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          PurchLine."Document Type", PurchLine."Document No.", 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is deleted', CurrTest, PurchHeader."No."),
          not PurchHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure "Test 5"()
    var
        InvtSetup: Record "Inventory Setup";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'Interim postings P.10';

        InvtSetup.ModifyAll("Expected Cost Posting to G/L", true);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 2, 50.55);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 'BLUE', 11, 3.14);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000');
        UndoPurchRcptLine(PurchRcptLine);

        ReleasePurchDoc.Reopen(PurchHeader);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate("Direct Unit Cost", 3.33);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Direct Unit Cost", 3.33);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        GenPostSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        ValidateNetChange(GenPostSetup."Invt. Accrual Acc. (Interim)", 0, 0);
        InvtCostSetup.Get(PurchLine."Location Code", PurchLine."Posting Group");
        ValidateNetChange(InvtCostSetup."Inventory Account (Interim)", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure "Test 6"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
    begin
        CurrTest := 'Using Return Document - P.13';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order");
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 1, 50.55);
        PurchLine.Validate("Return Qty. to Ship", 0);
        PurchLine.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 'BLUE', 3.5, 50.55);
        PurchLine.Validate("Return Qty. to Ship", 0);
        PurchLine.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', '', 10, 3.14);
        PurchLine.Validate("Return Qty. to Ship", 5);
        PurchLine.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 'BLUE', -5, 3.14);
        PurchLine.Validate("Return Qty. to Ship", -5);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.SetRange("Return Order No.", PurchHeader."No.");
        ReturnShptHeader.FindLast();
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.SetFilter("Line No.", '30000|40000');
        UndoReturnShptLine(ReturnShptLine);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate("Return Qty. to Ship", 1);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Return Qty. to Ship", 0.5);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Return Qty. to Ship", 4);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();

        PPUtil.PostPurchase(PurchHeader, true, true);

        ReturnShptHeader.SetRange("Return Order No.", PurchHeader."No.");
        ReturnShptHeader.FindLast();
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.SetFilter("Line No.", '20000|40000');
        UndoReturnShptLine(ReturnShptLine);

        PurchLine.Find('-');
        PurchLine.Next();
        PurchLine.Validate("Return Qty. to Ship", 3.5);
        PurchLine.Validate("Qty. to Invoice", 3.5);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Return Qty. to Ship", 6);
        PurchLine.Validate("Qty. to Invoice", 9);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Return Qty. to Ship", -5);
        PurchLine.Validate("Qty. to Invoice", -5);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is deleted', CurrTest, PurchHeader."No."),
          not PurchHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure "Test 7"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := 'Order line changed - P.14';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 5, 50.55);
        PurchLine.Validate("Qty. to Receive", 3);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchHeader.Find();
        ReleasePurchDoc.Reopen(PurchHeader);

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 10000);
        PurchLine.Validate(Quantity, 4);
        PurchLine.Validate("Direct Unit Cost", 12.34);
        PurchLine.Validate("Expected Receipt Date", 20010101D);
        PurchLine.Modify(true);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000');
        UndoPurchRcptLine(PurchRcptLine);

        PurchLine.Find();
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 has Qty to receive as 0', CurrTest, PurchHeader."No."), PurchLine.Quantity, 4);
    end;

    [Scope('OnPrem')]
    procedure "Test 9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := 'Order Status - P.16';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 1, 50.55);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchHeader.Find();
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is in status Released', CurrTest, PurchHeader."No."),
          PurchHeader.Status = PurchHeader.Status::Released, true);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000');
        UndoPurchRcptLine(PurchRcptLine);

        PurchHeader.Find();
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is in status Released', CurrTest, PurchHeader."No."),
          PurchHeader.Status = PurchHeader.Status::Released, true);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchHeader.Find();
        ReleasePurchDoc.Reopen(PurchHeader);

        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is in status Open', CurrTest, PurchHeader."No."),
          PurchHeader.Status = PurchHeader.Status::Open, true);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000');
        UndoPurchRcptLine(PurchRcptLine);

        PurchHeader.Find();
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is in status Open', CurrTest, PurchHeader."No."),
          PurchHeader.Status = PurchHeader.Status::Open, true);
    end;

    [Scope('OnPrem')]
    procedure "Test 10"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CurrTest := 'Already Applied - P.15';

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', '', 2, 50.55);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', '', 1);
        SRUtil.ReserveSalesLnAgainstPurchLn(SalesLine, PurchLine, 1, 1);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 'Blue', 2, 50.55);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 'Blue', 2);
        SRUtil.ReserveSalesLnAgainstPurchLn(SalesLine, PurchLine, 2, 2);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', '', 1, 3.14);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000|20000|30000');
        UndoPurchRcptLine(PurchRcptLine);

        SRUtil.PostSales(SalesHeader, true, true);

        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 is deleted', CurrTest, PurchHeader."No."),
          not PurchHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure InsertItem(ItemNo: Code[20]; Description: Text[50]; BaseUOM: Code[20]; LastDirectUnitCost: Decimal; UnitPrice: Decimal)
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit;
        Clear(Item);
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        Item.Validate(Description, Description);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Last Direct Cost", LastDirectUnitCost);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Location: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate("Location Code", Location);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Location: Code[20]; Qty: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate("Location Code", Location);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UndoPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        "Undo Purchase Receipt Line": Codeunit "Undo Purchase Receipt Line";
    begin
        "Undo Purchase Receipt Line".SetHideDialog(true);
        "Undo Purchase Receipt Line".Run(PurchRcptLine);
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

    [Scope('OnPrem')]
    procedure UndoReturnShptLine(var ReturnShptLine: Record "Return Shipment Line")
    var
        "Undo Return Shipment Line": Codeunit "Undo Return Shipment Line";
    begin
        "Undo Return Shipment Line".SetHideDialog(true);
        "Undo Return Shipment Line".Run(ReturnShptLine);
    end;
}

