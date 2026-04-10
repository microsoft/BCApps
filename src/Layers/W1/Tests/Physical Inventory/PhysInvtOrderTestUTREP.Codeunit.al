codeunit 137453 "Phys. Invt. Order-Test UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [Report]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        ValueSpecifiedWarningTxt: Label '%1 must be specified.';
        AllowedRangeWarningTxt: Label '%1 is not within your allowed range of posting dates.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderHeaderWarning()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset PhysInvtOrderHeader - Report 5005352 - Phys. Invt. Order - Test.
        // [GIVEN] Create Physical Inventory Order Header with Status Open.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Open;
        PhysInvtOrderHeader."Posting Date" := 0D;
        PhysInvtOrderHeader."No. Series" := LibraryUTUtility.GetNewCode10();
        PhysInvtOrderHeader.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Warning for Status, Posting Date, Posting No. Series on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', 'Status must be Finished.');
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number_', StrSubstNo(ValueSpecifiedWarningTxt, PhysInvtOrderHeader.FieldCaption("Posting Date")));
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number_', StrSubstNo(ValueSpecifiedWarningTxt, PhysInvtOrderHeader.FieldCaption("Posting No. Series")));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderHeaderAllowPostingFromWarning()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset PhysInvtOrderHeader - Report 5005352 - Phys. Invt. Order - Test.
        // [GIVEN] Update User Setup with Allow Posting From, Create Physical Inventory Order Header with Posting Date less than Allow Posting From.
        Initialize();
        UserSetup."User ID" := UserId;
        UserSetup."Allow Posting From" := CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        UserSetup.Insert();

        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader."Posting Date" := WorkDate();
        PhysInvtOrderHeader.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Warning for Posting Date range on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number_', StrSubstNo(AllowedRangeWarningTxt, PhysInvtOrderHeader.FieldCaption("Posting Date")));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderHeaderAllowPostingToWarning()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset PhysInvtOrderHeader - Report 5005352 - Phys. Invt. Order - Test.
        // [GIVEN] Update User Setup with Allow Posting To, Create Physical Inventory Order Header with Posting Date more than Allow Posting To.
        Initialize();
        UserSetup."User ID" := UserId;
        UserSetup."Allow Posting To" := WorkDate();
        UserSetup.Insert();

        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader."Posting Date" :=
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', UserSetup."Allow Posting To");
        PhysInvtOrderHeader.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Warning for Posting Date range on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number_', StrSubstNo(AllowedRangeWarningTxt, PhysInvtOrderHeader.FieldCaption("Posting Date")));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineWarning()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Item: Record Item;
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset Phys. Inventory Order Line - Report 5005352 - Phys. Invt. Order - Test.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryUTUtility.GetNewCode());
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Warning for Qty. Expected Calculated, On Recording Lines, General Product Posting Group, Inventory Posting Group and Item on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control41', 'Qty. Exp. Calculated must be Yes.');
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control41', 'On Recording Lines must be Yes.');
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number__Control41', StrSubstNo(ValueSpecifiedWarningTxt, PhysInvtOrderLine.FieldCaption("Gen. Prod. Posting Group")));
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number__Control41', StrSubstNo(ValueSpecifiedWarningTxt, PhysInvtOrderLine.FieldCaption("Inventory Posting Group")));
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number__Control41', StrSubstNo('%1 %2 does not exist.', Item.TableCaption(), PhysInvtOrderLine."Item No."));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineItemBlockedWarning()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset Phys. Inventory Order Line - Report 5005352 - Phys. Invt. Order - Test.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", CreateBlockedItem());
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Warning for Blocked Item on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'ErrorText_Number__Control41', StrSubstNo('Blocked must be No for Item %1.', PhysInvtOrderLine."Item No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnAfterGetRecordPhysInventoryOrderLineItemVariantBlockedWarning()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        RequestPageXML: Text;
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset Phys. Inventory Order Line - Report 5005352 - Phys. Invt. Order - Test.
        Initialize();

        // [GIVEN] Blocked Item Variant exists
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItem(Item));
        ItemVariant.Blocked := true;
        ItemVariant.Modify();

        // [GIVEN] Phys. Invt. Order with blocked item variant exists
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine."Variant Code" := ItemVariant.Code;
        PhysInvtOrderLine.Modify();

        // [WHEN] Report "Phys. Invt. Order - Test" is run
        PhysInvtOrderHeader.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::"Phys. Invt. Order - Test", PhysInvtOrderHeader, RequestPageXML);

        // [THEN] Verify Warning for Blocked Item Variant on Report Phys. Invt. Order - Test.
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number__Control41', StrSubstNo('Blocked must be No for Item Variant %1 %2.', PhysInvtOrderLine."Item No.", PhysInvtOrderLine."Variant Code"));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestWithFiltersRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInvtOrderHeaderForLocationStatus()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        LocationCode: Code[10];
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for Dataset PhysInvtOrderHeader - Report 5005352 - Phys. Invt. Order - Test.
        // [GIVEN] Create Physical Inventory Order Header and Line with Location.
        Initialize();
        LocationCode := LibraryUTUtility.GetNewCode10();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader."Location Code" := LocationCode;
        PhysInvtOrderHeader.Modify();

        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."Location Code" := LocationCode;
        PhysInvtOrderLine.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestWithFiltersRequestPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Location Code");  // Required inside for PhysInvtOrderTestWithFiltersRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify Location Code and Status on Report Phys. Invt. Order - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Inventory_Order_Line__Location_Code_', PhysInvtOrderHeader."Location Code");
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Inventory_Order_Header__Status', Format(PhysInvtOrderHeader.Status));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineDimLoop()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for DataItem LineDimensionLoop - Report 5005352 - Phys. Invt. Order - Test.
        // Setup.
        Initialize();
        DimensionSetEntry.FindLast();
        CreateDimensionSetEntry(DimensionSetEntry2, DimensionSetEntry."Dimension Set ID" + LibraryRandom.RandInt(10));  // Value required for non existing Dimension Set Entry.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", CreateBlockedItem());
        PhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry2."Dimension Set ID";
        PhysInvtOrderLine.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify DimText on Report Phys. Invt. Order - Test for newly created Dimension Set ID.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText', StrSubstNo('%1 - %2', DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineDimLoopWithOldDimSetID()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
        DimensionSetEntry3: Record "Dimension Set Entry";
        DimensionSetID: Integer;
    begin
        // [SCENARIO] validate Function OnAfterGetRecord for DataItem LineDimensionLoop - Report 5005352 - Phys. Invt. Order - Test.
        // Setup.
        Initialize();
        DimensionSetEntry.FindLast();
        DimensionSetID := DimensionSetEntry."Dimension Set ID" + LibraryRandom.RandInt(10);  // Value required for non existing Dimension Set Entry.
        CreateDimensionSetEntry(DimensionSetEntry2, DimensionSetID);
        CreateDimensionSetEntry(DimensionSetEntry3, DimensionSetID);

        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", CreateBlockedItem());
        PhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry3."Dimension Set ID";
        PhysInvtOrderLine.Modify();
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside PhysInvtOrderTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Order - Test");

        // [THEN] Verify DimText on Report Phys. Invt. Order - Test for existing Dimension Set ID.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText',
          StrSubstNo('%1 - %2; %3 - %4',
            DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code",
            DimensionSetEntry3."Dimension Code", DimensionSetEntry3."Dimension Value Code"));
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure CreatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        PhysInvtOrderLine."Document No." := DocumentNo;
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := ItemNo;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreateBlockedItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Blocked := true;
        Item.Insert();
        exit(Item."No.")
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer)
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();

        DimensionSetEntry."Dimension Set ID" := DimensionSetID;
        DimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderTestRequestPageHandler(var PhysInvtOrderTest: TestRequestPage "Phys. Invt. Order - Test")
    var
        PhysInvtOrderHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PhysInvtOrderHeaderNo);
        PhysInvtOrderTest."Phys. Invt. Order Header".SetFilter("No.", PhysInvtOrderHeaderNo);
        PhysInvtOrderTest.ShowDimensions.SetValue(true);
        PhysInvtOrderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderTestWithFiltersRequestPageHandler(var PhysInvtOrderTest: TestRequestPage "Phys. Invt. Order - Test")
    var
        PhysInvtOrderHeaderNo: Variant;
        LocationCode: Variant;
        Status: Option Open,Finished;
    begin
        LibraryVariableStorage.Dequeue(PhysInvtOrderHeaderNo);
        LibraryVariableStorage.Dequeue(LocationCode);
        PhysInvtOrderTest."Phys. Invt. Order Header".SetFilter("No.", PhysInvtOrderHeaderNo);
        PhysInvtOrderTest."Phys. Invt. Order Header".SetFilter("Location Code", LocationCode);
        PhysInvtOrderTest."Phys. Invt. Order Header".SetFilter(Status, Format(Status::Open));
        PhysInvtOrderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

