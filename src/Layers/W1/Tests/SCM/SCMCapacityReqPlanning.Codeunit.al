codeunit 137042 "SCM Capacity Req. Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        isInitialized := false;
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ErrAllocatedTimeMustBeSame: Label 'Allocated Time Must Be Same';
        ErrTimeMustBeSame: Label '%1 must be %2 in %3.';
        ErrEfficiencyZero: Label 'Efficiency must';
        ErrorGeneratedMustBeSame: Label 'Error Generated Must Be Same';

    [Test]
    [Scope('OnPrem')]
    procedure CapacityNeedAllocTime()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionOrder: Record "Production Order";
        AllocatedTime: Decimal;
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM,Routing and update Item.
        // Create Planned Production Order. Update and Refresh it
        Initialize();
        CapReqPlanningSetup(TempSalesReceivablesSetup, TempManufacturingSetup, ProductionOrder);
        AllocatedTime := CalculateAllocatedTime(ProductionOrder);

        // Verify : Verify Allocated Time of Prouction Order Capacity Need Table with Production Order Routing Line.
        VerifyCapNeedAllocatedTime(ProductionOrder, AllocatedTime);

        // 4. Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        // Set Manufacturing Setup as Default for Normal Start Time and Normal End Time.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQtyCapacityNeedAllocTime()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionOrder: Record "Production Order";
        AllocatedTime: Decimal;
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM,Routing and update Item.
        // Create Planned Production Order.Update and Refresh it.
        Initialize();
        CapReqPlanningSetup(TempSalesReceivablesSetup, TempManufacturingSetup, ProductionOrder);

        // Exercise: Change Production Order Quantity.
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrder."No.");
        UpdateProdOrder(ProductionOrder, LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        AllocatedTime := CalculateAllocatedTime(ProductionOrder);

        // Verify : Verify Allocated Time of Production Order Capacity Need Table with Production Order Routing Line.
        VerifyCapNeedAllocatedTime(ProductionOrder, AllocatedTime);

        // 4. Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        // Set Manufacturing Setup as Default for Normal Start Time and Normal End Time.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EfficiencyMachWorkCenterUpdate()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionOrder: Record "Production Order";
        MachineCenter: Record "Machine Center";
        AllocatedTime: Decimal;
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM,Routing and update Item.
        // Create Planned Production Order.Update and Refresh it.
        Initialize();
        SalesReceivablesSetup.Get();
        CapReqPlanningSetup(TempSalesReceivablesSetup, TempManufacturingSetup, ProductionOrder);

        // Exercise: Change Efficiency on Machine Center and Work Center,
        UpdateWorkCenterEfficiency(ProductionOrder, LibraryRandom.RandInt(100));
        UpdateMachCenterEfficiency(MachineCenter, ProductionOrder, LibraryRandom.RandInt(100));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        AllocatedTime := CalculateAllocatedTime(ProductionOrder);

        // Verify : Verify Allocated Time of Production Order Capacity Need Table with Production Order Routing Line.
        VerifyCapNeedAllocatedTime(ProductionOrder, AllocatedTime);

        // 4. Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        // Set Manufacturing Setup as Default for Normal Start Time and Normal End Time.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EfficiencyMachWorkCenterToDec()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MachineCenter: Record "Machine Center";
        AllocatedTime: Decimal;
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM,Routing and update Item.
        // Create Planned Production Order.Update and Refresh it.
        Initialize();
        SalesReceivablesSetup.Get();
        CapReqPlanningSetup(TempSalesReceivablesSetup, TempManufacturingSetup, ProductionOrder);

        // Exercise: Change Efficiency to decimal value on Machine Center and Work Center,
        UpdateWorkCenterEfficiency(ProductionOrder, LibraryRandom.RandDec(5, 2));
        UpdateMachCenterEfficiency(MachineCenter, ProductionOrder, LibraryRandom.RandDec(5, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        AllocatedTime := CalculateAllocatedTime(ProductionOrder);

        // Verify : Verify Allocated Time of Production Order Capacity Need Table with Production Order Routing Line.
        // Verify Run Time and Setup Time On Machine and Work Center.
        VerifyCapNeedAllocatedTime(ProductionOrder, AllocatedTime);
        VerifyRunSetupTime(ProductionOrder, ProdOrderRoutingLine.Type::"Work Center");
        VerifyRunSetupTime(ProductionOrder, ProdOrderRoutingLine.Type::"Machine Center");

        // 4. Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        // Set Manufacturing Setup as Default for Normal Start Time and Normal End Time.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EfficiencyMachCenterToZero()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionOrder: Record "Production Order";
        MachineCenter: Record "Machine Center";
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM,Routing and update Item.
        // Create Planned Production Order.Update and Refresh it.
        Initialize();
        SalesReceivablesSetup.Get();
        CapReqPlanningSetup(TempSalesReceivablesSetup, TempManufacturingSetup, ProductionOrder);

        // Exercise: Change Efficiency to Zero on Machine Center and Work Center,
        UpdateMachCenterEfficiency(MachineCenter, ProductionOrder, 0);
        asserterror LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // 3. Verify : Verify Error message generated on Validation Efficiency by Zero.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrEfficiencyZero) > 0, ErrorGeneratedMustBeSame);
        ClearLastError();

        // 4. Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        // Set Manufacturing Setup as Default for Normal Start Time and Normal End Time.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    local procedure CapReqPlanningSetup(var TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary; var TempManufacturingSetup: Record "Manufacturing Setup" temporary; var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        // Setup : Update Sales and Manufacturing Setup.Create Items, Production BOM with three Items,Routing and update Item.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        UpdateManufacturingSetup(TempManufacturingSetup);
        CreateProdOrderItemSetup(Item, Item."Flushing Method"::"Pick + Manual", 3);

        // Create Planned Production Order.Update and Refresh it.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(5));
        UpdateProdOrder(ProductionOrder, 0);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLine()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Setup : Update Sales Setup.Create Items, Production BOM with three Items,Routing and update Item.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateProdOrderItemSetup(Item, Item."Flushing Method"::Forward, 2);

        // Create Planned Production Order.Refresh it.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(5, 2));

        // Exercise : Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify : Created Production Order Line with Production Header.
        VerifyProdOrderLine(ProductionOrder);

        // Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningProdOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup : Update Sales Setup.Create Items, Production BOM with three Items,Routing and update Item.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateProdOrderItemSetup(Item, Item."Flushing Method"::Forward, 2);

        // Exercise:Create Sales Order and Create Firm Planned Production order using order Planning.
        CreateSalesOrder(SalesHeader, Item."No.");
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // Verify : Firm Planned Production Order created.
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindLast();

        // Tear down: Set Sales & Receivables Setup as default for Credit Warnings and Stockout Warning.
        RestoreSalesReceivablesSetup(TempSalesReceivablesSetup);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Capacity Req. Planning");

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Capacity Req. Planning");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Capacity Req. Planning");
    end;

    [Normal]
    local procedure UpdateSalesReceivablesSetup(var BaseSalesReceivablesSetup: Record "Sales & Receivables Setup")
    begin
        SalesReceivablesSetup.Get();
        BaseSalesReceivablesSetup := SalesReceivablesSetup;
        BaseSalesReceivablesSetup.Insert(true);

        // Values used are important for test.
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    [Normal]
    local procedure UpdateManufacturingSetup(var BaseManufacturingSetup: Record "Manufacturing Setup")
    begin
        ManufacturingSetup.Get();
        BaseManufacturingSetup := ManufacturingSetup;
        BaseManufacturingSetup.Insert(true);

        // Values used are important for test.
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 160000T);
        ManufacturingSetup.Modify(true);
    end;

    local procedure RestoreSalesReceivablesSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure RestoreManufacturingSetup(TempManufacturingSetup: Record "Manufacturing Setup" temporary)
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Normal Starting Time", TempManufacturingSetup."Normal Starting Time");
        ManufacturingSetup.Validate("Normal Ending Time", TempManufacturingSetup."Normal Ending Time");
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateProdOrderItemSetup(var Item: Record Item; FlushingMethod: Enum "Flushing Method"; NoBOMLine: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        // Create Item, Routing and Production BOM with two lines.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateRouting(RoutingHeader, FlushingMethod);
        CreateProdBOM(ProductionBOMHeader, Item."Replenishment System"::Purchase, Item."Base Unit of Measure", NoBOMLine);
        UpdateItem(Item, ProductionBOMHeader."No.", RoutingHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        // Random values used are important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(50, 2),
          Item."Reordering Policy", Item."Flushing Method"::"Pick + Manual", '', '');
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; ReplenishmentSystem: Enum "Replenishment System"; BaseUnitOfMeasure: Code[10]; NoBOMLine: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ItemNo: array[5] of Code[20];
        "Count": Integer;
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);

        for Count := 1 to NoBOMLine do begin
            CreateItem(Item, ReplenishmentSystem);
            ItemNo[Count] := Item."No.";
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo[Count], 1);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateSetupWorkCenter(WorkCenter, FlushingMethod);
        CreateSetupMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateSetupWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSetupMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, 105); // Value used is important for test.
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure UpdateItem(var Item: Record Item; ProductionBOMHeaderNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMHeaderNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateProdOrder(var ProductionOrder: Record "Production Order"; Quantity: Decimal)
    begin
        ProductionOrder.Validate("Starting Date", WorkDate());
        ProductionOrder.Validate("Ending Date", WorkDate());
        ProductionOrder.Validate("Due Date", WorkDate());
        ProductionOrder.Validate(Quantity, ProductionOrder.Quantity + Quantity);
        ProductionOrder.Modify(true);
    end;

    local procedure UpdateWorkCenterEfficiency(ProductionOrder: Record "Production Order"; Efficiency: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", ProdOrderRoutingLine.Type::"Work Center");
        WorkCenter.Get(ProdOrderRoutingLine."No.");
        WorkCenter.Validate(Efficiency, Efficiency + Efficiency);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateMachCenterEfficiency(var MachineCenter: Record "Machine Center"; ProductionOrder: Record "Production Order"; Efficiency: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", ProdOrderRoutingLine.Type::"Machine Center");
        MachineCenter.Get(ProdOrderRoutingLine."No.");
        MachineCenter.Validate(Efficiency, Efficiency + Efficiency);
        MachineCenter.Modify(true);
    end;

    [Normal]
    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Enum "Capacity Type")
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Planned);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange(Type, Type);
        ProdOrderRoutingLine.FindSet();
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; Type: Enum "Capacity Type"; No: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange(Type, Type);
        RoutingLine.SetRange("No.", No);
        RoutingLine.FindFirst();
    end;

    local procedure CalculateAllocatedTime(ProductionOrder: Record "Production Order") ExpectedlAllocatedTime: Decimal
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange(Status, ProductionOrder.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderCapacityNeed.FindSet();
        repeat
            ExpectedlAllocatedTime += ProdOrderCapacityNeed."Allocated Time"
        until ProdOrderCapacityNeed.Next() = 0;
    end;

    local procedure VerifyCapNeedAllocatedTime(ProductionOrder: Record "Production Order"; ExpectedlAllocatedTime: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActualAllocatedTime: Decimal;
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Planned);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindSet();
        repeat
            ActualAllocatedTime += ProdOrderRoutingLine."Setup Time" + ProductionOrder.Quantity * ProdOrderRoutingLine."Run Time";
        until ProdOrderRoutingLine.Next() = 0;

        Assert.AreEqual(ExpectedlAllocatedTime, ActualAllocatedTime, ErrAllocatedTimeMustBeSame);
    end;

    local procedure VerifyRunSetupTime(ProductionOrder: Record "Production Order"; Type: Enum "Capacity Type")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", Type);
        FindRoutingLine(
          RoutingLine, ProdOrderRoutingLine."Routing No.", Type, ProdOrderRoutingLine."No.");
        Assert.AreEqual(
          ProdOrderRoutingLine."Setup Time", RoutingLine."Setup Time", StrSubstNo(ErrTimeMustBeSame,
            RoutingLine.FieldCaption("Setup Time"), RoutingLine."Setup Time", RoutingLine.TableCaption()));
        Assert.AreEqual(
          ProdOrderRoutingLine."Run Time", RoutingLine."Run Time", StrSubstNo(ErrTimeMustBeSame,
            RoutingLine.FieldCaption("Run Time"), RoutingLine."Run Time", RoutingLine.TableCaption()));
    end;

    local procedure VerifyProdOrderLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Item No.", ProductionOrder."Source No.");
        ProdOrderLine.TestField(Quantity, ProductionOrder.Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandler(var CreateOrderFromSales: Page "Create Order From Sales"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

