codeunit 103425 Corsica_AdjCostOfCOGS
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // TC-5 is only the general preparation for manual tests TC-5-1,TC-5-2 and TC-5-3.
    // The test results A2 are not automated.


    trigger OnRun()
    begin
        WMSTestscriptManagement.SetGlobalPreconditions();
        "TCS-1-1"();
        // Purchase Invoice before Sales Invoice"TCS-1-2"();
        // Purchase Invoice after Sales Invoice"TCS-1-3"();
        // Purchase Invoice after Sales Invoice, Online Adjustment used"TCS-1-4"();
        // Purchase Invoice before Sales Invoice"TCS-1-5"();
        // Sales Invoice Date before Sales Shipment Date"TCS-1-6"();
        // Multiple Sales Invoices for one Sales Shipment"TCS-2-1"();
        // Undo Shipment"TCS-3-1"();
        // Rounding Differences"TCS-4-1"();
        // Finalizing Output"GeneralPrepTCS-5"();      // Cost Adjustment Posting Dates on Closed Periods
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CurrTest: Text[80];
        TEXT001: Label 'Not found';
        TEXT002: Label '- Records in Table =';
        TEXT003: Label '- Posting Date =';
        TEXT004: Label '- Test failed, Value Entry not found =';
        TEXT005: Label '- Document No. =';

    [Scope('OnPrem')]
    procedure "TCS-1-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010129D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 55, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010130D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-1-1-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 5);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 300, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 500, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010123D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 41);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 51);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 51, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 310);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 310, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 510, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010124D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-1-2-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ValueEntryNo: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Always);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);

        WorkDate := 20010125D;
        if ValueEntry.FindLast() then
            ValueEntryNo := ValueEntry."Entry No."
        else
            ValueEntryNo := 0;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader2 := PurchHeader;
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 55, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010129D;
        // Post second purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010130D;
        // Post first purchase order as invoiced
        PurchHeader := PurchHeader2;
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Verify Results A-1
        Code := '103425-TC-1-3-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntryNo);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 5);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 6);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                if ValueEntry."Expected Cost" then
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010125D)
                else
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ValueEntry: Record "Value Entry";
        OrgValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ValueEntryNo: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Always);
        // Initialize workdate
        WorkDate := 20010125D;
        if ValueEntry.FindLast() then
            ValueEntryNo := ValueEntry."Entry No."
        else
            ValueEntryNo := 0;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 300, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 500, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntryNo);
        ValueEntry.FindFirst();
        // Raise workdate
        WorkDate := 20010126D;
        // Create transfer header
        Clear(TransHeader);
        WMSTestscriptManagement.InsertTransferHeader(TransHeader, 'Blue', 'RED', 'OWN LOG.', WorkDate());
        // Create transfer lines
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 10000, '1_FI_RE', '', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 20000, '4_AV_RE', '', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 30000, '2_LI_RA', '', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 40000, '5_ST_RA', '', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 50000, '6_AV_OV', '', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 60000, '1_FI_RE', '11', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 70000, '4_AV_RE', '41', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 80000, '2_LI_RA', '21', 'PCS', 7, 0, 7);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 90000, '6_AV_OV', '61', 'PCS', 7, 0, 7);
        // Post transfer as shipped
        WMSTestscriptManagement.PostTransferOrder(TransHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post first purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Post transfer as received
        WMSTestscriptManagement.ModifyTransferHeader(TransHeader, WorkDate());
        WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010201D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010130D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 41);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 51);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 51, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 310);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 310, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 510, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 9, '', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 9, 20, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 30000, '2_LI_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 40000, '5_ST_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 50000, '6_AV_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 60000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 70000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 80000, '2_LI_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 90000, "Purchase Applies-to Document Type"::Receipt, ValueEntry."Document No.", 90000, '6_AV_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 90000, 1);
        // Post purchase invoice
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Verify Results A-1
        Code := '103425-TC-1-4-A1-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntryNo);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 61);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                OrgValueEntry.Get(ValueEntry."Applies-to Entry");
                TestscriptMgt.TestDateValue(
                  MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", OrgValueEntry."Posting Date")
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 300, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 500, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010126D;
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 10, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 20, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 30, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 40, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 50, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 100, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 200, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 300, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 500, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010123D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 41);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 51);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 51, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 310);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 310, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 510, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010124D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-1-5-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        OrgValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 300, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 500, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Modify sales lines
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 70000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 80000, 0, 3, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 90000, 0, 3, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010123D;
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 20, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 30, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 10, 40, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 10, 50, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 10, 60, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 10, 110, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 10, 210, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 10, 310, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 10, 510, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;

        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-1-6-A1-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                if ValueEntry."Expected Cost" then
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D)
                else
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 41);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 51);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 51, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 10, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 10, 'PCS', 310);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 310, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 510, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103425-TC-1-6-A2-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 4);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 4);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                if ValueEntry."Expected Cost" then
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D)
                else
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Raise workdate
        WorkDate := 20010201D;
        // Modify sales lines
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 70000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 80000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 90000, 0, 1, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010202D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010124D;
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 21, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 31, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 10, 41, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 10, 51, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 10, 61, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 10, 120, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 10, 220, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 10, 320, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 10, 520, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103425-TC-1-6-A3-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 23);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                OrgValueEntry.Get(ValueEntry."Applies-to Entry");
                TestscriptMgt.TestDateValue(
                  MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", OrgValueEntry."Posting Date")
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-7"()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RtrnRcptDocNo: Code[20];
        TempInventoryValue: Decimal;
        RecordCount: Integer;
        ApplyFromEntryNo: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        if ItemLedgEntry.FindLast() then
            ApplyFromEntryNo := ItemLedgEntry."Entry No."
        else
            ApplyFromEntryNo := 0;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 11, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 11, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 11, 11, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '1_FI_RE', '11', 11, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 11, 11, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, ApplyFromEntryNo);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        ItemLedgEntry.Reset();
        ItemLedgEntry.FindLast();
        RtrnRcptDocNo := ItemLedgEntry."Document No.";
        // Raise workdate
        WorkDate := 20010127D;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Raise inventory value of every item by 10 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '', 'BLUE', '', 20010127D, '103425-TC-1-7', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange(ItemJnlLine."Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                TempInventoryValue := ItemJnlLine."Inventory Value (Revalued)" + 10;
                ItemJnlLine.Validate(ItemJnlLine."Inventory Value (Revalued)", TempInventoryValue);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010128D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 100, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 100, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 100, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 100, 'PCS', 41);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 100, 'PCS', 51);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 51, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 100, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '41', 100, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 100, 'PCS', 310);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 310, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '6_AV_OV', '61', 100, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 510, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010129D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-1-7-A1-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.SetRange("Expected Cost", true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
        Code := IncStr(Code);
        ValueEntry.SetRange("Expected Cost", false);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 16);
        ValueEntry.SetRange("Expected Cost");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                if ValueEntry."Valued Quantity" < 0 then
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010125D)
                else
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010126D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 9, '', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 9, 100, 0, 0);
        // Assign item charges to return receipt lines
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 30000, '2_LI_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 40000, '5_ST_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 50000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 50000, '6_AV_OV');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 50000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 60000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 60000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 60000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 70000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 70000, '4_AV_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 70000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 80000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 80000, '2_LI_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 80000, 1);
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 90000, "Sales Applies-to Document Type"::"Return Receipt", RtrnRcptDocNo, 90000, '6_AV_OV');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 90000, 1);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103425-TC-1-7-A2-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShptLine: Record "Sales Shipment Line";
        ValueEntry: Record "Value Entry";
        UndoSalesShptLine: Codeunit "Undo Sales Shipment Line";
        "Code": Code[20];
        RecordCount: Integer;
        ValueEntryNo: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Always);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Initialize workdate
        WorkDate := 20010125D;

        if ValueEntry.FindLast() then
            ValueEntryNo := ValueEntry."Entry No."
        else
            ValueEntryNo := 0;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        ValueEntry.FindLast();
        // Raise workdate
        WorkDate := 20010127D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;

        SalesShptLine.SetRange("Document No.", ValueEntry."Document No.");
        UndoSalesShptLine.SetHideDialog(true);
        UndoSalesShptLine.Run(SalesShptLine);
        // Raise workdate
        WorkDate := 20010129D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 55, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010130D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010131D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Verify Results A-1
        Code := '103425-TC-2-1-A1-1-';
        ValueEntry.Reset();
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntryNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Shipment");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 5);
        Code := IncStr(Code);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 6);
        ValueEntry.SetRange("Document Type");
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                if ValueEntry."Document Type" = ValueEntry."Document Type"::"Sales Shipment" then
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010126D)
                else
                    TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010130D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        DocumentNo: Code[20];
        RcptDocumentNo: Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 10, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ValueEntry.FindLast();
        RcptDocumentNo := ValueEntry."Document No.";
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ValueEntry.FindLast();
        DocumentNo := ValueEntry."Document No.";
        // Raise workdate
        WorkDate := 20010128D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010129D;

        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-3-1-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 1);
        if ValueEntry.FindSet() then begin
            Code := IncStr(Code);
            TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D);
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), DocumentNo, ValueEntry."Document No.");
        end;
        ValueEntry.SetRange("Entry Type");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 3);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Raise workdate
        WorkDate := 20010130D;
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 1, '', 1);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 1, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo, 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        // Post purchase invoice
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103425-TC-3-1-A2-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 1);
        if ValueEntry.FindSet() then begin
            Code := IncStr(Code);
            TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010127D);
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), DocumentNo, ValueEntry."Document No.");
        end;
        ValueEntry.SetRange("Entry Type");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 3);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-4-1"()
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        CalcConsumption: Report "Calc. Consumption";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B', '', 100, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 20, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create released production order
        Clear(ProdOrder);
        WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'A', 50, 'BLUE');
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        // Raise workdate
        WorkDate := 20010127D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B', '', 100, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 30, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create consumption journal lines
        ProdOrder.Reset();
        ProdOrder.SetRange("Location Code", 'BLUE');
        ProdOrder.SetRange("Source No.", 'A');
        ProdOrder.FindFirst();
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
        // Post consumption
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.FindFirst();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010129D;
        // Create output journal line
        ItemJnlLine.Reset();
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, WorkDate(), ItemJnlLine."Entry Type"::Output,
          ProdOrder."No.", 'A', '', 'BLUE', '', 2, 'PCS', 0, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", 10000);
        ItemJnlLine.Validate("Source No.", 'A');
        ItemJnlLine.Validate("Output Quantity", 50);
        ItemJnlLine.Modify();
        // Post output
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'OUTPUT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.FindFirst();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010130D;
        // Finish production order
        FinishProdOrder(ProdOrder, WorkDate(), false);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-4-1-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 2);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0;

        ValueEntry.SetRange(Adjustment);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 2);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010129D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Raise workdate
        WorkDate := 20010201D;
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 100, 30, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 100, 40, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Modify purchase lines
        PurchHeader.Next(-1);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 100, 20, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 100, 30, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010202D;

        ValueEntry.Reset();
        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103425-TC-4-1-A2-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        ValueEntry.SetRange(Adjustment, true);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 2);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010128D);
            until ValueEntry.Next() = 0;

        ValueEntry.SetRange(Adjustment);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 2);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010129D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure "GeneralPrepTCS-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        GLSetup: Record "General Ledger Setup";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        // sts
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostCalcType("Automatic Cost Adjustment Type"::Day);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        PurchHeader2 := PurchHeader;
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010129D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010130D;
        PurchHeader := PurchHeader2;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;

        ValueEntry.FindLast();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103425-TC-5-1-A1-1-';
        ValueEntry.SetFilter("Entry No.", '>%1', ValueEntry."Entry No.");
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 5);
        if ValueEntry.FindSet() then
            repeat
                Code := IncStr(Code);
                TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Posting Date", 20010129D);
            until ValueEntry.Next() = 0
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, '');
        end;
        // Raise workdate
        WorkDate := 20010201D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010202D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 21);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 21, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 31, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 41, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 51, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010203D;
        // Post purchase order as invoiced
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010204D;
        // Post sales order as invoiced
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010205D;

        GLSetup.Get();
        GLSetup."Allow Posting From" := WorkDate();
        GLSetup."Allow Posting To" := 0D;
        GLSetup.Modify();
        // The next tests must be executed manually
    end;

    local procedure CreateRevalJnl(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; ItemLocation: Code[10]; ItemVariant: Code[10]; RevalDate: Date; DocNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdateStandardCost: Boolean)
    var
        Item: Record Item;
        CalcInvValue: Report "Calculate Inventory Value";
    begin
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        if ItemNo <> '' then
            Item.SetRange("No.", ItemNo);
        if ItemLocation <> '' then
            Item.SetRange("Location Filter", ItemLocation);
        if ItemVariant <> '' then
            Item.SetRange("Variant Filter", ItemVariant);
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(RevalDate, DocNo, true, CalculatePer, ByLocation, ByVariant, UpdateStandardCost, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);
    end;

    local procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Text[250]): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;

    [Scope('OnPrem')]
    procedure FinishProdOrder(ProdOrder: Record "Production Order"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        ToProdOrder: Record "Production Order";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, NewPostingDate, NewUpdateUnitCost);
        WhseProdRelease.FinishedDelete(ToProdOrder);
    end;
}

