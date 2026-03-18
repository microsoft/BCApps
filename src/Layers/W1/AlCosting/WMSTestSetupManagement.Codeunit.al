codeunit 103304 "WMS TestSetupManagement"
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
        CODEUNIT.Run(Codeunit::"BW TestSetupManagement");
    end;

    var
        UseCase: Record "Whse. Use Case";
        TestCase: Record "Whse. Test Case";
        TestIteration: Record "Whse. Test Iteration";
        OldTestIteration: Record "Whse. Test Iteration";
        IncrSteps: Integer;

    [Scope('OnPrem')]
    procedure CreateUseCases()
    begin
        UseCase.Reset();
        UseCase.SetRange("Project Code",'WMS');
        UseCase.DeleteAll();
        InsertUseCase(2,'Receive Items from Purchase Order');
        InsertUseCase(3,'Put away Items according to Put-away Template');
        InsertUseCase(4,'Changing Bin and Quantity on Put-away Document');
        InsertUseCase(5,'Working with Outbound Deliveries');
        InsertUseCase(6,'Assign Items to be Picked');
        InsertUseCase(7,'Confirm Pick');
        InsertUseCase(8,'Move Items from Bin to Bin');
        InsertUseCase(9,'Adjust Bin Content');
        InsertUseCase(10,'Physical Inventory in Warehouse');
        InsertUseCase(11,'Physical Inventory Adjustment');
        InsertUseCase(15,'Receive Items from Production Order');
        InsertUseCase(16,'Return from a Production Order');
        InsertUseCase(17,'Pick for Released Production Order');
        InsertUseCase(18,'Manual Consumption for Production Order');
        InsertUseCase(19,'Pick for Open Shop Floor Bin');
        InsertUseCase(20,'Automatic Consumption for Open Shop Floor Bin');
        InsertUseCase(21,'Inbound and Outbound Item Movement');
        InsertUseCase(22,'Integration to Manufactoring');
        InsertUseCase(23,'Picks and Reservations');
        InsertUseCase(25,'Undo Receipt');
        InsertUseCase(26,'Convert Location to WMS');
        InsertUseCase(27,'Non WMS Item Tracking');
        InsertUseCase(28,'Lot tracked Items and UoM >1');
    end;

    [Scope('OnPrem')]
    procedure InsertUseCase(NewUseCaseNo: Integer;NewDescription: Text[100])
    begin
        UseCase."Project Code" := 'WMS';
        UseCase."Use Case No." := NewUseCaseNo;
        UseCase.Description := NewDescription;
        UseCase.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTestCases()
    begin
        TestCase.Reset();
        TestCase.SetRange("Project Code",'WMS');
        TestCase.DeleteAll();
        InsertTestCase(2,1,'Receive Items from Purchase Order',true);
        InsertTestCase(2,2,'Receive Multiple Purchase Orders',true);
        InsertTestCase(2,3,'Receive Items from a Transfer Order',true);
        InsertTestCase(2,4,'Receive Items from a Sales Return Order',true);
        InsertTestCase(3,1,'Find Bin according to STD Template',true);
        InsertTestCase(3,2,'Find Bin according to VAR Template',true);
        InsertTestCase(3,3,'Put-away Documents created automatically',true);
        InsertTestCase(4,1,'Normal Sequence',true);
        InsertTestCase(5,1,'Create a Shipment out of a Sales Order',true);
        InsertTestCase(5,2,'Ship multiple Sales Orders',true);
        InsertTestCase(5,3,'Ship Items from a Purchase Return Order',true);
        InsertTestCase(5,4,'Create Shipment for a Transfer Order',true);
        InsertTestCase(6,1,'Normal Sequence',true);
        InsertTestCase(6,3,'Select Types of Picking',true);
        InsertTestCase(7,1,'Normal Sequence',true);
        InsertTestCase(8,1,'Normal Sequence',true);
        InsertTestCase(8,2,'Create Movement Lines',true);
        InsertTestCase(8,3,'Bin Replenishment',true);
        InsertTestCase(9,1,'Positive Adjustment',true);
        InsertTestCase(9,2,'Negative Adjustment',true);
        InsertTestCase(10,1,'Normal Sequence',true);
        InsertTestCase(11,1,'Normal Sequence',true);
        InsertTestCase(15,1,'Normal Sequence',true);
        InsertTestCase(16,1,'Normal Sequence',true);
        InsertTestCase(17,1,'Normal Sequence',true);
        InsertTestCase(17,2,'Pick Activities created directly',true);
        InsertTestCase(17,3,'Pick Items for a Pick Order',true);
        InsertTestCase(18,1,'Normal Sequence',true);
        InsertTestCase(19,1,'Use Pick Order',true);
        InsertTestCase(19,2,'Use Replenishment Batch Job',true);
        InsertTestCase(20,1,'Normal Sequence',true);
        InsertTestCase(21,1,'Standard flow put-away deleted',true);
        InsertTestCase(21,2,'Standard flow put-away splitted',true);
        InsertTestCase(21,3,'Standard flow put-away bin change',true);
        InsertTestCase(21,4,'Standard flow multiple Sales Orders',true);
        InsertTestCase(21,5,'Standard flow Sales Return Order',true);
        InsertTestCase(21,10,'Standard flow Cross-Dock',true);
        InsertTestCase(21,11,'Standard Flow - Purchase Quote',true);
        InsertTestCase(21,12,'Standard Flow - Blanket Order',true);
        InsertTestCase(21,13,'Standard Flow - Combine Shipment and Item Tracking',true);
        InsertTestCase(21,14,'Standard Flow - Reservation - Transfer',true);
        InsertTestCase(21,15,'Standard Flow - Date compression case 1',true);
        InsertTestCase(21,16,'Standard Flow - Date compression case 2',true);
        InsertTestCase(21,17,'Standard Flow - Partial Receive / Ship',true);
        InsertTestCase(22,1,'Picking auto flushed components',true);
        InsertTestCase(22,2,'Picking auto flushed components (Pick)',true);
        InsertTestCase(22,3,'Pick from different Locations',true);
        InsertTestCase(22,8,'Create Pick for Lot tracked Components',true);
        InsertTestCase(22,9,'Consump. of Bwrd/Fwrd flushed Components and Rt.',true);
        InsertTestCase(22,10,'Consump. of Pick-Bwrd/Fwrd flushed Comp. and Rt.',true);
        InsertTestCase(23,1,'Reserve from Sales Line - Normal Flow',true);
        InsertTestCase(23,2,'Availabilty Calculation',true);
        InsertTestCase(23,3,'Handling within the Warehouse',true);
        InsertTestCase(23,4,'Reservation against different Source Documents',true);
        InsertTestCase(23,5,'Respecting reserved Quantity within the Warehouse',true);
        InsertTestCase(23,6,'IT item to pick already reserved with special IT info',true);
        InsertTestCase(23,7,'Item to be picked not yet received / not yet produced',true);
        InsertTestCase(25,1,'Undo Receipt with invoiced Item charge assigned',true);
        InsertTestCase(25,2,'Undo Receipt with different Put-away UoM and different locations',true);
        InsertTestCase(25,3,'Undo Receipt with Put-away Worksheet lines',true);
        InsertTestCase(25,4,'Undo Receipt of Cross-docked items',true);
        InsertTestCase(25,5,'Purchase order and Sales Return Order split into several Receipts',true);
        InsertTestCase(26,1,'Convert a non Whse. Location into a WMS Location',true);
        InsertTestCase(26,2,'Convert a WM Location into a WMS Location',true);
        InsertTestCase(27,1,'Assign Serial / Lot Number at Receipt',true);
        InsertTestCase(27,2,'Select Serial / Lot Number when Shipping',true);
        InsertTestCase(28,1,'Standard Flow',true);
        InsertTestCase(28,2,'Warehouse Adjustment Bin and Internal Warehouse Transactions',true);
        InsertTestCase(28,3,'Reservation and Transfer',true);
        InsertTestCase(28,4,'Create Pick for Lot tracked Components ',true);
        InsertTestCase(28,5,'Consumption of Lot tracked Backward or Forward flushed Components with Routing ',true);
        InsertTestCase(28,6,'Consumption of Lot tracked Pick + Backward / Pick + Forward flushed Components with Routing',true);
    end;

    [Scope('OnPrem')]
    procedure InsertTestCase(NewUseCaseNo: Integer;NewTestCaseNo: Integer;NewDescription: Text[100];NewTestScriptCompleted: Boolean)
    begin
        TestCase."Entry No." += 1;
        TestCase."Project Code" := 'WMS';
        TestCase."Use Case No." := NewUseCaseNo;
        TestCase."Test Case No." := NewTestCaseNo;
        TestCase.Description := NewDescription;
        TestCase."Testscript Completed" := NewTestScriptCompleted;
        TestCase.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateIterations(NewTestCase: Record "Whse. Test Case";CreateAll: Boolean;RunOnUserRequest: Boolean)
    begin
        IncrSteps := 10;

        TestIteration.Reset();
        TestCase.Reset();
        if not CreateAll then begin
          NewTestCase.TestField("Project Code");
          NewTestCase.TestField("Use Case No.");
          NewTestCase.TestField("Test Case No.");
          TestIteration.SetRange("Project Code",NewTestCase."Project Code");
          TestIteration.SetRange("Use Case No.",NewTestCase."Use Case No.");
          TestIteration.SetRange("Test Case No.",NewTestCase."Test Case No.");
          TestCase.SetRange("Project Code",NewTestCase."Project Code");
          TestCase.SetRange("Use Case No.",NewTestCase."Use Case No.");
          TestCase.SetRange("Test Case No.",NewTestCase."Test Case No.");
        end;

        TestIteration.SetRange("Project Code",'WMS');
        TestIteration.DeleteAll();
        TestCase.SetRange("Project Code",'WMS');

        if TestCase.Find('-') then
          repeat
            case TestCase."Use Case No." of
              2:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations2-1"();
                  2:
                      "CreateIterations2-2"();
                  3:
                      "CreateIterations2-3"();
                  4:
                      "CreateIterations2-4"();
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
                  else
                      CreateUndefinedIteration();
                end;
              4:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations4-1"();
                  else
                      CreateUndefinedIteration();
                end;
              5:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations5-1"();
                  2:
                      "CreateIterations5-2"();
                  3:
                      "CreateIterations5-3"();
                  4:
                      "CreateIterations5-4"();
                  else
                      CreateUndefinedIteration();
                end;
              6:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations6-1"();
                  3:
                      "CreateIterations6-3"();
                  else
                      CreateUndefinedIteration();
                end;
              7:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations7-1"();
                  else
                      CreateUndefinedIteration();
                end;
              8:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations8-1"();
                  2:
                      "CreateIterations8-2"();
                  3:
                      "CreateIterations8-3"();
                  else
                      CreateUndefinedIteration();
                end;
              9:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations9-1"();
                  2:
                      "CreateIterations9-2"();
                  else
                      CreateUndefinedIteration();
                end;
              10:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations10-1"();
                  else
                      CreateUndefinedIteration();
                end;
              11:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations11-1"();
                  else
                      CreateUndefinedIteration();
                end;
              15:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations15-1"();
                  else
                      CreateUndefinedIteration();
                end;
              16:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations16-1"();
                  else
                      CreateUndefinedIteration();
                end;
              17:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations17-1"();
                  2:
                      "CreateIterations17-2"();
                  3:
                      "CreateIterations17-3"();
                  else
                      CreateUndefinedIteration();
                end;
              18:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations18-1"();
                  else
                      CreateUndefinedIteration();
                end;
              19:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations19-1"();
                  2:
                      "CreateIterations19-2"();
                  else
                      CreateUndefinedIteration();
                end;
              20:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations20-1"();
                  else
                      CreateUndefinedIteration();
                end;
              21:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations21-1"();
                  2:
                      "CreateIterations21-2"();
                  3:
                      "CreateIterations21-3"();
                  4:
                      "CreateIterations21-4"();
                  5:
                      "CreateIterations21-5"();
                  10:
                      "CreateIterations21-10"();
                  11:
                      "CreateIterations21-11"();
                  12:
                      "CreateIterations21-12"();
                  13:
                      "CreateIterations21-13"();
                  14:
                      "CreateIterations21-14"();
                  15:
                      "CreateIterations21-15"();
                  16:
                      "CreateIterations21-16"();
                  17:
                      "CreateIterations21-17"();
                  else
                      CreateUndefinedIteration();
                end;
              22:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations22-1"();
                  2:
                      "CreateIterations22-2"();
                  3:
                      "CreateIterations22-3"();
                  8:
                      "CreateIterations22-8"();
                  9:
                      "CreateIterations22-9"();
                  10:
                      "CreateIterations22-10"();
                  else
                      CreateUndefinedIteration();
                end;
              23:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations23-1"();
                  2:
                      "CreateIterations23-2"();
                  3:
                      "CreateIterations23-3"();
                  4:
                      "CreateIterations23-4"();
                  5:
                      "CreateIterations23-5"();
                  6:
                      "CreateIterations23-6"();
                  7:
                      "CreateIterations23-7"();
                  else
                      CreateUndefinedIteration();
                end;
              25:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations25-1"();
                  2:
                      "CreateIterations25-2"();
                  3:
                      "CreateIterations25-3"();
                  4:
                      "CreateIterations25-4"();
                  5:
                      "CreateIterations25-5"();
                  else
                      CreateUndefinedIteration();
                end;
              26:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations26-1"();
                  2:
                      "CreateIterations26-2"();
                  else
                      CreateUndefinedIteration();
                end;
              27:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations27-1"();
                  2:
                      "CreateIterations27-2"();
                  else
                      CreateUndefinedIteration();
                end;
              28:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations28-1"();
                  2:
                      "CreateIterations28-2"();
                  3:
                      "CreateIterations28-3"();
                  4:
                      "CreateIterations28-4"();
                  5:
                      "CreateIterations28-5"();
                  6:
                      "CreateIterations28-6"();
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

    local procedure "CreateIterations2-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Whse. Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Modify Whse. Receipt Lines');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Create and Release 3 Purchase Orders');
        InsertIteration(2,'Create Whse. Receipt Header');
        InsertIteration(2,'Create Whse. Receipt Lines using Selection Filter');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Modify Whse. Receipt Lines');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Whse. Receipt Header');
        InsertIteration(6,'Create Whse. Receipt Lines using Selected Document');
        InsertIteration(6,'Autofill Qty. to Handle');
        InsertIteration(6,'Post Whse. Receipt');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post 3 Purchase Orders as invoiced');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Create Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Transfer Order');
        InsertIteration(4,'Post Transfer Order as shipped');
        InsertIteration(4,'Create Transfer Order');
        InsertIteration(4,'Post Transfer Order as shipped');
        InsertIteration(4,'Create Whse. Receipt for Transfer Order');
        InsertIteration(4,'Create Transfer Order');
        InsertIteration(4,'Post Transfer Order as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Whse. Receipt Lines');
        InsertIteration(6,'Post Whse. Receipt');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Whse. Receipt Header');
        InsertIteration(8,'Create Whse. Receipt Lines using Selection Filter');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Modify Whse. Receipt Lines');
        InsertIteration(10,'Post Whse. Receipt');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Create and Release 4 Sales Return Orders');
        InsertIteration(2,'Create Whse. Receipt Header');
        InsertIteration(2,'Create Whse. Receipt Lines using Selection Filter');
        InsertIteration(2,'Post Whse. Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Whse. Receipt for 4. Sales Return Order');
        InsertIteration(4,'Modify Whse. Receipt Lines');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Whse. Receipt Header');
        InsertIteration(6,'Create Whse. Receipt Lines using Selected Document');
        InsertIteration(6,'Autofill Qty. to Handle');
        InsertIteration(6,'Post Whse. Receipt');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(1,'Modify Items');
        InsertIteration(2,'Insert Whse. Adjust.Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Purchase Order');
        InsertIteration(4,'Create Whse. Receipt from Purchase Order');
        InsertIteration(4,'Autofill Qty. to Handle');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Put-away Wksh.-Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Autofill Qty. to Handle');
        InsertIteration(8,'Create Put-away Activity');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Put-away Activity');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(1,'Modify Items');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Purchase Order');
        InsertIteration(4,'Create Whse. Receipt Header');
        InsertIteration(4,'Create Whse. Receipt Lines using Selection Filter');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Put-away Wksh.-Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify Put-away Wksh.-Lines');
        InsertIteration(8,'Create Put-away Activity');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Put-away');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Autofill Qty. to Handle for Put-away Wksh.');
        InsertIteration(12,'Create Put-away Activity');
        InsertIteration(13,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(1,'Modify Items');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Purchase Order');
        InsertIteration(4,'Create Whse. Receipt Header');
        InsertIteration(4,'Create Whse. Receipt Lines using Selection Filter');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations4-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Purchase Order');
        InsertIteration(4,'Create Whse. Receipt from Purchase Order');
        InsertIteration(4,'Autofill Qty. to Handle');
        InsertIteration(4,'Modify Whse. Receipt Lines');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Whse. Put-away Lines');
        InsertIteration(6,'Split Last Put-away Line');
        InsertIteration(6,'Modify created Whse. Put-away Line');
        InsertIteration(6,'Post Put-away Activity');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Sales Order');
        InsertIteration(4,'Release Sales Order');
        InsertIteration(4,'Create Whse. Shipment');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Whse. Shipment Lines');
        InsertIteration(6,'Create Pick');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post Pick');
        InsertIteration(8,'Post Whse. Shpt. as shipped and invoiced');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release 3 Sales Orders');
        InsertIteration(4,'Create Whse. Shipment Header');
        InsertIteration(4,'Create Whse. Shpt.-Lines using Selected Document');
        InsertIteration(4,'Create Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Pick');
        InsertIteration(6,'Post Whse. Shipment as shipped');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Purchase Return Order');
        InsertIteration(4,'Create Whse. Shipment Header');
        InsertIteration(4,'Create Whse. Shpt.-Lines using Selected Document');
        InsertIteration(4,'Create Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Pick');
        InsertIteration(6,'Post Whse. Shipment as shipped');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release 3 Transfer Orders');
        InsertIteration(4,'Create Whse. Shipment Header');
        InsertIteration(4,'Create Whse. Shpt. Lines using Selected Document');
        InsertIteration(4,'Create Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Pick');
        InsertIteration(6,'Modify Whse. Shipment Lines');
        InsertIteration(6,'Post Whse. Shipment');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl. Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Sales Order');
        InsertIteration(4,'Create and Release Transfer Order');
        InsertIteration(4,'Create Whse. Shipment for Transfer Order');
        InsertIteration(4,'Modify Whse. Shipment Lines for Transfer Order');
        InsertIteration(4,'Create Whse. Shpt.-Lines using Selection Filter');
        InsertIteration(4,'Modify Whse. Shipment Lines for Sales Order');
        InsertIteration(4,'Release Whse. Shipment');
        InsertIteration(4,'Create Pick Wksh.-Lines for Whse. Shipment');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Autofill Qty. to Handle for Pick Wksh.');
        InsertIteration(6,'Create Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Transfer Order');
        InsertIteration(4,'Create Whse. Shipment Header');
        InsertIteration(4,'Create Whse. Shpt.-Lines using Selected Document');
        InsertIteration(4,'Release Whse. Shipment');
        InsertIteration(4,'Create Pick Wksh.-Lines for Whse. Shipment');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Autofill Qty. to Handle for Pick Wksh.');
        InsertIteration(6,'Create Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Release Sales Order');
        InsertIteration(4,'Create Whse. Shipment Header');
        InsertIteration(4,'Create Whse. Shpt.-Lines using Selected Document');
        InsertIteration(4,'Create Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Whse. Movement Jnl.-Lines');
        InsertIteration(4,'Post Whse. Jnl.-Lines');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Whse. Movement Wksh. Lines');
        InsertIteration(4,'Call Function Create Movement');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Created Whse. Activity');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bin Contents');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Replenish Single Bin Content');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Call Function Create Movement');
        InsertIteration(6,'Replenish Bin Contents');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Call Function Create Movement');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Post Created Whse. Activity');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations9-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Bin with two Items, Adjust one');
        InsertIteration(4,'Post Whse. Jnl.-Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Bin with Uom Pallet, Adjust PCS');
        InsertIteration(6,'Post Whse. Jnl.-Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Bin with two Items, Adjust both');
        InsertIteration(8,'Post Whse. Jnl.-Lines');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Calc. Inventory Value for Item A_TEST');
        InsertIteration(10,'Modify New Unit Cost');
        InsertIteration(10,'Post Jnl.-Lines');
        InsertIteration(10,'Create Movement for A_TEST');
        InsertIteration(10,'Register created Movement');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations9-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Positive Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines and Item Jnl. Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Whse Negative Adjust. Jnl.-Lines');
        InsertIteration(4,'Post Whse. Jnl.-Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Bin with Uom Pallet, Adjust PCS');
        InsertIteration(6,'Post Whse. Jnl.-Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Bin with two Items, Adjust both');
        InsertIteration(8,'Post Whse. Jnl.-Lines');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations10-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Item Journal Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Warehouse Inventory');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Calculate Warehouse Inventory');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Modify Physical Inventory Jnl.-Lines');
        InsertIteration(10,'Post Whse. Jnl.-Lines');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations11-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Item Journal Lines');
        InsertIteration(4,'Post Item Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Calculate Warehouse Inventory');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify Physical Inventory Jnl.-Lines');
        InsertIteration(8,'Post Whse. Jnl.-Lines');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Calculate Item Jnl Physical Inventory');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Calculate Item Jnl Physical Inventory');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Post Whse. Jnl.-Lines');
        InsertIteration(15,'Verify Post Conditions');
    end;

    local procedure "CreateIterations15-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(1,'Modify Items');
        InsertIteration(2,'Insert and Post Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Insert and Post Item Journal Lines');
        InsertIteration(2,'Release E_PROD Production Order');
        InsertIteration(2,'Refresh Prod. Order with Forward Flushing');
        InsertIteration(2,'Release D_PROD Production Order');
        InsertIteration(2,'Refresh Prod. Order with Forward Flushing');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create and Post an Output Journal');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert a Put-away Order');
        InsertIteration(6,'Create Put-away Activity Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify the Put-away Activity Lines');
        InsertIteration(8,'Post Put-away Activity Lines');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations16-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert and Post Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Insert and Post Item Journal Lines');
        InsertIteration(2,'Release a Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Create Pick out of Production Order');
        InsertIteration(2,'Post Pick for Production Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post Consumption Journal');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert a Put-away Order');
        InsertIteration(6,'Create Put-away Activity Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post Put-away Activity Lines');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations17-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Block Bin Content');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Release a new Production Order');
        InsertIteration(4,'Refresh Production Order');
        InsertIteration(4,'Create Pick Wksh.-Lines for Prod. Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Autofill Quantity to Handle');
        InsertIteration(6,'Create Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations17-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Release a new Production Order');
        InsertIteration(4,'Refresh Production Order');
        InsertIteration(4,'Create Pick out of Production Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Warehouse Activity Lines Type Pick');
        InsertIteration(6,'Post Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations17-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create a new Pick Order');
        InsertIteration(4,'Release the Pick Order');
        InsertIteration(4,'Insert Whse. Movement Jnl.-Lines');
        InsertIteration(4,'Create Movement');
        InsertIteration(4,'Create Pick Wksh.-Lines for Pick Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Autofill Quantity to Handle');
        InsertIteration(6,'Create Pick with Options');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post Picks');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations18-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Release a Production Order');
        InsertIteration(4,'Refresh Production Order');
        InsertIteration(4,'Create Pick out of Production Order');
        InsertIteration(4,'Post Pick for Production Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Consumption Journal');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations19-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Whse. Movement Jnl.-Lines');
        InsertIteration(4,'Create Movement');
        InsertIteration(4,'Create a new Pick Order');
        InsertIteration(4,'Create Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Warehouse Activity Lines Type Pick');
        InsertIteration(6,'Post Pick');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations19-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Dedicated Bins');
        InsertIteration(1,'Location Setup');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Whse. Movement Jnl.-Lines');
        InsertIteration(4,'Create Movement');
        InsertIteration(4,'Insert a new Sales Order');
        InsertIteration(4,'Release Sales Order');
        InsertIteration(4,'Create Whse. Shipment');
        InsertIteration(4,'Modify Shipment Lines');
        InsertIteration(4,'Release Shipment');
        InsertIteration(4,'Post Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Run Replenishment Batch Job');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Movement');
        InsertIteration(8,'Post Replenishment Movement');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations20-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Location Setup');
        InsertIteration(1,'Modify Items');
        InsertIteration(2,'Insert Whse. Adjust. Jnl.-Lines');
        InsertIteration(2,'Post Whse. Jnl.-Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Create a new Pick Order');
        InsertIteration(2,'Create Pick');
        InsertIteration(2,'Post Pick');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Release a new Production Order');
        InsertIteration(4,'Refresh Prod. Order with Forward Flushing');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations21-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Sales Header');
        InsertIteration(2,'Insert Sales Lines');
        InsertIteration(2,'Insert Reservation Entry');
        InsertIteration(2,'Delete Sales Lines');
        InsertIteration(2,'Modify Sales Line');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(2,'Create Whse. Shipment from Sales Order');
        InsertIteration(3,'Insert Purchase Order');
        InsertIteration(3,'Insert Item Tracking Information');
        InsertIteration(3,'Modify Purchase Line');
        InsertIteration(3,'Release Purchase Order');
        InsertIteration(3,'Create Whse. Receipt from Purchase Order');
        InsertIteration(3,'Insert Item Tracking Information Lot No.');
        InsertIteration(3,'Post Whse. Receipt');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Delete created Put-away');
        InsertIteration(5,'Create Put-away from posted Receipt');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Register created Put-away');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Create Movement Worksheet');
        InsertIteration(9,'Assign Item Tracking Information');
        InsertIteration(9,'Modify Movement Worksheet');
        InsertIteration(9,'Create Movement from Movement Worksheet');
        InsertIteration(9,'Register created Movement');
        InsertIteration(10,'Verify Post Conditions');
        InsertIteration(11,'Create Pick from Shipment');
        InsertIteration(12,'Assign Serial Nos.');
        InsertIteration(12,'Register created Pick');
        InsertIteration(13,'Post Whse. Shipment as invoiced');
        InsertIteration(14,'Verify Post Conditions');
        InsertIteration(15,'Insert Whse. Adjust.Jnl.-Line');
        InsertIteration(15,'Change Description of Item 70000');
        InsertIteration(15,'Post Whse. Jnl.-Lines');
        InsertIteration(16,'Verify Post Conditions');
    end;

    local procedure "CreateIterations21-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Item Tracking Code Lotall');
        InsertIteration(1,'Modify Gen. Post. Setup');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Modify Purchase Lines');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Whse. Receipt from Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information Lot No.');
        InsertIteration(2,'Insert Lot No. Information');
        InsertIteration(2,'Post Whse. Receipt');
        InsertIteration(2,'Split Put-away Line');
        InsertIteration(2,'Register Put-away');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Modify Sales Lines');
        InsertIteration(4,'Release Sales Order');
        InsertIteration(4,'Create Whse. Shipment from Sales Order');
        InsertIteration(4,'Create Pick from Whse. Shipment');
        InsertIteration(4,'Assign Item Tracking Information');
        InsertIteration(4,'Register created Pick');
        InsertIteration(5,'Post Whse. Shipment as invoiced');
        InsertIteration(6,'Verify Post Conditions');
    end;

    local procedure "CreateIterations21-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Sales Header');
        InsertIteration(2,'Insert Sales Lines');
        InsertIteration(2,'Insert Reservation Entry');
        InsertIteration(2,'Modify Sales Line');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(2,'Create Whse. Shipment from Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Purchase Order');
        InsertIteration(4,'Insert Item Tracking Information');
        InsertIteration(4,'Modify Purchase Line');
        InsertIteration(4,'Release Purchase Order');
        InsertIteration(4,'Reserve Line from Sales Order');
        InsertIteration(4,'Create Whse. Receipt from Purchase Order');
        InsertIteration(4,'Insert Item Tracking Information Lot No.');
        InsertIteration(4,'Post Whse. Receipt');
        InsertIteration(4,'Change Put-away bin');
        InsertIteration(4,'Register Put-away');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Pick from Shipment');
        InsertIteration(6,'Register created Pick');
        InsertIteration(7,'Post Whse. Shipment as invoiced');
        InsertIteration(8,'Verify Post Conditions');
    end;

    local procedure "CreateIterations21-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Whse. Source Doc. Filter');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Whse. Receipt from Purchase Order');
        InsertIteration(2,'Post Whse. Receipt');
        InsertIteration(2,'Register Put-away');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines');
        InsertIteration(4,'Release Sales Order');
        InsertIteration(5,'Insert sec. Sales Header');
        InsertIteration(5,'Insert sec. Sales Lines');
        InsertIteration(5,'Release sec. Sales Order');
        InsertIteration(6,'Create Whse. Shipment Header');
        InsertIteration(6,'Insert Whse.Shpt "Get Source Doc..." for both');
        InsertIteration(6,'Create Pick from Whse. Shipment');
        InsertIteration(6,'Assign Serial Nos to Item Tracking');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Register created Pick');
        InsertIteration(9,'Post Whse. Shipment as invoiced');
        InsertIteration(10,'Verify Post Conditions');
    end;

    local procedure "CreateIterations21-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Location White');
        InsertIteration(1,'Modify Bin W-01-0002');
        InsertIteration(1,'Modify Item Unit of Measure');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Whse. Receipt from Purchase Order');
        InsertIteration(2,'Post Whse. Receipt');
        InsertIteration(2,'Change Put-away bin');
        InsertIteration(2,'Register Put-away');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Insert Sales Header');
        InsertIteration(4,'Insert Sales Lines and assign charge');
        InsertIteration(4,'Release Sales Order');
        InsertIteration(4,'Create Whse. Shipment from Sales Order');
        InsertIteration(4,'Create Pick from Whse. Shipment');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Register created Pick');
        InsertIteration(7,'Post Whse. Shipment as invoiced');
        InsertIteration(8,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-10"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Sales Order');
        InsertIteration(2,'Release Sales Order and create Whse. Shipment');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Receipt');
        InsertIteration(2,'Delete sec. Whse. Receipt Line');
        InsertIteration(2,'Operate Function Calculate Cross-Dock');
        InsertIteration(2,'Operate Function Autofill Qty. to Cross-Dock');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register the created Put-away');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create a Warehouse Receipt');
        InsertIteration(4,'Operate Function Calculate Cross-Dock');
        InsertIteration(4,'Operate Function Autofill Qty. to Cross-Dock');
        InsertIteration(4,'Post the Receipt');
        InsertIteration(4,'Modify Qty. to Handle WhseActivLine');
        InsertIteration(4,'Register Put-away');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Pick from Shipment');
        InsertIteration(6,'Assign Lot Nos.');
        InsertIteration(6,'Split Line Item 80002');
        InsertIteration(6,'Register created Pick');
        InsertIteration(6,'Post Whse. Shipment as shipped');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert and Release Sales Order');
        InsertIteration(8,'Insert Purchase Order');
        InsertIteration(8,'Assign LOT04 to Item 80002');
        InsertIteration(8,'Release Purchase Order, Create a Warehouse Receipt');
        InsertIteration(8,'Operate Function Calculate Cross-Dock');
        InsertIteration(8,'Operate Function Autofill Qty. to Cross-Dock');
        InsertIteration(8,'Post the Receive');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-11"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Create a Purchase Quote');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Operate Make Order');
        InsertIteration(2,'Release created Purchase Order');
        InsertIteration(2,'Create a Warehouse Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Modify Receipt Line');
        InsertIteration(4,'Post the Receipt');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-12"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Option Reserve Always for Items');
        InsertIteration(2,'Create a Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Assign Serial Nos to Item T_TEST');
        InsertIteration(2,'Release Order');
        InsertIteration(2,'Create a Warehouse Receipt');
        InsertIteration(2,'Modify Receipt Line');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post the second Receipt');
        InsertIteration(4,'Verify Serial and Lot Nos in Whse. Activity Line');
        InsertIteration(4,'Register created Put-aways');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create a Sales Blanket Order');
        InsertIteration(6,'Operate Make Order');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Release created Sales Order');
        InsertIteration(8,'Create Whse. Shipment');
        InsertIteration(8,'Create Pick from Shipment');
        InsertIteration(8,'Verify Serial and Lot Nos in Whse. Activity Line');
        InsertIteration(8,'Register Whse. Pick');
        InsertIteration(8,'Modify Shipment Line');
        InsertIteration(8,'Post Whse. Shipment');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-13"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Option Tracking only for Items');
        InsertIteration(2,'Create a Purchase Order');
        InsertIteration(2,'Assign Lot No. to Item 80002');
        InsertIteration(2,'Assign Lot No. and Serial Nos to Item T_TEST');
        InsertIteration(2,'Create a Sales Order');
        InsertIteration(2,'Reserve Sales Order with created Purchase Order');
        InsertIteration(2,'Release created Sales Order');
        InsertIteration(2,'Create Whse. Shipment');
        InsertIteration(2,'Modify Expected Receipt Date in Purchas Line');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Release Purchase Order');
        InsertIteration(4,'Create a Warehouse Receipt');
        InsertIteration(4,'Post the Receipt');
        InsertIteration(4,'Register created Whse. Put-away');
        InsertIteration(4,'Create Pick from Shipment');
        InsertIteration(4,'Register Whse. Pick');
        InsertIteration(4,'Post Whse. Shipment as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Operate Function Combine Shipments');
        InsertIteration(6,'Post created Sales Invoice');
        InsertIteration(6,'Operate Function Delete Invoiced Sales Orders');
        InsertIteration(6,'Post Purchase Order as invoiced');
        InsertIteration(6,'Create a new Sales Order');
        InsertIteration(6,'Auto Reserve Lines against stock');
        InsertIteration(6,'Release created Sales Order');
        InsertIteration(6,'Create Whse. Shipment');
        InsertIteration(6,'Create Pick from Shipment');
        InsertIteration(6,'Register Whse. Pick');
        InsertIteration(6,'Post Whse. Shipment as shipped');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-14"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Transfer Routes');
        InsertIteration(1,'Set SKUs for items');
        InsertIteration(2,'Create and Release Sales Orders');
        InsertIteration(2,'Operate Function Calculate Plan in Req. Wksh.');
        InsertIteration(2,'Operate Function Carry Out in Req. Wksh.');
        InsertIteration(2,'Add Line to created Purchase Order');
        InsertIteration(2,'Assign Lot No. and Serial Nos for Item T_TEST');
        InsertIteration(2,'Assign Lot No. for Item 80002');
        InsertIteration(2,'Post created Purchase Order as received');
        InsertIteration(2,'Add Line to created Transfer Order for Loc. RED');
        InsertIteration(2,'Post Transfer Order RED as shipped and invoiced');
        InsertIteration(2,'Post Sales Order RED as shipped and invoiced');
        InsertIteration(2,'Create a Warehouse Receipt');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Release Transfer Order');
        InsertIteration(2,'Create Shipment from Transfer Order');
        InsertIteration(2,'Create Pick from Shipment');
        InsertIteration(2,'Assign Serial and Lot No. to Pick Lines');
        InsertIteration(2,'Register created Pick');
        InsertIteration(2,'Post the Shipment as shipped');
        InsertIteration(2,'Create Whse. Receipt for Location WHITE');
        InsertIteration(2,'Operate Get Source Docs. for TransOrders shipped');
        InsertIteration(2,'Post created Warehouse Receipt');
        InsertIteration(2,'Register Put-away');
        InsertIteration(2,'Create Shipment from Customer 30000');
        InsertIteration(2,'Create Pick from created Shipment');
        InsertIteration(2,'Assign Item Tracking Information');
        InsertIteration(2,'Register created Pick');
        InsertIteration(2,'Post the Shipment as shipped and invoiced');
        InsertIteration(2,'Modify Vendor invoice No. in Purchase Order');
        InsertIteration(2,'Post Purchase Order as invoiced');
        InsertIteration(3,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-15"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Create a Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Receipt');
        InsertIteration(2,'Post the Receipt and register created Put-away');
        InsertIteration(2,'Create a Sales Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Shipment');
        InsertIteration(2,'Create and register Pick from Shipment');
        InsertIteration(2,'Post Whse. Shipment as shipped');
        InsertIteration(2,'Create a new Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Receipt');
        InsertIteration(2,'Post the Receipt and register created Put-away');
        InsertIteration(2,'Create a new Sales Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Shipment');
        InsertIteration(2,'Create and register Pick from Shipment');
        InsertIteration(2,'Post Whse. Shipment as shipped');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Run Date Compression for Item Ledger Entries');
        InsertIteration(4,'Run Date Compression for Warehouse Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-16"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Create a Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Receipt');
        InsertIteration(2,'Post the Receipt and register created Put-away');
        InsertIteration(2,'Create a Sales Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Shipment');
        InsertIteration(2,'Create and register Pick from Shipment');
        InsertIteration(2,'Post Whse. Shipment as shipped');
        InsertIteration(2,'Create a new Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Receipt');
        InsertIteration(2,'Post the Receipt and register created Put-away');
        InsertIteration(2,'Create a new Sales Order');
        InsertIteration(2,'Assign Lot Nos to Item 80002');
        InsertIteration(2,'Release Order, Create a Warehouse Shipment');
        InsertIteration(2,'Create and register Pick from Shipment');
        InsertIteration(2,'Post Whse. Shipment as shipped');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Run Date Compression for Item Ledger Entries');
        InsertIteration(4,'Run Date Compression for Warehouse Entries');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations21-17"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Create a Purchase Order');
        InsertIteration(2,'Release Order and create a Warehouse Receipt');
        InsertIteration(2,'Modify Receipt Line');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post the second Receipt and register Put-aways');
        InsertIteration(4,'Create a Sales Order');
        InsertIteration(4,'Release Order and create Whse. Shipment');
        InsertIteration(4,'Create Pick from Shipment');
        InsertIteration(4,'Register Whse. Pick');
        InsertIteration(4,'Modify Shipment Lines');
        InsertIteration(4,'Post Whse. Shipment');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations22-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Routing Lines');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(3,'Insert Production Order');
        InsertIteration(3,'Refresh Production Order');
        InsertIteration(3,'Autoreserv Item "F_TEST_BACKFLUSH');
        InsertIteration(3,'Modify Qty. per for Item "T_TEST');
        InsertIteration(3,'Reserve Qty. for Item "F_TEST_BACKFLUSHPICK');
        InsertIteration(3,'Modify Qty. per for Item "F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Insert ProdComp. for Item "F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Modify Qty. per for Item "1120');
        InsertIteration(4,'Create new ProdCompLines');
        InsertIteration(5,'Create Whse. Receipt from Purchase Order');
        InsertIteration(5,'Post Whse. Receipt');
        InsertIteration(5,'Register created Put-away');
        InsertIteration(5,'Post created Purchase Order as received');
        InsertIteration(5,'Create Whse. Wrksh. Lines');
        InsertIteration(5,'Create Whse. Movement from WhseWrksh. Lines');
        InsertIteration(5,'Register created Movement');
        InsertIteration(6,'Change Status created Prod. Order');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Pick from Production Order');
        InsertIteration(8,'Assign Serial Nos for Item T_TEST');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Register created Pick');
        InsertIteration(10,'Create Consumption Journal from Production Order');
        InsertIteration(10,'Post Consumption Journal');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Create Output Journal and Explode Route');
        InsertIteration(12,'Post Output Journal');
        InsertIteration(13,'Change Status created Prod. Order to finished');
        InsertIteration(14,'Verify Post Conditions');
    end;

    local procedure "CreateIterations22-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Routing Lines');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(3,'Insert Production Order');
        InsertIteration(3,'Refresh Production Order');
        InsertIteration(3,'Autoreserv Item "F_TEST_BACKFLUSH');
        InsertIteration(3,'Modify Qty. per for Item "T_TEST');
        InsertIteration(3,'Reserve Qty. for Item "F_TEST_BACKFLUSHPICK');
        InsertIteration(3,'Modify Qty. per for Item "F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Insert ProdComp. for Item "F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Modify Qty. per for Item "1120');
        InsertIteration(4,'Create new ProdCompLines');
        InsertIteration(5,'Create Whse. Receipt from Purchase Order');
        InsertIteration(5,'Post Whse. Receipt');
        InsertIteration(5,'Register created Put-away');
        InsertIteration(5,'Post created Purchase Order as received');
        InsertIteration(5,'Create Whse. Wrksh. Lines');
        InsertIteration(5,'Create Whse. Movement from WhseWrksh. Lines');
        InsertIteration(5,'Register created Movement');
        InsertIteration(6,'Change Status created Prod. Order');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Pick Worksheet from Whse. Source');
        InsertIteration(8,'Create Whse. Pick from WhseWrksh. Lines');
        InsertIteration(8,'Assign Serial Nos for Item T_TEST');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Register created Pick');
        InsertIteration(10,'Create Consumption Journal from Production Order');
        InsertIteration(10,'Post Consumption Journal');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Create Output Journal and Explode Route');
        InsertIteration(12,'Post Output Journal');
        InsertIteration(13,'Change Status created Prod. Order to finished');
        InsertIteration(14,'Verify Post Conditions');
    end;

    local procedure "CreateIterations22-3"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Zones for location BLUE');
        InsertIteration(1,'Set up Bins for location BLUE');
        InsertIteration(1,'Modify Location BLUE');
        InsertIteration(1,'Insert Worksheet for Location BLUE');
        InsertIteration(1,'Insert Routing Lines');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Whse. Receipts from Purchase Order');
        InsertIteration(2,'Post Whse. Receipts');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Post created Purchase Order as received');
        InsertIteration(3,'Insert Production Order');
        InsertIteration(3,'Refresh Production Order');
        InsertIteration(3,'Modify Qty. per for Item T_TEST');
        InsertIteration(3,'Modify Location for Item F_TEST_BACKFLUSHPICK');
        InsertIteration(3,'Modify Qty. per for Item F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Insert ProdComp. for Item F_TEST_FORWFLUSHPICK');
        InsertIteration(3,'Modify Location for Item 1120');
        InsertIteration(4,'Create Whse. Wrksh. Lines Location WHITE');
        InsertIteration(4,'Create Whse. Movement from WhseWrksh. Lines');
        InsertIteration(4,'Register created Movement');
        InsertIteration(4,'Create Whse. Wrksh. Lines Location BLUE');
        InsertIteration(4,'Create Whse. Movement from WhseWrksh. Lines');
        InsertIteration(4,'Register created Movement');
        InsertIteration(5,'Change Status created Prod. Order');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Create Pick from created Prod. Order');
        InsertIteration(7,'Assign Serial Nos for Item T_TEST');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Register created Pick');
        InsertIteration(9,'Create Consumption Journal from Production Order');
        InsertIteration(9,'Post Consumption Journal');
        InsertIteration(10,'Verify Post Conditions');
        InsertIteration(11,'Create Output Journal and Explode Route');
        InsertIteration(11,'Post Output Journal');
        InsertIteration(12,'Change Status created Prod. Order to finished');
        InsertIteration(13,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations22-8"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set LOTALL for Items');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Items');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Warehouse Receipt from PO');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Insert Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Lot Nos to Component Items');
        InsertIteration(2,'Create Warehouse Pick from Prod. Order');
        InsertIteration(3,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations22-9"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Items');
        InsertIteration(1,'Set LOTALL for Item');
        InsertIteration(1,'Create Bin Contents');
        InsertIteration(1,'Create Routing TEST');
        InsertIteration(1,'Calculate Work-Center calendar');
        InsertIteration(1,'Set up Item E_PROD with Routing Link TEST');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item B_TEST');
        InsertIteration(2,'Assign Serial Nos to Item T_TEST');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Warehouse Receipt from PO');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Calculate Replenishment');
        InsertIteration(2,'Create Movement');
        InsertIteration(2,'Assign Serial and Lot No to T_TEST');
        InsertIteration(2,'Assign Lot No to B_TEST');
        InsertIteration(2,'Register Movement');
        InsertIteration(2,'Insert firm planned Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Routing No. 100 to all Components');
        InsertIteration(2,'Assign Serial and Lot No. to Components');
        InsertIteration(2,'Change Prod Order Status to released');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Output Journal and Explode Route');
        InsertIteration(4,'Post Output Journal');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert 2. firm planned Production Order');
        InsertIteration(6,'Refresh Production Order');
        InsertIteration(6,'Assign Routing No. 100 to all Components');
        InsertIteration(6,'Change Flushing Methods');
        InsertIteration(6,'Assign Serial and Lot No. to Components');
        InsertIteration(6,'Change Prod Order Status to released');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Output Journal and Explode Route');
        InsertIteration(8,'Post Output Journal');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations22-10"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Items');
        InsertIteration(1,'Set LOTALL for Item');
        InsertIteration(1,'Create Routing TEST');
        InsertIteration(1,'Calculate Work-Center calendar');
        InsertIteration(1,'Set up Item E_PROD with Routing Link TEST');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Item B_TEST');
        InsertIteration(2,'Assign Serial Nos to Item T_TEST');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Warehouse Receipt from PO');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Insert firm planned Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Routing No. 100 to all Components');
        InsertIteration(2,'Assign Serial and Lot No. to Components');
        InsertIteration(2,'Change Prod Order Status to released');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Pick from Prod. Order');
        InsertIteration(4,'Register created Pick');
        InsertIteration(4,'Create Output Journal and Explode Route');
        InsertIteration(4,'Post Output Journal');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert 2. firm planned Production Order');
        InsertIteration(6,'Refresh Production Order');
        InsertIteration(6,'Assign Routing No. 100 to all Components');
        InsertIteration(6,'Change Flushing Methods');
        InsertIteration(6,'Assign Serial and Lot No. to Components');
        InsertIteration(6,'Change Prod Order Status to released');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Pick from Prod. Order');
        InsertIteration(8,'Register created Pick');
        InsertIteration(8,'Create Output Journal and Explode Route');
        InsertIteration(8,'Post Output Journal');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-1"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Location White to Always Create Pick Lines');
        InsertIteration(1,'Insert dedicated Bins for test items');
        InsertIteration(1,'Create Purchase, Receive, Register Put-away');
        InsertIteration(2,'Insert Sales Order #1');
        InsertIteration(2,'Insert Sales Order #2');
        InsertIteration(2,'Insert Purchase Return Order');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-2"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Allow Breakbulk to false for White');
        InsertIteration(1,'Create initial stock in Warehouse White');
        InsertIteration(1,'Block Bin W-02-0002 for all movements');
        InsertIteration(2,'Insert Sales Order #1');
        InsertIteration(3,'Insert Purchase Order');
        InsertIteration(3,'Insert Item Tracking Information');
        InsertIteration(3,'Release Purchase Order');
        InsertIteration(3,'Create Whse. Receipt from Purchase Order, post it');
        InsertIteration(3,'Delete the Put-away and create Put-away Worksheet');
        InsertIteration(4,'Create Whse. Wrksh. Lines Location WHITE');
        InsertIteration(4,'Create Whse. Movement from WhseWrksh. Lines');
        InsertIteration(4,'Register created Movement');
        InsertIteration(5,'Insert Sales Order #2');
        InsertIteration(5,'Insert Sales Order #3');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-3"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Location White to Always Create Pick Lines');
        InsertIteration(1,'Create initial stock in Warehouse White / Blue');
        InsertIteration(2,'Insert Sales Order #1');
        InsertIteration(2,'Insert Sales Order #2');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-4"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Modify item 80100 and D_PROD');
        InsertIteration(1,'Create initial stock in Warehouse WHITE');
        InsertIteration(2,'Insert Sales Return Order');
        InsertIteration(3,'Create Transfer from Blue to White');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-5"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Create initial stock in Warehouse White');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-6"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Purchase Order #1');
        InsertIteration(3,'Insert Sales Order #1');
        InsertIteration(3,'Insert Sales Order #2');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations23-7"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Purchase Order #1');
        InsertIteration(3,'Insert Purchase Order #2');
        InsertIteration(4,'Insert Production Order');
        InsertIteration(5,'Insert Sales Order');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations25-1"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Location White to use Put-away Wksheet');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Assign Item charge, Release Order');
        InsertIteration(2,'Create a Warehouse Receipt');
        InsertIteration(2,'Set Qty to Receive 2');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(3,'Insert Sales Return Order');
        InsertIteration(3,'Assign Item charge, Release Order');
        InsertIteration(3,'Create a Warehouse Receipt');
        InsertIteration(3,'Set Qty to Receive 1');
        InsertIteration(3,'Post the Receipt');
        InsertIteration(4,'Undo the Purchase Receipt');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo the Return Receipt');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations25-2"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Modify item 80100 Put-away UoM = Box');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Create a Warehouse Receipt, Post it');
        InsertIteration(2,'Set Qty Put-away 2 Line 40000, Register Put-away');
        InsertIteration(2,'Post Line 10000, Qty 1 as invoiced');
        InsertIteration(2,'Delete the Put-away');
        InsertIteration(3,'Insert Sales Return Order');
        InsertIteration(3,'Create the Warehouse Receipts');
        InsertIteration(3,'Modify the Qty to Receive');
        InsertIteration(3,'Post the Receipts');
        InsertIteration(3,'Modify Sales Return lines and post the order');
        InsertIteration(3,'Delete the Put-away');
        InsertIteration(4,'Undo the Purchase Receipt Line 30000');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo the Return Receipt Lines 20000 - 40000');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations25-3"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Create a Warehouse Receipt, Post it');
        InsertIteration(2,'Post the Purchase Order as Invoiced');
        InsertIteration(2,'Delete the Put-away');
        InsertIteration(3,'Insert a new Purchase Order');
        InsertIteration(3,'Create a Warehouse Receipt, Post it');
        InsertIteration(3,'Enter Qty to Put-away 1, Register Put-away');
        InsertIteration(3,'Delete the Put-away');
        InsertIteration(4,'Insert Sales Return Order');
        InsertIteration(4,'Create a Warehouse Receipt, Post it');
        InsertIteration(4,'Delete the Put-away');
        InsertIteration(5,'Undo all Return Receipt Lines');
        InsertIteration(6,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations25-4"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set Location White to use Put-away Wksheet');
        InsertIteration(2,'Insert Sales Order');
        InsertIteration(2,'Release Order, Create Shipment');
        InsertIteration(3,'Create Released Production Order');
        InsertIteration(3,'Refresh Production Order');
        InsertIteration(4,'Insert Purchase Order');
        InsertIteration(4,'Release Order, Create a Warehouse Receipt');
        InsertIteration(4,'Calculate cross-Dock');
        InsertIteration(4,'Post the Receive');
        InsertIteration(5,'Insert Sales Return Order');
        InsertIteration(5,'Release Order, Create a Warehouse Receipt');
        InsertIteration(5,'Calculate cross-Dock');
        InsertIteration(5,'Post the Receive');
        InsertIteration(6,'Undo all Posted Purchase Receipt Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Undo all Return Receipt Lines');
        InsertIteration(9,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations25-5"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Sales Return Order');
        InsertIteration(2,'Create a Warehouse Receipt');
        InsertIteration(2,'Modify the Qty to Receive 20');
        InsertIteration(2,'Post the Receipt, Register Put-away');
        InsertIteration(2,'Modify the Qty to Receive 10');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Modify the Qty to Receive 25');
        InsertIteration(2,'Post the Receipt, Delete the Put-away');
        InsertIteration(2,'Create Warehouse Worksheet Lines for the Receipt');
        InsertIteration(2,'Modify the Qty to Receive 31');
        InsertIteration(2,'Post the Receipt, Delete the Put-away');
        InsertIteration(3,'Insert Purchase Order');
        InsertIteration(3,'Create a Warehouse Receipt');
        InsertIteration(3,'Modify the Qty to Receive 20');
        InsertIteration(3,'Post the Receipt, Register Put-away');
        InsertIteration(3,'Modify the Qty to Receive 10');
        InsertIteration(3,'Post the Receipt');
        InsertIteration(3,'Modify the Qty to Receive 25');
        InsertIteration(3,'Post the Receipt, Delete the Put-away');
        InsertIteration(3,'Create Warehouse Worksheet Lines for the Receipt');
        InsertIteration(3,'Modify the Qty to Receive 31');
        InsertIteration(3,'Post the Receipt, Delete the Put-away');
        InsertIteration(4,'Undo the last Purchase Receipt, Qty on line 31');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo the last Return Receipt, Qty on line 31');
        InsertIteration(7,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations26-1"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Modify item 80100 Put-away UoM = Box');
        InsertIteration(2,'Insert Purchase Order #1');
        InsertIteration(2,'Post as Received and Invoiced');
        InsertIteration(2,'Insert Sales Return Order');
        InsertIteration(2,'Post as Received');
        InsertIteration(2,'Insert Sales Order #1');
        InsertIteration(2,'Post as Shipped');
        InsertIteration(2,'Insert Purchase Order #2');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Post as Received');
        InsertIteration(2,'Insert Purchase Order #3');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Modify Quantity to Receive');
        InsertIteration(2,'Post as Received');
        InsertIteration(2,'Insert Sales Order #2');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Insert Reservations');
        InsertIteration(2,'Modify Quantity to Ship');
        InsertIteration(2,'Post as Shipped');
        InsertIteration(2,'Insert Production Order');
        InsertIteration(2,'Post Consumption');
        InsertIteration(2,'Post Output Quantity 10');
        InsertIteration(2,'Insert Transfer Order, post as shipped');
        InsertIteration(2,'Post a Item Journal, type Negative Adjustment');
        InsertIteration(2,'Insert Purchase Order #4, post as received');
        InsertIteration(2,'Undo the last Purchase Receipt #4');
        InsertIteration(2,'Insert Sales Order #3, post as partly shipped');
        InsertIteration(2,'Undo the last Shipment #3');
        InsertIteration(2,'Set Item A_TEST to Blocked = TRUE');
        InsertIteration(3,'Insert a Bin for Location Blue');
        InsertIteration(3,'Run Report to convert Location Blue');
        InsertIteration(4,'Set Item A_TEST to Blocked = FALSE');
        InsertIteration(4,'Calculate Inventory in Phys. Inventory Journals');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations26-2"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Modify item 80100 Put-away UoM = Box');
        InsertIteration(2,'Insert Purchase Order #1');
        InsertIteration(2,'Create a Warehouse Receipt and post it');
        InsertIteration(2,'Register the Put-away');
        InsertIteration(2,'Post the Order as Invoiced');
        InsertIteration(2,'Insert Sales Return Order');
        InsertIteration(2,'Create a Warehouse Receipt and post it');
        InsertIteration(2,'Register the Put-away');
        InsertIteration(2,'Insert Sales Order #1');
        InsertIteration(2,'Create a Shipment and a Pick');
        InsertIteration(2,'Register Pick and post Shipment and Invoice');
        InsertIteration(2,'Insert Purchase Order #2');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Create a Warehouse Receipt and post it');
        InsertIteration(2,'Register the Put-away');
        InsertIteration(2,'Insert Purchase Order #3');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Create a Warehouse Receipt modify Receive Qty');
        InsertIteration(2,'Post Receipt, Delete it, Register the Put-away');
        InsertIteration(2,'Insert Sales Order #2');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Insert Reservations');
        InsertIteration(2,'Create a Shipment and a Pick');
        InsertIteration(2,'Modify Pick Lines');
        InsertIteration(2,'Register Pick and post Shipment');
        InsertIteration(2,'Delete Pick and delete Shipment');
        InsertIteration(2,'Insert Production Order');
        InsertIteration(2,'Post Consumption');
        InsertIteration(2,'Post Output Quantity 10');
        InsertIteration(2,'Insert Transfer Order, post as shipped');
        InsertIteration(2,'Post a Item Journal, type Negative Adjustment');
        InsertIteration(2,'Insert Purchase Order #4, post as received');
        InsertIteration(2,'Delete the Put-away, Undo the last Receipt #4');
        InsertIteration(2,'Insert Sales Return Order, post as shipped');
        InsertIteration(2,'Delete the Put-away, Undo the last Receipt #2');
        InsertIteration(2,'Set Item A_TEST to Blocked = TRUE');
        InsertIteration(3,'Insert a Bin for Location Green');
        InsertIteration(3,'Run Report to convert Location Green');
        InsertIteration(4,'Set Item A_TEST to Blocked = FALSE');
        InsertIteration(4,'Calculate Inventory in Phys. Inventory Journals');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations27-1"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(2,'Insert Purchase Order #1');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Release Order and Create Warehouse Receipt');
        InsertIteration(3,'Modify Warehouse Receipt lines');
        InsertIteration(3,'Insert Item Tracking Informations');
        InsertIteration(3,'Post the Warehouse Receipt');
        InsertIteration(3,'Register the Put-away');
        InsertIteration(4,'Modify Warehouse Receipt lines');
        InsertIteration(4,'Insert Item Tracking Informations');
        InsertIteration(4,'Register the Put-away');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Insert Sales Return Order');
        InsertIteration(6,'Release Order and Create Warehouse Receipt');
        InsertIteration(7,'Modify Warehouse Receipt lines');
        InsertIteration(7,'Insert Item Tracking Informations');
        InsertIteration(7,'Post the Warehouse Receipt');
        InsertIteration(7,'Register the Put-away');
        InsertIteration(8,'Modify Warehouse Receipt lines');
        InsertIteration(8,'Insert Item Tracking Informations');
        InsertIteration(8,'Register the Put-away');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Purchase Order #2');
        InsertIteration(10,'Insert Item Tracking Information');
        InsertIteration(10,'Release Order and Create Warehouse Receipt');
        InsertIteration(10,'Post the Warehouse Receipt');
        InsertIteration(10,'Register the Put-away');
        InsertIteration(11,'Insert Purchase Invoice');
        InsertIteration(11,'Insert Item Charge line, Assign Item charge');
        InsertIteration(11,'Post the Invoice');
        InsertIteration(12,'Calculate Inventory in Phys. Inventory Journals');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Insert Purchase Order');
        InsertIteration(14,'Insert Item Tracking Information');
        InsertIteration(14,'Post the Purchase Order as received');
        InsertIteration(14,'Modify Quantity to invoice from Purchase Order');
        InsertIteration(14,'Post the Purchase Order as invoiced');
        InsertIteration(15,'Verify Post Conditions');
        InsertIteration(16,'Insert Sales Order');
        InsertIteration(16,'Insert Item Tracking Information');
        InsertIteration(16,'Post the Sales Order as shipped');
        InsertIteration(16,'Modify Quantity to invoice from Sales Order');
        InsertIteration(16,'Post the Sales Order as invoiced');
        InsertIteration(17,'Verify Post Conditions');
        InsertIteration(18,'Insert Sales Return Order');
        InsertIteration(18,'Insert Item Tracking Information');
        InsertIteration(18,'Post the Sales Return Order as shipped');
        InsertIteration(18,'Modify Qty. to invoice from Sales Return Order');
        InsertIteration(18,'Post the Sales Return Order as invoiced');
        InsertIteration(19,'Verify Post Conditions');
        InsertIteration(20,'Insert Purchase Return Order');
        InsertIteration(20,'Insert Item Tracking Information');
        InsertIteration(20,'Post the Purchase Return Order as received');
        InsertIteration(20,'Modify Qty. to invoice from Purchase Return Order');
        InsertIteration(20,'Post the Purchase Return Order as invoiced');
        InsertIteration(21,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations27-2"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Create Pick worksheet template for Green');
        InsertIteration(2,'Insert Item Journal, Positive Adjustment');
        InsertIteration(2,'Insert Item Tracking Information');
        InsertIteration(2,'Post the Journal');
        InsertIteration(3,'Insert Sales Order #1');
        InsertIteration(3,'Insert Item Tracking Information Blue');
        InsertIteration(3,'Release Order, Create Shipment and Release it');
        InsertIteration(4,'Create a Pick Worksheet');
        InsertIteration(4,'Enter Qty to Handle');
        InsertIteration(4,'Create a Pick');
        InsertIteration(4,'Insert Item Tracking Information');
        InsertIteration(4,'Register the Pick');
        InsertIteration(5,'Enter Qty to Handle');
        InsertIteration(5,'Create a Pick');
        InsertIteration(5,'Insert Item Tracking Information');
        InsertIteration(5,'Register the Pick');
        InsertIteration(6,'Post the Shipment');
        InsertIteration(6,'Post the Sales Order as shipped');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Item Journal, Positive Adjustment');
        InsertIteration(8,'Insert Item Tracking Information');
        InsertIteration(8,'Post the Journal');
        InsertIteration(9,'Insert Sales Order #2');
        InsertIteration(9,'Modify Quantity to Ship');
        InsertIteration(9,'Insert Item Tracking Information');
        InsertIteration(9,'Post the Sales Order as shipped');
        InsertIteration(10,'Verify Post Conditions');
        InsertIteration(11,'Modify Quantity to Ship');
        InsertIteration(11,'Insert Item Tracking Information');
        InsertIteration(11,'Post the Sales Order as shipped');
        InsertIteration(12,'Verify Post Conditions');
        InsertIteration(13,'Insert Purchase Return Order');
        InsertIteration(13,'Insert Item Tracking Information');
        InsertIteration(13,'Create a Shipment and a Pick');
        InsertIteration(13,'Register Pick and post Shipment');
        InsertIteration(14,'Insert Sales Invoice');
        InsertIteration(14,'Insert Item Charge line, Assign Item charge');
        InsertIteration(14,'Post the Invoice');
        InsertIteration(15,'Calculate Inventory in Phys. Inventory Journals');
        InsertIteration(16,'Verify Post Conditions');
    end;

    local procedure "CreateIterations28-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Itms and Location');
        InsertIteration(2,'Insert Purchase Order BLUE');
        InsertIteration(2,'Insert item tracking info');
        InsertIteration(2,'Post Purchase Order');
        InsertIteration(2,'Undo Purchase Receipt Line');
        InsertIteration(2,'Modify Purchase Order');
        InsertIteration(2,'Post Purchase Order');
        InsertIteration(2,'Insert Sales Order WHITE');
        InsertIteration(2,'Insert Transfer from BLUE to WHITE');
        InsertIteration(2,'Reserve transfer Lines for SO');
        InsertIteration(2,'Release Sales Order and create Shipment');
        InsertIteration(2,'Post Transfer as shipped');
        InsertIteration(2,'Create new Purchase Order for WHITE');
        InsertIteration(2,'Assign Item Tracking Information');
        InsertIteration(2,'Release Order create Receipt');
        InsertIteration(2,'Post Receipt');
        InsertIteration(2,'Modify Put-away lines and register partial');
        InsertIteration(2,'Create a Pick for the Shipment');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Receipt for the Transfer');
        InsertIteration(4,'Post the Receipt');
        InsertIteration(4,'Register all open Put-aways');
        InsertIteration(4,'Delete the Pick created before');
        InsertIteration(4,'Create a Pick for the Shipment');
        InsertIteration(4,'Register Pick');
        InsertIteration(4,'Post the Shipment as shipped');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Sales Order for White');
        InsertIteration(6,'Assign Item tracking');
        InsertIteration(6,'Assign Item Charge');
        InsertIteration(6,'Release order and create Shipment');
        InsertIteration(6,'Create Pick');
        InsertIteration(6,'Register created Pick');
        InsertIteration(6,'Post Whse. Shipment as invoiced');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Create Sales Order for White');
        InsertIteration(8,'Release order and create Shipment');
        InsertIteration(8,'Create Pick');
        InsertIteration(8,'Modify Pick lines');
        InsertIteration(8,'Register created Pick');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Register created Pick');
        InsertIteration(10,'Modify Shipment lines');
        InsertIteration(10,'Post Whse. Shipment as shipped');
        InsertIteration(11,'Verify Post Conditions');
        InsertIteration(12,'Post Whse. Shipment as invoiced');
        InsertIteration(12,'Create Sales Return Order WHITE');
        InsertIteration(12,'Assign Item tracking');
        InsertIteration(12,'Release order and create Receipt');
        InsertIteration(12,'Modify Receipt line and Post the Receipt');
        InsertIteration(12,'Delete Put-away');
        InsertIteration(12,'Undo Return Receipt');
        InsertIteration(12,'Create new receipt and get Sales Return Order');
        InsertIteration(12,'Post the Receipts');
        InsertIteration(12,'Register created Put-aways');
        InsertIteration(13,'Verify Post Conditions');
        InsertIteration(14,'Create Purchase Order for White');
        InsertIteration(14,'Assign Item tracking');
        InsertIteration(14,'Release order and create Receipt');
        InsertIteration(14,'Modify Receipt line and post the Receipt');
        InsertIteration(14,'Delete the Put-away');
        InsertIteration(14,'Undo the Purchase Receipt');
        InsertIteration(14,'Create new receipt and get Purchase Order');
        InsertIteration(14,'Modify the Receipt lines');
        InsertIteration(14,'Post the Receipts');
        InsertIteration(14,'Register created Put-aways');
        InsertIteration(15,'Verify Post Conditions');
        InsertIteration(16,'Create Purchase Return Order WHITE');
        InsertIteration(16,'Assign Item tracking');
        InsertIteration(16,'Release order and create Shipment');
        InsertIteration(16,'Create Pick');
        InsertIteration(16,'Register Pick');
        InsertIteration(17,'Verify Post Conditions');
    end;

    local procedure "CreateIterations28-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Modify Item Tracking Code Lotall');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Insert Item Tracking Information and release');
        InsertIteration(2,'Create Whse. Receipt from Purchase Order');
        InsertIteration(2,'Post Whse. Receipt');
        InsertIteration(2,'Register Put-away');
        InsertIteration(2,'Insert Sales Order');
        InsertIteration(2,'Insert Item Tracking Information and release');
        InsertIteration(2,'Create Whse. Shipment from Sales Order');
        InsertIteration(2,'Create Pick');
        InsertIteration(2,'Register Pick');
        InsertIteration(2,'Post Shipment as shipped');
        InsertIteration(2,'Insert Sales Order');
        InsertIteration(2,'Insert Item Tracking Information and release');
        InsertIteration(2,'Create Whse. Shipment from Sales Order');
        InsertIteration(2,'Create Pick');
        InsertIteration(2,'Register Pick');
        InsertIteration(2,'Post Shipment as shipped');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create new Whse Item Journal');
        InsertIteration(4,'Insert Item Tracking Information');
        InsertIteration(4,'Post Whse Item Journal');
        InsertIteration(4,'Create Inventory Item Journal');
        InsertIteration(4,'Insert Item Tracking Information');
        InsertIteration(4,'Post Inventory Item Journal');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Movement Worksheet');
        InsertIteration(6,'Insert Item Tracking Information');
        InsertIteration(6,'Create Movement');
        InsertIteration(6,'Register Movement');
        InsertIteration(6,'Create Internal Put-away');
        InsertIteration(6,'Create Put-away');
        InsertIteration(6,'Register Put-away');
        InsertIteration(6,'Create Internal Pick');
        InsertIteration(6,'Insert Item Tracking Information');
        InsertIteration(6,'Create Pick');
        InsertIteration(6,'Register Pick');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Sales Order');
        InsertIteration(8,'Reserve all lines against Stock');
        InsertIteration(8,'Release Sales Order');
        InsertIteration(8,'Create Whse. Shipment from Sales Order');
        InsertIteration(8,'Create Pick');
        InsertIteration(8,'Register Pick');
        InsertIteration(8,'Post the Shipment');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Insert Sales Return Order');
        InsertIteration(10,'Insert Item Tracking Information and release');
        InsertIteration(10,'Create Whse. Receive from Sales Order');
        InsertIteration(10,'Post the Receive');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations28-3"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Transfer Routes');
        InsertIteration(1,'Set SKUs for items');
        InsertIteration(2,'Create and Release Sales Orders');
        InsertIteration(2,'Operate Function Calculate Plan in Req. Wksh.');
        InsertIteration(2,'Operate Function Carry Out in Req. Wksh.');
        InsertIteration(2,'Modify the created Purchase Order');
        InsertIteration(2,'Assign Lot No. for the Items');
        InsertIteration(2,'Post created Purchase Order as received');
        InsertIteration(2,'Modify Lines for Transfer Order, assign Lot Nos.');
        InsertIteration(2,'Insert new Transfer Line, assign Lot Nos.');
        InsertIteration(2,'Post Transfer Order as shipped');
        InsertIteration(2,'Create Whse. Receipt for Location WHITE');
        InsertIteration(2,'Operate Get Source Docs. for TransOrders shipped');
        InsertIteration(2,'Post created Warehouse Receipt');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Register Put-away');
        InsertIteration(4,'Create Shipment for Order 30000');
        InsertIteration(4,'Create Pick from created Shipment');
        InsertIteration(4,'Assign Item Tracking Information');
        InsertIteration(4,'Register created Pick');
        InsertIteration(4,'Post the Shipment as shipped and invoiced');
        InsertIteration(4,'Modify Vendor Invoice No. in Purchase Order');
        InsertIteration(4,'Post Purchase Order as invoiced');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations28-4"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set LOTALL for Items');
        InsertIteration(1,'Modify BOM for E_PROD');
        InsertIteration(2,'Insert Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Items');
        InsertIteration(2,'Release Order and create Whse Receipt');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Insert Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Lot Nos to Component Items');
        InsertIteration(2,'Create Warehouse Pick from Prod. Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Register created Pick');
        InsertIteration(4,'Create Consumption Journal');
        InsertIteration(4,'Post Consumption Journal');
        InsertIteration(4,'Create Output Journal for Prod. Order');
        InsertIteration(4,'Post Output Journal');
        InsertIteration(4,'Finish Production Order');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations28-5"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Items for Flushing and Lotall');
        InsertIteration(1,'Modify Prod Bom E_PROD');
        InsertIteration(1,'Create Bin Contents');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Items');
        InsertIteration(2,'Release Purch. Order and create Warehouse Receipt');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Calculate Replenishment');
        InsertIteration(2,'Create Movement');
        InsertIteration(2,'Assign Lot No to Items');
        InsertIteration(2,'Register Movement');
        InsertIteration(2,'Insert firm planned Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Lot No. to Components');
        InsertIteration(2,'Change Prod Order Status to released');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Output Journal for Prod. Order');
        InsertIteration(4,'Post Output Journal');
        InsertIteration(4,'Finish Production Order');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure "CreateIterations28-6"()
    begin
        InsertIteration(1,'Set up Global Preconditions');
        InsertIteration(1,'Set up Items for Flushing and Lotall');
        InsertIteration(1,'Modify Prod Bom E_PROD');
        InsertIteration(1,'Create Bin Contents');
        InsertIteration(1,'Create Routing and Set up Item E_PROD with TEST ');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Assign Lot Nos to Items');
        InsertIteration(2,'Release Purch. Order and create Warehouse Receipt');
        InsertIteration(2,'Post the Receipt');
        InsertIteration(2,'Register created Put-aways');
        InsertIteration(2,'Insert firm planned Production Order');
        InsertIteration(2,'Refresh Production Order');
        InsertIteration(2,'Assign Lot No. to Components');
        InsertIteration(2,'Change Prod Order Status to released');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Pick from Prod. Order');
        InsertIteration(4,'Register created Pick');
        InsertIteration(4,'Create Output Journal for Prod. Order');
        InsertIteration(4,'Explode Routing');
        InsertIteration(4,'Post Output Journal');
        InsertIteration(4,'Finish Production Order');
        InsertIteration(5,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure CreateUndefinedIteration()
    begin
        InsertIteration(1, GetUndefinedText());
    end;

    local procedure InsertIteration(IterationNo: Integer;Description: Text[50])
    begin
        TestIteration."Project Code" := 'WMS';
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
        if (TestIteration."Project Code" <> OldTestIteration."Project Code") or
           (TestIteration."Use Case No." <> OldTestIteration."Use Case No.") or
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

