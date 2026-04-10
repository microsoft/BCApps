codeunit 137454 "Phys. Invt. Order Diff. UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [Difference] [Report]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineNewAmountPositiveStatusFinished()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate Total Amount on OnAfterGetRecord for Dataset Phys. Inventory Order Line in Phys. Invt. Order Diff. List Report for Positive Adjmt.

        // [GIVEN] Create and update Phys. Inventory Order. Create Phys. Inventory Recording.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreatePhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");
        UpdatePhysInventoryOrderStatusToFinished(PhysInvtOrderHeader);  // Update Phys. Inventory Order Status to Finished.

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Status and New Amount Positive on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInvtOrderDiffListReport('Phys__Inventory_Order_Header__Status', Format(PhysInvtOrderHeader.Status::Finished));
        VerifyPhysInvtOrderDiffListReport('NewAmountPos', PhysInvtOrderLine."Pos. Qty. (Base)" * PhysInvtOrderLine."Unit Amount");
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineNewAmountNegativeStatusFinished()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate Total Amount on OnAfterGetRecord for Dataset Phys. Inventory Order Line in Phys. Invt. Order Diff. List Report for Negative Adjmt.

        // [GIVEN] Create and update Phys. Inventory Order. Create Phys. Inventory Recording.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
        CreatePhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");
        UpdatePhysInventoryOrderStatusToFinished(PhysInvtOrderHeader);  // Update Phys. Inventory Order Status to Finished.

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Status and New Amount Negative on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInvtOrderDiffListReport('Phys__Inventory_Order_Header__Status', Format(PhysInvtOrderHeader.Status::Finished));
        VerifyPhysInvtOrderDiffListReport('NewAmountNeg', PhysInvtOrderLine."Neg. Qty. (Base)" * PhysInvtOrderLine."Unit Amount");
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineAmountPositiveStatusOpen()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate OnAfterGetRecord for Dataset Phys. Inventory Order Line in Phys. Invt. Order Diff. List Report for Positive Adjmt.

        // [GIVEN] Create and update Phys. Inventory Order. Create Phys. Inventory Recording.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreatePhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Status, Amount Positive and Quantity Positive on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInvtOrderDiffListReport('Phys__Inventory_Order_Header__Status', 'Open');
        VerifyPhysInvtOrderDiffListReport('AmountPos', PhysInvtOrderLine."Pos. Qty. (Base)" * PhysInvtOrderLine."Unit Amount");
        VerifyPhysInvtOrderDiffListReport('QtyPos', PhysInvtOrderLine."Pos. Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInventoryOrderLineAmountNegativeStatusOpen()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate OnAfterGetRecord for Dataset Phys. Inventory Order Line in Phys. Invt. Order Diff. List Report for Negative Adjmt.

        // [GIVEN] Create and update Phys. Inventory Order. Create Phys. Inventory Recording.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
        CreatePhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Status, Amount Negative and Quantity Negative on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInvtOrderDiffListReport('Phys__Inventory_Order_Header__Status', 'Open');
        VerifyPhysInvtOrderDiffListReport('AmountNeg', PhysInvtOrderLine."Neg. Qty. (Base)" * PhysInvtOrderLine."Unit Amount");
        VerifyPhysInvtOrderDiffListReport('QtyNeg', PhysInvtOrderLine."Neg. Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineDimensionLoopOnAfterGetRecordSingleDimension()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] validate the LineDimensionLoop OnAfterGetRecord of the Phys. Invt. Order Diff. List Report.

        // [GIVEN] Create Phys. Inventory Order. Update Phys. Inventory Order Line. Create and update Dimension Set Entry on Phys. Inventory Order Line.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreateDimension(DimensionSetEntry);
        PhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        PhysInvtOrderLine.Modify();

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Dimension Code and Dimension Value correctly updated on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText', StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderDiffListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineDimensionLoopOnAfterGetRecordMultipleDimensions()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        // [SCENARIO] validate the LineDimensionLoop OnAfterGetRecord of the Phys. Invt. Order Diff. List Report for else condition.

        // [GIVEN] Create Phys. Inventory Order. Update Phys. Inventory Order Line. Create and update Dimension Set Entry on Phys. Inventory Order Line.
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine, CreateItem());
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreateDimension(DimensionSetEntry);
        CreateDimensionSetEntry(
          DimensionSetEntry2, DimensionSetEntry."Dimension Set ID", LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        PhysInvtOrderLine.Modify();

        // [WHEN] Run Phys. Invt. Order Diff. List Report.
        RunPhysInvtOrderDiffListReport(PhysInvtOrderHeader);

        // [THEN] Verify the Dimension Code and Dimension Value correctly updated on Phys. Invt. Order Diff. List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText',
          StrSubstNo(
            '%1 - %2; %3 - %4',
            DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code",
            DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code"));
    end;

    local procedure CreatePhysInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemNo: Code[20])
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := ItemNo;
        PhysInvtOrderLine."Location Code" := LibraryUTUtility.GetNewCode10();
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInventoryRecording(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; OrderNo: Code[20])
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();

        PhysInvtRecordLine."Order No." := OrderNo;
        PhysInvtRecordLine."Order Line No." := 1;
        PhysInvtRecordLine.Quantity := 1;
        PhysInvtRecordLine."Quantity (Base)" := 1;
        PhysInvtRecordLine.Recorded := true;
        PhysInvtRecordLine."Serial No." := LibraryUTUtility.GetNewCode();
        PhysInvtRecordLine."Lot No." := LibraryUTUtility.GetNewCode();
        PhysInvtRecordLine.Insert();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateDimension(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();

        DimensionSetEntry2.FindLast();
        CreateDimensionSetEntry(DimensionSetEntry,
          DimensionSetEntry2."Dimension Set ID" + LibraryRandom.RandInt(10), DimensionSetEntry."Dimension Code", DimensionValue.Code);  // Should be greater than available Dimension Set ID.
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        DimensionSetEntry."Dimension Set ID" := DimensionSetID;
        DimensionSetEntry."Dimension Code" := DimensionCode;
        DimensionSetEntry."Dimension Value Code" := DimensionValueCode;
        DimensionSetEntry.Insert();
    end;

    local procedure UpdatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; EntryType: Option)
    begin
        PhysInvtOrderLine."Entry Type" := EntryType;
        PhysInvtOrderLine."Unit Amount" := 1;
        PhysInvtOrderLine."Quantity (Base)" := 1;
        PhysInvtOrderLine."Neg. Qty. (Base)" := 1;
        PhysInvtOrderLine."Pos. Qty. (Base)" := 1;
        PhysInvtOrderLine."Use Item Tracking" := true;
        PhysInvtOrderLine.Modify();
    end;

    local procedure UpdatePhysInventoryOrderStatusToFinished(PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Finished;
        PhysInvtOrderHeader.Modify();
    end;

    local procedure RunPhysInvtOrderDiffListReport(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    var
        PhysInvtOrderDiffList: Report "Phys. Invt. Order Diff. List";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderDiffList.SetTableView(PhysInvtOrderHeader);
        PhysInvtOrderDiffList.Run();  // Invokes PhysInvtOrderDiffListReportHandler.
        Clear(PhysInvtOrderDiffList);
    end;

    local procedure VerifyPhysInvtOrderDiffListReport(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderDiffListReportHandler(var PhysInvtOrderDiffList: TestRequestPage "Phys. Invt. Order Diff. List")
    begin
        PhysInvtOrderDiffList.ShowDimensions.SetValue(true);
        PhysInvtOrderDiffList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

