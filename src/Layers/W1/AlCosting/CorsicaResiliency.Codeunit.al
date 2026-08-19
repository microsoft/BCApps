codeunit 103424 Corsica_Resiliency
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        WMSTestscriptManagement.SetGlobalPreconditions();
        TestResultsPath := CostingTestScriptMgmt.GetTestResultsPath();
        "TCS-1-1"();
        // Calc Average Cost per Item no Item Groups used"TCS-1-2"();
        // Calc Average Cost per Item no posting to G/L"TCS-1-3"();
        // Calc Average Cost per Item Location and Variant"TCS-2-1"();
        // Calc Average Cost per Item"TCS-2-2"();
        // Calc Average Cost per Item & Location & Variant"TCS-3-1"();
        // Run Adjustment Batch Job per Item"TCS-3-2"();
        // Run Adjustment Batch Job per Item Category"TCS-4"();
        // Calculate Adjusted Cost for Items with fixed applied entries outbound"TCS-5"();
        // Calculate Adjusted Cost for Items with fixed applied entries inbound"TCS-6"();
        // Calculate Adjusted Cost for Items with negative inventory"TCS-7"();
        // Calculate Adjusted Cost for Items"TCS-9-1-1"();
        // Post per Value Entry Skip Posting Error"TCS-9-1-2"();
        // Post per Value Entry Skip Posting Error"TCS-9-1-5"();
        // Post per Value Entry Skip Posting Error"TCS-9-1-6"();
        // Post per Value Entry Skip Posting Error"TCS-9-2-1"();
        // Post per Posting Group Skip Posting Error"TCS-9-2-2"();
        // Post per Posting Group Skip Posting Error"TCS-9-2-4"();
        // Post per Posting Group Skip Posting Error"TCS-9-2-5"();  // Post per Posting Group Skip Posting Error

        // Manual Tests
        // GeneralPreparationTC8;    // TCS-8 General preparation for test cases TC-8-x
        // "TCS-9-1-4";  // Post per Value Entry Skip Posting Error
        // "TCS-9-2-3";  // Post per Posting Group Skip Posting Error
        // "TCS-10-1";   // Detect Posting Error, missing Inventory Posting Group
        // "TCS-10-2";   // Detect Posting Error, missing Gen. Product Posting Group
        // "TCS-10-3";   // Detect Posting Error, missing Account in Posting setup
        // "TCS-10-4";   // Detect Posting Error, Account Blocked
        // "TCS-10-5";   // Detect Posting Error, Dimension required
        // "TCS-10-6";   // Detect Posting Error, Dimension combination blocked
        // "TCS-10-7";   // Detect Posting Error, only one Dimension combination blocked

        CostingTestScriptMgmt.SetGlobalPreconditions();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        CurrTest: Text[80];
        TEXT001: Label 'Not found';
        TEXT002: Label '- Records in Table =';
        TEXT003: Label '- Adjusted Cost Amount Expected =';
        TEXT004: Label '- Test failed, Value Entry not found =';
        TEXT005: Label '- Adjusted Cost Posted to G/L =';
        TEXT006: Label '- Adjusted Expected Cost Posted to G/L =';
        TEXT007: Label '- Adjusted Cost Amount =';
        TestResultsPath: Text[250];
        TEXT008: Label '- Distinc Count =';

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Item: Record Item;
    begin
        Item.Get('6_AV_OV');
        Item.Validate("Indirect Cost %", 0);
        Item.Validate("Overhead Rate", 0);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 11, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('6_AV_OV', '', false);
        // Verify Results A-1
        Code := '103424-TC-1-1-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        if ValueEntry.FindFirst() then begin
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", -120);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 0);
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), ValueEntry."Cost Posted to G/L", -120);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT006), ValueEntry."Expected Cost Posted to G/L", 0);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 2, '', 22);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 22, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107002', 10000, '6_AV_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107002', 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        // Post purchase invoice
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('4_AV_RE', '', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-1-1-A2-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 1);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        if ValueEntry.FindFirst() then begin
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", -72);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 0);
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), ValueEntry."Cost Posted to G/L", -72);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT006), ValueEntry."Expected Cost Posted to G/L", 0);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS1-1', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-1.pdf');
        // Verify Results A-3
        Code := '103424-TC-1-1-A3-';
        RecordCount := GLEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, GLEntry.TableCaption(), TEXT002), RecordCount, 37);
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
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        // Post purchase order as received
        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('6_AV_OV', '', true);
        // Verify Results A-1
        Code := '103424-TC-1-2-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        if ValueEntry.FindFirst() then begin
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", 0);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), ValueEntry."Cost Posted to G/L", 0);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT006), ValueEntry."Expected Cost Posted to G/L", 0);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS1-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-2.pdf');
        // Verify Results A-2
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        if ValueEntry.FindFirst() then begin
            Code := '103424-TC-1-2-A2-';
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), ValueEntry."Cost Posted to G/L", 0);
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT006), ValueEntry."Expected Cost Posted to G/L", -120);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-3"()
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
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 200, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location RED
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 400);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 400, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 500, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 300, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 220);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 220, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location RED
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 420);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 420, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 510);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 510, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 210);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 210, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 320);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 320, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010127D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '61', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header for location RED
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '61', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 12, 'PCS', 1000);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 1000, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('6_AV_OV', '', false);
        // Verify Results A-1
        Code := '103424-TC-1-3-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 0);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        if ValueEntry.FindFirst() then begin
            Code := IncStr(Code);
            ValueEntry.SetRange("Location Code", 'BLUE');
            ValueEntry.SetRange("Variant Code", '');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
            Code := IncStr(Code);
            ValueEntry.SetRange("Variant Code", '61');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
            Code := IncStr(Code);
            ValueEntry.SetRange("Location Code", 'RED');
            ValueEntry.SetRange("Variant Code", '');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
            Code := IncStr(Code);
            ValueEntry.SetRange("Variant Code", '61');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        ValueEntry.Reset();
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 2, '', 22);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 22, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107003', 10000, '6_AV_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107003', 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        // Post purchase invoice
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('4_AV_RE', '', false);
        // Verify Results A-2
        Code := '103424-TC-1-3-A2-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 4);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        if ValueEntry.FindFirst() then begin
            Code := IncStr(Code);
            ValueEntry.SetRange("Location Code", 'BLUE');
            ValueEntry.SetRange("Variant Code", '');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -72);
            Code := IncStr(Code);
            ValueEntry.SetRange("Variant Code", '41');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2160);
            Code := IncStr(Code);
            ValueEntry.SetRange("Location Code", 'RED');
            ValueEntry.SetRange("Variant Code", '');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
            Code := IncStr(Code);
            ValueEntry.SetRange("Variant Code", '41');
            if ValueEntry.FindFirst() then;
            TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -3360);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        GLEntry: Record "G/L Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 11, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 1, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.SetExpCostPost(true);
        // Verify Results A-1
        Code := '103424-TC-1-4-A1-';
        RecordCount := PostValueEntryToGL.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntryToGL.TableCaption(), TEXT002), RecordCount, 5);
        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS1-4', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-1.pdf');
        // Verify Results A-2
        Code := '103424-TC-1-4-A2-';
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", 'TCS1-4');
        RecordCount := GLEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, GLEntry.TableCaption(), TEXT002), RecordCount, 3);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-1"()
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
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        SetItemCategory(true);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 200, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 7, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 220);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 220, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', 'FURNITURE', false);
        // Verify Results A-1
        Code := '103424-TC-2-1-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 3);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'A');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010127D);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010127D, 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 40, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 40, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 40, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 40, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 7, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 40, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 40, 'PCS', 220);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 220, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', 'MISC', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-2-1-A2-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 6);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'B');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -180);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -90);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -18);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-2"()
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
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        SetItemCategory(true);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 600);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 600, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 300);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 300, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 50, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location RED
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 2.5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 2.5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 90);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 90, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 190);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 190, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 500);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 500, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 20, 'PCS', 4);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 4, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 7, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 220);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 220, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 800);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 800, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 400);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 400, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 20, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 70, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location RED
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 4);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 4, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 550);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 550, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 250);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 250, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 20, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 65, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 20, 'PCS', 6);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 6, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '6_AV_OV', '61', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '4_AV_RE', '41', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '1_FI_RE', '11', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '2_LI_RA', '21', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header for location RED
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '6_AV_OV', '61', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '4_AV_RE', '41', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '1_FI_RE', '11', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '2_LI_RA', '21', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('', 'FURNITURE', false);
        // Verify Results A-1
        ValueEntry.Reset();
        Code := '103424-TC-2-2-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 10);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'A');
        ValueEntry.SetRange("Location Code", 'BLUE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        ValueEntry.SetRange("Location Code", 'BLUE');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '61');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1200);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '61');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -300);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        ValueEntry.SetRange("Location Code", 'BLUE');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '11');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1680);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -540);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '11');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -630);
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010127D);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010127D, 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 40, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 40, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 40, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 40, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 7, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 40, 'PCS', 110);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 110, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 40, 'PCS', 220);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 220, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 40, 'PCS', 800);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 800, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 40, 'PCS', 400);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 400, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 40, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 40, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 70, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location RED
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010127D);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010127D, 'RED', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 40, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 40, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 40, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 40, 'PCS', 4);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 4, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A', '', 40, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'B', '', 40, 'PCS', 200);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 200, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '6_AV_OV', '61', 40, 'PCS', 550);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 550, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '4_AV_RE', '41', 40, 'PCS', 250);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 250, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '1_FI_RE', '11', 40, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 65, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '2_LI_RA', '21', 40, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 6, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', 'MISC', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-2-2-A2-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 20);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'B');
        ValueEntry.SetRange("Location Code", 'BLUE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -180);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 30);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Location Code", 'BLUE');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -90);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '41');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -4140);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -90);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '41');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2490);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        ValueEntry.SetRange("Location Code", 'BLUE');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -18);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '21');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -720);
        Code := IncStr(Code);
        ValueEntry.SetRange("Location Code", 'RED');
        ValueEntry.SetRange("Variant Code", '');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 16.5);
        Code := IncStr(Code);
        ValueEntry.SetRange("Variant Code", '21');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -6);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C', '', 20, 'PCS', 4);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 4, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 8);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 8, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C', '', 20, 'PCS', 6);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 6, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create released production order
        CostingTestScriptMgmt.InsertProdOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, 'A', 8);
        ProdOrder.Validate("Location Code", 'BLUE');
        ProdOrder.Modify(true);

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        CostingTestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, WorkDate(), ProdOrder."No.", 'B', 10, 0);
        CostingTestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 20000, WorkDate(), ProdOrder."No.", 'C', 19, 0);

        CostingTestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, WorkDate(), ProdOrder."No.", 'A', 8);

        FinishProdOrder(ProdOrder, WorkDate(), false);

        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('2_LI_RA', '', false);
        // Verify Results A-1
        ValueEntry.Reset();
        Code := '103424-TC-3-1-A1-1-';
        ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 1);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -110);
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 2, '', 22);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 22, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107002', 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107002', 20000, '2_LI_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('A|B|C|1_FI_RE|5_ST_RA', '', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-3-1-A2-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 1);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -3);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'C');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", -16);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'A');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", 142);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        SetItemCategory(false);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C', '', 20, 'PCS', 4);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 4, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 5, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 8);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 8, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C', '', 20, 'PCS', 6);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 6, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create released production order
        CostingTestScriptMgmt.InsertProdOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, 'A', 9);
        ProdOrder.Validate("Location Code", 'BLUE');
        ProdOrder.Modify(true);

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        CostingTestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, WorkDate(), ProdOrder."No.", 'B', 12, 0);
        CostingTestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 20000, WorkDate(), ProdOrder."No.", 'C', 21, 0);

        CostingTestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, WorkDate(), ProdOrder."No.", 'A', 9);

        FinishProdOrder(ProdOrder, WorkDate(), false);

        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '6_AV_OV', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('', 'FURNITURE', false);
        // Verify Results A-1
        ValueEntry.Reset();
        Code := '103424-TC-3-2-A1-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 3);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'B');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", -3);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '6_AV_OV');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1);
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 2, '', 22);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 22, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107002', 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107002', 20000, '2_LI_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', 'MISC', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-3-2-A2-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 7);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'A');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", 167);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", 'C');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT007), ValueEntry."Cost Amount (Actual)", -20);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -60);
        Code := IncStr(Code);
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -132);
    end;

    [Scope('OnPrem')]
    procedure "TCS-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
        TempUnitCost: Decimal;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010128D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 13);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 13, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 60, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010130D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 1);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 2);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 3);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 4);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 5);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 6);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 7);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 10);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '2_LI_RA', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 8);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '2_LI_RA', '', 4, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 11);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 110000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 9);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 120000, SalesLine.Type::Item, '4_AV_RE', '', 4, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 12);
        SalesLine.Modify();

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise unit cost in purchase lines by 10 for the three purchase orders and post the orders as invoiced
        PurchHeader.Reset();
        if PurchHeader.Find('-') then
            repeat
                ReleasePurchDoc.Reopen(PurchHeader);
                PurchLine.Reset();
                PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
                if PurchLine.Find('-') then
                    repeat
                        TempUnitCost := PurchLine."Direct Unit Cost" + 10;
                        PurchLine.Validate(PurchLine."Direct Unit Cost", TempUnitCost);
                        PurchLine.Modify(true);
                    until PurchLine.Next() = 0;
                PurchHeader.Invoice := true;
                CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 50, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results
        ValueEntry.Reset();
        Code := '103424-TC-4-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 9);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);

        ValueEntry.SetRange("Cost Amount (Expected)", -20);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT008), ValueEntry.Count, 3);
        ValueEntry.SetRange("Cost Amount (Expected)", -30);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT008), ValueEntry.Count, 3);
        ValueEntry.SetRange("Cost Amount (Expected)", -40);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT008), ValueEntry.Count, 3);
    end;

    [Scope('OnPrem')]
    procedure "TCS-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempUnitCost: Decimal;
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 1, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010130D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 10);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 11);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 12);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise unit cost in lines of 2nd PO by 10 and post both orders as invoiced
        PurchHeader.Reset();
        if PurchHeader.Find('+') then
            ReleasePurchDoc.Reopen(PurchHeader);
        PurchLine.Reset();
        PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
        if PurchLine.Find('-') then
            repeat
                TempUnitCost := PurchLine."Direct Unit Cost" + 10;
                PurchLine.Validate(PurchLine."Direct Unit Cost", TempUnitCost);
                PurchLine.Modify(true);
            until PurchLine.Next() = 0;
        PurchHeader.Reset();
        if PurchHeader.Find('-') then
            repeat
                PurchHeader.Receive := false;
                PurchHeader.Invoice := true;
                CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results
        ValueEntry.Reset();
        Code := '103424-TC-5-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 6);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Item Ledger Entry No.", 12);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -120);
        ValueEntry.SetRange("Item Ledger Entry No.", 15);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 10);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        ValueEntry.SetRange("Item Ledger Entry No.", 10);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -11);
        ValueEntry.SetRange("Item Ledger Entry No.", 13);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 0.92);
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        ValueEntry.SetRange("Item Ledger Entry No.", 11);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -220);
        ValueEntry.SetRange("Item Ledger Entry No.", 14);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 18.33);
    end;

    [Scope('OnPrem')]
    procedure "TCS-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempUnitCost: Decimal;
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010127D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010128D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise unit cost in purchase lines by 10 for the two purchase orders and post the orders as invoiced
        PurchHeader.Reset();
        if PurchHeader.Find('-') then
            repeat
                ReleasePurchDoc.Reopen(PurchHeader);
                PurchLine.Reset();
                PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
                if PurchLine.Find('-') then
                    repeat
                        TempUnitCost := PurchLine."Direct Unit Cost" + 10;
                        PurchLine.Validate(PurchLine."Direct Unit Cost", TempUnitCost);
                        PurchLine.Modify(true);
                    until PurchLine.Next() = 0;
                PurchHeader.Receive := false;
                PurchHeader.Invoice := true;
                CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        ValueEntry.Reset();
        Code := '103424-TC-6-A1-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 6);
        ValueEntry.SetRange("Item No.", '4_AV_RE');
        ValueEntry.SetRange("Item Ledger Entry No.", 3);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 2.44);
        ValueEntry.SetRange("Item Ledger Entry No.", 9);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -33.53);
        ValueEntry.SetRange("Item No.", '1_FI_RE');
        ValueEntry.SetRange("Item Ledger Entry No.", 1);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -7.67);
        ValueEntry.SetRange("Item Ledger Entry No.", 7);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -94);
        ValueEntry.SetRange("Item No.", '2_LI_RA');
        ValueEntry.SetRange("Item Ledger Entry No.", 2);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -7.67);
        ValueEntry.SetRange("Item Ledger Entry No.", 8);
        Code := IncStr(Code);
        if ValueEntry.FindFirst() then;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -112);
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010124D);
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010124D, 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 5, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 3);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 3, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 10, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-6-A2-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 8);
        ValueEntry.Get(28);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 2.5);
        ValueEntry.Get(29);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 17.86);
    end;

    [Scope('OnPrem')]
    procedure "TCS-7"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempInventoryValue: Decimal;
        TempUnitCost: Decimal;
        ValueEntry: Record "Value Entry";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);

        WorkDate := 20010125D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010127D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 4);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 5);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, false);
        SalesLine.Validate("Appl.-to Item Entry", 6);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010128D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010129D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 1);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 2);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 100, 0, 3);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise unit cost in purchase lines by 10 for the two purchase orders and post the orders as invoiced
        PurchHeader.Reset();
        if PurchHeader.Find('-') then
            repeat
                ReleasePurchDoc.Reopen(PurchHeader);
                PurchLine.Reset();
                PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
                if PurchLine.Find('-') then
                    repeat
                        TempUnitCost := PurchLine."Direct Unit Cost" + 10;
                        PurchLine.Validate(PurchLine."Direct Unit Cost", TempUnitCost);
                        PurchLine.Modify(true);
                    until PurchLine.Next() = 0;
                PurchHeader.Receive := false;
                PurchHeader.Invoice := true;
                CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        ValueEntry.Reset();
        Code := '103424-TC-7-A1-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 12);
        ValueEntry.Get(25);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 2.44);
        ValueEntry.Get(26);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -10);
        ValueEntry.Get(27);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 4.89);
        ValueEntry.Get(28);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2.44);
        ValueEntry.Get(29);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -7.67);
        ValueEntry.Get(30);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -10);
        ValueEntry.Get(31);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -15.33);
        ValueEntry.Get(32);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 7.67);
        ValueEntry.Get(33);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -7.67);
        ValueEntry.Get(34);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -10);
        ValueEntry.Get(35);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -15.33);
        ValueEntry.Get(36);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", 7.67);
        // Raise inventory value of every item by 10 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '', '', '', 20010126D, '103424-TC-7', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                TempInventoryValue := ItemJnlLine."Inventory Value (Revalued)" + 10;
                ItemJnlLine.Validate("Inventory Value (Revalued)", TempInventoryValue);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        ValueEntry.Reset();
        Code := '103424-TC-7-A2-1-';
        ValueEntry.SetRange("Source Code", 'INVTADJMT');
        RecordCount := ValueEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT002), RecordCount, 18);
        // Only ILE No. 11 and 12 should be affected by the revaluation, and 1 should be added to the unit cost (Value Entries 40 and 41)
        ValueEntry.Get(40);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1);
        ValueEntry.Get(41);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2);
        ValueEntry.Get(42);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1);
        ValueEntry.Get(43);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2);
        ValueEntry.Get(44);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -1);
        ValueEntry.Get(45);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), ValueEntry."Cost Amount (Expected)", -2);
    end;

    [Scope('OnPrem')]
    procedure GeneralPreparationTC8()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        InvPostingSetup: Record "Inventory Posting Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        DefaultDim: Record "Default Dimension";
        DimCombination: Record "Dimension Combination";
        DimValueCombination: Record "Dimension Value Combination";
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 5, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 7, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        // Post sales order as shipped
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create new location BLUES
        Clear(Location);
        Location.Validate(Code, 'BLUES');
        if not Location.Insert(true) then;
        // Rename inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RAW MAT');
        InvPostingSetup.Rename('BLUES', 'RAW MAT');
        // Rename general product posting group entry
        GenProdPostingGroup.Init();
        GenProdPostingGroup.Code := 'RAW MATS';
        GenProdPostingGroup."Def. VAT Prod. Posting Group" := 'VAT25';
        GenProdPostingGroup."Auto Insert Default" := true;
        GenProdPostingGroup.Insert();

        Item.Get('A');
        Item.Validate("Gen. Prod. Posting Group", 'RAW MATS');
        Item.Modify();

        GenProdPostingGroup.Get('RAW MATS');
        GenProdPostingGroup.Delete();
        // Delete account no. from inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RESALE');
        InvPostingSetup.Validate("Inventory Account", '');
        InvPostingSetup.Modify(true);
        // Block G/L account
        GLAccount.Get('2110');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        GLAccount.Get('2130');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        GLAccount.Get('7291');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        // Change default dimensions for G/L account
        if not DefaultDim.Get(15, '7191', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7191');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;
        // Block dimension combination
        if not DimCombination.Get('AREA', 'DEPARTMENT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'DEPARTMENT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
            DimCombination.Insert(true);
        end;
        // Limit dimension combination
        if not DimCombination.Get('AREA', 'PROJECT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Limited);
            DimCombination.Insert(true);
        end;
        if not DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then begin
            DimValueCombination.Validate("Dimension 1 Code", 'AREA');
            DimValueCombination.Validate("Dimension 1 Value Code", '30');
            DimValueCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimValueCombination.Validate("Dimension 2 Value Code", 'VW');
            DimValueCombination.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GeneralPreparationTC9()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Location: Record Location;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(true);
        // Initialize workdate
        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 5, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        PurchHeader.FindFirst();
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 7);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 7, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        PurchHeader.FindFirst();
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 100, 0, false);

        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        SalesHeader.FindFirst();
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create new location BLUES
        Clear(Location);
        Location.Validate(Code, 'BLUES');
        if not Location.Insert(true) then;
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-1"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Rename inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RAW MAT');
        InvPostingSetup.Rename('BLUES', 'RAW MAT');
        Code := '103424-TCS-9-1-1-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-1-1.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 12);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-2"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Delete account no. from inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RESALE');
        InvPostingSetup.Validate("Inventory Account", '');
        InvPostingSetup.Modify(true);

        Code := '103424-TCS-9-1-2-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-1-2.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 2);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-3"()
    var
        DefaultDim: Record "Default Dimension";
        DimCombination: Record "Dimension Combination";
        DimValueCombination: Record "Dimension Value Combination";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();

        // Change default dimensions for G/L account
        if not DefaultDim.Get(15, '7191', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7191');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;

        // Block dimension combination
        if not DimCombination.Get('AREA', 'DEPARTMENT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'DEPARTMENT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
            DimCombination.Insert(true);
        end;

        // Limit dimension combination
        if not DimCombination.Get('AREA', 'PROJECT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Limited);
            DimCombination.Insert(true);
        end;
        if not DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then begin
            DimValueCombination.Validate("Dimension 1 Code", 'AREA');
            DimValueCombination.Validate("Dimension 1 Value Code", '30');
            DimValueCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimValueCombination.Validate("Dimension 2 Value Code", 'VW');
            DimValueCombination.Insert(true);
        end;

        Code := '103424-TCS-9-1-3-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-1-3.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-4"()
    var
        DefaultDim: Record "Default Dimension";
        DimCombination: Record "Dimension Combination";
        DimValueCombination: Record "Dimension Value Combination";
    begin
        GeneralPreparationTC9();

        // Change default dimensions for G/L account
        if not DefaultDim.Get(15, '7191', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7191');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;

        // Block dimension combination
        if not DimCombination.Get('AREA', 'DEPARTMENT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'DEPARTMENT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
            DimCombination.Insert(true);
        end;

        // Limit dimension combination
        if not DimCombination.Get('AREA', 'PROJECT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Limited);
            DimCombination.Insert(true);
        end;
        if not DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then begin
            DimValueCombination.Validate("Dimension 1 Code", 'AREA');
            DimValueCombination.Validate("Dimension 1 Value Code", '30');
            DimValueCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimValueCombination.Validate("Dimension 2 Value Code", 'VW');
            DimValueCombination.Insert(true);
        end;
        // Run REP1002 Post Inventory Cost to G/L
        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-5"()
    var
        GLAccount: Record "G/L Account";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Block G/L account
        GLAccount.Get('2130');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        GLAccount.Get('7291');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        Code := '103424-TCS-9-1-5-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-1-5.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 9);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-1-6"()
    var
        GLAccount: Record "G/L Account";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Block G/L account
        GLAccount.Get('2111');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        Code := '103424-TCS-9-1-6-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-1-6.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 6);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-2-1"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Rename inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RAW MAT');
        InvPostingSetup.Rename('BLUES', 'RAW MAT');

        Code := '103424-TCS-9-2-1-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS9-2-1', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-1.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 12);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-2-2"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Delete account no. from inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RESALE');
        InvPostingSetup.Validate("Inventory Account", '');
        InvPostingSetup.Modify(true);

        Code := '103424-TCS-9-2-2-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS9-2-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-2.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 2);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-2-3"()
    var
        DefaultDim: Record "Default Dimension";
        DimCombination: Record "Dimension Combination";
        DimValueCombination: Record "Dimension Value Combination";
    begin
        GeneralPreparationTC9();

        // Change default dimensions for G/L account
        if not DefaultDim.Get(15, '7191', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7191');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;

        // Block dimension combination
        if not DimCombination.Get('AREA', 'DEPARTMENT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'DEPARTMENT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
            DimCombination.Insert(true);
        end;

        // Limit dimension combination
        if not DimCombination.Get('AREA', 'PROJECT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Limited);
            DimCombination.Insert(true);
        end;
        if not DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then begin
            DimValueCombination.Validate("Dimension 1 Code", 'AREA');
            DimValueCombination.Validate("Dimension 1 Value Code", '30');
            DimValueCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimValueCombination.Validate("Dimension 2 Value Code", 'VW');
            DimValueCombination.Insert(true);
        end;

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS9-2-3', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-2.pdf');

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-2-4"()
    var
        GLAccount: Record "G/L Account";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Block G/L account
        GLAccount.Get('2130');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        GLAccount.Get('7291');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        Code := '103424-TCS-9-2-4-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS9-2-4', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-4.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 9);
    end;

    [Scope('OnPrem')]
    procedure "TCS-9-2-5"()
    var
        GLAccount: Record "G/L Account";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        "Code": Code[20];
        RecordCount: Integer;
    begin
        GeneralPreparationTC9();
        // Block G/L account
        GLAccount.Get('2111');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        Code := '103424-TCS-9-2-5-1';
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 24);

        // Run REP1002 Post Inventory Cost to G/L
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS9-2-5', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-5.pdf');

        Code := IncStr(Code);
        PostValueEntrytoGL.SetFilter("Posting Date", '<>%1', 11111111D);
        RecordCount := PostValueEntrytoGL.Count;
        PostValueEntrytoGL.Reset();
        TestscriptMgt.TestNumberValue(MakeName(Code, PostValueEntrytoGL.TableCaption(), TEXT002), RecordCount, 6);
    end;

    [Scope('OnPrem')]
    procedure GeneralPreparationTC10()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Location: Record Location;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 5, 0);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 5, 0);
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        // Create new location BLUES
        Clear(Location);
        Location.Validate(Code, 'BLUES');
        if not Location.Insert(true) then;
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-1"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        GeneralPreparationTC10();
        // Rename inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RAW MAT');
        InvPostingSetup.Rename('BLUES', 'RAW MAT');

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-2"()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
    begin
        GeneralPreparationTC10();
        // Rename general product posting group entry
        GenProdPostingGroup.Init();
        GenProdPostingGroup.Code := 'RAW MATS';
        GenProdPostingGroup."Def. VAT Prod. Posting Group" := 'VAT25';
        GenProdPostingGroup."Auto Insert Default" := true;
        GenProdPostingGroup.Insert();

        Item.Get('A');
        Item.Validate("Gen. Prod. Posting Group", 'RAW MATS');
        Item.Modify();

        GenProdPostingGroup.Get('RAW MATS');
        GenProdPostingGroup.Delete();

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-3"()
    var
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        GeneralPreparationTC10();
        // Delete account no. from inventory posting setup entry
        InvPostingSetup.Get('BLUE', 'RESALE');
        InvPostingSetup.Validate("Inventory Account", '');
        InvPostingSetup.Modify(true);

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-4"()
    var
        GLAccount: Record "G/L Account";
    begin
        GeneralPreparationTC10();
        // Block G/L account
        GLAccount.Get('2130');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        GLAccount.Get('7291');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-5"()
    var
        DefaultDim: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 5, 0);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 5, 0);
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        // Change default dimensions for G/L account
        if not DefaultDim.Get(15, '7191', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7191');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;
        if not DefaultDim.Get(15, '7190', 'DEPARTMENT') then begin
            DefaultDim.Validate("Table ID", 15);
            DefaultDim.Validate("No.", '7190');
            DefaultDim.Validate("Dimension Code", 'DEPARTMENT');
            DefaultDim.Validate("Dimension Value Code", 'ADM');
            DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
            DefaultDim.Insert(true);
        end;
        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-6"()
    var
        DimCombination: Record "Dimension Combination";
    begin
        GeneralPreparationTC10();

        // Block dimension combination
        if not DimCombination.Get('AREA', 'DEPARTMENT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'DEPARTMENT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
            DimCombination.Insert(true);
        end;

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
    end;

    [Scope('OnPrem')]
    procedure "TCS-10-7"()
    var
        DimCombination: Record "Dimension Combination";
        DimValueCombination: Record "Dimension Value Combination";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        SetPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(true);
        CostingTestScriptMgmt.SetExpCostPost(true);

        WorkDate := 20010125D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 20, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 5, 0);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        // Create purchase header for location BLUE
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B', '', 10, 'PCS', 5);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 5, 0);
        // Create sales header for location BLUE
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.ClearDimensions();
        CostingTestScriptMgmt.InsertDimension('AREA', '30', '');
        CostingTestScriptMgmt.InsertDimension('DEPARTMENT', 'ADM', '');
        CostingTestScriptMgmt.InsertDimension('PROJECT', 'VW', '');
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B', '', 12, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 100, 0, false);

        // Limit dimension combination
        if not DimCombination.Get('AREA', 'PROJECT') then begin
            DimCombination.Validate("Dimension 1 Code", 'AREA');
            DimCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Limited);
            DimCombination.Insert(true);
        end;
        if not DimValueCombination.Get('AREA', '30', 'PROJECT', 'VW') then begin
            DimValueCombination.Validate("Dimension 1 Code", 'AREA');
            DimValueCombination.Validate("Dimension 1 Value Code", '30');
            DimValueCombination.Validate("Dimension 2 Code", 'PROJECT');
            DimValueCombination.Validate("Dimension 2 Value Code", 'VW');
            DimValueCombination.Insert(true);
        end;

        // Post purchase order as received and invoiced

        // Verify result

        // Post sales order as shipped and invoiced

        // Verify result
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

    local procedure SetItemCategory("Average": Boolean)
    var
        Item: Record Item;
    begin
        if Average then begin
            Item.Get('1_FI_RE');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('2_LI_RA');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('4_AV_RE');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('6_AV_OV');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('A');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('B');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
        end else begin
            Item.Get('1_FI_RE');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Modify(true);
            Item.Get('2_LI_RA');
            Item.Validate("Item Category Code", 'MISC');
            Item.Modify(true);
            Item.Get('4_AV_RE');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('5_ST_RA');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Validate("Costing Method", Item."Costing Method"::Standard);
            Item.Modify(true);
            Item.Get('6_AV_OV');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Validate("Costing Method", Item."Costing Method"::Average);
            Item.Modify(true);
            Item.Get('A');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::FIFO);
            Item.Modify(true);
            Item.Get('B');
            Item.Validate("Item Category Code", 'FURNITURE');
            Item.Modify(true);
            Item.Get('C');
            Item.Validate("Item Category Code", 'MISC');
            Item.Validate("Costing Method", Item."Costing Method"::FIFO);
            Item.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetTestResultsPath(NewTestResultsPath: Text[250])
    begin
        TestResultsPath := NewTestResultsPath;
    end;
}

