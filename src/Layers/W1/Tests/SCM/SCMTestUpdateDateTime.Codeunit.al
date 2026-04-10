codeunit 137225 "SCM Test UpdateDateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Production Order] [Date-Time] [SCM] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5405()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        SetNullNull(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        SetNullNull(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.UpdateDatetime();
        ProductionOrder.TestField("Starting Date-Time", 0DT);
        ProductionOrder.TestField("Ending Date-Time", 0DT);

        SetDateNull(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        SetDateNull(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.UpdateDatetime();
        ProductionOrder.TestField("Starting Date-Time", 0DT);
        ProductionOrder.TestField("Ending Date-Time", 0DT);

        SetNullTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        SetNullTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.UpdateDatetime();
        ProductionOrder.TestField("Starting Date-Time", 0DT);
        ProductionOrder.TestField("Ending Date-Time", 0DT);

        SetDateTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        SetDateTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.UpdateDatetime();
        ProductionOrder.TestField("Starting Date-Time");
        ProductionOrder.TestField("Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5406()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        Initialize();
        SetNullNull(ProdOrderLine."Starting Date", ProdOrderLine."Starting Time");
        SetNullNull(ProdOrderLine."Ending Date", ProdOrderLine."Ending Time");
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.TestField("Starting Date-Time", 0DT);
        ProdOrderLine.TestField("Ending Date-Time", 0DT);

        SetNullTime(ProdOrderLine."Starting Date", ProdOrderLine."Starting Time");
        SetNullTime(ProdOrderLine."Ending Date", ProdOrderLine."Ending Time");
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.TestField("Starting Date-Time", 0DT);
        ProdOrderLine.TestField("Ending Date-Time", 0DT);

        SetDateTime(ProdOrderLine."Starting Date", ProdOrderLine."Starting Time");
        SetDateTime(ProdOrderLine."Ending Date", ProdOrderLine."Ending Time");
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.TestField("Starting Date-Time");
        ProdOrderLine.TestField("Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5407()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        SetNullNull(ProdOrderComponent."Due Date", ProdOrderComponent."Due Time");
        ProdOrderComponent.UpdateDatetime();
        ProdOrderComponent.TestField("Due Date-Time", 0DT);

        SetDateNull(ProdOrderComponent."Due Date", ProdOrderComponent."Due Time");
        ProdOrderComponent.UpdateDatetime();
        ProdOrderComponent.TestField("Due Date-Time", 0DT);

        SetNullTime(ProdOrderComponent."Due Date", ProdOrderComponent."Due Time");
        ProdOrderComponent.UpdateDatetime();
        ProdOrderComponent.TestField("Due Date-Time", 0DT);

        SetDateTime(ProdOrderComponent."Due Date", ProdOrderComponent."Due Time");
        ProdOrderComponent.UpdateDatetime();
        ProdOrderComponent.TestField("Due Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5409()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        Initialize();
        SetNullNull(ProdOrderRoutingLine."Starting Date", ProdOrderRoutingLine."Starting Time");
        SetNullNull(ProdOrderRoutingLine."Ending Date", ProdOrderRoutingLine."Ending Time");
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.TestField("Starting Date-Time", 0DT);
        ProdOrderRoutingLine.TestField("Ending Date-Time", 0DT);

        SetDateNull(ProdOrderRoutingLine."Starting Date", ProdOrderRoutingLine."Starting Time");
        SetDateNull(ProdOrderRoutingLine."Ending Date", ProdOrderRoutingLine."Ending Time");
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.TestField("Starting Date-Time", 0DT);
        ProdOrderRoutingLine.TestField("Ending Date-Time", 0DT);

        SetNullTime(ProdOrderRoutingLine."Starting Date", ProdOrderRoutingLine."Starting Time");
        SetNullTime(ProdOrderRoutingLine."Ending Date", ProdOrderRoutingLine."Ending Time");
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.TestField("Starting Date-Time", 0DT);
        ProdOrderRoutingLine.TestField("Ending Date-Time", 0DT);

        SetDateTime(ProdOrderRoutingLine."Starting Date", ProdOrderRoutingLine."Starting Time");
        SetDateTime(ProdOrderRoutingLine."Ending Date", ProdOrderRoutingLine."Ending Time");
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.TestField("Starting Date-Time");
        ProdOrderRoutingLine.TestField("Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5410()
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        Initialize();
        SetNullNull(ProdOrderCapNeed.Date, ProdOrderCapNeed."Starting Time");
        SetNullNull(ProdOrderCapNeed.Date, ProdOrderCapNeed."Ending Time");
        ProdOrderCapNeed.UpdateDatetime();
        ProdOrderCapNeed.TestField("Starting Date-Time", 0DT);
        ProdOrderCapNeed.TestField("Ending Date-Time", 0DT);

        SetDateNull(ProdOrderCapNeed.Date, ProdOrderCapNeed."Starting Time");
        SetDateNull(ProdOrderCapNeed.Date, ProdOrderCapNeed."Ending Time");
        ProdOrderCapNeed.UpdateDatetime();
        ProdOrderCapNeed.TestField("Starting Date-Time", 0DT);
        ProdOrderCapNeed.TestField("Ending Date-Time", 0DT);

        SetNullTime(ProdOrderCapNeed.Date, ProdOrderCapNeed."Starting Time");
        SetNullTime(ProdOrderCapNeed.Date, ProdOrderCapNeed."Ending Time");
        ProdOrderCapNeed.UpdateDatetime();
        ProdOrderCapNeed.TestField("Starting Date-Time", 0DT);
        ProdOrderCapNeed.TestField("Ending Date-Time", 0DT);

        SetDateTime(ProdOrderCapNeed.Date, ProdOrderCapNeed."Starting Time");
        SetDateTime(ProdOrderCapNeed.Date, ProdOrderCapNeed."Ending Time");
        ProdOrderCapNeed.UpdateDatetime();
        ProdOrderCapNeed.TestField("Starting Date-Time");
        ProdOrderCapNeed.TestField("Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueTimeIsUpdatedWithDueDateOnProdOrderComp()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 230435] "Due Time" and "Due Date-Time" are updated on Prod. Order Component from related Prod. Order Line when "Due Date" is updated.
        Initialize();

        // [GIVEN] Prod. Order Line with "Due Date" = "D" and "Due Time" = "T".
        MockProdOrderLine(ProdOrderLine);
        // [GIVEN] Prod. order component.
        ProdOrderComponent."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderComponent."Qty. per Unit of Measure" := 1;
        ProdOrderComponent.Insert();
        // [WHEN] Validate "Calculation Formula" on the component to trigger copying due date and time from production order line.
        ProdOrderComponent.Validate("Calculation Formula");
        // [THEN] "Due Date" on the component = "D", "Due Time" = "T", "Due Date-Time" = "D" "T".
        ProdOrderComponent.TestField("Due Date", ProdOrderLine."Starting Date");
        ProdOrderComponent.TestField("Due Time", ProdOrderLine."Starting Time");
        ProdOrderComponent.TestField("Due Date-Time", CreateDateTime(ProdOrderComponent."Due Date", ProdOrderComponent."Due Time"));
    end;

    local procedure SetNullNull(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := 0D;
        TimeVar := 0T;
    end;

    local procedure SetDateNull(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := DMY2Date(1, 1, 2001);
        TimeVar := 0T;
    end;

    local procedure SetNullTime(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := 0D;
        TimeVar := 111100T;
    end;

    local procedure SetDateTime(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := DMY2Date(1, 1, 2001);
        TimeVar := 111100T;
    end;

    local procedure MockProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.Init();
        ProdOrderLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderLine."Starting Date" := WorkDate();
        ProdOrderLine."Starting Time" := 120000T;
        ProdOrderLine.Insert();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Test UpdateDateTime");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Test UpdateDateTime");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Test UpdateDateTime");
    end;
}

