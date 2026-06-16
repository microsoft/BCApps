codeunit 137410 "Extended Text Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Extended Text]
        IsInitialzied := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        NotFoundErr: Label 'Could not find an order line with the Extended Text.';
        ExtendedTxt: Label 'Test Extended Text';
        ExtTextDeletedOnSalesQuoteErr: Label 'Extended text lines were deleted after editing description on the sales quote line.';
        ExtTextDeletedOnPurchaseQuoteErr: Label 'Extended text lines were deleted after editing description on the purchase quote line.';
        ExtTextDeletedOnSalesReturnOrderErr: Label 'Extended text lines were deleted after editing description on the sales return order line.';
        ExtTextDeletedOnPurchaseOrderErr: Label 'Extended text lines were deleted after editing description on the purchase order line.';
        ExtTextDeletedOnPurchaseInvoiceErr: Label 'Extended text lines were deleted after editing description on the purchase invoice line.';
        ExtTextDeletedOnPurchaseCreditMemoErr: Label 'Extended text lines were deleted after editing description on the purchase credit memo line.';
        ExtTextDeletedOnSalesOrderErr: Label 'Extended text lines were deleted after editing description on the sales order line.';
        ExtTextDeletedOnSalesInvoiceErr: Label 'Extended text lines were deleted after editing description on the sales invoice line.';
        ExtTextDeletedOnSalesCreditMemoErr: Label 'Extended text lines were deleted after editing description on the sales credit memo line.';
        IsInitialzied: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Extended Text Documents");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();
        if IsInitialzied then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Extended Text Documents");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialzied := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Extended Text Documents");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderWithExtText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        CreateItemwithStock(Item, ExtendedTxt, Quantity);
        LibrarySales.CreateSalesQuote(
            SalesHeader, SalesLine, Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        SalesOrder.Trap();

        // Exercise: Create Sales Order form Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);

        SalesOrder.Close();

        // Verify
        VerifySalesOrder(SalesLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderWithExtText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        CreateItemwithStock(Item, ExtendedTxt, Quantity);
        LibrarySales.CreateSalesBlanketOrder(
            SalesHeader, SalesLine, Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        // Exercise: Create Sales Order form Sales Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", SalesHeader);

        // Verify
        VerifySalesOrder(SalesLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesBlanketOrderWithExtText()
    var
        ShippedItem: Record Item;
        NotShippedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtText: Text;
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 379977] Extended Text for Blanket Sales Order Line with "Qty. to Ship" = 0 should not be transferred to Sales Order Line.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Items "I1" and "I2" with Extended Texts "ET1" and "ET2" respectively.
        ExtText := LibraryUtility.GenerateRandomText(30);
        LibraryInventory.CreateItemWithExtendedText(NotShippedItem, ExtText, "Costing Method"::FIFO, 0);
        LibraryInventory.CreateItemWithExtendedText(ShippedItem, LibraryUtility.GenerateRandomText(30), "Costing Method"::FIFO, 0);

        // [GIVEN] Blanket Sales Order for Items "I1" and "I2", in which "Qty. to Ship" for "I1" = 0.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        CreateSalesLineWithExtText(SalesHeader, NotShippedItem."No.", LibraryRandom.RandInt(10), 0);
        CreateSalesLineWithExtText(
          SalesHeader, ShippedItem."No.", LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5));

        // [WHEN] Make a Sales Order from the Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", SalesHeader);
        // [THEN] Extended Text "ET1" is not present in the Sales Order.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Description, ExtText);
        Assert.RecordIsEmpty(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteToOrderWithExtText()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryInventory.CreateItemWithExtendedText(Item, ExtendedTxt, Item."Costing Method"::FIFO, 0);
        LibraryPurchase.CreatePurchaseQuote(
            PurchaseHeader, PurchaseLine, Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false) then
            TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // Exercise: Create Sales Order form Purchase Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order (Yes/No)", PurchaseHeader);

        // Verify
        VerifyPurchOrder(PurchaseLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchBlanketOrderWithExtText()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryInventory.CreateItemWithExtendedText(Item, ExtendedTxt, Item."Costing Method"::FIFO, 0);
        LibraryPurchase.CreatePurchaseBlanketOrder(
            PurchaseHeader, PurchaseLine, Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false) then
            TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // Exercise: Create Sales Order form Purchase Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Purch Ord. to Ord. (Y/N)", PurchaseHeader);

        // Verify
        VerifyPurchOrder(PurchaseLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderFromPurchBlanketOrderWithExtText()
    var
        ShippedItem: Record Item;
        NotShippedItem: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExtText: Text;
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 379977] Extended Text for Blanket Purchase Order Line with "Qty. to Receive" = 0 should not be transferred to Purchase Order Line.
        Initialize();

        // [GIVEN] Items "I1" and "I2" with Extended Texts "ET1" and "ET2" respectively.
        ExtText := LibraryUtility.GenerateRandomText(30);
        LibraryInventory.CreateItemWithExtendedText(NotShippedItem, ExtText, "Costing Method"::FIFO, 0);
        LibraryInventory.CreateItemWithExtendedText(ShippedItem, LibraryUtility.GenerateRandomText(30), "Costing Method"::FIFO, 0);

        // [GIVEN] Blanket Purchase Order for Items "I1" and "I2", in which "Qty. to Receive" for "I1" = 0.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithExtText(PurchHeader, NotShippedItem."No.", LibraryRandom.RandInt(10), 0);
        CreatePurchLineWithExtText(
          PurchHeader, ShippedItem."No.", LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5));

        // [WHEN] Make a Purchase Order from the Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Purch Ord. to Ord. (Y/N)", PurchHeader);
        // [THEN] Extended Text "ET1" is not present in the Purchase Order.
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Description, ExtText);
        Assert.RecordIsEmpty(PurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertFinanceChargeMemoExtTextAndRollbackThroughError()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        ExtendedTextHeader: Record "Extended Text Header";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 274510] Inserting finance charge memo extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN] Finance Charge Memo "F" with void type line with extended text "No."
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, LibrarySales.CreateCustomerNo());
        LibraryERM.CreateFinanceChargeMemoLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::" ");
        FinanceChargeMemoLine.Validate("No.", ExtendedTextHeader."No.");
        FinanceChargeMemoLine.Modify(true);

        ExtendedTextHeader.Validate("Finance Charge Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.FinChrgMemoCheckIfAnyExtText(FinanceChargeMemoLine, true);

        // [WHEN] Insert extended text in "F" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertFinChrgMemoExtText(FinanceChargeMemoLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertPurchaseExtTextAndRollbackThroughError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExtendedTextHeader: Record "Extended Text Header";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 274510] Inserting purchase extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Purchase credit memo "P" with void type line with extended text "No."
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", ExtendedTextHeader."No.", 0);

        ExtendedTextHeader.Validate("Purchase Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, true);

        // [WHEN] Insert extended text in "P" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertReminderExtTextAndRollbackThroughError()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 274510] Inserting reminder extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Reminder "M" with void type line with extended text "No."
        LibraryERM.CreateReminderHeader(ReminderHeader);
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::" ");
        ReminderLine.Validate("No.", ExtendedTextHeader."No.");
        ReminderLine.Modify(true);

        ExtendedTextHeader.Validate(Reminder, true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.ReminderCheckIfAnyExtText(ReminderLine, true);

        // [WHEN] Insert extended text in "M" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertReminderExtText(ReminderLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertSalesExtTextAndRollbackThroughError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtendedTextHeader: Record "Extended Text Header";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 274510] Inserting sales extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Sales credit memo "S" with void type line with extended text "No."
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", ExtendedTextHeader."No.", 0);

        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);

        // [WHEN] Insert extended text in "S" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertSalesExtText(SalesLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertServiceExtTextAndRollbackThroughError()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 274510] Inserting service extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Service credit memo "S" with void type line with extended text "No."
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", ExtendedTextHeader."No.");

        ExtendedTextHeader.Validate("Service Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        ServiceTransferExtText.ServCheckIfAnyExtText(ServiceLine, true);

        // [WHEN] Insert extended text in "S" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        ServiceTransferExtText.InsertServExtText(ServiceLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithResourceLineAndExtendedText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExtTextPurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Insert extended text for purchase line with resource
        Initialize();

        // [GIVEN] Resource with extended text
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Automatic Ext. Texts", true);
        Resource.Modify(true);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, ExtendedTextHeader."Table Name"::Resource, Resource."No.");
        ExtendedTextHeader.Validate("Purchase Order", true);
        ExtendedTextHeader.Modify(true);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);

        // [GIVEN] Purchase order with resource line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));

        // [WHEN] Insert extended text
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // [THEN] Purchase line with Extended text is inserted
        ExtTextPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        ExtTextPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(ExtTextPurchaseLine, 2);
        ExtTextPurchaseLine.SetRange(Description, ExtendedTextLine.Text);
        Assert.RecordIsNotEmpty(ExtTextPurchaseLine);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure JobCheckIfAnyExtTextForItemTest()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobCheckIfAnyExtTextResult: Boolean;
    begin
        // [GIVEN] Item with Extended Text Line
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);


        // [GIVEN] Job Planning Line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), Item."No.", JobTask, JobPlanningLine);

        // [WHEN] JobCheckIfAnyExtText
        JobCheckIfAnyExtTextResult := TransferExtendedText.JobCheckIfAnyExtText(JobPlanningLine, true, Job);

        // [THEN] Verify Result
        Assert.IsTrue(JobCheckIfAnyExtTextResult, 'Ext. Texts expected');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCheckIfAnyExtTextForStandardTextTest()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // [GIVEN] Standard Text with Extended Text Line
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN] Job Planning Line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.TextType(), ExtendedTextHeader."No.", JobTask, JobPlanningLine);

        // [WHEN] Extended Text is inserted
        TransferExtendedText.JobCheckIfAnyExtText(JobPlanningLine, true, Job);
        TransferExtendedText.InsertJobExtText(JobPlanningLine);

        // [THEN] Verify Result
        VerifyInsertedJobPlanningLines(ExtendedTextHeader, JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnSalesQuoteLineDoesNotDeleteInsertedExtText()
    var
        Customer: Record Customer;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Sales Quote] [AI test]
        // [SCENARIO 634184] Editing Description on a Sales Quote item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a (manual, non-automatic) Extended Text valid for Sales Quote.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Quote", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Sales Quote with one item line and Insert Ext. Texts run on it.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SalesLines.GotoRecord(SalesLine);
        SalesQuote.SalesLines.InsertExtTexts.Invoke();
        SalesQuote.Close();
        AttachedCountBefore := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Sales Quote subform.
        NewDescription := CopyStr(SalesLine.Description + '2', 1, MaxStrLen(SalesLine.Description));
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SalesLines.GotoRecord(SalesLine);
        SalesQuote.SalesLines.Description.SetValue(NewDescription);
        SalesQuote.SalesLines.Next();
        SalesQuote.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnSalesQuoteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnPurchaseQuoteLineDoesNotDeleteInsertedExtText()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Purchase] [Purchase Quote] [AI test]
        // [SCENARIO 634184] Editing Description on a Purchase Quote item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a Extended Text valid for Purchase Quote.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Quote", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Purchase Quote with one item line and Insert Ext. Texts run on it.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PurchLines.GotoRecord(PurchaseLine);
        PurchaseQuote.PurchLines."Insert &Ext. Texts".Invoke();
        PurchaseQuote.Close();
        AttachedCountBefore := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Purchase Quote subform.
        NewDescription := CopyStr(PurchaseLine.Description + '2', 1, MaxStrLen(PurchaseLine.Description));
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PurchLines.GotoRecord(PurchaseLine);
        PurchaseQuote.PurchLines.Description.SetValue(NewDescription);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnPurchaseQuoteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnPurchaseOrderLineDoesNotDeleteInsertedExtText()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Purchase] [Purchase Order] [AI test]
        // [SCENARIO 634184] Editing Description on a Purchase Order item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a Extended Text valid for Purchase Order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Order", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Purchase Order with one item line and Insert Ext. Texts run on it.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines.GotoRecord(PurchaseLine);
        PurchaseOrder.PurchLines."Insert Ext. Texts".Invoke();
        PurchaseOrder.Close();
        AttachedCountBefore := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Purchase Order subform.
        NewDescription := CopyStr(PurchaseLine.Description + '2', 1, MaxStrLen(PurchaseLine.Description));
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines.GotoRecord(PurchaseLine);
        PurchaseOrder.PurchLines.Description.SetValue(NewDescription);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnPurchaseOrderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnPurchaseInvoiceLineDoesNotDeleteInsertedExtText()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Purchase] [Purchase Invoice] [AI test]
        // [SCENARIO 634184] Editing Description on a Purchase Invoice item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a Extended Text valid for Purchase Invoice.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Invoice", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Purchase Invoice with one item line and Insert Ext. Texts run on it.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.GotoRecord(PurchaseLine);
        PurchaseInvoice.PurchLines.InsertExtTexts.Invoke();
        PurchaseInvoice.Close();
        AttachedCountBefore := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Purchase Invoice subform.
        NewDescription := CopyStr(PurchaseLine.Description + '2', 1, MaxStrLen(PurchaseLine.Description));
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.GotoRecord(PurchaseLine);
        PurchaseInvoice.PurchLines.Description.SetValue(NewDescription);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnPurchaseInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnPurchaseCrMemoLineDoesNotDeleteInsertedExtText()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseCrMemo: TestPage "Purchase Credit Memo";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Purchase] [Purchase Credit Memo] [AI test]
        // [SCENARIO 634184] Editing Description on a Purchase Credit Memo item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a Extended Text valid for Purchase Credit Memo.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Credit Memo", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Purchase Credit Memo with one item line and Insert Ext. Texts run on it.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseCrMemo.OpenEdit();
        PurchaseCrMemo.GotoRecord(PurchaseHeader);
        PurchaseCrMemo.PurchLines.GotoRecord(PurchaseLine);
        PurchaseCrMemo.PurchLines.InsertExtTexts.Invoke();
        PurchaseCrMemo.Close();
        AttachedCountBefore := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Purchase Credit Memo subform.
        NewDescription := CopyStr(PurchaseLine.Description + '2', 1, MaxStrLen(PurchaseLine.Description));
        PurchaseCrMemo.OpenEdit();
        PurchaseCrMemo.GotoRecord(PurchaseHeader);
        PurchaseCrMemo.PurchLines.GotoRecord(PurchaseLine);
        PurchaseCrMemo.PurchLines.Description.SetValue(NewDescription);
        PurchaseCrMemo.PurchLines.Next();
        PurchaseCrMemo.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedPurchaseLines(PurchaseHeader, PurchaseLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnPurchaseCreditMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnSalesOrderLineDoesNotDeleteInsertedExtText()
    var
        Customer: Record Customer;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Sales Order] [AI test]
        // [SCENARIO 634184] Editing Description on a Sales Order item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a (manual, non-automatic) Extended Text valid for Sales Order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Order", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Sales Order with one item line and Insert Ext. Texts run on it.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.GotoRecord(SalesLine);
        SalesOrder.SalesLines."Insert Ext. Texts".Invoke();
        SalesOrder.Close();
        AttachedCountBefore := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Sales Order subform.
        NewDescription := CopyStr(SalesLine.Description + '2', 1, MaxStrLen(SalesLine.Description));
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.GotoRecord(SalesLine);
        SalesOrder.SalesLines.Description.SetValue(NewDescription);
        SalesOrder.SalesLines.Next();
        SalesOrder.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnSalesOrderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnSalesInvoiceLineDoesNotDeleteInsertedExtText()
    var
        Customer: Record Customer;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Sales Invoice] [AI test]
        // [SCENARIO 634184] Editing Description on a Sales Invoice item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a (manual, non-automatic) Extended Text valid for Sales Invoice.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Invoice", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Sales Invoice with one item line and Insert Ext. Texts run on it.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.GotoRecord(SalesLine);
        SalesInvoice.SalesLines.InsertExtTexts.Invoke();
        SalesInvoice.Close();
        AttachedCountBefore := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Sales Invoice subform.
        NewDescription := CopyStr(SalesLine.Description + '2', 1, MaxStrLen(SalesLine.Description));
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.GotoRecord(SalesLine);
        SalesInvoice.SalesLines.Description.SetValue(NewDescription);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnSalesInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnSalesCrMemoLineDoesNotDeleteInsertedExtText()
    var
        Customer: Record Customer;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemo: TestPage "Sales Credit Memo";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Sales Credit Memo] [AI test]
        // [SCENARIO 634184] Editing Description on a Sales Credit Memo item line must preserve previously
        // inserted Extended Text lines.
        Initialize();

        // [GIVEN] An item with a (manual, non-automatic) Extended Text valid for Sales Credit Memo.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Sales Credit Memo with one item line and Insert Ext. Texts run on it.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesCrMemo.OpenEdit();
        SalesCrMemo.GotoRecord(SalesHeader);
        SalesCrMemo.SalesLines.GotoRecord(SalesLine);
        SalesCrMemo.SalesLines.InsertExtTexts.Invoke();
        SalesCrMemo.Close();
        AttachedCountBefore := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Sales Credit Memo subform.
        NewDescription := CopyStr(SalesLine.Description + '2', 1, MaxStrLen(SalesLine.Description));
        SalesCrMemo.OpenEdit();
        SalesCrMemo.GotoRecord(SalesHeader);
        SalesCrMemo.SalesLines.GotoRecord(SalesLine);
        SalesCrMemo.SalesLines.Description.SetValue(NewDescription);
        SalesCrMemo.SalesLines.Next();
        SalesCrMemo.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnSalesCreditMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditingDescriptionOnSalesReturnOrderLineDoesNotDeleteInsertedExtText()
    var
        Customer: Record Customer;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        AttachedCountBefore: Integer;
        AttachedCountAfter: Integer;
        NewDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Sales Return Order] [AI test]
        // [SCENARIO 634184] Editing Description on a Sales Return Order item line must preserve previously
        // inserted Extended Text lines.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] An item with a (manual, non-automatic) Extended Text valid for Sales Return Order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Return Order", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomText(50));
        ExtendedTextLine.Modify(true);

        // [GIVEN] A Sales Return Order with one item line and Insert Ext. Texts run on it.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SalesLines.GotoRecord(SalesLine);
        SalesReturnOrder.SalesLines."Insert &Ext. Texts".Invoke();
        SalesReturnOrder.Close();
        AttachedCountBefore := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");

        // [WHEN] User edits Description on the parent item line via the Sales Return Order subform.
        NewDescription := CopyStr(SalesLine.Description + '2', 1, MaxStrLen(SalesLine.Description));
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SalesLines.GotoRecord(SalesLine);
        SalesReturnOrder.SalesLines.Description.SetValue(NewDescription);
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.Close();

        // [THEN] Inserted extended text lines must still be present.
        AttachedCountAfter := CountAttachedSalesLines(SalesHeader, SalesLine."Line No.");
        Assert.AreEqual(AttachedCountBefore, AttachedCountAfter, ExtTextDeletedOnSalesReturnOrderErr);
    end;

    local procedure CreateJobPlanningLine(LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; No: Code[20]; JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Line Type", LineType);
        JobPlanningLine.Validate(Type, Type);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateExtendedText(var ExtendedTextHeader: Record "Extended Text Header")
    var
        StandardText: Record "Standard Text";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibrarySales.CreateStandardText(StandardText);
        LibrarySmallBusiness.CreateExtendedTextHeader(
          ExtendedTextHeader, ExtendedTextHeader."Table Name"::"Standard Text", StandardText.Code);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CommitAndStartNewTransaction(): Code[10]
    var
        "Area": Record "Area";
    begin
        Commit();
        Area.Validate(Code, LibraryUtility.GenerateRandomCode(Area.FieldNo(Code), DATABASE::Area));
        Area.Validate(Text, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Area.Text)), 1, MaxStrLen(Area.Text)));
        Area.Insert(true);
        exit(Area.Code);
    end;

    local procedure RollbackTransactionThroughErrorAndVerify(InsertedCode: Code[10])
    var
        "Area": Record "Area";
    begin
        asserterror Error(LibraryUtility.GenerateRandomText(100));
        Area.SetRange(Code, InsertedCode);
        Assert.RecordIsEmpty(Area);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
    end;

    local procedure CreateItemwithStock(var Item: Record Item; ExtendedText: Text[50]; Quantity: Decimal)
    begin
        LibraryInventory.CreateItemWithExtendedText(Item, ExtendedText, Item."Costing Method"::FIFO, 0);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), 0);
    end;

    local procedure CreateSalesLineWithExtText(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure CreatePurchLineWithExtText(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
    end;

    local procedure VerifySalesOrder(ItemNo: Code[20]; ExtText: Text[50])
    var
        SalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
    begin
        ItemSalesLine.SetRange("Document Type", ItemSalesLine."Document Type"::Order);
        ItemSalesLine.SetRange("No.", ItemNo);
        ItemSalesLine.FindFirst();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", ItemSalesLine."Document No.");
        SalesLine.SetRange(Description, ExtText);
        Assert.IsFalse(SalesLine.IsEmpty, NotFoundErr);
    end;

    local procedure VerifyPurchOrder(ItemNo: Code[20]; ExtText: Text[50])
    var
        PurchLine: Record "Purchase Line";
        ItemPurchLine: Record "Purchase Line";
    begin
        ItemPurchLine.SetRange("Document Type", ItemPurchLine."Document Type"::Order);
        ItemPurchLine.SetRange("No.", ItemNo);
        ItemPurchLine.FindFirst();

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", ItemPurchLine."Document No.");
        PurchLine.SetRange(Description, ExtText);
        Assert.IsFalse(PurchLine.IsEmpty, NotFoundErr);
    end;

    local procedure VerifyInsertedJobPlanningLines(var ExtendedTextHeader: Record "Extended Text Header"; var JobPlanningLine: Record "Job Planning Line")
    var
        ExtendedTextLine: Record "Extended Text Line";
        ExtTextJobPlanningLine: Record "Job Planning Line";
    begin
        ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
        ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
        ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
        ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");

        ExtTextJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        ExtTextJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        ExtTextJobPlanningLine.SetRange("Attached to Line No.", JobPlanningLine."Line No.");
        Assert.RecordCount(ExtTextJobPlanningLine, ExtendedTextLine.Count());

        ExtTextJobPlanningLine.FindFirst();
        Assert.IsTrue(ExtTextJobPlanningLine."Contract Line" = true, 'Contract Line expected.');
        Assert.IsTrue(ExtTextJobPlanningLine."Job Contract Entry No." <> 0, 'Job Contract Entry No. expected.');
    end;

    local procedure CountAttachedSalesLines(SalesHeader: Record "Sales Header"; ParentLineNo: Integer): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Attached to Line No.", ParentLineNo);
        exit(SalesLine.Count());
    end;

    local procedure CountAttachedPurchaseLines(PurchaseHeader: Record "Purchase Header"; ParentLineNo: Integer): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Attached to Line No.", ParentLineNo);
        exit(PurchaseLine.Count());
    end;
}

