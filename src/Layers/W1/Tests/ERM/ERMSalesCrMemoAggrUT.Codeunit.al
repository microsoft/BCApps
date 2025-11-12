codeunit 134397 "ERM Sales Cr. Memo Aggr. UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Sales] [Credit Memo]
        IsInitialized := false;
    end;

    var
        DummySalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
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
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        APIMockEvents: Codeunit "API Mock Events";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        CalculateInvoiceDiscountQst: Label 'Do you want to calculate the invoice discount?';
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        TaxAmountErr: Label 'Tax Amount must be equal to %1', Comment = '%1= Expected Tax Amount';

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Cr. Memo Aggr. UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Cr. Memo Aggr. UT");

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        if GeneralLedgerSetup.UseVat() then begin
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.CreateGeneralPostingSetupData();
        end;

        LibrarySales.SetStockoutWarning(false);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        DisableWarningOnClosingCrMemo();

        Commit();

        BindSubscription(APIMockEvents);
        APIMockEvents.SetIsAPIEnabled(true);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Cr. Memo Aggr. UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageNoDiscount(SalesCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(SalesCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        // Execute
        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(SalesCreditMemo);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmtTest()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CrMemoDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();
        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(SalesCreditMemo);
        CrMemoDiscountAmount :=
          LibraryRandom.RandDecInDecimalRange(1, SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal() / 2, 1);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        SalesLine."Recalculate Invoice Disc." := true;
        SalesLine.Modify();
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCreditMemo."No.".Value);
        SalesCreditMemo.Close();

        // Execute
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(CrMemoDiscountAmount);
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesTotalsKeepsCrMemoDiscTypeAmount()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CrMemoDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(SalesCreditMemo);
        CrMemoDiscountAmount := SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal();

        // Execute
        CreateLineThroughTestPage(SalesCreditMemo, SalesCreditMemo.SalesLines."No.".Value);

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(CrMemoDiscountAmount);
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageNoDiscount(SalesCreditMemo);

        // Execute
        SalesCreditMemo.SalesLines.Quantity.SetValue(SalesCreditMemo.SalesLines.Quantity.AsDecimal() * 2);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(SalesCreditMemo);

        // Execute
        SalesCreditMemo.SalesLines."Line Amount".SetValue(Round(SalesCreditMemo.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(SalesCreditMemo);

        // Execute
        SalesCreditMemo.SalesLines."Unit Price".SetValue(SalesCreditMemo.SalesLines."Unit Price".AsDecimal() * 2);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesTotalsKeepsCrMemoDiscTypeAmount()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(SalesCreditMemo);

        // Execute
        SalesCreditMemo.SalesLines."Unit Price".SetValue(SalesCreditMemo.SalesLines."Unit Price".AsDecimal() * 2);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineUpdatesTotalsNoDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // Execute
        SalesLine.Delete(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");

        // Execute last
        SalesLine.FindLast();
        SalesLine.Delete(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineUpdatesTotalsDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountPct(SalesHeader, SalesLine);

        // Execute
        SalesLine.Delete(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineUpdatesTotalsDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountAmt(SalesHeader, SalesLine);
        SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);

        // Execute
        SalesLine.Delete(true);
        GraphMgtSalCrMemoBuf.RedistributeCreditMemoDiscounts(SalesCrMemoEntityBuffer);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsNoDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountPct(SalesHeader, SalesLine);

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAllLinesUpdatesTotalsDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeDiscountAmt(SalesHeader, SalesLine);

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSellToCustomerRecalculatesForCrMemoDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NewCustDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);
        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);

        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesCreditMemo."Sell-to Customer No.".SetValue(NewCustomer."No.");

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSellToCustomerSetsDiscountToZeroForCrMemoDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CrMemoDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Customer, CrMemoDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        // Execute
        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        CreateCustomer(NewCustomer);

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderRecalculatesForCrMemoDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NewCustomerDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesCreditMemo."Bill-to Name".SetValue(NewCustomer.Name);

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderSetsDiscountToZeroForCrMemoDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CrMemoDiscountAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Customer, CrMemoDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesCreditMemo."Bill-to Name".SetValue(NewCustomer.Name);

        // Verify
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesCrMemoWithDiscountAmount()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedCrMemoDiscountTypeAmt(SalesCrMemoHeader);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesCrMemoTransfersId()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");

        // Execute
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // Verify
        Assert.IsFalse(SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false), 'Draft Aggregated Credit Memo still exists');

        Assert.AreEqual(SalesHeader.SystemId, SalesCrMemoHeader."Draft Cr. Memo SystemId", 'Posted Credit Memo ID is incorrect');
        Assert.IsFalse(SalesHeader.Find(), 'Draft Credit Memo still exists');
        SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true);
        Assert.IsFalse(IsNullGuid(SalesCrMemoEntityBuffer.Id), 'Id cannot be null');
        Assert.AreEqual(SalesCrMemoHeader."Draft Cr. Memo SystemId", SalesCrMemoEntityBuffer.Id, 'Aggregate Credit Memo ID is incorrect');

        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", SalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingPostedCrMemoThroughCodeTransfersId()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        ExpectedGUID: Guid;
        TempGUID: Guid;
    begin
        // Setup
        Initialize();
        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");

        TempGUID := CreateGuid();
        SalesCrMemoHeader.TransferFields(SalesHeader, true);
        SalesCrMemoHeader."Pre-Assigned No." := SalesHeader."No.";
        SalesCrMemoHeader.Insert(true);

        // Execute
        SalesHeader.Delete(true);

        // Verify
        Assert.IsFalse(SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false), 'Draft Aggregated Credit Memo still exists');

        SalesCrMemoHeader.Find();
        Assert.AreEqual(SalesHeader.SystemId, SalesCrMemoHeader."Draft Cr. Memo SystemId", 'Posted Credit Memo ID is incorrect');
        Assert.IsFalse(SalesHeader.Find(), 'Draft Credit Memo still exists');
        SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true);
        Assert.IsFalse(IsNullGuid(SalesCrMemoEntityBuffer.Id), 'Id cannot be null');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesCrMemoWithDiscountPrecentage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedCrMemoDiscountTypePct(SalesCrMemoHeader);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        // Setup
        Initialize();

        CreateCrMemoWithLinesThroughCodeNoDiscount(SalesHeader);

        // Execute
        SalesHeader.Delete(true);

        // Verify
        Assert.IsFalse(SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        // Setup
        Initialize();
        CreatePostedCrMemoDiscountTypeAmt(SalesCrMemoHeader);

        // Execute
        SalesCrMemoHeader.Delete();

        // Verify
        Assert.IsFalse(SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamePostedCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewCode: Code[10];
    begin
        // Setup
        Initialize();
        CreatePostedCrMemoNoDiscount(SalesCrMemoHeader);

        // Execute
        NewCode := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Rename(NewCode);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(NewCode, DummySalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateMatchesSalesDocumentHeaders()
    var
        DummySalesHeader: Record "Sales Header";
        DummySalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempCrMemoBufferSpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        BufferRecordRef: RecordRef;
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithSalesHeader(TempCommonField);
        GetCrMemoAggregateSpecificFields(TempCrMemoBufferSpecificField);

        // Execute and verify
        BufferRecordRef.Open(DATABASE::"Sales Cr. Memo Entity Buffer");
        Assert.AreEqual(
          TempCommonField.Count + TempCrMemoBufferSpecificField.Count, BufferRecordRef.FieldCount,
          'Update reflection test. There are fields that are not accounted.');

        TempCommonField.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4',
          DummySalesHeader.FieldNo("Recalculate Invoice Disc."),
          DummySalesHeader.FieldNo("Shipping Advice"),
          DummySalesHeader.FieldNo("Completely Shipped"),
          DummySalesHeader.FieldNo("Requested Delivery Date"));
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Cr.Memo Header", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Cr.Memo Header", TempCrMemoBufferSpecificField);

        TempCommonField.SetFilter("No.", '<>%1', DummySalesCrMemoHeader.FieldNo("Cust. Ledger Entry No."));
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Header", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Header", TempCrMemoBufferSpecificField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateLineMatchesSalesDocumentLines()
    var
        TempCrMemoLineEntitySpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        AggregateLineRecordRef: RecordRef;
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithSalesLine(TempCommonField);
        GetCrMemoAggregateLineSpecificFields(TempCrMemoLineEntitySpecificField);

        // Execute and verify
        AggregateLineRecordRef.Open(DATABASE::"Sales Invoice Line Aggregate");
        Assert.AreEqual(TempCommonField.Count + TempCrMemoLineEntitySpecificField.Count,
          AggregateLineRecordRef.FieldCount,
          'Update reflection test. There are fields that are not accounted.');

        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Line", TempCrMemoLineEntitySpecificField);

        FilterOutFieldsMissingOnSalesCrMemoLine(TempCommonField);
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Cr.Memo Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Cr.Memo Line", TempCrMemoLineEntitySpecificField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelingPostedCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreateAndCancelPostedCrMemo(SalesCrMemoHeader, NewSalesInvoiceHeader);

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingCustomerLedgerEntry()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OpenCustLedgerEntry: Record "Cust. Ledger Entry";
        ClosedCustLedgerEntry: Record "Cust. Ledger Entry";
        UnpaidSalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup
        Initialize();
        CreateAndMarkPostedCrMemoAsPaid(SalesCrMemoHeader);
        CreatePostedCrMemoNoDiscount(UnpaidSalesCrMemoHeader);

        // Execute
        ClosedCustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No.");
        ClosedCustLedgerEntry.Delete();

        OpenCustLedgerEntry.SetRange("Entry No.", UnpaidSalesCrMemoHeader."Cust. Ledger Entry No.");
        OpenCustLedgerEntry.FindFirst();
        OpenCustLedgerEntry.Rename(SalesCrMemoHeader."Cust. Ledger Entry No.");

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Open);
        VerifyBufferTableIsUpdatedForPostedCrMemo(UnpaidSalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingCancelledDocument()
    var
        CancelledDocument: Record "Cancelled Document";
        CancelledSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        CreateAndCancelPostedCrMemo(CancelledSalesCrMemoHeader, NewSalesInvoiceHeader);
        CancelledDocument.Get(DATABASE::"Sales Cr.Memo Header", CancelledSalesCrMemoHeader."No.");

        // Execute
        CancelledDocument.Rename(DATABASE::"Sales Header", CancelledDocument."Cancelled Doc. No.");

        // Verify
        VerifyBufferTableIsUpdatedForPostedCrMemo(CancelledSalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Paid);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCrMemoApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        SetAllowManualDisc();

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesCrMemo(SalesHeader, SalesCreditMemo);

        // Execute
        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesCreditMemo."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateAggregateTable()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGuid, SalesHeader."Document Type"::"Credit Memo");
        CreatePostedCrMemoNoDiscount(SalesCrMemoHeader);
        SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true);
        SalesCrMemoEntityBuffer.Delete();
        SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);
        SalesCrMemoEntityBuffer.Delete();

        // Execute
        GraphMgtSalCrMemoBuf.UpdateBufferTableRecords();

        // Verify
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
        VerifyBufferTableIsUpdatedForPostedCrMemo(SalesCrMemoHeader."No.", DummySalesCrMemoEntityBuffer.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertSalesAggregate()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesHeader: Record "Sales Header";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        // Setup
        Initialize();

        UpdateSalesCrMemoAggregate(SalesCrMemoEntityBuffer, TempFieldBuffer);

        // Execute
        GraphMgtSalCrMemoBuf.PropagateOnInsert(SalesCrMemoEntityBuffer, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No."), 'Could not find Sales Header');
        Assert.AreEqual(
          SalesHeader."Sell-to Customer No.", SalesCrMemoEntityBuffer."Sell-to Customer No.", 'Fields were not transferred');

        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPropagateModifySalesAggregate()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesHeader: Record "Sales Header";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        // Setup
        Initialize();
        CreateCrMemoWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);
        UpdateSalesCrMemoAggregate(SalesCrMemoEntityBuffer, TempFieldBuffer);

        // Execute
        AnswerYesToAllConfirmDialogs();
        GraphMgtSalCrMemoBuf.PropagateOnModify(SalesCrMemoEntityBuffer, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No."), 'Could not find Sales Header');
        Assert.AreEqual(
          SalesHeader."Sell-to Customer No.", SalesCrMemoEntityBuffer."Sell-to Customer No.", 'Fields were not transferred');

        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteSalesAggregate()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGuid, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);

        // Execute
        GraphMgtSalCrMemoBuf.PropagateOnDelete(SalesCrMemoEntityBuffer);

        // Verify
        Assert.IsFalse(SalesHeader.Find(), 'Sales header should be deleted');
        Assert.IsFalse(SalesCrMemoEntityBuffer.Find(), 'Sales line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteSalesAggregatePostedCrMemo()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        // Setup
        Initialize();

        CreatePostedCrMemoNoDiscount(SalesCrMemoHeader);
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesCrMemoHeader."Posting Date" + 1);
        SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true);

        // Execute
        GraphMgtSalCrMemoBuf.PropagateOnDelete(SalesCrMemoEntityBuffer);

        // Verify
        Assert.IsFalse(SalesCrMemoHeader.Find(), 'Sales header should be deleted');
        Assert.IsFalse(SalesCrMemoEntityBuffer.Find(), 'Sales line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertSalesLineTrhowsAnErrorIfDocumentIDNotSpecified()
    var
        SalesHeader: Record "Sales Header";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        UpdateSalesCrMemoLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        asserterror GraphMgtSalCrMemoBuf.PropagateInsertLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Verify
        Assert.ExpectedError(DocumentIDNotSpecifiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertSalesLineTrhowsAnErrorIfMultipleDocumentIdsFound()
    var
        SalesHeader: Record "Sales Header";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");

        TempSalesInvoiceLineAggregate.SetFilter("Document Id", '<>%1', ExpectedGUID);
        UpdateSalesCrMemoLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        asserterror GraphMgtSalCrMemoBuf.PropagateInsertLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Verify
        Assert.ExpectedError(MultipleDocumentsFoundForIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateModifySalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        GraphMgtSalCrMemoBuf.LoadLines(TempSalesInvoiceLineAggregate, SalesHeader.SystemId);
        TempSalesInvoiceLineAggregate.FindFirst();
        UpdateSalesCrMemoLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        GraphMgtSalCrMemoBuf.PropagateModifyLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesHeader."No.", TempSalesInvoiceLineAggregate."Line No."),
          'Sales line was updated');
        Assert.AreEqual(SalesLine."No.", TempSalesInvoiceLineAggregate."No.", 'No. was not set');
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteAggregateLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeaderWithID(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::"Credit Memo");
        GraphMgtSalCrMemoBuf.LoadLines(TempSalesInvoiceLineAggregate, SalesHeader.SystemId);
        TempSalesInvoiceLineAggregate.FindFirst();

        // Execute
        GraphMgtSalCrMemoBuf.PropagateDeleteLine(TempSalesInvoiceLineAggregate);

        // Verify
        Assert.IsFalse(
          SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesHeader."No.", TempSalesInvoiceLineAggregate."Line No."),
          'Sales line was not deleted');
        VerifyBufferTableIsUpdatedForCrMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConsolidationTrialBalanceReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyBusinessUnitEntriesOnConsolidatedTrialBalanceReport()
    var
        AccountingPeriod: Record "Accounting Period";
        BusinessUnit: array[2] of Record "Business Unit";
        GenJnlLine: array[2] of Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Amount: Decimal;
    begin
        // [SCENARIO 467338] Consolidated Trial Balance (Report 17) filtering not working
        Initialize();

        // [GIVEN] No Accounting periods/Fiscal years setup
        AccountingPeriod.DeleteAll();

        // [GIVEN] Create 2 new Business Units with Company set to current company
        LibraryERM.CreateBusinessUnit(BusinessUnit[1]);
        LibraryERM.CreateBusinessUnit(BusinessUnit[2]);
        BusinessUnit[2].Validate("Company Name", CompanyName);
        BusinessUnit[2].Validate("Starting Date", WorkDate());
        BusinessUnit[2].Modify(true);

        // [GIVEN] Create new G/L Account and enqueue G/L Account "No." field value
        CreateGLAccountWithConsolidationSetup(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");

        // [GIVEN] Create new journal entry to post with Business Unit Code 1
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJnlLine[1],
            "Gen. Journal Account Type"::"G/L Account",
            GenJnlLine[1]."Account Type"::"G/L Account",
            GLAccount."No.",
            Amount);

        // [THEN] Update Business Unit Code 1 to Gen. Journal Line and Post the Journal
        GenJnlLine[1].Validate("Business Unit Code", BusinessUnit[1].Code);
        GenJnlLine[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine[1]);

        // [GIVEN] Create new journal entry to post with Business Unit Code 2
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJnlLine[2],
            "Gen. Journal Account Type"::"G/L Account",
            GenJnlLine[2]."Account Type"::"G/L Account",
            GLAccount."No.",
            Amount);

        // [THEN] Update Business Unit Code 2 to Gen. Journal Line and Post the Journal
        GenJnlLine[2].Validate("Business Unit Code", BusinessUnit[2].Code);
        GenJnlLine[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine[2]);
        Commit();

        // [WHEN] Report "Consolidated Trial Balance" is run
        REPORT.Run(Report::"Consolidated Trial Balance", true, false, GLAccount);

        // [VERIFY] Verify: Business Unit Entries in generated report dataset
        VerifyBusinessUnitSpecificEntries(GLAccount."No.", Amount, BusinessUnit);
    end;

    [Test]
    [HandlerFunctions('ConsolidationTrialBalanceWithBusinessUnitFilterReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyBusinessUnitFilteringWorkingOnConsolidatedTrialBalanceReport()
    var
        AccountingPeriod: Record "Accounting Period";
        BusinessUnit: array[2] of Record "Business Unit";
        GenJnlLine: array[2] of Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Amount: Decimal;
    begin
        // [SCENARIO 467338] Consolidated Trial Balance (Report 17) filtering not working
        Initialize();

        // [GIVEN] No Accounting periods/Fiscal years setup
        AccountingPeriod.DeleteAll();

        // [GIVEN] Create 2 new Business Units with Company set to current company
        LibraryERM.CreateBusinessUnit(BusinessUnit[1]);
        LibraryERM.CreateBusinessUnit(BusinessUnit[2]);
        BusinessUnit[2].Validate("Company Name", CompanyName);
        BusinessUnit[2].Validate("Starting Date", WorkDate());
        BusinessUnit[2].Modify(true);

        // [GIVEN] Create new G/L Account
        CreateGLAccountWithConsolidationSetup(GLAccount);

        // [GIVEN] Create new journal entry to post with Business Unit Code 1
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJnlLine[1],
            "Gen. Journal Account Type"::"G/L Account",
            GenJnlLine[1]."Account Type"::"G/L Account",
            GLAccount."No.",
            Amount);

        // [THEN] Update Business Unit Code 1 to Gen. Journal Line and Post the Journal
        GenJnlLine[1].Validate("Business Unit Code", BusinessUnit[1].Code);
        GenJnlLine[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine[1]);

        // [GIVEN] Create and Post journal entries with Business Unit Code 2
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine[2], "Gen. Journal Account Type"::"G/L Account", GenJnlLine[2]."Account Type"::"G/L Account", GLAccount."No.", Amount);

        // [THEN] Update Business Unit Code 2 to Gen. Journal Line and Post the Journal
        GenJnlLine[2].Validate("Business Unit Code", BusinessUnit[2].Code);
        GenJnlLine[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine[2]);

        // [THEN] Enqueue G/L Account "No." field value and Business Unit Code 1
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        LibraryVariableStorage.Enqueue(BusinessUnit[1].Code);
        Commit();

        // [WHEN] Report "Consolidated Trial Balance" is run
        REPORT.Run(Report::"Consolidated Trial Balance", true, false, GLAccount);

        // [VERIFY] Verify: Business Unit Entries in generated report dataset
        VerifyFilteredBusinessUnitSpecificEntries(GLAccount."No.", Amount, BusinessUnit);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OpenSalesStatisticsPage')]
    procedure VerifyTotalTaxAmountSameonStats()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesStatistics: TestPage "Sales Statistics";
        UnitPrice: array[4] of Decimal;
        Quantity: array[4] of Integer;
        ExpectedTaxAmount: Decimal;
        ActualTaxAmount: Decimal;
    begin
        // [SCENARIO 524113] Correct VAT in Statistics FactBox when "Price Including VAT" is activated.
        Initialize();

        // [GIVEN] Create VAT Posting Setup with VAT Percentage 20
        CreateVATPostingSetup(VATPostingSetup, 20);

        // [GIVEN] Create Static Unit Price to get the 0.01 difference
        AssignStaticValues524113(UnitPrice, Quantity);

        // [GIVEN] Create Four Sales Credit Memo Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesCreditMemo, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesStatistics.Trap();
        SalesCreditMemo.Statistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Credit Memo and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OpenSalesStatisticsPage')]
    procedure VerifyTotalTaxAmountSameonSalesCreditMemoAndSalesStatistics()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesStatistics: TestPage "Sales Statistics";
        UnitPrice: array[3] of Decimal;
        Quantity: array[3] of Integer;
        ExpectedTaxAmount: Decimal;
        ActualTaxAmount: Decimal;
    begin
        // [SCENARIO 502847] Correct VAT in Statistics FactBox when "Price Including VAT" is activated.
        Initialize();

        // [GIVEN] Create VAT Posting Setup with VAT Percentage 7
        CreateVATPostingSetup(VATPostingSetup, 7);

        // [GIVEN] Create Static Unit Price to get the 0.01 difference
        AssignStaticValues502847(UnitPrice, Quantity);

        // [GIVEN] Create Four Sales Credit Memo Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesCreditMemo, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesStatistics.Trap();
        SalesCreditMemo.Statistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Credit Memo and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    procedure VerifyTotalTaxAmountSameOnStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        UnitPrice: array[4] of Decimal;
        Quantity: array[4] of Integer;
        ExpectedTaxAmount: Decimal;
        ActualTaxAmount: Decimal;
    begin
        // [SCENARIO 524113] Correct VAT in Statistics FactBox when "Price Including VAT" is activated.
        Initialize();

        // [GIVEN] Create VAT Posting Setup with VAT Percentage 20
        CreateVATPostingSetup(VATPostingSetup, 20);

        // [GIVEN] Create Static Unit Price to get the 0.01 difference
        AssignStaticValues524113(UnitPrice, Quantity);

        // [GIVEN] Create Four Sales Credit Memo Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesCreditMemo, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesCreditMemo.SalesStatistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Credit Memo and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    procedure VerifyTotalTaxAmountSameonSalesCreditMemoAndSalesStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        UnitPrice: array[3] of Decimal;
        Quantity: array[3] of Integer;
        ExpectedTaxAmount: Decimal;
        ActualTaxAmount: Decimal;
    begin
        // [SCENARIO 502847] Correct VAT in Statistics FactBox when "Price Including VAT" is activated.
        Initialize();

        // [GIVEN] Create VAT Posting Setup with VAT Percentage 7
        CreateVATPostingSetup(VATPostingSetup, 7);

        // [GIVEN] Create Static Unit Price to get the 0.01 difference
        AssignStaticValues502847(UnitPrice, Quantity);

        // [GIVEN] Create Four Sales Credit Memo Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesCreditMemo, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesCreditMemo.SalesStatistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Credit Memo and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; minAmount: Decimal)
    begin
        CreateCustomer(Customer);
        AddCrMemoDiscToCustomer(Customer, minAmount, DiscPct);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := Customer."No.";
        Customer.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageDiscountTypePCT(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateCrMemoWithOneLineThroughTestPage(SalesCreditMemo, Customer, Item);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageDiscountTypeAMT(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        Customer: Record Customer;
        Item: Record Item;
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, CrMemoDiscountAmount);
        CreateCrMemoWithOneLineThroughTestPage(SalesCreditMemo, Customer, Item);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(CrMemoDiscountAmount);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPageNoDiscount(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateCustomer(Customer);
        CreateCrMemoWithOneLineThroughTestPage(SalesCreditMemo, Customer, Item);
    end;

    local procedure CreateCrMemoWithOneLineThroughTestPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; Customer: Record Customer; Item: Record Item)
    begin
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");

        CreateLineThroughTestPage(SalesCreditMemo, Item."No.");
    end;

    local procedure CreateLineThroughTestPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; ItemNo: Text)
    var
        ItemQuantity: Decimal;
    begin
        SalesCreditMemo.SalesLines.Last();
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines."No.".SetValue(ItemNo);

        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
    end;

    local procedure CreateSalesHeaderWithID(var SalesHeader: Record "Sales Header"; var ExpectedGUID: Guid; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        ExpectedGUID := SalesHeader.SystemId;
    end;

    local procedure CreatePostedInvoiceDiscountTypePct(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreatePostedCrMemoDiscountTypePct(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreatePostedCrMemoDiscountTypeAmt(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, CrMemoDiscountAmount);

        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(CrMemoDiscountAmount, SalesHeader);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreatePostedCrMemoNoDiscount(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateCrMemoWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndCancelPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var NewSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CreatePostedInvoiceDiscountTypePct(SalesInvoiceHeader);

        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        NewSalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        NewSalesCrMemoHeader.FindLast();
    end;

    local procedure CreateAndCancelPostedCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var NewSalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        CreateAndCancelPostedInvoice(SalesInvoiceHeader, SalesCrMemoHeader);
        CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader);
        NewSalesInvoiceHeader.SetRange("Bill-to Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        NewSalesInvoiceHeader.FindLast();
    end;

    local procedure CreateAndMarkPostedCrMemoAsPaid(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreatePostedCrMemoDiscountTypePct(SalesCrMemoHeader);

        CustLedgerEntry.SetRange("Entry No.", SalesCrMemoHeader."Cust. Ledger Entry No.");
        CustLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure CreateCrMemoWithLinesThroughCodeNoDiscount(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateCustomer(Customer);
        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);
    end;

    local procedure CreateCrMemoWithLinesThroughCodeDiscountPct(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);

        SalesHeader.Find();
        SalesLine.Find();
    end;

    local procedure CreateCrMemoWithLinesThroughCodeDiscountAmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CrMemoDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, CrMemoDiscountAmount);
        CreateCrMemoWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(CrMemoDiscountAmount, SalesHeader);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure CreateInvoiceWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
        ItemQuantity: Decimal;
        NumberOfLines: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(3, 10);
        ItemQuantity := LibraryRandom.RandIntInRange(10, 100);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateCrMemoWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
        ItemQuantity: Decimal;
        NumberOfLines: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(3, 10);
        ItemQuantity := LibraryRandom.RandIntInRange(10, 100);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure OpenSalesCrMemo(SalesHeader: Record "Sales Header"; var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure GetSalesCrMemoAggregateLines(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary)
    var
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        GraphMgtSalCrMemoBuf.LoadLines(TempSalesInvoiceLineAggregate, SalesCrMemoEntityBuffer.Id);
        TempSalesInvoiceLineAggregate.Reset();
    end;

    local procedure AddCrMemoDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", Percentage);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var Customer: Record Customer)
    var
        ItemUnitPrice: Decimal;
        DiscPct: Decimal;
        MinAmt: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitPrice);
        CreateCustomerWithDiscount(Customer, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var Customer: Record Customer; var CrMemoDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemUnitPrice: Decimal;
    begin
        SetAllowManualDisc();

        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CrMemoDiscountAmount := LibraryRandom.RandDecInRange(1, 1000, 2);

        if GeneralLedgerSetup.UseVat() then begin
            Customer."Prices Including VAT" := true;
            Customer.Modify();
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
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", false);
        SalesReceivablesSetup.Modify(true);
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
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", DocumentNo);
        SalesCrMemoEntityBuffer.Get(DocumentNo, false);

        VerifyBufferTableIsUpdated(SalesHeader, SalesCrMemoEntityBuffer);
        Assert.AreEqual(SalesCrMemoEntityBuffer.Status::Draft, SalesCrMemoEntityBuffer.Status, 'Wrong status set');

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetFilter(Type, '<>'' ''');
        VerifyLinesMatch(SalesLine, SalesCrMemoEntityBuffer);
    end;

    local procedure VerifyBufferTableIsUpdatedForPostedCrMemo(DocumentNo: Text; ExpectedStatus: Enum "Sales Cr. Memo Entity Buffer Status")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoEntityBuffer.Get(DocumentNo, true);

        VerifyBufferTableIsUpdated(SalesCrMemoHeader, SalesCrMemoEntityBuffer);
        Assert.AreEqual(ExpectedStatus, SalesCrMemoEntityBuffer.Status, 'Wrong status set');

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");

        VerifyLinesMatch(SalesCrMemoLine, SalesCrMemoEntityBuffer);
    end;

    local procedure VerifyBufferTableIsUpdated(SourceRecordVariant: Variant; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    begin
        ValidateTotalsMatch(SourceRecordVariant, SalesCrMemoEntityBuffer);
        VerifyTransferredFieldsMatch(SourceRecordVariant, SalesCrMemoEntityBuffer);
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

    local procedure VerifyLinesMatch(SourceRecordLines: Variant; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        LinesRecordRef: RecordRef;
    begin
        GetSalesCrMemoAggregateLines(SalesCrMemoEntityBuffer, TempSalesInvoiceLineAggregate);
        DataTypeManagement.GetRecordRef(SourceRecordLines, LinesRecordRef);

        Assert.AreEqual(LinesRecordRef.Count, TempSalesInvoiceLineAggregate.Count, 'Wrong number of lines');
        if LinesRecordRef.Count = 0 then
            exit;

        TempSalesInvoiceLineAggregate.FindFirst();
        LinesRecordRef.FindFirst();
        repeat
            VerifyLineValuesMatch(LinesRecordRef, TempSalesInvoiceLineAggregate, SalesCrMemoEntityBuffer.Posted);
            TempSalesInvoiceLineAggregate.Next();
        until LinesRecordRef.Next() = 0;
    end;

    local procedure VerifyLineValuesMatch(var SourceRecordRef: RecordRef; var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary; Posted: Boolean)
    var
        TempField: Record "Field" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceFieldRef: FieldRef;
        AggregateLineFieldRef: FieldRef;
        TaxId: Guid;
    begin
        GetFieldsThatMustMatchWithSalesLine(TempField);

        if Posted then
            FilterOutFieldsMissingOnSalesCrMemoLine(TempField);
        TempField.FindFirst();
        repeat
            AggregateLineFieldRef := SourceRecordRef.Field(TempField."No.");
            SourceFieldRef := SourceRecordRef.Field(TempField."No.");
            Assert.AreEqual(
              Format(SourceFieldRef.Value), Format(AggregateLineFieldRef.Value),
              StrSubstNo('Value did not match for field no. %1', TempField."No."));
        until TempField.Next() = 0;

        if GeneralLedgerSetup.UseVat() then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("VAT Prod. Posting Group"));
            if VATProductPostingGroup.Get(SourceFieldRef.Value) then
                TaxId := VATProductPostingGroup.SystemId;
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("VAT Identifier"))
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("Tax Group Code"));
            if TaxGroup.Get(SourceFieldRef.Value) then
                TaxId := TaxGroup.SystemId
        end;

        Assert.AreEqual(Format(SourceFieldRef.Value), Format(TempSalesInvoiceLineAggregate."Tax Code"), 'Tax code did not match');
        Assert.AreEqual(Format(TaxId), Format(TempSalesInvoiceLineAggregate."Tax Id"), 'Tax ID did not match');

        if TempSalesInvoiceLineAggregate.Type <> TempSalesInvoiceLineAggregate.Type::Item then
            exit;

        DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("No."));
        Item.Get(SourceFieldRef.Value);
        Assert.AreEqual(TempSalesInvoiceLineAggregate."Item Id", Item.SystemId, 'Item ID was not set');
        Assert.IsFalse(IsNullGuid(Item.SystemId), 'Item ID was not set');
        Assert.AreNearlyEqual(
          TempSalesInvoiceLineAggregate."Tax Amount",
          TempSalesInvoiceLineAggregate."Amount Including VAT" - TempSalesInvoiceLineAggregate.Amount,
          0.01, 'Tax amount is not correct');
    end;

    local procedure ValidateTotalsMatch(SourceRecord: Variant; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DataTypeManagement: Codeunit "Data Type Management";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        SourceRecordRef: RecordRef;
        ExpectedCrMemoDiscountAmount: Decimal;
        ExpectedTotalInclTaxAmount: Decimal;
        ExpectedTotalExclTaxAmount: Decimal;
        ExpectedTaxAmountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        DataTypeManagement.GetRecordRef(SourceRecord, SourceRecordRef);
        case SourceRecordRef.Number of
            DATABASE::"Sales Header":
                begin
                    SalesCreditMemo.OpenEdit();
                    Assert.IsTrue(SalesCreditMemo.GotoRecord(SourceRecord), 'Could not navigate to credit memo');
                    if SalesCreditMemo.SalesLines."Invoice Discount Amount".Visible() then
                        ExpectedCrMemoDiscountAmount := SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal();
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
                    SalesLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");
                    NumberOfLines := SalesLine.Count();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    PostedSalesCreditMemo.OpenEdit();
                    Assert.IsTrue(PostedSalesCreditMemo.GotoRecord(SourceRecord), 'Could not navigate to invoice');
                    ExpectedCrMemoDiscountAmount := PostedSalesCreditMemo.SalesCrMemoLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := PostedSalesCreditMemo.SalesCrMemoLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := PostedSalesCreditMemo.SalesCrMemoLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := PostedSalesCreditMemo.SalesCrMemoLines."Total Amount Incl. VAT".AsDecimal();
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");
                    NumberOfLines := SalesCrMemoLine.Count();
                end;
        end;

        SalesCrMemoEntityBuffer.Find();

        if NumberOfLines > 0 then
            Assert.IsTrue(ExpectedTotalExclTaxAmount > 0, 'One amount must be greated than zero');
        Assert.AreEqual(
          ExpectedCrMemoDiscountAmount, SalesCrMemoEntityBuffer."Invoice Discount Amount", 'Invoice discount amount is not correct');
        Assert.AreEqual(ExpectedTaxAmountAmount, SalesCrMemoEntityBuffer."Total Tax Amount", 'Total Tax Amount is not correct');
        Assert.AreEqual(ExpectedTotalExclTaxAmount, SalesCrMemoEntityBuffer.Amount, 'Amount is not correct');
        Assert.AreEqual(
          ExpectedTotalInclTaxAmount, SalesCrMemoEntityBuffer."Amount Including VAT", 'Amount Including VAT is not correct');
    end;

    local procedure GetFieldsThatMustMatchWithSalesHeader(var TempField: Record "Field" temporary)
    begin
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
         DummySalesCrMemoEntityBuffer.FieldNo("Posting Date"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Payment Terms Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Shipment Method Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Due Date"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Customer Posting Group"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Currency Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Prices Including VAT"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Salesperson Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Recalculate Invoice Disc."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo(Amount), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Amount Including VAT"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer Name"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address 2"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Sell-to City"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Post Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to County"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Country/Region Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Phone No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to E-Mail"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Name"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address 2"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Bill-to City"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Contact"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Post Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to County"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Country/Region Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Customer No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Document Date"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Cust. Ledger Entry No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Shipping Advice"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Completely Shipped"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Requested Delivery Date"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("External Document No."), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Reason Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Shortcut Dimension 1 Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Shortcut Dimension 2 Code"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
    end;

    local procedure GetFieldsThatMustMatchWithSalesLine(var TempField: Record "Field" temporary)
    var
        DummySalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
    begin
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Line No."), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo(Type), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("No."), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Shipment Date"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo(Description), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Description 2"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo(Quantity), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Unit Price"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("VAT %"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Inv. Discount Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Line Discount %"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Discount Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo(Amount), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Amount Including VAT"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Currency Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("VAT Base Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Line Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("VAT Prod. Posting Group"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Tax Group Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Unit of Measure Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Qty. to Invoice"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Qty. to Ship"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Quantity Invoiced"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Quantity Shipped"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Discount Calculation"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Variant Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Location Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
    end;

    local procedure GetCrMemoAggregateSpecificFields(var TempField: Record "Field" temporary)
    begin
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Total Tax Amount"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo(Status), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo(Posted), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Last Modified Date Time"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Customer Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Contact Graph Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Currency Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Payment Terms Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Shipment Method Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(
          DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Customer Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo("Reason Code Id"), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
        AddFieldToBuffer(DummySalesCrMemoEntityBuffer.FieldNo(Id), DATABASE::"Sales Cr. Memo Entity Buffer", TempField);
    end;

    local procedure GetCrMemoAggregateLineSpecificFields(var TempField: Record "Field" temporary)
    var
        DummySalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
    begin
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Tax Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Tax Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Tax Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Discount Applied Before Tax"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Item Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Document Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("API Type"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Account Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Amount Excluding Tax"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Amount Including Tax"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Prices Including Tax"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Tax Amount"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Inv. Discount Amount Excl. VAT"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Unit of Measure Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Line Discount Value"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo(Id), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Variant Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceLineAggregate.FieldNo("Location Id"), DATABASE::"Sales Invoice Line Aggregate", TempField);
    end;

    local procedure AddFieldToBuffer(FieldNo: Integer; TableID: Integer; var TempField: Record "Field" temporary)
    var
        "Field": Record "Field";
    begin
        Field.Get(TableID, FieldNo);
        TempField.TransferFields(Field, true);
        TempField.Insert();
    end;

    local procedure UpdateSalesCrMemoAggregate(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        SalesCrMemoEntityBuffer.Validate("Sell-to Customer No.", Customer."No.");
        RegisterFieldSet(TempFieldBuffer, SalesCrMemoEntityBuffer.FieldNo("Sell-to Customer No."));
    end;

    local procedure UpdateSalesCrMemoLineAggregate(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        SalesInvoiceLineAggregate.Type := SalesInvoiceLineAggregate.Type::Item;
        SalesInvoiceLineAggregate.Validate("No.", Item."No.");

        RegisterFieldSet(TempFieldBuffer, SalesInvoiceLineAggregate.FieldNo(Type));
        RegisterFieldSet(TempFieldBuffer, SalesInvoiceLineAggregate.FieldNo("No."));
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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Cr. Memo Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure CreateGLAccountWithConsolidationSetup(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Consol. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Validate("Consol. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Modify(true);
    end;

    local procedure VerifyBusinessUnitSpecificEntries(GLAccountNo: Code[20]; Amount: Decimal; BusinessUnit: array[2] of Record "Business Unit")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAcc', Format(GLAccountNo));
        LibraryReportDataset.SetRange('GLAccIndentation22Code', '  ' + Format(BusinessUnit[1].Code));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GLBalance', Amount);
        LibraryReportDataset.SetRange('No_GLAcc', Format(GLAccountNo));
        LibraryReportDataset.SetRange('GLAccIndentation22Code', '  ' + Format(BusinessUnit[2].Code));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GLBalance', Amount);
    end;

    local procedure VerifyFilteredBusinessUnitSpecificEntries(GLAccountNo: Code[20]; Amount: Decimal; BusinessUnit: array[2] of Record "Business Unit")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAcc', Format(GLAccountNo));
        LibraryReportDataset.SetRange('GLAccIndentation22Code', '  ' + Format(BusinessUnit[1].Code));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GLBalance', Amount);
        LibraryReportDataset.SetRange('No_GLAcc', Format(GLAccountNo));
        LibraryReportDataset.SetRange('GLAccIndentation22Code', '  ' + Format(BusinessUnit[2].Code));
        LibraryReportDataset.GetNextRow();
        asserterror LibraryReportDataset.AssertCurrentRowValueEquals('GLBalance', Amount);
    end;

    local procedure AssignStaticValues524113(var UnitPrice: array[4] of Decimal; Quantity: array[4] of Integer)
    var
        i: Integer;
    begin
        UnitPrice[1] := 68.28;
        UnitPrice[2] := 4.90;
        UnitPrice[3] := -4.90;
        UnitPrice[4] := 0.05;

        for i := 1 to ArrayLen(Quantity) do
            Quantity[i] := 1;
    end;

    local procedure AssignStaticValues502847(var UnitPrice: array[4] of Decimal; Quantity: array[4] of Integer)
    begin
        UnitPrice[1] := 56;
        UnitPrice[2] := 20;
        UnitPrice[3] := 50;

        Quantity[1] := 3;
        Quantity[2] := 4;
        Quantity[3] := 1;
    end;

    local procedure CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(var SalesCreditMemo: TestPage "Sales Credit Memo";
                                                                               VATPostingSetup: Record "VAT Posting Setup";
                                                                               UnitPrice: array[4] of Decimal;
                                                                               Quantity: array[4] of Integer)
    var
        Customer: Record Customer;
        Item: Record Item;
        i: Integer;
    begin
        CreateItemWithVATPostingSetup(Item, VATPostingSetup);
        CreateCustomerWithVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");

        for i := 1 to ArrayLen(UnitPrice) do
            CreateInvoiceWithMultipleLineThroughTestPage(SalesCreditMemo, Item."No.", UnitPrice[i], Quantity[i]);
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(var Customer: Record Customer; VATBusPostingGroup: Code[20])
    begin
        CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify();
    end;

    local procedure CreateItemWithVATPostingSetup(var Item: Record Item; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercentage);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Modify();
    end;

    local procedure CreateInvoiceWithMultipleLineThroughTestPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; ItemNo: Code[20]; UnitPrice: Decimal; Quantity: Integer)
    begin
        SalesCreditMemo.SalesLines.Last();
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines."No.".SetValue(ItemNo);
        SalesCreditMemo.SalesLines.Quantity.SetValue(Quantity);
        SalesCreditMemo.SalesLines."Unit Price".SetValue(UnitPrice);

        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTrialBalanceReportHandler(var ConsolidationmTrialBalance: TestRequestPage "Consolidated Trial Balance")
    var
        GLAccountNo: Variant;
    begin
        ConsolidationmTrialBalance.StartingDt.SetValue(WorkDate());
        ConsolidationmTrialBalance.EndingDt.SetValue(WorkDate());
        LibraryVariableStorage.Dequeue(GLAccountNo);
        ConsolidationmTrialBalance."G/L Account".SetFilter("No.", GLAccountNo);
        ConsolidationmTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTrialBalanceWithBusinessUnitFilterReportHandler(var ConsolidationmTrialBalance: TestRequestPage "Consolidated Trial Balance")
    var
        GLAccountNo: Variant;
        BusinessUnitCode: Variant;
    begin
        ConsolidationmTrialBalance.StartingDt.SetValue(WorkDate());
        ConsolidationmTrialBalance.EndingDt.SetValue(WorkDate());
        LibraryVariableStorage.Dequeue(GLAccountNo);
        LibraryVariableStorage.Dequeue(BusinessUnitCode);
        ConsolidationmTrialBalance."G/L Account".SetFilter("No.", GLAccountNo);
        ConsolidationmTrialBalance."G/L Account".SetFilter("Business unit Filter", Format(BusinessUnitCode));
        ConsolidationmTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Scope('OnPrem')]
    procedure FilterOutFieldsMissingOnSalesCrMemoLine(var TempCommonField: Record "Field" temporary)
    var
        DummySalesLine: Record "Sales Line";
    begin
        TempCommonField.SetFilter(
          "No.", '<>%1&<>%2&<>%3&<>%4&<>%5', DummySalesLine.FieldNo("Currency Code"), DummySalesLine.FieldNo("Qty. to Invoice"),
          DummySalesLine.FieldNo("Qty. to Ship"), DummySalesLine.FieldNo("Quantity Shipped"), DummySalesLine.FieldNo("Quantity Invoiced"));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OpenSalesStatisticsPage(var SalesStatistics: TestPage "Sales Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesStatistics.VATAmount.AsDecimal());
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesStatistics.VATAmount.AsDecimal());
    end;
}

