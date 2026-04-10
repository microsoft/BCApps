codeunit 139052 "Office Addin Initiate Tasks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DefaultDocSendingProfileTxt: Label 'DEFAULT';
        QuoteTxt: Label 'Quote';
        ReportAsPdfFileNameMsg: Label 'Sales %1 %2.pdf';

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageVerifyActions()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156484] Stan can initiate tasks from the Customer Card

        // [GIVEN] New contact with email is created and assigned to customer
        CreateOfficeAddinContext(OfficeAddinContext);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [THEN] Customer card is opened for associated email with correct actions
        Assert.IsTrue(CustomerCard.NewSalesQuoteAddin.Visible(), 'New Sales Quote (add-in) not visible');
        Assert.IsTrue(CustomerCard.NewSalesInvoiceAddin.Visible(), 'New Sales Invoice (add-in) not visible');
        Assert.IsTrue(CustomerCard.NewSalesCreditMemoAddin.Visible(), 'New Sales Credit Memo (add-in) not visible');
        Assert.IsFalse(CustomerCard.NewSalesQuote.Visible(), 'New Sales Quote shouldn''t be visible');
        Assert.IsFalse(CustomerCard.NewSalesInvoice.Visible(), 'New Sales Invoice shoudln''t be visible');
        Assert.IsFalse(CustomerCard.NewSalesCreditMemo.Visible(), 'New Sales Credit Memo shouldn''t be visible');
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageInvoicePostAndSendDefault()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Contact] [Customer] [Invoice]
        // [SCENARIO 156492] Stan initiates task Post & Send from the Sales Invoice - no default sending profile exists

        // [GIVEN] New contact with email is created and assigned to customer
        CreateOfficeAddinContext(OfficeAddinContext);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        SetReplyWithAttachment();
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Customer card is opened and user selects New Sales Invoice
        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [WHEN] New Invoice Created and user selects Post and Send with no default sendong profile exists
        CreateSalesInvoiceLine(SalesInvoice);
        SalesInvoice.PostAndSend.Invoke();

        // [THEN] Email with reply is opened with PDF attached
        // Verified in ActionHandler that email was reply with PDF attached
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageInvoicePostAndSendEmailPDFOnly()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Contact] [Customer] [Invoice]
        // [SCENARIO 156492] Stan initiates task Post & Send but default sending profile is not email with PDF

        // [GIVEN] New contact with email is created and assigned to customer
        UpdateCustomerDocSendingProfile(CreateOfficeAddinContext(OfficeAddinContext), DefaultDocSendingProfileTxt);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        SetReplyWithAttachment();
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Customer card is opened and user selects New Sales Invoice
        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [WHEN] New Invoice Created and user selects Post and Send when sending profile is not email with PDF
        CreateSalesInvoiceLine(SalesInvoice);
        SalesInvoice.PostAndSend.Invoke();

        // [THEN] Email with reply is opened with PDF attached
        // Verified in ActionHandler that assigned sending document profile not used
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreditMemoPostAndSendDefault()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Contact] [Customer] [Credit Memo]
        // [SCENARIO 156493] Stan can initiate task Post & Send from the Credit Memo - no default sending profile

        // [GIVEN] New contact with email is created and assigned to customer
        CreateOfficeAddinContext(OfficeAddinContext);

        // [WHEN]  Outlook Main Engine finds email and contact/customer it is assigned to
        SetReplyWithAttachment();
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Customer card is opened and user selects New Credit Memo
        SalesCreditMemo.Trap();
        CustomerCard.NewSalesCreditMemo.Invoke();

        // [WHEN] New Credit Memo Created and user selects Post and Send with no default sendong profile exists
        CreateSalesCreditMemoLine(SalesCreditMemo);
        SalesCreditMemo.PostAndSend.Invoke();

        // [THEN] Email with reply is opened with PDF attached
        // Verified in ActionHandler that email was reply with PDF attached
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreditMemoPostAndSendEmailPDFOnly()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Contact] [Customer] [Credit Memo]
        // [SCENARIO 156493] Stan initiates Post & Send on Credit Memo but default sending profile is not email/PDF

        // [GIVEN] New contact with email is created and assigned to customer
        UpdateCustomerDocSendingProfile(CreateOfficeAddinContext(OfficeAddinContext), DefaultDocSendingProfileTxt);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        SetReplyWithAttachment();
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Customer card is opened and user selects New Credit Memo
        SalesCreditMemo.Trap();
        CustomerCard.NewSalesCreditMemo.Invoke();

        // [WHEN] New Invoice Created and user selects Post and Send when sending profile is not email with PDF
        CreateSalesCreditMemoLine(SalesCreditMemo);
        SalesCreditMemo.PostAndSend.Invoke();

        // [THEN] Email with reply is opened with PDF attached
        // Verified in ActionHandler that assigned sending document profile not used
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateQuoteVerifyActions()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156484] Stan can create a Quote from the Customer Card. Verify Quote Actions are there for Stan
        // Setup
        CreateOfficeAddinContext(OfficeAddinContext);

        // [THEN] Customer card is opened for associated email
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();

        Assert.AreEqual(true, SalesQuote.Email.Visible(), 'Email not visible');
        Assert.AreEqual(true, SalesQuote.MakeInvoice.Visible(), 'MakeInvoice not visible');
        Assert.AreEqual(false, SalesQuote.Print.Visible(), 'Print should not be visible');
    end;

    [Test]
    [HandlerFunctions('EmailActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateQuoteEmail()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        BodyTextInStream: InStream;
        EmailBodyTempBlob: Codeunit "Temp Blob";
        BodyText: Text;
        QuoteNextNo: Code[20];
        DummyEmailAddress: Text[250];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156484] Stan can create an Email from the Quote
        CreateOfficeAddinContext(OfficeAddinContext);

        // [WHEN] Customer card is opened for associated email
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // Gather expected parameters
        LibraryVariableStorage.Enqueue('sendAttachment');
        QuoteNextNo := GetQuoteNextNo();
        LibraryVariableStorage.Enqueue(StrSubstNo(ReportAsPdfFileNameMsg, QuoteTxt, QuoteNextNo));

        // [WHEN] New sales quote is created from the customer card
        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();
        SalesQuote."Sell-to Customer Name".Value(CustomerCard.Name.Value);

        // Get Email body text
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("No.", QuoteNextNo);
        ReportSelections.GetEmailBodyForCust(EmailBodyTempBlob, ReportSelections.Usage::"S.Quote", SalesHeader, CustomerCard."No.".Value, DummyEmailAddress);
        EmailBodyTempBlob.CreateInStream(BodyTextInStream);
        BodyTextInStream.Read(BodyText);

        LibraryVariableStorage.Enqueue(BodyText);

        // [WHEN] Email action is invoked from the sales quote page
        SalesQuote.Email.Invoke();

        // [THEN] EmailActionHandler verifies that the expected JS function is called with the correct parameters
    end;

    [Test]
    [HandlerFunctions('SalesOrderShipAndInvoiceHandler,ShipAndInvoiceActionHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateOrderPostAndSendShipAndInvoice()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Item: Record Item;
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156484] Stan can attach both the shipment and invoice document for an order
        CreateOfficeAddinContext(OfficeAddinContext);

        // [WHEN] Customer card is opened for associated email
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] New sales order is created from the customer card
        SalesOrder.Trap();
        CustomerCard.NewSalesOrder.Invoke();
        SalesOrder."Sell-to Customer Name".Value(CustomerCard."No.".Value);

        // [WHEN] An item is entered on the order
        LibraryInventory.CreateItem(Item);
        SalesOrder.SalesLines.Type.SetValue(2);
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Quantity.SetValue(5);
        LibraryVariableStorage.Enqueue(CustomerCard."No.".Value);

        // [WHEN] Post and send action is invoked from the sales order page
        SalesOrder.PostAndSend.Invoke();

        // [THEN] EmailActionHandler verifies that both the shipment and invoice documents are attached to the email
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuotesPrintNotVisible()
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from sales quotes page
        Initialize();

        // [WHEN] Posted sales quotes page is opened
        SalesQuotes.Trap();
        PAGE.Run(PAGE::"Sales Quotes");

        // [THEN] Print action is not visible
        Assert.IsFalse(SalesQuotes.Print.Visible(), 'Print button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderActionsNotVisible()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from sales order page
        Initialize();

        // [WHEN] Sales order page is opened
        SalesOrder.Trap();
        PAGE.Run(PAGE::"Sales Order");

        // [THEN] Print action are not visible
        Assert.IsFalse(SalesOrder."Print Confirmation".Visible(), 'Print confirmation button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdersActionsNotVisible()
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from sales order list page
        Initialize();

        // [WHEN] Sales order list page is opened
        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List");

        // [THEN] Print action are not visible
        Assert.IsFalse(SalesOrderList."Print Confirmation".Visible(), 'Print confirmation button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceActionsNotVisible()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted sales invoice page
        Initialize();

        // [WHEN] Posted sales invoice page is opened
        PostedSalesInvoice.Trap();
        PAGE.Run(PAGE::"Posted Sales Invoice");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedSalesInvoice.Print.Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedSalesInvoice."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoActionsNotVisible()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted sales credit memo page
        Initialize();

        // [WHEN] Posted sales credit memo page is opened
        PostedSalesCreditMemo.Trap();
        PAGE.Run(PAGE::"Posted Sales Credit Memo");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedSalesCreditMemo.Print.Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedSalesCreditMemo."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesActionsNotVisible()
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted sales invoices page
        Initialize();

        // [WHEN] Posted sales invoices page is opened
        PostedSalesInvoices.Trap();
        PAGE.Run(PAGE::"Posted Sales Invoices");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedSalesInvoices.Print.Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedSalesInvoices.Navigate.Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemosActionsNotVisible()
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from the posted sales credit memos page
        Initialize();

        // [WHEN] Posted sales credit memos page is opened
        PostedSalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Posted Sales Credit Memos");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedSalesCreditMemos."&Print".Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedSalesCreditMemos."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentsActionsNotVisible()
    var
        PostedSalesShipments: TestPage "Posted Sales Shipments";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted sales shipments page
        Initialize();

        // [WHEN] Posted sales shipments page is opened
        PostedSalesShipments.Trap();
        PAGE.Run(PAGE::"Posted Sales Shipments");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedSalesShipments."&Print".Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedSalesShipments."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemosActionsNotVisible()
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from purchase credit memos page
        Initialize();

        // [WHEN] Purchase credit memos page is opened
        PurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Purchase Credit Memos");

        // [THEN] Print action is not visible
        Assert.IsFalse(PurchaseCreditMemos.PostAndPrint.Visible(), 'Post and print button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesActionsNotVisible()
    var
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted purchase invoices page
        Initialize();

        // [WHEN] Posted purchase invoices page is opened
        PostedPurchaseInvoices.Trap();
        PAGE.Run(PAGE::"Posted Purchase Invoices");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedPurchaseInvoices."&Print".Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedPurchaseInvoices.Navigate.Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemosActionsNotVisible()
    var
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted purchase credit memos page
        Initialize();

        // [WHEN] Posted purchase credit memos page is opened
        PostedPurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Posted Purchase Credit Memos");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedPurchaseCreditMemos."&Print".Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedPurchaseCreditMemos."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsActionsNotVisible()
    var
        PostedPurchaseReceipts: TestPage "Posted Purchase Receipts";
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can initiate tasks from posted purchase receipts page
        Initialize();

        // [WHEN] Posted purchase receipts page is opened
        PostedPurchaseReceipts.Trap();
        PAGE.Run(PAGE::"Posted Purchase Receipts");

        // [THEN] Print and navigate actions are not visible
        Assert.IsFalse(PostedPurchaseReceipts."&Print".Visible(), 'Print button should not be visible.');
        Assert.IsFalse(PostedPurchaseReceipts."&Navigate".Visible(), 'Navigate button should not be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentSendingProfileUsesOfficeMgtProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ExpectedDocSendingProfile: Record "Document Sending Profile";
        Result: Boolean;
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Stan can email from posted sales documents
        Initialize();

        // [GIVEN] OfficeMgt is in test mode
        DocumentSendingProfile.GetOfficeAddinDefault(ExpectedDocSendingProfile, true);

        // [WHEN] Fetch the document sending profile
        Result := DocumentSendingProfile.LookupProfile('', true, true);

        // [THEN] Sending profile retrieved is the office add-in default (email as PDF).
        Assert.IsTrue(Result, 'Failed to lookup profile.');
        Assert.AreEqual(ExpectedDocSendingProfile.Code, DocumentSendingProfile.Code, 'Unexpected profile field value.');
        Assert.AreEqual(ExpectedDocSendingProfile.Default, DocumentSendingProfile.Default, 'Unexpected profile field value.');
        Assert.AreEqual(ExpectedDocSendingProfile."E-Mail", DocumentSendingProfile."E-Mail", 'Unexpected profile field value.');
        Assert.AreEqual(ExpectedDocSendingProfile."E-Mail Attachment", DocumentSendingProfile."E-Mail Attachment",
          'Unexpected profile field value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentBodyTextReplacesBase64WithUrl()
    var
        MailManagement: Codeunit "Mail Management";
        Regex: DotNet Regex;
        Body: Text;
        Base64Text: Text;
        UrlText: Text;
    begin
        Body := '<html><body>Picture: <img src="%1" width="50" height="60"></body></html>';
        Base64Text := StrSubstNo(Body, 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAARnQU1BAAC' +
            'xjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAASSURBVBhXYwCC////gygGBgYAGvMC/lpuXEoAAAAASUVORK5CYII=');
        UrlText := StrSubstNo(Body, 'https?:\/\/.*');
        Body := MailManagement.ImageBase64ToUrl(Base64Text);
        Assert.IsTrue(Regex.IsMatch(Body, UrlText), 'Body text doesn''t contain url.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentBodyTextReplacesMultipleBase64WithUrl()
    var
        MailManagement: Codeunit "Mail Management";
        Regex: DotNet Regex;
        Body: Text;
        Base64Text: Text;
        ImageUrl1: Text;
        ImageUrl2: Text;
    begin
        Body := '<html><body>Picture: <img src="%1" width="50" height="60"> <img src="%1" width="80" height="40"></body></html>';
        Regex := Regex.Regex(StrSubstNo(Body, '(https?:\/\/.*)'));
        Base64Text := StrSubstNo(Body, 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAAXNSR0IArs4c6QAAAARnQU1BAAC' +
            'xjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAASSURBVBhXYwCC////gygGBgYAGvMC/lpuXEoAAAAASUVORK5CYII=');

        Body := MailManagement.ImageBase64ToUrl(Base64Text);
        ImageUrl1 := Regex.Replace(Body, '$1', 1);
        ImageUrl2 := Regex.Replace(Body, '$2', 1);

        Assert.IsTrue(Regex.IsMatch(ImageUrl1, 'https?:\/\/.*'), 'Image not replaced with URL.');
        Assert.IsTrue(Regex.IsMatch(ImageUrl2, 'https?:\/\/.*'), 'Image not replaced with URL.');
        Assert.AreNotEqual(ImageUrl1, ImageUrl2, 'Image URLs are the same.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateQuoteMakeInvoice()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        QuoteNo: Code[20];
    begin
        // [FEATURE] [Contact] [Customer] [Sales Invoice]
        // [SCENARIO 156484] Stan initiates task Make Invoice from Quote
        Initialize();

        // [GIVEN] New contact assigned to customer and Outlook retrieves
        CreateOfficeAddinContext(OfficeAddinContext);

        // [THEN] Customer card is opened for associated email
        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();
        CreateSalesQuoteLine(SalesQuote);

        SalesInvoice.Trap();
        QuoteNo := SalesQuote."No.".Value();
        SalesQuote.MakeInvoice.Invoke();

        SalesInvoice."Quote No.".AssertEquals(QuoteNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageReminder()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        Reminder: TestPage Reminder;
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159038] Test Report should not be visible on Reminder page while the mail engine enabled.
        Initialize();

        // [GIVEN] New contact assigned to customer and Outlook retrieves
        CreateOfficeAddinContext(OfficeAddinContext);

        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Open Reminder page
        Reminder.Trap();
        CustomerCard.NewReminder.Invoke();

        // [THEN] Test Report action is not visible
        Assert.IsFalse(Reminder.TestReport.Visible(), 'Test Report should not be visible.');
    end;

    [Test]
    [HandlerFunctions('IssueReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageReminderIssueReminder()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        Reminder: TestPage Reminder;
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 160756] Email option should only be available when in Addin on Issue Reminders page
        Initialize();

        // [GIVEN] New contact assigned to customer and Outlook retrieves
        CreateOfficeAddinContext(OfficeAddinContext);

        RunOutlookMailEngine(OfficeAddinContext, CustomerCard);

        // [WHEN] Open Reminder page
        Reminder.Trap();
        CustomerCard.NewReminder.Invoke();
        // Need to run commit because run request page modal issue
        Commit();
        // [THEN] PrintDoc option is disabled
        Reminder.Issue.Invoke();
    end;

    local procedure Initialize()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ReportLayoutSelection: Record "Report Layout Selection";
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        OfficeHostType: DotNet OfficeHostType;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Office Addin Initiate Tasks");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);
        OfficeAttachmentManager.Done();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Office Addin Initiate Tasks");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        LibraryERMCountryData.SetupReportSelections();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySales.SetStockoutWarning(false);
        SetupCompanyPaymentInfo();
        SetupMarketing();
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        CreateDefaultDocSendingProfile();
        ReportLayoutSelection.DeleteAll();
        SetRDLCLayout(REPORT::"Standard Sales - Quote");
        SetRDLCLayout(REPORT::"Standard Sales - Invoice");
        SetRDLCLayout(REPORT::"Standard Sales - Credit Memo");
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Office Addin Initiate Tasks");
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@%2', CreateGuid(), 'example.com'));
    end;

    local procedure SetupMarketing()
    var
        MarketingSetup: Record "Marketing Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        MarketingSetup.Get();
        if MarketingSetup."Contact Nos." = '' then
            MarketingSetup.Validate("Contact Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        MarketingSetup.Modify();
    end;

    local procedure CreateContactFromCustomer(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]): Code[20]
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CreateContsFromCustomers: Report "Create Conts. from Customers";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibrarySales.CreateCustomer(Customer);

        // Create Contact from Customer by running the report Create Conts. from Customers.
        Customer.SetRecFilter();
        CreateContsFromCustomers.UseRequestPage(false);
        CreateContsFromCustomers.SetTableView(Customer);
        CreateContsFromCustomers.Run();

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.", Email);
        exit(Customer."No.");
    end;

    local procedure ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers: Code[10])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCodeForCustomers);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateContactEmail(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]; Email: Text[80]) ContactNo: Code[20]
    var
        Contact: Record Contact;
    begin
        ContactNo := FindContactNo(BusinessRelationCode, LinkToTable, LinkNo);
        Contact.Get(ContactNo);
        Contact."E-Mail" := Email;
        Contact."Search E-Mail" := UpperCase(Email);

        // Need to set the type to person, default of company will cause issues...
        Contact.Type := Contact.Type::Person;
        Contact.Modify(true);
    end;

    local procedure FindContactNo(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelationCode);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure CreateOfficeAddinContext(var OfficeAddinContext: Record "Office Add-in Context") CustomerNo: Code[20]
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OfficeHostType: DotNet OfficeHostType;
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        Initialize();
        TestEmail := RandomEmail();
        CustomerNo := CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode);

        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);
        OfficeAddinContext.SetRange(Email, TestEmail);
    end;

    local procedure CreateSalesInvoiceLine(var SalesInvoice: TestPage "Sales Invoice")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesInvoice.SalesLines.Type.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines."No.".SetValue(CreateItem());
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(5));
        SalesInvoice.SalesLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesCreditMemoLine(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesCreditMemo.SalesLines.Type.SetValue(Format(SalesLine.Type::Item));
        SalesCreditMemo.SalesLines."No.".SetValue(CreateItem());
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(5));
        SalesCreditMemo.SalesLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
    end;

    [Normal]
    local procedure CreateSalesQuoteLine(var SalesQuote: TestPage "Sales Quote")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesQuote.SalesLines.Type.SetValue(Format(SalesLine.Type::Item));
        SalesQuote.SalesLines."No.".SetValue(CreateItem());
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(5));
        SalesQuote.SalesLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure SetRDLCLayout(ReportID: Integer)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := ReportID;
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"RDLC (built-in)");
        ReportLayoutSelection.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ActionHandler(Message: Text[1024])
    var
        ExpectedAction: Variant;
        ExpectedParam2: Variant;
        ActualAction: Text;
        ActualParam1: Text;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAction);
        LibraryVariableStorage.Dequeue(ExpectedParam2);
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, ActualParam1);

        Assert.AreEqual(ExpectedAction, ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreNotEqual('', ActualParam1, 'The file URL is empty.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure EmailActionHandler(Message: Text[1024])
    var
        ActualAction: Text;
        ActualUrl: Text;
        ActualFileName: Text;
        ActualEmailBody: Text;
        ExpectedEmailBody: Text;
    begin
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, ActualUrl);
        ExtractComponent(Message, ActualFileName);
        ExtractComponent(Message, ActualEmailBody);

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualFileName, 'Incorrect file name passed to function.');
        ExpectedEmailBody := CopyStr(LibraryVariableStorage.DequeueText(), 1,
            1000 - StrLen(StrSubstNo('%1|%2|%3|', ActualAction, ActualUrl, ActualFileName)));
        Assert.AreEqual(ExpectedEmailBody, ActualEmailBody, 'Incorrect body text passed to function.');
        Assert.AreNotEqual('', ActualUrl, 'The file URL is empty.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceActionHandler(Message: Text[1024])
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BodyTextInStream: InStream;
        EmailBodyTempBlob: Codeunit "Temp Blob";
        BodyText: Text;
        ActualAction: Text;
        ActualUrl1: Text;
        ActualUrl2: Text;
        ActualFileName1: Text;
        ActualFileName2: Text;
        InvoiceFileName: Text;
        ActualEmailBody: Text;
        ExpectedEmailBody: Text;
        DummyEmailAddress: Text[250];
        InvoiceNo: Text;
        NoPos: Integer;
        CustNo: Code[20];
    begin
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, ActualUrl1);
        ExtractComponent(Message, ActualUrl2);
        ExtractComponent(Message, ActualFileName1);
        ExtractComponent(Message, ActualFileName2);
        ExtractComponent(Message, ActualEmailBody);

        if StrPos(LowerCase(ActualFileName1), 'invoice') > 0 then
            InvoiceFileName := ActualFileName1
        else
            InvoiceFileName := ActualFileName2;

        NoPos := StrPos(LowerCase(InvoiceFileName), 'invoice') + 8;
        InvoiceNo := CopyStr(InvoiceFileName, NoPos, StrPos(InvoiceFileName, '.') - NoPos);
        SalesInvoiceHeader.SetRange("No.", InvoiceNo);
        CustNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        ReportSelections.GetEmailBodyForCust(EmailBodyTempBlob, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, CustNo, DummyEmailAddress);
        EmailBodyTempBlob.CreateInStream(BodyTextInStream);
        BodyTextInStream.Read(BodyText);

        ExpectedEmailBody := CopyStr(BodyText, 1,
            1000 - StrLen(StrSubstNo('%1|%2|%3|%4|%5|', ActualAction, ActualUrl1, ActualUrl2, ActualFileName1, ActualFileName2)));

        Assert.AreNotEqual('', ActualUrl1, 'Two document urls not provided.');
        Assert.AreNotEqual('', ActualUrl2, 'Two document urls not provided.');
        Assert.AreNotEqual('', ActualFileName1, 'Two document names not provided.');
        Assert.AreNotEqual('', ActualFileName2, 'Two document names not provided.');
        Assert.AreEqual(ExpectedEmailBody, ActualEmailBody, 'Unexpected email body.');
    end;

    local procedure ExtractComponent(var String: Text; var Component: Text)
    var
        DelimiterPos: Integer;
    begin
        DelimiterPos := StrPos(String, '|');
        if DelimiterPos <> 0 then begin
            Component := CopyStr(String, 1, DelimiterPos - 1);
            String := CopyStr(String, DelimiterPos + 1);
        end else
            Component := String;
    end;

    local procedure UpdateCustomerDocSendingProfile(CustomerNo: Code[20]; DocSendingProfile: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."E-Mail" := 'testuser@somewhere.com';
        Customer."Document Sending Profile" := DocSendingProfile;
        Customer.Modify(true);
    end;

    local procedure CreateDefaultDocSendingProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.DeleteAll();
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := DefaultDocSendingProfileTxt;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Validate(Printer, DocumentSendingProfile.Printer::"Yes (Prompt for Settings)");
        DocumentSendingProfile.Validate("E-Mail", DocumentSendingProfile."E-Mail"::No);
        DocumentSendingProfile.Validate(Disk, DocumentSendingProfile.Disk::PDF);
        DocumentSendingProfile.Insert(true);
    end;

    local procedure SetReplyWithAttachment()
    begin
        LibraryVariableStorage.Enqueue('sendAttachment');
        LibraryVariableStorage.Enqueue('.pdf');
    end;

    local procedure RunOutlookMailEngine(var OfficeAddinContext: Record "Office Add-in Context"; var CustomerCard: TestPage "Customer Card")
    var
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        OutlookMailEngine.Trap();
        CustomerCard.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    local procedure SetupCompanyPaymentInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Allow Blank Payment Info.", true);
        CompanyInformation.Modify(true);
    end;

    [Normal]
    local procedure GetQuoteNextNo() QuoteNextNo: Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        DocNoSeries: Code[20];
    begin
        SalesReceivablesSetup.Get();
        DocNoSeries := SalesReceivablesSetup."Quote Nos.";
        QuoteNextNo := NoSeries.PeekNextNo(DocNoSeries);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueReminderRequestPageHandler(var IssueReminders: TestRequestPage "Issue Reminders")
    begin
        Assert.IsFalse(IssueReminders.PrintDoc.Enabled() = true, 'PrintDoc should be disabled.');
        IssueReminders.PrintDoc.AssertEquals('Email');
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SalesOrderShipAndInvoiceHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;
    end;
}

