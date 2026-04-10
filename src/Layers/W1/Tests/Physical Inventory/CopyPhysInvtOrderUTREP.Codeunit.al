codeunit 137459 "CopyPhysInvtOrder UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('CopyPhysInvtOrderRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportCopyPhysInventoryOrder()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeader2: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.
        // Setup.
        Initialize();
        CreatePhysicalInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No."); // Required inside CopyPhysInvtOrderRequestPageHandler.
        CreatePhysicalInventoryOrderHeader(PhysInvtOrderHeader2);

        // [WHEN] Run Report Copy Physical Inventory Order.
        CopyPhysicalInventoryOrder(PhysInvtOrderHeader2);  // Test Autocommit, because COMMIT is used in OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.

        // [THEN] Verify Physical Inventory Order Line is successfully copied for second Physical Inventory Order Header.
        PhysInvtOrderLine2.SetRange("Document No.", PhysInvtOrderHeader2."No.");
        PhysInvtOrderLine2.FindFirst();
        PhysInvtOrderLine2.TestField("Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtOrderLine2.TestField("Location Code", PhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('CopyPhysInvtOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportCopyPhysInventoryOrderError()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.
        // Setup.
        Initialize();
        CreatePhysicalInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No."); // Required inside CopyPhysInvtOrderRequestPageHandler.

        // [WHEN] Run Report Copy Physical Inventory Order.
        asserterror CopyPhysicalInventoryOrder(PhysInvtOrderHeader);  // Test Autocommit, because COMMIT is used in OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.

        // [THEN] Verify error code, Order cannot be copied onto itself.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CopyPostedPhysInvtOrderRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportCopyPostedPhysInventoryOrder()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.
        // Setup.
        Initialize();
        CreatePostedPhysInventoryOrderHeader(PstdPhysInvtOrderHdr);
        CreatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");
        LibraryVariableStorage.Enqueue(PstdPhysInvtOrderHdr."No."); // Required inside CopyPostedPhysInvtOrderRequestPageHandler.
        CreatePhysicalInventoryOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run Report Copy Physical Inventory Order.
        CopyPhysicalInventoryOrder(PhysInvtOrderHeader);  // Test Autocommit, because COMMIT is used in OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.

        // [THEN] Verify Posted Physical Inventory Order Line is successfully copied for Physical Inventory Order Header.
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Item No.", PstdPhysInvtOrderLine."Item No.");
        PhysInvtOrderLine.TestField("Location Code", PstdPhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('CopyPhysInvtOrderRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportCopyPhysInventoryOrderTwice()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeader2: Record "Phys. Invt. Order Header";
        PhysInvtOrderLineCount: Integer;
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.
        // Setup.
        Initialize();
        CreatePhysicalInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No."); // Required inside CopyPhysInvtOrderRequestPageHandler.
        CreatePhysicalInventoryOrderHeader(PhysInvtOrderHeader2);
        CopyPhysicalInventoryOrder(PhysInvtOrderHeader2);
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No."); // Required inside CopyPhysInvtOrderRequestPageHandler.

        // [WHEN] Run Report Copy Physical Inventory Order again for same Physical Inventory Order Header.
        CopyPhysicalInventoryOrder(PhysInvtOrderHeader2);  // Test Autocommit, because COMMIT is used in OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.

        // [THEN] Verify Physical Inventory Order Line of same Physical Inventory Order Header is not copied again.
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader2."No.");
        PhysInvtOrderLine.FindSet();
        PhysInvtOrderLineCount := PhysInvtOrderLine.Count();
        Assert.AreEqual(PhysInvtOrderLineCount, 1, 'Order Line Count must not be greater than 1.');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreatePhysicalInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure CreatePhysicalInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PhysInvtOrderLine."Document No." := DocumentNo;
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := CreateItem();
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysicalInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        CreatePhysicalInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader."Location Code" := CreateLocation();
        PhysInvtOrderHeader.Modify();
        CreatePhysicalInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");
    end;

    local procedure CreatePostedPhysInventoryOrderHeader(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr")
    begin
        PstdPhysInvtOrderHdr."No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderHdr.Insert();
    end;

    local procedure CreatePostedPhysInventoryOrderLine(var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PstdPhysInvtOrderLine."Document No." := DocumentNo;
        PstdPhysInvtOrderLine."Line No." := 1;
        PstdPhysInvtOrderLine."Item No." := CreateItem();
        PstdPhysInvtOrderLine."Location Code" := CreateLocation();
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure CopyPhysicalInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    var
        CopyPhysInvtOrder: Report "Copy Phys. Invt. Order";
    begin
        Commit();  // COMMIT required in OnPreReport Trigger of Report 5005362 - Copy Phys. Invt. Order.
        CopyPhysInvtOrder.SetPhysInvtOrderHeader(PhysInvtOrderHeader);
        CopyPhysInvtOrder.Run();  // Invokes CopyPhysInvtOrderRequestPageHandler or CopyPostedPhysInvtOrderRequestPageHandler as required.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPhysInvtOrderRequestPageHandler(var CopyPhysInvtOrder: TestRequestPage "Copy Phys. Invt. Order")
    var
        PhysInvtOrderHeaderNo: Variant;
        DocumentType: Option "Phys. Invt. Order","Posted Phys. Invt. Order ";
    begin
        LibraryVariableStorage.Dequeue(PhysInvtOrderHeaderNo);
        CopyPhysInvtOrder.DocumentType.SetValue(Format(DocumentType::"Phys. Invt. Order"));
        CopyPhysInvtOrder.DocumentNo.SetValue(PhysInvtOrderHeaderNo);
        CopyPhysInvtOrder.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPostedPhysInvtOrderRequestPageHandler(var CopyPhysInvtOrder: TestRequestPage "Copy Phys. Invt. Order")
    var
        PstdPhysInvtOrderHdrNo: Variant;
        DocumentType: Option "Phys. Invt. Order","Posted Phys. Invt. Order ";
    begin
        LibraryVariableStorage.Dequeue(PstdPhysInvtOrderHdrNo);
        CopyPhysInvtOrder.DocumentType.SetValue(Format(DocumentType::"Posted Phys. Invt. Order "));
        CopyPhysInvtOrder.DocumentNo.SetValue(PstdPhysInvtOrderHdrNo);
        CopyPhysInvtOrder.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

