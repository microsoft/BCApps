codeunit 103422 Corsica_ClosingInventoryPeriod
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        TestCase2();
        "TestCase5-1"();
        "TestCase5-2"();
        TestCase6();
        "TestCase7-2"();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        CurrTest: Text[80];

    [Scope('OnPrem')]
    procedure TestCase2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InventoryPeriod: Record "Inventory Period";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // Create purchase header and lines on 25-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 70);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010127D;
        // Create sales header and lines on 27-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 62);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010128D;
        // Close Inventory Period, Ending Date = 27-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010127D, 'Close');
        // Check Results, Inventory Period should be closed now
        RecordCount := InventoryPeriod.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-2-A1-', InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 1);
        if InventoryPeriod.FindFirst() then;
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-2-A2-', InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, true);
        // Create purchase header and lines on 28-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 50);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010129D;
        // Reopen Closed Period
        HandleCloseInvPeriod(20010127D, 'Reopen');
        // Check Results, Inventory Period should be closed now
        RecordCount := InventoryPeriod.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-2-B1-', InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 1);
        if InventoryPeriod.FindFirst() then;
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-2-B2-', InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, false);
        // Close Inventory Period, Ending Date = 28-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010128D, 'Close');
        // Check Results, both Inventory periods should be closed now
        Code := '103422-TC-2-C1-';
        RecordCount := InventoryPeriod.Count;
        TestscriptMgt.TestNumberValue(
          MakeName(Code, InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 2);
        if InventoryPeriod.FindFirst() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestBooleanValue(
                  MakeName(Code, InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, true);
            until InventoryPeriod.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure "TestCase5-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InventoryPeriod: Record "Inventory Period";
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // Create purchase header and lines on 25-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 10);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010126D;
        // Create sales header and lines on 26-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 6, 'PCS', 62.34567);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PCS', 15);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010127D;
        // Close Inventory Period, Ending Date = 26-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010126D, 'Close');
        // Create sales header and lines on 27-01-01, with Posting Date 26-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 15);
        // Reopen Closed Period
        HandleCloseInvPeriod(20010126D, 'Reopen');
        // Post sales order as shipped and invoiced
        SalesHeader.FindFirst();
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Check Results, Inventory period should be open now, Sales Header is posted
        RecordCount := SalesHeader.Count();
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-5-1-A-', SalesHeader.TableCaption(), '- No Record in Table ='), RecordCount, 0);
        if InventoryPeriod.FindFirst() then
            repeat
                TestscriptMgt.TestBooleanValue(
                  MakeName('103422-TC-5-1-B-', InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, false);
            until InventoryPeriod.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure "TestCase5-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InventoryPeriod: Record "Inventory Period";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // Create purchase header and lines on 25-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 50);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010127D;
        // Create sales header and lines on 27-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 6, 'PCS', 15);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 6, 5, 0, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010128D;
        // Close Inventory Period, Ending Date = 27-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010127D, 'Close');
        // Create sales header and lines on 28-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 6, 'PCS', 75);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 6, 5, 0, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010129D;
        // Close Inventory Period, Ending Date = 28-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010128D, 'Close');
        // Create sales header and lines on 29-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 6, 'PCS', 85);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 6, 5, 0, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010130D;
        // Close Inventory Period, Ending Date = 29-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010129D, 'Close');
        // Check Results A, All three Inventory Periods are closed
        RecordCount := InventoryPeriod.Count;
        Code := '103422-TC-5-2-A1-';
        TestscriptMgt.TestNumberValue(
          MakeName(Code, InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 3);
        if InventoryPeriod.FindFirst() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestBooleanValue(
                  MakeName(Code, InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, true);
            until InventoryPeriod.Next() = 0;
        // Reopen Closed Period
        HandleCloseInvPeriod(20010128D, 'Reopen');
        // Create purchase header and lines on 30-01-01, with Order Posting Date 28-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010128D);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010128D, 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 55);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Check Results B, The inventory Periods with Ending Dates 28-01-01 and 29-01-01 are open now.
        // Purchase Order is posted successfully.
        RecordCount := PurchHeader.Count();
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-5-2-B1-', PurchHeader.TableCaption(), '- Records in Table ='), RecordCount, 0);
        InventoryPeriod.Get(20010127D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-B2-', InventoryPeriod.TableCaption(), '- Inventory Period 27-01-01 is closed ='), InventoryPeriod.Closed, true);
        InventoryPeriod.Get(20010128D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-B3-', InventoryPeriod.TableCaption(), '- Inventory Period 28-01-01 is closed ='), InventoryPeriod.Closed, false);
        InventoryPeriod.Get(20010129D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-B4-', InventoryPeriod.TableCaption(), '- Inventory Period 29-01-01 is closed ='), InventoryPeriod.Closed, false);
        // Close Inventory Period, Ending Date = 28-01-01 again
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010128D, 'Reclose');
        // Check Results C, Inventory Period 28-01-01 is closed, Inventory Period 29-01-01 is still open
        RecordCount := InventoryPeriod.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-5-2-C1-', InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 3);
        InventoryPeriod.Get(20010127D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-C2-', InventoryPeriod.TableCaption(), '- Inventory Period 27-01-01 is closed ='), InventoryPeriod.Closed, true);
        InventoryPeriod.Get(20010128D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-C3-', InventoryPeriod.TableCaption(), '- Inventory Period 28-01-01 is closed ='), InventoryPeriod.Closed, true);
        InventoryPeriod.Get(20010129D);
        TestscriptMgt.TestBooleanValue(
          MakeName('103422-TC-5-2-C4-', InventoryPeriod.TableCaption(), '- Inventory Period 29-01-01 is closed ='), InventoryPeriod.Closed, false);
        // Check Result D, Adjustment Entries are created in the Value Entry Table with Posting Date = 28-01-01
        if ValueEntry.FindLast() then begin
            TestscriptMgt.TestTextValue(
              MakeName('103422-TC-5-2-D1-', ValueEntry.TableCaption(), '- Created by Adjustment ='), ValueEntry."Source Code", 'INVTADJMT');
            TestscriptMgt.TestDateValue(
              MakeName('103422-TC-5-2-D2-', ValueEntry.TableCaption(), '- Posting Date is ='), ValueEntry."Posting Date", 20010128D);
        end;
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-5-2-D3-', ValueEntry.TableCaption(), '- Records in Table ='), RecordCount, 3);
        //Reopen the inventory posting period which has been closed for Work Date 27-01-01
        HandleCloseInvPeriod(20010127D, 'Reopen');
        //Check Results E, All inventory Periods are open now
        RecordCount := InventoryPeriod.Count;
        Code := '103422-TC-5-2-E1-';
        TestscriptMgt.TestNumberValue(
          MakeName(Code, InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 3);
        if InventoryPeriod.FindFirst() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestBooleanValue(
                  MakeName(Code, InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, false);
            until InventoryPeriod.Next() = 0;
        // Close Inventory Period, Ending Date = 29-01-01 again
        HandleCloseInvPeriod(20010129D, 'Reclose');
        CostingTestScriptMgmt.AdjustItem('', '', false);
        //Check Results F, All inventory Periods are now closed again
        RecordCount := InventoryPeriod.Count;
        Code := '103422-TC-5-2-F1-';
        TestscriptMgt.TestNumberValue(
          MakeName(Code, InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 3);
        if InventoryPeriod.FindFirst() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestBooleanValue(
                  MakeName(Code, InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, true);
            until InventoryPeriod.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure TestCase6()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InventoryPeriod: Record "Inventory Period";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // Create purchase header and lines on 25-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 10);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 70);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 55);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 50);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010126D;
        // Create sales header and lines on 27-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 22);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 140);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 90);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010127D;
        // Create purchase header and lines on 27-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 12);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Post sales order as invoiced
        SalesHeader.FindFirst();
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20010128D;
        // Create Purchase Invoice, retrieve posted receipts, post invoice
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010125D, 'BLUE', '', false);
        PurchRcptLine.Reset();
        PurchGetRcpLine.SetPurchHeader(PurchHeader);
        PurchRcptLine.SetRange("Buy-from Vendor No.", '10000');
        PurchGetRcpLine.CreateInvLines(PurchRcptLine);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010129D;
        // Close Inventory Period, Ending Date = 28-01-01
        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20010128D, 'Close');
        // Check Results A, Inventory Period is closed
        RecordCount := InventoryPeriod.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-6-A1-', InventoryPeriod.TableCaption(), '- Records in Table ='), RecordCount, 1);
        if InventoryPeriod.FindFirst() then
            repeat
                TestscriptMgt.TestBooleanValue(
                  MakeName('103422-TC-6-A2-', InventoryPeriod.TableCaption(), '- Inventory Period is closed ='), InventoryPeriod.Closed, true);
            until InventoryPeriod.Next() = 0;
        // Create purchase header and lines on 29-01-01
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 14);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20010130D;
        // Create sales header and lines on 30-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 22);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 140);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '', 3, 'PCS', 90);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Check Results B, Sales order is posted succesfully,
        // The Item Ledger Entries with the Numbers 1,2,3,4,8,9 show the following values
        Code := '103422-TC-6-B1-';
        ItemLedgEntry.Get(1);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 0);
        Code := IncStr(Code);
        ItemLedgEntry.Get(2);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '4_AV_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 0);
        Code := IncStr(Code);
        ItemLedgEntry.Get(3);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '7_ST_OV');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 1);
        Code := IncStr(Code);
        ItemLedgEntry.Get(4);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '4_AV_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 2);
        Code := IncStr(Code);
        ItemLedgEntry.Get(8);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107002');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010127D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 3);
        Code := IncStr(Code);
        ItemLedgEntry.Get(9);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107003');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010129D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 5);
        //Create a new Sales Invoice for Customer 10000 and retrieve the Sales Order posted lately
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        Clear(SalesShipmentLine);
        SalesShipmentLine.SetRange("Sell-to Customer No.", '10000');
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Result C, the invoice was posted succesfully
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        RecordCount := SalesHeader.Count;
        TestscriptMgt.TestNumberValue(
          MakeName('103422-TC-6-C-', SalesHeader.TableCaption(), '- Records in Table ='), RecordCount, 0);
        // New workdate
        WorkDate := 20010131D;
        // Create sales header and lines on 31-01-01
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 22);
        SalesLine.Validate("Appl.-to Item Entry", 8);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 140);
        SalesLine.Validate("Appl.-to Item Entry", 4);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 90);
        SalesLine.Validate("Appl.-to Item Entry", 3);
        SalesLine.Modify();
        // Post sales order as shipped
        SalesHeader.Ship := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Check Results B, Sales order is posted succesfully, with Apply -To Item Ledger Entry No.
        // The Item Ledger Entries with the Numbers 1,2,3,4,8,9 show the following values
        Code := '103422-TC-6-B6-';
        Code := IncStr(Code);
        ItemLedgEntry.Get(1);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 0);
        Code := IncStr(Code);
        ItemLedgEntry.Get(2);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '4_AV_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 0);
        Code := IncStr(Code);
        ItemLedgEntry.Get(3);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '7_ST_OV');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 0);
        Code := IncStr(Code);
        ItemLedgEntry.Get(4);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '4_AV_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107001');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010125D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 1);
        Code := IncStr(Code);
        ItemLedgEntry.Get(8);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107002');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010127D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 2);
        Code := IncStr(Code);
        ItemLedgEntry.Get(9);
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Item Number ='), ItemLedgEntry."Item No.", '1_FI_RE');
        TestscriptMgt.TestTextValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Document Number ='), ItemLedgEntry."Document No.", '107003');
        TestscriptMgt.TestDateValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Posting Date ='), ItemLedgEntry."Posting Date", 20010129D);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, ItemLedgEntry.TableCaption(), '- Remaining Quantity ='), ItemLedgEntry."Remaining Quantity", 5);
    end;

    [Scope('OnPrem')]
    procedure "TestCase7-2"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CalcInv: Report "Calculate Inventory";
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // New workdate
        WorkDate := 20001201D;
        // Create purchase header and lines on 01-12-00
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 53.45678);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 10, 'PCS', 73.45678);
        // Post purchase order as received
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // New workdate
        WorkDate := 20001202D;
        // Create sales header and lines on 02-12-00
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 80.34567);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20001210D;
        // Physical Inventory on 10-12-00, decreasing Inventory
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetFilter("Location Filter", 'BLUE');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(WorkDate(), 'T02001', false, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PHYS. INV.');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindFirst() then
            repeat
                ItemJnlLine.Validate("Qty. (Phys. Inventory)", 9);
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // New workdate
        WorkDate := 20001211D;
        // Physical Inventory on 11-12-00, increasing Inventory
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetFilter("Location Filter", 'BLUE');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(WorkDate(), 'T02002', false, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PHYS. INV.');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindFirst() then
            repeat
                ItemJnlLine.Validate("Qty. (Phys. Inventory)", 10);
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // New workdate
        WorkDate := 20001217D;
        // Create sales header and lines on 17-12-00
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 8, 'PCS', 26);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 80.55);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 26);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20001218D;
        // Create sales header and lines on 18-12-00
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 80.34567);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 10);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20001221D;
        // Create purchase header and lines on 21-12-00
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 24);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 53.45678);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 73.45678);

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // New workdate
        WorkDate := 20001222D;

        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 2, 'PCS', 50.55);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 12, 'PCS', 50.55);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 3.4);

        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // New workdate
        WorkDate := 20001223D;

        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 8.4);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 19, 'PCS', 58.34567);

        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);

        WorkDate := 20010101D;

        CostingTestScriptMgmt.AdjustItem('', '', false);
        HandleCloseInvPeriod(20001231D, 'Close');
    end;

    local procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;

    local procedure HandleCloseInvPeriod(EndingDate: Date; "Action": Code[10])
    var
        InventoryPeriod: Record "Inventory Period";
        CloseInventoryPeriod: Codeunit "Close Inventory Period";
    begin
        CloseInventoryPeriod.SetHideDialog(true);
        case Action of
            'CLOSE':
                begin
                    InventoryPeriod."Ending Date" := EndingDate;
                    InventoryPeriod.Insert();
                    InventoryPeriod.FindLast();
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
            'REOPEN':
                begin
                    InventoryPeriod.Get(EndingDate);
                    CloseInventoryPeriod.SetReOpen(true);
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
            'RECLOSE':
                begin
                    InventoryPeriod.Get(EndingDate);
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
        end;
    end;
}

