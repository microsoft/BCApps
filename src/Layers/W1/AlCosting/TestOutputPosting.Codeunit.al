codeunit 103520 "Test - Output Posting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103520);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        PostStopTime();
        PostCapOnly_Time();
        PostCapOnly_Unit();
        PostCapOnlyNoValue();
        PostOutputOnly();
        PostScrapOnly();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        TestscriptMgt: Codeunit TestscriptManagement;
        MFGUtil: Codeunit MFGUtil;
        CRPUtil: Codeunit CRPUtil;
        INVTUtil: Codeunit INVTUtil;
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        MachCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        RtngHeader: Record "Routing Header";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkCenter.Init();
        WorkCenter.Validate("No.", '100');
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Unit of Measure Code", 'MINUTES');
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate("Gen. Prod. Posting Group", 'MANUFACT');
        WorkCenter.Validate("Direct Unit Cost", 1.2);
        WorkCenter.Modify(true);

        MachCenter.Init();
        MachCenter.Validate("No.", '120');
        MachCenter.Insert(true);
        MachCenter.Validate("Work Center No.", WorkCenter."No.");
        MachCenter.Validate("Gen. Prod. Posting Group", WorkCenter."Gen. Prod. Posting Group");
        MachCenter.Validate("Direct Unit Cost", 2.72727);
        MachCenter.Validate("Indirect Cost %", 10);
        MachCenter.TestField("Unit Cost", 3);
        MachCenter.Modify(true);

        MachCenter.Init();
        MachCenter.Validate("No.", '130');
        MachCenter.Insert(true);
        MachCenter.Validate("Work Center No.", WorkCenter."No.");
        MachCenter.Validate("Gen. Prod. Posting Group", WorkCenter."Gen. Prod. Posting Group");
        MachCenter.Modify(true);

        MachCenter.Init();
        MachCenter.Validate("No.", '110');
        MachCenter.Insert(true);
        MachCenter.Validate("Work Center No.", WorkCenter."No.");
        MachCenter.Validate("Gen. Prod. Posting Group", WorkCenter."Gen. Prod. Posting Group");
        MachCenter.Modify(true);
        CreateRoutings();

        INVTUtil.CreateBasisItem('1000', true, Item, Item."Costing Method"::FIFO, 0);

        RtngHeader.Get('1000');
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);
    end;

    [Scope('OnPrem')]
    procedure PostStopTime()
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Document No.", 'Stop time only');
        ItemJnlLine.Validate(Type, ItemJnlLine.Type::"Work Center");
        ItemJnlLine.Validate("No.", '100');
        ItemJnlLine.Validate("Stop Time", 25);
        ItemJnlLine.Description := 'Stop time only';
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(25, 0, 0, 25, 0, 0, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure PostCapOnly_Time()
    begin
        CreateProdOrder('Capacity only (time)');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", ProdOrder."Source No.");
        ItemJnlLine.Validate("Operation No.", '20');
        ItemJnlLine.Validate("Setup Time", 5);
        ItemJnlLine.Validate("Run Time", 29);
        ItemJnlLine.Description := ProdOrder.Description;
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(34, 5, 29, 0, 0, 0, 92.73, 9.27);
    end;

    [Scope('OnPrem')]
    procedure PostCapOnly_Unit()
    begin
        CreateProdOrder('Capacity only (unit)');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", ProdOrder."Source No.");
        ItemJnlLine.Validate("Operation No.", '10');
        ItemJnlLine.Validate("Output Quantity", 4);
        ItemJnlLine.Validate("Scrap Quantity", 3);
        ItemJnlLine.Description := ProdOrder.Description;
        ItemJnlLine.Insert();
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(7, 0, 0, 0, 4, 3, 8.4, 0);
    end;

    [Scope('OnPrem')]
    procedure PostCapOnlyNoValue()
    begin
        CreateProdOrder('Capacity - no cost value');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", ProdOrder."Source No.");
        ItemJnlLine.Validate("Operation No.", '30');
        ItemJnlLine.Validate("Setup Time", 7);
        ItemJnlLine.Description := ProdOrder.Description;
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(7, 7, 0, 0, 0, 0, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure PostOutputOnly()
    begin
        CreateProdOrder('Output only');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", ProdOrder."Source No.");
        ItemJnlLine.Validate("Operation No.", '40');
        ItemJnlLine.Validate("Output Quantity", 27);
        ItemJnlLine.Description := ProdOrder.Description;
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(0, 0, 0, 0, 27, 0, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure PostScrapOnly()
    begin
        CreateProdOrder('Scrap only');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", ProdOrder."Source No.");
        ItemJnlLine.Validate("Operation No.", '40');
        ItemJnlLine.Validate("Scrap Quantity", 17);
        ItemJnlLine.Description := ProdOrder.Description;
        ItemJnlPostLine.Run(ItemJnlLine);

        ValidateCapLedgEntry(0, 0, 0, 0, 0, 17, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure CreateProdOrder(Description: Text[30])
    begin
        MFGUtil.CreateRelProdOrder(ProdOrder, '', '1000', 5);
        ProdOrder.Description := Description;
        ProdOrder.Modify();
    end;

    local procedure CreateRoutings()
    var
        RtngHeader: Record "Routing Header";
    begin
        CRPUtil.InsertRtngHeader('1000', RtngHeader);
        InsertRntgLine(RtngHeader."No.", '', '10', '100', '');
        InsertRntgLine(RtngHeader."No.", '', '20', '', '120');
        InsertRntgLine(RtngHeader."No.", '', '30', '', '130');
        InsertRntgLine(RtngHeader."No.", '', '40', '', '110');
    end;

    local procedure InsertRntgLine(RtngNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; WorkCenterNo: Code[20]; MachineCenterNo: Code[20])
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.InsertRntgLine(RtngNo, VersionCode, OperationNo, RtngLine);
        if WorkCenterNo <> '' then begin
            RtngLine.Validate(Type, RtngLine.Type::"Work Center");
            RtngLine.Validate("No.", WorkCenterNo);
        end else begin
            RtngLine.Validate(Type, RtngLine.Type::"Machine Center");
            RtngLine.Validate("No.", MachineCenterNo);
        end;
        RtngLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateCapLedgEntry(Qty: Decimal; SetupTime: Decimal; RunTime: Decimal; StopTime: Decimal; OutputQty: Decimal; ScrapQty: Decimal; DirCost: Decimal; OvhdCost: Decimal)
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.FindLast();
        CapLedgEntry.CalcFields("Direct Cost", "Overhead Cost");
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName(Quantity)),
          CapLedgEntry.Quantity, Qty);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Setup Time")),
          CapLedgEntry."Setup Time", SetupTime);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Run Time")),
          CapLedgEntry."Run Time", RunTime);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Stop Time")),
          CapLedgEntry."Stop Time", StopTime);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Output Quantity")),
          CapLedgEntry."Output Quantity", OutputQty);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Scrap Quantity")),
          CapLedgEntry."Scrap Quantity", ScrapQty);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Direct Cost")),
          CapLedgEntry."Direct Cost", DirCost);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Overhead Cost")),
          CapLedgEntry."Overhead Cost", OvhdCost);
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2', CapLedgEntry.Description, CapLedgEntry.FieldName("Completely Invoiced")),
          CapLedgEntry."Completely Invoiced", true);
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
}

