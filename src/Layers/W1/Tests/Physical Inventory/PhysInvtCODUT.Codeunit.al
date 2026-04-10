codeunit 137461 "Phys. Invt. COD UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";

    [Test]
    [HandlerFunctions('PhysInventoryOrderLinePageHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunPhysInventoryOrderShowDuplicateLines()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate OnRun trigger of Codeunit - 5005361, Show Duplicate Order lines.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);

        // Enqueue values for use in PhysInventoryOrderLinePageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 2;  // Required to create second Phys. Inventory Order Line.
        PhysInvtOrderLine.Insert();

        // Exercise & Verify: Show Duplicate Lines on Phys. Inventory Order. Verify the Duplicate Phys. Inventory Order Line in PhysInventoryOrderLinePageHandler.
        CODEUNIT.Run(CODEUNIT::"Phys. Invt.-Show Duplicates", PhysInvtOrderHeader);
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhysInvtOrderPrintDocument()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO] validate PhysInvtOrderPrint function of Codeunit - 5005396, Print Document Comfort.
        // Setup.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);

        // Exercise & Verify: Print Phys. Inventory Order Report. Added Report Handler PhysInvtOrderDiffListReportHandler.
        DocumentPrint.PrintInvtOrder(PhysInvtOrderHeader, true);  // Use RequestPage - TRUE.
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhysInvtOrderTestPrintDocument()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO] validate PhysInvtOrderPrintTest function of Codeunit - 5005396, Print Document Comfort.
        // Setup.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);

        // Exercise & Verify: Print Phys. Invt. Order - Test Report. Added Report Handler PhysInvtOrderTestReportHandler.
        DocumentPrint.PrintInvtOrderTest(PhysInvtOrderHeader, true);  // Use RequestPage - TRUE.
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderPrintDocument()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO] validate PostedPhysInvtOrderPrint function of Codeunit - 5005396, Print Document Comfort.
        // Setup.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine);

        // Exercise & Verify: Print Posted Phys. Invt. Order Diff. Report. Added Report Handler PostedPhysInvtOrderDiffReportHandler.
        DocumentPrint.PrintPostedInvtOrder(PstdPhysInvtOrderHdr, true);  // Use RequestPage - TRUE.
    end;

    [Test]
    [HandlerFunctions('PhysInvtRecordingReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhysInvtRecPrintDocument()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO] validate PhysInvtRecPrint function of Codeunit - 5005396, Print Document Comfort.
        // Setup.
        CreatePhysInventoryRecording(PhysInvtRecordHeader, LibraryUTUtility.GetNewCode());

        // Exercise & Verify: Print Phys. Invt. Recording Report. Added Report Handler PhysInvtRecordingReportHandler.
        DocumentPrint.PrintInvtRecording(PhysInvtRecordHeader, true);  // Use RequestPage - TRUE.
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecPrintDocument()
    var
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO] validate PostedPhysInvtRecPrint function of Codeunit - 5005396, Print Document Comfort.
        // Setup.
        CreatePostedPhysInventoryRecording(PstdPhysInvtRecordHdr, LibraryUTUtility.GetNewCode());

        // Exercise & Verify: Print Posted Phys. Invt. Recording Report. Added Report Handler PostedPhysInvtRecordingReportHandler.
        DocumentPrint.PrintPostedInvtRecording(PstdPhysInvtRecordHdr, true);  // Use RequestPage - TRUE.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SignFactorForCreateReservationEntry()
    var
        ReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        NextEntryNo: Integer;
        SignFactor: Option;
    begin
        // [SCENARIO] validate the SignFactor function of Codeunit - 99000830, Create Reserv. Entry.
        // Setup.
        NextEntryNo := 1;
        if ReservationEntry.FindLast() then
            NextEntryNo := ReservationEntry."Entry No." + 1;
        ReservationEntry."Entry No." := NextEntryNo;
        ReservationEntry."Source Type" := DATABASE::"Phys. Invt. Order Line";
        ReservationEntry.Positive := true;
        ReservationEntry.Insert();

        // [WHEN] Invoke SignFactor function of Codeunit Create Reserv. Entry.
        SignFactor := CreateReservEntry.SignFactor(ReservationEntry);

        // [THEN] Verify the correct value after calling SignFactor function of Codeunit Create Reserv. Entry.
        Assert.AreEqual(1, SignFactor, 'Value must match.');
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

    local procedure CreatePhysInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := CreateItem();
        PhysInvtOrderLine."Quantity (Base)" := 1;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePostedPhysInventoryOrder(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr"; var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line")
    begin
        PstdPhysInvtOrderHdr."No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderHdr.Insert();

        PstdPhysInvtOrderLine."Document No." := PstdPhysInvtOrderHdr."No.";
        PstdPhysInvtOrderLine."Line No." := 1;
        PstdPhysInvtOrderLine."Item No." := CreateItem();
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInventoryRecording(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();

        PhysInvtRecordLine."Order No." := OrderNo;
        PhysInvtRecordLine."Order Line No." := 1;
        PhysInvtRecordLine.Quantity := 1;
        PhysInvtRecordLine.Recorded := true;
        PhysInvtRecordLine.Insert();
    end;

    local procedure CreatePostedPhysInventoryRecording(var PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; OrderNo: Code[20])
    var
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        PstdPhysInvtRecordHdr."Order No." := OrderNo;
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Insert();

        PstdPhysInvtRecordLine."Order No." := OrderNo;
        PstdPhysInvtRecordLine."Order Line No." := 1;
        PstdPhysInvtRecordLine.Quantity := 1;
        PstdPhysInvtRecordLine.Recorded := true;
        PstdPhysInvtRecordLine.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderDiffListReportHandler(var PhysInvtOrderDiffList: TestRequestPage "Phys. Invt. Order Diff. List")
    begin
        PhysInvtOrderDiffList.SaveAsXml(LibraryReportDataset.GetFileName(), LibraryReportDataset.GetParametersFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderTestReportHandler(var PhysInvtOrderTest: TestRequestPage "Phys. Invt. Order - Test")
    begin
        PhysInvtOrderTest.SaveAsXml(LibraryReportDataset.GetFileName(), LibraryReportDataset.GetParametersFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderDiffReportHandler(var PostedPhysInvtOrderDiff: TestRequestPage "Posted Phys. Invt. Order Diff.")
    begin
        PostedPhysInvtOrderDiff.SaveAsXml(LibraryReportDataset.GetFileName(), LibraryReportDataset.GetParametersFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingReportHandler(var PhysInvtRecording: TestRequestPage "Phys. Invt. Recording")
    begin
        PhysInvtRecording.SaveAsXml(LibraryReportDataset.GetFileName(), LibraryReportDataset.GetParametersFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingReportHandler(var PostedPhysInvtRecording: TestRequestPage "Posted Phys. Invt. Recording")
    begin
        PostedPhysInvtRecording.SaveAsXml(LibraryReportDataset.GetFileName(), LibraryReportDataset.GetParametersFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryOrderLinePageHandler(var PhysInventoryOrderLines: TestPage "Physical Inventory Order Lines")
    var
        DocumentNo: Variant;
        ItemNo: Variant;
        LineCount: Integer;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(ItemNo);
        PhysInventoryOrderLines.FILTER.SetFilter("Document No.", DocumentNo);
        PhysInventoryOrderLines.FILTER.SetFilter("Item No.", ItemNo);
        repeat
            LineCount += 1;
        until not PhysInventoryOrderLines.Next();
        Assert.IsTrue(LineCount > 1, 'No of Lines must be greater than one');  // Verify more than one Phys. Inventory Order lines.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

