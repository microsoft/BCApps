codeunit 103427 Corsica_ValuingInvtAtAvgCost
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        WMSTestscriptManagement.SetGlobalPreconditions;

        "TCS-1-1";    // Different Sources of Item/Value Increase for Average Cost Calculation Type Item & Location & Variant
        "TCS-1-2";    // Different Sources of Item/Value Increase for Average Cost Calculation Type Item
        "TCS-1-3";    // Manufacturing as source of Item/Value Increase/Decrease
        "TCS-1-4";    // Item Application
        "TCS-1-5";    // Revaluation
        "TCS-2-1";    // Change of Average Cost Period for Reopened Inventory Period
        "TCS-2-2";    // Change of Average Cost Period for Fiscal Year with closed Inventory Periods
        "TCS-2-3";    // Change of Avg. Cost Period and Avg. Calc. Type for Fiscal Year with closed Inventory Periods
        "TCS-3-1";    // Automatic Cost Adjustment
    end;

    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        TestscriptMgt: Codeunit Codeunit103001;
        CostingTestScriptMgmt: Codeunit Codeunit103492;
        WMSTestscriptManagement: Codeunit Codeunit103303;
        WMSSetGlobalPreconditions: Codeunit Codeunit103301;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          // Initialize workdate
          WORKDATE := 010101D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-1-1','6_AV_OV','','BLUE','',10,'PCS',62.44444,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-1-1','1_FI_RE','','BLUE','',10,'PCS',12.33333,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-1-1','4_AV_RE','','BLUE','',10,'PCS',42.44444,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-1-1','4_AV_RE','41','BLUE','',10,'PCS',52.44444,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 240101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          SalesHeader2 := SalesHeader;

          // Raise workdate
          WORKDATE := 250101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,10,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,40,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,30,0);
          END;

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 260101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-1-1','6_AV_OV','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-1-1','1_FI_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-1-1','4_AV_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-1-1','4_AV_RE','41','','BLUE',15,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);
          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-1-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,32);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  5,25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.22);
                  6,26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-142.43,0);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1051.92);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1051.92);
                  // 1_FI_RE
                  7,27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-12.33);
                  8,28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-12.33,0);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-150);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,150);
                  // 4_AV_RE, ''
                  9,29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40.98);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-40.98,0);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-600);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,600);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-40.98,0);
                  // 4_AV_RE, 41
                  11,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-38.98);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-77.96,0);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-77.95,0);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-450);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,450);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",70.98958);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",71.21632);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",10.53885);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",39.0218);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",40.97714);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",38.97737);

          // Lower workdate
          WORKDATE := 250101D;

          // Modify purchase lines
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);
          WITH PurchLine DO BEGIN
            ModifyPurchLine(PurchHeader,10000,0,20,70,0);
            ModifyPurchLine(PurchHeader,20000,0,20,20,0);
            ModifyPurchLine(PurchHeader,30000,0,20,45,0);
            ModifyPurchLine(PurchHeader,40000,0,20,44,0);
          END;

          // Post purchase order as invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 260101D;

          // Modify sales lines
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Ship := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Lower workdate
          WORKDATE := 240101D;

          // Modify sales lines
          SalesHeader := SalesHeader2;
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Ship := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-1-A2-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  5,25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-77.9);
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-155.79);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1218.92);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1218.92);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-155.79);
                  // 1_FI_RE
                  7,27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-12.33);
                  8,28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-12.33);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,300);
                  // 4_AV_RE, ''
                  9,29,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-43.98);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-43.98);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-675);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,675);
                  // 4_AV_RE, 41
                  11,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-47.38);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.76);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-660);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,660);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.75);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",78.59708);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",77.89632);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",18.23115);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.3738);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.97714);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",47.37737);

          // Raise workdate
          WORKDATE := 280101D;

          // Set Unit Cost (Revalued) of item 4_AV_RE to 60 and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-1-1',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Unit Cost (Revalued)",60);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Raise workdate
          WORKDATE := 300101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',19,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",19,19,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',21,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",21,21,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',21,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",21,21,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',19,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",19,19,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-1-A3-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  5,25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-77.9);
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-155.79);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1218.92);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1218.92);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-155.79);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-406.3);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1480.03);
                  // 1_FI_RE
                  7,8,27,28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-12.33);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,300);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-374);
                  // 4_AV_RE, ''
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-43.98);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-43.98);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-675);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,919.31);
                  29,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-43.98);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1260);
                  // 4_AV_RE, 41
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-47.38);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.76);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-660);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,841.99);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-47.38);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.75);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1140);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",77.89632);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",77.89632);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",17.80952);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",60);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",60);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",60);
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostCalcType(1);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          // Initialize workdate
          WORKDATE := 010101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,10,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 150101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',65);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,65,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,15,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,40,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,20,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 240101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',70);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,70,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',5,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,35,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',5,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,30,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Lower workdate
          WORKDATE := 160101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-1','6_AV_OV','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-1','1_FI_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-1','4_AV_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-1','4_AV_RE','41','','BLUE',15,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 190101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          SalesHeader2 := SalesHeader;

          // Raise workdate
          WORKDATE := 210101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-2-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,37);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1079.76);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1079.76);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.98);
                  23,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-143.97,0);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  25,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-500);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,500);
                  26,28,34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",76.20068);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",76.20068);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.52174);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);

          // Lower workdate
          WORKDATE := 170101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-2','6_AV_OV','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-2','1_FI_RE','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-2','4_AV_RE','','BLUE','',5,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-2-2','4_AV_RE','41','BLUE','',14,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-2-A2-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,47);

            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1079.76);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1079.76);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.98);
                  23,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-143.97,0);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1143.01);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1143.01);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  25,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-500);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,500);
                  26,28,34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-166.67);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,166.67);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-464.73);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,464.73);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",76.20068);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",76.20068);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.52174);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);

          // Raise workdate
          WORKDATE := 200101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,15,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,50,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // Modify sales lines
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Ship := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Modify sales lines
          SalesHeader := SalesHeader2;
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          SalesHeader2 := SalesHeader;

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-2-A3-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,51);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1068.62);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1068.62);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.24);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1115.59);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1115.59);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,25,32,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-630);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,630);
                  26,27,28,34,35,36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-42);
                  29,37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-84);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-210);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,210);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-574.7);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,574.7);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",74.37266);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",74.37266);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.06061);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",41.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.05);

          // Lower workdate
          WORKDATE := 070101D;

          // Set Unit Cost (Revalued) of every item to 60 and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-1-2',1,FALSE,FALSE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Unit Cost (Revalued)",60);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Raise workdate
          WORKDATE := 300101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',34,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",34,34,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',36,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",36,36,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',31,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",31,31,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',30,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",30,30,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',30,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",30,30,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',29,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",29,29,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-2-A4-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,59);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1068.62);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1068.62);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.24);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1115.59);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1115.59);
                  52:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2528.67);
                  56:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2231.18);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,25,32,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  53:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-620);
                  57:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-440);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-780);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,780);
                  26,27,28,34,35,36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-52);
                  29,37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-104);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-260);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,260);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-700.7);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,700.7);
                  54:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1551.55);
                  55,58:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1001);
                  59:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1451.45);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",74.37265);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",74.37265);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",17.22222);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",50.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50.05);
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          CreateFiscalYear(010101D,52,'<1W>');
          CreateFiscalYear(311201D,52,'<1W>');
          SetAverageCostPeriod(6); // Accounting Period
          SetBOM;
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          // Initialize workdate
          WORKDATE := 010101D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-1','1_FI_RE','','BLUE','',30,'PCS',5,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-1','4_AV_RE','','BLUE','',30,'PCS',15,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-1','4_AV_RE','41','BLUE','',30,'PCS',20,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 070101D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-2','1_FI_RE','','BLUE','',30,'PCS',10,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-2','4_AV_RE','','BLUE','',30,'PCS',25,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-2','4_AV_RE','41','BLUE','',30,'PCS',30,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 080101D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-3','1_FI_RE','','BLUE','',30,'PCS',20,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-3','4_AV_RE','','BLUE','',30,'PCS',12,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-3-3','4_AV_RE','41','BLUE','',30,'PCS',17,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Create released production order
          CLEAR(ProdOrder);
          WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'A',8,'BLUE');
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          // Raise workdate
          WORKDATE := 040101D;

          // Create consumption journal lines
          ProdOrder.Reset();
          ProdOrder.SETRANGE("Location Code",'BLUE');
          ProdOrder.SETRANGE("Source No.",'A');
          ProdOrder.FindFirst();
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          // Post consumption
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'CONSUMP');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.FindSet();
          ItemJnlPostBatch(ItemJnlLine);

          ItemLedgEntry.FindLast();

          // Create negative consumption journal line
          ItemJnlLine.Reset();
          InsertItemJnlLine(
            ItemJnlLine,'CONSUMP','DEFAULT',10000,WORKDATE,ItemJnlLine."Entry Type"::Consumption,
            ProdOrder."No.",'4_AV_RE','','BLUE','',-1,'PCS',0,0);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Order Line No.",10000);
          ItemJnlLine.VALIDATE("Source No.",'A');
          ItemJnlLine.VALIDATE("Applies-from Entry",ItemLedgEntry."Entry No." - 1);
          ItemJnlLine.Modify();

          // Post consumption
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'CONSUMP');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.FindSet();
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 050101D;

          // Create consumption journal lines
          ProdOrder.Reset();
          ProdOrder.SETRANGE("Location Code",'BLUE');
          ProdOrder.SETRANGE("Source No.",'A');
          ProdOrder.FindFirst();
          CLEAR(CalcConsumption);
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          // Post consumption
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'CONSUMP');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.FindSet();
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 080101D;

          // Create output journal line
          ItemJnlLine.Reset();
          InsertItemJnlLine(
            ItemJnlLine,'OUTPUT','DEFAULT',10000,WORKDATE,ItemJnlLine."Entry Type"::Output,
            ProdOrder."No.",'A','','BLUE','',8,'PCS',0,0);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Order Line No.",10000);
          ItemJnlLine.VALIDATE("Source No.",'A');
          ItemJnlLine.VALIDATE("Output Quantity",8);
          ItemJnlLine.Modify();

          // Post output
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'OUTPUT');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.SETRANGE("Line No.",10000);
          ItemJnlLine.FindFirst();
          ItemJnlPostBatch(ItemJnlLine);

          // Lower workdate
          WORKDATE := 070101D;
          ItemLedgEntry.FindLast();

          // Create output journal line
          ItemJnlLine.Reset();
          InsertItemJnlLine(
            ItemJnlLine,'OUTPUT','DEFAULT',10000,WORKDATE,ItemJnlLine."Entry Type"::Output,
            ProdOrder."No.",'A','','BLUE','',-1,'PCS',0,0);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Order Line No.",10000);
          ItemJnlLine.VALIDATE("Source No.",'A');
          ItemJnlLine.VALIDATE("Output Quantity",-1);
          ItemJnlLine.VALIDATE("Applies-to Entry",ItemLedgEntry."Entry No.");
          ItemJnlLine.Modify();

          // Post output
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'OUTPUT');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.FindFirst();
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 090101D;

          // Create output journal line
          ItemJnlLine.Reset();
          InsertItemJnlLine(
            ItemJnlLine,'OUTPUT','DEFAULT',10000,WORKDATE,ItemJnlLine."Entry Type"::Output,
            ProdOrder."No.",'A','','BLUE','',1,'PCS',0,0);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Order Line No.",10000);
          ItemJnlLine.VALIDATE("Source No.",'A');
          ItemJnlLine.VALIDATE("Output Quantity",1);
          ItemJnlLine.Modify();

          // Post output
          ItemJnlLine.Reset();
          ItemJnlLine.SETRANGE("Journal Template Name",'OUTPUT');
          ItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.SETRANGE("Line No.",10000);
          ItemJnlLine.FindFirst();
          ItemJnlPostBatch(ItemJnlLine);

          // Finish production order
          FinishProdOrder(ProdOrder,WORKDATE,FALSE);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-3-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,17);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-50);
                  // 4_AV_RE, ''
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-380);
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,20);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-20);
                  // 4_AV_RE, 41
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-200);
                  // A
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,630);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-78.75);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,78.75);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",12.5);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",19.54248);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",16.61972);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",22.07317);
          Item.GET('A');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",78.75);

          // Raise workdate
          WORKDATE := 100101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'A','',8,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",8,8,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-3-A2-1-';
            IF FindLast() then
              CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-630)
            else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
        END;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1-4"()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
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
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        "Code": Code[20];
        RecordCount: Integer;
        ItemJnlLineNo: Integer;
        ApplyFromEntryNo: Integer;
        i: Integer;
    begin
        // Test case will not run with parallel G/L posting
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use Legacy G/L Entry Locking" := TRUE;
        GeneralLedgerSetup.MODIFY(TRUE);

        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          Item.GET('6_AV_OV');
          Item."Item Tracking Code" := 'LOTALL';
          Item.Modify();

          // Initialize workdate
          WORKDATE := 290101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,40,0);
          END;

          // Add the following item tracking information to the line
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 030201D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,50,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,50,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',45);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,45,0);
          END;

          // Add the following item tracking information to the line
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

          // Post purchase order as received
          PostPurchOrder(PurchHeader);
          PurchHeader2 := PurchHeader;
          ItemLedgEntry.FindLast();

          // Raise workdate
          WORKDATE := 300101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-4-1','6_AV_OV','','','BLUE',15,'PCS',0,0);

          // Add the following item tracking information to the line
          CreateRes.CreateReservEntryFor(83,4,'RECLASS','DEFAULT',0,ItemJnlLineNo,1,10,10,'','LOTA','');
          CreateRes.SetNewSerialLotNo('','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(83,4,'RECLASS','DEFAULT',0,ItemJnlLineNo,1,5,5,'','LOTB','');
          CreateRes.SetNewSerialLotNo('','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-4-1','4_AV_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-4-1','4_AV_RE','41','','BLUE',15,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 010201D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            // Add the following item tracking information to the lines
            CreateRes.SetApplyToEntryNo(ItemLedgEntry."Entry No." - 3);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,5,5,'','LOTA','');
            CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'6_AV_OV','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            // Add the following item tracking information to the lines
            CreateRes.SetApplyToEntryNo(ItemLedgEntry."Entry No." - 2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,5,5,'','LOTB','');
            CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            GET(SalesHeader."Document Type",SalesHeader."No.","Line No.");
            VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No." - 1);
            Modify();
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
            GET(SalesHeader."Document Type",SalesHeader."No.","Line No.");
            VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No.");
            Modify();
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-4-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,20);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-664.17);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,664.17);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-332.08);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,332.08);
                  17,18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-294.98);
                  // 4_AV_RE, ''
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-592.11);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,592.11);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  // 4_AV_RE, 41
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-634.46);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,634.46);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-135);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",66.41667);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",66.41667);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",40.86667);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",39.474);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",42.29733);

          // Close inventory period
          HandleCloseInvtPeriod(310101D,'Close');

          // Raise workdate
          WORKDATE := 030201D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,35,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',45);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,45,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',55);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,55,0);
          END;

          // Add the following item tracking information to the line
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','BLUE','',250101D,0D,0,2);

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          ValueEntry.FindLast();

          // Lower workdate
          WORKDATE := 020201D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,50,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',55);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,55,0);
          END;

          // Add the following item tracking information to the line
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','BLUE','',250101D,0D,0,2);

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Add the following item tracking information to the lines
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          ItemLedgEntry.FindLast();
          ApplyFromEntryNo := ItemLedgEntry."Entry No." - 4;

          // Undo Purchase Receipt
          PurchRcptLine.SETRANGE("Document No.",ValueEntry."Document No.");
          UndoPurchRcptLine.SetHideDialog(TRUE);
          UndoPurchRcptLine.RUN(PurchRcptLine);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Add the following item tracking information to the lines
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LOTA','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LOTB','');
          CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-4-A2-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,41);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-664.17);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,664.17);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-332.08);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,332.08);
                  17,18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-294.98);
                  29,38,39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.42);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.42);
                  34,35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-422.96);
                  // 4_AV_RE, ''
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-592.11);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,592.11);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-78.95);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-900);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-78.95);
                  // 4_AV_RE, 41
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-634.46);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,634.46);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-135);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-42.3);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-84.59,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1100);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-126.89);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",68.03);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",68.53743);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.26971);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",45.48886);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",49.556);

          // Raise workdate
          WORKDATE := 040201D;

          // Create sales return order header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',1,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",1,1,100,0,0);
            // Add the following item tracking information to the lines
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,"Line No.",1,1,1,'','LOTA','');
            CreateRes.SetApplyFromEntryNo(ApplyFromEntryNo);
            CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'6_AV_OV','',1,'PCS',100);
            ApplyFromEntryNo := ApplyFromEntryNo + 1;
            ModifySalesReturnLine(SalesHeader,"Line No.",1,1,100,0,0);
            // Add the following item tracking information to the lines
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,"Line No.",1,1,1,'','LOTB','');
            CreateRes.SetApplyFromEntryNo(ApplyFromEntryNo);
            CreateRes.CreateEntry('6_AV_OV','','','',250101D,0D,0,2);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ApplyFromEntryNo := ApplyFromEntryNo + 1;
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',1,'PCS',100);
            ApplyFromEntryNo := ApplyFromEntryNo + 1;
            ModifySalesReturnLine(SalesHeader,"Line No.",1,1,100,0,ApplyFromEntryNo);
            InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'4_AV_RE','41',2,'PCS',100);
            ApplyFromEntryNo := ApplyFromEntryNo + 1;
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo);
          END;

          // Post sales return order as received and invoiced
          SalesHeader.Receive := TRUE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-4-A3-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,46);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-664.17);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,664.17);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-332.08);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,332.08);
                  17,18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-294.98);
                  29,39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.42);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.42);
                  34,35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-422.96);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.42);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,66.42);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,66.42);
                  // 4_AV_RE, ''
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-592.11);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,592.11);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-78.95);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-900);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-78.95);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,78.95);
                  // 4_AV_RE, 41
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-634.46);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,634.46);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-135);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-42.3);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-84.59,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1100);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-126.89);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,42.3);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,84.59);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",67.96292);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",68.53743);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.08327);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",45.48886);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",49.556);

          // Modify purchase lines
          PurchHeader := PurchHeader2;
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);
          WITH PurchLine DO BEGIN
            ModifyPurchLine(PurchHeader,10000,0,20,40,0);
            ModifyPurchLine(PurchHeader,20000,0,20,40,0);
            ModifyPurchLine(PurchHeader,30000,0,20,40,0);
          END;

          // Post purchase order as invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-4-A4-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,46);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-627.06);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,627.06);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-313.53);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,313.53);
                  17,18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-239.31);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-62.71);
                  30,39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-62.71);
                  34,35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-422.96);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-62.71);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,62.71);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,62.71);
                  // 4_AV_RE, ''
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-521.05);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,521.05);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-69.47);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-900);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-69.47);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,69.47);
                  // 4_AV_RE, 41
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-600);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,600);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-120);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-80,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1100);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-120);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,40);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",65.79833);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",66.94714);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",42.823);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.45857);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",48.57143);
        END;

        // Clean-up
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use Legacy G/L Entry Locking" := FALSE;
        GeneralLedgerSetup.MODIFY(TRUE);
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','','41',0);

          WORKDATE := 010101D; // Week 1

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 020101D; // Week 1

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',55);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,55,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',45);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,45,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',55);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,55,0);
          END;

          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 030101D; // Week 1

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          WORKDATE := 010101D; // Week 1

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',25);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,25,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',25);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,25,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',25);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,25,0);
          END;

          PostPurchOrder(PurchHeader);
          PurchHeader2 := PurchHeader;

          WORKDATE := 100101D; // Week 2

          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-1','6_AV_OV','','','BLUE',25,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-1','4_AV_RE','','','BLUE',25,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-1','4_AV_RE','41','','BLUE',25,'PCS',0,0);

          ItemJnlPostBatch(ItemJnlLine);

          WORKDATE := 110101D; // Week 2

          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-2','6_AV_OV','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-2','4_AV_RE','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS1-5-2','4_AV_RE','41','BLUE','',15,'PCS',0,0);

          ItemJnlPostBatch(ItemJnlLine);

          ItemLedgEntry.FindLast();

          WORKDATE := 120101D; // Week 2

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          WORKDATE := 150101D; // Week 3

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,40,0);
          END;

          PostPurchOrder(PurchHeader);

          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-5-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,33);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  7:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-673.45);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-336.72);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1683.62);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1683.62);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-855.11);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,855.11);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.04);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-375);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-187.5);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-937.5);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,937.5);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-508.93);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,508.93);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-169.64);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-475);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-237.5);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1187.5);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1187.5);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-616.07);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,616.07);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-205.36);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",62.2554);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",57.007);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",36.5);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.9285);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.0715);

          WORKDATE := 120101D; // Week 2

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            GET(SalesHeader."Document Type",SalesHeader."No.","Line No.");
            VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No." - 4);
            Modify();
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            GET(SalesHeader."Document Type",SalesHeader."No.","Line No.");
            VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No." - 2);
            Modify();
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            GET(SalesHeader."Document Type",SalesHeader."No.","Line No.");
            VALIDATE("Appl.-to Item Entry",ItemLedgEntry."Entry No.");
            Modify();
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-5-A2-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,36);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  7:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-673.45);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-336.72);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1683.62);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1683.62);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-855.11);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,855.11);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.04);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-570.07);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-375);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-187.5);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-937.5);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,937.5);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-508.93);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,508.93);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-169.64);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-339.29);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-475);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-237.5);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1187.5);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1187.5);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-616.07);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,616.07);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-205.36);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-410.71);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",63.5675);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",57.007);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",36.25);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.9285);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.0715);

          WORKDATE := 070101D; // Week 1

          // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-1-5',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                IF "Variant Code" = '41' THEN
                  VALIDATE("Unit Cost (Revalued)",40)
                else
                  VALIDATE("Unit Cost (Revalued)",30);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          ItemJnlPostBatch(ItemJnlLine);

          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-5-A3-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-375);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-187.5);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-750);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,750);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-428.57);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,428.57);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.86);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.71);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-475);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-237.5);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1000);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-535.71);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,535.71);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-178.57);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-357.14);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",33.5715);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",28.5715);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",35.7145);

          WORKDATE := 150101D; // Week 3

          // Modify purchase lines
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);
          WITH PurchLine DO BEGIN
            ModifyPurchLine(PurchHeader,20000,0,20,55,0);
            ModifyPurchLine(PurchHeader,30000,0,20,55,0);
          END;

          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 010101D; // Week 1

          // Modify purchase lines
          PurchHeader := PurchHeader2;
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
          WITH PurchLine DO BEGIN
            ModifyPurchLine(PurchHeader,10000,0,10,25,0);
            ModifyPurchLine(PurchHeader,20000,0,10,25,0);
            ModifyPurchLine(PurchHeader,30000,0,10,25,0);
          END;

          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          AdjustItem('','',FALSE);

          HandleCloseInvtPeriod(110101D,'Close');

          WORKDATE := 140101D; // Week 2

          // Set Unit Cost (Revalued) of every item to 55 and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-1-5',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Unit Cost (Revalued)",55);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          ItemJnlPostBatch(ItemJnlLine);

          AdjustItem('','',FALSE);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-5-A4-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-375);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-187.5);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-750);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1278.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-428.57);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,428.57);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.86);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.71);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-475);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-237.5);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1385.71);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-535.71);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,535.71);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-178.57);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-357.14);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",55);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",55);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",55);

          WORKDATE := 170101D; // Week 3

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
          END;

          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          AdjustItem('','',FALSE);

          // Verify Results A-5
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-1-5-A5-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  7:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-673.45);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-336.72);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1683.62);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1683.62);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-855.11);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,855.11);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.04);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-570.07);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1402.56);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1140.14);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-375);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-187.5);
                  18:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-750);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1278.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-428.57);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,428.57);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.86);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-285.71);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1100);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-475);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-237.5);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1385.71);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-535.71);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,535.71);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-178.57);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-357.14);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1100);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",57.007);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",57.007);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",55);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",55);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",55);
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostCalcType(1);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          // Initialize workdate
          WORKDATE := 030101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Lower workdate
          WORKDATE := 010101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,10,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 070101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,35,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 310101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,30,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',25);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,25,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,50,0);
          END;

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 280201D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,10,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,40,0);
          END;

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 010301D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,20,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,15,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',25);
            ModifyPurchLine(PurchHeader,"Line No.",20,0,25,0);
          END;

          // Post purchase order as received
          PostPurchOrder(PurchHeader);

          // Lower workdate
          WORKDATE := 290101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 010201D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-1-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,27);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  1:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-20);
                  // 4_AV_RE
                  2,3:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-312.5);
                  21,23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.75);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.75,0);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-67.5,0);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-67.5);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-101.25);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",19.30233);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",30.80882);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",30.80882);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",30.80882);

          // Lower workdate
          WORKDATE := 170101D;

          // Close inventory period
          HandleCloseInvtPeriod(310101D,'Close');

          // Change Average Cost Period from week to day
          SetAverageCostPeriod(1); // day

          // Raise workdate
          WORKDATE := 170201D;

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-1-A2-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  1:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-100);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  25:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-20);
                  // 4_AV_RE
                  2,3:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-350);
                  21,23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-30);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-30,0);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-60,0);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-66.32);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-99.47);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",19.30233);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",30.49535);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",30.49535);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",30.49535);

          // Reopen inventory period
          HandleCloseInvtPeriod(310101D,'Reopen');

          // Change Average Cost Period from Day to Accounting Period (= Month)
          SetAverageCostPeriod(6); // Accounting Period

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-1-A3-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 4_AV_RE
                  2:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-333.33);
                  3:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-333.33);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  26:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-67.65);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-101.48);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",30.57382);
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostPeriod(2); // week
          CreateFiscalYear(010102D,12,'<1M>');
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','','41',0);

          // Create fiscal year per quarter
          CreateFiscalYear(010103D,4,'<3M>');

          // Initialize workdate
          WORKDATE := 011202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,10,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          ItemLedgEntry.FindLast();
          RcptDocumentNo := ItemLedgEntry."Document No.";

          // Raise workdate
          WORKDATE := 231202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,50,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 271202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',15,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",15,15,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 281202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",10,10,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 291202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',70);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,70,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 301202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,35,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',65);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,65,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',75);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,75,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',20,'PCS',39);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,39,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','41',20,'PCS',49);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,49,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 311202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          ItemLedgEntry.FindLast();
          ApplyFromEntryNo := ItemLedgEntry."Entry No.";

          // Raise workdate
          WORKDATE := 010103D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,80,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',90);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,90,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          ItemLedgEntry.FindLast();
          RcptDocumentNo2 := ItemLedgEntry."Document No.";

          // Raise workdate
          WORKDATE := 040103D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-1','1_FI_RE','','','',30,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-1','4_AV_RE','','','',30,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-1','4_AV_RE','41','','',30,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 050103D;

          // Create sales return order header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo - 2);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo - 1);
            InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",3,3,100,0,ApplyFromEntryNo);
          END;

          // Post sales return order as received and invoiced
          SalesHeader.Receive := TRUE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 060103D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-2','1_FI_RE','','','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-2','4_AV_RE','','','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-2','4_AV_RE','41','','',15,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 310303D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',17);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,17,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',37);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,37,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',47);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,47,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 010403D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',13);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,13,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',33);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,33,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',20,'PCS',43);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,43,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,41);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  7,10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-150);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-770);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-510);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-400);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.71);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1643.18);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,94.71);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.59);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-160);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-533.33);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-179.4);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2002.3);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,179.4);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1001.15);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",24.57143);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",49.35829);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",39);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",49);

          // Lower workdate
          WORKDATE := 311202D;

          // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-2-2',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                CASE TRUE OF
                  ("Location Code" = 'BLUE') and ("Variant Code" = '41'):
                    BEGIN
                      VALIDATE("Unit Cost (Revalued)",50);
                      MODIFY(TRUE);
                    END;
                  ("Location Code" = 'BLUE') and ("Variant Code" = ''):
                    BEGIN
                      VALIDATE("Unit Cost (Revalued)",40);
                      MODIFY(TRUE);
                    END;
                  ("Location Code" = '') and ("Variant Code" = '41'):
                    BEGIN
                      VALIDATE("Unit Cost (Revalued)",45);
                      MODIFY(TRUE);
                    END;
                  else
                    DELETE;
                END;
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A2-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-400);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.71);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1643.18);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,94.71);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.59);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-160);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-533.33);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-179.4);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1675.66);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,179.4);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-837.83);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",47.32263);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",40);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50);

          // Close inventory period
          HandleCloseInvtPeriod(311202D,'Close');

          // Close fiscal years incl. 2002
          CloseFiscalYear;
          CloseFiscalYear;
          CloseFiscalYear;

          // Raise workdate
          WORKDATE := 300303D;

          // Set Unit Cost (Revalued) of item 4_AV_RE and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-2-2',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                CASE TRUE OF
                  ("Location Code" = 'BLUE') or ("Variant Code" = ''):
                    DELETE;
                  ("Location Code" = '') and ("Variant Code" = '41'):
                    BEGIN
                      VALIDATE("Unit Cost (Revalued)",50);
                      MODIFY(TRUE);
                    END;
                  else BEGIN
                    VALIDATE("Unit Cost (Revalued)",40);
                    MODIFY(TRUE);
                  END;
                END;
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A3-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-400);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.71);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1643.18);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,94.71);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.59);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-160);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-533.33);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-179.4);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1675.66);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,165.04);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-837.83);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",46.12307);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",40);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50);

          // Change Average Cost Period from week to Accounting Period (= Quarter)
          SetAverageCostPeriod(6); // Accounting Period

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A4-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  7,10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-150);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-770);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-510);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-400);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-94.71);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1544.44);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,94.71);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-772.22);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-160);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-533.33);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-179.4);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1626);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,165.04);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-813);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",24.57143);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",47.20893);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",40);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50);

          // Raise workdate
          WORKDATE := 020403D;

          // Create purchase header for invoice
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::"Charge (Item)",'UPS','',3,'',100);
            ModifyPurchLine(PurchHeader,"Line No.",3,3,100,0);
          END;

          // Assign item charges to receipt lines
          PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Invoice);
          PurchLine.SETRANGE("Document No.",PurchHeader."No.");
          PurchLine.SETRANGE("Line No.",10000);
          PurchLine.FindFirst();
          InsertPurchChargeAssignLine(PurchLine,10000,6,RcptDocumentNo,10000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
          InsertPurchChargeAssignLine(PurchLine,20000,6,RcptDocumentNo,20000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
          InsertPurchChargeAssignLine(PurchLine,30000,6,RcptDocumentNo,30000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);

          // Post purchase invoice
          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Create purchase header for invoice
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::"Charge (Item)",'UPS','',3,'',100);
            ModifyPurchLine(PurchHeader,"Line No.",3,3,100,0);
          END;

          // Assign item charges to receipt lines
          PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Invoice);
          PurchLine.SETRANGE("Document No.",PurchHeader."No.");
          PurchLine.SETRANGE("Line No.",10000);
          PurchLine.FindFirst();
          InsertPurchChargeAssignLine(PurchLine,10000,6,RcptDocumentNo2,10000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
          InsertPurchChargeAssignLine(PurchLine,20000,6,RcptDocumentNo2,20000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
          InsertPurchChargeAssignLine(PurchLine,30000,6,RcptDocumentNo2,30000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);

          // Post purchase invoice
          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-5
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A5-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  7:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-225);
                  10:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-770);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-510);
                  // 4_AV_RE, ''
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-83.33);
                  11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-416.67);
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-97.06);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1594.44);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,97.06);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-797.22);
                  // 4_AV_RE, 41
                  9:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-165);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-550);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-182.91);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1676);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,168.55);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-838);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",26);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",48.22517);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",40);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50);

          // Raise workdate
          WORKDATE := 010603D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',70,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",70,70,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',83,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",83,83,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',82,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",82,82,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','41',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-6
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-2-A6-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,46);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1820);
                  // 4_AV_RE, ''
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-4008.34);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-800);
                  // 4_AV_RE, 41
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-4077.82);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(0);
          SetAverageCostPeriod(3); // month
          CreateFiscalYear(010102D,12,'<1M>');
          CreateFiscalYear(010103D,12,'<1M>');

          // Initialize workdate
          WORKDATE := 011202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,10,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',30,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",30,30,30,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 311202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',10,'PCS',70);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,70,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Lower workdate
          WORKDATE := 021202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',25,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",25,25,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',25,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",25,25,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 291202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 010103D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 030103D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 310103D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,15,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,35,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Lower workdate
          WORKDATE := 011202D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',11);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,11,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',31);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,31,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'RED','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',19);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,19,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',39);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,39,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 031202D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          ItemLedgEntry.FindLast();
          ApplyFromEntryNo := ItemLedgEntry."Entry No.";

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'RED',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,5,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Raise workdate
          WORKDATE := 050103D;

          // Create sales return order header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'RED',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo - 1);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',2,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",2,2,100,0,ApplyFromEntryNo);
          END;

          // Post sales return order as received and invoiced
          SalesHeader.Receive := TRUE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Lower workdate
          WORKDATE := 010103D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 020103D;

          // Create item journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-3','1_FI_RE','','BLUE','',30,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS2-2-3','4_AV_RE','','BLUE','',30,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 030103D;

          // Create sales return order header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",1,1,100,0,ApplyFromEntryNo - 1);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',1,'PCS',100);
            ModifySalesReturnLine(SalesHeader,"Line No.",1,1,100,0,ApplyFromEntryNo);
          END;

          // Post sales return order as received and invoiced
          SalesHeader.Receive := TRUE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,30);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  5:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  7,11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-55);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-95);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-615);
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-91.32);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-93);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1072.11);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,31);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-117);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,62);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",21.45946);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",42.815);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",35.73625);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",38.15789);

          // Lower workdate
          WORKDATE := 311202D;

          // Set Unit Cost (Revalued) of item 4_AV_RE, location RED and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','RED','',WORKDATE,'103427-TC-2-3',1,TRUE,TRUE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Unit Cost (Revalued)",50);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 100303D;

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A2-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1000);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-80);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-91.32);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-93);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1072.11);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,31);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-117);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,62);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;

          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.21244);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",35.73625);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",48);

          // Close inventory period
          HandleCloseInvtPeriod(311202D,'Close');

          // Change Avg. Cost Calc. Type from Item & Location & Variant to Item
          SetAverageCostCalcType(1);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A3-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-937.5);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-75);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-86.58);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-112.5);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1298.73);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,37.5);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-112.5);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;

          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",43.2909);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.2909);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.2909);

          // Change Average Cost Period from Month to Week
          SetAverageCostPeriod(2); // week

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A4-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.43);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-65.71);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-93.36);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1400.43);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,32.86);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,65.71);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",43.6859);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.6859);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.6859);

          // Close fiscal years incl. 2002
          CloseFiscalYear;
          CloseFiscalYear;
          CloseFiscalYear;

          // Change Avg. Cost Calc. Type from Item to Item & Location & Variant
          SetAverageCostCalcType(2);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-5
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A5-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.43);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-65.71);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-107.98);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1257.96);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,32.86);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,65.71);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.325);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.93229);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.48781);

          // Change Average Cost Period from Week to Month
          SetAverageCostPeriod(3); // month

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-6
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A6-1-';
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.43);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-65.71);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-93.65);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1257.96);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,32.86);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,65.71);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",45.50872);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.93229);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.48781);

          // Raise workdate
          WORKDATE := 150103D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',51,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",51,51,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',51,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",51,51,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',6,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",6,6,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',8,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",8,8,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'RED',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',17,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",17,17,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',19,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",19,19,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // Verify Results A-7
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-2-3-A7-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,36);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 1_FI_RE
                  5:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-300);
                  7,11:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-40);
                  19:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-55);
                  21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-95);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-615);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1120);
                  33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-161);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-307);
                  // '', 4_AV_RE
                  6:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-821.43);
                  8:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-65.71);
                  12:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-93.65);
                  32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2387.95);
                  // BLUE, 4_AV_RE
                  20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  28:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1257.96);
                  30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,32.86);
                  34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-335.46);
                  // RED, 4_AV_RE
                  22:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-98.57);
                  24:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,65.71);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-826.27);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",21.96078);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",46.82255);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.9325);
          Code := INCSTR(Code);
          SKU.GET('RED','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",43.48789);
        END;
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
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetAutoCostPost(FALSE);
          SetExpCostPost(FALSE);
          SetAutoCostAdjmt(6); // always
          SetAverageCostCalcType(1);
          SetAverageCostPeriod(2); // week
          WMSSetGlobalPreconditions.MaintStockKeepUnit('4_AV_RE','BLUE','41',0);

          // Initialize workdate
          WORKDATE := 010101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,10,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,30,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,40,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 150101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',65);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,65,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,15,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',40);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,40,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,20,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Raise workdate
          WORKDATE := 240101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',70);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,70,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,20,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',5,'PCS',35);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,35,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',5,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,30,0);
          END;

          // Post purchase order as received and invoiced
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // Lower workdate
          WORKDATE := 160101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-1','6_AV_OV','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-1','1_FI_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-1','4_AV_RE','','','BLUE',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-1','4_AV_RE','41','','BLUE',15,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 190101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          SalesHeader2 := SalesHeader;

          // Raise workdate
          WORKDATE := 210101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',7,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,1,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Verify Results A-1
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-3-1-A1-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,37);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1079.76);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1079.76);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.98);
                  23,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-143.97,0);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  25,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-500);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,500);
                  26,28,34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",76.20068);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",76.20068);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.52174);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);

          // Lower workdate
          WORKDATE := 170101D;

          // Create reclassification journal
          ItemJnlLineNo := 10000;
          ClearDimensions;
          CLEAR(ItemJnlLine);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-2','6_AV_OV','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-2','1_FI_RE','','BLUE','',15,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-2','4_AV_RE','','BLUE','',5,'PCS',0,0);
          InsertItemJnlLine(
            ItemJnlLine,'RECLASS','DEFAULT',GetNextNo(ItemJnlLineNo),WORKDATE,
            ItemJnlLine."Entry Type"::Transfer,'TCS3-1-2','4_AV_RE','41','BLUE','',14,'PCS',0,0);

          // Post item journal
          ItemJnlPostBatch(ItemJnlLine);

          // Verify Results A-2
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-3-1-A2-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,47);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1079.76);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1079.76);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.98);
                  23,31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-143.97,0);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1143.01);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1143.01);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,32:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  25,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-10,0);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-500);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,500);
                  26,28,34:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-33.33);
                  27:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  35:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-33.33,0);
                  29:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,-66.67,0);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-166.67);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,166.67);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-464.73);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,464.73);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",76.20068);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",76.20068);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.52174);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",33.19467);

          // Raise workdate
          WORKDATE := 200101D;

          // Create purchase header
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          // Create purchase lines
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,15,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,50,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,60,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // Modify sales lines
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as invoiced
          SalesHeader.Ship := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Modify sales lines
          SalesHeader := SalesHeader2;
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,TRUE);
          WITH SalesLine DO BEGIN
            ModifySalesLine(SalesHeader,10000,0,2,100,0,FALSE);
            ModifySalesLine(SalesHeader,20000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,30000,0,1,100,0,FALSE);
            ModifySalesLine(SalesHeader,40000,0,2,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);
          SalesHeader2 := SalesHeader;

          // Verify Results A-3
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-3-1-A3-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,51);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1068.62);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1068.62);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.24);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1115.59);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1115.59);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,25,32,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-630);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,630);
                  26,27,28,34,35,36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-42);
                  29,37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-84);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-210);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,210);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-574.7);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,574.7);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",74.37266);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",74.37266);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",16.06061);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",41.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",41.05);

          // Lower workdate
          WORKDATE := 070101D;

          // Set Unit Cost (Revalued) of every item to 60 and post the revaluation journal
          CLEAR(ItemJnlLine);
          CreateRevalJnl(ItemJnlLine,'4_AV_RE','','',WORKDATE,'103427-TC-3-1',1,FALSE,FALSE,FALSE);
          WITH ItemJnlLine DO BEGIN
            Reset();
            SETRANGE("Journal Template Name",'REVAL');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Unit Cost (Revalued)",60);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          // Post revaluation journal lines
          ItemJnlPostBatch(ItemJnlLine);

          // Raise workdate
          WORKDATE := 300101D;

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',34,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",34,34,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',36,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",36,36,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',31,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",31,31,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Create sales header
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'',TRUE,FALSE);

          // Create sales lines
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',30,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",30,30,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',30,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",30,30,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",20,20,100,0,FALSE);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','41',29,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",29,29,100,0,FALSE);
          END;

          // Post sales order as shipped and invoiced
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          // Verify Results A-4
          WITH ExpResultItemLedgEntry DO BEGIN
            Code := '103427-TC-3-1-A4-1-';
            RecordCount := COUNT;
            TestscriptMgt.TestNumberValue(MakeName(Code,TABLECAPTION,TEXT002),RecordCount,59);
            IF FindSet() then BEGIN
              i := 0;
              REPEAT
                i := i + 1;
                CASE i OF
                  // 6_AV_OV
                  13:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1068.62);
                  14:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1068.62);
                  22,30:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-71.24);
                  23:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  31:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-142.48);
                  38:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1115.59);
                  39:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,1115.59);
                  52:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2528.67);
                  56:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-2231.18);
                  // 1_FI_RE
                  15:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-175);
                  16:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,100);
                  17:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  24,25,32,33:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-10);
                  40:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-215);
                  41:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,60);
                  42:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,75);
                  43:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,80);
                  53:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-620);
                  57:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-440);
                  // 4_AV_RE
                  18,20:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-780);
                  19,21:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,780);
                  26,27,28,34,35,36:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-52);
                  29,37:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-104);
                  44:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-260);
                  45:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,260);
                  46:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-700.7);
                  47:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,700.7);
                  54:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1551.55);
                  55,58:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1001);
                  59:
                    CheckItemLedgEntry(ExpResultItemLedgEntry,Code,0,-1451.45);
                END;
              until Next() = 0;
            END else BEGIN
              Code := INCSTR(Code);
              TestscriptMgt.TestTextValue(MakeName(Code,TABLECAPTION,TEXT004),TEXT001,TEXT001);
            END;
          END;
          Code := INCSTR(Code);
          Item.GET('6_AV_OV');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",74.37265);
          Code := INCSTR(Code);
          SKU.GET('BLUE','6_AV_OV','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",74.37265);
          Code := INCSTR(Code);
          Item.GET('1_FI_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",17.22222);
          Code := INCSTR(Code);
          Item.GET('4_AV_RE');
          TestscriptMgt.TestNumberValue(MakeName(Code,Item.TableCaption(),TEXT003),Item."Unit Cost",50.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50.05);
          Code := INCSTR(Code);
          SKU.GET('BLUE','4_AV_RE','41');
          TestscriptMgt.TestNumberValue(MakeName(Code,SKU.TableCaption(),TEXT003),SKU."Unit Cost",50.05);
        END;
    end;

    local procedure CreateRevalJnl(var ItemJnlLine: Record "Item Journal Line";ItemNo: Code[20];ItemLocation: Code[10];ItemVariant: Code[10];RevalDate: Date;DocNo: Code[20];CalculatePer: Integer;ByLocation: Boolean;ByVariant: Boolean;UpdateStandardCost: Boolean)
    var
        Item: Record Item;
        CalcInvValue: Report "Calculate Inventory Value";
    begin
        Commit();
        CLEAR(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        IF ItemNo <> '' THEN
          Item.SETRANGE("No.",ItemNo);
        IF ItemLocation <> '' THEN
          Item.SETRANGE("Location Filter",ItemLocation);
        IF ItemVariant <> '' THEN
          Item.SETRANGE("Variant Filter",ItemVariant);
        CalcInvValue.SETTABLEVIEW(Item);
        CalcInvValue.InitializeRequest(RevalDate,DocNo,TRUE,CalculatePer,ByLocation,ByVariant,UpdateStandardCost,0,TRUE);
        CalcInvValue.USEREQUESTPAGE(FALSE);
        CalcInvValue.RunModal();
        CLEAR(CalcInvValue);
    end;

    local procedure MakeName(TextPar1: Variant;TextPar2: Variant;TextPar3: Text[250]): Text[250]
    begin
        EXIT(STRSUBSTNO('%1 - %2 %3 %4',CurrTest,TextPar1,TextPar2,TextPar3));
    end;

    [Scope('OnPrem')]
    procedure FinishProdOrder(ProdOrder: Record "Production Order";NewPostingDate: Date;NewUpdateUnitCost: Boolean)
    var
        ToProdOrder: Record "Production Order";
        ChgStatOnProdOrder: Codeunit "Prod. Order Status Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        Status: Option Quote,Planned,"Firm Planned",Released,Finished;
    begin
        WITH ChgStatOnProdOrder DO BEGIN
          ChangeStatusOnProdOrder(ProdOrder,Status::Finished,NewPostingDate,NewUpdateUnitCost);
          WhseProdRelease.FinishedDelete(ToProdOrder);
        END;
    end;

    [Scope('OnPrem')]
    procedure CreateFiscalYear(FiscalYearStartDate: Date;NoOfPeriods: Integer;PeriodLengthTxt: Text[30])
    var
        AccountingPeriod: Record "Accounting Period";
        InvtSetup: Record "Inventory Setup";
        FirstPeriodStartDate: Date;
        PeriodLength: DateFormula;
        i: Integer;
        FirstPeriodLocked: Boolean;
    begin
        EVALUATE(PeriodLength,PeriodLengthTxt);
        AccountingPeriod."Starting Date" := FiscalYearStartDate;
        AccountingPeriod.TESTFIELD("Starting Date");
        FirstPeriodStartDate := AccountingPeriod."Starting Date";
        InvtSetup.Get();

        AccountingPeriod.SETFILTER("Starting Date",'>=%1',AccountingPeriod."Starting Date");
        AccountingPeriod.DeleteAll();
        AccountingPeriod.Reset();

        FOR i := 1 TO NoOfPeriods + 1 DO BEGIN
          if (FiscalYearStartDate <= FirstPeriodStartDate) and (i = NoOfPeriods + 1) THEN
            EXIT;

          AccountingPeriod.Init();
          AccountingPeriod."Starting Date" := FiscalYearStartDate;
          AccountingPeriod.VALIDATE("Starting Date");
          if (i = 1) or (i = NoOfPeriods + 1) THEN BEGIN
            AccountingPeriod."New Fiscal Year" := TRUE;
            AccountingPeriod."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type";
            AccountingPeriod."Average Cost Period" := InvtSetup."Average Cost Period";
          END;
          if (FirstPeriodStartDate = 0D) and (i = 1) THEN
            AccountingPeriod."Date Locked" := TRUE;
          if (AccountingPeriod."Starting Date" < FirstPeriodStartDate) AND FirstPeriodLocked THEN BEGIN
            AccountingPeriod.Closed := TRUE;
            AccountingPeriod."Date Locked" := TRUE;
          END;
          IF NOT AccountingPeriod.FIND('=') THEN
            AccountingPeriod.Insert();
          FiscalYearStartDate := CALCDATE(PeriodLength,FiscalYearStartDate);
        END;
    end;

    [Scope('OnPrem')]
    procedure SetBOM()
    var
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        WITH WMSSetGlobalPreconditions DO BEGIN
          ModifyProdBOMHdr('A',ProdBOMHdr.Status::New);
          ProdBOMLine.SETRANGE("Production BOM No.",'A');
          ProdBOMLine.DeleteAll();
          InsertProdBOMLine('A',10000,ProdBOMLine.Type::Item,'1_FI_RE','',1.25);
          InsertProdBOMLine('A',20000,ProdBOMLine.Type::Item,'4_AV_RE','',2.3);
          InsertProdBOMLine('A',30000,ProdBOMLine.Type::Item,'4_AV_RE','41',1);
          ModifyProdBOMHdr('A',ProdBOMHdr.Status::Certified);
        END;
    end;

    local procedure HandleCloseInvtPeriod(EndingDate: Date;"Action": Code[10])
    var
        InventoryPeriod: Record "Inventory Period";
        CloseInventoryPeriod: Codeunit "Close Inventory Period";
    begin
        CloseInventoryPeriod.SetHideDialog(TRUE);
        CASE Action OF
          'Close':
            BEGIN
              InventoryPeriod."Ending Date" := EndingDate;
              InventoryPeriod.Insert();
              InventoryPeriod.FindLast();
              CloseInventoryPeriod.RUN(InventoryPeriod);
            END;
          'Reopen':
            BEGIN
              InventoryPeriod.GET(EndingDate);
              CloseInventoryPeriod.SetReOpen(TRUE);
              CloseInventoryPeriod.RUN(InventoryPeriod);
            END;
          'Reclose':
            BEGIN
              InventoryPeriod.GET(EndingDate);
              CloseInventoryPeriod.RUN(InventoryPeriod);
            END;
        END;
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
        WITH AccountingPeriod DO BEGIN
          AccountingPeriod2.SETRANGE(Closed,FALSE);
          AccountingPeriod2.FIND('-');

          FiscalYearStartDate := AccountingPeriod2."Starting Date";
          AccountingPeriod := AccountingPeriod2;
          TESTFIELD("New Fiscal Year",TRUE);

          AccountingPeriod2.SETRANGE("New Fiscal Year",TRUE);
          IF AccountingPeriod2.FIND('>') THEN BEGIN
            FiscalYearEndDate := CALCDATE('<-1D>',AccountingPeriod2."Starting Date");

            AccountingPeriod3 := AccountingPeriod2;
            AccountingPeriod2.SETRANGE("New Fiscal Year");
            AccountingPeriod2.FIND('<');
          END else
            ERROR(TEXT001);

          Reset();

          SETRANGE("Starting Date",FiscalYearStartDate,AccountingPeriod2."Starting Date");
          MODIFYALL(Closed,TRUE);

          SETRANGE("Starting Date",FiscalYearStartDate,AccountingPeriod3."Starting Date");
          MODIFYALL("Date Locked",TRUE);

          Reset();
        END;
    end;

    [Scope('OnPrem')]
    procedure CheckItemLedgEntry(TestItemLedgEntry: Record "Item Ledger Entry";var "Code": Code[20];ExpCostAmount: Decimal;ActCostAmount: Decimal)
    begin
        WITH TestItemLedgEntry DO BEGIN
          SETRANGE("Cost Amount (Expected)",ExpCostAmount);
          SETRANGE("Cost Amount (Actual)",ActCostAmount);
          IF FindFirst() then;

          CALCFIELDS("Cost Amount (Expected)","Cost Amount (Actual)");
          Code := INCSTR(Code);
          TestscriptMgt.TestNumberValue(
            MakeName(Code,TABLECAPTION,STRSUBSTNO(TEXT005,"Entry No.")),"Cost Amount (Expected)",ExpCostAmount);
          Code := INCSTR(Code);
          TestscriptMgt.TestNumberValue(
            MakeName(Code,TABLECAPTION,STRSUBSTNO(TEXT006,"Entry No.")),"Cost Amount (Actual)",ActCostAmount);
        END;
    end;
}

