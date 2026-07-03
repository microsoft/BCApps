codeunit 103511 "Test - Partial Posting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103511);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();

        TestOnlyPosLine('A2');
        TestOnlyPosLine('A3');
        TestOnlyPosLine('B9');
        TestOnlyPosLine('B11');
        TestOnlyPosLine('C1');
        TestOnlyPosLine('C2');
        TestOnlyPosLine('C3');
        TestOnlyPosLine('C4');
        TestOnlyPosLine('C5');

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        SRUtil: Codeunit SRUtil;
        LastGLEntryNo: Integer;
        LastItemLedgEntryNo: Integer;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkDate := 20010201D;

        GLUtil.SetAddCurr('', 1, 1, 1, 1);

        SalesSetup.ModifyAll("Return Receipt on Credit Memo", true, true);
        SalesSetup.ModifyAll("Exact Cost Reversing Mandatory", false, true);
        SalesSetup.ModifyAll("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning", true);

        PurchSetup.ModifyAll("Ext. Doc. No. Mandatory", false, true);

        INVTUtil.CreateBasisItem('A', false, Item, Item."Costing Method"::Average, 0);
        Item.Validate("Unit Price", 3.33333);
        Item.Modify(true);
        SetLastEntryNo();
    end;

    [Scope('OnPrem')]
    procedure TestOnlyPosLine(TestCase: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        TestscriptMgt.TestBooleanValue(StrSubstNo('Test Case: %1', TestCase), true, true);

        case TestCase of
            'A2':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 1);
                    PostOneLineSalesOrder(SalesHeader, 1, 1);

                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                end;
            'A3':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 1);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 0, 1);

                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                end;
            'B9':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 2);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 2);

                    ValidateItemLedgEntry('A', -1, -1, 3.34, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -6.67);
                    ValidateGLEntry('5610', -1.67);
                    ValidateGLEntry('2310', 8.34);
                end;
            'B11':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 2);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 0, 2);

                    ValidateItemLedgEntry('A', -1, -1, 3.34, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -6.67);
                    ValidateGLEntry('5610', -1.67);
                    ValidateGLEntry('2310', 8.34);
                end;
            'C1':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 6);
                    PostOneLineSalesOrder(SalesHeader, 2, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 3, 0);
                    PostOneLineSalesOrder(SalesHeader, 0, 1);
                    PostOneLineSalesOrder(SalesHeader, 0, 3);
                    PostOneLineSalesOrder(SalesHeader, 0, 2);

                    ValidateItemLedgEntry('A', -2, -2, 6.66, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.34, 0, 0, 0);
                    ValidateItemLedgEntry('A', -3, -3, 10, 0, 0, 0);

                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                    ValidateGLEntry('6210', -10);
                    ValidateGLEntry('5610', -2.5);
                    ValidateGLEntry('2310', 12.5);
                    ValidateGLEntry('6210', -6.67);
                    ValidateGLEntry('5610', -1.67);
                    ValidateGLEntry('2310', 8.34);
                end;
            'C2':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 6);
                    PostOneLineSalesOrder(SalesHeader, 2, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 1);
                    PostOneLineSalesOrder(SalesHeader, 2, 4);
                    PostOneLineSalesOrder(SalesHeader, 1, 1);

                    ValidateItemLedgEntry('A', -2, -2, 6.67, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);
                    ValidateItemLedgEntry('A', -2, -2, 6.66, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                    ValidateGLEntry('6210', -13.33);
                    ValidateGLEntry('5610', -3.33);
                    ValidateGLEntry('2310', 16.66);
                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                end;
            'C3':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 6);
                    PostOneLineSalesOrder(SalesHeader, 2, 0);
                    PostOneLineSalesOrder(SalesHeader, 4, 0);
                    PostOneLineSalesOrder(SalesHeader, 0, 6);

                    ValidateItemLedgEntry('A', -2, -2, 6.67, 0, 0, 0);
                    ValidateItemLedgEntry('A', -4, -4, 13.33, 0, 0, 0);

                    ValidateGLEntry('6210', -20);
                    ValidateGLEntry('5610', -5);
                    ValidateGLEntry('2310', 25);
                end;
            'C4':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 6);
                    PostOneLineSalesOrder(SalesHeader, 6, 0);
                    PostOneLineSalesOrder(SalesHeader, 0, 2);
                    PostOneLineSalesOrder(SalesHeader, 0, 4);

                    ValidateItemLedgEntry('A', -6, -6, 20, 0, 0, 0);

                    ValidateGLEntry('6210', -6.67);
                    ValidateGLEntry('5610', -1.67);
                    ValidateGLEntry('2310', 8.34);
                    ValidateGLEntry('6210', -13.33);
                    ValidateGLEntry('5610', -3.33);
                    ValidateGLEntry('2310', 16.66);
                end;
            'C5':
                begin
                    CreateOneLineSalesOrder(SalesHeader, 6);
                    PostOneLineSalesOrder(SalesHeader, 2, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 3);
                    PostOneLineSalesOrder(SalesHeader, 1, 0);
                    PostOneLineSalesOrder(SalesHeader, 1, 1);
                    PostOneLineSalesOrder(SalesHeader, 1, 2);

                    ValidateItemLedgEntry('A', -2, -2, 6.67, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.34, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);
                    ValidateItemLedgEntry('A', -1, -1, 3.33, 0, 0, 0);

                    ValidateGLEntry('6210', -10);
                    ValidateGLEntry('5610', -2.5);
                    ValidateGLEntry('2310', 12.5);
                    ValidateGLEntry('6210', -3.33);
                    ValidateGLEntry('5610', -0.83);
                    ValidateGLEntry('2310', 4.16);
                    ValidateGLEntry('6210', -6.67);
                    ValidateGLEntry('5610', -1.67);
                    ValidateGLEntry('2310', 8.34);
                end;
            else
                Error('%1 test case is not defined', TestCase);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateOneLineSalesOrder(var SalesHeader: Record "Sales Header"; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", 'A');
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostOneLineSalesOrder(var SalesHeader: Record "Sales Header"; QtyToShip: Decimal; QtyToInv: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInv);
        SalesLine.Modify(true);
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Receive := false;
        SalesPost.Run(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure SetLastEntryNo()
    var
        GLEntry: Record "G/L Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if GLEntry.FindLast() then;
        LastGLEntryNo := GLEntry."Entry No.";

        if InventorySetup.UseLegacyPosting() then begin
            if ItemLedgEntry.FindLast() then;
            LastItemLedgEntryNo := ItemLedgEntry."Entry No.";
        end else begin
            SequenceNoMgt.ClearState();
            LastItemLedgEntryNo := ItemLedgEntry.GetNextEntryNo(); // makes sure the nosequence is created. We 'loose' one number here.
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateGLEntry(AccNo: Code[20]; Amt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        LastGLEntryNo := LastGLEntryNo + 1;

        GLEntry.Get(LastGLEntryNo);
        TestscriptMgt.TestTextValue(GLEntry.FieldName("G/L Account No."), GLEntry."G/L Account No.", AccNo);
        TestscriptMgt.TestNumberValue(GLEntry.FieldName(Amount), GLEntry.Amount, Amt);
    end;

    [Scope('OnPrem')]
    procedure ValidateItemLedgEntry(ItemNo: Code[20]; Qty: Decimal; InvdQty: Decimal; SalesAmtAct: Decimal; CostAmtAct: Decimal; SalesAmtExp: Decimal; CostAmtExp: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        LastItemLedgEntryNo := LastItemLedgEntryNo + 1;

        ItemLedgEntry.Get(LastItemLedgEntryNo);
        ItemLedgEntry.CalcFields("Sales Amount (Actual)");
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgEntry.CalcFields("Sales Amount (Expected)");
        ItemLedgEntry.CalcFields("Cost Amount (Expected)");
        TestscriptMgt.TestTextValue(ItemLedgEntry.FieldName("Item No."), ItemLedgEntry."Item No.", ItemNo);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName(Quantity), ItemLedgEntry.Quantity, Qty);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Invoiced Quantity"), ItemLedgEntry."Invoiced Quantity", InvdQty);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Sales Amount (Actual)"), ItemLedgEntry."Sales Amount (Actual)", SalesAmtAct);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Cost Amount (Actual)"), ItemLedgEntry."Cost Amount (Actual)", CostAmtAct);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Sales Amount (Expected)"), ItemLedgEntry."Sales Amount (Expected)", SalesAmtExp);
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Cost Amount (Expected)"), ItemLedgEntry."Cost Amount (Expected)", CostAmtExp);
    end;
}

