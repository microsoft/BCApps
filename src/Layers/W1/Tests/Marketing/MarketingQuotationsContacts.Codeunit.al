codeunit 136204 "Marketing Quotations Contacts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Quote] [Sales] [Marketing]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        SalesQuoteMustNotExistError: Label '%1 with %2=%3, %4=%5 must not exist.';
        SalesQuoteAlreadyAssignedError: Label 'A sales quote has already been assigned to this opportunity.';
        UnknownError: Label 'Unknown error.';
        CustomerTemplateCode2: Code[20];
        SalesQuoteMustBeInProgressErr: Label '%1 must be equal to ''%2''  in Opportunity: No.=%3. Current value is ''%4''.', Comment = '%1=Opportunity Status;%2=Status Value;%3=Opportunity No.;%4=Status Value.';
        SellToContactMissMatchErr: Label 'Sell-To Contact No. on created Quote must be %1.', Comment = '%1- Contact No.';
        SalesDocumentTypeMissMatchErr: Label 'Sales Document Type must be Quote on Opportunity %1.', Comment = '%1- Opportunity No';

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler')]
    [Scope('OnPrem')]
    procedure CreatingSalesQuoteOpportunity()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        CustomerTemplate: Record "Customer Templ.";
    begin
        // Covers document number TC0011 - refer to TFS ID 21733.
        // [SCENARIO 21733] Test creation of a Sales Quote from the Opportunity for a Contact that is not registered as a Customer.

        // [GIVEN] Create a new Customer Template, Contact, Sales Cycle, Opportunity.
        Initialize();
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);

        // [WHEN] Assign the Sales Quote to the Opportunity created earlier.
        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");

        // [THEN] Check that the value of the Sell-to Contact No. is the same as the value of the Contact that was created earlier. Verify that the Sales Quote has been updated on Opportunity.
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Quote);

        SalesHeader.TestField("Sell-to Contact No.", Contact."No.");
        SalesHeader.TestField("VAT Bus. Posting Group", CustomerTemplate."VAT Bus. Posting Group");
        SalesHeader.TestField("Opportunity No.", Opportunity."No.");

        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Quote);
        Opportunity.TestField("Sales Document No.", SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler')]
    [Scope('OnPrem')]
    procedure CreatingSalesQuoteOpportunityForPerson()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        ContactPerson: Record Contact;
        Opportunity: Record Opportunity;
    begin
        // [SCENARIO 172048] Sales Quote should be assigned to the Opportunity for a Contact of type Person
        Initialize();

        // [GIVEN] The Customer with Contact 'C' of type Company.
        CreateContactWithCustomerRelation(Contact);
        // [GIVEN] The Contact 'P' of type Person.
        LibraryMarketing.CreateCompanyContact(ContactPerson);
        ContactPerson."Company No." := Contact."No.";
        ContactPerson.Type := ContactPerson.Type::Person;
        ContactPerson.Modify();

        // [WHEN] Assign the Sales Quote to the Opportunity
        CreateAndAssignQuoteToOpportunity(Opportunity, ContactPerson."No.");

        // [THEN] The Sales Quote is created, where "Sell-to Contact No." is 'P'.
        FindSalesDocument(SalesHeader, '', ContactPerson."No.", SalesHeader."Document Type"::Quote);
        SalesHeader.TestField("Sell-to Contact No.", ContactPerson."No.");
        SalesHeader.TestField("Opportunity No.", Opportunity."No.");
        // [THEN] The Sales Quote is linked with the Opportunity.
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Quote);
        Opportunity.TestField("Sales Document No.", SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ConvertSalesQuoteToOrder()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        CustomerNo: Code[20];
    begin
        // Covers document number TC0012 - refer to TFS ID 21733.
        // [SCENARIO 21733] Test creation of a Sales Quote for a Contact registered as a Customer directly from the Sales Quote window and conversion to Sales Order.

        // [GIVEN] Create a new Customer Template, Contact, Sales Quote - Sales Header and Sales Line.
        Initialize();
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);
        CreateSalesQuoteWOCustomer(SalesHeader, Contact."No.", CustomerTemplate.Code);

        // [WHEN] Convert the Sales Quote to Order by Make Order.
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();

        // [THEN] Check that the Sales Quote has been deleted.
        CustomerNo := VerifySalesOrderFromQuote(SalesHeader);
        VerifyCustomerCreatedFromQuote(CustomerNo, CustomerTemplate);
        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."),
          StrSubstNo(
            SalesQuoteMustNotExistError, SalesHeader.TableCaption(), SalesHeader.FieldCaption("Document Type"), SalesHeader."Document Type",
            SalesHeader.FieldCaption("No."), SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler')]
    [Scope('OnPrem')]
    procedure AssignQuoteToOpportunityError()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        CustomerTemplate: Record "Customer Templ.";
    begin
        // Covers document number TC0013 - refer to TFS ID 21733.
        // [SCENARIO 21733] Test that the application generates an error on assigning a Sales Quote to an Opportunity that has already been assigned a Sales Quote.

        // [GIVEN] Create a new Customer Template, Contact, Sales Cycle, Opportunity. Create and assign a Sales Quote to Opportunity.
        Initialize();
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);

        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");

        // [WHEN] Try assigning another Sales Quote to the Opportunity created earlier.
        asserterror Opportunity.CreateQuote();

        // [THEN] Check that the application generates an error on assigning a Sales Quote to an Opportunity that has already been assigned a Sales Quote.
        Assert.AreEqual(StrSubstNo(SalesQuoteAlreadyAssignedError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler')]
    [Scope('OnPrem')]
    procedure ChangeSalesQuoteOnOpportunity()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        CustomerTemplate: Record "Customer Templ.";
    begin
        // Covers document number TC0013 - refer to TFS ID 21733.
        // [SCENARIO 21733] Test that the application allows changing Sales Quote assigned to an Opportunity that has already been assigned a Sales Quote.

        // [GIVEN] Create a new Customer Template, Contact, Sales Cycle, Opportunity. Create and assign a Sales Quote to Opportunity.
        // [GIVEN] Create a new Sales Quote - Sales Header and Sales Line.
        Initialize();
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);

        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Quote);
        CreateSalesQuoteWOCustomer(SalesHeader2, SalesHeader."Sell-to Contact No.", SalesHeader."Sell-to Customer Templ. Code");

        // [WHEN] Try changing the Sales Quote on the Opportunity created earlier.
        Opportunity.Validate("Sales Document No.", SalesHeader2."No.");
        Opportunity.Modify(true);

        // [THEN] Check that the application allows changing Sales Quote assigned to an Opportunity that has already been assigned a Sales Quote.
        SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader2.TestField("Opportunity No.", Opportunity."No.");
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Opportunity No.", '');
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler')]
    [Scope('OnPrem')]
    procedure AssignOpportunityOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        CustomerTemplate: Record "Customer Templ.";
        TempOpportunity: Record Opportunity temporary;
    begin
        // [SCENARIO] Test that the application allows Assigning a Sales Quote to an Opportunity from the Sales Quote window.

        // [GIVEN] Create a new Customer Template, Contact, Sales Quote - Sales Header and Sales Line, Sales Cycle, Opportunity.
        Initialize();
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);
        CreateSalesQuoteWOCustomer(SalesHeader, Contact."No.", CustomerTemplate.Code);

        Opportunity.SetRange("Contact No.", Contact."No.");
        TempOpportunity.CreateOppFromOpp(Opportunity);
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();

        // [WHEN] Update Opportunity No. On Sales Quote.
        SalesHeader.Validate("Opportunity No.", Opportunity."No.");
        SalesHeader.Modify(true);

        // [THEN] Verify Sales Document No. , Sales Document Type On Opportunity.
        Opportunity.Get(SalesHeader."Opportunity No.");
        Opportunity.TestField("Sales Document No.", SalesHeader."No.");
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteWithOpportunityNo()
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO] Verify Sales Document Type and No. on Opportunity card after restoring from Sales Quote Archive with Opportunity No.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Archive Sales Header.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verifing Sales Document Type and No. on Opportunity card.
        VerifyDocumentTypeAndNoOnOpportunity(SalesHeader."Sell-to Contact No.",
          SalesHeader."No.", Opportunity."Sales Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteWithoutOpportunityNo()
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO] Verify Sales Document Type and No. on Opportunity card after restoring from Sales Quote Archive without Opportunity No.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Update Opportunity No. as blank before Archive Sales Header.
        UpdateOpportunityNoAsBlank(SalesHeader);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verifing Sales Document Type and No. on Opportunity card.
        VerifyDocumentTypeAndNoOnOpportunity(SalesHeader."Sell-to Contact No.", '', Opportunity."Sales Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,CloseOpportModalPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesOrderWithOpportunityNo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader1: Record "Sales Header";
        Opportunity: Record Opportunity;
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesOrder: TestPage "Sales Order";
        CustomerTemplateCode: Code[10];
    begin
        // [SCENARIO] Verify Sales Document Type and No. on Opportunity card after restoring from Sales order Archive with Opportunity No.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CustomerTemplateCode := CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Convert Quote to Order.
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();

        // [GIVEN] Find Sales order and Archive Sales Header.
        FindSalesDocument(SalesHeader1, CustomerTemplateCode, SalesHeader."Sell-to Contact No.", SalesHeader1."Document Type"::Order);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader1);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader1."No.", SalesHeader1."Document Type"::Order);

        // [THEN] Verifing Sales Document Type and No. on Opportunity card.
        VerifyDocumentTypeAndNoOnOpportunity(SalesHeader1."Sell-to Contact No.",
          SalesHeader1."No.", Opportunity."Sales Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,CloseOpportModalPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesOrderWithoutOpportunityNo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader1: Record "Sales Header";
        Opportunity: Record Opportunity;
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesOrder: TestPage "Sales Order";
        CustomerTemplateCode: Code[10];
    begin
        // [SCENARIO] Verify Sales Document Type and No. on Opportunity card after restoring from Sales order Archive without Opportunity No.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign quote.
        Initialize();
        CustomerTemplateCode := CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Convert Quote to Order.
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();

        // [GIVEN] Find Sales Order and Update Opportunity No. as blank before Archive Sales Header.
        FindSalesDocument(SalesHeader1, CustomerTemplateCode, SalesHeader."Sell-to Contact No.", SalesHeader1."Document Type"::Order);
        UpdateOpportunityNoAsBlank(SalesHeader1);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader1);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader1."No.", SalesHeader1."Document Type"::Order);

        // [THEN] Verifing Sales Document Type and No. on Opportunity card.
        VerifyDocumentTypeAndNoOnOpportunity(SalesHeader1."Sell-to Contact No.", '', Opportunity."Sales Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteWhenOppLinkedToAnotherQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Opportunity: Record Opportunity;
        OpportunityNo: Code[20];
    begin
        // [SCENARIO] Verify the Oppotunity Link after assigning the same opportunity to second sales quote and then restoring the first quote.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Archive Sales Header and create another sales quote by linking the same opportunity no.
        OpportunityNo := ArchiveSalesDocument(SalesHeader);
        CreateSalesQuoteWOCustomerWithOpportunity(SalesHeader2, SalesHeader);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verifing Sales Document Type and No. on Opportunity and also checking the opportunity link on the Sales Quotes.
        VerifyDocumentTypeAndNoOnOpportunity(
          SalesHeader."Sell-to Contact No.", SalesHeader."No.", Opportunity."Sales Document Type"::Quote);
        VerifyOpportunityLinkingOnSalesQuotes(SalesHeader."No.", SalesHeader2."No.", OpportunityNo);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteAfterRemovingOppFromQuote()
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO] Verify Sales Document Type and No. on Opportunity card by removing the opportunity link before restoring the Sales Quote.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Update Opportunity No. as blank after Archive Sales Header.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        UpdateOpportunityNoAsBlank(SalesHeader);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verifing Sales Document Type and No. on Opportunity card.
        VerifyDocumentTypeAndNoOnOpportunity(
          SalesHeader."Sell-to Contact No.", SalesHeader."No.", Opportunity."Sales Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteAfterRemovingOppLinkAndLinkToAnotherQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Opportunity: Record Opportunity;
        OpportunityNo: Code[20];
    begin
        // [SCENARIO] Verify the Oppotunity Link after removing the opportunity link and assigning the same opportunity to second sales quote and then restoring the first quote.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Update Opportunity No. as blank after Archive Sales Header.
        OpportunityNo := ArchiveSalesDocument(SalesHeader);
        UpdateOpportunityNoAsBlank(SalesHeader);
        CreateSalesQuoteWOCustomerWithOpportunity(SalesHeader2, SalesHeader);

        // [WHEN] Restore Sales Header Archive.
        RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verifing Sales Document Type and No. on Opportunity and also checking the opportunity link on the Sales Quotes.
        VerifyDocumentTypeAndNoOnOpportunity(
          SalesHeader."Sell-to Contact No.", SalesHeader."No.", Opportunity."Sales Document Type"::Quote);
        VerifyOpportunityLinkingOnSalesQuotes(SalesHeader."No.", SalesHeader2."No.", OpportunityNo);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RestoreSalesQuoteWhereOppStatusEqualToWon()
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        OpportunityNo: Code[20];
    begin
        // [SCENARIO] Verify that error gets appeared at the time of restore when opportunity status change to won.

        // [GIVEN] Create a new Customer Template,Contact,Sales Cycle,Opportunity and Assign Quote.
        Initialize();
        CreateSetupForOpportunity(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Update Opportunity No. as blank after Archive Sales Header.Also change the status of the opportunity to won.
        OpportunityNo := ArchiveSalesDocument(SalesHeader);
        UpdateOpportunityNoAsBlank(SalesHeader);
        UpdateOpportunityStatus(OpportunityNo);
        Opportunity.Get(OpportunityNo);

        // [WHEN] Restore Sales Header Archive.
        asserterror RestoreSalesHeaderArchive(SalesHeader."No.", SalesHeader."Document Type");

        // [THEN] Verify that the expected error is coming at the time of restoring.
        Assert.ExpectedError(StrSubstNo(SalesQuoteMustBeInProgressErr, Opportunity.FieldCaption(Status),
            Opportunity.Status::"In Progress", Opportunity."No.", Opportunity.Status));
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,CloseOpportModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderRelatedToOpportunity()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Opportunity: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO 378651] User successfully deletes Sales Order related to won Opportunity

        // [GIVEN] New Customer Template, Contact, Sales Cycle
        Initialize();

        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);

        // [GIVEN] Sales Quote assigned to the Opportunity created earlier
        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");
        OpportunityEntry.SetRange("Opportunity No.", Opportunity."No.");
        OpportunityEntry.DeleteAll();
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Quote);

        // [GIVEN] Sales Order made from Sales Quote
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Order);

        // [WHEN] Deleting Sales Order
        SalesHeader.Delete(true);

        // [THEN] Sales Order deleted without errors
        // [THEN] Opportunity "Status" changed to "Lost"
        Opportunity.Find();
        Opportunity.TestField(Status, Opportunity.Status::Lost);

        // [THEN] Created while closing Opportunity Entry has 0 "Estimated Value"
        OpportunityEntry.SetRange("Action Taken", OpportunityEntry."Action Taken"::Lost);
        OpportunityEntry.FindLast();
        OpportunityEntry.TestField("Estimated Value (LCY)", 0);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,CloseOpportModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure EstimatedValueInClosedOpportunityHavingEstimatedValue()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Opportunity: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        EstimatedValueAmount: Integer;
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO 378651] User successfully deletes Sales Order related to won Opportunity having Estimated Value and last Entry of Opportunity has the same "Estimated Value" as previous Entry

        // [GIVEN] New Customer Template, Contact, Sales Cycle
        Initialize();

        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);

        // [GIVEN] Opportunity with "Estimated Value (LCY)" = 100
        // [GIVEN] Sales Quote assigned to the Opportunity created earlier
        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");
        OpportunityEntry.SetRange("Opportunity No.", Opportunity."No.");
        OpportunityEntry.FindLast();
        EstimatedValueAmount := LibraryRandom.RandInt(100);
        OpportunityEntry."Estimated Value (LCY)" := EstimatedValueAmount;
        OpportunityEntry.Modify();
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Quote);

        // [GIVEN] Sales Order made from Sales Quote
        SalesOrder.Trap();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        SalesOrder.Close();
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Order);

        // [WHEN] Deleting Sales Order
        SalesHeader.Delete(true);

        // [THEN] Created while closing Opportunity Entry has "Estimated Value (LCY)" = 100
        OpportunityEntry.SetRange("Action Taken", OpportunityEntry."Action Taken"::Lost);
        OpportunityEntry.FindLast();
        OpportunityEntry.TestField("Estimated Value (LCY)", EstimatedValueAmount);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,SalesQuoteFormHandler,CustomerTemplateModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure AssignQuoteToContactWithNoRelatedCustomer()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        CustomerTemplate: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        ActionOption: Option LookupOK,Cancel;
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO 175273] User can assign a Quote to Contact from Opportunity with Customer Template if there is no Customer related to this Contact
        // [SCENARIO 253087] Update the dialogs and modal windows.
        Initialize();

        // [GIVEN] Contact without relation with Customer from Customer Template
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateCustomerTemplate(CustomerTemplate);
        LibraryVariableStorage.Enqueue(ActionOption::LookupOK);

        // [WHEN] Assign the Sales Quote to the Opportunity
        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");

        // [THEN] Customer created automatically and Sales Quote is assigned to him
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SalesQuoteNoCustomerPageHandler')]
    [Scope('OnPrem')]
    procedure CreatingSalesQuoteOpportunityForPersonAndNoCustomer()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        Opportunity: Record Opportunity;
    begin
        // [SCENARIO 491477] Sales Quote should be assigned to the Opportunity for a Contact of type Person where company no. is blank and customer is also not created for the contact.
        Initialize();

        // [GIVEN] The Customer with Contact 'C' of type Person.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] The Company No. on contact must be blank.
        Contact.Validate("Company No.", '');
        Contact.Modify();

        // [GIVEN] Create Opportunity for the Contact and initiate first stage.
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        Opportunity.StartActivateFirstStage();
        Opportunity.Get(Opportunity."No.");

        // [WHEN] Create Sales Quote for the Opportunity.
        Opportunity.CreateQuote();

        // [THEN] The Sales Document Type on Opportunity should be updated as Quote.
        Assert.AreEqual(Format(Opportunity."Sales Document Type"), Format(Enum::"Sales Document Type"::Quote), StrSubstNo(SalesDocumentTypeMissMatchErr, Opportunity."No."));

        // [THEN] The Sales Quote Dcoument should be created with the Sales Document No. of Oppurtunity.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("No.", Opportunity."Sales Document No.");
        Assert.RecordIsNotEmpty(SalesHeader);

        // [THEN] The created Sales Quote Document should have same Sell-To Contact No. as Oppurtunity.
        SalesHeader.FindFirst();
        Assert.AreEqual(SalesHeader."Sell-to Contact No.", Opportunity."Contact No.", StrSubstNo(SellToContactMissMatchErr, Opportunity."Contact No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Quotations Contacts");
        LibraryApplicationArea.EnableFoundationSetup();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Quotations Contacts");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryTemplates.EnableTemplatesFeature();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Quotations Contacts");
    end;

    local procedure AssignQuoteToOpportunity(var Opportunity: Record Opportunity; ContactNo: Code[20])
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.CreateQuote();
    end;

    local procedure ArchiveSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        exit(SalesHeader."Opportunity No.");
    end;

    local procedure CreateAndAssignQuoteToOpportunity(var Opportunity: Record Opportunity; ContactNo: Code[20])
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        TempOpportunity.CreateOppFromOpp(Opportunity);
        AssignQuoteToOpportunity(Opportunity, ContactNo);
    end;

    local procedure CreateCustomerTemplate(var CustomerTemplate: Record "Customer Templ.")
    var
        Customer2: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer2);
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", Customer2."Gen. Bus. Posting Group");
        CustomerTemplate.Validate("Customer Posting Group", Customer2."Customer Posting Group");
        CustomerTemplate.Validate("VAT Bus. Posting Group", Customer2."VAT Bus. Posting Group");
        CustomerTemplate.Validate("Payment Terms Code", Customer2."Payment Terms Code");
        CustomerTemplate.Modify(true);

        CustomerTemplateCode2 := CustomerTemplate.Code;  // Set global variable for Page Handler.
    end;

    local procedure CreateContactWithCustomerRelation(var Contact: Record Contact)
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, Contact."No.", BusinessRelation.Code);
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := LibrarySales.CreateCustomerNo();
        ContactBusinessRelation.Modify(true);
    end;

    local procedure CreateSalesQuoteWOCustomer(var SalesHeader: Record "Sales Header"; ContactNo: Code[20]; CustomerTemplateCode: Code[20])
    begin
        LibrarySales.SetStockoutWarning(false);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Contact No.", ContactNo);
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplateCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader);
    end;

    local procedure CreateSalesQuoteWOCustomerWithOpportunity(var SalesHeader2: Record "Sales Header"; SalesHeader: Record "Sales Header")
    begin
        CreateSalesQuoteWOCustomer(SalesHeader2, SalesHeader."Sell-to Contact No.", SalesHeader."Sell-to Customer Templ. Code");
        SalesHeader2.Validate("Opportunity No.", SalesHeader."Opportunity No.");
        SalesHeader2.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreateSetupForOpportunity(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[10]
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Opportunity: Record Opportunity;
    begin
        CreateCustomerTemplate(CustomerTemplate);
        CreateContactWithCustomerRelation(Contact);
        CreateAndAssignQuoteToOpportunity(Opportunity, Contact."No.");
        FindSalesDocument(SalesHeader, CustomerTemplate.Code, Contact."No.", DocumentType);
        exit(CustomerTemplate.Code);
    end;

    local procedure FindSalesDocument(var SalesHeader: Record "Sales Header"; CustomerTemplateCode: Code[20]; SellToContactNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        if CustomerTemplateCode <> '' then
            SalesHeader.SetRange("Sell-to Customer Templ. Code", CustomerTemplateCode);
        SalesHeader.SetRange("Sell-to Contact No.", SellToContactNo);
        SalesHeader.FindFirst();
    end;

    local procedure RestoreSalesHeaderArchive(No: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        SalesHeaderArchive.SetRange("Document Type", DocumentType);
        SalesHeaderArchive.SetRange("No.", No);
        SalesHeaderArchive.FindFirst();
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);
    end;

    local procedure UpdateOpportunityNoAsBlank(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Opportunity No.", '');
        SalesHeader.Modify(true);
    end;

    local procedure UpdateOpportunityStatus(OpportunityNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.Get(OpportunityNo);
        Opportunity.Validate(Status, Opportunity.Status::Won);
        Opportunity.Modify(true);
    end;

    local procedure VerifyCustomerCreatedFromQuote(CustomerNo: Code[20]; CustomerTemplate: Record "Customer Templ.")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.TestField("Gen. Bus. Posting Group", CustomerTemplate."Gen. Bus. Posting Group");
        Customer.TestField("Customer Posting Group", CustomerTemplate."Customer Posting Group");
        Customer.TestField("VAT Bus. Posting Group", CustomerTemplate."VAT Bus. Posting Group");
    end;

    local procedure VerifySalesOrderFromQuote(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesHeader2: Record "Sales Header";
    begin
        SalesHeader2.SetRange("Document Type", SalesHeader2."Document Type"::Order);
        SalesHeader2.SetRange("Quote No.", SalesHeader."No.");
        SalesHeader2.FindFirst();
        SalesHeader2.TestField("Sell-to Contact No.", SalesHeader."Sell-to Contact No.");
        SalesHeader2.TestField("Gen. Bus. Posting Group", SalesHeader."Gen. Bus. Posting Group");
        SalesHeader2.TestField("Customer Posting Group", SalesHeader."Customer Posting Group");
        SalesHeader2.TestField("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        exit(SalesHeader2."Sell-to Customer No.");
    end;

    local procedure VerifyDocumentTypeAndNoOnOpportunity(ContactNo: Code[20]; SalesDocumentNo: Code[20]; SalesDocumentType: Enum "Opportunity Document Type")
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.TestField("Sales Document Type", SalesDocumentType);
        Opportunity.TestField("Sales Document No.", SalesDocumentNo);
    end;

    local procedure VerifyOpportunityLinkingOnSalesQuotes(FirstSalesQuoteNo: Code[20]; SecondSalesQuoteNo: Code[20]; OpportunityNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Quote, FirstSalesQuoteNo);
        SalesHeader.TestField("Opportunity No.", OpportunityNo);
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SecondSalesQuoteNo);
        SalesHeader.TestField("Opportunity No.", '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOpportModalFormHandler(var CreateOpportunity: Page "Create Opportunity"; var Reply: Action)
    var
        SalesCycle: Record "Sales Cycle";
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();  // Required to initialize the variable.
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();  // Insert temporary Opportunity to modify fields later.

        LibraryMarketing.CreateSalesCycle(SalesCycle);
        TempOpportunity.Validate(Description, SalesCycle.Code);
        TempOpportunity.Validate("Sales Cycle Code", SalesCycle.Code);
        TempOpportunity.Validate("Activate First Stage", true);
        TempOpportunity.Modify();
        TempOpportunity.FinishWizard();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteFormHandler(var SalesQuote: Page "Sales Quote")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesQuote.GetRecord(SalesHeader);
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplateCode2);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteNoCustomerPageHandler(var SalesQuote: Page "Sales Quote")
    begin
        SalesQuote.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpportModalPageHandler(var CloseOpportunity: Page "Close Opportunity"; var Reply: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateModalPageHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        CustomerTemplate: Record "Customer Templ.";
        ActionOption: Option LookupOK,Cancel;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ActionOption::LookupOK:
                begin
                    CustomerTemplate.Get(CustomerTemplateCode2);
                    CustomerTemplateList.SetRecord(CustomerTemplate);
                    Reply := ACTION::LookupOK;
                end;
            ActionOption::Cancel:
                Reply := ACTION::Cancel;
        end;
    end;
}

