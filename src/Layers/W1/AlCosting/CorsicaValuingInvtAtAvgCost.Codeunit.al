codeunit 103427 Corsica_ValuingInvtAtAvgCost
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        WMSTestscriptManagement.SetGlobalPreconditions();
        "TCS-1-1"();
        // Different Sources of Item/Value Increase for Average Cost Calculation Type Item & Location & Variant"TCS-1-2"();
        // Different Sources of Item/Value Increase for Average Cost Calculation Type Item"TCS-1-3"();
        // Manufacturing as source of Item/Value Increase/Decrease"TCS-1-4"();
        // Item Application"TCS-1-5"();
        // Revaluation"TCS-2-1"();
        // Change of Average Cost Period for Reopened Inventory Period"TCS-2-2"();
        // Change of Average Cost Period for Fiscal Year with closed Inventory Periods"TCS-2-3"();
        // Change of Avg. Cost Period and Avg. Calc. Type for Fiscal Year with closed Inventory Periods"TCS-3-1"();    // Automatic Cost Adjustment
    end;

    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        WMSSetGlobalPreconditions: Codeunit "WMS Set Global Preconditions";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CurrTest: Text[80];
        TEXT001: Label 'Not found';
        TEXT002: Label '- Records in Table =';
        TEXT003: Label '- Unit Cost =';
        TEXT004: Label '- Test failed, Item Ledger Entry not found =';
        TEXT005: Label '%1 - Adjusted Cost Amount (Expected) =';
        TEXT006: Label '%1 - Adjusted Cost Amount (Actual) =';

    [Scope('OnPrem')]
    procedure "TCS-1-1"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        // Initialize workdate
        WorkDate := 20010101D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-1-1', '6_AV_OV', '', 'BLUE', '', 10, 'PCS', 62.44444, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-1-1', '1_FI_RE', '', 'BLUE', '', 10, 'PCS', 12.33333, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-1-1', '4_AV_RE', '', 'BLUE', '', 10, 'PCS', 42.44444, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-1-1', '4_AV_RE', '41', 'BLUE', '', 10, 'PCS', 52.44444, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010124D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        SalesHeader2 := SalesHeader;
        // Raise workdate
        WorkDate := 20010125D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 30, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-1-1', '6_AV_OV', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-1-1', '1_FI_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-1-1', '4_AV_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-1-1', '4_AV_RE', '41', '', 'BLUE', 15, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-1-1-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 32);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    5, 25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.22);
                    6, 26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -142.43, 0);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1051.92);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1051.92);
                    // 1_FI_RE
                    7, 27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -12.33);
                    8, 28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -12.33, 0);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -150);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 150);
                    // 4_AV_RE, ''
                    9, 29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40.98);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -40.98, 0);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -600);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 600);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -40.98, 0);
                    // 4_AV_RE, 41
                    11, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -38.98);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -77.96, 0);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -77.95, 0);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -450);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 450);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 70.98958);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 71.21632);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 10.53885);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 39.0218);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 40.97714);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 38.97737);
        // Lower workdate
        WorkDate := 20010125D;
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 20, 70, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 20, 20, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 20, 45, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 20, 44, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Modify sales lines
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010124D;
        // Modify sales lines
        SalesHeader := SalesHeader2;
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-1-1-A2-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    5, 25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -77.9);
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -155.79);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1218.92);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1218.92);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -155.79);
                    // 1_FI_RE
                    7, 27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -12.33);
                    8, 28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -12.33);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 300);
                    // 4_AV_RE, ''
                    9, 29, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -43.98);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -43.98);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -675);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 675);
                    // 4_AV_RE, 41
                    11, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -47.38);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.76);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -660);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 660);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.75);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 78.59708);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 77.89632);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 18.23115);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.3738);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.97714);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 47.37737);
        // Raise workdate
        WorkDate := 20010128D;
        // Set Unit Cost (Revalued) of item 4_AV_RE to 60 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-1-1', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine.Validate("Unit Cost (Revalued)", 60);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 19, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 19, 19, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 21, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 21, 21, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 21, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 21, 21, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 19, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 19, 19, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-1-1-A3-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    5, 25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -77.9);
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -155.79);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1218.92);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1218.92);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -155.79);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -406.3);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1480.03);
                    // 1_FI_RE
                    7, 8, 27, 28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -12.33);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 300);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -374);
                    // 4_AV_RE, ''
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -43.98);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -43.98);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -675);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 919.31);
                    29, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -43.98);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1260);
                    // 4_AV_RE, 41
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -47.38);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.76);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -660);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 841.99);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -47.38);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.75);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1140);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 77.89632);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 77.89632);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 17.80952);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 60);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 60);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 60);
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-2"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        // Initialize workdate
        WorkDate := 20010101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010115D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 65, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 20, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010124D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 70, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 30, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Lower workdate
        WorkDate := 20010116D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-1', '6_AV_OV', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-1', '1_FI_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-1', '4_AV_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-1', '4_AV_RE', '41', '', 'BLUE', 15, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010119D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        SalesHeader2 := SalesHeader;
        // Raise workdate
        WorkDate := 20010121D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-1-2-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 37);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1079.76);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1079.76);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.98);
                    23, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -143.97, 0);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    25, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -500);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 500);
                    26, 28, 34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 76.20068);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 76.20068);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.52174);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        // Lower workdate
        WorkDate := 20010117D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-2', '6_AV_OV', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-2', '1_FI_RE', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-2', '4_AV_RE', '', 'BLUE', '', 5, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-2-2', '4_AV_RE', '41', 'BLUE', '', 14, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-1-2-A2-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 47);

        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1079.76);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1079.76);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.98);
                    23, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -143.97, 0);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1143.01);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1143.01);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    25, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -500);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 500);
                    26, 28, 34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -166.67);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 166.67);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -464.73);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 464.73);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 76.20068);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 76.20068);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.52174);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        // Raise workdate
        WorkDate := 20010120D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Modify sales lines
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify sales lines
        SalesHeader := SalesHeader2;
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        SalesHeader2 := SalesHeader;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-1-2-A3-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 51);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1068.62);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1068.62);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.24);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1115.59);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1115.59);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 25, 32, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -630);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 630);
                    26, 27, 28, 34, 35, 36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -42);
                    29, 37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -84);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -210);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 210);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -574.7);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 574.7);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 74.37266);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 74.37266);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.06061);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 41.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.05);
        // Lower workdate
        WorkDate := 20010107D;
        // Set Unit Cost (Revalued) of every item to 60 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-1-2', "Inventory Value Calc. Per"::Item, false, false, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine.Validate("Unit Cost (Revalued)", 60);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 34, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 34, 34, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 36, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 36, 36, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 31, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 31, 31, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 30, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 30, 30, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 30, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 30, 30, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 29, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 29, 29, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-4
        Code := '103427-TC-1-2-A4-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 59);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1068.62);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1068.62);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.24);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1115.59);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1115.59);
                    52:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2528.67);
                    56:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2231.18);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 25, 32, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    53:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -620);
                    57:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -440);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -780);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 780);
                    26, 27, 28, 34, 35, 36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -52);
                    29, 37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -104);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -260);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 260);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -700.7);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 700.7);
                    54:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1551.55);
                    55, 58:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1001);
                    59:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1451.45);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 74.37265);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 74.37265);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 17.22222);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 50.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50.05);
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        ItemLedgEntry: Record "Item Ledger Entry";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        Item: Record Item;
        CalcConsumption: Report "Calc. Consumption";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CreateFiscalYear(20010101D, 52, '<1W>');
        CreateFiscalYear(20011231D, 52, '<1W>');
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::"Accounting Period");
        // Accounting PeriodSetBOM();
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        // Initialize workdate
        WorkDate := 20010101D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-1', '1_FI_RE', '', 'BLUE', '', 30, 'PCS', 5, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-1', '4_AV_RE', '', 'BLUE', '', 30, 'PCS', 15, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-1', '4_AV_RE', '41', 'BLUE', '', 30, 'PCS', 20, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010107D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-2', '1_FI_RE', '', 'BLUE', '', 30, 'PCS', 10, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-2', '4_AV_RE', '', 'BLUE', '', 30, 'PCS', 25, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-2', '4_AV_RE', '41', 'BLUE', '', 30, 'PCS', 30, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010108D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-3', '1_FI_RE', '', 'BLUE', '', 30, 'PCS', 20, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-3', '4_AV_RE', '', 'BLUE', '', 30, 'PCS', 12, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-3-3', '4_AV_RE', '41', 'BLUE', '', 30, 'PCS', 17, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Create released production order
        Clear(ProdOrder);
        WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'A', 8, 'BLUE');
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        // Raise workdate
        WorkDate := 20010104D;
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
        ItemJnlLine.FindSet();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        ItemLedgEntry.FindLast();
        // Create negative consumption journal line
        ItemJnlLine.Reset();
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'CONSUMP', 'DEFAULT', 10000, WorkDate(), ItemJnlLine."Entry Type"::Consumption,
          ProdOrder."No.", '4_AV_RE', '', 'BLUE', '', -1, 'PCS', 0, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", 10000);
        ItemJnlLine.Validate("Source No.", 'A');
        ItemJnlLine.Validate("Applies-from Entry", ItemLedgEntry."Entry No." - 1);
        ItemJnlLine.Modify();
        // Post consumption
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.FindSet();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010105D;
        // Create consumption journal lines
        ProdOrder.Reset();
        ProdOrder.SetRange("Location Code", 'BLUE');
        ProdOrder.SetRange("Source No.", 'A');
        ProdOrder.FindFirst();
        Clear(CalcConsumption);
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
        // Post consumption
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.FindSet();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010108D;
        // Create output journal line
        ItemJnlLine.Reset();
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, WorkDate(), ItemJnlLine."Entry Type"::Output,
          ProdOrder."No.", 'A', '', 'BLUE', '', 8, 'PCS', 0, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", 10000);
        ItemJnlLine.Validate("Source No.", 'A');
        ItemJnlLine.Validate("Output Quantity", 8);
        ItemJnlLine.Modify();
        // Post output
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'OUTPUT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetRange("Line No.", 10000);
        ItemJnlLine.FindFirst();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Lower workdate
        WorkDate := 20010107D;
        ItemLedgEntry.FindLast();
        // Create output journal line
        ItemJnlLine.Reset();
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, WorkDate(), ItemJnlLine."Entry Type"::Output,
          ProdOrder."No.", 'A', '', 'BLUE', '', -1, 'PCS', 0, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", 10000);
        ItemJnlLine.Validate("Source No.", 'A');
        ItemJnlLine.Validate("Output Quantity", -1);
        ItemJnlLine.Validate("Applies-to Entry", ItemLedgEntry."Entry No.");
        ItemJnlLine.Modify();
        // Post output
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'OUTPUT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.FindFirst();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010109D;
        // Create output journal line
        ItemJnlLine.Reset();
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, WorkDate(), ItemJnlLine."Entry Type"::Output,
          ProdOrder."No.", 'A', '', 'BLUE', '', 1, 'PCS', 0, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", 10000);
        ItemJnlLine.Validate("Source No.", 'A');
        ItemJnlLine.Validate("Output Quantity", 1);
        ItemJnlLine.Modify();
        // Post output
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'OUTPUT');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetRange("Line No.", 10000);
        ItemJnlLine.FindFirst();
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Finish production order
        FinishProdOrder(ProdOrder, WorkDate(), false);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-1-3-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 17);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -50);
                    // 4_AV_RE, ''
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -380);
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 20);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -20);
                    // 4_AV_RE, 41
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -200);
                    // A
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 630);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -78.75);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 78.75);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 12.5);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 19.54248);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 16.61972);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 22.07317);
        Item.Get('A');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 78.75);
        // Raise workdate
        WorkDate := 20010110D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A', '', 8, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-1-3-A2-1-';
        if ExpResultItemLedgEntry.FindLast() then
            CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -630)
        else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-4"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TrackingSpecification: Record "Tracking Specification";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        ApplyFromEntryNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);

        Item.Get('6_AV_OV');
        Item."Item Tracking Code" := 'LOTALL';
        Item.Modify();
        // Initialize workdate
        WorkDate := 20010129D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 40, 0);
        // Add the following item tracking information to the line
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010203D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 45, 0);
        // Add the following item tracking information to the line
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        PurchHeader2 := PurchHeader;
        ItemLedgEntry.FindLast();
        // Raise workdate
        WorkDate := 20010130D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-4-1', '6_AV_OV', '', '', 'BLUE', 15, 'PCS', 0, 0);
        // Add the following item tracking information to the line
        CreateReservEntryFor(83, 4, 'RECLASS', 'DEFAULT', 0, ItemJnlLineNo, 1, 10, 10, '', 'LOTA');
        TrackingSpecification."Lot No." := 'LOTA';
        CreateReservEntry.SetNewTrackingFromNewTrackingSpecification(TrackingSpecification);
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(83, 4, 'RECLASS', 'DEFAULT', 0, ItemJnlLineNo, 1, 5, 5, '', 'LOTB');
        TrackingSpecification."Lot No." := 'LOTB';
        CreateReservEntry.SetNewTrackingFromNewTrackingSpecification(TrackingSpecification);
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);

        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-4-1', '4_AV_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-4-1', '4_AV_RE', '41', '', 'BLUE', 15, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010201D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        // Add the following item tracking information to the lines
        CreateReservEntry.SetApplyToEntryNo(ItemLedgEntry."Entry No." - 3);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 5, 5, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        // Add the following item tracking information to the lines
        CreateReservEntry.SetApplyToEntryNo(ItemLedgEntry."Entry No." - 2);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 5, 5, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No." - 1);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
        SalesLine.Modify();
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-1-4-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 20);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -664.17);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 664.17);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -332.08);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 332.08);
                    17, 18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -294.98);
                    // 4_AV_RE, ''
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -592.11);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 592.11);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -135);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 66.41667);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 66.41667);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 40.86667);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 39.474);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 42.29733);
        // Close inventory period
        HandleCloseInvtPeriod(20010131D, 'Close');
        // Raise workdate
        WorkDate := 20010203D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 55, 0);
        // Add the following item tracking information to the line
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ValueEntry.FindLast();
        // Lower workdate
        WorkDate := 20010202D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 55, 0);
        // Add the following item tracking information to the line
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Add the following item tracking information to the lines
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        ItemLedgEntry.FindLast();
        ApplyFromEntryNo := ItemLedgEntry."Entry No." - 4;
        // Undo Purchase Receipt
        PurchRcptLine.SetRange("Document No.", ValueEntry."Document No.");
        UndoPurchRcptLine.SetHideDialog(true);
        UndoPurchRcptLine.Run(PurchRcptLine);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Add the following item tracking information to the lines
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, '', 'LOTA');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, '', 'LOTB');
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-1-4-A2-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 41);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -664.17);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 664.17);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -332.08);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 332.08);
                    17, 18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -294.98);
                    29, 38, 39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.42);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.42);
                    34, 35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -422.96);
                    // 4_AV_RE, ''
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -592.11);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 592.11);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -78.95);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -900);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -78.95);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -135);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -42.3);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -84.59, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1100);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -126.89);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 68.03);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 68.53743);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.26971);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 45.48886);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 49.556);
        // Raise workdate
        WorkDate := 20010204D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        // Add the following item tracking information to the lines
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, SalesLine."Line No.", 1, 1, 1, '', 'LOTA');
        CreateReservEntry.SetApplyFromEntryNo(ApplyFromEntryNo);
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '6_AV_OV', '', 1, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        // Add the following item tracking information to the lines
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, SalesLine."Line No.", 1, 1, 1, '', 'LOTB');
        CreateReservEntry.SetApplyFromEntryNo(ApplyFromEntryNo);
        CreateReservEntry.CreateEntry('6_AV_OV', '', '', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 1, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, ApplyFromEntryNo);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '41', 2, 'PCS', 100);
        ApplyFromEntryNo := ApplyFromEntryNo + 1;
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo);
        // Post sales return order as received and invoiced
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-1-4-A3-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 46);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -664.17);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 664.17);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -332.08);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 332.08);
                    17, 18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -294.98);
                    29, 39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.42);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.42);
                    34, 35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -422.96);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.42);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 66.42);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 66.42);
                    // 4_AV_RE, ''
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -592.11);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 592.11);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -78.95);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -900);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -78.95);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 78.95);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -135);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -42.3);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -84.59, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1100);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -126.89);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 42.3);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 67.96292);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 68.53743);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.08327);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 45.48886);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 49.556);
        // Modify purchase lines
        PurchHeader := PurchHeader2;
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 20, 40, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 20, 40, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 20, 40, 0);
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-4
        Code := '103427-TC-1-4-A4-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 46);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -627.06);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 627.06);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -313.53);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 313.53);
                    17, 18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -239.31);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -62.71);
                    30, 39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -62.71);
                    34, 35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -422.96);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -62.71);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 62.71);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 62.71);
                    // 4_AV_RE, ''
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -521.05);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 521.05);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -69.47);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -900);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -69.47);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 69.47);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -120);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -80, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1100);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -120);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 40);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 65.79833);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 66.94714);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 42.823);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.45857);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 48.57143);
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-5"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', '', '41', 0);

        WorkDate := 20010101D;
        // Week 1
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);

        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010102D;
        // Week 1
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 55, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 55, 0);

        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010103D;
        // Week 1
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010101D;
        // Week 1
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 25, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        PurchHeader2 := PurchHeader;

        WorkDate := 20010110D;
        // Week 2
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-1', '6_AV_OV', '', '', 'BLUE', 25, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-1', '4_AV_RE', '', '', 'BLUE', 25, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-1', '4_AV_RE', '41', '', 'BLUE', 25, 'PCS', 0, 0);

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := 20010111D;
        // Week 2
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-2', '6_AV_OV', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-2', '4_AV_RE', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS1-5-2', '4_AV_RE', '41', 'BLUE', '', 15, 'PCS', 0, 0);

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        ItemLedgEntry.FindLast();

        WorkDate := 20010112D;
        // Week 2
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010115D;
        // Week 3
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 40, 0);

        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-1-5-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 33);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    7:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -673.45);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -336.72);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1683.62);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1683.62);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -855.11);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 855.11);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.04);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -375);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -187.5);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -937.5);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 937.5);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -508.93);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 508.93);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -169.64);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -475);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -237.5);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1187.5);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1187.5);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -616.07);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 616.07);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -205.36);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 62.2554);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 57.007);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 36.5);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.9285);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.0715);

        WorkDate := 20010112D;
        // Week 2
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No." - 4);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No." - 2);
        SalesLine.Modify();
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
        SalesLine.Modify();

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-1-5-A2-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 36);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    7:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -673.45);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -336.72);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1683.62);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1683.62);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -855.11);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 855.11);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.04);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -570.07);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -375);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -187.5);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -937.5);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 937.5);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -508.93);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 508.93);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -169.64);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -339.29);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -475);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -237.5);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1187.5);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1187.5);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -616.07);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 616.07);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -205.36);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -410.71);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 63.5675);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 57.007);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 36.25);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.9285);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.0715);

        WorkDate := 20010107D;
        // Week 1
        // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-1-5', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                if ItemJnlLine."Variant Code" = '41' then
                    ItemJnlLine.Validate("Unit Cost (Revalued)", 40)
                else
                    ItemJnlLine.Validate("Unit Cost (Revalued)", 30);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-1-5-A3-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -375);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -187.5);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -750);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 750);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -428.57);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 428.57);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.86);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.71);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -475);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -237.5);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1000);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -535.71);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 535.71);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -178.57);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -357.14);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 33.5715);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 28.5715);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 35.7145);

        WorkDate := 20010115D;
        // Week 3
        // Modify purchase lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 20, 55, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 20, 55, 0);

        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010101D;
        // Week 1
        // Modify purchase lines
        PurchHeader := PurchHeader2;
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 25, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 25, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 10, 25, 0);

        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);

        HandleCloseInvtPeriod(20010111D, 'Close');

        WorkDate := 20010114D;
        // Week 2
        // Set Unit Cost (Revalued) of every item to 55 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-1-5', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine.Validate("Unit Cost (Revalued)", 55);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;

        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-4
        Code := '103427-TC-1-5-A4-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -375);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -187.5);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -750);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1278.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -428.57);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 428.57);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.86);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.71);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -475);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -237.5);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1385.71);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -535.71);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 535.71);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -178.57);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -357.14);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 55);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 55);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 55);

        WorkDate := 20010117D;
        // Week 3
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);

        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-5
        Code := '103427-TC-1-5-A5-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    7:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -673.45);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -336.72);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1683.62);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1683.62);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -855.11);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 855.11);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.04);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -570.07);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1402.56);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1140.14);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -375);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -187.5);
                    18:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -750);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1278.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -428.57);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 428.57);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.86);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -285.71);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1100);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -475);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -237.5);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1385.71);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -535.71);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 535.71);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -178.57);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -357.14);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1100);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 57.007);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 57.007);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 55);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 55);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 55);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        // Initialize workdate
        WorkDate := 20010103D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20010101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010107D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 35, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010131D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 25, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 50, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010228D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 40, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010301D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 25);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 25, 0);
        // Post purchase order as received
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Lower workdate
        WorkDate := 20010129D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010201D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-2-1-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 27);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    1:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -20);
                    // 4_AV_RE
                    2, 3:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -312.5);
                    21, 23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.75);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.75, 0);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -67.5, 0);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -67.5);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -101.25);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 19.30233);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 30.80882);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 30.80882);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 30.80882);
        // Lower workdate
        WorkDate := 20010117D;
        // Close inventory period
        HandleCloseInvtPeriod(20010131D, 'Close');
        // Change Average Cost Period from week to day
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Day);
        // day
        // Raise workdate
        WorkDate := 20010217D;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-2-1-A2-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    1:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -100);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    25:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -20);
                    // 4_AV_RE
                    2, 3:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -350);
                    21, 23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -30);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -30, 0);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -60, 0);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -66.32);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -99.47);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 19.30233);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 30.49535);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 30.49535);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 30.49535);
        // Reopen inventory period
        HandleCloseInvtPeriod(20010131D, 'Reopen');
        // Change Average Cost Period from Day to Accounting Period (= Month)
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::"Accounting Period");
        // Accounting Period
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-2-1-A3-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 4_AV_RE
                    2:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -333.33);
                    3:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -333.33);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    26:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -67.65);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -101.48);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 30.57382);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-2"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RcptDocumentNo: Code[20];
        RcptDocumentNo2: Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        ApplyFromEntryNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        CreateFiscalYear(20020101D, 12, '<1M>');
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', '', '41', 0);
        // Create fiscal year per quarter
        CreateFiscalYear(20030101D, 4, '<3M>');
        // Initialize workdate
        WorkDate := 20021201D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ItemLedgEntry.FindLast();
        RcptDocumentNo := ItemLedgEntry."Document No.";
        // Raise workdate
        WorkDate := 20021223D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 50, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20021227D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 15, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 15, 15, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20021228D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20021229D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 70, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20021230D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 65, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 75);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 75, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 39);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 39, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 49);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 49, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20021231D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        ItemLedgEntry.FindLast();
        ApplyFromEntryNo := ItemLedgEntry."Entry No.";
        // Raise workdate
        WorkDate := 20030101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 80);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 80, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 90);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 90, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        ItemLedgEntry.FindLast();
        RcptDocumentNo2 := ItemLedgEntry."Document No.";
        // Raise workdate
        WorkDate := 20030104D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-1', '1_FI_RE', '', '', '', 30, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-1', '4_AV_RE', '', '', '', 30, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-1', '4_AV_RE', '41', '', '', 30, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20030105D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo - 2);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo - 1);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, ApplyFromEntryNo);
        // Post sales return order as received and invoiced
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20030106D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-2', '1_FI_RE', '', '', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-2', '4_AV_RE', '', '', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-2', '4_AV_RE', '41', '', '', 15, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20030331D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 17);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 17, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 37);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 37, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 47);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 47, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20030401D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 13);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 13, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 33);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 33, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 43);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 43, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-2-2-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 41);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    7, 10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -150);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -770);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -510);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -400);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.71);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1643.18);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 94.71);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.59);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -160);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -533.33);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -179.4);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2002.3);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 179.4);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1001.15);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 24.57143);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 49.35829);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 39);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 49);
        // Lower workdate
        WorkDate := 20021231D;
        // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-2-2', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange(ItemJnlLine."Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                case true of
                    (ItemJnlLine."Location Code" = 'BLUE') and (ItemJnlLine."Variant Code" = '41'):
                        begin
                            ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 50);
                            ItemJnlLine.Modify(true);
                        end;
                    (ItemJnlLine."Location Code" = 'BLUE') and (ItemJnlLine."Variant Code" = ''):
                        begin
                            ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 40);
                            ItemJnlLine.Modify(true);
                        end;
                    (ItemJnlLine."Location Code" = '') and (ItemJnlLine."Variant Code" = '41'):
                        begin
                            ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 45);
                            ItemJnlLine.Modify(true);
                        end;
                    else
                        ItemJnlLine.Delete();
                end;
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-2-2-A2-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -400);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.71);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1643.18);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 94.71);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.59);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -160);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -533.33);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -179.4);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1675.66);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 179.4);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -837.83);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 47.32263);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 40);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50);
        // Close inventory period
        HandleCloseInvtPeriod(20021231D, 'Close');
        CloseFiscalYear();
        CloseFiscalYear();
        CloseFiscalYear();
        // Raise workdate
        WorkDate := 20030330D;
        // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-2-2', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange(ItemJnlLine."Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                case true of
                    (ItemJnlLine."Location Code" = 'BLUE') or (ItemJnlLine."Variant Code" = ''):
                        ItemJnlLine.Delete();
                    (ItemJnlLine."Location Code" = '') and (ItemJnlLine."Variant Code" = '41'):
                        begin
                            ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 50);
                            ItemJnlLine.Modify(true);
                        end;
                    else begin
                        ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 40);
                        ItemJnlLine.Modify(true);
                    end;
                end;
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-2-2-A3-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -400);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.71);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1643.18);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 94.71);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.59);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -160);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -533.33);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -179.4);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1675.66);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 165.04);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -837.83);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 46.12307);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 40);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50);
        // Change Average Cost Period from week to Accounting Period (= Quarter)
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::"Accounting Period");
        // Accounting Period
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-4
        Code := '103427-TC-2-2-A4-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    7, 10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -150);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -770);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -510);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -400);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -94.71);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1544.44);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 94.71);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -772.22);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -160);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -533.33);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -179.4);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1626);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 165.04);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -813);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 24.57143);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 47.20893);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 40);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50);
        // Raise workdate
        WorkDate := 20030402D;
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 3, '', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 3, 100, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo, 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo, 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo, 30000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase invoice
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header for invoice
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);

        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 3, '', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 3, 100, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo2, 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo2, 20000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, RcptDocumentNo2, 30000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase invoice
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-5
        Code := '103427-TC-2-2-A5-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    7:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -225);
                    10:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -770);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -510);
                    // 4_AV_RE, ''
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -83.33);
                    11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -416.67);
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -97.06);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1594.44);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 97.06);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -797.22);
                    // 4_AV_RE, 41
                    9:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -165);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -550);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -182.91);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1676);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 168.55);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -838);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 26);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 48.22517);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 40);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50);
        // Raise workdate
        WorkDate := 20030601D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 70, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 70, 70, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 83, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 83, 83, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '41', 82, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 82, 82, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-6
        Code := '103427-TC-2-2-A6-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 46);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1820);
                    // 4_AV_RE, ''
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -4008.34);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -800);
                    // 4_AV_RE, 41
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -4077.82);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-2-3"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        ApplyFromEntryNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Never);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Month);
        // month
        CreateFiscalYear(20020101D, 12, '<1M>');
        CreateFiscalYear(20030101D, 12, '<1M>');
        // Initialize workdate
        WorkDate := 20021201D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 30, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 30, 30, 30, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20021231D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 70, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Lower workdate
        WorkDate := 20021202D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 25, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 25, 25, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 25, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 25, 25, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20021229D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20030101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20030103D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20030131D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 35, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Lower workdate
        WorkDate := 20021201D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 11);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 11, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 31);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 31, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 19);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 19, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 39);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 39, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20021203D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        ItemLedgEntry.FindLast();
        ApplyFromEntryNo := ItemLedgEntry."Entry No.";
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20030105D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo - 1);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, ApplyFromEntryNo);
        // Post sales return order as received and invoiced
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Lower workdate
        WorkDate := 20030101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20030102D;
        // Create item journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-3', '1_FI_RE', '', 'BLUE', '', 30, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'ITEM', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS2-2-3', '4_AV_RE', '', 'BLUE', '', 30, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20030103D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);

        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, ApplyFromEntryNo - 1);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, ApplyFromEntryNo);
        // Post sales return order as received and invoiced
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-1
        Code := '103427-TC-2-3-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 30);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    5:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    7, 11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -55);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -95);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -615);
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -91.32);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -93);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1072.11);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 31);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -117);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 62);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 21.45946);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 42.815);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 35.73625);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 38.15789);
        // Lower workdate
        WorkDate := 20021231D;
        // Set Unit Cost (Revalued) of item 4_AV_RE, location RED and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', 'RED', '', WorkDate(), '103427-TC-2-3', "Inventory Value Calc. Per"::Item, true, true, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange(ItemJnlLine."Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 50);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20030310D;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-2
        Code := '103427-TC-2-3-A2-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1000);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -80);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -91.32);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -93);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1072.11);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 31);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -117);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 62);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;

        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.21244);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 35.73625);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 48);
        // Close inventory period
        HandleCloseInvtPeriod(20021231D, 'Close');
        // Change Avg. Cost Calc. Type from Item & Location & Variant to Item
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-3
        Code := '103427-TC-2-3-A3-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -937.5);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -75);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -86.58);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -112.5);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1298.73);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 37.5);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -112.5);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;

        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 43.2909);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.2909);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.2909);
        // Change Average Cost Period from Month to Week
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-4
        Code := '103427-TC-2-3-A4-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.43);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -65.71);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -93.36);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1400.43);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 32.86);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 65.71);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 43.6859);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.6859);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.6859);
        CloseFiscalYear();
        CloseFiscalYear();
        CloseFiscalYear();
        // Change Avg. Cost Calc. Type from Item to Item & Location & Variant
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::"Item & Location & Variant");
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-5
        Code := '103427-TC-2-3-A5-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.43);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -65.71);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -107.98);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1257.96);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 32.86);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 65.71);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.325);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.93229);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.48781);
        // Change Average Cost Period from Week to Month
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Month);
        // month
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-6
        Code := '103427-TC-2-3-A6-1-';
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.43);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -65.71);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -93.65);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1257.96);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 32.86);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 65.71);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 45.50872);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.93229);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.48781);
        // Raise workdate
        WorkDate := 20030115D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 51, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 51, 51, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 51, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 51, 51, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 6, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 8, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 17, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 17, 17, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 19, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 19, 19, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Results A-7
        Code := '103427-TC-2-3-A7-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 36);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 1_FI_RE
                    5:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -300);
                    7, 11:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -40);
                    19:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -55);
                    21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -95);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -615);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1120);
                    33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -161);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -307);
                    // '', 4_AV_RE
                    6:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -821.43);
                    8:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -65.71);
                    12:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -93.65);
                    32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2387.95);
                    // BLUE, 4_AV_RE
                    20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    28:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1257.96);
                    30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 32.86);
                    34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -335.46);
                    // RED, 4_AV_RE
                    22:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -98.57);
                    24:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 65.71);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -826.27);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 21.96078);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 46.82255);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.9325);
        Code := IncStr(Code);
        SKU.Get('RED', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 43.48789);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-1"()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpResultItemLedgEntry: Record "Item Ledger Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        i: Integer;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Always);
        // always
        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        CostingTestScriptMgmt.SetAverageCostPeriod("Average Cost Period Type"::Week);
        // week
        WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE', 'BLUE', '41', 0);
        // Initialize workdate
        WorkDate := 20010101D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 40, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010115D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 65);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 65, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 20, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010124D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 70);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 70, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 35);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 35, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 30, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Lower workdate
        WorkDate := 20010116D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-1', '6_AV_OV', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-1', '1_FI_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-1', '4_AV_RE', '', '', 'BLUE', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-1', '4_AV_RE', '41', '', 'BLUE', 15, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010119D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        SalesHeader2 := SalesHeader;
        // Raise workdate
        WorkDate := 20010121D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Results A-1
        Code := '103427-TC-3-1-A1-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 37);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1079.76);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1079.76);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.98);
                    23, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -143.97, 0);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    25, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -500);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 500);
                    26, 28, 34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 76.20068);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 76.20068);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.52174);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        // Lower workdate
        WorkDate := 20010117D;
        // Create reclassification journal
        ItemJnlLineNo := 10000;
        CostingTestScriptMgmt.ClearDimensions();
        Clear(ItemJnlLine);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-2', '6_AV_OV', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-2', '1_FI_RE', '', 'BLUE', '', 15, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-2', '4_AV_RE', '', 'BLUE', '', 5, 'PCS', 0, 0);
        CostingTestScriptMgmt.InsertItemJnlLine(
          ItemJnlLine, 'RECLASS', 'DEFAULT', CostingTestScriptMgmt.GetNextNo(ItemJnlLineNo), WorkDate(),
          ItemJnlLine."Entry Type"::Transfer, 'TCS3-1-2', '4_AV_RE', '41', 'BLUE', '', 14, 'PCS', 0, 0);
        // Post item journal
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Verify Results A-2
        Code := '103427-TC-3-1-A2-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 47);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1079.76);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1079.76);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.98);
                    23, 31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -143.97, 0);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1143.01);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1143.01);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 32:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    25, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -10, 0);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -500);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 500);
                    26, 28, 34:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -33.33);
                    27:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    35:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -33.33, 0);
                    29:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, -66.67, 0);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -166.67);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 166.67);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -464.73);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 464.73);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 76.20068);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 76.20068);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.52174);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 33.19467);
        // Raise workdate
        WorkDate := 20010120D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 60);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 60, 0);
        // Post purchase order as received and invoiced
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Modify sales lines
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify sales lines
        SalesHeader := SalesHeader2;
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 100, 0, false);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        SalesHeader2 := SalesHeader;
        // Verify Results A-3
        Code := '103427-TC-3-1-A3-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 51);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1068.62);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1068.62);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.24);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1115.59);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1115.59);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 25, 32, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -630);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 630);
                    26, 27, 28, 34, 35, 36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -42);
                    29, 37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -84);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -210);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 210);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -574.7);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 574.7);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 74.37266);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 74.37266);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 16.06061);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 41.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 41.05);
        // Lower workdate
        WorkDate := 20010107D;
        // Set Unit Cost (Revalued) of every item to 60 and post the revaluation journal
        Clear(ItemJnlLine);
        CreateRevalJnl(ItemJnlLine, '4_AV_RE', '', '', WorkDate(), '103427-TC-3-1', "Inventory Value Calc. Per"::Item, false, false, false);
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange(ItemJnlLine."Journal Template Name", 'REVAL');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine.Validate(ItemJnlLine."Unit Cost (Revalued)", 60);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 34, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 34, 34, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 36, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 36, 36, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 31, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 31, 31, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 30, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 30, 30, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 30, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 30, 30, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 20, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '41', 29, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 29, 29, 100, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Results A-4
        Code := '103427-TC-3-1-A4-1-';
        RecordCount := ExpResultItemLedgEntry.Count;
        TestscriptMgt.TestNumberValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT002), RecordCount, 59);
        if ExpResultItemLedgEntry.FindSet() then begin
            i := 0;
            repeat
                i := i + 1;
                case i of
                    // 6_AV_OV
                    13:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1068.62);
                    14:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1068.62);
                    22, 30:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -71.24);
                    23:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    31:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -142.48);
                    38:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1115.59);
                    39:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 1115.59);
                    52:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2528.67);
                    56:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -2231.18);
                    // 1_FI_RE
                    15:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -175);
                    16:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 100);
                    17:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    24, 25, 32, 33:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -10);
                    40:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -215);
                    41:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 60);
                    42:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 75);
                    43:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 80);
                    53:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -620);
                    57:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -440);
                    // 4_AV_RE
                    18, 20:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -780);
                    19, 21:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 780);
                    26, 27, 28, 34, 35, 36:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -52);
                    29, 37:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -104);
                    44:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -260);
                    45:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 260);
                    46:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -700.7);
                    47:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, 700.7);
                    54:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1551.55);
                    55, 58:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1001);
                    59:
                        CheckItemLedgEntry(ExpResultItemLedgEntry, Code, 0, -1451.45);
                end;
            until ExpResultItemLedgEntry.Next() = 0;
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ExpResultItemLedgEntry.TableCaption(), TEXT004), TEXT001, TEXT001);
        end;
        Code := IncStr(Code);
        Item.Get('6_AV_OV');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 74.37265);
        Code := IncStr(Code);
        SKU.Get('BLUE', '6_AV_OV', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 74.37265);
        Code := IncStr(Code);
        Item.Get('1_FI_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 17.22222);
        Code := IncStr(Code);
        Item.Get('4_AV_RE');
        TestscriptMgt.TestNumberValue(MakeName(Code, Item.TableCaption(), TEXT003), Item."Unit Cost", 50.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50.05);
        Code := IncStr(Code);
        SKU.Get('BLUE', '4_AV_RE', '41');
        TestscriptMgt.TestNumberValue(MakeName(Code, SKU.TableCaption(), TEXT003), SKU."Unit Cost", 50.05);
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

    [Scope('OnPrem')]
    procedure CreateFiscalYear(FiscalYearStartDate: Date; NoOfPeriods: Integer; PeriodLengthTxt: Text[30])
    var
        AccountingPeriod: Record "Accounting Period";
        InvtSetup: Record "Inventory Setup";
        FirstPeriodStartDate: Date;
        PeriodLength: DateFormula;
        i: Integer;
        FirstPeriodLocked: Boolean;
    begin
        Evaluate(PeriodLength, PeriodLengthTxt);
        AccountingPeriod."Starting Date" := FiscalYearStartDate;
        AccountingPeriod.TestField("Starting Date");
        FirstPeriodStartDate := AccountingPeriod."Starting Date";
        InvtSetup.Get();

        AccountingPeriod.SetFilter("Starting Date", '>=%1', AccountingPeriod."Starting Date");
        AccountingPeriod.DeleteAll();
        AccountingPeriod.Reset();

        for i := 1 to NoOfPeriods + 1 do begin
            if (FiscalYearStartDate <= FirstPeriodStartDate) and (i = NoOfPeriods + 1) then
                exit;

            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := FiscalYearStartDate;
            AccountingPeriod.Validate("Starting Date");
            if (i = 1) or (i = NoOfPeriods + 1) then begin
                AccountingPeriod."New Fiscal Year" := true;
                AccountingPeriod."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type";
                AccountingPeriod."Average Cost Period" := InvtSetup."Average Cost Period";
            end;
            if (FirstPeriodStartDate = 0D) and (i = 1) then
                AccountingPeriod."Date Locked" := true;
            if (AccountingPeriod."Starting Date" < FirstPeriodStartDate) and FirstPeriodLocked then begin
                AccountingPeriod.Closed := true;
                AccountingPeriod."Date Locked" := true;
            end;
            if not AccountingPeriod.Find('=') then
                AccountingPeriod.Insert();
            FiscalYearStartDate := CalcDate(PeriodLength, FiscalYearStartDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBOM()
    var
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        WMSSetGlobalPreconditions.ModifyProdBOMHdr('A', ProdBOMHdr.Status::New);
        ProdBOMLine.SetRange("Production BOM No.", 'A');
        ProdBOMLine.DeleteAll();
        WMSSetGlobalPreconditions.InsertProdBOMLine('A', 10000, ProdBOMLine.Type::Item, '1_FI_RE', '', 1.25);
        WMSSetGlobalPreconditions.InsertProdBOMLine('A', 20000, ProdBOMLine.Type::Item, '4_AV_RE', '', 2.3);
        WMSSetGlobalPreconditions.InsertProdBOMLine('A', 30000, ProdBOMLine.Type::Item, '4_AV_RE', '41', 1);
        WMSSetGlobalPreconditions.ModifyProdBOMHdr('A', ProdBOMHdr.Status::Certified);
    end;

    local procedure HandleCloseInvtPeriod(EndingDate: Date; "Action": Code[10])
    var
        InventoryPeriod: Record "Inventory Period";
        CloseInventoryPeriod: Codeunit "Close Inventory Period";
    begin
        CloseInventoryPeriod.SetHideDialog(true);
        case Action of
            'Close':
                begin
                    InventoryPeriod."Ending Date" := EndingDate;
                    InventoryPeriod.Insert();
                    InventoryPeriod.FindLast();
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
            'Reopen':
                begin
                    InventoryPeriod.Get(EndingDate);
                    CloseInventoryPeriod.SetReOpen(true);
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
            'Reclose':
                begin
                    InventoryPeriod.Get(EndingDate);
                    CloseInventoryPeriod.Run(InventoryPeriod);
                end;
        end;
    end;

    local procedure CloseFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriod2: Record "Accounting Period";
        AccountingPeriod3: Record "Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
    begin
        // Copy of COD6
        AccountingPeriod2.SetRange(Closed, false);
        AccountingPeriod2.Find('-');

        FiscalYearStartDate := AccountingPeriod2."Starting Date";
        AccountingPeriod := AccountingPeriod2;
        AccountingPeriod.TestField("New Fiscal Year", true);

        AccountingPeriod2.SetRange("New Fiscal Year", true);
        if AccountingPeriod2.Find('>') then begin
            FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod2."Starting Date");

            AccountingPeriod3 := AccountingPeriod2;
            AccountingPeriod2.SetRange("New Fiscal Year");
            AccountingPeriod2.Find('<');
        end else
            Error(TEXT001);

        AccountingPeriod.Reset();

        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, AccountingPeriod2."Starting Date");
        AccountingPeriod.ModifyAll(Closed, true);

        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, AccountingPeriod3."Starting Date");
        AccountingPeriod.ModifyAll("Date Locked", true);

        AccountingPeriod.Reset();
    end;

    [Scope('OnPrem')]
    procedure CheckItemLedgEntry(TestItemLedgEntry: Record "Item Ledger Entry"; var "Code": Code[20]; ExpCostAmount: Decimal; ActCostAmount: Decimal)
    begin
        TestItemLedgEntry.SetRange("Cost Amount (Expected)", ExpCostAmount);
        TestItemLedgEntry.SetRange("Cost Amount (Actual)", ActCostAmount);
        if TestItemLedgEntry.FindFirst() then;

        TestItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, TestItemLedgEntry.TableCaption(), StrSubstNo(TEXT005, TestItemLedgEntry."Entry No.")), TestItemLedgEntry."Cost Amount (Expected)", ExpCostAmount);
        Code := IncStr(Code);
        TestscriptMgt.TestNumberValue(
          MakeName(Code, TestItemLedgEntry.TableCaption(), StrSubstNo(TEXT006, TestItemLedgEntry."Entry No.")), TestItemLedgEntry."Cost Amount (Actual)", ActCostAmount);
    end;

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

