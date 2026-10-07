codeunit 103308 "BW TestSetupManagement"
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
        TestCase."Project Code" := 'BW';
        CreateIterations(TestCase,true,false);
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
        UseCase.SetRange("Project Code",'BW');
        UseCase.DeleteAll();
        InsertUseCase(1,'Post Inbound Item Movement');
        InsertUseCase(2,'Register Internal Movement of Items');
        InsertUseCase(3,'Post Outbound Item Movement');
        InsertUseCase(5,'Carry Out Physical Inventory');
        InsertUseCase(6,'Adjust Inventory');
        InsertUseCase(7,'Undo a Quantity Posting');
        InsertUseCase(8,'Post Consumption');
        InsertUseCase(9,'Post Output');
    end;

    [Scope('OnPrem')]
    procedure InsertUseCase(NewUseCaseNo: Integer;NewDescription: Text[100])
    begin
        UseCase."Project Code" := 'BW';
        UseCase."Use Case No." := NewUseCaseNo;
        UseCase.Description := NewDescription;
        UseCase.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTestCases()
    begin
        TestCase.Reset();
        TestCase.SetRange("Project Code",'BW');
        TestCase.DeleteAll();
        InsertTestCase(1,1,'Inbound Item Movement from Purchase Order',true);
        InsertTestCase(1,2,'Inbound Item Movement from Purchase Return Order',true);
        InsertTestCase(1,3,'Inbound Item Movement from Purchase Credit Memo',true);
        InsertTestCase(1,4,'Inbound Item Movement from Sales Order',true);
        InsertTestCase(1,5,'Inbound Item Movement from Sales Return Order',true);
        InsertTestCase(1,6,'Inbound Item Movement from Sales Credit Memo',true);
        InsertTestCase(1,7,'Inbound Item Movement from Transfer Order',true);
        InsertTestCase(1,13,'Inbound Purchase Order with split Put-Away lines',true);
        InsertTestCase(1,14,'Inbound Purchase Return Order (w Pick/Put-Away)',true);
        InsertTestCase(1,16,'Inbound Sales Order (w Pick/Put-Away)',true);
        InsertTestCase(1,17,'Inbound Sales Return Order (w Pick/Put-Away)',true);
        InsertTestCase(1,19,'Inbound Transfer Order (w Pick/Put-Away)',true);
        InsertTestCase(2,1,'Normal Sequence',true);
        InsertTestCase(2,2,'Move complete bin contents',true);
        InsertTestCase(3,1,'Outbound Item Movement from Purchase Order',true);
        InsertTestCase(3,2,'Outbound Item Movement from Purchase Return Order',true);
        InsertTestCase(3,3,'Outbound Item Movement from Purchase Credit Memo',true);
        InsertTestCase(3,4,'Outbound Item Movement from Sales Order',true);
        InsertTestCase(3,5,'Outbound Item Movement from Sales Return Order',true);
        InsertTestCase(3,6,'Outbound Item Movement from Sales Credit Memo',true);
        InsertTestCase(3,7,'Outbound Item Movement from Transfer Order',true);
        InsertTestCase(3,12,'Outbound Purchase Order (w Pick/Put-Away)',true);
        InsertTestCase(3,13,'Outbound Purchase Return Order (w Pick/Put-Away)',true);
        InsertTestCase(3,15,'Outbound Sales Order (w Pick/Put-Away)',true);
        InsertTestCase(3,16,'Outbound Sales Return Order (w Pick/Put-Away)',true);
        InsertTestCase(3,17,'Outbound Summery (w Pick/Put-Away)',true);
        InsertTestCase(5,1,'Normal Sequence',true);
        InsertTestCase(5,2,'Calculate Invt.: Items not on inventory',true);
        InsertTestCase(5,3,'Item-driven physical counting',true);
        InsertTestCase(6,1,'Positive Adjustment',true);
        InsertTestCase(6,2,'Negative Adjustment',true);
        InsertTestCase(6,3,'Negative Adjustment reduces Quantity below reserved quantity',true);
        InsertTestCase(7,1,'Undo a Quantity Posting of a Purchase Order',true);
        InsertTestCase(7,2,'Undo a Quantity Posting of a Purchase Return Order',true);
        InsertTestCase(7,3,'Undo a Quantity Posting of a Sales Order',true);
        InsertTestCase(7,4,'Undo a Quantity Posting of a Sales Return Order',true);
        InsertTestCase(8,1,'Normal Sequence',true);
        InsertTestCase(8,2,'Negative quantity and component not specified on production BOM',true);
        InsertTestCase(8,3,'Additional Picking',true);
        InsertTestCase(8,7,'Normal Sequence (w Pick/Put-Away)',true);
        InsertTestCase(8,8,'Neg. qty. and component not spec. on prod. BOM (w Pick/Put-Away)',true);
        InsertTestCase(8,9,'Additional Picking (w Pick/Put-Away)',true);
        InsertTestCase(9,1,'Normal Sequence',true);
        InsertTestCase(9,2,'Negative Quantity',true);
        InsertTestCase(9,5,'Normal Sequence (w Pick/Put-Away)',true);
    end;

    [Scope('OnPrem')]
    procedure InsertTestCase(NewUseCaseNo: Integer;NewTestCaseNo: Integer;NewDescription: Text[100];NewTestScriptCompleted: Boolean)
    begin
        TestCase."Entry No." += 1;
        TestCase."Project Code" := 'BW';
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

        TestIteration.SetRange("Project Code",'BW');
        TestIteration.DeleteAll();
        TestCase.SetRange("Project Code",'BW');

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
                  6:
                      "CreateIterations1-6"();
                  7:
                      "CreateIterations1-7"();
                  13:
                      "CreateIterations1-13"();
                  14:
                      "CreateIterations1-14"();
                  16:
                      "CreateIterations1-16"();
                  17:
                      "CreateIterations1-17"();
                  19:
                      "CreateIterations1-19"();
                  else
                      CreateUndefinedIteration();
                end;
              2:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations2-1"();
                  2:
                      "CreateIterations2-2"();
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
                  5:
                      "CreateIterations3-5"();
                  6:
                      "CreateIterations3-6"();
                  7:
                      "CreateIterations3-7"();
                  12:
                      "CreateIterations3-12"();
                  13:
                      "CreateIterations3-13"();
                  15:
                      "CreateIterations3-15"();
                  16:
                      "CreateIterations3-16"();
                  17:
                      "CreateIterations3-17"();
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
                  else
                      CreateUndefinedIteration();
                end;
              6:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations6-1"();
                  2:
                      "CreateIterations6-2"();
                  3:
                      "CreateIterations6-3"();
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
                  4:
                      "CreateIterations7-4"();
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
                  7:
                      "CreateIterations8-7"();
                  8:
                      "CreateIterations8-8"();
                  9:
                      "CreateIterations8-9"();
                  else
                      CreateUndefinedIteration();
                end;
              9:
                case TestCase."Test Case No." of
                  1:
                      "CreateIterations9-1"();
                  2:
                      "CreateIterations9-2"();
                  5:
                      "CreateIterations9-5"();
                  else
                      CreateUndefinedIteration();
                end;
              else
                  CreateUndefinedIteration();
            end;
          until TestCase.Next() = 0;

        if RunOnUserRequest then
          Message('Test Iterations have been created successfully.');
    end;

    local procedure "CreateIterations1-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup General Posting Setup');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Warehouse Receipt');
        InsertIteration(2,'Get Sourcedocument for Warehouse Receipt');
        InsertIteration(2,'Verify Post Conditions');
        InsertIteration(2,'Post Warehouse Receipt');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(2,'Create Purchase Return Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Release Purchase Return Order');
        InsertIteration(2,'Post Purchase Return Order');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup General Posting Setup');
        InsertIteration(2,'Create Purchase Credit Memo');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(2,'Create Item Charge Assignment');
        InsertIteration(2,'Release Purchase Credit Memo');
        InsertIteration(2,'Post Purchase Credit Memo');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Assign Item Charge');
        InsertIteration(2,'Assign Lot Nos.');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(2,'Post Sales Order as shipped and invoiced');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Create Sales Return Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Release Sales Return Order');
        InsertIteration(2,'Post Sales Return Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Modify Sales Return Order');
        InsertIteration(4,'Post Sales Return Order');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-6"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup General Posting Setup');
        InsertIteration(2,'Create Sales Credit Memo');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(2,'Create Item Charge Assignment');
        InsertIteration(2,'Release Sales Credit Memo');
        InsertIteration(2,'Post Sales Credit Memo');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-7"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Line');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Create Transfer Order');
        InsertIteration(3,'Run Function Get Bin Content');
        InsertIteration(3,'Modify Quantity created Transfer Line');
        InsertIteration(3,'Create Transfer - Lines using Selected Document');
        InsertIteration(3,'Release Transfer Order');
        InsertIteration(3,'Post Transfer Order as shipped');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Post Transfer Order as received');
        InsertIteration(6,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-13"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup General Posting Setup');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(2,'Enter Bin Code for Item 80002');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Purchase Order with man. No.');
        InsertIteration(2,'Release created Purchase Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Split Warehouse Activity Line');
        InsertIteration(7,'Post Warehouse Activity Lines');
        InsertIteration(7,'Post Purchase Order');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Create Sales Order');
        InsertIteration(9,'Create Sales - Lines using Selected Document');
        InsertIteration(9,'Release Sales Order');
        InsertIteration(9,'Create Warehouse Activity Lines');
        InsertIteration(9,'Split Warehouse Activity Line');
        InsertIteration(9,'Post Warehouse Activity Lines');
        InsertIteration(9,'Post Sales Order');
        InsertIteration(10,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-14"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(2,'Create Purchase Return Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Release Purchase Return Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Header');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Post Warehouse Activity Lines');
        InsertIteration(6,'Post Purchase Return Order');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-16"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Post Warehouse Activity Lines');
        InsertIteration(6,'Post Sales Order');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-17"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Create Sales Return Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Release Sales Return Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Post Warehouse Activity Lines');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Modify Sales Return Order');
        InsertIteration(9,'Create Warehouse Activity Lines');
        InsertIteration(10,'Verify Post Conditions');
        InsertIteration(10,'Autofill Qty. to Handle');
        InsertIteration(11,'Post Warehouse Activity Lines');
        InsertIteration(11,'Post Sales Return Order');
        InsertIteration(12,'Verify Post Conditions');
    end;

    local procedure "CreateIterations1-19"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Insert Item Journal Line');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Create Transfer Order');
        InsertIteration(3,'Run Function Get Bin Content');
        InsertIteration(3,'Modify Quantity created Transfer Line');
        InsertIteration(3,'Release Transfer Order');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Create Warehouse Activity Lines');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(6,'Autofill Qty. to Handle');
        InsertIteration(7,'Post Warehouse Activity Lines');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Create Warehouse Activity Lines');
        InsertIteration(10,'Verify Post Conditions');
        InsertIteration(10,'Autofill Qty. to Handle');
        InsertIteration(11,'Post Warehouse Activity Lines');
        InsertIteration(12,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Line');
        InsertIteration(3,'Insert Reservation Entry');
        InsertIteration(3,'Post Item Journal Lines');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Insert Item Reclassification Journal');
        InsertIteration(6,'Insert Reservation Entry');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations2-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Lines');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(2,'Get Bin Content in Item Reclass. Journal');
        InsertIteration(3,'Modify Item Reclass. Journal');
        InsertIteration(4,'Post Item Reclass. Journal Lines');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Enter Item in Reclass. Journal');
        InsertIteration(6,'Assign Lot Nos.');
        InsertIteration(7,'Post Item Reclass. Journal Line');
        InsertIteration(8,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Post Purchase Order');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Purchase Return Order');
        InsertIteration(3,'Reserve Items from Current Line');
        InsertIteration(4,'Release and Post Purchase Return Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Modify Purchase Return Order');
        InsertIteration(6,'Post Purchase Return Order');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Lines');
        InsertIteration(1,'Insert Item Tracking Lines');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Purchase Credit Memo');
        InsertIteration(2,'Insert Item Tracking Lines');
        InsertIteration(2,'Insert Item Charge Lines');
        InsertIteration(2,'Release Purchase Credit Memo');
        InsertIteration(2,'Post Purchase Credit Memo');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Insert Tracking Information');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Insert Sales Order Tracking Information');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(2,'Insert Whse. Shipment Header');
        InsertIteration(2,'Create Whse.Shpt.Lines "Get Source Documents..."');
        InsertIteration(2,'Verify Post Conditions');
        InsertIteration(2,'Post Whse. Shipment');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Sales Return Order');
        InsertIteration(2,'Release and Post Sales Return Order');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-6"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Insert Tracking Information');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Sales Credit Memo');
        InsertIteration(2,'Insert Sales Credit Memo Tracking Information');
        InsertIteration(2,'Insert Item Charge Information');
        InsertIteration(2,'Release and Post Sales Credit Memo');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-7"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Line');
        InsertIteration(2,'Post Item Journal Line');
        InsertIteration(3,'Create Transfer Order');
        InsertIteration(3,'Release Transfer Order');
        InsertIteration(3,'Post Transfer Order as shipped');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Post Transfer Order as received');
        InsertIteration(6,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-12"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Create Lines using selected Document');
        InsertIteration(2,'Release Purchase Order');
        InsertIteration(2,'Create Warehouse Activity Lines');
        InsertIteration(2,'Autofill Qty. to Handle');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Post Warehouse Activity Lines');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(4,'Autofill Qty. to Handle');
        InsertIteration(4,'Post Warehouse Activity Lines');
        InsertIteration(5,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-13"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Purchase Return Order');
        InsertIteration(2,'Create Lines using selected Document');
        InsertIteration(3,'Reserve Items from Current Line');
        InsertIteration(4,'Release Purchase Return Order');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Create Warehouse Activity Lines');
        InsertIteration(6,'Autofill Qty. to Handle');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Post Warehouse Activity Lines');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Modify Purchase Return Order');
        InsertIteration(10,'Modify Lines from selected Document');
        InsertIteration(11,'Release Purchase Return Order');
        InsertIteration(12,'Verify Post Conditions');
        InsertIteration(13,'Create Warehouse Activity Lines');
        InsertIteration(13,'Autofill Qty. to Handle');
        InsertIteration(14,'Verify Post Conditions');
        InsertIteration(15,'Post Warehouse Activity Lines');
        InsertIteration(16,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-15"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup General Posting Setup');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Insert Tracking Information Lot No.');
        InsertIteration(1,'Insert Item Tracking Lines Serial No.');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Create Lines using selected Document');
        InsertIteration(2,'Insert Sales Order Tracking Information Lot No.');
        InsertIteration(2,'Insert Sales Order Tracking Information Serial No.');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(4,'Autofill Qty. to Handle');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Warehouse Activity Lines');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-16"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Insert Item Journal Line');
        InsertIteration(1,'Post Item Journal Line');
        InsertIteration(2,'Create Sales Return Order');
        InsertIteration(2,'Create Lines using selected Document');
        InsertIteration(2,'Release Sales Return Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Activity Lines');
        InsertIteration(4,'Autofill Qty. to Handle');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Post Warehouse Activity Lines');
        InsertIteration(6,'Post Sales Return Order');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations3-17"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Location / Bin / Bin Content');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Create Lines using selected Document');
        InsertIteration(2,'Release Sales Order');
        InsertIteration(2,'Create Warehouse Shipment Header');
        InsertIteration(2,'Create Warehouse Shipment from Sales Order');
        InsertIteration(3,'Create Production Order D_PROD');
        InsertIteration(3,'Refresh Production Order D_PROD');
        InsertIteration(4,'Create Production Order E_PROD');
        InsertIteration(4,'Refresh Production Order E_PROD');
        InsertIteration(5,'Create Purchase Order');
        InsertIteration(5,'Release Purchase Order');
        InsertIteration(5,'Insert Warehouse Receipt Header');
        InsertIteration(5,'Create Warehouse Receipt');
        InsertIteration(6,'Modify Warehouse Receipt Lines');
        InsertIteration(7,'Assign Item Tracking Lines');
        InsertIteration(8,'Register Put-away');
        InsertIteration(8,'Post Purchase Order as received');
        InsertIteration(9,'Create Transfer Order');
        InsertIteration(9,'Release Transfer Order');
        InsertIteration(9,'Post Transfer Order');
        InsertIteration(9,'Create Warehouse Receipt from Transfer');
        InsertIteration(9,'Post Warehouse Receipt');
        InsertIteration(9,'Register Put-away');
        InsertIteration(10,'Insert Line in Production Order Component');
        InsertIteration(10,'Create Pick from Production Order D_PROD');
        InsertIteration(10,'Autofill Qty. to Handle');
        InsertIteration(10,'Register Pick');
        InsertIteration(11,'Create Consumption for Production Order D_PROD');
        InsertIteration(11,'Post Consumption for Production Order D_PROD');
        InsertIteration(12,'Create Output Journal and Explode Routing D_PROD');
        InsertIteration(12,'Post Output Journal for Production Order D_PROD');
        InsertIteration(13,'Create Pick from Production Order E_PROD');
        InsertIteration(13,'Split Line for Item L_TEST');
        InsertIteration(13,'Register Pick');
        InsertIteration(14,'Create Consumption for Production Order E_PROD');
        InsertIteration(14,'Post Consumption for Production Order E_PROD');
        InsertIteration(15,'Create Output Journal and Explode Routing E_PROD');
        InsertIteration(15,'Post Output Journal for Production Order E_PROD');
        InsertIteration(16,'Create Pick from Warehouse Shipment');
        InsertIteration(16,'Assign Item Tracking Lines');
        InsertIteration(17,'Register Pick');
        InsertIteration(17,'Post Warehouse Shipment');
    end;

    local procedure "CreateIterations5-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(1,'Setup Items');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(3,'Insert Reservation Entry');
        InsertIteration(3,'Post Item Journal Lines');
        InsertIteration(4,'Verify Post Conditions');
        InsertIteration(5,'Calculate Inventory');
        InsertIteration(6,'Edit Phys. Inventory Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations5-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Location');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Calculate Inventory: Items not on Inventory');
        InsertIteration(4,'Choose Location Filter');
        InsertIteration(5,'Verify Item Journal Lines');
    end;

    local procedure "CreateIterations5-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Items');
        InsertIteration(1,'Setup SKUs');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(3,'Item-driven physical counting');
        InsertIteration(4,'Verify Item Journal Lines');
    end;

    local procedure "CreateIterations6-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(3,'Insert Reservation Entry');
        InsertIteration(3,'Post Item Journal Lines');
        InsertIteration(4,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Insert Item Journal Lines');
        InsertIteration(1,'Insert Reservation Entry');
        InsertIteration(2,'Insert Item Journal Lines Neg. Adjmt.');
        InsertIteration(2,'Insert Reservation Entry');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
    end;

    local procedure "CreateIterations6-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal Lines');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Sales Header');
        InsertIteration(4,'Create Sales - Lines using Selected Document');
        InsertIteration(5,'Insert Reservation Entry');
        InsertIteration(6,'Insert Item Journal Lines');
        InsertIteration(6,'Post Item Journal Lines');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(2,'Create Purchase Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(3,'Post Purchase Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Undo Posted Purchase Line A_TEST');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo Posted Purchase Line T_TEST');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(2,'Create Purchase Return Order');
        InsertIteration(2,'Create Purchase - Lines using Selected Document');
        InsertIteration(2,'Post Purchase Return Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Undo Posted Shipment Line 20000');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo Posted Purchase Line 10000');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Create Item Tracking Lines');
        InsertIteration(1,'Post Item Journal Lines');
        InsertIteration(1,'Create Warehouse Item Journal Line');
        InsertIteration(1,'Register Warehouse Item Journal Lines');
        InsertIteration(2,'Create Sales Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines');
        InsertIteration(2,'Post Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Warehouse Shipment');
        InsertIteration(4,'Get Sourcedocument for Warehouse Shipment');
        InsertIteration(4,'Create Warehouse Pick');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Register Warehouse Pick');
        InsertIteration(6,'Post Warehouse Shipment');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Undo Posted Sales Line A_TEST');
        InsertIteration(9,'Verify Post Conditions');
        InsertIteration(10,'Undo Posted Sales Line L_TEST');
        InsertIteration(11,'Verify Post Conditions');
    end;

    local procedure "CreateIterations7-4"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Create Item Journal Line');
        InsertIteration(1,'Create Item Tracking Lines');
        InsertIteration(1,'Post Item Journal');
        InsertIteration(2,'Create Sales Return Order');
        InsertIteration(2,'Create Sales - Lines using Selected Document');
        InsertIteration(2,'Create Item Tracking Lines for Line 10000');
        InsertIteration(2,'Create Item Tracking Lines for Line 20000');
        InsertIteration(2,'Post Sales Order');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Undo Posted Receipt Line 10000');
        InsertIteration(5,'Verify Post Conditions');
        InsertIteration(6,'Undo Posted Receipt Line 20000');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Sales Order');
        InsertIteration(4,'Create Prod. Order');
        InsertIteration(5,'Release Prod. Order');
        InsertIteration(5,'Modify Prod. Order Qty.');
        InsertIteration(5,'Insert Item Tracking Lines');
        InsertIteration(5,'Reserve Prod. Order Component');
        InsertIteration(6,'Calc. Consumption in Cons. Journal');
        InsertIteration(6,'Post Consumption Journal');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Prod. Order');
        InsertIteration(4,'Modify Prod. Order Lines');
        InsertIteration(4,'Insert Item Tracking Lines');
        InsertIteration(4,'Release Prod. Order');
        InsertIteration(5,'Calc. Consumption in Cons. Journal');
        InsertIteration(5,'Post Consumption Journal');
        InsertIteration(6,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-3"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Sales Order');
        InsertIteration(4,'Create Prod. Order');
        InsertIteration(5,'Release Prod. Order');
        InsertIteration(5,'Insert Item Tracking Lines');
        InsertIteration(6,'Calc. Consumption in Cons. Journal');
        InsertIteration(6,'Post Consumption Journal');
        InsertIteration(6,'Modify Cons. Journal Lines');
        InsertIteration(6,'Post Consumption Journal');
        InsertIteration(7,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-7"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines Serial No.');
        InsertIteration(2,'Insert Item Tracking Lines Lot No.');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create realeased Prod. Order');
        InsertIteration(4,'Insert Item Tracking Lines Serial No.');
        InsertIteration(4,'Insert Item Tracking Lines Lot No.');
        InsertIteration(4,'Reserve Prod. Order Component');
        InsertIteration(4,'Add additional Items to Prod. Order Component');
        InsertIteration(5,'Create Pick/Put-away');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Post Pick');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Post Put-away');
    end;

    local procedure "CreateIterations8-8"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines Serial No.');
        InsertIteration(2,'Insert Item Tracking Lines Lot No.');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create released Prod. Order');
        InsertIteration(4,'Modify Prod. Order Lines');
        InsertIteration(4,'Insert Item Tracking Lines Serial No.');
        InsertIteration(4,'Insert Item Tracking Lines Lot No.');
        InsertIteration(5,'Create Pick / Put-away');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Post Pick / Put-away');
        InsertIteration(8,'Verify Post Conditions');
    end;

    local procedure "CreateIterations8-9"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines Serial No.');
        InsertIteration(2,'Insert Item Tracking Lines Lot No.');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create released Prod. Order');
        InsertIteration(4,'Insert Item Tracking Lines Serial No.');
        InsertIteration(4,'Insert Item Tracking Lines Lot No.');
        InsertIteration(4,'Reserve Prod. Order Component');
        InsertIteration(5,'Create Pick');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Post Pick');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Create Prod. Order Line');
        InsertIteration(9,'Create Pick');
        InsertIteration(9,'Autofill Qty. to Handle');
        InsertIteration(9,'Post Pick');
        InsertIteration(10,'Verify Post Conditions');
    end;

    local procedure "CreateIterations9-1"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Sales Order');
        InsertIteration(4,'Create Prod. Order');
        InsertIteration(5,'Release Prod. Order');
        InsertIteration(5,'Modify Prod. Order Qty.');
        InsertIteration(5,'Insert Item Tracking Lines');
        InsertIteration(5,'Reserve Prod. Order Component');
        InsertIteration(6,'Calc. Consumption in Cons. Journal');
        InsertIteration(6,'Post Consumption Journal');
        InsertIteration(7,'Verify Post Conditions');
        InsertIteration(8,'Insert Output Journal Lines');
        InsertIteration(8,'Post Output Journal');
        InsertIteration(9,'Verify Post Conditions');
    end;

    local procedure "CreateIterations9-2"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create Prod. Order');
        InsertIteration(4,'Modify Prod. Order Lines');
        InsertIteration(5,'Calc. Consumption in Cons. Journal');
        InsertIteration(5,'Post Consumption Journal');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Insert Output Journal Lines');
        InsertIteration(7,'Post Output Journal');
        InsertIteration(8,'Verify Post Conditions');
    end;

    local procedure "CreateIterations9-5"()
    begin
        InsertIteration(1,'Setup Global Preconditions');
        InsertIteration(1,'Setup Locations');
        InsertIteration(2,'Insert Item Journal Lines');
        InsertIteration(2,'Insert Item Tracking Lines Serial No.');
        InsertIteration(2,'Insert Item Tracking Lines Lot No.');
        InsertIteration(2,'Post Item Journal');
        InsertIteration(3,'Verify Post Conditions');
        InsertIteration(4,'Create released Prod. Order');
        InsertIteration(4,'Insert Item Tracking Lines Serial No.');
        InsertIteration(4,'Insert Item Tracking Lines Lot No.');
        InsertIteration(4,'Reserve Prod. Order Component');
        InsertIteration(5,'Create Pick');
        InsertIteration(5,'Autofill Qty. to Handle');
        InsertIteration(6,'Verify Post Conditions');
        InsertIteration(7,'Post Pick');
        InsertIteration(8,'Verify Post Conditions');
        InsertIteration(9,'Create Put-Away');
        InsertIteration(9,'Autofill Qty. to Handle');
        InsertIteration(10,'Post Put-Away');
        InsertIteration(11,'Verify Post Conditions');
    end;

    [Scope('OnPrem')]
    procedure CreateUndefinedIteration()
    begin
        InsertIteration(1, GetUndefinedText());
    end;

    local procedure InsertIteration(IterationNo: Integer;Description: Text[50])
    begin
        TestIteration."Project Code" := TestCase."Project Code";
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

