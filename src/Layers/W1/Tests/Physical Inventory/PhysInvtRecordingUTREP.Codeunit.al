codeunit 137456 "Phys. Invt. Recording UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Recording] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';

    [Test]
    [HandlerFunctions('PhysInvtRecordingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPhysInvtRecordingWithVariousFilters()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] verify execution of Report Physical Inventory Recording with various filters.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInvtRecordingOrderHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryVariableStorage.Enqueue(PhysInvtRecordHeader."Order No."); // Required inside PhysInvtRecordingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Recording");

        // [THEN] Verify Order No, Recording No, Status and Description on Report Physical Inventory Recording.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header_Order_No_', PhysInvtRecordHeader."Order No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header_Recording_No_', 1);
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header__Status', Format(PhysInvtRecordHeader.Status));
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header__Description', PhysInvtRecordHeader.Description);
    end;

    [Test]
    [HandlerFunctions('PhysInvtRecordingWithoutFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPhysInvtRecordingWithoutFilters()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] verify execution of Report Physical Inventory Recording without any filter.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInvtRecordingOrderHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");

        // [WHEN] Run report Physical Inventory Recording without any filter.
        REPORT.Run(REPORT::"Phys. Invt. Recording");

        // [THEN] Verify Report runs for all the Physical Inventory Order which exists in database.
        LibraryReportDataset.LoadDataSetFile();
        PhysInvtRecordHeader.FindFirst();
        repeat
            LibraryReportDataset.AssertElementWithValueExists(
              'Phys__Invt__Recording_Header_Order_No_', PhysInvtRecordHeader."Order No.");
        until PhysInvtRecordHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPostedPhysInvtRecordingWithVariousFilters()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
    begin
        // [SCENARIO] verify execution of Report Posted Phys. Invt. Recording with various filters.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePostedPhysInvtRecordingOrderHeader(PstdPhysInvtRecordHdr, PhysInvtOrderHeader."No.");
        LibraryVariableStorage.Enqueue(PstdPhysInvtRecordHdr."Order No."); // Required inside PostedPhysInvtRecordingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Posted Phys. Invt. Recording");

        // [THEN] Verify Order No, Recording No and Description on Report Posted Physical Inventory Recording.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header___Order_No__', PstdPhysInvtRecordHdr."Order No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header___Recording_No__', 1);
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header__Description', PstdPhysInvtRecordHdr.Description);
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingWithoutFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPostedPhysInvtRecordingWithoutFilter()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
    begin
        // [SCENARIO] verify execution of Report Posted Phys. Invt. Recording without any  filters.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePostedPhysInvtRecordingOrderHeader(PstdPhysInvtRecordHdr, PhysInvtOrderHeader."No.");

        // [WHEN] Run report Posted Physical Inventory Recording without any filter.
        REPORT.Run(REPORT::"Posted Phys. Invt. Recording");

        // [THEN] Verify Report runs for all the Physical Inventory Order which exists in database.
        LibraryReportDataset.LoadDataSetFile();
        PstdPhysInvtRecordHdr.FindFirst();
        repeat
            LibraryReportDataset.AssertElementWithValueExists(
              'Posted_Phys__Invt__Rec__Header___Order_No__', PstdPhysInvtRecordHdr."Order No.");
        until PstdPhysInvtRecordHdr.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MakePhysInvtRecordingRequestPageHandler,MessageHandler')]
    procedure PhysInvtRecordingNotThrowAnyErrorWhenImportingTxtFile()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        FileManagement: Codeunit "File Management";
        PhysInventoryRecording: TestPage "Phys. Inventory Recording";
        InitialQty, FinalQty : Decimal;
        ServerFileName: text;
    begin
        // [SCENARIO 579922] Verify that the Physical Inventory Recording does not produce any errors when importing a .txt file
        Initialize();

        // [GIVEN] Create physical inventory order.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");

        // [GIVEN] Create a physical inventory record header via MakeNewRecordingAction from the physical inventory order page.
        PhysInvtRecordHeader := CreatePhysInvtRecordHeader(PhysInvtOrderHeader);

        // [GIEVN] Open the physical inventory recording order page and set the value.
        OpenPhysInvRecoringOrderPage(PhysInventoryRecording, PhysInvtRecordHeader);

        // [GIVEN] Set the quantity in the physical inventory recording line.
        InitialQty := LibraryRandom.RandIntInRange(10, 20);
        PhysInventoryRecording.Lines.First();
        PhysInventoryRecording.Lines.Quantity.SetValue(InitialQty);
        PhysInventoryRecording.Close();

        // [GIVEN] Export the physical inventory recording.
        ServerFileName := FileManagement.ServerTempFileName('.txt');
        ExportPhyInvtRecording(ServerFileName, PhysInvtRecordHeader);

        // [WHEN] After exporting, change the quantity in the physical inventory recording line.
        FinalQty := InitialQty + LibraryRandom.RandIntInRange(1, 10);
        PhysInventoryRecording.OpenEdit();
        PhysInventoryRecording.GoToRecord(PhysInvtRecordHeader);
        PhysInventoryRecording.Lines.First();
        PhysInventoryRecording.Lines.Quantity.SetValue(FinalQty);
        PhysInventoryRecording.Lines.Recorded.SetValue(false);
        PhysInventoryRecording.Close();

        // [THEN] Verify that the file was imported successfully.
        ImportPhyInvRecording(ServerFileName, PhysInvtRecordHeader);

        // [WHEN] Find the physical inventory recording line.
        PhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.FindFirst();

        // [THEN] After importing, verify that the quantity has also changed in the physical inventory recording line.
        Assert.AreEqual(
           InitialQty, PhysInvtRecordLine.Quantity,
           StrSubstNo(
               ValueMustBeEqualErr,
               PhysInvtRecordLine.FieldCaption(Quantity),
               InitialQty,
               PhysInvtRecordLine.TableCaption()));
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure CreatePhysInvtRecordingOrderHeader(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Description := 'Description';
        PhysInvtRecordHeader.Insert();
    end;

    local procedure CreatePostedPhysInvtRecordingOrderHeader(var PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; OrderNo: Code[20])
    begin
        PstdPhysInvtRecordHdr."Order No." := OrderNo;
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Description := 'Description';
        PstdPhysInvtRecordHdr.Insert();
    end;

    local procedure CreatePhysInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine.Validate("Item No.", Item."No.");
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInvtRecordHeader(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"): Record "Phys. Invt. Record Header";
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysicalInventoryOrder: TestPage "Physical Inventory Order";
    begin
        PhysicalInventoryOrder.OpenEdit();
        PhysicalInventoryOrder.GoToRecord(PhysInvtOrderHeader);
        Commit();
        PhysicalInventoryOrder.MakeNewRecording.Invoke();
        PhysicalInventoryOrder.Close();

        PhysInvtRecordHeader.Get(PhysInvtOrderHeader."No.", 1);
        exit(PhysInvtRecordHeader);
    end;

    local procedure OpenPhysInvRecoringOrderPage(var PhysInventoryRecording: TestPage "Phys. Inventory Recording"; PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    var
        Employee: Record Employee;
    begin
        PhysInventoryRecording.OpenEdit();
        PhysInventoryRecording.GoToRecord(PhysInvtRecordHeader);
        Employee.FindFirst();
        PhysInventoryRecording."Person Recorded".SetValue(Employee."No.");
        PhysInventoryRecording."Date Recorded".SetValue(Today());
        PhysInventoryRecording."Time Recorded".SetValue(Time());
    end;

    local procedure ExportPhyInvtRecording(ServerFileName: Text; PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    var
        ExportPhysInvtRecording: XmlPort "Export Phys. Invt. Recording";
        ExportFile: File;
        OutStream: OutStream;
    begin
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        ExportPhysInvtRecording.Set(PhysInvtRecordHeader);
        ExportPhysInvtRecording.SetDestination(OutStream);
        ExportPhysInvtRecording.TextEncoding(TextEncoding::UTF8);
        ExportPhysInvtRecording.Export();
        ExportFile.Close();
    end;

    local procedure ImportPhyInvRecording(ServerFileName: Text; PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    var
        ImportPhysInvtRecording: XmlPort "Import Phys. Invt. Recording";
        ImportFile: File;
        InStream: InStream;
    begin
        ImportFile.Open(ServerFileName);
        ImportFile.CreateInStream(InStream);
        ImportPhysInvtRecording.Set(PhysInvtRecordHeader);
        ImportPhysInvtRecording.TextEncoding(TextEncoding::UTF8);
        ImportPhysInvtRecording.SetSource(InStream);
        ImportPhysInvtRecording.Import();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingRequestPageHandler(var PhysInvtRecording: TestRequestPage "Phys. Invt. Recording")
    var
        PhysInvtRecordHeaderOrderNo: Variant;
        Status: Option Open,Finished;
    begin
        LibraryVariableStorage.Dequeue(PhysInvtRecordHeaderOrderNo);
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter("Order No.", PhysInvtRecordHeaderOrderNo);
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter("Recording No.", Format(1));
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter(Status, Format(Status::Open));
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter(Description, 'Description');
        PhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingRequestPageHandler(var PostedPhysInvtRecording: TestRequestPage "Posted Phys. Invt. Recording")
    var
        PostedPhysInvtRecHeaderOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedPhysInvtRecHeaderOrderNo);
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter("Order No.", PostedPhysInvtRecHeaderOrderNo);
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter("Recording No.", Format(1));
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter(Description, 'Description');
        PostedPhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingWithoutFilterRequestPageHandler(var PhysInvtRecording: TestRequestPage "Phys. Invt. Recording")
    begin
        PhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingWithoutFilterRequestPageHandler(var PostedPhysInvtRecording: TestRequestPage "Posted Phys. Invt. Recording")
    begin
        PostedPhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    Procedure MakePhysInvtRecordingRequestPageHandler(var MakePhysInvtRecording: TestRequestPage "Make Phys. Invt. Recording")
    var
        PhysInvtRecordHeaderOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PhysInvtRecordHeaderOrderNo);
        MakePhysInvtRecording."Phys. Invt. Order Header".SetFilter("No.", PhysInvtRecordHeaderOrderNo);
        MakePhysInvtRecording.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

