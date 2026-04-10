codeunit 137222 "PurchOrder Whse Validate Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Order] [Purchase] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        ErrFieldMustNotBeChanged: Label '%1 must not be changed when a %2 for this %3 exists';
        ErrStatusMustBeOpen: Label 'Status must be equal to ''Open''  in %1';
        ErrCannotBeDeleted: Label 'The %1 cannot be deleted when a related %2 exists';
        UnexpectedMessage: Label 'Unexpected message: "%1". Expected: "%2"';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        PurchaseReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"PurchOrder Whse Validate Line");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"PurchOrder Whse Validate Line");

        IsInitialized := true;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        DisableWarnings();

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        PurchaseReceivablesSetup.Get();
        PurchaseReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchaseReceivablesSetup.Modify(true);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"PurchOrder Whse Validate Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderTypeChang()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
        WhseReceiptLine: Record "Warehouse Receipt Line";
        ExpectedErrorMessage: Text[1024];
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);

        ExpectedErrorMessage := StrSubstNo(ErrFieldMustNotBeChanged,
            PurchaseLine.FieldName(Type), WhseReceiptLine.TableCaption(), PurchaseLine.TableCaption());

        asserterror PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");
        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderTypeChange()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);

        PurchaseOrderFieldChange(true, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo(Type), PurchaseLine.Type::"Fixed Asset");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderNoChange()
    begin
        PurchaseOrderNoChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderNoChange()
    begin
        PurchaseOrderNoChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderVariantCo()
    begin
        PurchaseOrderVariantCodChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderVariantCodCha()
    begin
        PurchaseOrderVariantCodChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderLocCodCha()
    begin
        PurchaseOrderLocCodChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderLocCodChange()
    begin
        PurchaseOrderLocCodChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderQtyChange()
    begin
        PurchaseOrderQtyChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderQtyChange()
    begin
        PurchaseOrderQtyChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderUOMChange()
    begin
        PurchaseOrderUOMChange(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderUOMChange()
    begin
        PurchaseOrderUOMChange(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedPurchaseOrderDelLines()
    var
        PurchaseHeader: Record "Purchase Header";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, PurchaseHeader.TableCaption());

        PurchaseOrderDelLines(false, ExpectedErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPurchaseOrderDelLines()
    var
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        ExpectedErrorMessage: Text[1024];
    begin
        ExpectedErrorMessage := StrSubstNo(ErrCannotBeDeleted,
            PurchaseLine.TableCaption(), WhseReceiptLine.TableCaption());

        PurchaseOrderDelLines(true, ExpectedErrorMessage);
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
        PurchaseReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchaseReceivablesSetup.Get();
        PurchaseReceivablesSetup.Validate("Credit Warnings", PurchaseReceivablesSetup."Credit Warnings"::"No Warning");
        PurchaseReceivablesSetup.Validate("Stockout Warning", false);
        PurchaseReceivablesSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; Location: Record Location)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        // One of the test cases will try to update quantity to "original - 1" so it is important to have quantity at least 2
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10) + 2);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure TestPurchaseOrderSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Item: Record Item; var Location: Record Location)
    begin
        LocationSetup(Location);

        LibraryInventory.CreateItem(Item);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, Location);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure PurchaseOrderFieldChange(Reopen: Boolean; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; FieldNo: Integer; Value: Variant)
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        ExpectedErrorMessage: Text[1024];
    begin
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(FieldNo);

        if Reopen then begin
            LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
            ExpectedErrorMessage := StrSubstNo(ErrFieldMustNotBeChanged,
                FieldRef.Name, WhseReceiptLine.TableCaption(), PurchaseLine.TableCaption());
        end else
            ExpectedErrorMessage := StrSubstNo(ErrStatusMustBeOpen, PurchaseHeader.TableCaption());

        asserterror UpdatePurchaseLine(PurchaseLine, FieldNo, Value);
        if Reopen then
            Assert.ExpectedTestFieldError(FieldRef.Name, '')
        else
            Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
        ClearLastError();
    end;

    local procedure PurchaseOrderDelLines(Reopen: Boolean; ExpectedErrorMessage: Text[1024])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);

        if Reopen then begin
            LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
            PurchaseLine.SetRange("No.", PurchaseLine."No.");
            PurchaseLine.FindFirst();
        end;

        asserterror PurchaseLine.DeleteAll(true);
        if not Reopen then
            Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));

        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
    end;

    [Normal]
    local procedure PurchaseOrderNoChange(Reopen: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);
        LibraryInventory.CreateItem(Item);

        PurchaseOrderFieldChange(Reopen, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo("No."), Item."No.");
    end;

    local procedure PurchaseOrderVariantCodChange(Reopen: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        PurchaseOrderFieldChange(Reopen, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo("Variant Code"), ItemVariant.Code);
    end;

    local procedure PurchaseOrderLocCodChange(Reopen: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);
        LocationSetup(Location);

        PurchaseOrderFieldChange(Reopen, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo("Location Code"), Location.Code);
    end;

    local procedure PurchaseOrderQtyChange(Reopen: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);

        PurchaseOrderFieldChange(Reopen, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo(Quantity), PurchaseLine.Quantity - 1);
    end;

    local procedure PurchaseOrderUOMChange(Reopen: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();
        TestPurchaseOrderSetup(PurchaseHeader, PurchaseLine, Item, Location);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        PurchaseOrderFieldChange(
          Reopen, PurchaseHeader, PurchaseLine, PurchaseLine.FieldNo("Unit of Measure Code"), ItemUnitOfMeasure.Code);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Sales Line base on Field and its corresponding value.
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.Modify(true);
    end;
}

