codeunit 134640 "Sales E2E"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Contact] [Customer] [Quote] [Order] [Payment] [UI]
    end;

    var
        CustomerEmailTxt: Label 'Customer@contoso.com';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        SalesE2E: Codeunit "Sales E2E";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        DummyAddressTxt: Label '667 Fifth avenue';
        DummyCityTxt: Label 'New York';
        DummyFirstNameTxt: Label 'John';
        DummySurnameTxt: Label 'Doe';

    [Test]
    [HandlerFunctions('ContactNameDetailsHandler,CustTemplateListHandler,ConfirmHandlerYes,MessageHandler,SendNotificationHandler,PostAndSendConfirmationHandler,StrMenuHandler,ApplyCustomerEntriesHandler,StandardStatementSetRequestOptions')]
    [Scope('OnPrem')]
    procedure SalesFromContactToPayment()
    var
        SalesHeader: Record "Sales Header";
        CustomerTempl: Record "Customer Templ.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerNo: Code[20];
        ContactNo: Code[20];
        QuoteNo: Code[20];
        OrderNo: Code[20];
        PostedInvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [SCENARIO] E2E scenario: user is able to manage simple sales activities: create contact, create customer from contact,
        // [SCENARIO] create quote, create order from quote, post order, post payment applied to posted order, and finally to run customer statement
        Initialize();
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustomerTempl."Contact Type" := CustomerTempl."Contact Type"::Person;
        CustomerTempl.Modify();

        // [GIVEN] Create contact, fill name and address fields, create customer from contact
        ContactNo := CreateContactAsCustomer();
        CustomerNo := FindCustomerByContact(ContactNo);

        // [GIVEN] Create sales quote with several items for created customer, send it by e-mail
        QuoteNo := CreateQuote(CustomerNo);

        // [GIVEN] Convert sales quote to order from contact list, send e-mail confirmation
        OrderNo := ConvertQuoteToOrderFromContactList(ContactNo, QuoteNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo);
        SalesHeader.Validate("Bal. Account No.", '');
        SalesHeader.Modify();

        // [GIVEN] Post and send by e-mail created order
        PostedInvoiceNo := PostSendSalesOrder(OrderNo);

        // [GIVEN] Create and post payment for full invoice's amount
        PaymentNo := CreatePostPayment(PostedInvoiceNo, CustomerNo);

        // [WHEN] Standard statement is being printed for customer
        PrintCustomerStatement(CustomerNo);

        // [THEN] Statement contains both invoice and payment
        VerifyCustomerStatement(PostedInvoiceNo, PaymentNo);

        // Cleanup
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('StandardStatementSetRequestOptions')]
    [Scope('OnPrem')]
    procedure TestCustomerLastStatementNo()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        LastStatementNo: Integer;
    begin
        // [SCENARIO 456488] Customer Statement numbering issue

        // [GIVEN] Create Item, create Sales Order and post
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LastStatementNo := Customer."Last Statement No.";

        // [WHEN] Standard statement is being printed for customer
        PrintCustomerStatement(Customer."No.");

        // [VERIFY] Verify: Last Statement No. printed on Customer "Standard Statement" report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LastStatmntNo_Cust', Format(LastStatementNo + 1));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales E2E");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryVariableStorage.Clear();
        DisableSendMails();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales E2E");
    end;

    local procedure CreateContactAsCustomer(): Code[20]
    var
        DummyContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenNew();
        ContactCard.Type.SetValue(DummyContact.Type::Person);
        ContactCard.Name.AssistEdit();
        ContactCard.Address.SetValue(DummyAddressTxt);
        ContactCard.City.SetValue(DummyCityTxt);
        ContactCard."Post Code".SetValue(FindPostCode());
        ContactCard."E-Mail".SetValue(CustomerEmailTxt);
        ContactCard.CreateCustomer.Invoke();
        exit(ContactCard."No.".Value);
    end;

    local procedure CreateQuote(CustomerNo: Code[20]): Code[20]
    var
        SalesQuote: TestPage "Sales Quote";
        i: Integer;
    begin
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer No.".SetValue(CustomerNo);

        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateQuoteLine(SalesQuote);

        SalesQuote.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));
        SalesQuote.Email.Invoke();
        exit(SalesQuote."No.".Value);
    end;

    local procedure CreateQuoteLine(var SalesQuote: TestPage "Sales Quote")
    var
        DummySalesLine: Record "Sales Line";
    begin
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Type.SetValue(DummySalesLine.Type::Item);
        SalesQuote.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(5, 10));
        SalesQuote.SalesLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(10, 50, 2));
    end;

    local procedure ConvertQuoteToOrderFromContactList(ContactNo: Code[20]; QuoteNo: Code[20]): Code[20]
    var
        ContactList: TestPage "Contact List";
        SalesQuotes: TestPage "Sales Quotes";
        SalesOrder: TestPage "Sales Order";
    begin
        ContactList.OpenView();
        ContactList.FILTER.SetFilter("No.", ContactNo);
        SalesQuotes.Trap();
        ContactList.ShowSalesQuotes.Invoke();
        SalesQuotes.FILTER.SetFilter("No.", QuoteNo);
        SalesOrder.Trap();
        SalesQuotes.MakeOrder.Invoke();
        SalesOrder.SendEmailConfirmation.Invoke();
        exit(SalesOrder."No.".Value);
    end;

    local procedure CreatePostPayment(InvoiceNo: Code[20]; CustomerNo: Code[20]) PaymentNo: Code[20]
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Posting Date".SetValue(WorkDate() + 60);
        CashReceiptJournal."Document Type".SetValue(DummyGenJournalLine."Document Type"::Payment);
        CashReceiptJournal."Account Type".SetValue(DummyGenJournalLine."Account Type"::Customer);
        CashReceiptJournal."Account No.".SetValue(CustomerNo);
        CashReceiptJournal."Applies-to Doc. Type".SetValue(DummyGenJournalLine."Applies-to Doc. Type"::Invoice);
        LibraryVariableStorage.Enqueue(InvoiceNo);
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        PaymentNo := CashReceiptJournal."Document No.".Value();
        CashReceiptJournal.Post.Invoke();
    end;

    local procedure DisableSendMails()
    begin
        BindSubscription(SalesE2E);
    end;

    local procedure FindCustomerByContact(ContactNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."No.");
    end;

    local procedure FindPostCode(): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.FindPostCode(PostCode);
        exit(PostCode.Code);
    end;

    local procedure PostSendSalesOrder(OrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", OrderNo);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesOrder."Sell-to Customer No.".Value);
        SalesOrder.PostAndSend.Invoke();
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure PrintCustomerStatement(CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
        Commit();
        REPORT.Run(REPORT::"Standard Statement");
    end;

    local procedure VerifyCustomerStatement(PostedInvoiceNo: Code[20]; PaymentNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_DtldCustLedgEntries', PostedInvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('DocNo_DtldCustLedgEntries', PaymentNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactNameDetailsHandler(var NameDetails: TestPage "Name Details")
    begin
        NameDetails."First Name".SetValue(DummyFirstNameTxt);
        NameDetails.Surname.SetValue(DummySurnameTxt);
        NameDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustTemplateListHandler(var CustomerTemplateList: TestPage "Select Customer Templ. List")
    begin
        CustomerTemplateList.First();
        CustomerTemplateList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationHandler(var PostAndSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostAndSendConfirmation.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementSetRequestOptions(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(CalcDate('<-CY>', WorkDate()));
        StandardStatement."End Date".SetValue(CalcDate('<CY>', WorkDate()));
        StandardStatement.IncludeAllCustomerswithLE.SetValue(true);
        StandardStatement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardStatement.ReportOutput.SetValue('Preview');
        StandardStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 3; // Ship and Invoice
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        if Question = 'Do you want to create a follow-up task?' then
            Reply := false
        else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeDoSending', '', false, false)]
    local procedure DoNotSendMails(var CancelSending: Boolean)
    begin
        CancelSending := true;
    end;
}

