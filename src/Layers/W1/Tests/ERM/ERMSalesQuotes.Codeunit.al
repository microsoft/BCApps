codeunit 134379 "ERM Sales Quotes"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Quote] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3.';
        FieldError: Label '%1 not updated correctly.';
        QuoteToOrderMessage: Label 'Do you want to convert the quote to an order?';
        LineError: Label 'No. of Lines must be Equal.';
        UnknownError: Label 'Unexpected Error.';
        SalesDocExistErr: Label 'You cannot delete resource %1 because there are one or more outstanding %2 that include this resource.', Comment = '%1 = Resource No. %2 = Document Type';
        DialogErrorCodeTok: Label 'Dialog';
        OpenNewOrderQst: Label 'The quote has been converted to order', Comment = '%1 = No. of the new sales order document.';
        ControlShouldBeDisabledErr: Label 'Control should be disabled';
        ControlShouldBeEnabledErr: Label 'Control should be enabled';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when customer is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when customer is selected.';
        BillToAddressFieldsNotEditableErr: Label 'Bill-to address fields should not be editable.';
        BillToAddressFieldsEditableErr: Label 'Bill-to address fields should be editable.';
        LinesUneditableErr: Label 'Lines should not be editable.';
        LinesEditableErr: Label 'Lines should be editable.';
        CopyCustTemplateErr: Label 'Customer template copied incorrectly.';
        DifferentCustomerTemplateMsg: Label 'Sales quote %1 with original customer template %2 was assigned to the customer created from template %3.', Comment = '%1=Document No.,%2=Original Customer Template Code,%3=Customer Template Code';
        NoOriginalCustomerTemplateMsg: Label 'Sales quote %1 without an original customer template was assigned to the customer created from template %2.', Comment = '%1=Document No.,%2=Customer Template Code';

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
    begin
        // Test if the system allows to create New Sales Quote for Customer.

        // Setup.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // Exercise: Create Sales Quote.
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));

        // Verify: Verify Blanket Sales Quote.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Test if the system calculates applicable VAT in Sales Quote.

        // Setup: Create Sales Quote with Multiple Sales Quote Line.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));

        // Calculate VAT Amount on Sales Quote.
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify VAT Amount on Sales Quote.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          SalesHeader.Amount * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, VATAmountLine.FieldCaption("VAT Amount"), SalesHeader.Amount * SalesLine."VAT %" / 100,
            VATAmountLine.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
        LineCount: Integer;
        ResponsibilityCenterCode: Code[10];
    begin
        // [SCENARIO] Test Create Sales Order from Sales Quote.

        // [GIVEN] Sales Quote "Q" where "Responsibility Center" = "RC" and Total no. of Lines = "NumL"
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));
        LineCount := FindSalesLineCount(SalesHeader."No.");
        ResponsibilityCenterCode := SalesHeader."Responsibility Center";

        // [WHEN] Create Sales Order "O" form "Q"
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] O."Responsibility Center" = "RC" and O.SalesLine.COUNT = "NumL"
        FindSalesLine(SalesLine, SalesHeader."No.");
        Assert.AreEqual(LineCount, SalesLine.Count, LineError);
        FindSalesOrderHeader(SalesHeader);
        SalesHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuoteWithVATRegNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
    begin
        // [SCENARIO] Test Create Sales Order from Sales Quote with "VAT Registration No."

        // [GIVEN] Sales Quote for the Customer without "VAT Registration No."
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        LibrarySales.CreateCustomer(Customer);
        Customer.TestField("VAT Registration No.", '');

        CreateSalesQuote(SalesHeader, SalesLine, Customer."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Update "VAT Registration No." on Customer
        Customer."VAT Registration No." :=
            LibraryUtility.GenerateRandomCode20(Customer.FieldNo("VAT Registration No."), Database::Customer);
        Customer.Modify();

        // [WHEN] Create Sales Order from Quote
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] Check "VAT Registration No." on Sales Order equal to Customer "VAT Registration No."
        FindSalesOrderHeader(SalesHeader);
        SalesHeader.TestField("VAT Registration No.", Customer."VAT Registration No.");

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteWithContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Quote with Contact and check Sell to Customer is getting updated.

        // Setup: Find Contact from Contact Business Relation that have setup for a Customer.
        Initialize();
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst();

        // Exercise: Create Sales Quote for Contact.
        SalesHeader.Insert(true);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Sell-to Contact No.", ContactBusinessRelation."Contact No.");
        SalesHeader.Modify(true);

        // Verify: Verify that New Sales Quote updated correct Sell to Customer No.
        Assert.AreEqual(
          ContactBusinessRelation."No.", SalesHeader."Sell-to Customer No.",
          StrSubstNo(FieldError, SalesHeader.FieldCaption("Sell-to Customer No.")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesQuoteWithCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
    begin
        // Check if the system allows changing Sell to Contact No. in Sales Quote and Check Sales Line updated for the same.

        // Setup: Create Sales Quote with Multiple Sales Quote Line.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));

        // Exercise: Update Sales Header with different Sell to Customer No.
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomer());
        SalesHeader.Modify(true);

        // Verify: Verify Sell to Customer No in Sales Line table.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(
          SalesHeader."Sell-to Customer No.", SalesLine."Sell-to Customer No.",
          StrSubstNo(FieldError, SalesLine.FieldCaption("Sell-to Customer No.")));

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvDiscFromSaleQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
        InvDiscountAmount: Decimal;
    begin
        // Check Invoice Discount has been flow correctly on Sales Order after Make Order from Sales Quote.

        // Setup: Create Sales Quote and Calculate Invoice Discount with 1 Fix Sales Quote Line.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomerInvDiscount(CreateCustomer()), 1);
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        InvDiscountAmount := SalesLine."Inv. Discount Amount";

        // Exercise: Make Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // Verify: Verify Sales Quote Line for Invoice Discount after run Make Order.
        FindSalesLine(SalesLine, SalesHeader."No.");
        Assert.AreNearlyEqual(
          InvDiscountAmount, SalesLine."Inv. Discount Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErrorMessage, SalesLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, SalesLine.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteToOrderFalse')]
    [Scope('OnPrem')]
    procedure SalesQuoteConfirmDialogFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
        LineCount: Integer;
    begin
        // Convert Sales Quote to an Order. Click No on Confirmation Dialog Box to invoke NO Button Using Handler.

        // Setup: Create Sales Quote and store Total no. of Lines count in a variable with Multiple Sales Quote Line.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));
        LineCount := FindSalesLineCount(SalesHeader."No.");

        // Exercise: Create Sales Order form Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);

        // Verify: Verify Sales Quote Exists. Verify Message on Message Dialog in SalesQuoteToOrderFalse Handler.
        Assert.AreEqual(LineCount, FindSalesLineCount(SalesHeader."No."), LineError);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteToOrderTrue')]
    [Scope('OnPrem')]
    procedure SalesQuoteConfirmDialogTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrder: TestPage "Sales Order";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
        LineCount: Integer;
    begin
        // Convert Sales Quote to an Order. Click Yes on Confirmation Dialog Box to invoke YES Button Using Handler.

        // Setup: Create Sales Quote and store Total no. of Lines count in a variable with Multiple Sales Quote Line.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));
        LineCount := FindSalesLineCount(SalesHeader."No.");

        SalesOrder.Trap();

        LibraryVariableStorage.Enqueue(QuoteToOrderMessage);
        LibraryVariableStorage.Enqueue(OpenNewOrderQst);

        // Exercise: Create Sales Order form Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();

        // Verify: Verify that New Sales Order created from Sales Quote.
        // Verify Message on Message Dialog in SalesQuoteToOrderFalse Handler.
        FindSalesLine(SalesLine, SalesHeader."No.");
        Assert.AreEqual(LineCount, SalesLine.Count, LineError);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuoteWithPostingDateBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
        OldStockoutWarning: Boolean;
    begin
        // Check that blank Posting Date is populating on created Sales Order from Sales Quote while Default Posting Date is set to No Date on the Sales & Receivables Setup.

        // Setup: Update Sales & Receivables Setup and create Sales Quote.
        Initialize();
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"No Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));  // Take Randon value for Number of lines.
        // To avoid failure in IT, using Posting Date as Document Date when Default Posting Date: "No Date" in Sales & Receivables Setup.
        SalesHeader.Validate("Document Date", SalesHeader."Posting Date");
        SalesHeader.Modify(true);

        // Exercise: Create Sales Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // Verify: Verify that New Sales Order created from Sales Quote with Posting Date blank.
        VerifyPostingDateOnOrder(SalesHeader, SalesHeader."No.");

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DeleteResourceExistedInSalesQuote()
    var
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Resource]
        // [SCENARIO 376793] Not possible to delete resource which exists in Sales Quote

        Initialize();
        // [GIVEN] Sales Line with Type = "Resource" and "Resouce No." = "X"
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Quote;
        SalesLine.Type := SalesLine.Type::Resource;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");
        SalesLine."No." := Resource."No.";
        SalesLine.Insert();

        // [WHEN] Delete Resouce "X"
        asserterror Resource.Delete(true);

        // [THEN] Error "You cannot delete resource "X" because there one or more outstanding Quote that include this resource" shown
        Assert.ExpectedError(StrSubstNo(SalesDocExistErr, Resource."No.", SalesLine."Document Type"::Quote));
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesQuotesControlsDisableNoQuotes()
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 202130] Actions on Sales Quote Page not enabled if no Quotes exist in the list

        // [GIVEN] No Sales Quote exist
        DeleteSalesQuotes();

        // [WHEN] Sales Quotes page is opened
        SalesQuotes.OpenView();

        // [THEN] All controls related with Sales Quote are disabled
        Assert.IsFalse(SalesQuotes.Email.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Print.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.MakeOrder.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.MakeInvoice.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Approvals.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Dimensions.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Customer.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes."C&ontact".Enabled(), ControlShouldBeDisabledErr);
#if not CLEAN26
        Assert.IsFalse(SalesQuotes.Statistics.Enabled(), ControlShouldBeDisabledErr);
#endif
        Assert.IsFalse(SalesQuotes.SalesStatistics.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes."Co&mments".Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.CreateCustomer.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.CreateTask.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Release.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.Reopen.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.SendApprovalRequest.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.CancelApprovalRequest.Enabled(), ControlShouldBeDisabledErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesQuotesControlsEnabledWithSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 202130] Actions on Sales Quote Page are enabled if Quotes exist in the list

        // [GIVEN] Sales Quote "SQ" ith "Sell-to Customer No." and "Sell-to Contact No." filled
        DeleteSalesQuotes();
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Sales Quotes page is opened
        SalesQuotes.OpenView();

        // [THEN] All controls related with Sales Quote are enabled, except "Create Customer" and "Cancel Approval Request"
        Assert.IsTrue(SalesQuotes.Email.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Print.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.MakeOrder.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.MakeInvoice.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Approvals.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Dimensions.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Customer.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes."C&ontact".Enabled(), ControlShouldBeEnabledErr);
#if not CLEAN26
        Assert.IsTrue(SalesQuotes.Statistics.Enabled(), ControlShouldBeEnabledErr);
#endif
        Assert.IsTrue(SalesQuotes.SalesStatistics.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes."Co&mments".Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuotes.CreateCustomer.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsTrue(SalesQuotes.CreateTask.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Release.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.Reopen.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuotes.SendApprovalRequest.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsFalse(SalesQuotes.CancelApprovalRequest.Enabled(), ControlShouldBeDisabledErr);
        SalesQuotes.Close();

        // [WHEN] "Sell-to Contact No." = '' in Sales Quote
        SalesHeader."Sell-to Contact No." := '';
        SalesHeader.Modify();
        SalesQuotes.OpenView();

        // [THEN] "Contact" control is disabled
        Assert.IsFalse(SalesQuotes."C&ontact".Enabled(), ControlShouldBeDisabledErr);
        SalesQuotes.Close();

        // [WHEN] "Sell-to Contact No." = "C", "Sell-to Customer No." = ''
        SalesHeader."Sell-to Contact No." := Contact."No.";
        SalesHeader."Sell-to Customer No." := '';
        SalesHeader.Modify();
        SalesQuotes.OpenView();

        // [THEN] "Contact" control is enabled, "Customer" control - disabled, "Create Customer" - enabled
        Assert.IsTrue(SalesQuotes."C&ontact".Enabled(), ControlShouldBeEnabledErr);
        Assert.IsFalse(SalesQuotes.Customer.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsTrue(SalesQuotes.CreateCustomer.Enabled(), ControlShouldBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssignCustomerTemplateCodeAfterConfirmationWhenValidateContact()
    var
        CustomerTemplate: Record "Customer Templ.";
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT] [Customer Template]
        // [SCENARIO 382435] Isaac can assign "Customer Template" after confirmation when validate "Contact No."

        Initialize();

        // [GIVEN] Customer Template "CUST"
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);

        // [GIVEN] Contact "X" without relation to any Customer
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Sales Quote
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader.Insert(true);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code); // for CustomerTemplateListModalPageHandler

        // [WHEN] Validate "Contact No." in Sales Quote and confirm "Customer Template" selection with code "CUST"
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");

        // [THEN] "Sell-to Customer Template Code" is assigned according to selected "Customer Template"
        SalesHeader.TestField("Sell-to Customer Templ. Code", CustomerTemplate.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerTemplateListModalPageHandler,ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssignCustomerTemplateCodeAfterConfirmationWhenLookupContact()
    var
        CustomerTemplate: Record "Customer Templ.";
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Customer Template]
        // [SCENARIO 382435] Isaac can assign "Customer Template" after confirmation when lookup "Contact No."

        Initialize();

        // [GIVEN] Customer Template "CUST"
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);

        // [GIVEN] Contact "X" without relation to any Customer
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."No."); // for ContactListModalPageHandler

        // [GIVEN] Sales Quote
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader.Insert(true);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code); // for CustomerTemplateListModalPageHandler

        // [GIVEN] Opened "Sales Quote" page
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] Lookup "Contact No." in Sales Quote and confirm "Customer Template" selection with code "CUST"
        SalesQuote."Sell-to Contact No.".Lookup();
        SalesQuote.Close();

        // [THEN] "Sell-to Customer Template Code" is assigned according to selected "Customer Template"
        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer Templ. Code", CustomerTemplate.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteExtendedText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtendedTextLine: array[2] of Record "Extended Text Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 201839] Extended Texts are being pulled into the sales document if there are more than just one Extended Text for an item

        Initialize();

        // [GIVEN] Item with Extended Texts "X" and "Y"
        Item.Get(CreateItem());
        CreateExtendedTextForItem(Item, ExtendedTextLine[1]);
        CreateExtendedTextForItem(Item, ExtendedTextLine[2]);

        // [WHEN] Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Insert Extended Text into the Sales Line.
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesQuote.SalesLines.InsertExtTexts.Invoke();

        // [THEN] Desription of the Sales Line with type " " must match with "X" or "Y".
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.SetRange(Description, ExtendedTextLine[1].Text);
        Assert.RecordIsNotEmpty(SalesLine);
        SalesLine.SetRange(Description, ExtendedTextLine[2].Text);
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteControlsDisabledBeforeCustomerSelected()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Actions on Sales Quote Page not enabled if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Quote page is opened on SaaS
        SalesQuote.OpenNew();

        // [THEN] All controls related to customer (and on SaaS) are disabled
        Assert.IsFalse(SalesQuote.MakeOrder.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.MakeInvoice.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.CalculateInvoiceDiscount.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.Email.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.Print.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.GetRecurringSalesLines.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesQuote.CopyDocument.Enabled(), ControlShouldBeDisabledErr);

        SalesQuote.Close();

        // [WHEN] Sales Quotes page is opened with no application area
        LibraryApplicationArea.DisableApplicationAreaSetup();
        SalesQuote.OpenNew();

        // [THEN] All controls related to customer (and not on SaaS) are disabled
#if not CLEAN26
        Assert.IsFalse(SalesQuote.Statistics.Enabled(), ControlShouldBeDisabledErr);
#endif
        Assert.IsFalse(SalesQuote.SalesStatistics.Enabled(), ControlShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteControlsEnabledAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Actions on Sales Quote Page are enabled if customer is selected
        Initialize();

        // [Given] A sample sales quote
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));

        // [WHEN] Sales Quote page is opened on SaaS
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] All controls related to customer (and on SaaS) are enabled
        Assert.IsTrue(SalesQuote.MakeOrder.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.MakeInvoice.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.CalculateInvoiceDiscount.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.Email.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.Print.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.GetRecurringSalesLines.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesQuote.CopyDocument.Enabled(), ControlShouldBeEnabledErr);

        SalesQuote.Close();

        // [WHEN] Sales Quotes page is opened with no application area
        LibraryApplicationArea.DisableApplicationAreaSetup();

        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] All controls related to customer (and not on SaaS) are enabled
#if not CLEAN26
        Assert.IsTrue(SalesQuote.Statistics.Enabled(), ControlShouldBeEnabledErr);
#endif

        Assert.IsTrue(SalesQuote.SalesStatistics.Enabled(), ControlShouldBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteContactNotEditableBeforeCustomerSelected()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Quote Page not editable if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Quote page is opened
        SalesQuote.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(SalesQuote."Sell-to Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteContactEditableAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Quote Page editable if customer selected
        // [Given]
        Initialize();

        // [Given] A sample Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer());

        // [WHEN] Sales Quote page is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(SalesQuote."Sell-to Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteBillToAddressFieldsNotEditableIfSameSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Sell-to Address Fields on Sales Quote Page not editable if Customer selected equals sell-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer());

        // [WHEN] Sales Quote page is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(SalesQuote."Bill-to Address".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesQuote."Bill-to Address 2".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesQuote."Bill-to City".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesQuote."Bill-to Contact".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesQuote."Bill-to Post Code".Editable(), BillToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesQuoteBillToAddressFieldsEditableIfDifferentSellToCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Sell-to Address Fields on Sales Quote Page editable if Customer selected not equals Sell-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer());

        // [WHEN] Sales Quote page is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] Another Pay-to vendor is picked
        Customer.Get(CreateCustomer());
        SalesQuote."Bill-to Name".SetValue(Customer.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(SalesQuote."Bill-to Address".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesQuote."Bill-to Address 2".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesQuote."Bill-to City".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesQuote."Bill-to Contact".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesQuote."Bill-to Post Code".Editable(), BillToAddressFieldsEditableErr);
    end;

    [Test]
    [HandlerFunctions('SalesCreditLimitOnSalesOrderNotificationHandler,ConfirmHandlerYes,SalesOrderPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_CreditLimitNotificationShownInSalesOrderCreatedFromQuote()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 209065] "Credit Limit" notification is shown when create Sales Order from Sales Quote

        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] "Credit Warnings"  set to "Credit Limit" in "Sales & Receivables Setup"
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        LibrarySales.SetStockoutWarning(false); // make sure no "out of stock" notification will be send

        // [GIVEN] Customer "X" with "Credit Limit (LCY)" = 1
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", 1);
        Customer.Modify(true);

        // [GIVEN] Sales Quote "SQ" with Customer "X" and Amount = 100
        CreateSalesQuote(SalesHeader, SalesLine, Customer."No.", 1);

        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT");
        SalesHeader.SetRecFilter();

        // [GIVEN] Sales Quote page with "SQ" is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] Action "Make Order" is invoked on Sales Quote page
        SalesQuote.MakeOrder.Invoke();

        // [THEN] Notification "Credit Limit" is shown
        // Verification done in CreditLimitNotificationHandler

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityNotificationHandler,ConfirmHandlerYes,SalesOrderPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_ItemAvailabilityNotificationShownInSalesOrderCreatedFromQuote()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 209065] "Item Availability" notification is shown when create Sales Order from Sales Quote

        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] "Credit Warnings"  set to "Credit Limit" in "Sales & Receivables Setup"
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning"); // make sure no "credit limit" notification will be send
        LibrarySales.SetStockoutWarning(true);

        // [GIVEN] Sales Quote "SQ" with Customer "X" and Amount = 100
        CreateSalesQuote(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), 1);

        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        SalesHeader.SetRecFilter();

        // [GIVEN] Sales Quote page with "SQ" is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] Action "Make Order" is invoked on Sales Quote page
        SalesQuote.MakeOrder.Invoke();

        // [THEN] Notification "Item Availability" is shown
        // Verification done in ItemAvailabilityNotificationHandler

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerTemplateListModalPageHandler,MessageHandler,SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure UpdatedShipToFieldsOfSalesQuoteFromTemplateMovedToSalesOrder()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesQuote: TestPage "Sales Quote";
        PackageTrackingNo: Text;
        SalesQuoteNo: Code[20];
    begin
        // [FEATURE] [UI] [Contact] [Customer Template]
        // [SCENARIO 228972] If you create a new sales quote from template, it must be possible to populate the Ship-to fields

        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Sales Quote is created for new Contact with Customer Template Code
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Customer Template "CUST"
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code); // for CustomerTemplateListModalPageHandler

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");
        SalesQuoteNo := SalesQuote."No.".Value();

        // [GIVEN] "Ship-to Contact" field is updated on Shipping and Billing tab of the Sales Quote with "STC" value
        SalesQuote."Ship-to Contact".SetValue(Contact."No.");

        // [GIVEN] "Shipment Method Code" field is updated on Shipping and Billing tab of the Sales Quote with "SMC" value
        ShipmentMethod.FindFirst();
        SalesQuote."Shipment Method Code".SetValue(ShipmentMethod.Code);

        // [GIVEN] "Shipping Agent Code" field is updated on Shipping and Billing tab of the Sales Quote with "SAC" value
        ShippingAgentServices.FindFirst();
        ShippingAgent.SetRange(Code, ShippingAgentServices."Shipping Agent Code");
        ShippingAgent.FindFirst();
        SalesQuote."Shipping Agent Code".SetValue(ShippingAgent.Code);

        // [GIVEN] "Shipping Agent Service Code" field is updated on Shipping and Billing tab of the Sales Quote with "SASC" value
        SalesQuote."Shipping Agent Service Code".SetValue(ShippingAgentServices.Code);

        // [GIVEN] "Package Tracking No." field is updated on Shipping and Billing tab of the Sales Quote with "PTN" value
        PackageTrackingNo := LibraryUtility.GenerateRandomText(10);
        SalesQuote."Package Tracking No.".SetValue(PackageTrackingNo);

        // [WHEN] Make Sales Order from the Sales Quote
        SalesQuote.MakeOrder.Invoke();
        SalesHeader.SetRange("Quote No.", SalesQuoteNo);
        SalesHeader.FindFirst();

        // [THEN] Sales Order has "Ship-to Contact" = "STC"
        SalesHeader.TestField("Ship-to Contact", Contact."No.");

        // [THEN] Sales Order has "Shipment Method Code" = "SMC"
        SalesHeader.TestField("Shipment Method Code", ShipmentMethod.Code);

        // [THEN] Sales Order has "Shipping Agent Code" = "SAC"
        SalesHeader.TestField("Shipping Agent Code", ShippingAgent.Code);

        // [THEN] Sales Order has "Shipping Agent Service Code" = "SASC"
        SalesHeader.TestField("Shipping Agent Service Code", ShippingAgentServices.Code);

        // [THEN] Sales Order has "Package Tracking No." = "PTN"
        SalesHeader.TestField("Package Tracking No.", PackageTrackingNo);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankSalesQuoteLinesUneditable()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 234080] Lines of a blank sales quote should not be editable.
        SalesQuote.OpenNew();
        Assert.IsFalse(SalesQuote.SalesLines.Description.Editable(), LinesUneditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteWithSellToCustomerNoLinesEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 234080] When open sales quote with populated "Sell-to Customer No." lines are editable.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesQuote.SalesLines.Description.Editable(), LinesEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteWithSellToCustomerTemplateLinesEditable()
    var
        CustomerTemplate: Record "Customer Templ.";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 234080] When open sales quote with populated "Sell-to Customer Template Code" lines are editable.
        SalesQuote.OpenNew();
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        SalesQuote."Sell-to Customer Templ. Code".SetValue(CustomerTemplate.Code);
        Assert.IsTrue(SalesQuote.SalesLines.Description.Editable(), LinesEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SalesQuoteWithSellToContactNoLinesEditable()
    var
        Contact: Record Contact;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 234080] When open sales quote with populated "Sell-to Contact No." lines are editable.
        SalesQuote.OpenNew();
        LibraryMarketing.CreateCompanyContact(Contact);
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");
        Assert.IsTrue(SalesQuote.SalesLines.Description.Editable(), LinesEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteYourReferenceQuoteValidUntilDateFieldsVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 253884] Fields "Your Reference" and "Quote Valid Until Date" can be viewed on Sales Quote page

        // [GIVEN] Sales Quote with "Your Reference" = Y and "Quote Valid Until Date" = D exist
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        SalesHeader.Validate(
          "Your Reference",
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(SalesHeader."Your Reference")));
        SalesHeader.Validate(
          "Quote Valid Until Date",
          SalesHeader."Document Date" + 1);
        SalesHeader.Modify();

        // [WHEN] Page Sales Quote is opened
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Sales Quote page has "Your Reference" = Y and "Quote Valid Until Date" = D
        SalesQuote."Your Reference".AssertEquals(SalesHeader."Your Reference");
        SalesQuote."Quote Valid Until Date".AssertEquals(SalesHeader."Quote Valid Until Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteYourReferenceQuoteValidUntilDateFieldsEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        SalesDocNo: Code[20];
        SalesDocYourReference: Text[35];
        SalesDocQuoteValidUntilDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 253884] Fields "Your Reference" and "Quote Valid Until Date" can be edited on Sales Quote page

        // [GIVEN] Sales Quote page opened
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer No.".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] "Your Reference" = Y and "Quote Valid Until Date" = D are filled on Sales Quote page
        SalesQuote."Your Reference".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(SalesHeader."Your Reference")));
        SalesQuote."Quote Valid Until Date".SetValue(
          SalesQuote."Document Date".AsDate() + 1);
        SalesDocNo := SalesQuote."No.".Value();
        SalesDocYourReference := SalesQuote."Your Reference".Value();
        SalesDocQuoteValidUntilDate := SalesQuote."Quote Valid Until Date".AsDate();
        SalesQuote.Close();

        // [THEN] Created Sales Header record has "Your Reference" = Y and "Quote Valid Until Date" = D
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesDocNo);
        SalesHeader.TestField("Your Reference", SalesDocYourReference);
        SalesHeader.TestField("Quote Valid Until Date", SalesDocQuoteValidUntilDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerTemplateListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromQuoteWithPersonContactLinkedToCompanyContact()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ContactPerson: array[2] of Record Contact;
        ContactCompany: array[2] of Record Contact;
        CustomerTemplate: Record "Customer Templ.";
    begin
        // [SCENARIO 262275] Create customers function from quote with contact of person type which is linked to contact of company type causes creating customer based on contact-company
        Initialize();

        // [GIVEN] Contact COMP1 with type Company
        // [GIVEN] Contact PERS1 with type Person linked to contact COMP1
        LibraryMarketing.CreatePersonContactWithCompanyNo(ContactPerson[1]);
        ContactCompany[1].Get(ContactPerson[1]."Company No.");

        // [GIVEN] Contact COMP2 with type Company
        // [GIVEN] Contact PERS2 with type Person linked to contact COMP2
        LibraryMarketing.CreatePersonContactWithCompanyNo(ContactPerson[2]);
        ContactCompany[2].Get(ContactPerson[2]."Company No.");

        // [GIVEN] Sales quote created from contact PERS1 (Sell-to Contact = PERS1)
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code); // for CustomerTemplateListModalPageHandler
        CreateQuoteFromContact(SalesHeader, ContactPerson[1]."No.");

        // [GIVEN] Sales quote has Bill-to Contact = PERS2
        SalesHeader.Validate("Bill-to Contact No.", ContactPerson[2]."No.");
        SalesHeader.Modify();

        // [WHEN] Customers are being created from quote
        SalesHeader.CheckCustomerCreated(false);

        // [THEN] Created sales-to customer is based on contact COMP1
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.TestField(Name, ContactCompany[1].Name);

        // [THEN] Created bill-to customer is based on contact COMP2
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.TestField(Name, ContactCompany[2].Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteValidUntilDateOnValidateDocumentDate()
    var
        SalesHeader: Record "Sales Header";
        ExpectedQuoteValidUntilDate: Date;
    begin
        // [FEATURE] [Quote Valid To Date]
        // [SCENARIO 280680] "Quote Valid Until Date" calculated based on "Document Date" and SalesSetup."Quote Validity Calculation"
        Initialize();

        // [GIVEN] Create sales qoute
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Set SalesSetup."Quote Validity Calculation" = 30D
        SetSalesSetupQuoteValidUntilDate('<30D>');

        // [WHEN] Set "Document Date" = 01.01.2018
        SalesHeader.Validate("Document Date", CalcDate('<10D>', SalesHeader."Document Date"));

        // [THEN] "Quote Valid Until Date" = 31.01.2018
        ExpectedQuoteValidUntilDate := CalcDate('<30D>', SalesHeader."Document Date");
        SalesHeader.TestField("Quote Valid Until Date", ExpectedQuoteValidUntilDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteValidUntilDateOnInsertSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Quote Valid To Date]
        // [SCENARIO 280680] "Quote Valid Until Date" calculated when new quote is being created
        Initialize();

        // [GIVEN] Set SalesSetup."Quote Validity Calculation" = 30D
        SetSalesSetupQuoteValidUntilDate('<30D>');

        // [WHEN] New Quote is being inserted
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);

        // [THEN] "Quote Valid Until Date" = 31.01.2018
        SalesHeader.TestField("Quote Valid Until Date", CalcDate('<30D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('DeleteOverdueSalesQuotesRequestPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOverdueQuotesConfirmYes()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Quote Valid To Date]
        // [SCENARIO 280680] Report "Delete Overdue Sales Quotes" deletes overdue after confirmation
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Create overdue quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        SalesHeader."Quote Valid Until Date" := WorkDate() - 1;
        SalesHeader.Modify();
        Commit();

        // [WHEN] Report "Delete Overdue Sales Quotes" is being run with confirmation to delete quotes
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::"Delete Expired Sales Quotes");

        // [THEN] Quote deleted
        Assert.IsFalse(SalesHeader.Find(), 'Quote should be deleted');

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('DeleteOverdueSalesQuotesRequestPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DeleteOverdueQuotesConfirmNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Quote Valid To Date]
        // [SCENARIO 280680] Report "Delete Overdue Sales Quotes" does not delete overdue after decline confirmation
        Initialize();

        // [GIVEN] Create overdue quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        SalesHeader."Quote Valid Until Date" := WorkDate() - 1;
        SalesHeader.Modify();
        Commit();

        // [WHEN] Report "Delete Overdue Sales Quotes" is being run and cancel confirmation to delete quotes
        LibraryVariableStorage.Enqueue(WorkDate());
        asserterror REPORT.Run(REPORT::"Delete Expired Sales Quotes");

        // [THEN] Quote is not deleted
        Assert.IsTrue(SalesHeader.Find(), 'Quote should not be deleted');
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('DeleteOverdueSalesQuotesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOverdueQuotesEmptyQuoteValidUntilDate()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Quote Valid To Date]
        // [SCENARIO 282997] Report "Delete Overdue Sales Quotes" does not delete quotes with empty "Quote Valid Until Date"
        Initialize();

        // [GIVEN] No Sales Quote exist
        DeleteSalesQuotes();

        // [GIVEN] Create quote with empty "Quote Valid Until Date"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [WHEN] Report "Delete Overdue Sales Quotes" is being run
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::"Delete Expired Sales Quotes");

        // [THEN] Quote is not deleted
        Assert.IsTrue(SalesHeader.Find(), 'Quote should not be deleted');
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyCustomerTemplate()
    var
        CustomerTemplate: Record "Customer Templ.";
        CustomerTemplateCard: TestPage "Customer Templ. Card";
    begin
        // [SCENARIO 210447] Copy customer template
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Customer template 'CT1'
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code);
        // [GIVEN] New customer template 'CT2'
        CustomerTemplateCard.OpenNew();
        CustomerTemplateCard.Code.SetValue('CT2');
        // [WHEN] Copy from customer template 'CT1' to 'CT2'
        CustomerTemplateCard.CopyTemplate.Invoke();

        // [THEN] Customer template 'CT1' fields copied to 'CT2'
        Assert.AreEqual(
          CustomerTemplate."Country/Region Code",
          CustomerTemplateCard."Country/Region Code".Value, CopyCustTemplateErr);
        Assert.AreEqual(
          CustomerTemplate."Gen. Bus. Posting Group",
          CustomerTemplateCard."Gen. Bus. Posting Group".Value, CopyCustTemplateErr);
        Assert.AreEqual(
          CustomerTemplate."Customer Posting Group",
          CustomerTemplateCard."Customer Posting Group".Value, CopyCustTemplateErr);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SalesCreditLimitNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_CreditLimitNotificationShownDeltaAmountUnderLimit()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuote: TestPage "Sales Quote";
        CreditLimit: Integer;
    begin
        // [FEATURE] [UI] [Credit Limit] [Notification]
        // [SCENARIO 290301] "Credit Limit" notification is shown when Amount change is less than Credit Limit on Sales Quote
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] "Credit Warnings"  set to "Credit Limit" in "Sales & Receivables Setup"
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] VAT Posting Setup "VB","VP" with "VAT %" = 0
        CreateSimpleVATPostingSetup(VATPostingSetup);

        // [GIVEN] Customer "X" with "Credit Limit (LCY)" = 1000 and "VAT Bus. Posting Group" = "VB"
        LibrarySales.CreateCustomer(Customer);
        CreditLimit := LibraryRandom.RandIntInRange(10, 1000);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // [GIVEN] Item "IT" with "VAT Prod. Posting Group" = "VP"
        // [GIVEN] Sales Quote "SQ" with Customer "X" and Amount = 500 for Item "IT"
        CreateSalesQuoteWithUnitPrice(
          SalesHeader,
          SalesLine,
          Customer."No.",
          LibraryRandom.RandDecInDecimalRange(1, CreditLimit / 2, 2),
          VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(CreditLimit + 1);
        SalesHeader.SetRecFilter();

        // [GIVEN] Sales Quote page with "SQ" is opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] Change Amount on Sales Line to 1001
        SalesQuote.SalesLines."Unit Price".SetValue(CreditLimit + 1);

        // [THEN] Notification "Credit Limit" is shown
        // Verification done in CreditLimitNotificationHandler
        NotificationLifecycleMgt.RecallAllNotifications();
        SalesQuote.Close();
        LibraryVariableStorage.AssertEmpty();

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CompanyContactWithoutCustomer()
    var
        SalesQuote: TestPage "Sales Quote";
        ContactNo: Code[20];
    begin
        // [FEATURE]
        // [SCENARIO 307204] Setting Company Contact without Customer on new Sales Quote page leads to fields "Sell-to Contact" and "Bill-to Contact" being equal to ''.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Company Contact "X" without Customer
        ContactNo := LibraryMarketing.CreateCompanyContactNo();
        LibraryVariableStorage.Enqueue(ContactNo);

        // [WHEN] "Sell-to Contact" is set to Contact "X" on new Sales Quote page.
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Contact".Lookup();

        // [THEN] Fields "Sell-to Contact" and "Bill-to Contact" are equal to ''.
        SalesQuote."Sell-to Contact".AssertEquals('');
        SalesQuote."Bill-to Contact".AssertEquals('');
        SalesQuote."Sell-to Contact No.".AssertEquals(ContactNo);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ConvertToSalesOrderConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteToSalesOrderUnlockedPage()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderQuote: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Order]
        // [SCENARIO 305396] Stan can switch to other documents from sales order created from quote.
        Initialize();

        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Sales Order "XX"
        LibrarySales.CreateSalesOrder(SalesHeaderOrder);
        // [GIVEN] Sales Quote "YY"
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeaderQuote, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Run "Sales-Quote to Order (Yes/No)" on "YY", create Sales Order "ZZ"
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeaderQuote);

        // [THEN] Opened Sales Order No. = "XX" - because Setfilter orders records
        SalesOrder.FILTER.SetFilter("Sell-to Customer No.", SalesHeaderOrder."Sell-to Customer No.");
        SalesHeaderOrder.SetRange("Sell-to Customer No.", SalesHeaderOrder."Sell-to Customer No.");
        SalesOrder."No.".AssertEquals(SalesHeaderOrder."No.");

        // [THEN] Stan can switch from "XX"
        Assert.IsTrue(SalesOrder.Next(), '');
        Assert.AreEqual(1, SalesHeaderOrder.Next(), '');
        SalesOrder."No.".AssertEquals(SalesHeaderOrder."No.");

        // Cleanup
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerTemplateListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromQuoteContactWithMultipleCustomerTemplates()
    var
        Contact: Record Contact;
        CustomerTemplate: array[2] of Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        ErrorMessage: Record "Error Message";
        ErrorMessages: TestPage "Error Messages";
        I: Integer;
        DocumentNo: array[2] of Code[20];
    begin
        // [SCENARIO 328279] Assigning Sales Quotes for Contact to Customer created from a different Customer Template raises a warning
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Company Contact "COMP"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Sales quote "SQ1" created from contact COMP with Customer Template "CT01"
        // [GIVEN] Sales quote "SQ2" created from contact COMP with Customer Template "CT02"
        for I := 1 to 2 do begin
            SalesHeader."No." := '';
            CreateCustomerTemplateWithPostingSetup(CustomerTemplate[I]);
            LibraryVariableStorage.Enqueue(CustomerTemplate[I].Code); // for CustomerTemplateListModalPageHandler
            CreateQuoteFromContact(SalesHeader, Contact."No.");
            DocumentNo[I] := SalesHeader."No.";
        end;

        // [WHEN] Customer created from quote "SQ2"
        ErrorMessages.Trap();
        SalesHeader.CheckCustomerCreated(false);
        SalesHeader.Find();

        // [THEN] Confirmation message is shown: "Quotes with Customer Templates different from CT02 were assigned to customer C00010. Do you want to review..."
        // [THEN] Error Messages page is shown with warning message "Sales quote SQ1 with original customer template CT01 was assigned to the customer created from template CT02."
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCustomerTemplateMsg, DocumentNo[1], CustomerTemplate[1].Code, CustomerTemplate[2].Code),
          ErrorMessages.Description.Value);
        ErrorMessages."Message Type".AssertEquals(ErrorMessage."Message Type"::Warning);
        Assert.IsFalse(ErrorMessages.Next(), 'Unexpected error message');
        LibraryVariableStorage.AssertEmpty();

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerConditional,CustomerTemplateListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerForContactQuoteWithoutCustomerTemplate()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        ErrorMessage: Record "Error Message";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 331392] Assigning Sales Quote without Customer Template for Contact to Customer created from a Customer Template raises a warning
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Company Contact "COMP"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Sales quote "SQ1" created from contact COMP without Customer Template
        LibraryVariableStorage.Enqueue(false);
        CreateQuoteFromContact(SalesHeader, Contact."No.");
        DocumentNo := SalesHeader."No.";

        // [GIVEN] Sales quote "SQ2" created from contact COMP with Customer Template "CT01"
        SalesHeader."No." := '';
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code); // for CustomerTemplateListModalPageHandler
        CreateQuoteFromContact(SalesHeader, Contact."No.");

        // [WHEN] Customer created from quote "SQ2"
        ErrorMessages.Trap();
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.CheckCustomerCreated(false);
        SalesHeader.Find();

        // [THEN] Confirmation message is shown: "Quotes with Customer Templates different from CT01 were assigned to customer C00010. Do you want to review..."
        // [THEN] Error Messages page is shown with warning message "Sales quote SQ1 without an original customer template was assigned to the customer created from template CT01."
        Assert.ExpectedMessage(
          StrSubstNo(NoOriginalCustomerTemplateMsg, DocumentNo, CustomerTemplate.Code),
          ErrorMessages.Description.Value);
        ErrorMessages."Message Type".AssertEquals(ErrorMessage."Message Type"::Warning);
        Assert.IsFalse(ErrorMessages.Next(), 'Unexpected error message');
        LibraryVariableStorage.AssertEmpty();

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure GetRecurringSalesLinesIsNotEnabledWithoutSalesToCustomerNoInSalesQuote()
    var
        Contact: Record Contact;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO 361782] When you create a new sales quote with validated "Sell-to Contact No."
        // [SCENARIO 361782] and not validated "Sell-to Customer No.", the action "Get Recurring Sales Lines" is not enabled.
        Initialize();

        // [GIVEN] Sales Quote is created for new Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Created new Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Validate "Sell-to Contact No.". The "Sell-to Customer No." do not validated.
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");

        // [THEN] The action "Get Recurring Sales Lines" is not enabled.
        Assert.IsFalse(SalesQuote.GetRecurringSalesLines.Enabled(), '');
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRecurringSalesLinesIsUnabledWithValidationSalesToCustomerNoFromValidationSalesToContactNoInSalesQuote()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO 361782] When you create a new sales quote with validated "Sell-to Contact No."
        // [SCENARIO 361782] and validated "Sell-to Customer No.", the action "Get Recurring Sales Lines" is enabled.
        Initialize();

        // [GIVEN] Sales Quote is created for new Contact with Customer
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Created new Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Validate "Sell-to Contact No.". The "Sell-to Customer No." is validated too.
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");

        // [THEN] The action "Get Recurring Sales Lines" is enabled.
        Assert.IsTrue(SalesQuote.GetRecurringSalesLines.Enabled(), '');
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('SalesQuoteToOrderTrue')]
    [Scope('OnPrem')]
    procedure WorkDescriptionCorrectlyCopiedToTheSalesOrderFromSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrder: TestPage "Sales Order";
        OldDefaultPostingDate: Enum "Default Posting Date";
        WorkDescription: Text;
        OldStockoutWarning: Boolean;
    begin
        // [SCENARIO 370775] The Work Description copied correctly when the user convert Sales Quote to an Order.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Create Sales Quote with Work Description
        OldStockoutWarning :=
          UpdateSalesReceivablesSetup(OldDefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));
        WorkDescription := LibraryRandom.RandText(50);
        SalesHeader.SetWorkDescription(WorkDescription);

        // [WHEN] Create Sales Order form Sales Quote.
        SalesOrder.Trap();
        LibraryVariableStorage.Enqueue(QuoteToOrderMessage);
        LibraryVariableStorage.Enqueue(OpenNewOrderQst);
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);

        // [THEN] Work Description copied successfully
        SalesOrder.WorkDescription.AssertEquals(WorkDescription);
        SalesOrder.Close();
        UpdateSalesReceivablesSetup(OldDefaultPostingDate, OldDefaultPostingDate, OldStockoutWarning);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuoteDeleteComments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 416939] Sales quote comments deleted on Sales Order from Sales Quote action
        Initialize();

        // [GIVEN] Created Sales Quote
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));  // Take Randon value for Number of lines.
        // [GIVEN] Created comment for quote
        CreateSalesQuoteComments(SalesHeader, SalesLine."Line No.");
        SalesCommentLine.SetRange("Document Type", "Sales Comment Document Type"::Quote);
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesCommentLine);

        // [WHEN] Create Sales Order from Sales Quote.
        Codeunit.Run(Codeunit::"Sales-Quote to Order", SalesHeader);

        // [THEN] Sales quote comments deleted
        Assert.RecordIsEmpty(SalesCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromSalesQuoteDeleteComments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        xSalesCommentLine: Record "Sales Comment Line" temporary;
        QuoteNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 426021] Sales quote comments deleted on Sales Invoice from Sales Quote action
        Initialize();

        // [GIVEN] Created Sales Quote
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), LibraryRandom.RandInt(5));  // Take Randon value for Number of lines.
        QuoteNo := SalesHeader."No.";
        // [GIVEN] Created comment for quote
        CreateSalesQuoteComments(SalesHeader, SalesLine."Line No.");
        SalesCommentLine.SetRange("Document Type", "Sales Comment Document Type"::Quote);
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesCommentLine);
        if SalesCommentLine.FindSet() then
            repeat
                xSalesCommentLine := SalesCommentLine;
                xSalesCommentLine.Insert();
            until SalesCommentLine.Next() = 0;

        // [WHEN] Create Sales Invoice from Sales Quote.
        Codeunit.Run(Codeunit::"Sales-Quote to Invoice", SalesHeader);

        // [THEN] Sales quote comments deleted
        Assert.RecordIsEmpty(SalesCommentLine);
        // [THEN] Quote comments are copied to Invoice comments
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
        SalesCommentLine.SetRange("Document Type", "Sales Comment Document Type"::Invoice);
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        if SalesCommentLine.FindSet() then
            repeat
                xSalesCommentLine.SetRange(Comment, SalesCommentLine.Comment);
                Assert.IsTrue(xSalesCommentLine.FindFirst(), 'not found comment on invoice');
            until SalesCommentLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuotePageIsCommentLineIsBlankLineResetOnChangeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ERMSalesQuotes: Codeunit "ERM Sales Quotes";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 432859] Drill-down on field value should not be shown on Sales Quote line with Item when returned from comment line
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Sales Quote with 2 lines: Item - Qty = 1, Qty. to Assemble to Order = 1; Empty Line with Description
        CreateSalesQuote(SalesHeader, SalesLine, CreateCustomer(), 1);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Qty. to Assemble to Order", 1);
        SalesLine.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine.Validate(Description, 'Description');
        SalesLine.Modify();

        // [GIVEN] Sales Quote page opened
        SalesQuote.OpenEdit();
        SalesQuote.GoToRecord(SalesHeader);

        // [GIVEN] User navigates to second 'Comment' line and invoke DrillDown on Qty. to Assemble to Order
        LibraryVariableStorage.Enqueue(true);
        ERMSalesQuotes.SetVariableStorage(LibraryVariableStorage);
        BindSubscription(ERMSalesQuotes);
        SalesQuote.SalesLines.Last();

        // [WHEN] User returns on first line with Item
        LibraryVariableStorage.Enqueue(false);
        ERMSalesQuotes.SetVariableStorage(LibraryVariableStorage);
        SalesQuote.SalesLines.Previous();
        // [THEN] The field Qty. to Assemble to Order is editable (Drill-down not invoke), Checked in CheckIsCommentLineIsBlankNumber.

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSPrePaymentErrorOnNegValueQtySalsQuote()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 446418] Sales Quote control missing regarding Prepayments and negative quantities.

        Initialize();

        // [GIVEN] Create Item and Customer
        Item.Get(CreateItem());
        LibrarySales.CreateCustomer(Customer);

        // [THEN] Update Prepayment % on customer.
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(100, 2));
        Customer.Modify();

        // [GIVEN] Create Sales Quote.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        UpdateVatProdPostingGroup(Item, SalesHeader."Gen. Bus. Posting Group", SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [VERIFY] On Validate of Negative quantity prepayment error expected.
        asserterror SalesLine.Validate(Quantity, -1 * SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReleaseSalesQuoteWithPrepayment()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 455940] Sales Quote with Prepayment % can be release

        Initialize();

        // [GIVEN] Create Item and Customer
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 0));
        Item.Modify(true);
        LibrarySales.CreateCustomer(Customer);

        // [THEN] Update Prepayment % on customer.
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(100, 2));
        Customer.Modify();

        // [GIVEN] Create Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        UpdateVatProdPostingGroup(Item, SalesHeader."Gen. Bus. Posting Group", SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [VERIFY] Sales Quote released succesfully
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Quotes");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Quotes");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Quotes");
    end;

    local procedure CreateSimpleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; NoOfLines: Integer)
    var
        ResponsibilityCenter: Record "Responsibility Center";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        ResponsibilityCenter.FindFirst();
        SalesHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        SalesHeader.Modify(true);

        // Using Random for Quantity, value not important for Quantity.
        for Counter := 1 to NoOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesQuoteComments(SalesHeader: Record "Sales Header"; DocLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine."Document Type" := "Sales Comment Document Type"::Quote;
        SalesCommentLine."No." := SalesHeader."No.";
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine.Comment := LibraryUtility.GenerateGUID();
        SalesCommentLine.Insert();

        SalesCommentLine."Line No." := 20000;
        SalesCommentLine."Document Line No." := DocLineNo;
        SalesCommentLine.Comment := LibraryUtility.GenerateGUID();
        SalesCommentLine.Insert();
    end;

    local procedure CreateSalesQuoteWithUnitPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; UnitPrice: Decimal; VATProdPostingGroupCode: Code[20])
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        CreateItemWithUnitPrice(Item, UnitPrice);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          Item."No.",
          1);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvDiscount(CustomerNo: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustomerNo);
    end;

    local procedure CreateCustomerTemplateWithPostingSetup(var CustomerTemplate: Record "Customer Templ.")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CustomerTemplate.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        CustomerTemplate.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        CreateItemWithUnitPrice(Item, LibraryRandom.RandDec(100, 0));
        exit(Item."No.");
    end;

    local procedure CreateItemWithUnitPrice(var Item: Record Item; UnitPrice: Decimal)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreateExtendedTextForItem(Item: Record Item; var ExtendedTextLine: Record "Extended Text Line")
    var
        ExtendedTextHeader: Record "Extended Text Header";
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        LibraryUtility.FillFieldMaxText(ExtendedTextLine, ExtendedTextLine.FieldNo(Text));
        ExtendedTextLine.Find();
    end;

    local procedure CreateQuoteFromContact(var SalesHeader: Record "Sales Header"; ContactNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader.Validate("Sell-to Contact No.", ContactNo);
        SalesHeader.Modify();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; QuoteNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindSalesLineCount(DocumentNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        exit(SalesLine.Count);
    end;

    local procedure FindSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRange("Quote No.", SalesHeader."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst();
    end;

    local procedure VerifyPostingDateOnOrder(var SalesHeader: Record "Sales Header"; QuoteNo: Code[20])
    begin
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst();
        SalesHeader.TestField("Posting Date", 0D);
    end;

    local procedure UpdateVatProdPostingGroup(Item: Record Item; GenBusPostingGroup: Code[20]; VATBusPostingGrp: Code[20]; VATProdPostingGroup: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATpostingSetup(VATPostingSetup, VATBusPostingGrp, VATProdPostingGroup);
        if GenPostingSetup.Get(GenBusPostingGroup, Item."Gen. Prod. Posting Group") then
            if GenPostingSetup."Sales Prepayments Account" <> '' then begin
                GLAcc.Get(GenPostingSetup."Sales Prepayments Account");
                GLAcc."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
                GLAcc.Modify();
            end;
    end;

    local procedure FindVATpostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGrp: Code[20]; VATProdPostingGrouptxt: Code[20])
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", VATBusPostingGrp);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATProdPostingGrouptxt);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if not VATPostingSetup.FindFirst() then begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGrp, VATProdPostingGroup.Code);
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATPostingSetup.Validate("VAT %", 0);
            VATPostingSetup.Validate("VAT Identifier",
              LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
            VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Validate("Tax Category", 'S');
            VATPostingSetup.Insert(true);

        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler.
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderTrue(Question: Text[1024]; var Reply: Boolean)
    var
        Message: Text;
    begin
        Message := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(StrPos(Question, Message) <> 0, UnknownError);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler.
        Assert.AreEqual(Question, StrSubstNo(QuoteToOrderMessage), UnknownError);
        Reply := false;
    end;

    local procedure UpdateSalesReceivablesSetup(var OldDefaultPostingDate: Enum "Default Posting Date"; DefaultPostingDate: Enum "Default Posting Date"; StockoutWarning: Boolean) OldStockoutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldDefaultPostingDate := SalesReceivablesSetup."Default Posting Date";
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetSalesSetupQuoteValidUntilDate(QuoteValidityCalculation: Text)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        Evaluate(SalesSetup."Quote Validity Calculation", QuoteValidityCalculation);
        SalesSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerConditional(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListModalPageHandler(var CustomerTemplateList: TestPage "Select Customer Templ. List")
    begin
        CustomerTemplateList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        CustomerTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListModalPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SalesCreditLimitOnSalesOrderNotificationHandler(var Notification: Notification): Boolean
    var
        SalesHeader: Record "Sales Header";
        AmountInNotification: Decimal;
    begin
        // Quote already removed when notification handled is shown so that notification belongs to Order
        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type"::Quote, LibraryVariableStorage.DequeueText()), 'Sales Quote is not deleted');

        Evaluate(AmountInNotification, Notification.GetData('OrderAmountThisOrderLCY'));
        Assert.AreEqual(AmountInNotification, LibraryVariableStorage.DequeueDecimal(), 'Amount in Credit Limit notification is not correct');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SalesCreditLimitNotificationHandler(var Notification: Notification): Boolean
    var
        AmountInNotification: Decimal;
    begin
        Evaluate(AmountInNotification, Notification.GetData('OrderAmountThisOrderLCY'));
        Assert.AreEqual(AmountInNotification, LibraryVariableStorage.DequeueDecimal(), 'Amount in Credit Limit notification is not correct');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // Quote already removed when notification handled is shown so that notification belongs to Order
        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type"::Quote, LibraryVariableStorage.DequeueText()), 'Sales Quote is not deleted');

        Evaluate(ItemNo, Notification.GetData('ItemNo'));
        Assert.AreEqual(ItemNo, LibraryVariableStorage.DequeueText(), 'Item in Item Availability notification is not correct');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
    end;

    local procedure DeleteSalesQuotes()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.DeleteAll();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteOverdueSalesQuotesRequestPageHandler(var DeleteOverdueSalesQuotes: TestRequestPage "Delete Expired Sales Quotes")
    begin
        DeleteOverdueSalesQuotes.ValidToDate.Value(Format(LibraryVariableStorage.DequeueDate()));
        DeleteOverdueSalesQuotes.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConvertToSalesOrderConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Quote Subform", 'OnAfterUpdateEditableOnRow', '', false, false)]
    local procedure CheckIsCommentLineIsBlankNumber(SalesLine: Record "Sales Line"; var IsCommentLine: Boolean; var IsBlankNumber: Boolean)
    var
        BooleanValue: Boolean;
    begin
        if LibraryVariableStorage.Length() = 0 then
            exit;
        BooleanValue := LibraryVariableStorage.DequeueBoolean();
        Assert.AreEqual(BooleanValue, IsCommentLine, '');
        Assert.AreEqual(BooleanValue, IsBlankNumber, '');
    end;

    [Scope('OnPrem')]
    procedure SetVariableStorage(var NewLibraryVariableStorage: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorage := NewLibraryVariableStorage;
    end;
}

