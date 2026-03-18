codeunit 103495 TestSetupManagement
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        CreateUseCases();
        CreateTestCases();
        TestCase.Reset();
        CreateIterations(TestCase,true,false);
    end;

    var
        UseCase: Record "Use Case";
        TestCase: Record "Test Case";
        TestIteration: Record "Test Iteration";
        OldTestIteration: Record "Test Iteration";
        IncrSteps: Integer;

    [Scope('OnPrem')]
    procedure CreateUseCases()
    begin
        UseCase.Reset();
        UseCase.DeleteAll();
        InsertUseCase(1,'Post Purchase Order by Quantity');
        InsertUseCase(2,'Post Purchase Order by Value');
        InsertUseCase(3,'Reverse Purchase Posting');
        InsertUseCase(4,'Post Purchase Credit Memo by Quantity');
        InsertUseCase(5,'Post Purchase Credit Memo by Value');
        InsertUseCase(6,'Post Additional Vendor Cost to Purchased Items Already Posted');
        InsertUseCase(7,'Valuate Inventory');
        // InsertUseCase(8,'Post a Drop Shipment');
        // InsertUseCase(9,'Use Weighted Average as Cost Flow Assumption');
        // InsertUseCase(10,'Change Valuation Method');
        // InsertUseCase(11,'Create Combined Invoice for Additional Direct Cost');
        // InsertUseCase(12,'Close Purchase Order');
        InsertUseCase(13,'Post Sales Order by Quantity');
        InsertUseCase(14,'Post Sales Order by Value');
        InsertUseCase(15,'Post Sales Credit Memo by Quantity');
        InsertUseCase(16,'Post Sales Credit Memo by Value');
        // InsertUseCase(17,'Post Price Reduction For Sold Items');
        InsertUseCase(18,'Post Additional Cost For Sold Items');
        InsertUseCase(19,'Expected Costs - Extended');
        // InsertUseCase(20,'Outbound Transfer');
        // InsertUseCase(21,'Inbound Transfers');
        // InsertUseCase(22,'Commission Handling');
    end;

    [Scope('OnPrem')]
    procedure InsertUseCase(NewUseCaseNo: Integer;NewDescription: Text[100])
    begin
        UseCase."Use Case No." := NewUseCaseNo;
        UseCase.Description := NewDescription;
        UseCase.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTestCases()
    begin
        TestCase.Reset();
        TestCase.SetRange("Project Code",'CETAF');
        TestCase.DeleteAll();
        InsertTestCase(1,1,'Std',true);
        InsertTestCase(1,2,'Average - prod.',true);
        InsertTestCase(1,3,'Actual',true);
        InsertTestCase(1,4,'Mixed',true);
        InsertTestCase(1,5,'Item Charges on Purchases and Sales Orders',true);
        InsertTestCase(2,1,'No additional cost',true);
        InsertTestCase(2,2,'Partly received / partly invoiced + job',true);
        // InsertTestCase(2,3,'Prod. order update',TRUE);                      Removed on 12/09/2000
        InsertTestCase(2,4,'Fully received / partly invoiced',true);
        InsertTestCase(2,5,'Fully received / fully invoiced',true);
        InsertTestCase(2,6,'Vendor currency',true);
        InsertTestCase(2,7,'Fully received / invoiced with changed unit cost',true);
        InsertTestCase(3,1,'Reverse invoice',true);
        InsertTestCase(3,2,'Reverse receipt',true);
        InsertTestCase(3,3,'Reverse invoice & receipt',true);
        InsertTestCase(3,4,'Reverse combined invoices',true);
        InsertTestCase(4,1,'Partly invoiced + expected costs',true);
        InsertTestCase(4,2,'Not invoiced + no expected costs (simple case)',true);
        InsertTestCase(4,3,'Not invoiced + expected costs',true);
        InsertTestCase(5,1,'Return only value - partly invoiced',true);
        // InsertTestCase(5,2,'Return only value - fully invoiced',TRUE);      Removed on 27/09/2000
        InsertTestCase(5,3,'Return value and quantity - partly invoiced',true);
        InsertTestCase(5,4,'Return value and quantity - fully invoiced (simple case)',true);
        InsertTestCase(5,5,'Return invoice + additional cost',true);
        InsertTestCase(6,1,'Received / not invoiced',true);
        // InsertTestCase(6,2,'Prod. order update',TRUE);                      Removed on 27/09/2000
        InsertTestCase(6,3,'Partly received / partly invoiced',true);
        InsertTestCase(6,4,'Fully received / partly invoiced',true);
        InsertTestCase(6,5,'Fully received / fully invoiced',true);
        InsertTestCase(7,1,'Valuate (part of) inventory',true);
        InsertTestCase(7,2,'Wrong posting',true);
        InsertTestCase(7,3,'Std. costed',true);
        // InsertTestCase(7,4,'Production order',TRUE);                        Removed on 27/09/2000
        InsertTestCase(7,5,'Negative inventory',true);
        InsertTestCase(7,6,'SKU + Additional Cost',true);
        InsertTestCase(7,7,'Multi transfer + sales credit note',true);
        InsertTestCase(7,8,'Multi transfer + rounding',true);
        InsertTestCase(7,9,'WIP Testcase 373.1',true);
        InsertTestCase(7,10,'WIP Testcase 373.2a',true);
        InsertTestCase(7,11,'WIP Testcase 373.2b',true);
        InsertTestCase(7,12,'WIP Testcase 373.3',true);
        InsertTestCase(7,13,'WIP Testcase 373.4',true);
        InsertTestCase(7,14,'WIP Testcase 373.5',true);
        InsertTestCase(7,15,'WIP Testcase 373.6',true);
        // InsertTestCase(7,16,'WIP Testcase 373.7',TRUE);                     Removed on 27/09/2000
        InsertTestCase(7,17,'WIP Testcase 373.8',true);
        InsertTestCase(7,18,'WIP + Average Cost',true);
        InsertTestCase(7,19,'Valuation Date + Average Cost',true);
        InsertTestCase(7,20,'Cost per Unit, while Output Qty. < 1',true);
        InsertTestCase(7,21,'Valuation Date of Transfer Entries',true);
        InsertTestCase(7,22,'Valuation Date and Endless Loops',true);
        InsertTestCase(7,23,'Ajustment and Reclass. Journal',true);
        InsertTestCase(7,24,'Valuate Inventory and Unit Cost',true);
        InsertTestCase(7,25,'Costing and Manufacturing',true);
        InsertTestCase(7,26,'Valuate Cost Amount Actual',true);
        // InsertTestCase(8,1,'Include drop shipment in cost calc.',TRUE);
        // InsertTestCase(8,2,'Exclude drop shipment in cost calc.',TRUE);
        // InsertTestCase(8,3,'Sales first 8.1',TRUE);
        // InsertTestCase(8,4,'Sales first 8.2',TRUE);
        // InsertTestCase(9,1,'Automatic cost posting',TRUE);
        // InsertTestCase(9,2,'No automatic cost posting',TRUE);
        // InsertTestCase(9,3,'No ILE in selected period',TRUE);
        // InsertTestCase(10,1,'Std to Average',TRUE);
        // InsertTestCase(10,2,'Std to Actual',TRUE);
        // InsertTestCase(10,3,'Average to Std',TRUE);
        // InsertTestCase(10,4,'Average to Actual',TRUE);
        // InsertTestCase(10,5,'Actual to Std',TRUE);
        // InsertTestCase(10,6,'Actual to Average',TRUE);
        // InsertTestCase(11,1,'Multiple invoices',TRUE);
        // InsertTestCase(11,2,'Multiple receipts',TRUE);
        // InsertTestCase(11,3,'Multiple invoices and receipts',TRUE);
        // InsertTestCase(12,1,'With expected costs - partly invoiced',TRUE);
        // InsertTestCase(12,2,'Without expected costs - partly invoiced (prod order)',TRUE);
        // InsertTestCase(12,3,'With expected costs - no invoice',TRUE);
        // InsertTestCase(12,4,'Without expected costs - no invoice',TRUE);
        InsertTestCase(13,1,'Std',true);
        InsertTestCase(13,2,'Average',true);
        InsertTestCase(13,3,'Actual',true);
        InsertTestCase(13,4,'Sales Amount Expected',true);
        InsertTestCase(13,5,'Sales Return Orders and Item Charge',true);
        InsertTestCase(13,6,'Sales Credit Memo and Item Charge',true);
        InsertTestCase(14,1,'No additional cost',true);
        InsertTestCase(14,2,'Partly shipped / partly invoiced',true);
        InsertTestCase(14,3,'Fully shipped / partly invoiced (add costs)',true);
        InsertTestCase(14,4,'Fully shipped / fully invoiced (Item charge + job)',true);
        InsertTestCase(14,5,'Fully shipped / fully invoiced',true);
        InsertTestCase(15,1,'Partly invoiced',true);
        InsertTestCase(15,2,'Not invoiced',true);
        InsertTestCase(15,3,'Not invoiced and add. customer currency',true);
        InsertTestCase(16,1,'Return only value / Partly invoiced',true);
        InsertTestCase(16,2,'Return only value / Fully invoiced',true);
        InsertTestCase(16,3,'Return value and quantity / Partly invoiced',true);
        InsertTestCase(16,4,'Return value and quantity / Fully invoiced',true);
        InsertTestCase(16,5,'Return invoice + additional cost',true);
        InsertTestCase(18,1,'Shipped / Not invoiced',true);
        InsertTestCase(18,2,'Partly shipped / Partly invoiced',true);
        InsertTestCase(18,3,'Fully shipped / Partly invoiced',true);
        InsertTestCase(18,4,'Fully shipped / Fully invoiced',true);
        InsertTestCase(19,1,'Post Documents by Value',true);
        InsertTestCase(19,2,'Post Documents by Quantity',true);
        InsertTestCase(19,3,'Manufacturing',true);
    end;

    [Scope('OnPrem')]
    procedure InsertTestCase(NewUseCaseNo: Integer;NewTestCaseNo: Integer;NewDescription: Text[100];NewTestScriptCompleted: Boolean)
    begin
        TestCase.Validate("Project Code",'CETAF');
        TestCase."Entry No." += 1;
        TestCase."Use Case No." := NewUseCaseNo;
        TestCase."Test Case No." := NewTestCaseNo;
        TestCase.Description := NewDescription;
        TestCase."Testscript Completed" := NewTestScriptCompleted;
        TestCase.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateIterations(NewTestCase: Record "Test Case";CreateAll: Boolean;RunOnUserRequest: Boolean)
    begin
        IncrSteps := 10;

        TestIteration.Reset();
        TestCase.Reset();
        if not CreateAll then begin
          NewTestCase.TestField("Use Case No.");
          NewTestCase.TestField("Test Case No.");
          TestIteration.SetRange("Use Case No.",NewTestCase."Use Case No.");
          TestIteration.SetRange("Test Case No.",NewTestCase."Test Case No.");
          TestCase.SetRange("Use Case No.",NewTestCase."Use Case No.");
          TestCase.SetRange("Test Case No.",NewTestCase."Test Case No.");
        end;

        TestIteration.DeleteAll();

        if TestCase.Find('-') then
          repeat
            case TestCase."Use Case No." of
              1:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations1-1"();
                  2:
                      "CreateIterations1-2"();
                  3:
                      "CreateIterations1-3"();
                  4:
                      "CreateIterations1-4"();
                  5:
                      "CreateIterations1-5"();
                  else
                      CreateUndefinedIteration();
                end;
              2:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations2-1"();
                  2:
                      "CreateIterations2-2"();
                  4:
                      "CreateIterations2-4"();
                  5:
                      "CreateIterations2-5"();
                  6:
                      "CreateIterations2-6"();
                  7:
                      "CreateIterations2-7"();
                  else
                      CreateUndefinedIteration();
                end;
              3:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations3-1"();
                  2:
                      "CreateIterations3-2"();
                  3:
                      "CreateIterations3-3"();
                  4:
                      "CreateIterations3-4"();
                  else
                      CreateUndefinedIteration();
                end;
              4:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations4-1"();
                  2:
                      "CreateIterations4-2"();
                  3:
                      "CreateIterations4-3"();
                  else
                      CreateUndefinedIteration();
                end;
              5:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations5-1"();
                  3:
                      "CreateIterations5-3"();
                  4:
                      "CreateIterations5-4"();
                  5:
                      "CreateIterations5-5"();
                  else
                      CreateUndefinedIteration();
                end;
              6:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations6-1"();
                  3:
                      "CreateIterations6-3"();
                  4:
                      "CreateIterations6-4"();
                  5:
                      "CreateIterations6-5"();
                  else
                      CreateUndefinedIteration();
                end;
              7:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations7-1"();
                  2:
                      "CreateIterations7-2"();
                  3:
                      "CreateIterations7-3"();
                  5:
                      "CreateIterations7-5"();
                  6:
                      "CreateIterations7-6"();
                  7:
                      "CreateIterations7-7"();
                  8:
                      "CreateIterations7-8"();
                  9:
                      "CreateIterations7-9"();
                  10:
                      "CreateIterations7-10"();
                  11:
                      "CreateIterations7-11"();
                  12:
                      "CreateIterations7-12"();
                  13:
                      "CreateIterations7-13"();
                  14:
                      "CreateIterations7-14"();
                  15:
                      "CreateIterations7-15"();
                  17:
                      "CreateIterations7-17"();
                  18:
                      "CreateIterations7-18"();
                  19:
                      "CreateIterations7-19"();
                  20:
                      "CreateIterations7-20"();
                  21:
                      "CreateIterations7-21"();
                  22:
                      "CreateIterations7-22"();
                  23:
                      "CreateIterations7-23"();
                  24:
                      "CreateIterations7-24"();
                  25:
                      "CreateIterations7-25"();
                  26:
                      "CreateIterations7-26"();
                  else
                      CreateUndefinedIteration();
                end;
              13:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations13-1"();
                  2:
                      "CreateIterations13-2"();
                  3:
                      "CreateIterations13-3"();
                  4:
                      "CreateIterations13-4"();
                  5:
                      "CreateIterations13-5"();
                  6:
                      "CreateIterations13-6"();
                  else
                      CreateUndefinedIteration();
                end;
              14:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations14-1"();
                  2:
                      "CreateIterations14-2"();
                  3:
                      "CreateIterations14-3"();
                  4:
                      "CreateIterations14-4"();
                  5:
                      "CreateIterations14-5"();
                  else
                      CreateUndefinedIteration();
                end;
              15:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations15-1"();
                  2:
                      "CreateIterations15-2"();
                  3:
                      "CreateIterations15-3"();
                  else
                      CreateUndefinedIteration();
                end;
              16:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations16-1"();
                  2:
                      "CreateIterations16-2"();
                  3:
                      "CreateIterations16-3"();
                  4:
                      "CreateIterations16-4"();
                  5:
                      "CreateIterations16-5"();
                  else
                      CreateUndefinedIteration();
                end;
              18:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations18-1"();
                  2:
                      "CreateIterations18-2"();
                  3:
                      "CreateIterations18-3"();
                  4:
                      "CreateIterations18-4"();
                  else
                      CreateUndefinedIteration();
                end;
              19:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations19-1"();
                  2:
                      "CreateIterations19-2"();
                  3:
                      "CreateIterations19-3"();
                  else
                      CreateUndefinedIteration();
                end;
              else
                  CreateUndefinedIteration();
            end;
          until TestCase.Next() = 0;

        if RunOnUserRequest then
          Message('Test Iterations were successfully created.');
    end;

    local procedure "CreateIterations1-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Post the order as (partly) received');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 24.01.01');
        InsertIteration(6,'Enter Qty. To Receive');
        InsertIteration(6,'Post the order as (partly) received');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Posting Date: 25.01.01');
        InsertIteration(8,'Enter Qty. To Receive');
        InsertIteration(8,'Post the order as received');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Dimensions and Purchase Header');
        InsertIteration(10,'Insert Purchase Lines');
        InsertIteration(10,'Insert Item Charges for Purchase Order');
        InsertIteration(10,'Insert Item Charges for Purchase Receipt');
        InsertIteration(10,'Post the order as received and invoiced');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as (partly) received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 03.01.01');
        InsertIteration(4,'Enter Qty. To Receive');
        InsertIteration(4,'Post the order as (partly) received');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 05.01.01');
        InsertIteration(6,'Enter Qty. To Receive');
        InsertIteration(6,'Post the order as received');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as (partly) received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Post the order as (partly) received');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 04.01.01');
        InsertIteration(6,'Enter Qty. To Receive');
        InsertIteration(6,'Post the order as (partly) received');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Posting Date: 05.01.01');
        InsertIteration(8,'Enter Qty. To Receive');
        InsertIteration(8,'Post the order as received');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Purchase Header');
        InsertIteration(10,'Insert Purchase Lines');
        InsertIteration(10,'Post the order as received and invoiced');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Post Inventory Cost to G/L');
        InsertIteration(13,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Add Item Tracking Code for Item 2_LI_RA');
        InsertIteration(2,'Assign Item Charge');
        InsertIteration(2,'Post the order as received and invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Add Item Tracking Code for Item 2_LI_RA');
        InsertIteration(4,'Assign Item Charge');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Sales Invoice');
        InsertIteration(6,'Get Sales Shipment Lines');
        InsertIteration(6,'Post the invoice');
        InsertIteration(6,'Run Report Delete Invoiced Sales Orders');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Line');
        InsertIteration(2,'Post the order as received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 03.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Post the order as invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as (partly) received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 02.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Enter Cost Distribution Lines');
        InsertIteration(4,'Post the order as (partly) invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 03.01.01');
        InsertIteration(6,'Enter Qty. To Invoice');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the order as (partly) invoiced');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Posting Date: 04.01.01');
        InsertIteration(8,'Enter Qty. To Invoice');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the order as (partly) invoiced');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 02.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Enter Cost Distribution Lines');
        InsertIteration(4,'Post the order as (partly) invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 03.01.01');
        InsertIteration(6,'Enter Qty. To Invoice');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the order as (partly) invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Posting Date: 04.01.01');
        InsertIteration(8,'Enter Qty. To Invoice');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the order as (partly) invoiced');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 02.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-6"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 02.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-7"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Posting Date: 02.01.01');
        InsertIteration(4,'Enter Qty. To Invoice');
        InsertIteration(4,'Post the order as invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Posting Date: 03.01.01');
        InsertIteration(6,'Enter Qty. To Invoice');
        InsertIteration(6,'Post the order as invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped & invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped & invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 030101');
        InsertIteration(6,'Modify Purchase Lines');
        InsertIteration(6,'Post the order as received & invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Purchase Header');
        InsertIteration(8,'Insert Purchase Lines');
        InsertIteration(8,'Post the return order as shipped & invoiced');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 030101');
        InsertIteration(6,'Modify Purchase Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the order as received & invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 040101');
        InsertIteration(8,'Modify Purchase Lines');
        InsertIteration(8,'Post the order as received & invoiced');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Purchase Header');
        InsertIteration(10,'Insert Purchase Lines');
        InsertIteration(10,'Post the return order as shipped & invoiced');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations4-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations4-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations4-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 020101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Posting Date 030101');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the order as received & invoiced');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Purchase Header');
        InsertIteration(8,'Insert Purchase Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the return order as shipped & invoiced');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 030101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Post the return order as shipped & invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Post the return order as shipped & invoiced');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Enter Qty. To Assign');
        InsertIteration(2,'Post the invoice');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the return order as shipped & invoiced');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Post the order as received');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the invoice');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the invoice');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the order as received & invoiced');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Posting Date 030101');
        InsertIteration(4,'Modify Purchase Lines');
        InsertIteration(4,'Post the order as received & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Purchase Header');
        InsertIteration(6,'Insert Purchase Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the invoice');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post the invoice');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Header');
        InsertIteration(4,'Insert Purchase Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the invoice');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Item REVAL Journal Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-6"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Enter Item Transfer Journal Lines');
        InsertIteration(12,'Post Item Transfer Journal Lines');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Adjust Cost - Item Entries');
        InsertIteration(14,'Calculate Inventory Value');
        InsertIteration(15,'Verify Post Conditions');
        InsertIteration(16,'Enter new Inventory Value');
        InsertIteration(16,'Post Item Journal Lines');
        InsertIteration(17,'Verify Post Conditions');
        InsertIteration(18,'Adjust Cost - Item Entries');
        InsertIteration(18,'Post Inventory Cost to G/L');
        InsertIteration(19,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-7"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Reclass. Journal Lines');
        InsertIteration(4,'Post Reclass. Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Reclass. Journal Lines');
        InsertIteration(6,'Post Reclass. Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Item Journal Lines');
        InsertIteration(8,'Post Item Journal Lines');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Enter Item Journal Lines');
        InsertIteration(10,'Post Item Journal Lines');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Calculate Inventory Value');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Enter new Inventory Value');
        InsertIteration(14,'Post Item Journal Lines');
        InsertIteration(14,'Adjust Cost - Item Entries');
        InsertIteration(14,'Post Inventory Cost to G/L');
        InsertIteration(15,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-8"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Reclass. Journal Lines');
        InsertIteration(4,'Post Reclass. Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Reclass. Journal Lines');
        InsertIteration(6,'Post Reclass. Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Reclass. Journal Lines');
        InsertIteration(8,'Post Reclass. Journal Lines');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Enter Item REVAL Journal Lines');
        InsertIteration(10,'Post Item REVAL Journal Lines');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-9"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post consumption for B1');
        InsertIteration(4,'Post output from B1');
        InsertIteration(4,'Finish production order B1');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post consumption for A1');
        InsertIteration(8,'Post output from A1');
        InsertIteration(8,'Finish production order A1');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Sell one piece of item A');
        InsertIteration(12,'Post Inventory Cost to G/L');
        InsertIteration(13,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-10"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Finish production order B1');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post consumption for A1');
        InsertIteration(4,'Post output from A1');
        InsertIteration(4,'Finish production order A1');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Sell one piece of item A');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(8,'Enter new Inventory Value');
        InsertIteration(8,'Post Item Journal Lines');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-11"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Post consumption for A1');
        InsertIteration(2,'Post output from A1');
        InsertIteration(2,'Finish production order A1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Sell one piece of item A');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(4,'Enter new Inventory Value');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-12"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Post consumption for A1');
        InsertIteration(2,'Post output from A1');
        InsertIteration(2,'Finish production order A1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Sell one piece of item A');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(4,'Enter new Inventory Value');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-13"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Post neg. consumption for B1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post consumption for A1');
        InsertIteration(4,'Post output from A1');
        InsertIteration(4,'Finish production order A1');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Sell one piece of item A');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-14"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(2,'Post consumption for A1');
        InsertIteration(2,'Post output from A1');
        InsertIteration(2,'Finish production order A1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Sell one piece of item A');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(4,'Enter new Inventory Value');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-15"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Post consumption for A1');
        InsertIteration(2,'Post output from A1');
        InsertIteration(2,'Finish production order A1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Sell one piece of item A');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(4,'Enter new Inventory Value');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-17"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Purchase WIP item C');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Post output from B1');
        InsertIteration(2,'Finish production order B1');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post consumption for A1');
        InsertIteration(4,'Post output from A1');
        InsertIteration(4,'Finish production order A1');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Sell one piece of item A');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-18"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Production Orders');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory Value');
        InsertIteration(4,'Enter new Inventory Value');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post output from B1');
        InsertIteration(6,'Calculate Inventory Value');
        InsertIteration(6,'Enter new Inventory Value');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Finish production order B1');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Enter Item Journal Lines');
        InsertIteration(10,'Post Item Journal Lines');
        InsertIteration(10,'Post consumption for D1');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Enter Item Journal Lines');
        InsertIteration(12,'Post Item Journal Lines');
        InsertIteration(12,'Adjust Cost - Item Entries');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Calculate Inventory Value');
        InsertIteration(14,'Enter new Inventory Value');
        InsertIteration(14,'Post Item Journal Lines');
        InsertIteration(14,'Enter Item Journal Lines');
        InsertIteration(14,'Post Item Journal Lines');
        InsertIteration(14,'Adjust Cost - Item Entries');
        InsertIteration(15,'Verify Post Conditions');
        InsertIteration(16,'Enter Item Journal Lines');
        InsertIteration(16,'Post Item Journal Lines');
        InsertIteration(16,'Post output from D1');
        InsertIteration(16,'Calculate Inventory Value');
        InsertIteration(16,'Enter new Inventory Value');
        InsertIteration(16,'Post Item Journal Lines');
        InsertIteration(17,'Verify Post Conditions');
        InsertIteration(18,'Finish production order D1');
        InsertIteration(18,'Enter Item Journal Lines');
        InsertIteration(18,'Post Item Journal Lines');
        InsertIteration(18,'Adjust Cost - Item Entries');
        InsertIteration(18,'Post Inventory Cost to G/L');
        InsertIteration(19,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-19"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Production Order');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Post consumption for B1');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post output from B1');
        InsertIteration(4,'Enter Item Journal Lines for B');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Post all Purchase Orders as invoiced');
        InsertIteration(4,'Finish production order B1');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-20"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Calculate Items for manufactoring');
        InsertIteration(1,'Modify Qty. per in ProdBOMLine Item A');
        InsertIteration(1,'Setup Inventory');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Create released Production Order');
        InsertIteration(2,'Refresh created Production Order');
        InsertIteration(2,'Calc. consumption for Production Order');
        InsertIteration(2,'Modify Qty for Item B + C and post');
        InsertIteration(2,'Create Output Jnl. for Production Order A');
        InsertIteration(2,'Explode Routing for Production Order A');
        InsertIteration(2,'Modify Qty. for Production Order A and post');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Modify Standard Cost for Item B + C');
        InsertIteration(4,'Calc. consumption for Production Order');
        InsertIteration(4,'Modify Qty to neg. for Item B + C');
        InsertIteration(4,'Post consumption');
        InsertIteration(4,'Create Output Jnl. for Production Order A');
        InsertIteration(4,'Explode Routing for Production Order A');
        InsertIteration(4,'Modify Qty for Item A and post');
        InsertIteration(4,'Post Purchase Order as invoiced');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(4,'Enter Item Journal Lines for A');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-21"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Item Journal Reclass Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Reclass Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Purchase Invoice');
        InsertIteration(8,'Get posted Purchase Receipt');
        InsertIteration(8,'Modify Purchase Invoice Lines');
        InsertIteration(8,'Post Purchase Invoice');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations7-22"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Sales Order Header and Lines');
        InsertIteration(2,'Post the order as shipped and invoiced');
        InsertIteration(2,'Insert Purchase Invoice Header and Lines');
        InsertIteration(2,'Post the order');
        InsertIteration(2,'Insert Sales Invoice Header and Lines');
        InsertIteration(2,'Post the order');
        InsertIteration(2,'Insert Sales Credit Memo and Lines');
        InsertIteration(2,'Post the Credit Memo');
        InsertIteration(2,'Insert Sales Credit Memo and Lines');
        InsertIteration(2,'Post the Credit Memo');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Enter Item Journal Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(4,'Enter Revaluation Journal Lines');
        InsertIteration(4,'Post Revaluation Journal Lines');
        InsertIteration(5,'Create released Production Order');
        InsertIteration(5,'Refresh created Production Order');
        InsertIteration(5,'Create Output Jnl. for Production Order A');
        InsertIteration(5,'Explode Routing for Production Order A');
        InsertIteration(5,'Post Output Journal Lines');
        InsertIteration(5,'Create Output Jnl. for Production Order A');
        InsertIteration(5,'Post Output Journal Lines');
        InsertIteration(6,'Enter Item Journal Line for item C and post it');
        InsertIteration(6,'Post Consumption for the Production Order');
        InsertIteration(6,'Finish the Production Order');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations7-23"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Enter Item Journal Reclass Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Insert Purchase Invoice');
        InsertIteration(2,'Get posted Purchase Receipt');
        InsertIteration(2,'Modify Purchase Invoice Lines');
        InsertIteration(2,'Post Purchase Invoice');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Order Header and Lines');
        InsertIteration(4,'Post the order');
        InsertIteration(4,'Insert Purchase Order Header and Lines');
        InsertIteration(4,'Post the order');
        InsertIteration(4,'Insert Purchase Credit Memo and Lines');
        InsertIteration(4,'Post the Credit Memo');
        InsertIteration(4,'Insert Sales Credit Memo and Lines');
        InsertIteration(4,'Post the Credit Memo');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations7-24"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post Purchase Order as received and invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Transfer Header');
        InsertIteration(4,'Insert Transfer Lines');
        InsertIteration(4,'Post Transfer Order as Ship and Receive');
        InsertIteration(4,'Enter Item Journal Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Assign Item Charge');
        InsertIteration(6,'Post Sales Order as shipped and invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations7-25"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(2,'Insert Sec. Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create released Production Order');
        InsertIteration(4,'Refresh created Production Order');
        InsertIteration(4,'Post Consump Jnl. for Item C');
        InsertIteration(4,'Create Output Jnl. for Production Order B');
        InsertIteration(4,'Explode Routing for Production Order B');
        InsertIteration(4,'Modify Output Quantity for Production Order B');
        InsertIteration(4,'Post Output Journal Lines');
        InsertIteration(4,'Create new Output Jnl. for Production Order B');
        InsertIteration(4,'Modify neg. Output Quantity for Production Order B');
        InsertIteration(4,'Post Output Journal Lines');
        InsertIteration(4,'Create new Output Jnl. for Production Order B');
        InsertIteration(4,'Explode Routing for Production Order B');
        InsertIteration(4,'Modify Output Quantity for Production Order B');
        InsertIteration(4,'Post Output Journal Lines');
        InsertIteration(4,'Finish Production Order');
        InsertIteration(4,'Insert Purchase Invoice');
        InsertIteration(4,'Get posted Purchase Receipt');
        InsertIteration(4,'Post Purchase Invoice');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Post Sales Order as shipped and invoiced');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Calculate Inventory Value');
        InsertIteration(8,'Post Item Journal Lines');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations7-26"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Items 1_FI_RE and 4_AV_RE');
        InsertIteration(2,'Insert Sales Order for 1_FI_RE');
        InsertIteration(2,'Post Order as shipped and invoiced');
        InsertIteration(2,'Insert Sec. Sales Order for 1_FI_RE');
        InsertIteration(2,'Post Order as shipped');
        InsertIteration(2,'Undo posted Sales Shipment');
        InsertIteration(2,'Post Sales Order as as shipped and invoiced');
        InsertIteration(2,'Insert Purchase Order for 1_FI_RE');
        InsertIteration(2,'Post Order as received and invoiced');
        InsertIteration(2,'Insert Sales Order for 1_FI_RE');
        InsertIteration(2,'Post Order as shipped and invoiced');
        InsertIteration(2,'Adjust Cost - Item Entries');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Order for 4_AV_RE');
        InsertIteration(4,'Post Order as shipped and invoiced');
        InsertIteration(4,'Insert Sec. Sales Order for 4_AV_RE');
        InsertIteration(4,'Post Order as shipped');
        InsertIteration(4,'Undo posted Sales Shipment');
        InsertIteration(4,'Post Sales Order as as shipped and invoiced');
        InsertIteration(4,'Insert Purchase Order for 4_AV_RE');
        InsertIteration(4,'Post Order as received and invoiced');
        InsertIteration(4,'Insert Sales Order for 4_AV_RE');
        InsertIteration(4,'Post Order as shipped and invoiced');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 050101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Post the order as shipped');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 060101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Post the order as shipped');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 040101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Post the order as shipped');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify Posting Date 050101');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Post the order as shipped');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Post Purchase Order as received');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post Purchase Order as invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Post the order as shipped');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post the order as invoiced');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Purchase Header');
        InsertIteration(2,'Insert Purchase Lines');
        InsertIteration(2,'Assign Item Charge');
        InsertIteration(2,'Post Purchase Order as received and invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(4,'Insert Sales Return Order');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Assign Item Charge to Item');
        InsertIteration(4,'Assign Item Charge to Item from Shpt');
        InsertIteration(4,'Post the order as shipped and invoiced');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations13-6"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Insert Sales Header');
        InsertIteration(2,'Insert Sales Lines');
        InsertIteration(2,'Post the order as shipped and invoiced');
        InsertIteration(2,'Insert Sales Credit Memo');
        InsertIteration(2,'Insert Sales Lines');
        InsertIteration(2,'Assign Item Charge to Item from Shpt');
        InsertIteration(2,'Post the Credit Memo as shipped and invoiced');
        InsertIteration(3,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations14-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations14-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 060101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the order as shipped & invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 080101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Post the order as shipped & invoiced');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Posting Date 100101');
        InsertIteration(10,'Modify Sales Lines');
        InsertIteration(10,'Enter Qty. To Assign');
        InsertIteration(10,'Post the order as shipped & invoiced');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations14-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 040101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the order as invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 060101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the order as shipped & invoiced');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Enter Item Journal Lines');
        InsertIteration(10,'Post Item Journal Lines');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations14-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations14-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item REVAL Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 060101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Post the order as invoiced');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations15-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 040101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Post the order as shipped');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Header');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the return order as receive & invoiced');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations15-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Header');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Post the return order as receive');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations15-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 060101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Post the order as shipped');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Sales Header');
        InsertIteration(10,'Insert Sales Lines');
        InsertIteration(10,'Enter Qty. To Assign');
        InsertIteration(10,'Post the return order as receive & invoiced');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(10,'Post Inventory Cost to G/L');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations16-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Post the return order as receive');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify Credit Memo Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the return order as invoiced');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations16-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 030101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Post the order as shipped & invoiced');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Posting Date 040101');
        InsertIteration(8,'Modify Sales Lines');
        InsertIteration(8,'Post the order as shipped & invoiced');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Sales Header');
        InsertIteration(10,'Insert Sales Lines');
        InsertIteration(10,'Post the return order as receive');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Modify Credit Memo Lines');
        InsertIteration(12,'Enter Qty. To Assign');
        InsertIteration(12,'Post the return order as invoiced');
        InsertIteration(12,'Adjust Cost - Item Entries');
        InsertIteration(12,'Post Inventory Cost to G/L');
        InsertIteration(13,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations16-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoiced');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the return order as receive & invoiced');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations16-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Sales Header');
        InsertIteration(2,'Insert Sales Lines');
        InsertIteration(2,'Post the order as invoiced');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the return order as receive & invoiced');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations16-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Enter Qty. To Assign');
        InsertIteration(4,'Post the invoice');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the return order as shipped & invoiced');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Enter Item Journal Lines');
        InsertIteration(8,'Post Item Journal Lines');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations18-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Post the order as shipped');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Header');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the invoice');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations18-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoice');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Post the order as shipped & invoice');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Header');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the invoice');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations18-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Post Inventory Cost to G/L');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the order as shipped & invoice');
        InsertIteration(4,'Post Inventory Cost to G/L');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Posting Date 040101');
        InsertIteration(6,'Modify Sales Lines');
        InsertIteration(6,'Post the order as invoice');
        InsertIteration(6,'Post Inventory Cost to G/L');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Header');
        InsertIteration(8,'Insert Sales Lines');
        InsertIteration(8,'Enter Qty. To Assign');
        InsertIteration(8,'Post the invoice');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(8,'Post Inventory Cost to G/L');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations18-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Enter Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Post the invoice');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Header');
        InsertIteration(6,'Insert Sales Lines');
        InsertIteration(6,'Enter Qty. To Assign');
        InsertIteration(6,'Post the invoice');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations19-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Create Purchase Invoice');
        InsertIteration(2,'Post Purchase Invoice');
        InsertIteration(2,'Create Transfer Order');
        InsertIteration(2,'Post Transfer Order Ship');
        InsertIteration(2,'Post Transfer Order Receive');
        InsertIteration(2,'Create Sales Invoice');
        InsertIteration(2,'Post Sales Invoice');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Purchase Invoice');
        InsertIteration(4,'Post Purchase Invoice');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Purchase Order');
        InsertIteration(8,'Post Purchase Order');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Create Sales Credit Memo');
        InsertIteration(10,'Post Sales Credit Memo');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Calculate Inventory Value');
        InsertIteration(12,'Modify Item Journal Lines ');
        InsertIteration(12,'Post Item Journal Lines ');
        InsertIteration(12,'Adjust Cost - Item Entries');
        InsertIteration(12,'Post Inventory Cost to G/L');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Create Sales Invoice');
        InsertIteration(14,'Post Sales Invoice');
        InsertIteration(14,'Create Purchase Credit Memo');
        InsertIteration(14,'Post Purchse Credit Memo');
        InsertIteration(14,'Adjust Cost - Item Entries');
        InsertIteration(14,'Calculate Inventory Value');
        InsertIteration(15,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations19-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Post Purchase Order');
        InsertIteration(2,'Create Transfer Order');
        InsertIteration(2,'Post Transfer Order Ship');
        InsertIteration(2,'Post Transfer Order Receive');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Post Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Purchase Order');
        InsertIteration(4,'Post Purchase Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Purchase Order');
        InsertIteration(8,'Post Purchase Order');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Modify Purchase Lines');
        InsertIteration(10,'Post the order as received');
        InsertIteration(10,'Modify Purchase Lines');
        InsertIteration(10,'Post the order as received');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Modify Purchase Lines');
        InsertIteration(12,'Post the order as invoiced');
        InsertIteration(12,'Modify Purchase Lines');
        InsertIteration(12,'Post the order as invoiced');
        InsertIteration(12,'Adjust Cost - Item Entries');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Create Sales Return Order');
        InsertIteration(14,'Post Sales Return Order');
        InsertIteration(15,'Verify Post Conditions');
        InsertIteration(16,'Calculate Inventory Value');
        InsertIteration(16,'Enter new Inventory Values');
        InsertIteration(16,'Post Item Journal');
        InsertIteration(16,'Adjust Cost - Item Entries');
        InsertIteration(16,'Post Inventory Cost to G/L');
        InsertIteration(16,'Create Purchase Return Order');
        InsertIteration(16,'Post Purchase Return Order');
        InsertIteration(17,'Verify Post Conditions');
        InsertIteration(18,'Create Sales Invoice');
        InsertIteration(18,'Post Sales Invoice');
        InsertIteration(18,'Modify Purchase Return Order');
        InsertIteration(18,'Post Purchase Return Order');
        InsertIteration(18,'Modify Sales Return Order');
        InsertIteration(18,'Post Sales Return Order');
        InsertIteration(18,'Adjust Cost - Item Entries');
        InsertIteration(18,'Calc. Inventory Value');
        InsertIteration(19,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations19-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify BOM');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Post Purchase Order');
        InsertIteration(2,'Create Production Order 3_SP_RE');
        InsertIteration(2,'Create Production Order 3_SP_RE');
        InsertIteration(2,'Change Variant Code, Component Lines 3_SP_RE');
        InsertIteration(2,'Create Production Order A');
        InsertIteration(2,'Create Production Order B');
        InsertIteration(2,'Create Production Order C');
        InsertIteration(2,'Create Production Order D');
        InsertIteration(2,'Create Consumption Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Purchase Order');
        InsertIteration(4,'Post Purchase Order');
        InsertIteration(4,'Create Output Journal');
        InsertIteration(4,'Adjust Cost - Item Entries');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Consupmtion Journal');
        InsertIteration(6,'Create Output Journal with Serial No.');
        InsertIteration(6,'Adjust Cost - Item Entries');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Sales Invoice');
        InsertIteration(8,'Post Sales Invoice');
        InsertIteration(8,'Post Purchase Order as Invoiced');
        InsertIteration(8,'Adjust Cost - Item Entries');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Purchase Order as Invoiced');
        InsertIteration(10,'Adjust Cost - Item Entries');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure CreateUndefinedIteration()
    begin
        InsertIteration(1, GetUndefinedText());
    end;

    local procedure InsertIteration(IterationNo: Integer;Description: Text[50])
    begin
        TestIteration."Use Case No." := TestCase."Use Case No.";
        TestIteration."Test Case No." := TestCase."Test Case No.";
        TestIteration."Iteration No." := IterationNo;
        TestIteration."Step No." := GetNextStepNo();
        TestIteration.Description := Description;
        TestIteration.Insert();

        OldTestIteration := TestIteration;
    end;

    [Scope('OnPrem')]
    procedure GetNextStepNo(): Integer
    begin
        if (TestIteration."Use Case No." <> OldTestIteration."Use Case No.") or
           (TestIteration."Test Case No." <> OldTestIteration."Test Case No.") or
           (TestIteration."Iteration No." <> OldTestIteration."Iteration No.")
        then
          OldTestIteration."Step No." := 0;
        exit(OldTestIteration."Step No." + IncrSteps);
    end;

    [Scope('OnPrem')]
    procedure GetUndefinedText(): Text[50]
    begin
        exit('Not yet defined');
    end;
}

