codeunit 137221 "SalesOrder Whse Validate Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Order] [Sales] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLoweredPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        ErrFieldMustNotBeChanged: Label '%1 must not be changed when a %2 for this %3 exists';
        ErrStatusMustBeOpen: Label 'Status must be equal to ''Open''  in %1';
        ErrCannotBeDeleted: Label 'The %1 cannot be deleted when a related %2 exists';
        UnexpectedMessage: Label 'Unexpected message: "%1". Expected: "%2"';
        MissingPermissionsMessage: Label 'Sorry, the current permissions prevented the action. (TableData';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SalesOrder Whse Validate Line");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SalesOrder Whse Validate Line");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        DisableWarnings();

        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify(true);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SalesOrder Whse Validate Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderTypeChange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
        ExpectedErrorMessage: Text[1024];
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);

        ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, SalesHeader.TableCaption());

        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate(Type, SalesLine2.Type::Resource);
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));

        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderTypeChange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);

        SalesOrderFieldChange(true, SalesHeader, SalesLine, SalesLine.FieldNo(Type), SalesLine.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderNoChange()
    begin
        SalesOrderNoChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderNoChange()
    begin
        SalesOrderNoChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderVariantCodCh()
    begin
        SalesOrderVariantCodChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderVariantCodChange()
    begin
        SalesOrderVariantCodChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderLocCodChange()
    begin
        SalesOrderLocCodChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderLocCodChange()
    begin
        SalesOrderLocCodChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderQtyChange()
    begin
        SalesOrderQtyChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderQtyChange()
    begin
        SalesOrderQtyChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderUOMChange()
    begin
        SalesOrderUOMChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderUOMChange()
    begin
        SalesOrderUOMChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderDropShmtChan()
    begin
        SalesOrderDropShmtChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderDropShmtChange()
    begin
        SalesOrderDropShmtChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedSalesOrderDelLines()
    var
        SalesHeader: Record "Sales Header";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, SalesHeader.TableCaption());

        SalesOrderDelLines(false, ExpectedErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSalesOrderDelLines()
    var
        SalesLine: Record "Sales Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrCannotBeDeleted,
            SalesLine.TableCaption(), WhseShptLine.TableCaption());

        SalesOrderDelLines(true, ExpectedErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockSOwithWhseShptLineDeletionWithoutPermissions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Location: Record Location;
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        // [SCENARIO 399442] User without permission to Warehouse Shipment Line is blocked for deletion of S. Order with shipment lines
        Initialize();

        // [GIVEN] Released Sales Order with Warehouse Shipment Line
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] User have permissions without access to Warehouse Shipment Line record
        LibraryLoweredPermissions.SetSalesDocsPost();

        // [WHEN] Sales Order is deleted
        // [THEN] Error message about missing permissions to Warehouse Shipment Line appears 
        asserterror SalesHeader.Delete(true);
        assert.ExpectedError(StrSubstNo(MissingPermissionsMessage, WhseShptLine.TableCaption()));
        ClearLastError();
    end;

    local procedure LocationSetup(var Location: Record Location)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location);
        // Skip validate trigger for bin mandatory to improve performance.
        Location."Bin Mandatory" := true;
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(
          Bin,
          Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
          '',
          '');

        Bin.Validate(Dedicated, true);
        Bin.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure DisableWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; Location: Record Location)
    begin
        // One of the test cases will try to update quantity to "original - 1" so it is important to have quantity at least 2
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10) + 2, Location.Code, WorkDate());
    end;

    local procedure TestSalesOrderSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Item: Record Item; var Location: Record Location)
    begin
        LocationSetup(Location);

        LibraryInventory.CreateItem(Item);

        CreateSalesOrder(SalesHeader, SalesLine, Item, Location);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure SalesOrderFieldChange(Reopen: Boolean; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; FieldNo: Integer; Value: Variant)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        ExpectedErrorMessage: Text[1024];
    begin
        RecRef.GetTable(SalesLine);
        FieldRef := RecRef.Field(FieldNo);

        if Reopen then begin
            LibrarySales.ReopenSalesDocument(SalesHeader);
            ExpectedErrorMessage := StrSubstNo(ErrFieldMustNotBeChanged,
                FieldRef.Name, WhseShptLine.TableCaption(), SalesLine.TableCaption());
        end else
            ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, SalesHeader.TableCaption());

        asserterror LibraryInventory.UpdateSalesLine(SalesLine, FieldNo, Value);
        if Reopen then
            Assert.ExpectedTestFieldError(FieldRef.Name, '')
        else
            Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
        ClearLastError();
    end;

    local procedure SalesOrderDelLines(Reopen: Boolean; ExpectedErrorMessage: Text[1024])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Location: Record Location;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);

        if Reopen then begin
            LibrarySales.ReopenSalesDocument(SalesHeader);
            SalesLine.SetRange("No.", SalesLine."No.");
            SalesLine.FindFirst();
        end;

        asserterror SalesLine.DeleteAll(true);

        if not Reopen then
            Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));

        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
    end;

    [Normal]
    local procedure SalesOrderNoChange(Reopen: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);
        LibraryInventory.CreateItem(Item);

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo("No."), Item."No.");
    end;

    local procedure SalesOrderVariantCodChange(Reopen: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo("Variant Code"), ItemVariant.Code);
    end;

    local procedure SalesOrderLocCodChange(Reopen: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);
        LocationSetup(Location);

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo("Location Code"), Location.Code);
    end;

    local procedure SalesOrderQtyChange(Reopen: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo(Quantity), SalesLine.Quantity - 1);
    end;

    local procedure SalesOrderUOMChange(Reopen: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo("Unit of Measure Code"), UnitOfMeasure.Code);
    end;

    local procedure SalesOrderDropShmtChange(Reopen: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestSalesOrderSetup(SalesHeader, SalesLine, Item, Location);

        SalesOrderFieldChange(Reopen, SalesHeader, SalesLine, SalesLine.FieldNo("Drop Shipment"), not SalesLine."Drop Shipment");
    end;
}

