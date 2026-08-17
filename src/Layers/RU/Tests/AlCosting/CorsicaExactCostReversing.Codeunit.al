codeunit 103423 Corsica_ExactCostReversing
{
    // Unsupported version tags:
    // ES: Unable to Compile
    // NA: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // This codeunit is only ment as a tool for speeding up testing of Use Case 3 Costing Corsica
    // It is NOT part of the automated C/AL Testsuite
    // The test itself has to be done manually as described in the TCS for this use case
    // You can provide the data needed to perform the test case you want by the following steps
    // Remove the '//' infront of the Test Case you want to test
    // Make sure all other Procedures, named TestCaseXX are commented out
    // Save the codeunit
    // Run the codeunit


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit Codeunit103303;
    begin
        WMSTestscriptManagement.SetGlobalPreconditions;
        // "TestCase1-1";
        // "TestCase1-2";
        // "TestCase1-3";
        // "TestCase1-4";
        // "TestCase1-5";
        // TestCase2;
        // "TestCase3-1";
        // "TestCase3-2";
        // "TestCase3-3";
        // "TestCase3-4";
        // "TestCase3-5";
        // TestCase4;
        // "TestCase5-1";
        // "TestCase5-2";
        // "TestCase5-3";
        // "TestCase5-4";
        // "TestCase5-5";
        // "TestCase5-6";
        // "TestCase5-7";
        // "TestCase6-1";
        // "TestCase6-2";
        // TestCase7;
        // "TestCase8-1";
        // "TestCase8-2";
        // "TestCase8-3";
        // "TestCase8-4";
        // "TestCase8-5";
        // "TestCase8-6";
        // "TestCase8-7";
        // "TestCase8-8";
        // "TestCase9-1";
        // "TestCase9-2";
        // "TestCase10-1";
        // "TestCase10-2";
        // TestCase11_12;
        // "TestCase13-1";
        // "TestCase13-2";
        // "TestCase13-3";
        // "TestCase13-4";
    end;

    var
        TestscriptMgt: Codeunit Codeunit103001;
        CostingTestScriptMgmt: Codeunit Codeunit103492;
        CurrTest: Text[80];
        QtyPerUnitOfMeasure: array [10] of Decimal;
        UnitOfMeasure: array [10] of Code[10];
        iU: Integer;

    local procedure SetPreconditions()
    var
        NoSeries: Record "No. Series";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
        ExtendedTextHdr: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        NewUnitCost: Decimal;
    begin
        SalesSetup.Get();
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.VALIDATE("Stockout Warning",FALSE);
        SalesSetup.VALIDATE("Shipment on Invoice",TRUE);
        SalesSetup.VALIDATE("Calc. Inv. Discount",FALSE);
        SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",TRUE);
        SalesSetup.MODIFY(TRUE);
        PurchSetup.Get();
        PurchSetup.VALIDATE("Exact Cost Reversing Mandatory",TRUE);
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"All Discounts";
        PurchSetup.MODIFY(TRUE);
        WITH Item DO BEGIN
          SETRANGE("No.",'1_FI_RE','7_ST_OV');
          NewUnitCost := 0;
          IF FindFirst() then
            REPEAT
              NewUnitCost := NewUnitCost +1;
              "Unit Cost" := NewUnitCost;
              Modify();
            until Next() = 0;
        END;
        ExtendedTextHdr.DeleteAll();
        ExtendedTextLine.DeleteAll();
    end;

    local procedure "TestCase1-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
        
          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 260101D;
        
          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',7,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",3,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',5,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",2,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,1,0,0,TRUE);
          END;
        
          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);
        
          // New workdate
          WORKDATE := 270101D;
        
          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 280101D;
        
          // Create sales header and lines on 28-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',40);
          END;
        
          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);
        
          // Create purchase header and lines on 28-01-01
        // not active because of a bug (new feature) implemented with UC3
        /*
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',-10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",-1,0,0,0);
          END;
        
          // Post purchase order
          PostPurchOrder(PurchHeader);
        */
          // New workdate
          WORKDATE := 290101D;
        
          CLEAR(PurchHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
        
        
        
        END;

    end;

    local procedure "TestCase1-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
        
          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 260101D;
        
          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',3,'PCS',100);
          END;
        
          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);
        
          // New workdate
          WORKDATE := 270101D;
        
          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 280101D;
        /*
          // Create purchase header and lines on 28-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',-2,'PCS',80);
          END;
        
          // Post purchase invoice as received and invoiced
          PostPurchOrder(PurchHeader);
        */
          // New workdate
          WORKDATE := 290101D;
        
        END;

    end;

    local procedure "TestCase1-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
        
          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',20,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 260101D;
        
          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',2,'PCS',140);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',520);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',500);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
          END;
        
          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);
        
          // New workdate
          WORKDATE := 270101D;
        
          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;
        
          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);
        
          // New workdate
          WORKDATE := 280101D;
        /*
          // Create purchase header and lines on 28-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
        
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',-2,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",-2,0,0,0);
          END;
        
          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);
        */
          // New workdate
          WORKDATE := 290101D;
        
        END;

    end;

    local procedure "TestCase1-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        Item: Record Item;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('1_FI_RE');
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'BOX');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",0.2);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',3,'PALLET',300);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',13);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',3,'PALLET',300);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',2,'PALLET',140);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',20,'BOX',4);
            ModifySalesLine(SalesHeader,"Line No.",6,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',2,'PALLET',500);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
          END;

          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',2,'PALLET',400);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',15);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',2,'PALLET',400);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

        END;
    end;

    local procedure "TestCase1-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('1_FI_RE');
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'BOX');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",0.2);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',3,'PALLET',300);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',13);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',3,'PALLET',300);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',1,'PALLET',140);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',14);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',1,'PALLET',500);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
          END;

          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

        END;
    end;

    local procedure TestCase2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 01-12-00
          // New workdate
          WORKDATE := 011200D;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",20,20,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'6_AV_OV','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 021200D;

          // Create sales header and lines on 02-12-00
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',10,'PCS',80.34567);
            ModifySalesLine(SalesHeader,"Line No.",10,10,0,0,TRUE);
          END;

          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 171200D;

          // Create sales header and lines on 17-12-00
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',8,'PCS',26);
            ModifySalesLine(SalesHeader,"Line No.",8,8,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'6_AV_OV','',1,'PCS',80.55);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',26);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          // Post sales order as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 181200D;

          // Create sales header and lines on 18-12-00
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',1,'PCS',80.34567);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',10);
            ModifySalesLine(SalesHeader,"Line No.",3,3,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // Create purchase header and lines on 28-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',24);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'6_AV_OV','',10,'PCS',90);
            ModifyPurchLine(PurchHeader,"Line No.",5,5,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

          // New workdate
          WORKDATE := 221200D;

          // Create sales header and lines on 22-12-00
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',2,'PCS',50.55);
            ModifySalesLine(SalesHeader,"Line No.",2,2,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'6_AV_OV','',12,'PCS',50.55);
            ModifySalesLine(SalesHeader,"Line No.",12,12,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',3.4);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 231200D;

          // Create sales header and lines on 23-12-00
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',8.4);
            ModifySalesLine(SalesHeader,"Line No.",2,2,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',19,'PCS',58.234567);
            ModifySalesLine(SalesHeader,"Line No.",19,19,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // Run the Adjust Cost - Item Entries batch job
          AdjustItem('','',FALSE);

        END;
    end;

    local procedure "TestCase3-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        NewDirectUnitCost: Decimal;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
          END;

          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create sales header and lines on 28-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',11,'PCS',40);
          END;

          // Post sales invoice as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 290101D;
          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 300101D;

          // Create Purchase Invoice, retrieve posted receipts, modify lines, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);
          PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Invoice);
          PurchLine.SETFILTER("No.",'<> %1','');
          IF PurchLine.FindFirst() then
            REPEAT
              NewDirectUnitCost := PurchLine."Direct Unit Cost" +10;
              PurchLine.VALIDATE(PurchLine."Direct Unit Cost",NewDirectUnitCost);
              PurchLine.Modify();
            UNTIL PurchLine.Next() = 0;
          PostPurchOrder(PurchHeader);

          WORKDATE := 310101D;

        END;
    end;

    local procedure "TestCase3-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        NewDirectUnitCost: Decimal;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
          END;

          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create sales header and lines on 28-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',11,'PCS',40);
          END;

          // Post sales invoice as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 290101D;
          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 300101D;

          // Create Purchase Invoice, retrieve posted receipts, modify lines, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);
          PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Invoice);
          PurchLine.SETFILTER("No.",'<> %1','');
          IF PurchLine.FindFirst() then
            REPEAT
              NewDirectUnitCost := PurchLine."Direct Unit Cost" +10;
              PurchLine.VALIDATE(PurchLine."Direct Unit Cost",NewDirectUnitCost);
              PurchLine.Modify();
            UNTIL PurchLine.Next() = 0;
          PostPurchOrder(PurchHeader);

          AdjustItem('','',FALSE);

          WORKDATE := 310101D;

        END;
    end;

    local procedure "TestCase3-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        NewDirectUnitCost: Decimal;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
          END;

          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',10,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',10,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',10,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",10,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create sales header and lines on 28-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',11,'PCS',40);
          END;

          // Post sales invoice as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 290101D;
          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 300101D;

          // Create Purchase Invoice, retrieve posted receipts, modify lines, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);
          PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Invoice);
          PurchLine.SETFILTER("No.",'<> %1','');
          IF PurchLine.FindFirst() then
            REPEAT
              NewDirectUnitCost := PurchLine."Direct Unit Cost" +10;
              PurchLine.VALIDATE(PurchLine."Direct Unit Cost",NewDirectUnitCost);
              PurchLine.Modify();
            UNTIL PurchLine.Next() = 0;
          PostPurchOrder(PurchHeader);

          WORKDATE := 310101D;

        END;
    end;

    local procedure "TestCase3-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Resource: Record Resource;
        ResUnitofMeasure: Record "Resource Unit of Measure";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Resource DO BEGIN
            GET('LIFT');
            ResUnitofMeasure.Init();
            ResUnitofMeasure."Resource No." := "No.";
            ResUnitofMeasure.VALIDATE(Code,'PCS');
            ResUnitofMeasure.VALIDATE("Qty. per Unit of Measure",1);
            IF NOT ResUnitofMeasure.Insert() then
              ResUnitofMeasure.Modify();
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create sales header and lines on 27-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',4,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Resource,'Lift','',1,'PCS',200);
            InsertSalesLine(SalesLine,SalesHeader,50000,Type::"Charge (Item)",'UPS','',10,'PCS',10);
          END;

          InsertSalesChargeAssignLine(SalesLine,10000,SalesHeader."Document Type",SalesHeader."No.",
          10000,'4_AV_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,10000,3);
          InsertSalesChargeAssignLine(SalesLine,20000,SalesHeader."Document Type",SalesHeader."No.",
          20000,'1_FI_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,20000,4);
          InsertSalesChargeAssignLine(SalesLine,30000,SalesHeader."Document Type",SalesHeader."No.",
          30000,'4_AV_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,30000,3);

          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create purchase header and lines on 26-01-01 with Posting Date on 26-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create Purchase Invoice, retrieve posted receipts, modify lines, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);
          InsertPurchLine(PurchLine,PurchHeader,90000,PurchLine.Type::"Charge (Item)",'UPS','',12,'',5);

          InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",
          20000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,20000,2);
          InsertPurchChargeAssignLine(PurchLine,30000,PurchHeader."Document Type",PurchHeader."No.",
          30000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,30000,2);
          InsertPurchChargeAssignLine(PurchLine,40000,PurchHeader."Document Type",PurchHeader."No.",
          40000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,40000,2);
          InsertPurchChargeAssignLine(PurchLine,60000,PurchHeader."Document Type",PurchHeader."No.",
          60000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,60000,2);
          InsertPurchChargeAssignLine(PurchLine,70000,PurchHeader."Document Type",PurchHeader."No.",
          70000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,70000,2);
          InsertPurchChargeAssignLine(PurchLine,80000,PurchHeader."Document Type",PurchHeader."No.",
          80000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,80000,2);

          PostPurchOrder(PurchHeader);
          WORKDATE := 290101D;
        END;
    end;

    local procedure "TestCase3-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create purchase header and lines on 26-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create sales header and lines on 27-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',4,'PCS',40);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::"G/L Account",'5796','',1,'PCS',100);
            InsertSalesLine(SalesLine,SalesHeader,50000,Type::"Charge (Item)",'UPS','',10,'PCS',10);
          END;

          InsertSalesChargeAssignLine(SalesLine,10000,SalesHeader."Document Type",SalesHeader."No.",
          10000,'4_AV_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,10000,3);
          InsertSalesChargeAssignLine(SalesLine,20000,SalesHeader."Document Type",SalesHeader."No.",
          20000,'1_FI_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,20000,4);
          InsertSalesChargeAssignLine(SalesLine,30000,SalesHeader."Document Type",SalesHeader."No.",
          30000,'4_AV_RE');
          ModifySalesChargeAssignLine(SalesHeader,50000,30000,3);

          // Post sales invoice as shipped and invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create Purchase Invoice, retrieve posted receipts, modify lines, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);
          InsertPurchLine(PurchLine,PurchHeader,90000,PurchLine.Type::"Charge (Item)",'UPS','',12,'',5);

          InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",
          20000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,20000,2);
          InsertPurchChargeAssignLine(PurchLine,30000,PurchHeader."Document Type",PurchHeader."No.",
          30000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,30000,2);
          InsertPurchChargeAssignLine(PurchLine,40000,PurchHeader."Document Type",PurchHeader."No.",
          40000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,40000,2);
          InsertPurchChargeAssignLine(PurchLine,60000,PurchHeader."Document Type",PurchHeader."No.",
          60000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,60000,2);
          InsertPurchChargeAssignLine(PurchLine,70000,PurchHeader."Document Type",PurchHeader."No.",
          70000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,70000,2);
          InsertPurchChargeAssignLine(PurchLine,80000,PurchHeader."Document Type",PurchHeader."No.",
          80000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,90000,80000,2);

          PostPurchOrder(PurchHeader);
          WORKDATE := 290101D;

        END;
    end;

    local procedure TestCase4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CombShpts: Report "Combine Shipments";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::"Charge (Item)",'UPS','',6,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",6,6,0,0);
          END;

          InsertPurchChargeAssignLine(PurchLine,10000,PurchHeader."Document Type",PurchHeader."No.",
          10000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,10000,2);
          InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",
          20000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,20000,2);
          InsertPurchChargeAssignLine(PurchLine,30000,PurchHeader."Document Type",PurchHeader."No.",
          30000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,30000,2);

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',1,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
          END;

          // Post sales order as shipped
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',20);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::"Charge (Item)",'UPS','',6,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",6,6,0,0);
          END;

          InsertPurchChargeAssignLine(PurchLine,10000,PurchHeader."Document Type",PurchHeader."No.",
          10000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,10000,2);
          InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",
          20000,'1_FI_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,20000,2);
          InsertPurchChargeAssignLine(PurchLine,30000,PurchHeader."Document Type",PurchHeader."No.",
          30000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,40000,30000,2);

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
          END;

          // Post sales order as shipped
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 290101D;

          CLEAR(CombShpts);
          CombShpts.InitializeRequest(270101D,WORKDATE,FALSE,FALSE,FALSE,FALSE);
          CombShpts.SetHideDialog(TRUE);
          CombShpts.USEREQUESTPAGE(FALSE);
          CombShpts.RunModal();

          // Post sales invoice
          WITH SalesHeader DO BEGIN
            Reset();
            SETRANGE(SalesHeader."Document Type",SalesHeader."Document Type"::Invoice);
            IF FIND('-') THEN
              PostSalesOrder(SalesHeader);
          END;

          DeleteInvoicedSalesOrders.USEREQUESTPAGE(FALSE);
          DeleteInvoicedSalesOrders.RunModal();

          // New workdate
          WORKDATE := 300101D;

        END;
    end;

    local procedure "TestCase5-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.MODIFY(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',30);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 270101D;

          // Create purchase header and lines on 27-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',50);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',8);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','41',2,'PCS',20);
          END;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          // Create sales header and lines on 28-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",3,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",3,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','41',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,0,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 290101D;

        END;
    end;

    local procedure "TestCase5-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        SalesSetup: Record "Sales & Receivables Setup";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.MODIFY(TRUE);

          WITH Item DO BEGIN
            GET('4_AV_RE');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
            GET('1_FI_RE');
            "Item Tracking Code" := 'SNALL';
            MODIFY(TRUE);
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',10);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',8);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',4,'PCS',50);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,4,4,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',5,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",5,3,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",2,1,0,0,TRUE);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,2,2,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;
        END;
    end;

    local procedure "TestCase5-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.MODIFY(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
          SalesHeader.VALIDATE("Currency Code",'DKK');
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase5-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.MODIFY(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE("Currency Code",'DKK');
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",5,5,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase5-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.MODIFY(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;

          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',3,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",3,3,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 280101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 290101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',4,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",4,4,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 300101D;
        END;
    end;

    local procedure "TestCase5-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.VALIDATE("Calc. Inv. Discount",TRUE);
          SalesSetup.MODIFY(TRUE);

          //Invoice discounts
          WITH CustInvoiceDisc DO BEGIN
            Init();
            Code := '10000';
            "Minimum Amount" := 0.0;
            "Discount %" := 5;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 2000.0;
            "Discount %" := 10;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 5000.0;
            "Discount %" := 20;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',200,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",200,200,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',300,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",300,300,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // New Workdate
          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase5-7"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Exact Cost Reversing Mandatory",FALSE);
          SalesSetup.VALIDATE("Calc. Inv. Discount",TRUE);
          SalesSetup.MODIFY(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',200,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",200,150,0,10,TRUE);
          END;
          PostSalesOrder(SalesHeader);

          WORKDATE := 260101D;
          SalesHeader.FindFirst();
          ReleaseSalesDoc.Reopen(SalesHeader);
          SalesHeader.VALIDATE("Posting Date",WorkDate());
          SalesHeader.Modify();
          SalesLine.FindFirst();
          ModifySalesLine(SalesHeader,SalesLine."Line No.",0,50,0,1,TRUE);

          PostSalesOrder(SalesHeader);

          WORKDATE := 290101D;

          //Invoice discounts
          WITH CustInvoiceDisc DO BEGIN
            Init();
            Code := '10000';
            "Minimum Amount" := 0.0;
            "Discount %" := 5;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 2000.0;
            "Discount %" := 10;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 5000.0;
            "Discount %" := 20;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
          END;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',500,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",500,300,0,10,TRUE);
          END;
          PostSalesOrder(SalesHeader);

          WORKDATE := 300101D;
          // Set Line Discount = 1%
          SalesHeader.FindFirst();
          ReleaseSalesDoc.Reopen(SalesHeader);
          SalesHeader.VALIDATE("Posting Date",WorkDate());
          SalesHeader.Modify();
          SalesLine.FindFirst();
          ModifySalesLine(SalesHeader,SalesLine."Line No.",0,200,0,1,TRUE);

          PostSalesOrder(SalesHeader);

        END;
    end;

    local procedure "TestCase6-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('4_AV_RE');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
            GET('1_FI_RE');
            "Item Tracking Code" := 'SNALL';
            MODIFY(TRUE);
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',10);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',8);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',4,'PCS',50);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,4,4,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',5,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",5,2,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",2,1,0,0,TRUE);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,2,2,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

        END;
    end;

    local procedure "TestCase6-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        CreateRes: Codeunit "Create Reserv. Entry";
        CombShpts: Report "Combine Shipments";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('4_AV_RE');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
            GET('1_FI_RE');
            "Item Tracking Code" := 'SNALL';
            MODIFY(TRUE);
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          // Create sales header and lines on 26-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,2,2,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',50);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',8);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,4,4,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',WORKDATE,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN03','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',WORKDATE,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN04','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',WORKDATE,0D,0,2);

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 280101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',80);
            ModifySalesLine(SalesHeader,"Line No.",3,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',50);
            ModifySalesLine(SalesHeader,"Line No.",2,0,0,0,TRUE);
          END;

          // Add the following item tracking information to the lines

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,2,2,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN03','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN04','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',0D,WORKDATE,0,2);

          PostSalesOrder(SalesHeader);

          AdjustItem('','',FALSE);

          // New workdate
          WORKDATE := 290101D;

          CLEAR(CombShpts);
          CombShpts.InitializeRequest(260101D,WORKDATE,FALSE,FALSE,FALSE,FALSE);
          CombShpts.SetHideDialog(TRUE);
          CombShpts.USEREQUESTPAGE(FALSE);
          CombShpts.RunModal();

          // Post sales invoice
          WITH SalesHeader DO BEGIN
            Reset();
            SETRANGE(SalesHeader."Document Type",SalesHeader."Document Type"::Invoice);
            IF FIND('-') THEN
              PostSalesOrder(SalesHeader);
          END;

          DeleteInvoicedSalesOrders.USEREQUESTPAGE(FALSE);
          DeleteInvoicedSalesOrders.RunModal();

          // New workdate
          WORKDATE := 300101D;

        END;
    end;

    local procedure TestCase7()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Shipment on Invoice",FALSE);
          SalesSetup.MODIFY(TRUE);

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',10);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',8);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',4,'PCS',50);
          END;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',70);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',40);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 270101D;

        END;
    end;

    local procedure "TestCase8-1"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',4,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New Workdate
          WORKDATE := 260101D;

          // Create purchase header and lines on 26-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',1,'PCS',100);
            ModifyPurchLine(PurchHeader,"Line No.",1,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',3,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",3,3,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',120);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

        END;
    end;

    local procedure "TestCase8-2"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemJnlLine: Record "Item Journal Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('1_FI_RE');
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'BOX');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",0.2);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();
            GET('5_ST_RA');
            VALIDATE("Standard Cost",52);
            Modify();
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PALLET',300);
            ModifyPurchLine(PurchHeader,"Line No.",2,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'1_FI_RE','',5,'BOX',8);
            ModifyPurchLine(PurchHeader,"Line No.",5,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'5_ST_RA','',3,'PCS',52);
            ModifyPurchLine(PurchHeader,"Line No.",3,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'4_AV_RE','41',2,'PALLET',400);
            ModifyPurchLine(PurchHeader,"Line No.",2,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'4_AV_RE','41',2,'PALLET',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,1,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          CreateRevalJnl(ItemJnlLine,'5_ST_RA','','',260101D,'TESTREVAL',1,FALSE,FALSE,FALSE,0);
          WITH ItemJnlLine DO BEGIN
            ModifyItemJnlLine("Journal Template Name","Journal Batch Name",10000,180,TRUE,0);
          END;
          ItemJnlPostBatch(ItemJnlLine);

          // New workdate
          WORKDATE := 270101D;

        END;
    end;

    local procedure "TestCase8-3"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('6_AV_OV');
            "Indirect Cost %" := 3;
            "Overhead Rate" := 11;
            Modify();
            GET('7_ST_OV');
            "Indirect Cost %" := 2;
            "Overhead Rate" := 12;
            "Standard Cost" := 70;
            Modify();
          END;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'7_ST_OV','',5,'PCS',80);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'6_AV_OV','',5,'PCS',80);
          END;

          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;

          WITH Item DO BEGIN
            GET('6_AV_OV');
            "Indirect Cost %" := 1;
            "Overhead Rate" := 11;
            Modify();
            GET('7_ST_OV');
            "Indirect Cost %" := 0;
            "Overhead Rate" := 12;
            Modify();
          END;

        END;
    end;

    local procedure "TestCase8-4"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',5,'PALLET',100);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',10);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',5,'PCS',80);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'1_FI_RE','',4,'PCS',8);
            InsertPurchLine(PurchLine,PurchHeader,50000,Type::"Charge (Item)",'UPS','',1,'PCS',10);
          END;

          InsertPurchChargeAssignLine(PurchLine,10000,PurchHeader."Document Type",PurchHeader."No.",
          10000,'4_AV_RE');
          ModifyPurchChargeAssignLine(PurchHeader,50000,10000,1);

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          CreateRevalJnl(ItemJnlLine,'1_FI_RE','','',260101D,'TESTREVAL',1,FALSE,FALSE,FALSE,0);
          WITH ItemJnlLine DO BEGIN
            ModifyItemJnlLine("Journal Template Name","Journal Batch Name",10000,75,TRUE,0);
          END;

          ItemJnlPostBatch(ItemJnlLine);

          // New workdate
          WORKDATE := 270101D;

        END;
    end;

    local procedure "TestCase8-5"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;

          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;
          PurchHeader.FindFirst();
          ReleasePurchDoc.Reopen(PurchHeader);
          PurchLine.FindFirst();
          ModifyPurchLine(PurchHeader,PurchLine."Line No.",0,1,0,0);
          PostPurchOrder(PurchHeader);

          WORKDATE := 270101D;

          // Create Purchase Invoice, retrieve posted receipts, post invoice
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',FALSE);
          PurchHeader."Prices Including VAT" := TRUE;
          PurchHeader.Modify();

          PurchRcptLine.Reset();
          PurchGetRcpLine.SetPurchHeader(PurchHeader);
          PurchRcptLine.SETRANGE("Buy-from Vendor No.",'10000');
          PurchGetRcpLine.CreateInvLines(PurchRcptLine);

          PostPurchOrder(PurchHeader);

        END;
    end;

    local procedure "TestCase8-6"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);
          PurchHeader.VALIDATE("Currency Code",'DKK');
          PurchHeader.Modify();

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase8-7"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('4_AV_RE');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
            GET('1_FI_RE');
            "Item Tracking Code" := 'SNALL';
            MODIFY(TRUE);
          END;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',3,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",3,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',1,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',4,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
          END;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('1_FI_RE','','BLUE','',250101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,4,4,'','LOT02','');
          CreateRes.CreateEntry('4_AV_RE','','BLUE','',250101D,0D,0,2);

          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase8-8"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('1_FI_RE');
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'BOX');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",0.2);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();
          END;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',3,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",3,3,0,0);
          END;

          PostPurchOrder(PurchHeader);

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",1,1,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'4_AV_RE','',4,'PCS',80);
            ModifyPurchLine(PurchHeader,"Line No.",4,4,0,0);
          END;

          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',8,'BOX',40);
            ModifySalesLine(SalesHeader,"Line No.",8,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'4_AV_RE','',5,'PCS',70);
            ModifySalesLine(SalesHeader,"Line No.",5,0,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 270101D;

        END;
    end;

    local procedure "TestCase9-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemJnlLine: Record "Item Journal Line";
        ExtendedTextHdr: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Text001: Label 'This is an extremely long text.';
        Text002: Label 'It is used to test the Get Posted Document Lines ';
        Text003: Label 'functionality provided for Exact Cost Reversal';
        Text004: Label 'Use Case.';
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('1_FI_RE');
            "Automatic Ext. Texts" := TRUE;
            Modify();
            GET('5_ST_RA');
            VALIDATE("Standard Cost",52);
            Modify();
          END;

          ExtendedTextHdr.VALIDATE("Table Name",ExtendedTextHdr."Table Name"::Item);
          ExtendedTextHdr.VALIDATE("No.",'1_FI_RE');
          ExtendedTextHdr.VALIDATE("All Language Codes",TRUE);
          IF NOT ExtendedTextHdr.INSERT(TRUE) THEN
            ExtendedTextHdr.Modify();

          WITH ExtendedTextLine DO BEGIN
            VALIDATE("Table Name","Table Name"::Item);
            VALIDATE("No.",'1_FI_RE');
            VALIDATE("Text No.",1);
            VALIDATE("Line No.",10000);
            VALIDATE(Text,Text001);
            IF NOT INSERT(TRUE) THEN
              Modify();
            VALIDATE("Table Name","Table Name"::Item);
            VALIDATE("No.",'1_FI_RE');
            VALIDATE("Text No.",1);
            VALIDATE("Line No.",20000);
            VALIDATE(Text,Text002);
            IF NOT INSERT(TRUE) THEN
              Modify();
            VALIDATE("Table Name","Table Name"::Item);
            VALIDATE("No.",'1_FI_RE');
            VALIDATE("Text No.",1);
            VALIDATE("Line No.",30000);
            VALIDATE(Text,Text003);
            IF NOT INSERT(TRUE) THEN
              Modify();
            VALIDATE("Table Name","Table Name"::Item);
            VALIDATE("No.",'1_FI_RE');
            VALIDATE("Text No.",1);
            VALIDATE("Line No.",40000);
            VALIDATE(Text,Text004);
            IF NOT INSERT(TRUE) THEN
              Modify();
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',2,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'4_AV_RE','',2,'PCS',50);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'5_ST_RA','',3,'PCS',52);
            ModifyPurchLine(PurchHeader,"Line No.",3,2,0,0);
            InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'1_FI_RE','',5,'PCS',8);
            ModifyPurchLine(PurchHeader,"Line No.",5,2,0,0);
          END;

          // Post purchase order as received and invoiced
          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 270101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'4_AV_RE','',1,'PCS',90);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'5_ST_RA','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'1_FI_RE','',1,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",1,0,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          AdjustItem('','',FALSE);

          CreateRevalJnl(ItemJnlLine,'','','',260101D,'TESTREVAL',1,TRUE,TRUE,FALSE,0);

          WITH ItemJnlLine DO BEGIN
            ModifyItemJnlLine("Journal Template Name","Journal Batch Name",10000,48,TRUE,0);
            ModifyItemJnlLine("Journal Template Name","Journal Batch Name",20000,300,TRUE,0);
            ModifyItemJnlLine("Journal Template Name","Journal Batch Name",30000,180,TRUE,0);
          END;

          ItemJnlPostBatch(ItemJnlLine);

          // New workdate
          WORKDATE := 280101D;

        END;
    end;

    local procedure "TestCase9-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          WITH Item DO BEGIN
            GET('6_AV_OV');
            "Indirect Cost %" := 3;
            "Overhead Rate" := 11;
            Modify();
            GET('7_ST_OV');
            "Indirect Cost %" := 2;
            "Overhead Rate" := 12;
            "Standard Cost" := 70;
            Modify();
          END;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'6_AV_OV','',5,'PCS',100);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'7_ST_OV','',5,'PCS',80);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'6_AV_OV','',5,'PCS',80);
          END;

          PostPurchOrder(PurchHeader);

          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'7_ST_OV','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 270101D;

          WITH Item DO BEGIN
            GET('6_AV_OV');
            "Indirect Cost %" := 0;
            "Overhead Rate" := 0;
            Modify();
            GET('7_ST_OV');
            "Indirect Cost %" := 0;
            "Overhead Rate" := 0;
            Modify();
          END;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'6_AV_OV','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'7_ST_OV','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 290101D;

          WITH Item DO BEGIN
            GET('6_AV_OV');
            "Indirect Cost %" := 4;
            "Overhead Rate" := 10;
            Modify();
            GET('7_ST_OV');
            "Indirect Cost %" := 5;
            "Overhead Rate" := 10;
            Modify();
          END;
        END;
    end;

    local procedure "TestCase10-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
        TestScriptMgmt: Codeunit Codeunit103303;
        "Code": Code[20];
        SNCode: Code[20];
        i: Integer;
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;

          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',3,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",3,3,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 280101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",2,2,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 290101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',4,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",4,4,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 300101D;
        END;
    end;

    local procedure "TestCase10-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,0,0);
          END;

          PostPurchOrder(PurchHeader);

          // New workdate
          WORKDATE := 260101D;

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',100);
            ModifySalesLine(SalesHeader,"Line No.",5,0,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 270101D;
          SalesHeader.FindFirst();
          ReleaseSalesDoc.Reopen(SalesHeader);
          SalesLine.FindFirst();
          ModifySalesLine(SalesHeader,SalesLine."Line No.",0,3,0,0,TRUE);
          PostSalesOrder(SalesHeader);

          WORKDATE := 280101D;
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          SalesHeader.VALIDATE(SalesHeader."Prices Including VAT",TRUE);
          SalesHeader.Modify();

          CLEAR(SalesShipmentLine);
          SalesShipmentLine.SETRANGE("Sell-to Customer No.",'10000');
          SalesGetShipment.SetSalesHeader(SalesHeader);
          SalesGetShipment.CreateInvLines(SalesShipmentLine);
          PostSalesOrder(SalesHeader);

          WORKDATE := 290101D;
        END;
    end;

    local procedure TestCase11_12()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",2,2,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);
          SalesHeader.VALIDATE("Currency Code",'DKK');
          SalesHeader.Modify();

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",1,1,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // New workdate
          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase13-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Calc. Inv. Discount",TRUE);
          SalesSetup.MODIFY(TRUE);

          //Invoice discounts
          WITH CustInvoiceDisc DO BEGIN
            Init();
            Code := '10000';
            "Minimum Amount" := 0.0;
            "Discount %" := 5;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 2000.0;
            "Discount %" := 10;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 5000.0;
            "Discount %" := 20;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
          END;

          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;
          PostPurchOrder(PurchHeader);

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',200,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",200,200,0,0,TRUE);
          END;

          PostSalesOrder(SalesHeader);

          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase13-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;
          PostPurchOrder(PurchHeader);

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',100,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",100,100,0,10,TRUE);
          END;
          PostSalesOrder(SalesHeader);

          WORKDATE := 260101D;

        END;
    end;

    local procedure "TestCase13-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SalesSetup.Get();
          SalesSetup.VALIDATE("Calc. Inv. Discount",TRUE);
          SalesSetup.MODIFY(TRUE);

          WITH CustInvoiceDisc DO BEGIN
            Init();
            Code := '10000';
            "Minimum Amount" := 0.0;
            "Discount %" := 5;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 2000.0;
            "Discount %" := 10;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 5000.0;
            "Discount %" := 20;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
          END;

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;
          PostPurchOrder(PurchHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',200,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",200,200,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',300,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",300,300,0,0,TRUE);
          END;

          // Post sales order as invoiced
          PostSalesOrder(SalesHeader);

          // New Workdate
          WORKDATE := 260101D;

          WITH CustInvoiceDisc DO BEGIN
            Init();
            Code := '10000';
            "Minimum Amount" := 0.0;
            "Discount %" := 0;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 2000.0;
            "Discount %" := 0;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
            Init();
            Code := '10000';
            "Minimum Amount" := 5000.0;
            "Discount %" := 0;
            IF NOT INSERT(TRUE) THEN
              MODIFY(TRUE);
          END;

        END;
    end;

    local procedure "TestCase13-4"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        WITH CostingTestScriptMgmt DO BEGIN
          SetGlobalPreconditions;
          SetPreconditions;
          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);

          // Create purchase header and lines on 25-01-01
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',WorkDate());
          ModifyPurchHeader(PurchHeader,WORKDATE,'BLUE','',TRUE);

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1000,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",1000,1000,0,0);
          END;

          // Create sales header and lines on 25-01-01
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',WorkDate());
          ModifySalesHeader(SalesHeader,WORKDATE,'BLUE',FALSE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',200,'PCS',40);
            ModifySalesLine(SalesHeader,"Line No.",200,150,0,10,TRUE);
          END;
          PostSalesOrder(SalesHeader);

          WORKDATE := 260101D;
          SalesHeader.FindFirst();
          ReleaseSalesDoc.Reopen(SalesHeader);
          SalesHeader.VALIDATE("Posting Date",WorkDate());
          SalesHeader.Modify();
          SalesLine.FindFirst();
          ModifySalesLine(SalesHeader,SalesLine."Line No.",0,50,0,1,TRUE);

          PostSalesOrder(SalesHeader);

        END;
    end;

    local procedure CreateRevalJnl(var ItemJnlLine: Record "Item Journal Line";ItemNo: Code[20];ItemLocation: Code[10];ItemVariant: Code[10];RevalDate: Date;DocNo: Code[20];CalculatePer: Integer;ByLocation: Boolean;ByVariant: Boolean;UpdateStandardCost: Boolean;CalcBase: Integer)
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
}

