codeunit 137224 "TransfOrder Whse Validate Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Transfer Order] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ErrFieldMustNotBeChanged: Label '%1 must not be changed when a %2 for this %3 exists';
        ErrStatusMustBeOpen: Label 'Status must be equal to ''Open''  in %1';
        ErrCannotBeDeleted: Label 'The %1 cannot be deleted when a related %2 exists';
        UnexpectedMessage: Label 'Unexpected message: "%1". Expected: "%2"';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        TransferReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"TransfOrder Whse Validate Line");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"TransfOrder Whse Validate Line");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        DisableWarnings();

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        TransferReceivablesSetup.Get();
        TransferReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        TransferReceivablesSetup.Modify(true);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"TransfOrder Whse Validate Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedTransferOrderVariantCo()
    begin
        TransferOrderVariantCodChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTransferOrderVariantCodCha()
    begin
        TransferOrderVariantCodChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedTransferOrderQtyChange()
    begin
        TransferOrderQtyChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTransferOrderQtyChange()
    begin
        TransferOrderQtyChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedTransferOrderUOMChange()
    begin
        TransferOrderUOMChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTransferOrderUOMChange()
    begin
        TransferOrderUOMChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedTransferOrderDelLines()
    var
        TransferHeader: Record "Transfer Header";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, TransferHeader.TableCaption());

        TransferOrderDelLines(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTransferOrderDelLines()
    var
        TransferLine: Record "Transfer Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrCannotBeDeleted,
            TransferLine.TableCaption(), WhseShptLine.TableCaption());

        TransferOrderDelLines(true);
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
        TransferReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        TransferReceivablesSetup.Get();
        TransferReceivablesSetup.Validate("Credit Warnings", TransferReceivablesSetup."Credit Warnings"::"No Warning");
        TransferReceivablesSetup.Validate("Stockout Warning", false);
        TransferReceivablesSetup.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Item: Record Item; FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitCode: Code[10])
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitCode);
        // One of the test cases will try to update quantity to "original - 1" so it is important to have quantity at least 2
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10) + 2);
    end;

    local procedure TestTransferOrderSetup(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Item: Record Item; var ToLocation: Record Location)
    var
        FromLocationCode: Code[10];
        IntransitLocationCode: Code[10];
    begin
        LocationSetup(ToLocation);

        LibraryInventory.CreateItem(Item);
        CreateAndUpdateLocIntransit(FromLocationCode, IntransitLocationCode);

        CreateTransferOrder(TransferHeader, TransferLine, Item, ToLocation.Code, FromLocationCode, IntransitLocationCode);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure TransferOrderFieldChange(Reopen: Boolean; TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; FieldNo: Integer; Value: Variant)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        ExpectedErrorMessage: Text[1024];
    begin
        RecRef.GetTable(TransferLine);
        FieldRef := RecRef.Field(FieldNo);

        if Reopen then begin
            ReleaseTransferDoc.Reopen(TransferHeader);
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            TransferLine.FindFirst();
        end;

        ExpectedErrorMessage := StrSubstNo(ErrFieldMustNotBeChanged,
            FieldRef.Name, WhseShptLine.TableCaption(), TransferLine.TableCaption());

        asserterror UpdateTransferLine(TransferLine, FieldNo, Value);
        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
    end;

    local procedure TransferOrderDelLines(Reopen: Boolean)
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
    begin
        Initialize();
        TestTransferOrderSetup(TransferHeader, TransferLine, Item, Location);

        if Reopen then begin
            ReleaseTransferDoc.Reopen(TransferHeader);
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            TransferLine.FindFirst();
        end;

        asserterror TransferLine.DeleteAll(true);

        if not Reopen then
            Assert.ExpectedTestFieldError(TransferHeader.FieldCaption(Status), Format(TransferHeader.Status::Open));
        ClearLastError();
    end;

    local procedure TransferOrderVariantCodChange(Reopen: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        TestTransferOrderSetup(TransferHeader, TransferLine, Item, Location);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        TransferOrderFieldChange(Reopen, TransferHeader, TransferLine, TransferLine.FieldNo("Variant Code"), ItemVariant.Code);
    end;

    local procedure TransferOrderQtyChange(Reopen: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestTransferOrderSetup(TransferHeader, TransferLine, Item, Location);

        TransferOrderFieldChange(Reopen, TransferHeader, TransferLine, TransferLine.FieldNo(Quantity), TransferLine.Quantity - 1);
    end;

    local procedure TransferOrderUOMChange(Reopen: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();
        TestTransferOrderSetup(TransferHeader, TransferLine, Item, Location);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        TransferOrderFieldChange(Reopen, TransferHeader, TransferLine, TransferLine.FieldNo("Unit of Measure Code"), ItemUnitOfMeasure.Code);
    end;

    local procedure CreateAndUpdateLocIntransit(var LocationCode2: Code[10]; var LocationCode3: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location2: Record Location;
    begin
        // Create Location, Update Inventory Posting Setup And Intransit Location for Transfer .
        CreateAndUpdateLocation(Location2, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);
        LocationCode2 := Location2.Code;
        CreateAndUpdateLocation(Location2, false, true);
        LocationCode3 := Location2.Code;
    end;

    local procedure CreateAndUpdateLocation(var Location2: Record Location; RequireReceive: Boolean; UseAsInTransit: Boolean)
    begin
        // Create Location.
        LibraryWarehouse.CreateLocation(Location2);
        Location2.Validate("Require Receive", RequireReceive);
        Location2.Validate("Use As In-Transit", UseAsInTransit);
        Location2.Modify(true);
    end;

    local procedure UpdateTransferLine(var TransferLine: Record "Transfer Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(TransferLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(TransferLine);
        TransferLine.Modify(true);
    end;
}

