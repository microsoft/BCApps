codeunit 134416 "ERM Purch. Cr. Memo Aggr. UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Purchase] [Credit Memo]
        IsInitialized := false;
    end;

    var
        DummyPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PurchCalcDiscountByType: Codeunit "Purch - Calc Disc. By Type";
        APIMockEvents: Codeunit "API Mock Events";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        AllowPostedDocumentDeletionDate: Date;
        ChangeConfirmMsg: Label 'Do you want';
        CalculateInvoiceDiscountQst: Label 'Do you want to calculate the invoice discount?';
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Purch. Cr. Memo Aggr. UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Purch. Cr. Memo Aggr. UT");

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        AllowPostedDocumentDeletionDate := LibraryERM.GetDeletionBlockedAfterDate();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        DisableWarningOnClosingCrMemo();

        Commit();

        BindSubscription(APIMockEvents);
        APIMockEvents.SetIsAPIEnabled(true);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Purch. Cr. Memo Aggr. UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageNoDiscount(PurchaseCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(PurchaseCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(PurchaseCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmtTest()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CrMemoDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();
        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(PurchaseCreditMemo);
        CrMemoDiscountAmount :=
          LibraryRandom.RandDecInDecimalRange(1, PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal() / 2, 1);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        PurchaseLine."Recalculate Invoice Disc." := true;
        PurchaseLine.Modify();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseCreditMemo."No.".Value);
        PurchaseCreditMemo.Close();

        // Execute
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(CrMemoDiscountAmount);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesTotalsKeepsCrMemoDiscTypeAmount()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CrMemoDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(PurchaseCreditMemo);
        CrMemoDiscountAmount := PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal();

        // Execute
        CreateLineThroughTestPage(PurchaseCreditMemo, PurchaseCreditMemo.PurchLines."No.".Value);

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(CrMemoDiscountAmount);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageNoDiscount(PurchaseCreditMemo);

        // Execute
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(PurchaseCreditMemo.PurchLines.Quantity.AsDecimal() * 2);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(PurchaseCreditMemo);

        // Execute
        PurchaseCreditMemo.PurchLines."Line Amount".SetValue(Round(PurchaseCreditMemo.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(PurchaseCreditMemo);

        // Execute
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(PurchaseCreditMemo.PurchLines."Direct Unit Cost".AsDecimal() * 2);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesTotalsKeepsCrMemoDiscTypeAmount()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(PurchaseCreditMemo);

        // Execute
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(PurchaseCreditMemo.PurchLines."Direct Unit Cost".AsDecimal() * 2);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineUpdatesTotalsNoDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // Execute
        PurchaseLine.Delete(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");

        // Execute last
        PurchaseLine.FindLast();
        PurchaseLine.Delete(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsNoDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // Execute
        PurchaseLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsDiscountPct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountPct(PurchaseHeader, PurchaseLine);

        // Execute
        PurchaseLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsDiscountAmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountAmt(PurchaseHeader, PurchaseLine);

        // Execute
        PurchaseLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingBuyFromVendorRecalculatesForCrMemoDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NewVendorDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Vendor);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);
        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);

        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        PurchaseCreditMemo."Buy-from Vendor No.".SetValue(NewVendor."No.");

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingBuyFromVendorSetsDiscountToZeroForCrMemoDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CrMemoDiscountAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Vendor, CrMemoDiscountAmount);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        // Execute
        AnswerYesToAllConfirmDialogs();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor."No.");

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingBuyFromVendorToVendorWithoutDiscountsSetDiscountAndVendorDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Vendor);
        CreateVendor(NewVendor);

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor."No.");

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderRecalculatesForCrMemoDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NewVendorDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Vendor);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        PurchaseCreditMemo."Pay-to Name".SetValue(NewVendor.Name);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderSetsDiscountToZeroForCrMemoDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CrMemoDiscountAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Vendor, CrMemoDiscountAmount);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        AnswerYesToAllConfirmDialogs();

        // Execute
        PurchaseCreditMemo."Pay-to Name".SetValue(NewVendor.Name);

        // Verify
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseCrMemoWithDiscountAmount()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedCrMemoDiscountTypeAmt(PurchCrMemoHdr);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(PurchCrMemoHdr."No.", DummyPurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseCrMemoTransfersId()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");

        // Execute
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // Verify
        Assert.IsFalse(PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false), 'Draft Aggregated Credit Memo still exists');

        Assert.AreEqual(PurchaseHeader.SystemId, PurchCrMemoHdr."Draft Cr. Memo SystemId", 'Posted Credit Memo ID is incorrect');
        Assert.IsFalse(PurchaseHeader.Find(), 'Draft Credit Memo still exists');
        PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true);
        Assert.IsFalse(IsNullGuid(PurchCrMemoEntityBuffer.Id), 'Id cannot be null');
        Assert.AreEqual(PurchCrMemoHdr."Draft Cr. Memo SystemId", PurchCrMemoEntityBuffer.Id, 'Aggregate Credit Memo ID is incorrect');

        VerifyBufferTableIsUpdatedForPostedCrMemo(PurchCrMemoHdr."No.", PurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingPostedCrMemoThroughCodeTransfersId()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        ExpectedGUID: Guid;
        TempGUID: Guid;
    begin
        // Setup
        Initialize();
        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");

        TempGUID := CreateGuid();
        PurchCrMemoHdr.TransferFields(PurchaseHeader, true);
        PurchCrMemoHdr."Pre-Assigned No." := PurchaseHeader."No.";
        PurchCrMemoHdr.Insert(true);

        // Execute
        PurchaseHeader.Delete(true);

        // Verify
        Assert.IsFalse(PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false), 'Draft Aggregated Credit Memo still exists');

        PurchCrMemoHdr.Find();
        Assert.AreEqual(PurchaseHeader.SystemId, PurchCrMemoHdr."Draft Cr. Memo SystemId", 'Posted Credit Memo ID is incorrect');
        Assert.IsFalse(PurchaseHeader.Find(), 'Draft Credit Memo still exists');
        PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true);
        Assert.IsFalse(IsNullGuid(PurchCrMemoEntityBuffer.Id), 'Id cannot be null');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseCrMemoWithDiscountPrecentage()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedCrMemoDiscountTypePct(PurchCrMemoHdr);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(PurchCrMemoHdr."No.", DummyPurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(PurchaseHeader);

        // Execute
        PurchaseHeader.Delete(true);

        // Verify
        Assert.IsFalse(PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        // Setup
        Initialize();
        CreatePostedCrMemoDiscountTypeAmt(PurchCrMemoHdr);

        // Execute
        PurchCrMemoHdr.Delete();

        // Verify
        Assert.IsFalse(PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamePostedCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewCode: Code[10];
    begin
        // Setup
        Initialize();
        CreatePostedCrMemoNoDiscount(PurchCrMemoHdr);

        // Execute
        NewCode := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr.Rename(NewCode);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(NewCode, DummyPurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateMatchesPurchaseDocumentHeaders()
    var
        DummyPurchaseHeader: Record "Purchase Header";
        DummyPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TempCrMemoBufferSpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        BufferRecordRef: RecordRef;
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithPurchaseHeader(TempCommonField);
        GetCrMemoAggregateSpecificFields(TempCrMemoBufferSpecificField);

        // Execute and verify
        BufferRecordRef.Open(Database::"Purch. Cr. Memo Entity Buffer");
        Assert.AreEqual(
          TempCommonField.Count + TempCrMemoBufferSpecificField.Count, BufferRecordRef.FieldCount,
          'Update reflection test. There are fields that are not accounted.');

        TempCommonField.SetFilter("No.", '<>%1', DummyPurchaseHeader.FieldNo("Recalculate Invoice Disc."));
        VerifyFieldDefinitionsMatchTableFields(Database::"Purch. Cr. Memo Hdr.", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(Database::"Purch. Cr. Memo Hdr.", TempCrMemoBufferSpecificField);

        TempCommonField.SetFilter("No.", '<>%1', DummyPurchCrMemoHdr.FieldNo("Vendor Ledger Entry No."));
        VerifyFieldDefinitionsMatchTableFields(Database::"Purchase Header", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(Database::"Purchase Header", TempCrMemoBufferSpecificField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateLineMatchesPurchaseDocumentLines()
    var
        TempCrMemoLineEntitySpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        AggregateLineRecordRef: RecordRef;
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithPurchaseLine(TempCommonField);
        GetCrMemoAggregateLineSpecificFields(TempCrMemoLineEntitySpecificField);

        // Execute and verify
        AggregateLineRecordRef.Open(Database::"Purch. Inv. Line Aggregate");

        Assert.AreEqual(TempCommonField.Count + TempCrMemoLineEntitySpecificField.Count,
          AggregateLineRecordRef.FieldCount,
          'Update reflection test. There are fields that are not accounted.');

        VerifyFieldDefinitionsMatchTableFields(Database::"Purchase Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(Database::"Purchase Line", TempCrMemoLineEntitySpecificField);

        FilterOutFieldsMissingOnPurchaseCrMemoLine(TempCommonField);
        VerifyFieldDefinitionsMatchTableFields(Database::"Purch. Cr. Memo Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(Database::"Purch. Cr. Memo Line", TempCrMemoLineEntitySpecificField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingVendorLedgerEntry()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OpenVendorLedgerEntry: Record "Vendor Ledger Entry";
        ClosedVendorLedgerEntry: Record "Vendor Ledger Entry";
        UnpaidPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Setup
        Initialize();
        CreateAndMarkPostedCrMemoAsPaid(PurchCrMemoHdr);
        CreatePostedCrMemoNoDiscount(UnpaidPurchCrMemoHdr);

        // Execute
        ClosedVendorLedgerEntry.Get(PurchCrMemoHdr."Vendor Ledger Entry No.");
        ClosedVendorLedgerEntry.Delete();

        OpenVendorLedgerEntry.SetRange("Entry No.", UnpaidPurchCrMemoHdr."Vendor Ledger Entry No.");
        OpenVendorLedgerEntry.FindFirst();
        OpenVendorLedgerEntry.Rename(PurchCrMemoHdr."Vendor Ledger Entry No.");

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(PurchCrMemoHdr."No.", DummyPurchCrMemoEntityBuffer.Status::Open);
        VerifyBufferTableIsUpdatedForPostedCrMemo(UnpaidPurchCrMemoHdr."No.", DummyPurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCrMemoApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Vendor);
        SetAllowManualDisc();

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        OpenPurchaseCrMemo(PurchaseHeader, PurchaseCreditMemo);

        // Execute
        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        PurchaseCreditMemo.CalculateInvoiceDiscount.Invoke();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateAggregateTable()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGuid, PurchaseHeader."Document Type"::"Credit Memo");
        CreatePostedCrMemoNoDiscount(PurchCrMemoHdr);
        PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true);
        PurchCrMemoEntityBuffer.Delete();
        PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false);
        PurchCrMemoEntityBuffer.Delete();

        // Execute
        GraphMgtPurchCrMemo.UpdateBufferTableRecords();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
        VerifyBufferTableIsUpdatedForPostedCrMemo(PurchCrMemoHdr."No.", DummyPurchCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertPurchaseAggregate()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        TempFieldBuffer: Record "Field Buffer" temporary;
        PurchaseHeader: Record "Purchase Header";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
    begin
        // Setup
        Initialize();

        UpdatePurchaseCrMemoAggregate(PurchCrMemoEntityBuffer, TempFieldBuffer);

        // Execute
        GraphMgtPurchCrMemo.PropagateOnInsert(PurchCrMemoEntityBuffer, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No."), 'Could not find Purchase Header');
        Assert.AreEqual(
          PurchaseHeader."Buy-from Vendor No.", PurchCrMemoEntityBuffer."Buy-from Vendor No.", 'Fields were not transferred');

        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPropagateModifyPurchaseAggregate()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        TempFieldBuffer: Record "Field Buffer" temporary;
        PurchaseHeader: Record "Purchase Header";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
    begin
        // Setup
        Initialize();
        CreateCrMemoWithLinesThroughCodeNoDiscount(PurchaseHeader);
        PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false);
        UpdatePurchaseCrMemoAggregate(PurchCrMemoEntityBuffer, TempFieldBuffer);

        // Execute
        AnswerYesToAllConfirmDialogs();
        GraphMgtPurchCrMemo.PropagateOnModify(PurchCrMemoEntityBuffer, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No."), 'Could not find Purchase Header');
        Assert.AreEqual(
          PurchaseHeader."Buy-from Vendor No.", PurchCrMemoEntityBuffer."Buy-from Vendor No.", 'Fields were not transferred');

        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeletePurchaseAggregate()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGuid, PurchaseHeader."Document Type"::"Credit Memo");
        PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false);

        // Execute
        GraphMgtPurchCrMemo.PropagateOnDelete(PurchCrMemoEntityBuffer);

        // Verify
        Assert.IsFalse(PurchaseHeader.Find(), 'Purchase header should be deleted');
        Assert.IsFalse(PurchCrMemoEntityBuffer.Find(), 'Purchase line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeletePurchaseAggregatePostedCrMemo()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
    begin
        // Setup
        Initialize();

        CreatePostedCrMemoNoDiscount(PurchCrMemoHdr);
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(PurchCrMemoHdr."Posting Date" + 1);
        PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true);

        // Execute
        GraphMgtPurchCrMemo.PropagateOnDelete(PurchCrMemoEntityBuffer);

        // Verify
        Assert.IsFalse(PurchCrMemoHdr.Find(), 'Purchase header should be deleted');
        Assert.IsFalse(PurchCrMemoEntityBuffer.Find(), 'Purchase line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertPurchaseLineTrhowsAnErrorIfDocumentIDNotSpecified()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        UpdatePurchCrMemoLineAggregate(TempPurchInvLineAggregate, TempFieldBuffer);

        // Execute
        asserterror GraphMgtPurchCrMemo.PropagateInsertLine(TempPurchInvLineAggregate, TempFieldBuffer);

        // Verify
        Assert.ExpectedError(DocumentIDNotSpecifiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertPurchaseLineTrhowsAnErrorIfMultipleDocumentIdsFound()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");

        TempPurchInvLineAggregate.SetFilter("Document Id", '<>%1', ExpectedGUID);
        UpdatePurchCrMemoLineAggregate(TempPurchInvLineAggregate, TempFieldBuffer);

        // Execute
        asserterror GraphMgtPurchCrMemo.PropagateInsertLine(TempPurchInvLineAggregate, TempFieldBuffer);

        // Verify
        Assert.ExpectedError(MultipleDocumentsFoundForIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateModifyPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        GraphMgtPurchCrMemo.LoadLines(TempPurchInvLineAggregate, PurchaseHeader.SystemId);
        TempPurchInvLineAggregate.FindFirst();
        UpdatePurchCrMemoLineAggregate(TempPurchInvLineAggregate, TempFieldBuffer);

        // Execute
        GraphMgtPurchCrMemo.PropagateModifyLine(TempPurchInvLineAggregate, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          PurchaseLine.Get(PurchaseLine."Document Type"::"Credit Memo", PurchaseHeader."No.", TempPurchInvLineAggregate."Line No."),
          'Purchase line was updated');
        Assert.AreEqual(PurchaseLine."No.", TempPurchInvLineAggregate."No.", 'No. was not set');
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteAggregateLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary;
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreatePurchaseHeaderWithID(PurchaseHeader, ExpectedGUID, PurchaseHeader."Document Type"::"Credit Memo");
        GraphMgtPurchCrMemo.LoadLines(TempPurchInvLineAggregate, PurchaseHeader.SystemId);
        TempPurchInvLineAggregate.FindFirst();

        // Execute
        GraphMgtPurchCrMemo.PropagateDeleteLine(TempPurchInvLineAggregate);

        // Verify
        Assert.IsFalse(
          PurchaseLine.Get(PurchaseLine."Document Type"::"Credit Memo", PurchaseHeader."No.", TempPurchInvLineAggregate."Line No."),
          'Purchase line was not deleted');
        VerifyBufferTableIsUpdatedForCrMemo(PurchaseHeader."No.");
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; DiscPct: Decimal; minAmount: Decimal)
    begin
        CreateVendor(Vendor);
        AddCrMemoDiscToVendor(Vendor, minAmount, DiscPct);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Vendor);
        CreateCrMemoWithOneLineThroughTestPage(PurchaseCreditMemo, Vendor, Item);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Vendor, CrMemoDiscountAmount);
        CreateCrMemoWithOneLineThroughTestPage(PurchaseCreditMemo, Vendor, Item);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageNoDiscount(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateVendor(Vendor);
        CreateCrMemoWithOneLineThroughTestPage(PurchaseCreditMemo, Vendor, Item);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPage(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; Vendor: Record Vendor; Item: Record Item)
    begin
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor."No.");

        CreateLineThroughTestPage(PurchaseCreditMemo, Item."No.");
    end;

    local procedure CreateLineThroughTestPage(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; ItemNo: Text)
    var
        ItemQuantity: Decimal;
    begin
        PurchaseCreditMemo.PurchLines.Last();
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines."No.".SetValue(ItemNo);

        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(1, 100));

        // Trigger Save
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();
    end;

    local procedure CreatePurchaseHeaderWithID(var PurchaseHeader: Record "Purchase Header"; var ExpectedGUID: Guid; DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        SetupDataForDiscountTypePct(Item, Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(1, 100), LibraryRandom.RandIntInRange(1, 10));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(1, 100), LibraryRandom.RandIntInRange(1, 10));

        ExpectedGUID := PurchaseHeader.SystemId;
    end;

    local procedure CreatePostedCrMemoDiscountTypePct(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        SetupDataForDiscountTypePct(Item, Vendor);
        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure CreatePostedCrMemoDiscountTypeAmt(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Vendor, CrMemoDiscountAmount);

        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
        PurchCalcDiscountByType.ApplyInvDiscBasedOnAmt(CrMemoDiscountAmount, PurchaseHeader);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure CreatePostedCrMemoNoDiscount(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateCrMemoWithLinesThroughCodeNoDiscount(PurchaseHeader);
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure CreateAndMarkPostedCrMemoAsPaid(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreatePostedCrMemoDiscountTypePct(PurchCrMemoHdr);

        VendorLedgerEntry.SetRange("Entry No.", PurchCrMemoHdr."Vendor Ledger Entry No.");
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure CreateCrMemoWithLinesThroughCodeNoDiscount(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateVendor(Vendor);
        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);
    end;

    local procedure CreateCrMemoWithLinesThroughCodeDiscountPct(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Vendor);
        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        Codeunit.Run(Codeunit::"Purch - Calc Disc. By Type", PurchaseLine);

        PurchaseHeader.Find();
        PurchaseLine.Find();
    end;

    local procedure CreateCrMemoWithLinesThroughCodeDiscountAmt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchCalcDiscountByType: Codeunit "Purch - Calc Disc. By Type";
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Vendor, CrMemoDiscountAmount);
        CreateCrMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor);

        PurchCalcDiscountByType.ApplyInvDiscBasedOnAmt(CrMemoDiscountAmount, PurchaseHeader);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure CreateCrMemoWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
        ItemQuantity: Decimal;
        NumberOfLines: Integer;
        UnitCost: Decimal;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(3, 10);
        ItemQuantity := LibraryRandom.RandIntInRange(10, 100);
        UnitCost := LibraryRandom.RandIntInRange(1, 100);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.Validate("Posting Date", AllowPostedDocumentDeletionDate);
        PurchaseHeader.Modify(true);

        for I := 1 to NumberOfLines do
            LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", UnitCost, ItemQuantity);
    end;

    local procedure OpenPurchaseCrMemo(PurchaseHeader: Record "Purchase Header"; var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
    end;

    local procedure GetPurchCrMemoAggregateLines(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer"; var TempPurchInvoiceLineAggregate: Record "Purch. Inv. Line Aggregate" temporary)
    var
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
    begin
        GraphMgtPurchCrMemo.LoadLines(TempPurchInvoiceLineAggregate, PurchCrMemoEntityBuffer.Id);
        TempPurchInvoiceLineAggregate.Reset();
    end;

    local procedure AddCrMemoDiscToVendor(Vendor: Record Vendor; MinimumAmount: Decimal; Percentage: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", MinimumAmount);
        VendorInvoiceDisc.Validate("Discount %", Percentage);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var Vendor: Record Vendor)
    var
        ItemUnitPrice: Decimal;
        DiscPct: Decimal;
        MinAmt: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitPrice);
        CreateVendorWithDiscount(Vendor, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var Vendor: Record Vendor; var CrMemoDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemUnitPrice: Decimal;
    begin
        SetAllowManualDisc();

        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateVendor(Vendor);
        CrMemoDiscountAmount := LibraryRandom.RandDecInRange(1, 100, 2);

        if GeneralLedgerSetup.UseVat() then begin
            Vendor."Prices Including VAT" := true;
            Vendor.Modify();
        end;
    end;

    local procedure AnswerYesToConfirmDialogs(ExpectedNumberOfDialogs: Integer)
    var
        I: Integer;
    begin
        for I := 1 to ExpectedNumberOfDialogs do begin
            LibraryVariableStorage.Enqueue(ChangeConfirmMsg);
            LibraryVariableStorage.Enqueue(true);
        end;
    end;

    local procedure AnswerYesToAllConfirmDialogs()
    begin
        AnswerYesToConfirmDialogs(10);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(Answer);
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := Answer;
    end;

    local procedure SetAllowManualDisc()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", false);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure DisableWarningOnClosingCrMemo()
    var
        UserPreference: Record "User Preference";
    begin
        UserPreference."User ID" := UserId;
        UserPreference."Instruction Code" := 'QUERYPOSTONCLOSE';
        if UserPreference.Insert() then;
    end;

    local procedure ErrorMessageForFieldComparison(FieldRef1: FieldRef; FieldRef2: FieldRef; MismatchType: Text): Text
    begin
        exit(
          Format(
            'Field ' +
            MismatchType +
            ' on fields ' +
            FieldRef1.Record().Name() + '.' + FieldRef1.Name + ' and ' + FieldRef2.Record().Name() + '.' + FieldRef2.Name + ' do not match.'));
    end;

    local procedure VerifyFieldDefinitionsMatchTableFields(SourceTableID: Integer; var TempField: Record "Field" temporary)
    var
        RecRef: RecordRef;
        TargetTableRecRef: RecordRef;
        TargetTableFieldRef: FieldRef;
        SourceTableFieldRef: FieldRef;
    begin
        RecRef.Open(SourceTableID);
        TargetTableRecRef.Open(TempField.TableNo);

        TempField.FindFirst();

        repeat
            SourceTableFieldRef := RecRef.Field(TempField."No.");
            TargetTableFieldRef := TargetTableRecRef.Field(TempField."No.");
            ValidateFieldDefinitionsMatch(SourceTableFieldRef, TargetTableFieldRef);
        until TempField.Next() = 0;
    end;

    local procedure VerifyFieldDefinitionsDontExistInTargetTable(TableID: Integer; var TempField: Record "Field" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);

        TempField.Reset();
        TempField.FindFirst();

        repeat
            Assert.IsFalse(
              RecRef.FieldExist(TempField."No."),
              StrSubstNo(
                'Field %1 is specific for Table %2 and should not be in the Table %3. TRANSFERFIELDS will break existing functionailty.',
                TempField."No.", TempField.TableName, RecRef.Name));
        until TempField.Next() = 0;
    end;

    local procedure ValidateFieldDefinitionsMatch(FieldRef1: FieldRef; FieldRef2: FieldRef)
    begin
        Assert.AreEqual(FieldRef1.Name, FieldRef2.Name, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'names'));
        Assert.IsTrue(FieldRef1.Type = FieldRef2.Type, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'types'));
        Assert.AreEqual(FieldRef1.Length, FieldRef2.Length, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'lengths'));
        Assert.AreEqual(
          FieldRef1.OptionMembers, FieldRef2.OptionMembers, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option string'));
        Assert.AreEqual(
          FieldRef1.OptionCaption, FieldRef2.OptionCaption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option caption'));
    end;

    local procedure VerifyBufferTableIsUpdatedForCrMemo(DocumentNo: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", DocumentNo);
        PurchCrMemoEntityBuffer.Get(DocumentNo, false);

        VerifyBufferTableIsUpdated(PurchaseHeader, PurchCrMemoEntityBuffer);
        Assert.AreEqual(PurchCrMemoEntityBuffer.Status::Draft, PurchCrMemoEntityBuffer.Status, 'Wrong status set');

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseLine.SetFilter(Type, '<>'' ''');
        VerifyLinesMatch(PurchaseLine, PurchCrMemoEntityBuffer);
    end;

    local procedure VerifyBufferTableIsUpdatedForPostedCrMemo(DocumentNo: Text; ExpectedStatus: Enum "Purch. Cr. Memo Entity Status")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoEntityBuffer.Get(DocumentNo, true);

        VerifyBufferTableIsUpdated(PurchCrMemoHdr, PurchCrMemoEntityBuffer);
        Assert.AreEqual(ExpectedStatus, PurchCrMemoEntityBuffer.Status, 'Wrong status set');

        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");

        VerifyLinesMatch(PurchCrMemoLine, PurchCrMemoEntityBuffer);
    end;

    local procedure VerifyBufferTableIsUpdated(SourceRecordVariant: Variant; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    begin
        ValidateTotalsMatch(SourceRecordVariant, PurchCrMemoEntityBuffer);
        VerifyTransferredFieldsMatch(SourceRecordVariant, PurchCrMemoEntityBuffer);
    end;

    local procedure VerifyTransferredFieldsMatch(SourceRecord: Variant; TargetRecord: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        I: Integer;
    begin
        DataTypeManagement.GetRecordRef(SourceRecord, SourceRecordRef);
        DataTypeManagement.GetRecordRef(TargetRecord, TargetRecordRef);

        for I := 1 to SourceRecordRef.FieldCount do begin
            SourceFieldRef := SourceRecordRef.FieldIndex(I);
            if TargetRecordRef.FieldExist(SourceFieldRef.Number) then begin
                TargetFieldRef := TargetRecordRef.Field(SourceFieldRef.Number);
                if SourceFieldRef.Class = FieldClass::Normal then
                    if SourceFieldRef.Name <> 'Id' then
                        Assert.AreEqual(TargetFieldRef.Value, SourceFieldRef.Value, StrSubstNo('Fields %1 do not match', TargetFieldRef.Name));
            end;
        end;
    end;

    local procedure VerifyLinesMatch(SourceRecordLines: Variant; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        LinesRecordRef: RecordRef;
    begin
        GetPurchCrMemoAggregateLines(PurchCrMemoEntityBuffer, TempPurchInvLineAggregate);
        DataTypeManagement.GetRecordRef(SourceRecordLines, LinesRecordRef);

        Assert.AreEqual(LinesRecordRef.Count, TempPurchInvLineAggregate.Count, 'Wrong number of lines');
        if LinesRecordRef.Count = 0 then
            exit;

        TempPurchInvLineAggregate.FindFirst();
        LinesRecordRef.FindFirst();
        repeat
            VerifyLineValuesMatch(LinesRecordRef, TempPurchInvLineAggregate, PurchCrMemoEntityBuffer.Posted);
            TempPurchInvLineAggregate.Next();
        until LinesRecordRef.Next() = 0;
    end;

    local procedure VerifyLineValuesMatch(var SourceRecordRef: RecordRef; var TempPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate" temporary; Posted: Boolean)
    var
        TempField: Record "Field" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceFieldRef: FieldRef;
        AggregateLineFieldRef: FieldRef;
        TaxId: Guid;
    begin
        GetFieldsThatMustMatchWithPurchaseLine(TempField);

        if Posted then
            FilterOutFieldsMissingOnPurchaseCrMemoLine(TempField);
        TempField.FindFirst();
        repeat
            AggregateLineFieldRef := SourceRecordRef.Field(TempField."No.");
            SourceFieldRef := SourceRecordRef.Field(TempField."No.");
            Assert.AreEqual(
              Format(SourceFieldRef.Value), Format(AggregateLineFieldRef.Value),
              StrSubstNo('Value did not match for field no. %1', TempField."No."));
        until TempField.Next() = 0;

        if GeneralLedgerSetup.UseVat() then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, PurchaseLine.FieldName("VAT Prod. Posting Group"));
            if VATProductPostingGroup.Get(SourceFieldRef.Value) then
                TaxId := VATProductPostingGroup.SystemId;
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, PurchaseLine.FieldName("VAT Identifier"))
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, PurchaseLine.FieldName("Tax Group Code"));
            if TaxGroup.Get(SourceFieldRef.Value) then
                TaxId := TaxGroup.SystemId
        end;

        Assert.AreEqual(Format(SourceFieldRef.Value), Format(TempPurchInvLineAggregate."Tax Code"), 'Tax code did not match');
        Assert.AreEqual(Format(TaxId), Format(TempPurchInvLineAggregate."Tax Id"), 'Tax ID did not match');

        if TempPurchInvLineAggregate.Type <> TempPurchInvLineAggregate.Type::Item then
            exit;

        DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, PurchaseLine.FieldName("No."));
        Item.Get(SourceFieldRef.Value);
        Assert.AreEqual(TempPurchInvLineAggregate."Item Id", Item.SystemId, 'Item ID was not set');
        Assert.IsFalse(IsNullGuid(Item.SystemId), 'Item ID was not set');
        Assert.AreNearlyEqual(
          TempPurchInvLineAggregate."Tax Amount",
          TempPurchInvLineAggregate."Amount Including VAT" - TempPurchInvLineAggregate.Amount,
          0.01, 'Tax amount is not correct');
    end;

    local procedure ValidateTotalsMatch(SourceRecord: Variant; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DataTypeManagement: Codeunit "Data Type Management";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        SourceRecordRef: RecordRef;
        ExpectedCrMemoDiscountAmount: Decimal;
        ExpectedTotalInclTaxAmount: Decimal;
        ExpectedTotalExclTaxAmount: Decimal;
        ExpectedTaxAmountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        DataTypeManagement.GetRecordRef(SourceRecord, SourceRecordRef);
        case SourceRecordRef.Number of
            Database::"Purchase Header":
                begin
                    PurchaseCreditMemo.OpenEdit();
                    Assert.IsTrue(PurchaseCreditMemo.GotoRecord(SourceRecord), 'Could not navigate to credit memo');
                    if PurchaseCreditMemo.PurchLines."Invoice Discount Amount".Visible() then
                        ExpectedCrMemoDiscountAmount := PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal();
                    PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
                    PurchaseLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");
                    NumberOfLines := PurchaseLine.Count();
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    PostedPurchaseCreditMemo.OpenEdit();
                    Assert.IsTrue(PostedPurchaseCreditMemo.GotoRecord(SourceRecord), 'Could not navigate to invoice');
                    ExpectedCrMemoDiscountAmount := PostedPurchaseCreditMemo.PurchCrMemoLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := PostedPurchaseCreditMemo.PurchCrMemoLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := PostedPurchaseCreditMemo.PurchCrMemoLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := PostedPurchaseCreditMemo.PurchCrMemoLines."Total Amount Incl. VAT".AsDecimal();
                    PurchCrMemoLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");
                    NumberOfLines := PurchCrMemoLine.Count();
                end;
        end;

        PurchCrMemoEntityBuffer.Find();

        if NumberOfLines > 0 then
            Assert.IsTrue(ExpectedTotalExclTaxAmount > 0, 'One amount must be greated than zero');
        Assert.AreEqual(
          ExpectedCrMemoDiscountAmount, PurchCrMemoEntityBuffer."Invoice Discount Amount", 'Invoice discount amount is not correct');
        Assert.AreEqual(ExpectedTaxAmountAmount, PurchCrMemoEntityBuffer."Total Tax Amount", 'Total Tax Amount is not correct');
        Assert.AreEqual(ExpectedTotalExclTaxAmount, PurchCrMemoEntityBuffer.Amount, 'Amount is not correct');
        Assert.AreEqual(
          ExpectedTotalInclTaxAmount, PurchCrMemoEntityBuffer."Amount Including VAT", 'Amount Including VAT is not correct');
    end;

    local procedure GetFieldsThatMustMatchWithPurchaseHeader(var TempField: Record "Field" temporary)
    begin
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
         DummyPurchCrMemoEntityBuffer.FieldNo("Posting Date"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Payment Terms Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Shipment Method Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Due Date"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Posting Group"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Currency Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Prices Including VAT"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Purchaser Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo(Amount), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Amount Including VAT"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor Name"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address 2"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from City"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Post Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from County"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Country/Region Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Name"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address 2"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to City"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Contact"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Post Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to County"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Country/Region Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Vendor No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Document Date"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Ledger Entry No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Reason Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Shortcut Dimension 1 Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Shortcut Dimension 2 Code"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Cr. Memo No."), Database::"Purch. Cr. Memo Entity Buffer", TempField);
    end;

    local procedure GetFieldsThatMustMatchWithPurchaseLine(var TempField: Record "Field" temporary)
    var
        DummyPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate";
    begin
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Line No."), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo(Type), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("No."), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo(Description), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Description 2"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo(Quantity), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Direct Unit Cost"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("VAT %"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Inv. Discount Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Line Discount %"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Line Discount Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo(Amount), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Amount Including VAT"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Currency Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("VAT Base Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Line Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("VAT Prod. Posting Group"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Tax Group Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Unit of Measure Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Qty. to Invoice"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Quantity Invoiced"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Variant Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Location Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Expected Receipt Date"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Qty. to Receive"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Quantity Received"), Database::"Purch. Inv. Line Aggregate", TempField);
    end;

    local procedure GetCrMemoAggregateSpecificFields(var TempField: Record "Field" temporary)
    begin
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Total Tax Amount"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo(Status), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo(Posted), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Currency Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Payment Terms Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Shipment Method Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Vendor Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo("Reason Code Id"), Database::"Purch. Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummyPurchCrMemoEntityBuffer.FieldNo(Id), Database::"Purch. Cr. Memo Entity Buffer", TempField);
    end;

    local procedure GetCrMemoAggregateLineSpecificFields(var TempField: Record "Field" temporary)
    var
        DummyPurchInvLineAggregate: Record "Purch. Inv. Line Aggregate";
    begin
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Tax Code"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Tax Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Tax Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Discount Applied Before Tax"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Item Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Document Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("API Type"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Account Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Line Amount Excluding Tax"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Line Amount Including Tax"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Prices Including Tax"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Line Tax Amount"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Inv. Discount Amount Excl. VAT"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(
          DummyPurchInvLineAggregate.FieldNo("Unit of Measure Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo(Id), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Variant Id"), Database::"Purch. Inv. Line Aggregate", TempField);
        AddFieldToBuffer(DummyPurchInvLineAggregate.FieldNo("Location Id"), Database::"Purch. Inv. Line Aggregate", TempField);
    end;

    local procedure AddFieldToBuffer(FieldNo: Integer; TableID: Integer; var TempField: Record "Field" temporary)
    var
        "Field": Record "Field";
    begin
        Field.Get(TableID, FieldNo);
        TempField.TransferFields(Field, true);
        TempField.Insert();
    end;

    local procedure UpdatePurchaseCrMemoAggregate(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PurchCrMemoEntityBuffer.Validate("Buy-from Vendor No.", Vendor."No.");
        RegisterFieldSet(TempFieldBuffer, PurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor No."));
    end;

    local procedure UpdatePurchCrMemoLineAggregate(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        PurchInvLineAggregate.Type := PurchInvLineAggregate.Type::Item;
        PurchInvLineAggregate.Validate("No.", Item."No.");

        RegisterFieldSet(TempFieldBuffer, PurchInvLineAggregate.FieldNo(Type));
        RegisterFieldSet(TempFieldBuffer, PurchInvLineAggregate.FieldNo("No."));
    end;

    local procedure RegisterFieldSet(var TempFieldBuffer: Record "Field Buffer" temporary; FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := Database::"Purch. Cr. Memo Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure FilterOutFieldsMissingOnPurchaseCrMemoLine(var TempCommonField: Record "Field" temporary)
    var
        DummyPurchaseLine: Record "Purchase Line";
    begin
        TempCommonField.SetFilter(
          "No.", '<>%1&<>%2&<>%3&<>%4&<>%5', DummyPurchaseLine.FieldNo("Qty. to Receive"), DummyPurchaseLine.FieldNo("Quantity Received"), DummyPurchaseLine.FieldNo("Currency Code"), DummyPurchaseLine.FieldNo("Qty. to Invoice"), DummyPurchaseLine.FieldNo("Quantity Invoiced"));
    end;
}
