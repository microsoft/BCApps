codeunit 137450 "Phys. Invt. Order TAB UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        PhyInvtCommentLineExistMsg: Label 'Physical Inventory Comment Line exists.';
        PostedPhysInvtOrderLineExistMsg: Label 'Posted Physical Inventory Order Line exists.';
        PhysInvtRecordingHeaderExistMsg: Label 'Physical Inventory Recording Header exists.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePostedPhysInvtRecHeader()
    var
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate Trigger OnDelete for Table Pstd. Phys. Invt. Rec. Header.
        // [GIVEN] Create Posted Physical Inventory Recording Header with Recording Line and Physical Inventory Comment Line.
        PstdPhysInvtRecordHdr."Order No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Insert();

        PstdPhysInvtRecordLine."Order No." := PstdPhysInvtRecordHdr."Order No.";
        PstdPhysInvtRecordLine."Recording No." := PstdPhysInvtRecordHdr."Recording No.";
        PstdPhysInvtRecordLine."Line No." := 1;
        PstdPhysInvtRecordLine.Insert();
        CreatePhysInvtCommentLine(
          PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::"Posted Recording", PstdPhysInvtRecordHdr."Order No.",
          PstdPhysInvtRecordHdr."Recording No.");

        // Exercise.
        PstdPhysInvtRecordHdr.Delete(true);

        // [THEN] Verify Posted Physical Inventory Recording Header, Posted Physical Inventory Recording Line and Physical Inventory Comment Line deleted.
        Assert.IsFalse(
          PstdPhysInvtRecordHdr.Get(PstdPhysInvtRecordHdr."Order No.", PstdPhysInvtRecordHdr."Recording No."),
          'Posted Physical Inventory Recording Header exists.');
        Assert.IsFalse(
          PhysInvtCommentLine.Get(
            PhysInvtCommentLine."Document Type"::"Posted Recording", PhysInvtCommentLine."Order No.",
            PhysInvtCommentLine."Recording No.", PhysInvtCommentLine."Line No."),
          PhyInvtCommentLineExistMsg);
        Assert.IsFalse(
          PstdPhysInvtRecordLine.Get(
            PstdPhysInvtRecordLine."Order No.", PstdPhysInvtRecordLine."Recording No.", PstdPhysInvtRecordLine."Line No."),
          'Posted Physical Inventory Recording Line exists.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePostedPhysInvtOrderHeader()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Trigger OnDelete for Table Pstd. Phys. Invt. Order Header.
        // [GIVEN] Create Posted Physical Inventory Order Header with Order Line and Physical Inventory Comment Line.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");
        CreatePhysInvtCommentLine(
          PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::"Posted Order", PstdPhysInvtOrderHdr."No.", 0);  // Recording No as Zero.

        // Exercise.
        PstdPhysInvtOrderHdr.Delete(true);

        // [THEN] Verify Posted Physical Inventory Order Header, Posted Physical Inventory Order Line and Physical Inventory Comment Line deleted.
        Assert.IsFalse(
          PstdPhysInvtOrderHdr.Get(PstdPhysInvtOrderHdr."No."), 'Posted Physical Inventory Order Header exists.');
        Assert.IsFalse(
          PhysInvtCommentLine.Get(
            PhysInvtCommentLine."Document Type"::"Posted Order", PhysInvtCommentLine."Order No.",
            PhysInvtCommentLine."Recording No.", PhysInvtCommentLine."Line No."),
          PhyInvtCommentLineExistMsg);
        Assert.IsFalse(
          PstdPhysInvtOrderLine.Get(PstdPhysInvtOrderLine."Document No.", PstdPhysInvtOrderLine."Line No."),
          PostedPhysInvtOrderLineExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigatePostedPhysInvtOrderHeader()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        DocumentEntry: Record "Document Entry";
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] validate Function Navigate for Table Pstd. Phys. Invt. Order Header.
        // [GIVEN] Create Posted Physical Inventory Order Header.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);

        // Exercise.
        Navigate.Trap();
        PstdPhysInvtOrderHdr.Navigate();

        // [THEN] Verify Table Name on Navigate Page.
        Navigate."Table Name".AssertEquals(CopyStr(PstdPhysInvtOrderHdr.TableCaption(), 1, MaxStrLen(DocumentEntry."Table Name")));
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDimensionsPostedPhysInvtOrderHeader()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        // [SCENARIO] validate Function ShowDimensions for Table Pstd. Phys. Invt. Order Header.
        // [GIVEN] Create Posted Physical Inventory Order Header.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);

        // Exercise.
        PstdPhysInvtOrderHdr.ShowDimensions();

        // [THEN] Verify Dimension Set Entries Page Open. Added Page Handler DimensionSetEntriesModalPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeletePostedPhysInvtOrderLine()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
    begin
        // [SCENARIO] validate Trigger OnDelete for Table Pstd. Phys. Invt. Order Line.
        // [GIVEN] Create Posted Physical Inventory Order Line and Posted Expect Physical Inventory Tracking Line.
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        PstdExpInvtOrderTracking."Order No" := PstdPhysInvtOrderLine."Document No.";
        PstdExpInvtOrderTracking."Order Line No." := PstdPhysInvtOrderLine."Line No.";
        PstdExpInvtOrderTracking.Insert();

        // Exercise.
        PstdPhysInvtOrderLine.Delete(true);

        // [THEN] Verify Posted Physical Inventory Order Line and Posted Expect Physical Inventory Tracking Line deleted.
        Assert.IsFalse(
          PstdPhysInvtOrderLine.Get(PstdPhysInvtOrderLine."Document No.", PstdPhysInvtOrderLine."Line No."),
          PostedPhysInvtOrderLineExistMsg);
        Assert.IsFalse(
            PstdExpInvtOrderTracking.Get(
                PstdExpInvtOrderTracking."Order No", PstdExpInvtOrderTracking."Order Line No.",
                PstdExpInvtOrderTracking."Serial No.", PstdExpInvtOrderTracking."Lot No.", PstdExpInvtOrderTracking."Package No."),
               'Posted Expect Physical Inventory Tracking Line exists.');
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDimensionsPostedPhysInvtOrderLine()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function ShowDimensions for Table Pstd. Phys. Invt. Order Line.
        // [GIVEN] Create Posted Physical Inventory Order Line.
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        PstdPhysInvtOrderLine.ShowDimensions();

        // [THEN] Verify Dimension Set Entries Page Open. Added Page Handler DimensionSetEntriesModalPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyLinePostedPhysInvtOrderLine()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function EmptyLine for Table Pstd. Phys. Invt. Order Line.
        // Exercise and Verify: Verify EmptyLine Function return True value.
        Assert.IsTrue(PstdPhysInvtOrderLine.EmptyLine(), 'Posted Physical Inventory Order Line must be empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyLineWithLinePostedPhysInvtOrderLine()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function EmptyLine for Table Pstd. Phys. Invt. Order Line.
        // Setup.
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise and Verify: Verify EmptyLine Function return False Value.
        Assert.IsFalse(PstdPhysInvtOrderLine.EmptyLine(), 'Posted Physical Inventory Order Line must not be empty.');
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecLinesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowPostPhysInvtRecordingLinesPostedPhysInvtOrderLine()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function ShowPostPhysInvtRecordingLines for Table Pstd. Phys. Invt. Order Line.
        // Setup.
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        PstdPhysInvtOrderLine.ShowPostPhysInvtRecordingLines();

        // [THEN] Verify Posted Physical Inventory Recording Lines Page Open. Added Page Handler PstdPhysInvtRecordLinesModalPageHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUpNewLinePhysInventoryCommentLine()
    var
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        // [SCENARIO] validate Function SetUpNewLine for Table Phys. Inventory Comment Line.
        // Exercise.
        PhysInvtCommentLine.SetUpNewLine();

        // [THEN] Verify Date on Physical Inventory Comment Line.
        PhysInvtCommentLine.TestField(Date, WorkDate());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPhysInventoryOrderHeaderError()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        // [SCENARIO] validate Trigger OnInsert for Table Phys. Inventory Order Header.
        // [GIVEN] Create Posted Physical Inventory Header and assign posted No to Physical Inventory Order Header.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        PhysInvtOrderHeader."No." := PstdPhysInvtOrderHdr."No.";

        // Exercise.
        asserterror PhysInvtOrderHeader.Insert(true);

        // [THEN] Verify Error Code, Error Msg - Nos already exists.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePhysInventoryOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        // [SCENARIO] validate Trigger OnDelete for Table Phys. Inventory Order Header.
        // [GIVEN] Create Physical Inventory Order Header with Line, Physical Inventory Recording Header and Physical Inventory Comment Line for Order.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");
        CreatePhysInvtRecordingHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        CreatePhysInvtCommentLine(PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::Order, PhysInvtOrderHeader."No.", 0);  // Recording No as Zero.

        // Exercise.
        PhysInvtOrderHeader.Delete(true);

        // [THEN] Verify Physical Inventory Order Header, Physical Inventory Order Line, Physical Inventory Recording Header and Physical Inventory Comment Line deleted.
        Assert.IsFalse(
          PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No."), 'Physical Inventory Order Header exists.');
        Assert.IsFalse(
          PhysInvtOrderLine.Get(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No."), 'Physical Inventory Order Line exists.');
        Assert.IsFalse(
          PhysInvtRecordHeader.Get(PhysInvtRecordHeader."Order No.", PhysInvtRecordHeader."Recording No."),
          PhysInvtRecordingHeaderExistMsg);
        Assert.IsFalse(
          PhysInvtCommentLine.Get(
            PhysInvtCommentLine."Document Type"::Order, PhysInvtCommentLine."Order No.",
            PhysInvtCommentLine."Recording No.", PhysInvtCommentLine."Line No."),
          PhyInvtCommentLineExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenamePhysInventoryOrderHeaderError()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] validate Trigger OnRename for Table Phys. Inventory Order Header.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // Exercise.
        asserterror PhysInvtOrderHeader.Rename(LibraryUTUtility.GetNewCode());

        // [THEN] Verify Error Code, Error Msg - You cannot rename a Phys. Inventory Order Header.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PhysInvOrderLinesExistPhysInventoryOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function PhysInvOrderLinesExist for Table Phys. Inventory Order Header.
        // [GIVEN] Create Physical Inventory Order Header and Physical Inventory Order Line.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");

        // Exercise and Verify: Verify Function PhysInvOrderLinesExist return True value.
        Assert.IsTrue(PhysInvtOrderHeader.PhysInvtOrderLinesExist(), 'Physical Inventory Order Line must exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoOnValidatePhysInventoryOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
    begin
        // [SCENARIO] validate Trigger OnValidate of No. for TablePhys. Inventory Order Header.
        // [GIVEN] Update No. Series for Manual Nos. as True.
        InventorySetup.Get();
        NoSeries.Get(InventorySetup."Phys. Invt. Order Nos.");
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();

        // Exercise.
        PhysInvtOrderHeader.Validate("No.", LibraryUTUtility.GetNewCode());
        PhysInvtOrderHeader.Insert();

        // [THEN] Verify No. Series on Physical Inventory Order Header.
        PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No.");
        PhysInvtOrderHeader.TestField("No. Series", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFALSE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingDateOnValidateFalsePhysInventoryOrderHeader()
    begin
        // [SCENARIO] validate Trigger OnValidate of Posting Date for Table Phys. Inventory Order Header.
        // Setup.
        PostingDateOnValidatePhysInventoryOrderHeader(false);  // Confirm as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingDateOnValidateTruePhysInventoryOrderHeader()
    begin
        // [SCENARIO] validate Trigger OnValidate of Posting Date for Table Phys. Inventory Order Header.
        // Setup.
        PostingDateOnValidatePhysInventoryOrderHeader(true);  // Confirm as True.
    end;

    local procedure PostingDateOnValidatePhysInventoryOrderHeader(Confirm: Boolean)
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // Create Physical Inventory Order Header and Physical Inventory Order Line.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");

        PhysInvtOrderLine."Item No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderLine."Qty. Exp. Calculated" := true;
        PhysInvtOrderLine.Modify();

        // Exercise.
        PhysInvtOrderHeader.Validate("Posting Date", WorkDate());
        PhysInvtOrderHeader.Modify();

        // [THEN] Verify Qty. Exp. Calculated on Physical Inventory Order Line and Posting Date on Physical Inventory Order Header.
        PhysInvtOrderLine.Get(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");
        PhysInvtOrderLine.TestField("Qty. Exp. Calculated", not Confirm);
        if Confirm then
            PhysInvtOrderHeader.TestField("Posting Date", WorkDate())
        else
            PhysInvtOrderHeader.TestField("Posting Date", 0D);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BinCodeOnValidatePhysInventoryOrderHeaderError()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        Bin: Record Bin;
    begin
        // [SCENARIO] validate Trigger OnValidate of Bin Code for Table Phys. Inventory Order Header.
        // [GIVEN] Create Location, Bin and Physical Inventory Order Header.
        CreateLocationAndBin(Bin);
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader."Location Code" := Bin."Location Code";

        // Exercise.
        asserterror PhysInvtOrderHeader.Validate("Bin Code", Bin.Code);

        // [THEN] Verify Error Code. Error Msg - Directed Put-away and Pick must be equal to 'No'  in Location.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShortcutDim1OnValidatePhysInvtOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] validate Trigger OnValidate of Shortcut Dimension 1 Code for Table Phys. Inventory Order Header.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // Exercise.
        PhysInvtOrderHeader.Validate("Shortcut Dimension 1 Code", SelectDimensionValue(1));

        // [THEN] Verify Dimension Set ID.
        PhysInvtOrderHeader.TestField("Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShortcutDim2OnValidatePhysInvtOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Trigger OnValidate of Shortcut Dimension 2 Code for Table Phys. Inventory Order Header.
        // [GIVEN] Create Physical Inventory Order Header with Line.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");

        // Exercise.
        PhysInvtOrderHeader.Validate("Shortcut Dimension 2 Code", SelectDimensionValue(2));

        // [THEN] Verify Dimension Set ID.
        PhysInvtOrderHeader.TestField("Dimension Set ID");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingNoSeriesOnValidatePhysInventoryOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO] validate Trigger OnValidate of Posting No. Series for Table Phys. Inventory Order Header.
        // Setup.
        InventorySetup.Get();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // Exercise.
        PhysInvtOrderHeader.Validate("Posting No. Series", InventorySetup."Posted Phys. Invt. Order Nos.");
        PhysInvtOrderHeader.Modify();

        // [THEN] Verify Posting No on Physical Inventory Order Header.
        PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No.");
        PhysInvtOrderHeader.TestField("Posting No.", '');
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AssistEditPhysInventoryOrderHeader()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] validate Function AssistEdit for Table Phys. Inventory Order Header.
        // Exercise and Verify: Verify Function AssistEdit return True value.
        Assert.IsTrue(PhysInvtOrderHeader.AssistEdit(PhysInvtOrderHeader), 'Value must be True');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenamePhysInventoryRecordingHeaderError()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        // [SCENARIO] validate function OnRename of Table Physical Inventory Recording Header.
        // Setup.
        CreatePhysInvtRecordingHeader(PhysInvtRecordHeader, LibraryUTUtility.GetNewCode());

        // [WHEN] Rename Physical Inventory Recording Header.
        asserterror PhysInvtRecordHeader.Rename(LibraryUTUtility.GetNewCode(), PhysInvtRecordHeader."Recording No.");

        // [THEN] Verify error code, Error Msg - Physical Inventory Recording Header cannot be renamed.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePhysInventoryRecordingHeader()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        // [SCENARIO] validate function OnDelete of Table Physical Inventory Recording Header.
        // Setup.
        CreatePhysInvtRecordingHeader(PhysInvtRecordHeader, LibraryUTUtility.GetNewCode());
        CreatePhysInvtRecordingLine(PhysInvtRecordLine, PhysInvtRecordHeader."Order No.", 1, 1);  // Recording No and Line No respectively.
        CreatePhysInvtCommentLine(
          PhysInvtCommentLine, PhysInvtCommentLine."Document Type"::Recording, PhysInvtRecordHeader."Order No.", 1);  // Recording No as 1.

        // Exercise.
        PhysInvtRecordHeader.Delete(true);

        // [THEN] Verify Physical Inventory Recording Header, Physical Inventory Recording Line and Physical Inventory Comment Line deleted.
        Assert.IsFalse(
          PhysInvtRecordHeader.Get(
            PhysInvtRecordHeader."Order No.", PhysInvtRecordHeader."Recording No."), PhysInvtRecordingHeaderExistMsg);
        Assert.IsFalse(
          PhysInvtRecordLine.Get(PhysInvtRecordLine."Order No.", PhysInvtRecordLine."Recording No.", PhysInvtRecordLine."Line No."),
          'Physical Inventory Recording Line exists.');
        Assert.IsFalse(
          PhysInvtCommentLine.Get(
            PhysInvtCommentLine."Document Type"::Recording, PhysInvtCommentLine."Order No.",
            PhysInvtCommentLine."Recording No.", PhysInvtCommentLine."Line No."),
          PhyInvtCommentLineExistMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BinCodeOnValidatePhysInventoryRecordingHeaderError()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        Bin: Record Bin;
    begin
        // [SCENARIO] validate function OnValidate of Bin Code of Table Physical Inventory Recording Header.

        // [GIVEN] Create Location, Bin and Physical Inventory Recording Header.
        CreateLocationAndBin(Bin);
        CreatePhysInvtRecordingHeader(PhysInvtRecordHeader, LibraryUTUtility.GetNewCode());
        PhysInvtRecordHeader."Location Code" := Bin."Location Code";

        // Exercise.
        asserterror PhysInvtRecordHeader.Validate("Bin Code", Bin.Code);

        // [THEN] Verify Error Code. Error Msg - Directed Put-away and Pick must be equal to No on Location.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenamePhysInvtRecordingLineError()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate function OnRename trigger of Table Physical Inventory Recording Line.
        // Setup.
        CreatePhysInvtRecordingLine(PhysInvtRecordLine, LibraryUTUtility.GetNewCode(), 1, 1);  // Recording No and Line No respectively.

        // [WHEN] Rename Physical Inventory Recording Line.
        asserterror PhysInvtRecordLine.Rename(LibraryUTUtility.GetNewCode(), 1, 1);  // Recording No and Line No respectively.

        // [THEN] Verify error code, Error Msg - Physical Inventory Recording Line cannot be renamed.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckSerialNoPhysInvtRecordingLineError()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtRecordLine2: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate function CheckSerialNo of Table Physical Inventory Recording Line.

        // [GIVEN] Create two Physical Inventory Recording Lines with same Serial No.
        CreatePhysInvtRecordingLine(PhysInvtRecordLine, LibraryUTUtility.GetNewCode(), 1, 1);  // Recording No and Line No respectively.
        UpdateTrackingPhysInvtRecordingLine(PhysInvtRecordLine, LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());

        CreatePhysInvtRecordingLine(PhysInvtRecordLine2, PhysInvtRecordLine."Order No.", 1, 2);  // Recording No and Line No respectively.
        UpdateTrackingPhysInvtRecordingLine(PhysInvtRecordLine2, PhysInvtRecordLine."Item No.", PhysInvtRecordLine."Serial No.");

        // Exercise.
        asserterror PhysInvtRecordLine2.CheckSerialNo();

        // [THEN] Verify error code, Error Msg - Serial No. for item already exists.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure CreatePhysInvtCommentLine(var PhysInvtCommentLine: Record "Phys. Invt. Comment Line"; DocumentType: Option; OrderNo: Code[20]; RecordingNo: Integer)
    begin
        PhysInvtCommentLine."Document Type" := DocumentType;
        PhysInvtCommentLine."Order No." := OrderNo;
        PhysInvtCommentLine."Recording No." := RecordingNo;
        PhysInvtCommentLine."Line No." := 1;
        PhysInvtCommentLine.Insert();
    end;

    local procedure CreatePostedPhysInvtOrderHeader(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr")
    begin
        PstdPhysInvtOrderHdr."No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderHdr.Insert();
    end;

    local procedure CreatePostedPhysInvtOrderLine(var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PstdPhysInvtOrderLine."Document No." := DocumentNo;
        PstdPhysInvtOrderLine."Line No." := 1;
        PstdPhysInvtOrderLine."Item No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure CreatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PhysInvtOrderLine."Document No." := DocumentNo;
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreateLocationAndBin(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        // Create Location.
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location."Bin Mandatory" := true;
        Location."Directed Put-away and Pick" := true;
        Location.Insert();

        // Create Bin.
        Bin."Location Code" := Location.Code;
        Bin.Code := LibraryUTUtility.GetNewCode();
        Bin.Insert();
    end;

    local procedure CreatePhysInvtRecordingHeader(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();
    end;

    local procedure CreatePhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; OrderNo: Code[20]; RecordingNo: Integer; LineNo: Integer)
    begin
        PhysInvtRecordLine."Order No." := OrderNo;
        PhysInvtRecordLine."Recording No." := RecordingNo;
        PhysInvtRecordLine."Line No." := LineNo;
        PhysInvtRecordLine.Insert();
    end;

    local procedure SelectDimensionValue(GlobalDimensionNo: Integer): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Global Dimension No.", GlobalDimensionNo);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindFirst();
        exit(DimensionValue.Code);
    end;

    local procedure UpdateTrackingPhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20]; SerialNo: Code[50])
    begin
        PhysInvtRecordLine."Item No." := ItemNo;
        PhysInvtRecordLine."Serial No." := SerialNo;
        PhysInvtRecordLine."Quantity (Base)" := 1;
        PhysInvtRecordLine.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesModalPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecLinesModalPageHandler(var PostedPhysInvtRecLines: TestPage "Posted Phys. Invt. Rec. Lines")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFALSE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

