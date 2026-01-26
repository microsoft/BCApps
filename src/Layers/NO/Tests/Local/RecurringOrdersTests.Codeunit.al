codeunit 144200 "Recurring Orders Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Recurring Order] [Group]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        Initialized: Boolean;

    local procedure Initialize()
    begin
        if Initialized then
            exit;
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        Initialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGroup_Code()
    var
        SalesHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDocType: Option;
    begin
        // [FEATURE] [Recurring Group]
        Initialize();

        CreateRecurringSetup(RecurringGroup);
        Commit();

        // Check that Recurring Groups are only valid for Blanket Orders
        for NewDocType := SalesHeader."Document Type"::Quote.AsInteger() to SalesHeader."Document Type"::"Return Order".AsInteger() do begin
            SalesHeader.Init();
            SalesHeader.Validate("Document Type", NewDocType);
            if NewDocType = SalesHeader."Document Type"::"Blanket Order".AsInteger() then begin
                SalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
                Assert.AreEqual(RecurringGroup.Code, SalesHeader."Recurring Group Code", '');
            end else begin
                asserterror SalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
                Assert.ExpectedError(Format(SalesHeader."Document Type"::"Blanket Order"));
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_Dateformula()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        PeriodIndex: Integer;
        Periods: Text;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        Periods := 'D,W,M,Q,Y';
        for PeriodIndex := 1 to 5 do begin // For any type of period
            Evaluate(NewDF, '<1' + SelectStr(PeriodIndex, Periods) + '>');
            OriginalDate := WorkDate();

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Recurring Date formula set
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := WorkDate();
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Blanket Order Date is shifted forward by the Date formula
            BlanketSalesHeader.Find();
            Assert.AreEqual(CalcDate(RecurringGroup."Date formula", OriginalDate), BlanketSalesHeader."Order Date", '');
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_CreateOnlyTheLatest()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        PeriodIndex: Integer;
        Periods: Text;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        Periods := 'D,W,M,Q,Y';
        for PeriodIndex := 1 to 5 do begin  // Use different types of period Date formulas
            Evaluate(NewDF, '<1' + SelectStr(PeriodIndex, Periods) + '>');
            OriginalDate := WorkDate();

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Created only the lastest = TRUE
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Create only the latest" := true;
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := CalcDate('<2' + SelectStr(PeriodIndex, Periods) + '>', WorkDate());
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Blanket Order Date is shifted forward to be greater than the Processing Date
            BlanketSalesHeader.Find();
            Assert.IsTrue(ProcessingDate < BlanketSalesHeader."Order Date", SelectStr(PeriodIndex, Periods));
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_StartingDate()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        PeriodIndex: Integer;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        for PeriodIndex := -1 to 1 do begin // Use starting dates wrt order date
            OriginalDate := WorkDate();
            ProcessingDate := WorkDate();
            Evaluate(NewDF, '<1D>');

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Starting Date <> 0D
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Starting date" := CalcDate(StrSubstNo('<%1D>', PeriodIndex), OriginalDate);
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            if PeriodIndex > 0 then begin
                asserterror CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);
                Assert.ExpectedError('Processing date');
            end else begin
                CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);
                BlanketSalesHeader.Find();
                Assert.AreEqual(CalcDate(RecurringGroup."Date formula", OriginalDate), BlanketSalesHeader."Order Date", '');
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_ClosingDate()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        PeriodIndex: Integer;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);
        for PeriodIndex := -1 to 1 do begin
            OriginalDate := WorkDate();
            ProcessingDate := WorkDate();
            Evaluate(NewDF, '<1D>');

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Closing Date <> 0D
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Closing date" := CalcDate(StrSubstNo('<%1D>', PeriodIndex), OriginalDate);
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            // Verify : Check that the creation of the Sales Order Line respects the Closing Date
            if PeriodIndex < 0 then begin
                asserterror CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);
                Assert.ExpectedError('Processing date');
            end else begin
                CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);
                BlanketSalesHeader.Find();
                Assert.AreEqual(CalcDate(RecurringGroup."Date formula", OriginalDate), BlanketSalesHeader."Order Date", '');
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_DocumentDateFormula()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        PeriodIndex: Integer;
        Periods: Text;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        Periods := 'D,W,M,Q,Y';
        for PeriodIndex := 1 to 5 do begin // Use different Date formula Options
            Evaluate(NewDF, '<1D>');
            OriginalDate := WorkDate();

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Recurring Document Date formula set
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Update Document Date" := RecurringGroup."Update Document Date"::"Processing Date";
            RecurringGroup."Document Date Formula" := '<1' + SelectStr(PeriodIndex, Periods) + '>';
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Posting Date", OriginalDate);
            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Document Date", 0D);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := CalcDate(NewDF, WorkDate());
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Document Date is shifted forward by the Date formula
            BlanketSalesHeader.Find();
            Assert.AreEqual(0D, BlanketSalesHeader."Document Date", '');
            SalesOrderHeader.Find();
            Assert.AreEqual(CalcDate('<1' + SelectStr(PeriodIndex, Periods) + '>', ProcessingDate), SalesOrderHeader."Document Date", '');
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_DeliveryDateFormula()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        DeliveryDateDF: DateFormula;
        PeriodIndex: Integer;
        Periods: Text;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        Periods := 'D,W,M,Q,Y';
        for PeriodIndex := 1 to 5 do begin // Use different Date formula Options
            Evaluate(NewDF, '<1D>');
            Evaluate(DeliveryDateDF, '<1' + SelectStr(PeriodIndex, Periods) + '>');
            OriginalDate := WorkDate();

            CreateBlanketSalesOrder(BlanketSalesHeader);

            // Exercise : Create Recurring Sales Order with Recurring Delivery Date formula set
            RecurringGroup."Date formula" := NewDF;

            RecurringGroup."Delivery Date Formula" := Format(DeliveryDateDF);
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Posting Date", OriginalDate);
            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Shipment Date", 0D);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := WorkDate();
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Blanket Order Date is shifted forward by the Date formula
            BlanketSalesHeader.Find();
            Assert.AreEqual(0D, BlanketSalesHeader."Shipment Date", '');
            SalesOrderHeader.Find();
            Assert.AreEqual(CalcDate(DeliveryDateDF, OriginalDate), SalesOrderHeader."Shipment Date", '');
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_UpdatePrice()
    var
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        RecurringGroup: Record "Recurring Group";
        Item: Record Item;
        NewDF: DateFormula;
        PriceChoice: Integer;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        for PriceChoice := // Use different Update Price Options
            RecurringGroup."Update Price"::Fixed to
            RecurringGroup."Update Price"::Reset
        do begin
            OriginalDate := WorkDate();
            ProcessingDate := WorkDate();
            Evaluate(NewDF, '<1D>');

            CreateBlanketSalesOrder(BlanketSalesHeader);

            FindSalesLineWithItem(BlanketSalesHeader, BlanketSalesLine);
            BlanketSalesLine.Validate("Unit Price", BlanketSalesLine."Unit Price" + 1);
            BlanketSalesLine.Modify(true);

            // Exercise : Create Recurring Sales Order with Recurring Update Price set
            Item.Get(BlanketSalesLine."No.");
            Item."Unit Price" := BlanketSalesLine."Unit Price" + 1;
            Item.Modify(true);

            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Update Price" := PriceChoice;
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := WorkDate();
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Sales Order Line Unit Price wrt Recurring group Update Price option
            FindSalesLineWithItem(SalesOrderHeader, SalesOrderLine);
            BlanketSalesLine.Find();
            case PriceChoice of
                RecurringGroup."Update Price"::Fixed:
                    Assert.AreEqual(BlanketSalesLine."Unit Price", SalesOrderLine."Unit Price", '');
                RecurringGroup."Update Price"::Recalculate:
                    Assert.AreEqual(Item."Unit Price", SalesOrderLine."Unit Price", '');
                RecurringGroup."Update Price"::Reset:
                    Assert.AreEqual(0, SalesOrderLine."Unit Price", '');
                else
                    Assert.Fail('Unknown price choice')
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_UpdatePriceV16()
    var
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        RecurringGroup: Record "Recurring Group";
        Item: Record Item;
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        NewDF: DateFormula;
        PriceChoice: Integer;
        ProcessingDate: Date;
        OriginalDate: Date;
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        CreateRecurringSetup(RecurringGroup);

        for PriceChoice := // Use different Update Price Options
            RecurringGroup."Update Price"::Fixed to
            RecurringGroup."Update Price"::Reset
        do begin
            OriginalDate := WorkDate();
            ProcessingDate := WorkDate();
            Evaluate(NewDF, '<1D>');

            CreateBlanketSalesOrder(BlanketSalesHeader);

            FindSalesLineWithItem(BlanketSalesHeader, BlanketSalesLine);
            BlanketSalesLine.Validate("Unit Price", BlanketSalesLine."Unit Price" + 1);
            BlanketSalesLine.Modify(true);

            // Exercise : Create Recurring Sales Order with Recurring Update Price set
            Item.Get(BlanketSalesLine."No.");
            Item."Unit Price" := BlanketSalesLine."Unit Price" + 1;
            Item.Modify(true);
            LibraryPriceCalculation.CreateSalesPriceLine(
                PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
            PriceListLine."Unit Price" := Item."Unit Price" + 3;
            PriceListLine.Status := PriceListLine.Status::Active;
            PriceListLine.Modify();

            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Update Price" := PriceChoice;
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := WorkDate();
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Sales Order Line Unit Price wrt Recurring group Update Price option
            FindSalesLineWithItem(SalesOrderHeader, SalesOrderLine);
            BlanketSalesLine.Find();
            case PriceChoice of
                RecurringGroup."Update Price"::Fixed:
                    Assert.AreEqual(BlanketSalesLine."Unit Price", SalesOrderLine."Unit Price", '');
                RecurringGroup."Update Price"::Recalculate:
                    Assert.AreEqual(PriceListLine."Unit Price", SalesOrderLine."Unit Price", '');
                RecurringGroup."Update Price"::Reset:
                    Assert.AreEqual(0, SalesOrderLine."Unit Price", '');
                else
                    Assert.Fail('Unknown price choice')
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure RecurringGroup_UpdateNumber()
    var
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        RecurringGroup: Record "Recurring Group";
        NewDF: DateFormula;
        NumberChoice: Integer;
        ProcessingDate: Date;
        OriginalDate: Date;
    begin
        Initialize();

        CreateRecurringSetup(RecurringGroup);

        for NumberChoice :=
            RecurringGroup."Update Number"::Constant to
            RecurringGroup."Update Number"::Reduce
        do begin
            OriginalDate := WorkDate();
            ProcessingDate := WorkDate();
            Evaluate(NewDF, '<1D>');

            CreateBlanketSalesOrder(BlanketSalesHeader);
            FindSalesLineWithItem(BlanketSalesHeader, BlanketSalesLine);

            // Exercise : Create Recurring Sales Order with Recurring Update Number set set
            RecurringGroup."Date formula" := NewDF;
            RecurringGroup."Update Number" := NumberChoice;
            RecurringGroup.Modify();

            BlanketSalesHeader.Validate("Order Date", OriginalDate);
            BlanketSalesHeader.Validate("Recurring Group Code", RecurringGroup.Code);
            BlanketSalesHeader.Modify(true);

            ProcessingDate := WorkDate();
            CreateRecurringSalesOrder(BlanketSalesHeader, SalesOrderHeader, false, ProcessingDate);

            // Verify : Check that the Blanket Order Quantity to Ship is update wrt Recurring Group Update Number option
            FindSalesLineWithItem(SalesOrderHeader, SalesOrderLine);
            BlanketSalesLine.Find();
            case NumberChoice of
                RecurringGroup."Update Number"::Constant:
                    Assert.AreEqual(BlanketSalesLine.Quantity, BlanketSalesLine."Qty. to Ship", '');
                RecurringGroup."Update Number"::Reduce:
                    Assert.AreEqual(0, BlanketSalesLine."Qty. to Ship", '');
                else
                    Assert.Fail('Unknown number choice')
            end;
        end;
    end;

    local procedure CreateRecurringSetup(var RecurringGroup: Record "Recurring Group")
    begin
        RecurringGroup.Init();
        RecurringGroup.Code := LibraryUTUtility.GetNewCode10();
        RecurringGroup.Insert();
    end;

    local procedure CreateBlanketSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);

        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Cust."No.");

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateRecurringSalesOrder(BlanketSalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; HiddenError: Boolean; ProcessingDate: Date)
    var
        CreateRecurringOrders: Report "Create Recurring Orders";
    begin
        Commit();

        BlanketSalesHeader.SetRecFilter();
        CreateRecurringOrders.SetHiddenError(HiddenError);
        CreateRecurringOrders.SetCreatingDate(ProcessingDate);
        CreateRecurringOrders.SetTableView(BlanketSalesHeader);
        CreateRecurringOrders.UseRequestPage := false;
        CreateRecurringOrders.Run();

        SalesOrderHeader.SetRange("Document Type", SalesOrderHeader."Document Type"::Order);
        SalesOrderHeader.SetRange("Sell-to Customer No.", BlanketSalesHeader."Sell-to Customer No.");
        SalesOrderHeader.FindFirst();
    end;

    local procedure FindSalesLineWithItem(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgTxt: Text)
    begin
    end;
}

