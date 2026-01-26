codeunit 134396 "ERM Sales Invoice Aggregate UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Sales]
        IsInitialized := false;
    end;

    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
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
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        APIMockEvents: Codeunit "API Mock Events";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        CalculateInvoiceDiscountQst: Label 'Do you want to calculate the invoice discount?';
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        SalesAccountIsMissingTxt: Label 'Sales Account is missing in General Posting Setup.';
        CogsAccountIsMissingTxt: Label 'COGS Account is missing in General Posting Setup.';
        SalesVatAccountIsMissingTxt: Label 'Sales VAT Account is missing in VAT Posting Setup.';
        DueDateMustBeUpdatedTxt: Label 'Due Date must be updated';
        TaxAmountErr: Label 'Tax Amount must be equal to %1', Comment = '%1= Expected Tax Amount';
        SalesStatisticsQtyErr: Label 'Sales Statistics Quantity must be equal to %1', Comment = '%1= Expected Quantity';

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Invoice Aggregate UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Invoice Aggregate UT");

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        if GeneralLedgerSetup.UseVat() then begin
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.CreateGeneralPostingSetupData();
        end;

        LibrarySales.SetStockoutWarning(false);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        DisableWarningOnClosingInvoice();

        Commit();

        BindSubscription(APIMockEvents);

        APIMockEvents.SetIsAPIEnabled(true);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Invoice Aggregate UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        // Execute
        CreateInvoiceWithOneLineThroughTestPageNoDiscount(SalesInvoice);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        // Execute
        CreateInvoiceWithOneLineThroughTestPageDiscountTypePCT(SalesInvoice);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        // Execute
        CreateInvoiceWithOneLineThroughTestPageDiscountTypeAMT(SalesInvoice);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesAggregateTableTotalsDiscountAmtTest()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();
        CreateInvoiceWithOneLineThroughTestPageDiscountTypePCT(SalesInvoice);
        InvoiceDiscountAmount := LibraryRandom.RandDecInDecimalRange(1, SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal() / 2, 1);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value());
        SalesLine.FindFirst();
        SalesLine."Recalculate Invoice Disc." := true;
        SalesLine.Modify();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value());
        SalesInvoice.Close();

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(InvoiceDiscountAmount);
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingLineUpdatesTotalsKeepsInvDiscTypeAmount()
    var
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountAmount: Decimal;
    begin
        // Setup
        Initialize();

        CreateInvoiceWithOneLineThroughTestPageDiscountTypeAMT(SalesInvoice);
        InvoiceDiscountAmount := SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal();

        // Execute
        CreateLineThroughTestPage(SalesInvoice, SalesInvoice.SalesLines."No.".Value());

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(InvoiceDiscountAmount);
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsNoDiscount()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithOneLineThroughTestPageNoDiscount(SalesInvoice);

        // Execute
        SalesInvoice.SalesLines.Quantity.SetValue(SalesInvoice.SalesLines.Quantity.AsDecimal() * 2);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountPct()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithOneLineThroughTestPageDiscountTypePCT(SalesInvoice);

        // Execute
        SalesInvoice.SalesLines."Line Amount".SetValue(Round(SalesInvoice.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesAggregateTableTotalsDiscountAmt()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithOneLineThroughTestPageDiscountTypePCT(SalesInvoice);

        // Execute
        SalesInvoice.SalesLines."Unit Price".SetValue(SalesInvoice.SalesLines."Unit Price".AsDecimal() * 2);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value());
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesTotalsKeepsInvDiscTypeAmount()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithOneLineThroughTestPageDiscountTypeAMT(SalesInvoice);

        // Execute
        SalesInvoice.SalesLines."Unit Price".SetValue(SalesInvoice.SalesLines."Unit Price".AsDecimal() * 2);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value());

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value());
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

        CreateInvoiceWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // Execute
        SalesLine.Delete(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");

        // Execute last
        SalesLine.FindLast();
        SalesLine.Delete(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
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

        CreateInvoiceWithLinesThroughCodeDiscountPct(SalesHeader, SalesLine);

        // Execute
        SalesLine.Delete(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineUpdatesTotalsDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithLinesThroughCodeDiscountAmt(SalesHeader, SalesLine);
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);

        // Execute
        SalesLine.Delete(true);
        SalesInvoiceAggregator.RedistributeInvoiceDiscounts(SalesInvoiceEntityAggregate);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
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

        CreateInvoiceWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
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

        CreateInvoiceWithLinesThroughCodeDiscountPct(SalesHeader, SalesLine);

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
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

        CreateInvoiceWithLinesThroughCodeDiscountAmt(SalesHeader, SalesLine);

        // Execute
        SalesLine.DeleteAll(true);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NewCustDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesInvoice."Sell-to Customer No.".SetValue(NewCustomer."No.");

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        // Execute
        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
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
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NewCustomerDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypeAmt(Item, Customer, InvoiceDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();

        // Execute
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        // Verify
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesInvoiceWithDiscountAmount()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedInvoiceDiscountTypeAmt(SalesInvoiceHeader);

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesInvoiceTransfersId()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();
        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);

        // Execute
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // Verify
        Assert.IsFalse(SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false), 'Draft Aggregated Invoice still exists');

        Assert.AreEqual(SalesHeader.SystemId, SalesInvoiceHeader."Draft Invoice SystemId", 'Posted Invoice ID is incorrect');
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Draft Invoice still exists');
        SalesInvoiceEntityAggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.IsFalse(IsNullGuid(SalesInvoiceEntityAggregate.Id), 'Id cannot be null');
        Assert.AreEqual(SalesInvoiceHeader."Draft Invoice SystemId", SalesInvoiceEntityAggregate.Id, 'Aggregate Invoice ID is incorrect');

        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", SalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingPostedInvoiceThroughCodeTransfersId()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        ExpectedGUID: Guid;
        TempGUID: Guid;
    begin
        // Setup
        Initialize();
        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);

        TempGUID := CreateGuid();
        SalesInvoiceHeader.TransferFields(SalesHeader, true);
        SalesInvoiceHeader."Pre-Assigned No." := SalesHeader."No.";
        SalesInvoiceHeader.SystemId := TempGUID;
        SalesInvoiceHeader.Insert(true, true);

        // Execute
        SalesHeader.Delete(true);

        // Verify
        Assert.IsFalse(SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false), 'Draft Aggregated Invoice still exists');

        SalesInvoiceHeader.Find();
        Assert.AreEqual(SalesHeader.SystemId, SalesInvoiceHeader."Draft Invoice SystemId", 'Posted Invoice ID is incorrect');
        Assert.IsFalse(SalesHeader.Find(), 'Draft Invoice still exists');
        SalesInvoiceEntityAggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.IsFalse(IsNullGuid(SalesInvoiceEntityAggregate.SystemId), 'Id cannot be null');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesInvoiceWithDiscountPrecentage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreatePostedInvoiceDiscountTypePct(SalesInvoiceHeader);

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        // Setup
        Initialize();

        CreateInvoiceWithLinesThroughCodeNoDiscount(SalesHeader);

        // Execute
        SalesHeader.Delete(true);

        // Verify
        Assert.IsFalse(SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        // Setup
        Initialize();
        CreatePostedInvoiceDiscountTypeAmt(SalesInvoiceHeader);

        // Execute
        SalesInvoiceHeader.Delete();

        // Verify
        Assert.IsFalse(SalesInvoiceEntityAggregate.Get(SalesInvoiceHeader."No.", true), 'Aggregate should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamePostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        NewCode: Code[10];
    begin
        // Setup
        Initialize();
        CreatePostedInvoiceNoDiscount(SalesInvoiceHeader);

        // Execute
        NewCode := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Rename(NewCode);

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(NewCode, DummySalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateMatchesSalesDocumentHeaders()
    var
        DummySalesHeader: Record "Sales Header";
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        TempInvoiceAggregateSpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        AggregateField: Record "Field";
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithSalesHeader(TempCommonField);
        GetInvoiceAggregateSpecificFields(TempInvoiceAggregateSpecificField);
        SetFieldFilters(AggregateField);

        // Execute and verify
        Assert.AreEqual(
          TempCommonField.Count + TempInvoiceAggregateSpecificField.Count, AggregateField.Count,
          'Update reflection test. There are fields that are not accounted.');

        TempCommonField.SetFilter(ObsoleteState, '<>%1', TempCommonField.ObsoleteState::Removed);
        TempCommonField.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4',
          DummySalesHeader.FieldNo("Document Type"),
          DummySalesHeader.FieldNo("Invoice Discount Calculation"),
          DummySalesHeader.FieldNo("Invoice Discount Value"),
          DummySalesHeader.FieldNo("Recalculate Invoice Disc."));
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Invoice Header", TempCommonField);

        TempCommonField.SetFilter(
          "No.", '<>%1&<>%2', DummySalesInvoiceHeader.FieldNo("Order No."), DummySalesInvoiceHeader.FieldNo("Cust. Ledger Entry No."));
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Header", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Header", TempInvoiceAggregateSpecificField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregateLineMatchesSalesDocumentLines()
    var
        TempInvoiceAggregateLineSpecificField: Record "Field" temporary;
        TempCommonField: Record "Field" temporary;
        AggregateLineRecordRef: RecordRef;
    begin
        // Setup
        Initialize();
        GetFieldsThatMustMatchWithSalesLine(TempCommonField);
        GetInvoiceAggregateLineSpecificFields(TempInvoiceAggregateLineSpecificField);

        // Execute and verify
        AggregateLineRecordRef.Open(DATABASE::"Sales Invoice Line Aggregate");
        Assert.AreEqual(TempCommonField.Count + TempInvoiceAggregateLineSpecificField.Count,
          AggregateLineRecordRef.FieldCount,
          'Update reflection test. There are fields that are not accounted.');

        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Line", TempInvoiceAggregateLineSpecificField);

        FilterOutFieldsMissingOnSalesInvoiceLine(TempCommonField);
        VerifyFieldDefinitionsMatchTableFields(DATABASE::"Sales Invoice Line", TempCommonField);
        VerifyFieldDefinitionsDontExistInTargetTable(DATABASE::"Sales Invoice Line", TempInvoiceAggregateLineSpecificField);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSalesQuoteToInvoiceCreatesAggregate()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Quote);
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        LibraryVariableStorage.Enqueue('invoice');
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue('converted');
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.Trap();

        // Execute
        SalesQuote.MakeInvoice.Invoke();

        // Verify
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value());

        Assert.IsTrue(SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false), 'Sales Invoice Aggregate was not created');

        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelingPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup
        Initialize();

        // Execute
        CreateAndCancelPostedInvoice(SalesInvoiceHeader, NewSalesCrMemoHeader);

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectingCancelledPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectiveSalesInvoiceHeader: Record "Sales Invoice Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // Setup
        Initialize();
        CreateAndCancelPostedInvoice(SalesInvoiceHeader, NewSalesCrMemoHeader);

        // Execute
        CancelPostedSalesCrMemo.CancelPostedCrMemo(NewSalesCrMemoHeader);

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);

        CorrectiveSalesInvoiceHeader.SetRange("Applies-to Doc. No.", NewSalesCrMemoHeader."No.");
        CorrectiveSalesInvoiceHeader.FindFirst();

        VerifyAggregateTableIsUpdatedForPostedInvoice(
          CorrectiveSalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Corrective);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingCustomerLedgerEntry()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OpenCustLedgerEntry: Record "Cust. Ledger Entry";
        ClosedCustLedgerEntry: Record "Cust. Ledger Entry";
        UnpaidSalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup
        Initialize();
        CreateAndMarkPostedInvoiceAsPaid(SalesInvoiceHeader);
        CreatePostedInvoiceNoDiscount(UnpaidSalesInvoiceHeader);

        // Execute
        ClosedCustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        ClosedCustLedgerEntry.Delete();

        OpenCustLedgerEntry.SetRange("Entry No.", UnpaidSalesInvoiceHeader."Cust. Ledger Entry No.");
        OpenCustLedgerEntry.FindFirst();
        OpenCustLedgerEntry.Rename(SalesInvoiceHeader."Cust. Ledger Entry No.");

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);
        VerifyAggregateTableIsUpdatedForPostedInvoice(UnpaidSalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenamingCancelledDocument()
    var
        CancelledDocument: Record "Cancelled Document";
        CancelledSalesInvoiceHeader: Record "Sales Invoice Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup
        Initialize();
        CreateAndCancelPostedInvoice(CancelledSalesInvoiceHeader, NewSalesCrMemoHeader);
        CancelledDocument.Get(DATABASE::"Sales Invoice Header", CancelledSalesInvoiceHeader."No.");

        // Execute
        CancelledDocument.Rename(DATABASE::"Sales Header", CancelledDocument."Cancelled Doc. No.");

        // Verify
        VerifyAggregateTableIsUpdatedForPostedInvoice(CancelledSalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Paid);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();
        SetupDataForDiscountTypePct(Item, Customer);
        SetAllowManualDisc();

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        // Execute
        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesInvoice."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateAggregateTable()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGuid, SalesHeader."Document Type"::Invoice);
        CreatePostedInvoiceNoDiscount(SalesInvoiceHeader);
        SalesInvoiceEntityAggregate.Get(SalesInvoiceHeader."No.", true);
        SalesInvoiceEntityAggregate.Delete();
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);
        SalesInvoiceEntityAggregate.Delete();

        // Execute
        SalesInvoiceAggregator.UpdateAggregateTableRecords();

        // Verify
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
        VerifyAggregateTableIsUpdatedForPostedInvoice(SalesInvoiceHeader."No.", DummySalesInvoiceEntityAggregate.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertSalesAggregate()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesHeader: Record "Sales Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        // Setup
        Initialize();

        UpdateSalesInvoiceAggregate(SalesInvoiceEntityAggregate, TempFieldBuffer);

        // Execute
        SalesInvoiceAggregator.PropagateOnInsert(SalesInvoiceEntityAggregate, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceEntityAggregate."No."), 'Could not find Sales Header');
        Assert.AreEqual(
          SalesHeader."Sell-to Customer No.", SalesInvoiceEntityAggregate."Sell-to Customer No.", 'Fields were not transferred');

        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPropagateModifySalesAggregate()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesHeader: Record "Sales Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        // Setup
        Initialize();
        CreateInvoiceWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);
        UpdateSalesInvoiceAggregate(SalesInvoiceEntityAggregate, TempFieldBuffer);

        // Execute
        AnswerYesToAllConfirmDialogs();
        SalesInvoiceAggregator.PropagateOnModify(SalesInvoiceEntityAggregate, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceEntityAggregate."No."), 'Could not find Sales Header');
        Assert.AreEqual(
          SalesHeader."Sell-to Customer No.", SalesInvoiceEntityAggregate."Sell-to Customer No.", 'Fields were not transferred');

        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteSalesAggregate()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGuid: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGuid, SalesHeader."Document Type"::Invoice);
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);

        // Execute
        SalesInvoiceAggregator.PropagateOnDelete(SalesInvoiceEntityAggregate);

        // Verify
        Assert.IsFalse(SalesHeader.Find(), 'Sales header should be deleted');
        Assert.IsFalse(SalesInvoiceEntityAggregate.Find(), 'Sales line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteSalesAggregatePostedInvoice()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        // Setup
        Initialize();

        CreatePostedInvoiceNoDiscount(SalesInvoiceHeader);
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesInvoiceHeader."Posting Date" + 1);
        SalesInvoiceEntityAggregate.Get(SalesInvoiceHeader."No.", true);

        // Execute
        SalesInvoiceAggregator.PropagateOnDelete(SalesInvoiceEntityAggregate);

        // Verify
        Assert.IsFalse(SalesInvoiceHeader.Find(), 'Sales header should be deleted');
        Assert.IsFalse(SalesInvoiceEntityAggregate.Find(), 'Sales line should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateInsertSalesLineTrhowsAnErrorIfDocumentIDNotSpecified()
    var
        SalesHeader: Record "Sales Header";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        UpdateSalesInvoiceLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        asserterror SalesInvoiceAggregator.PropagateInsertLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

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
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);

        TempSalesInvoiceLineAggregate.SetFilter("Document Id", '<>%1', ExpectedGUID);
        UpdateSalesInvoiceLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        asserterror SalesInvoiceAggregator.PropagateInsertLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

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
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        SalesInvoiceAggregator.LoadLines(TempSalesInvoiceLineAggregate, SalesHeader.SystemId);
        TempSalesInvoiceLineAggregate.FindFirst();
        UpdateSalesInvoiceLineAggregate(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Execute
        SalesInvoiceAggregator.PropagateModifyLine(TempSalesInvoiceLineAggregate, TempFieldBuffer);

        // Verify
        Assert.IsTrue(
          SalesLine.Get(SalesLine."Document Type"::Invoice, SalesHeader."No.", TempSalesInvoiceLineAggregate."Line No."),
          'Sales line was updated');
        Assert.AreEqual(SalesLine."No.", TempSalesInvoiceLineAggregate."No.", 'No. was not set');
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPropagateDeleteAggregateLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        ExpectedGUID: Guid;
    begin
        // Setup
        Initialize();

        CreateSalesHeader(SalesHeader, ExpectedGUID, SalesHeader."Document Type"::Invoice);
        SalesInvoiceAggregator.LoadLines(TempSalesInvoiceLineAggregate, SalesHeader.SystemId);
        TempSalesInvoiceLineAggregate.FindFirst();

        // Execute
        SalesInvoiceAggregator.PropagateDeleteLine(TempSalesInvoiceLineAggregate);

        // Verify
        Assert.IsFalse(
          SalesLine.Get(SalesLine."Document Type"::Invoice, SalesHeader."No.", TempSalesInvoiceLineAggregate."Line No."),
          'Sales line was not deleted');
        VerifyAggregateTableIsUpdatedForInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceModifyWithCurrencyAndJobQueueStatus()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        Currency: Record Currency;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Batch Posting] [Background Posting] [UT]
        // [SCENARIO 328249] Ids stays the same (not updated) when modify sales header with "Job Queue Status" = "Posting" or "Scheduled for Posting" (batch posting emulation).
        // System skips "Sales Header" OnModify subscribers while batch posting ("Job Queue Status" updated to "Scheduled for Posting" or "Posting")
        Initialize();

        // [GIVEN] Currency
        LibraryERM.CreateCurrency(Currency);
        // [GIVEN] Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        // [GIVEN] Assigned "Currency Code" and "Job Queue Status" = "Scheduled for Posting"
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::"Scheduled for Posting";
        // [WHNE] Modify sales header (triggers OnModify subscribers)
        SalesHeader.Modify();
        Commit();

        // [THEN] Ids are empty (the same as before modify sales header) in sales invoice entity aggregate
        SalesInvoiceEntityAggregate.Reset();
        SalesInvoiceEntityAggregate.SetRange(Id, SalesHeader.SystemId);
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindFirst(), 'The unposted invoice should exist');
        Assert.AreEqual(ZeroGuid, SalesInvoiceEntityAggregate."Currency Id", 'The Id of the currency should be blank.');
        Assert.AreEqual('', SalesInvoiceEntityAggregate."Currency Code", 'The code of the currency should be blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderModifyWithCurrencyAndJobQueueStatus()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        Currency: Record Currency;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Batch Posting] [Background Posting] [UT]
        // [SCENARIO 328249] Ids stays the same (not updated) when modify sales header with "Job Queue Status" = "Posting" or "Scheduled for Posting" (batch posting emulation).
        // System skips "Sales Header" OnModify subscribers while batch posting ("Job Queue Status" updated to "Scheduled for Posting" or "Posting")
        Initialize();

        // [GIVEN] Currency
        LibraryERM.CreateCurrency(Currency);
        // [GIVEN] Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] Assigned "Currency Code" and "Job Queue Status" = "Scheduled for Posting"
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::"Scheduled for Posting";
        // [WHNE] Modify sales header (triggers OnModify subscribers)
        SalesHeader.Modify();
        Commit();

        // [THEN] Ids are empty (the same as before modify sales header) in sales order entity buffer
        SalesOrderEntityBuffer.Reset();
        SalesOrderEntityBuffer.SetRange(Id, SalesHeader.SystemId);
        Assert.IsTrue(SalesOrderEntityBuffer.FindFirst(), 'The unposted order should exist');
        Assert.AreEqual(ZeroGuid, SalesOrderEntityBuffer."Currency Id", 'The Id of the currency should be blank.');
        Assert.AreEqual('', SalesOrderEntityBuffer."Currency Code", 'The code of the currency should be blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoModifyWithCurrencyAndJobQueueStatus()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        Currency: Record Currency;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Batch Posting] [Background Posting] [UT]
        // [SCENARIO 328249] Ids stays the same (not updated) when modify sales header with "Job Queue Status" = "Posting" or "Scheduled for Posting" (batch posting emulation).
        // System skips "Sales Header" OnModify subscribers while batch posting ("Job Queue Status" updated to "Scheduled for Posting" or "Posting")
        Initialize();

        // [GIVEN] Currency
        LibraryERM.CreateCurrency(Currency);
        // [GIVEN] Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        // [GIVEN] Assigned "Currency Code" and "Job Queue Status" = "Scheduled for Posting"
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::"Scheduled for Posting";
        // [WHNE] Modify sales header (triggers OnModify subscribers)
        SalesHeader.Modify();
        Commit();

        // [THEN] Ids are empty (the same as before modify sales header) in sales credit memo entity buffer
        SalesCrMemoEntityBuffer.Reset();
        SalesCrMemoEntityBuffer.SetRange(Id, SalesHeader.SystemId);
        Assert.IsTrue(SalesCrMemoEntityBuffer.FindFirst(), 'The unposted credit memo should exist');
        Assert.AreEqual(ZeroGuid, SalesCrMemoEntityBuffer."Currency Id", 'The Id of the currency should be blank.');
        Assert.AreEqual('', SalesCrMemoEntityBuffer."Currency Code", 'The code of the currency should be blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceModifyWithCurrencyAndJobQueueStatus()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        LibraryPurchase: Codeunit "Library - Purchase";
        Currency: Record Currency;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Batch Posting] [Background Posting] [UT]
        // [SCENARIO 328249] Ids stays the same (not updated) when modify purchase header with "Job Queue Status" = "Posting" or "Scheduled for Posting" (batch posting emulation).
        // System skips "Purchase Header" OnModify subscribers while batch posting ("Job Queue Status" updated to "Scheduled for Posting" or "Posting")
        Initialize();

        // [GIVEN] Currency
        LibraryERM.CreateCurrency(Currency);
        // [GIVEN] Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        // [GIVEN] Assigned "Currency Code" and "Job Queue Status" = "Scheduled for Posting"
        PurchaseHeader."Currency Code" := Currency.Code;
        PurchaseHeader."Job Queue Status" := PurchaseHeader."Job Queue Status"::"Scheduled for Posting";
        // [WHNE] Modify purchase header (triggers OnModify subscribers)
        PurchaseHeader.Modify();
        Commit();

        // [THEN] Ids are empty (the same as before modify purchase header) in purchase invoice entity aggregate
        PurchInvEntityAggregate.Reset();
        PurchInvEntityAggregate.SetRange(Id, PurchaseHeader.SystemId);
        Assert.IsTrue(PurchInvEntityAggregate.FindFirst(), 'The unposted purchase invoice should exist');
        Assert.AreEqual(ZeroGuid, PurchInvEntityAggregate."Currency Id", 'The Id of the currency should be blank.');
        Assert.AreEqual('', PurchInvEntityAggregate."Currency Code", 'The code of the currency should be blank.');
    end;

    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineLimitedPermissionCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        Customer: Record Customer;
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [FEATURE] [Permissions]
        // [SCENARIO 325667] Sales Line without type is added when user has limited permissions.
        Initialize();

        // [GIVEN] Standard text.
        LibrarySales.CreateStandardText(StandardText);
        // [GIVEN] Enabled notification about missing G/L account.
        MyNotifications.InsertDefault(PostingSetupManagement.GetPostingSetupNotificationID(), '', '', true);
        // [GIVEN] Sales header.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Permisson to create sales invoices.
        LibraryLowerPermissions.SetSalesDocsCreate();

        // [WHEN] Add Sales Line with standard text, but whithout type.
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("No.", StandardText.Code);
        SalesLine.Insert(true);

        // [THEN] Sales line is created.
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineWithoutAccountCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [SCENARIO 325667] Notification is shown when Sales Line is added and G/L Account is missing in posting group.
        Initialize();

        // [GIVEN] Enabled notification about missing G/L account.
        MyNotifications.InsertDefault(PostingSetupManagement.GetPostingSetupNotificationID(), '', '', true);
        // [GIVEN] Sales header with "Gen. Business Posting Group" and "VAT Bus. Posting Group" are not in Posting Setup.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerrWithNewPostingGroups());

        // [WHEN] Add Purchase Line (SendNotificationHandler).
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [THEN] Notification "Sales Account is missing in General Posting Setup." is sent.
        Assert.ExpectedMessage(SalesAccountIsMissingTxt, LibraryVariableStorage.DequeueText());
        // [THEN] Notification "COGS Account is missing in General Posting Setup." is sent.
        Assert.ExpectedMessage(CogsAccountIsMissingTxt, LibraryVariableStorage.DequeueText());
        // [THEN] Notification "Sales VAT Account is missing in VAT Posting Setup." is sent.
        Assert.ExpectedMessage(SalesVatAccountIsMissingTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUpdateonPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        NewDueDate: Date;
    begin
        // [SCENARIO 539272] Suport update of Posted Sales Invoice
        Initialize();
        // [GIVEN] a Posted Sales Invocie ]
        CreatePostedInvoiceNoDiscount(SalesInvoiceHeader);

        // [WHEN] update "Due Date" on the document 
        TempFieldBuffer.DeleteAll();
        SalesInvoiceEntityAggregate.get(SalesInvoiceHeader."No.", true);
        NewDueDate := CalcDate('<+1D>', Today());
        SalesInvoiceEntityAggregate."Due Date" := NewDueDate;
        RegisterFieldSet(TempFieldBuffer, SalesInvoiceEntityAggregate.FieldNo("Due Date"));
        SalesInvoiceAggregator.PropagateOnModify(SalesInvoiceEntityAggregate, TempFieldBuffer);

        // [THEN] Due Date must be updated on the Posted Sales Invocie and the related Customer Ledger Entry
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindLast();
        Assert.AreEqual(NewDueDate, CustLedgerEntry."Due Date", DueDateMustBeUpdatedTxt);
    end;

    [Scope('OnPrem')]
    procedure VerifyUpdateonPostedInvoiceForANonWitheListedField()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        TempFieldBuffer: Record "Field Buffer" temporary;
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        NewBillToAddress: Text[100];
    begin
        // [SCENARIO 539272] Suport update of Posted Sales Invoice
        Initialize();
        // [GIVEN] a Posted Sales Invocie ]
        CreatePostedInvoiceNoDiscount(SalesInvoiceHeader);

        // [WHEN] update "Due Date" on the document 
        TempFieldBuffer.DeleteAll();
        SalesInvoiceEntityAggregate.get(SalesInvoiceHeader."No.", true);
        NewBillToAddress := LibraryUtility.GenerateRandomText(MaxStrLen(NewBillToAddress));
        SalesInvoiceEntityAggregate."Bill-to Address" := NewBillToAddress;
        RegisterFieldSet(TempFieldBuffer, SalesInvoiceEntityAggregate.FieldNo("Bill-to Address"));
        // [THEN] Update of Invoice should fail
        asserterror SalesInvoiceAggregator.PropagateOnModify(SalesInvoiceEntityAggregate, TempFieldBuffer);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OpenSalesStatisticsPage')]
    procedure VerifyTotalTaxAmountSameonStats()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
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

        // [GIVEN] Create Four Sales Invoice Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesInvoice, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesStatistics.Trap();
        SalesInvoice.Statistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Invoice and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    procedure VerifyTotalTaxAmountSamenStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
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

        // [GIVEN] Create Four Sales Invoice Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesInvoice, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesInvoice.SalesStatistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Invoice and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OpenSalesStatisticsPage')]
    procedure VerifyTotalTaxAmountSameonSalesInvoiceAndStatistics()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
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

        // [GIVEN] Create Four Sales Invoice Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesInvoice, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesStatistics.Trap();
        SalesInvoice.Statistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Invoice and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    procedure VerifyTotalTaxAmountSameonSalesInvoiceAndSalesStatistics()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
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

        // [GIVEN] Create Four Sales Invoice Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesInvoice, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ActualTaxAmount := SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();

        // [WHEN] Open Sales Statistics page to get the VAT Amount
        SalesInvoice.SalesStatistics.Invoke();
        ExpectedTaxAmount := LibraryVariableStorage.DequeueDecimal();

        // [THEN] Verify the Total Tax Amount on Sales Invoice and Sales Statistics page.
        Assert.AreEqual(ExpectedTaxAmount, ActualTaxAmount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalVATAmtIsNotZeroInSalesInvoicePageWhenSalesLineHavingVATPercentIsCreated()
    var
        Item: Record Item;
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 545351] When a Sales Line having VAT % is created then Total VAT Amount is not 0 in 
        // Sales Lines of Sales Invoice page if Default Item Quantity is set to true in Sales & Receivables page.
        Initialize();

        // [GIVEN] Set Default Item Quantity to true in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Default Item Quantity" := true;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create a VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Create a Customer with VAT Bus. Posting Group.
        CreateCustomerWithVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create an Item with VAT Posting Setup and Validate Unit Price.
        CreateItemWithVATPostingSetup(Item, VATPostingSetup);
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 100));
        Item.Modify(true);

        // [GIVEN] Open and create a Sales Invoice.
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer No.".SetValue(Customer."No.");

        // [WHEN] Create a Sales Line.
        SalesInvoice.SalesLines.Last();
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");

        // [THEN] Total VAT Amount must not be 0 in Sales Line of Sales Invoice.
        Assert.AreNotEqual(0, SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(), StrSubstNo(TaxAmountErr, 0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTotalTaxAmountSameOnGLEntries()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoice: TestPage "Sales Invoice";
        ExpectedTaxAmount: Decimal;
        DocumentNo: Text;
        PostedDocumentNo: Code[20];
        Quantity: array[4] of Integer;
        UnitPrice: array[4] of Decimal;
    begin
        // [SCENARIO 538876] Correct VAT in Statistics FactBox when "Price Including VAT" is activated.
        Initialize();

        // [GIVEN] In Sales Setup, Invoicing Rounding should be false.
        SalesSetup.Get();
        SalesSetup.Validate("Invoice Rounding", false);
        SalesSetup.Modify();

        // [GIVEN] Create VAT Posting Setup with VAT Percentage 20
        CreateVATPostingSetup(VATPostingSetup, 20);

        // [GIVEN] Create Static Unit Price to get the 0.01 difference
        AssignStaticValues524113(UnitPrice, Quantity);

        // [GIVEN] Create Four Sales Invoice Lines
        CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(SalesInvoice, VATPostingSetup, UnitPrice, Quantity);

        // [GIVEN] Save Total Tax Amount on Page as actual result
        ExpectedTaxAmount := -1 * SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();

        // [GIVEN] Save the Sales Invoice Document No.
        DocumentNo := SalesInvoice."No.".Value();

        // [GIVEN] Close the Sales Invoice Page
        SalesInvoice.Close();

        // [GIVEN] Get the Sales Header
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);

        // [WHEN] Post the Sales Document 
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Get the Sales VAT Account G/l Entries
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Sales VAT Account");
        GLEntry.FindFirst();

        // [THEN] Verify the Total tax amount should be same as on Sales Invoice Page
        Assert.AreEqual(ExpectedTaxAmount, GLEntry.Amount, StrSubstNo(TaxAmountErr, ExpectedTaxAmount));
    end;

    [Test]
    procedure SalesInvoiceStatisticShowsCorrectQuantityWithInvoiceRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        SalesStatistics: TestPage "Sales Statistics";
    begin
        // [SCENARIO 580156] Sales Invoice Statistic shows wrong quantity when invoice rounding is used.
        Initialize();

        // [GIVEN] Set Inv. Rounding Precision (LCY) as 0.05 in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 0.05);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create SalesHeader.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Line with Quantity as 1 and Unit Price Excl VAT as 1190.11.
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, LibraryInventory.CreateItemNo(), 1190.11, 1);

        // [WHEN] Open Sales Statistics page from Sales Invoice page.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesStatistics.Trap();
        SalesInvoice.SalesStatistics.Invoke();

        // [THEN] Verify Sales Invoice Statistics show Quantity as 1.
        Assert.AreEqual(1,
            SalesStatistics."TotalSalesLine.Quantity".AsDecimal(),
            StrSubstNo(SalesStatisticsQtyErr, 1));
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; minAmount: Decimal)
    begin
        CreateCustomer(Customer);
        AddInvoiceDiscToCustomer(Customer, minAmount, DiscPct);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := Customer."No.";
        Customer.Modify();
    end;

    local procedure CreateCustomerrWithNewPostingGroups(): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Customer.Init();
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Insert(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPageDiscountTypePCT(var SalesInvoice: TestPage "Sales Invoice")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateInvoiceWithOneLineThroughTestPage(SalesInvoice, Customer, Item);
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPageDiscountTypeAMT(var SalesInvoice: TestPage "Sales Invoice")
    var
        Customer: Record Customer;
        Item: Record Item;
        InvoiceDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, InvoiceDiscountAmount);
        CreateInvoiceWithOneLineThroughTestPage(SalesInvoice, Customer, Item);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPageNoDiscount(var SalesInvoice: TestPage "Sales Invoice")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateCustomer(Customer);
        CreateInvoiceWithOneLineThroughTestPage(SalesInvoice, Customer, Item);
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPage(var SalesInvoice: TestPage "Sales Invoice"; Customer: Record Customer; Item: Record Item)
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");

        CreateLineThroughTestPage(SalesInvoice, Item."No.");
    end;

    local procedure CreateLineThroughTestPage(var SalesInvoice: TestPage "Sales Invoice"; ItemNo: Text)
    var
        ItemQuantity: Decimal;
    begin
        SalesInvoice.SalesLines.Last();
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines."No.".SetValue(ItemNo);

        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; var ExpectedGUID: Guid; DocumentType: Enum "Sales Document Type")
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

    local procedure CreatePostedInvoiceDiscountTypeAmt(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        InvoiceDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreatePostedInvoiceNoDiscount(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateInvoiceWithLinesThroughCodeNoDiscount(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
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

    local procedure CreateAndMarkPostedInvoiceAsPaid(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreatePostedInvoiceDiscountTypePct(SalesInvoiceHeader);

        CustLedgerEntry.SetRange("Entry No.", SalesInvoiceHeader."Cust. Ledger Entry No.");
        CustLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure CreateInvoiceWithLinesThroughCodeNoDiscount(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        CreateCustomer(Customer);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);
    end;

    local procedure CreateInvoiceWithLinesThroughCodeDiscountPct(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        SetupDataForDiscountTypePct(Item, Customer);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);

        SalesHeader.Find();
        SalesLine.Find();
    end;

    local procedure CreateInvoiceWithLinesThroughCodeDiscountAmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        InvoiceDiscountAmount: Decimal;
    begin
        SetupDataForDiscountTypeAmt(Item, Customer, InvoiceDiscountAmount);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer);

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
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

    local procedure OpenSalesInvoice(SalesHeader: Record "Sales Header"; var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure GetSalesInvoiceAggregateLines(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate"; var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary)
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceAggregator.LoadLines(TempSalesInvoiceLineAggregate, SalesInvoiceEntityAggregate.Id);
        TempSalesInvoiceLineAggregate.Reset();
    end;

    local procedure AddInvoiceDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
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

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var Customer: Record Customer; var InvoiceDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemUnitPrice: Decimal;
    begin
        SetAllowManualDisc();

        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, 1000, 2);

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

    local procedure DisableWarningOnClosingInvoice()
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
            if not SkipValidation(SourceTableID, TempField."No.") then begin
                SourceTableFieldRef := RecRef.Field(TempField."No.");
                TargetTableFieldRef := TargetTableRecRef.Field(TempField."No.");
                ValidateFieldDefinitionsMatch(SourceTableFieldRef, TargetTableFieldRef);
            end;
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
            if not SkipValidation(TableID, TempField."No.") then
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

    local procedure VerifyAggregateTableIsUpdatedForInvoice(DocumentNo: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
        SalesInvoiceEntityAggregate.Get(DocumentNo, false);

        VerifyAggregateTableIsUpdated(SalesHeader, SalesInvoiceEntityAggregate);
        Assert.AreEqual(SalesInvoiceEntityAggregate.Status::Draft, SalesInvoiceEntityAggregate.Status, 'Wrong status set');

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetFilter(Type, '<>'' ''');
        VerifyLinesMatch(SalesLine, SalesInvoiceEntityAggregate);
    end;

    local procedure VerifyAggregateTableIsUpdatedForPostedInvoice(DocumentNo: Text; ExpectedStatus: Enum "Invoice Entity Aggregate Status")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceEntityAggregate.Get(DocumentNo, true);

        VerifyAggregateTableIsUpdated(SalesInvoiceHeader, SalesInvoiceEntityAggregate);
        Assert.AreEqual(ExpectedStatus, SalesInvoiceEntityAggregate.Status, 'Wrong status set');

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");

        VerifyLinesMatch(SalesInvoiceLine, SalesInvoiceEntityAggregate);
    end;

    local procedure VerifyAggregateTableIsUpdated(SourceRecordVariant: Variant; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    begin
        ValidateTotalsMatch(SourceRecordVariant, SalesInvoiceEntityAggregate);
        VerifyTransferredFieldsMatch(SourceRecordVariant, SalesInvoiceEntityAggregate);
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
                if not SkipValidation(TargetRecordRef.Number, TargetFieldRef.Number) then
                    if SourceFieldRef.Class = FieldClass::Normal then
                        if SourceFieldRef.Name <> 'Id' then
                            Assert.AreEqual(TargetFieldRef.Value, SourceFieldRef.Value, StrSubstNo('Fields %1 do not match', TargetFieldRef.Name));
            end;
        end;
    end;

    local procedure VerifyLinesMatch(SourceRecordLines: Variant; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        LinesRecordRef: RecordRef;
    begin
        GetSalesInvoiceAggregateLines(SalesInvoiceEntityAggregate, TempSalesInvoiceLineAggregate);
        DataTypeManagement.GetRecordRef(SourceRecordLines, LinesRecordRef);

        Assert.AreEqual(LinesRecordRef.Count, TempSalesInvoiceLineAggregate.Count, 'Wrong number of lines');
        if LinesRecordRef.Count = 0 then
            exit;

        TempSalesInvoiceLineAggregate.FindFirst();
        LinesRecordRef.FindFirst();
        repeat
            VerifyLineValuesMatch(LinesRecordRef, TempSalesInvoiceLineAggregate, SalesInvoiceEntityAggregate.Posted);
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
            FilterOutFieldsMissingOnSalesInvoiceLine(TempField);
        TempField.FindFirst();
        repeat
            SourceFieldRef := SourceRecordRef.Field(TempField."No.");
            AggregateLineFieldRef := SourceRecordRef.Field(TempField."No.");
            Assert.AreEqual(
              Format(SourceFieldRef.Value), Format(AggregateLineFieldRef.Value),
              StrSubstNo('Value did not match for field no. %1', TempField."No."));
        until TempField.Next() = 0;

        if GeneralLedgerSetup.UseVat() then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("VAT Prod. Posting Group"));
            if VATProductPostingGroup.Get(Format(SourceFieldRef.Value())) then
                TaxId := VATProductPostingGroup.SystemId;
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("VAT Identifier"))
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("Tax Group Code"));
            if TaxGroup.Get(Format(SourceFieldRef.Value())) then
                TaxId := TaxGroup.SystemId
        end;

        Assert.AreEqual(Format(SourceFieldRef.Value), Format(TempSalesInvoiceLineAggregate."Tax Code"), 'Tax code did not match');
        Assert.AreEqual(Format(TaxId), Format(TempSalesInvoiceLineAggregate."Tax Id"), 'Tax ID did not match');

        if TempSalesInvoiceLineAggregate.Type <> TempSalesInvoiceLineAggregate.Type::Item then
            exit;

        DataTypeManagement.FindFieldByName(SourceRecordRef, SourceFieldRef, SalesLine.FieldName("No."));
        Item.Get(Format(SourceFieldRef.Value()));
        Assert.AreEqual(TempSalesInvoiceLineAggregate."Item Id", Item.SystemId, 'Item ID was not set');
        Assert.IsFalse(IsNullGuid(Item.SystemId), 'Item ID was not set');
        Assert.AreNearlyEqual(
          TempSalesInvoiceLineAggregate."Tax Amount",
          TempSalesInvoiceLineAggregate."Amount Including VAT" - TempSalesInvoiceLineAggregate.Amount,
          0.01, 'Tax amount is not correct');
    end;

    local procedure ValidateTotalsMatch(SourceRecord: Variant; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DataTypeManagement: Codeunit "Data Type Management";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SourceRecordRef: RecordRef;
        ExpectedInvoiceDiscountAmount: Decimal;
        ExpectedTotalInclTaxAmount: Decimal;
        ExpectedTotalExclTaxAmount: Decimal;
        ExpectedTaxAmountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        DataTypeManagement.GetRecordRef(SourceRecord, SourceRecordRef);
        case SourceRecordRef.Number of
            DATABASE::"Sales Header":
                begin
                    SalesInvoice.OpenEdit();
                    Assert.IsTrue(SalesInvoice.GotoRecord(SourceRecord), 'Could not navigate to invoice');
                    if SalesInvoice.SalesLines."Invoice Discount Amount".Visible() then
                        ExpectedInvoiceDiscountAmount := SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := SalesInvoice.SalesLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal();
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
                    SalesLine.SetRange("Document No.", SalesInvoiceEntityAggregate."No.");
                    NumberOfLines := SalesLine.Count();
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    PostedSalesInvoice.OpenEdit();
                    Assert.IsTrue(PostedSalesInvoice.GotoRecord(SourceRecord), 'Could not navigate to invoice');
                    ExpectedInvoiceDiscountAmount := PostedSalesInvoice.SalesInvLines."Invoice Discount Amount".AsDecimal();
                    ExpectedTaxAmountAmount := PostedSalesInvoice.SalesInvLines."Total VAT Amount".AsDecimal();
                    ExpectedTotalExclTaxAmount := PostedSalesInvoice.SalesInvLines."Total Amount Excl. VAT".AsDecimal();
                    ExpectedTotalInclTaxAmount := PostedSalesInvoice.SalesInvLines."Total Amount Incl. VAT".AsDecimal();
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceEntityAggregate."No.");
                    NumberOfLines := SalesInvoiceLine.Count();
                end;
        end;

        SalesInvoiceEntityAggregate.Find();

        if NumberOfLines > 0 then
            Assert.IsTrue(ExpectedTotalExclTaxAmount > 0, 'One amount must be greated than zero');
        Assert.AreEqual(
          ExpectedInvoiceDiscountAmount, SalesInvoiceEntityAggregate."Invoice Discount Amount", 'Invoice discount amount is not correct');
        Assert.AreEqual(ExpectedTaxAmountAmount, SalesInvoiceEntityAggregate."Total Tax Amount", 'Total Tax Amount is not correct');
        Assert.AreEqual(ExpectedTotalExclTaxAmount, SalesInvoiceEntityAggregate.Amount, 'Amount is not correct');
        Assert.AreEqual(
          ExpectedTotalInclTaxAmount, SalesInvoiceEntityAggregate."Amount Including VAT", 'Amount Including VAT is not correct');
    end;

    local procedure GetFieldsThatMustMatchWithSalesHeader(var TempField: Record "Field" temporary)
    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Document Type"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Your Reference"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Payment Terms Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Prices Including VAT"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Shipment Method Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Due Date"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Customer Posting Group"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Currency Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Salesperson Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Order No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Recalculate Invoice Disc."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo(Amount), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Amount Including VAT"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer Name"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Sell-to City"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to County"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Country/Region Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Phone No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Sell-to E-Mail"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Name"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address 2"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Bill-to City"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Contact"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Post Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to County"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Country/Region Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Customer No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Name"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address 2"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Ship-to City"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Contact"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Post Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to County"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Country/Region Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Phone No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Document Date"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Cust. Ledger Entry No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Amount"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("External Document No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Tax Area Code"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Tax Liable"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("VAT Bus. Posting Group"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("VAT Registration No."), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Calculation"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Value"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Posting Date"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo(IsTest), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Shortcut Dimension 1 Code"), Database::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Shortcut Dimension 2 Code"), Database::"Sales Invoice Entity Aggregate", TempField);
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
          DummySalesInvoiceLineAggregate.FieldNo("Unit of Measure Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("VAT Prod. Posting Group"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Tax Group Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
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
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Variant Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceLineAggregate.FieldNo("Location Code"), DATABASE::"Sales Invoice Line Aggregate", TempField);
    end;

    local procedure GetInvoiceAggregateSpecificFields(var TempField: Record "Field" temporary)
    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Total Tax Amount"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo(Status), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo(Posted), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Discount Applied Before Tax"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Last Modified Date Time"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Customer Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo("Order Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Contact Graph Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Currency Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Payment Terms Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Shipment Method Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Dispute Status"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Dispute Status Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Promised Pay Date"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Subtotal Amount"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Tax Area ID"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(
          DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Customer Id"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
        AddFieldToBuffer(DummySalesInvoiceEntityAggregate.FieldNo(Id), DATABASE::"Sales Invoice Entity Aggregate", TempField);
    end;

    local procedure GetInvoiceAggregateLineSpecificFields(var TempField: Record "Field" temporary)
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
          DummySalesInvoiceEntityAggregate.FieldNo("Promised Pay Date"), DATABASE::"Sales Invoice Entity Aggregate", TempField);
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

    local procedure UpdateSalesInvoiceAggregate(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        SalesInvoiceEntityAggregate.Validate("Sell-to Customer No.", Customer."No.");
        RegisterFieldSet(TempFieldBuffer, SalesInvoiceEntityAggregate.FieldNo("Sell-to Customer No."));
    end;

    local procedure UpdateSalesInvoiceLineAggregate(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Entity Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure SetFieldFilters(var Field: Record Field)
    begin
        Field.SetRange(TableNo, DATABASE::"Sales Invoice Entity Aggregate");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<>%5',
            Field.FieldNo(SystemId),
            Field.FieldNo(SystemCreatedAt),
            Field.FieldNo(SystemCreatedBy),
            Field.FieldNo(SystemModifiedAt),
            Field.FieldNo(SystemModifiedBy));
    end;

    local procedure AssignStaticValues524113(var UnitPrice: array[4] of Decimal; var Quantity: array[4] of Integer)
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

    local procedure CreateInvoiceWithMultipleLineThroughTestPageNoDiscount(var SalesInvoice: TestPage "Sales Invoice";
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

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");

        for i := 1 to ArrayLen(UnitPrice) do
            CreateInvoiceWithMultipleLineThroughTestPage(SalesInvoice, Item."No.", UnitPrice[i], Quantity[i]);
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

    local procedure CreateInvoiceWithMultipleLineThroughTestPage(var SalesInvoice: TestPage "Sales Invoice"; ItemNo: Code[20]; UnitPrice: Decimal; Quantity: Integer)
    begin
        SalesInvoice.SalesLines.Last();
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines."No.".SetValue(ItemNo);
        SalesInvoice.SalesLines.Quantity.SetValue(Quantity);
        SalesInvoice.SalesLines."Unit Price".SetValue(UnitPrice);

        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();
    end;

    [Scope('OnPrem')]
    procedure FilterOutFieldsMissingOnSalesInvoiceLine(var TempCommonField: Record "Field" temporary)
    var
        DummySalesLine: Record "Sales Line";
    begin
        TempCommonField.SetFilter(
          "No.", '<>%1&<>%2&<>%3&<>%4&<>%5', DummySalesLine.FieldNo("Currency Code"), DummySalesLine.FieldNo("Qty. to Invoice"),
          DummySalesLine.FieldNo("Qty. to Ship"), DummySalesLine.FieldNo("Quantity Shipped"), DummySalesLine.FieldNo("Quantity Invoiced"));
    end;

    local procedure SkipValidation(TableNumber: Integer; FieldNumber: Integer): Boolean
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
    begin
        if (TableNumber in [DATABASE::"Sales Invoice Line", DATABASE::"Sales Line", DATABASE::"Sales Invoice Line Aggregate"]) and
           (FieldNumber in [SalesInvoiceLineAggregate.FieldNo(Type)])
        then
            exit(true);

        if (TableNumber = DATABASE::"Sales Invoice Entity Aggregate") and
           (FieldNumber in [SalesInvoiceEntityAggregate.FieldNo("Invoice Discount Calculation"), SalesInvoiceEntityAggregate.FieldNo("Invoice Discount Value")])
        then
            exit(true);
        if (TableNumber = DATABASE::"Sales Invoice Header") and
           (FieldNumber in [SalesInvoiceEntityAggregate.FieldNo(IsTest)])
        then
            exit(true)
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
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