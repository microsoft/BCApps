codeunit 136200 "Marketing Campaign Segments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [Campaign] [Segment] [Sales]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        IsInitialized: Boolean;
        CampaignNo2: Code[20];
        CampaignNo3: Code[20];
        InteractionTemplateCode: Code[10];
        ContactMustNotExistError: Label '%1 with %2 %3 must not exist.';
        ContactMustExistError: Label '%1 with %2 %3 must exist.';
        SegmentLineMustNotExistError: Label '%1 with %2=%3,%4=%5 must not exist.';
        PhoneNumberError: Label 'You must fill in the phone number.';
        DescriptionError: Label 'You must fill in the Description field.';
        UnknownError: Label 'Unknown error.';
        WrongMailingGroupDescriptionFieldLengthErr: Label 'Wrong Mailing Group Description field length.';
        InteractionTemplateCode2: Code[10];
        SegmentHeaderNo2: Code[20];
        InterTemplateSalesInvoicesNotSpecifiedErr: Label 'The Invoices field on the Sales FastTab in the Interaction Template Setup window must be filled in.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    [HandlerFunctions('CreateInteractModalFormHandler')]
    [Scope('OnPrem')]
    procedure CampaignAndInteractionsLinked()
    var
        Campaign: Record Campaign;
        CampaignStatus: Record "Campaign Status";
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        // Covers document number TC0064 - refer to TFS ID 21741.
        // Test creation of a campaign and the interactions linked to the campaign.

        // 1. Setup: Create new Campaign Status and Campaign. Link the Campaign Status to the Campaign. Create new Interaction Template
        // with Unit Cost (LCY) and Unit Duration (Min.).
        Initialize();
        LibraryMarketing.CreateCampaignStatus(CampaignStatus);
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Status Code", CampaignStatus.Code);
        Campaign.Modify(true);
        CampaignNo2 := Campaign."No.";  // Set global variable for form handler.
        CreateInteractionTemplate(InteractionTemplate);

        // 2. Exercise: Create Interaction for a Contact.
        Contact.SetFilter("Salesperson Code", '<>%1', '');
        Contact.FindFirst();
        Contact.CreateInteraction();

        // 3. Verify: Check that the Interaction Log Entry and Campaign Entry are created correctly.
        VerifyInteractionLogEntry(InteractionTemplate, Contact."No.", Campaign."No.");
        VerifyCampaignEntry(InteractionTemplate, Campaign."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSegmentLinesByNoTest()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentHeader.Validate(Description, 'Description');

        SegmentLine.Find();
        SegmentLine.TestField(Description, SegmentHeader.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingContactsToSegments()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
    begin
        // Covers document number TC0065 - refer to TFS ID 21741.
        // Test adding Contacts to Segments.

        // 1. Setup: Create new Segment Header.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);

        // 2. Exercise: Add Contact to Segment by running Add Contacts.
        Contact.FindFirst();
        Contact.SetRange("No.", Contact."No.");
        AddContactsToSegment(Contact, SegmentHeader);

        // 3. Verify: Check that the Contact was added successfully to the Segment Line.
        VerifyContactAddedSegmentLine(Contact, SegmentHeader."No.");
        SegmentHeader.CalcFields("No. of Lines");
        SegmentHeader.TestField("No. of Lines", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReducingContactsFromSegments()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
        SecondContactSalespersonCode: Code[20];
    begin
        // Covers document number TC0065 - refer to TFS ID 21741.
        // Test reducing Contacts from Segments.

        // 1. Setup: Create new Segment Header. Add Contacts with different Salespersons to Segment by running Add Contacts.
        Initialize();
        SecondContactSalespersonCode := CreateSegmentWithContact(SegmentHeader, Contact);

        // 2. Exercise: Reduce contacts for a specific Salesperson from the Segment Line by running Reduce Contacts - Remove.
        Contact.SetRange("Salesperson Code", Contact."Salesperson Code");
        RemoveContactsFromSegment(Contact, SegmentHeader);

        // 3. Verify: Check that the Contact was reduced/removed successfully from the Segment Line and contacts with other Salespersons
        // exist on Segment Line.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.SetRange("Salesperson Code", Contact."Salesperson Code");
        Assert.IsFalse(
          SegmentLine.FindFirst(),
          StrSubstNo(
            ContactMustNotExistError, SegmentLine.TableCaption(), SegmentLine.FieldCaption("Salesperson Code"),
            SegmentLine."Salesperson Code"));
        SegmentLine.SetRange("Salesperson Code", SecondContactSalespersonCode);
        Assert.IsTrue(
          SegmentLine.FindFirst(),
          StrSubstNo(
            ContactMustExistError, SegmentLine.TableCaption(), SegmentLine.FieldCaption("Salesperson Code"), SegmentLine."Salesperson Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefiningContactsOnSegments()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
        SecondContactSalespersonCode: Code[20];
    begin
        // Covers document number TC0065 - refer to TFS ID 21741.
        // Test refining Contacts on Segments.

        // 1. Setup: Create new Segment Header. Add Contacts with different Salespersons to Segment by running Add Contacts.
        Initialize();
        SecondContactSalespersonCode := CreateSegmentWithContact(SegmentHeader, Contact);

        // 2. Exercise: Refine contacts for a specific Salesperson from the Segment Line by running Reduce Contacts - Refine.
        Contact.SetRange("Salesperson Code", Contact."Salesperson Code");
        RefineContactsOnSegment(Contact, SegmentHeader);

        // 3. Verify: Check that the Segment Line was refined successfully. The Segment Lines with the Salesperson code refined exist and
        // contacts with other Salesperson do not exist on Segment Line.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.SetRange("Salesperson Code", Contact."Salesperson Code");
        Assert.IsTrue(
          SegmentLine.FindFirst(),
          StrSubstNo(
            ContactMustExistError, SegmentLine.TableCaption(), SegmentLine.FieldCaption("Salesperson Code"), SegmentLine."Salesperson Code"));
        SegmentLine.SetRange("Salesperson Code", SecondContactSalespersonCode);
        Assert.IsFalse(
          SegmentLine.FindFirst(),
          StrSubstNo(
            ContactMustNotExistError, SegmentLine.TableCaption(), SegmentLine.FieldCaption("Salesperson Code"),
            SegmentLine."Salesperson Code"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RemoveAllContactsFromSegments()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // Covers document number TC0065 - refer to TFS ID 21741.
        // Test removing all Contacts from Segments.

        // 1. Setup: Create new Segment Header. Add Contacts with different Salespersons to Segment by running Add Contacts.
        Initialize();
        CreateSegmentWithContact(SegmentHeader, Contact);

        // 2. Exercise: Reduce all contacts from the Segment Line by running Reduce Contacts - Remove.
        Contact.SetRange("Salesperson Code");  // Remove all filters from Contact.
        RemoveContactsFromSegment(Contact, SegmentHeader);

        // 3. Verify: Check that Segment Lines for all contacts were removed.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        Assert.IsFalse(
          SegmentLine.FindFirst(),
          StrSubstNo(
            SegmentLineMustNotExistError, SegmentLine.TableCaption(), SegmentLine.FieldCaption("Segment No."), SegmentLine."Segment No.",
            SegmentLine.FieldCaption("Line No."), SegmentLine."Line No."));
        SegmentHeader.CalcFields("No. of Lines");
        SegmentHeader.TestField("No. of Lines", 0);
    end;

    [Test]
    [HandlerFunctions('NumberErrorModalFormHandler')]
    [Scope('OnPrem')]
    procedure MakePhoneCallNumberError()
    begin
        // Covers document number TC0066 - refer to TFS ID 21741.
        // Test that the application generates an error if Phone Number is left blank in the Make Phone Call wizard, called from the
        // Segment window. The handler function called should be NumberErrorModalFormHandler.

        InvokeMakePhoneCallError(PhoneNumberError);
    end;

    [Test]
    [HandlerFunctions('DescriptionModalFormHandler')]
    [Scope('OnPrem')]
    procedure MakePhoneCallDescriptionError()
    begin
        // Covers document number TC0066 - refer to TFS ID 21741.
        // Test that the application generates an error if Description is left blank in the Make Phone Call wizard, called from the
        // Segment window. The handler function called should be DescriptionModalFormHandler.

        InvokeMakePhoneCallError(DescriptionError);
    end;

    local procedure InvokeMakePhoneCallError(ErrorMessage: Text[1024])
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // 1. Setup: Create new Segment Header, Segment Line.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // 2. Exercise: Run Make Phone Call wizard.
        asserterror SegmentLine.CreatePhoneCall();

        // 3. Verify: Check that the application generates an error if some field is not there in the Make Phone Call wizard.
        Assert.AreEqual(StrSubstNo(ErrorMessage), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('CallNeutralModalFormHandler')]
    [Scope('OnPrem')]
    procedure MakePhoneCallNeutralEvaluation()
    begin
        // Covers document number TC0066 - refer to TFS ID 21741.
        // Test the Neutral Evaluation option in Make Phone Call wizard, called from the Segment window. The handler function called should
        // be CallNeutralModalFormHandler.

        InvokeMakePhoneCall(false);
    end;

    [Test]
    [HandlerFunctions('AttemptFailedModalFormHandler')]
    [Scope('OnPrem')]
    procedure MakePhoneCallAttemptFailed()
    begin
        // Covers document number TC0066 - refer to TFS ID 21741.
        // Test the Neutral Evaluation option in Make Phone Call wizard with Attempt Failed unchecked, called from the Segment window. The
        // handler function called should be AttemptFailedModalFormHandler.

        InvokeMakePhoneCall(true);
    end;

    local procedure InvokeMakePhoneCall(AttemptFailed: Boolean)
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // 1. Setup: Create new Segment Header, Segment Line.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // 2. Exercise: Run Make Phone Call wizard.
        SegmentLine.CreatePhoneCall();

        // 3. Verify: Check that the Interaction Log Entry created contains Evaluation as Neutral and Attempt Failed as parameter passed.
        VerifyNeutralInteractionLog(SegmentHeader."No.", AttemptFailed);
    end;

    [Test]
    [HandlerFunctions('CallPositiveModalFormHandler')]
    [Scope('OnPrem')]
    procedure MakePhonePositiveEvaluation()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Campaign: Record Campaign;
        Opportunity: Record Opportunity;
    begin
        // Covers document number TC0066 - refer to TFS ID 21741.
        // Test the Very Positive Evaluation option in Make Phone Call wizard, called from the Segment window.

        // 1. Setup: Create new Segment Header, Segment Line, Campaign, Opportunity for Contact in Segment Line.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");
        LibraryMarketing.CreateCampaign(Campaign);
        CampaignNo3 := Campaign."No.";  // Set global variable for form handler.
        LibraryMarketing.CreateOpportunity(Opportunity, SegmentLine."Contact No.");

        // 2. Exercise: Run Make Phone Call wizard.
        SegmentLine.CreatePhoneCall();

        // 3. Verify: Check that the Interaction Log Entry created contains Evaluation as Very Positive, Attempt Failed as FALSE and
        // Opportunity No. as that of opportunity created.
        VerifyPositiveInteractionLog(SegmentHeader."No.", Opportunity."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentInteractionTemplateCode()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
    begin
        // Covers document number TC0069 - refer to TFS ID 21741.
        // Test that the Interaction Template information flows from the Segment Header to the Segment Lines.

        // 1. Setup: Create new Segment Header, Interaction Template.
        Initialize();
        CreateSegmentHeaderInteraction(SegmentHeader);

        // 2. Exercise: Create Segment Line by Add Contacts.
        FilterContacts(Contact);
        AddContactsToSegment(Contact, SegmentHeader);

        // 3. Verify: Check that the value of Interaction Template on Segment Lines matches the value of Interaction Template on Segment
        // Header.
        VerifyInteractionTemplate(SegmentHeader);
    end;

    [Test]
    [HandlerFunctions('SaveSegmentModalFormHandler,CriteriaListModalFormHandler')]
    [Scope('OnPrem')]
    procedure SegmentSaveCriteriaAndReuse()
    var
        SegmentHeader: Record "Segment Header";
        SegmentHeader2: Record "Segment Header";
        Contact: Record Contact;
    begin
        // Covers document number TC0069 - refer to TFS ID 21741.
        // Test that it is possible to save criteria for the Segment and create new Segment by using the saved criteria.

        // 1. Setup: Create new Segment Header, Interaction Template. Create Segment Line by Add Contacts. Save Criteria.
        Initialize();
        CreateSegmentHeaderInteraction(SegmentHeader);

        FilterContacts(Contact);
        AddContactsToSegment(Contact, SegmentHeader);
        InteractionTemplateCode2 := SegmentHeader."Interaction Template Code";  // Set global variable for form handler.
        SegmentHeaderNo2 := SegmentHeader."No.";
        SegmentHeader.SaveCriteria();

        // 2. Exercise: Create new Segment Header. Input the same Interaction Code as was used earlier. Run Reuse Criteria.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader2);
        SegmentHeader2.Validate("Interaction Template Code", SegmentHeader."Interaction Template Code");
        SegmentHeader2.Modify(true);
        SegmentHeader2.ReuseCriteria();

        // 3. Verify: Check that the Segment Lines created in new Segment by using the saved criteria have the same information as
        // Segment Lines for Segment for which Criteria was saved.
        VerifySaveCriteriaAndReuse(SegmentHeader."No.", SegmentHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceActivation()
    var
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        ContactBusinessRelation: Record "Contact Business Relation";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        CustomerNo: Code[20];
        SalesHeaderNo: Code[20];
    begin
        // Covers document number TC0070 - refer to TFS ID 21741.
        // Test that Sales Prices and Discounts are suggested on the Sales Line when all the required criteria are met for Activated
        // Campaign.

        // 1. Setup: Create new Campaign, Sales Price and Sales line Discount for Campaign, Segment Header with Campaign. Add Contacts to
        // Segment and Activate Campaign.
        Initialize();
        CreateCampaignPriceDiscount(Campaign, SalesPrice, SalesLineDiscount);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSegmentWithCampaign(Campaign."No.", ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // 2. Exercise: Create a new Sales Order- Sales Header and three Sales Lines with different quantities so that the conditions for
        // Sales Price and Line Discount are met.
        CopyAllSalesPriceToPriceListLine();
        SalesHeaderNo := CreateSalesOrderForCampaign(SalesPrice, CustomerNo, SalesLineDiscount."Minimum Quantity");

        // 3. Verify: Check that Sales Prices and Discounts are suggested on the Sales Line when all the required criteria are met for
        // Activated Campaign.
        VerifyPriceDiscountsActivated(SalesPrice, SalesLineDiscount, SalesHeaderNo);
    end;

    local procedure CopyAllSalesPriceToPriceListLine()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceDeactivation()
    var
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerNo: Code[20];
        SalesHeaderNo: Code[20];
    begin
        // Covers document number TC0070 - refer to TFS ID 21741.
        // Test that Sales Prices and Discounts are not suggested on the Sales Line when all the required criteria are met for Campaign
        // that is deactivated.

        // 1. Setup: Create new Campaign, Sales Price and Sales line Discount for Campaign, Segment Header with Campaign. Add Contacts to
        // Segment.
        Initialize();
        CreateCampaignPriceDiscount(Campaign, SalesPrice, SalesLineDiscount);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSegmentWithCampaign(Campaign."No.", ContactBusinessRelation."Link to Table"::Customer, CustomerNo);

        // 2. Exercise: Create a new Sales Order- Sales Header and three Sales Lines with different quantities so that the conditions for
        // Sales Price and Line Discount are met.
        SalesHeaderNo := CreateSalesOrderForCampaign(SalesPrice, CustomerNo, SalesLineDiscount."Minimum Quantity");

        // 3. Verify: Check that Sales Prices and Discounts are not suggested on the Sales Line when all the required criteria are met for
        // Campaign that is deactivated.
        VerifyPriceDiscountDeactivated(SalesHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactMailingGroupDescription()
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        MailingGroup: Record "Mailing Group";
    begin
        // Verifies Mailing Group Description flowfield calculation - refer to TFS ID 51572
        Assert.AreEqual(
          LibraryUtility.GetFieldLength(DATABASE::"Mailing Group", MailingGroup.FieldNo(Description)),
          LibraryUtility.GetFieldLength(DATABASE::"Contact Mailing Group", ContactMailingGroup.FieldNo("Mailing Group Description")),
          WrongMailingGroupDescriptionFieldLengthErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyMailingGroup()
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        MailingGroup: Record "Mailing Group";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test that on Apply Mailing Group from the segment the Mailing Group is attached to the Contact.

        // 1. Setup: Create new Segment Header, Segment Line.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // 2. Exercise: Create Mailing Group and Apply Mailing Group to the Segment.
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        ApplyMailingGroupToSegment(SegmentHeader, MailingGroup.Code);

        // 3. Verify: Check that Mailing group is attached to the Contact.
        ContactMailingGroup.SetRange("Mailing Group Code", MailingGroup.Code);
        ContactMailingGroup.FindFirst();
        ContactMailingGroup.TestField("Contact No.", SegmentLine."Contact No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReduceContactFromSegment()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SegmentLine2: Record "Segment Line";
        Contact: Record Contact;
        FirstContactNo: Code[20];
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test that removing a Contact from Segment does not remove all the contacts.

        // 1. Setup: Create new Segment Header. Add Contacts.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        FirstContactNo := SegmentLine."Contact No.";
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // 2. Exercise: Reduce the first contacts from the Segment Line by running Reduce Contacts - Remove.
        Contact.SetRange("No.", FirstContactNo);
        RemoveContactsFromSegment(Contact, SegmentHeader);

        // 3. Verify: Check on Segment Lines only first contact is removed and Second contact still exists.
        SegmentLine2.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine2.SetRange("Contact No.", FirstContactNo);
        Assert.IsFalse(
          SegmentLine2.FindFirst(),
          StrSubstNo(
            SegmentLineMustNotExistError, SegmentLine2.TableCaption(), SegmentLine2.FieldCaption("Segment No."), SegmentLine2."Segment No.",
            SegmentLine2.FieldCaption("Line No."), SegmentLine2."Line No."));

        SegmentLine2.SetRange("Contact No.", SegmentLine."Contact No.");
        SegmentLine2.FindFirst();  // Second contact still exists.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefineContactFromSegment()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SegmentLine2: Record "Segment Line";
        Contact: Record Contact;
        FirstContactNo: Code[20];
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test that refining a Contact from Segment removes all other Contact on Segment Lines.

        // 1. Setup: Create new Segment Header. Add Contacts.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");
        FirstContactNo := SegmentLine."Contact No.";
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // 2. Exercise: Refine the first contact from the Segment Line by running Reduce Contacts - Refine.
        Contact.SetRange("No.", FirstContactNo);
        RefineContactsOnSegment(Contact, SegmentHeader);

        // 3. Verify: Check that the Segment Line was refined successfully. First Segment Line refined exist and the second line
        // for the contact do not exist on Segment Line.
        SegmentLine2.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine2.SetRange("Contact No.", FirstContactNo);
        SegmentLine2.FindFirst();  // First Segment line is Refined.

        SegmentLine2.SetRange("Contact No.", SegmentLine."Contact No.");
        Assert.IsFalse(
          SegmentLine2.FindFirst(),
          StrSubstNo(
            ContactMustNotExistError, SegmentLine2.TableCaption(), SegmentLine2.FieldCaption("Contact No."), SegmentLine2."Contact No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewSegmentWithDetails()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
    begin
        // Test Creation of a new Segment along with other details such as Salesperson and Campaign.

        // 1. Setup: Create new Segment Header.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);

        // 2. Exercise: Add a new Salesperson to Segment and add Contact to Segment by running Add Contacts. Add Campaign.
        AddSalespersonToSegment(SegmentHeader);

        LibraryMarketing.FindContact(Contact);
        Contact.SetRange("No.", Contact."No.");
        AddContactsToSegment(Contact, SegmentHeader);

        AddCampaignToSegment(SegmentHeader);

        // 3. Verify: Verify that the Salesperson and Campaign has been added on the Segment Line.
        VerifySalespersonCampaignLines(SegmentHeader);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCampaignWithNoSeries()
    var
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Codeunit "No. Series";
        CampaignCard: TestPage "Campaign Card";
        CampaignNo: Code[20];
    begin
        // Test Creation of a new Campaign from Card with No Series.

        // 1. Setup:
        Initialize();
        MarketingSetup.Get();

        // 2. Exercise: Create new Campaign from Card.
        CampaignNo := NoSeries.PeekNextNo(MarketingSetup."Campaign Nos.");
        CampaignCard.OpenNew();
        CampaignCard."No.".AssistEdit();

        // 3. Verify: Verify Created Campaign Number with Number Series Value.
        CampaignCard."No.".AssertEquals(CampaignNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCampaignFromCardDetails()
    var
        CampaignStatus: Record "Campaign Status";
        SalespersonCode: Code[20];
        CampaignNo: Code[20];
    begin
        // Test Creation of a new Campaign from Card with details.

        // 1. Setup: Find Salesperson and create Campaign Status.
        Initialize();
        SalespersonCode := FindSalespersonPurchaser();
        LibraryMarketing.CreateCampaignStatus(CampaignStatus);

        // 2. Exercise: Create new Campaign from Card with Details.
        CampaignNo := CreateCampaignWithDetails(SalespersonCode, CampaignStatus.Code);

        // 3. Verify: Verify Campaign with Details;
        VerifyCampaignWithDetails(CampaignNo, SalespersonCode, CampaignStatus.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesPriceDiscountActivation()
    var
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Test to verify that Sales Price and Sales Line Discount are suggested on the Sales Line for an activated Campaign.

        // 1. Setup: Create new Campaign, Sales Price and Sales line Discount for Campaign, a Segment with the Campaign. Add Contacts to
        // Segment and Activate Campaign.
        SalesPriceDiscountScenario(Campaign, SalesPrice, CustomerNo, SalesLineDiscount);
        ActivatePagePriceLineDiscount(Campaign."No.");

        // 2. Exercise: Create a new Sales Order.
        SalesOrderPageOpenNew(SalesOrderNo);
        CopyAllSalesPriceToPriceListLine();
        UpdateSalesOrderForCampaign(SalesPrice, SalesOrderNo, CustomerNo, SalesLineDiscount."Minimum Quantity");

        // 3. Verify: Verify that Sales Price and Sales Line Discount are suggested on the Sales Line for an activated Campaign.
        VerifyPriceDiscountActivation(SalesOrderNo, SalesPrice."Unit Price", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceDiscountDeactivation()
    var
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Test to verify that Sales Price and Sales Line Discount are not suggested on the Sales Line for a deactivated Campaign.

        // 1. Setup: Create new Campaign, Sales Price and Sales line Discount for Campaign, a Segment with the Campaign. Add Contacts to
        // Segment.
        SalesPriceDiscountScenario(Campaign, SalesPrice, CustomerNo, SalesLineDiscount);

        // 2. Exercise: Create a new Sales Order.
        SalesOrderPageOpenNew(SalesOrderNo);
        UpdateSalesOrderForCampaign(SalesPrice, SalesOrderNo, CustomerNo, SalesLineDiscount."Minimum Quantity");

        // 3. Verify: Verify that Sales Price and Sales Line Discount are not suggested on the Sales Line for a Campaign.
        VerifyPriceDiscountDeactivate(SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignEntryCreatedWhenPostSalesOrderWithActivatedCampaign()
    var
        Campaign: Record Campaign;
        SalesHeader: Record "Sales Header";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 381140] Campaign Entry is created when post Sales Order with activated campaign

        Initialize();

        // [GIVEN] Activated Campaign "X"
        ActivatedSalesCampaignScenario(Campaign, SalesPrice, CustomerNo);

        // [GIVEN] Sales Order with Campaign "X"
        SalesHeader.Get(
          SalesHeader."Document Type"::Order, CreateSalesOrderForCampaign(SalesPrice, CustomerNo, 1));

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Campaign Entry with Campaign "X" exists
        VerifyCampaignEntryExist(Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignEntryNotCreatedWhenPostSalesOrderWithDeactivatedCampaign()
    var
        Campaign: Record Campaign;
        SalesHeader: Record "Sales Header";
        SalesPrice: Record "Sales Price";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 381140] Campaign Entry is not created when post Sales Order with deactivated campaign

        Initialize();

        // [GIVEN] Deactivated Campaign "X"
        ActivatedSalesCampaignScenario(Campaign, SalesPrice, CustomerNo);
        CampaignTargetGroupMgt.DeactivateCampaign(Campaign, false);

        // [GIVEN] Sales Order with Campaign "X"
        SalesHeader.Get(
          SalesHeader."Document Type"::Order, CreateSalesOrderForCampaign(SalesPrice, CustomerNo, 1));

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Campaign Entry with Campaign "X" does not exist
        VerifyCampaignEntryDoesNotExist(Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UT_CampaignEntryNotCreatedIfInteractionLogEntryAlreadyExist()
    var
        Campaign: Record Campaign;
        ContactBusinessRelation: Record "Contact Business Relation";
        SalesHeader: Record "Sales Header";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 381140] Sales Campaign Entry is not created when Interaction Log Entry for this "Document No." already exists

        Initialize();

        // [GIVEN] Activated Campaign "X"
        ActivatedSalesCampaignScenario(Campaign, SalesPrice, CustomerNo);

        // [GIVEN] Sales Order "Y" with Campaign "X"
        SalesHeader.Get(
          SalesHeader."Document Type"::Order, CreateSalesOrderForCampaign(SalesPrice, CustomerNo, 1));

        // [GIVEN] Interaction Log Entry with "Document Type" = "Sales Order Confirmation", "Document No." = "Y"
        // Interaction Log Entry with type "Sales Order Confirmation" inserts when print "Sales Order Confirmation" report
        MockInteractionLogEntry(
          "Interaction Log Entry Document Type"::"Sales Inv.", SalesHeader."No.",
          GetContactBusinessRelation(ContactBusinessRelation."Link to Table"::Customer, SalesHeader."Bill-to Customer No."));

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Campaign Entry with Campaign "X" does not exist
        VerifyCampaignEntryDoesNotExist(Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignEntryNotCreatedWhenPostSalesOrderWithActivatedCampaignOutsidePostingDate()
    var
        Campaign: Record Campaign;
        SalesHeader: Record "Sales Header";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 201851] Campaign Entry is not create when Sales Order with Activated Campaign and "Posting Date" outside campaign's dates

        Initialize();

        // [GIVEN] Activated Campaign "X" with "Starting Date" = 01.01 and "Ending Date" = 01.02
        ActivatedSalesCampaignScenario(Campaign, SalesPrice, CustomerNo);

        // [GIVEN] Sales Order "Y" with Campaign "X" and "Posting Date" = 05.02
        SalesHeader.Get(
          SalesHeader."Document Type"::Order, CreateSalesOrderForCampaign(SalesPrice, CustomerNo, 1));
        SalesHeader.Validate("Posting Date", Campaign."Ending Date" + 1);
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Campaign Entry with Campaign "X" does not exist
        VerifyCampaignEntryDoesNotExist(Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InteractionTemplateVerificationWhenPostSalesOrderWithActivatedCampaign()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        Campaign: Record Campaign;
        SalesHeader: Record "Sales Header";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 201851] Interaction template is verified and error message is raised if it does not exist when Sales Order with activated campaign is posted

        Initialize();

        // [GIVEN] Activated Campaign "X"
        ActivatedSalesCampaignScenario(Campaign, SalesPrice, CustomerNo);

        // [GIVEN] Interaction Template code for "Sales Invoices" is not specified in "Interaction Template Setup"
        InteractionTemplateSetup.Get();
        InteractionTemplateSetup."Sales Invoices" := '';
        InteractionTemplateSetup.Modify();

        // [GIVEN] Sales Order with Campaign "X"
        SalesHeader.Get(
          SalesHeader."Document Type"::Order, CreateSalesOrderForCampaign(SalesPrice, CustomerNo, 1));

        // [WHEN] Post Sales Order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error message "You must specify interaction template code "Sales Invoices" in Interaction Template Setup" is thrown
        Assert.ExpectedError(InterTemplateSalesInvoicesNotSpecifiedErr);
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsAllContactsMailingGrouAllowRelatedCompaniesTrue()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests all contacts within a mailing group ("Allow Related Companies" = TRUE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person and related Company "A"
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);
        Contact[3].Validate("Company No.", Contact[1]."No.");
        Contact[3].Modify(true);

        // [GIVEN] "M" contains "A", "B", "C"
        for Index := 1 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and with option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(true);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "A", "B", "C" suggested
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 3, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsAllContactsMailingGrouAllowRelatedCompaniesFalse()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests all contacts within a mailing group ("Allow Related Companies" = FALSE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person and related Company "A"
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);
        Contact[3].Validate("Company No.", Contact[1]."No.");
        Contact[3].Modify(true);

        // [GIVEN] "M" contains "A", "B", "C"
        for Index := 1 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and without option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(false);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "A", "B", "C" suggested (because all of them in mailing group)
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 3, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsAllUnRelatedContactsWithinMailingGroupmpaniesAllowRelatedCompaniesFALSE()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests all unrelated contacts within a mailing group ("Allow Related Companies" = FALSE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);

        // [GIVEN] "M" contains "A", "B", "C"
        for Index := 1 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and without option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(false);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "A", "B", "C" suggested (because all of them in mailing group)
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 3, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsMailingGroupContactsWithRelatedCompaniesAllowRelatedCompaniesTRUE()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests contacts within a mailing group with related companies out of mailing group ("Allow Related Companies" = TRUE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person and Related Company = "A"
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);
        Contact[3].Validate("Company No.", Contact[1]."No.");
        Contact[3].Modify(true);

        // [GIVEN] "M" contains "B", "C"
        for Index := 2 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and with option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(true);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "A", "B", "C" suggested (because "B" and "C" in mailing group and "A" added due to option "Allow Related Companies")
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 3, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsMailingGroupContactsOnlySkipsUnRelatedCompaniesAllowRelatedCompaniesTRUE()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests contacts within a mailing group only and skips unrelated companies ("Allow Related Companies" = TRUE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);

        // [GIVEN] "M" contains "B", "C"
        for Index := 2 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and with option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(true);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "B", "C" suggested (because "B" and "C" in mailing group and no one associated with "A")
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 2, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AddContactsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AddContactsMailingGroupContactsOnlySkipsRelatedCompaniesAllowRelatedCompaniesFALSE()
    var
        MailingGroup: Record "Mailing Group";
        Contact: array[3] of Record Contact;
        ContactMailingGroup: Record "Contact Mailing Group";
        SegmentHeader: Record "Segment Header";
        Index: Integer;
    begin
        // [SCEANARIO 264590] "Add Contacts" suggests contacts within a mailing group only and skips related companies ("Allow Related Companies" = FALSE)

        // [GIVEN] Mailing Group "M"
        // [GIVEN] Contact "A" with type Company
        // [GIVEN] Contact "B" with type Person
        // [GIVEN] Contact "C" with type Person with Related Company "A"
        LibraryMarketing.CreateMailingGroup(MailingGroup);
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreatePersonContact(Contact[2]);
        LibraryMarketing.CreatePersonContact(Contact[3]);
        Contact[3].Validate("Company No.", Contact[1]."No.");
        Contact[3].Modify(true);

        // [GIVEN] "M" contains "B", "C"
        for Index := 2 to ArrayLen(Contact) do
            LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact[Index]."No.", MailingGroup.Code);

        // [WHEN] Run report "Add contacts" with filter "Mailing Group" = "M" and without option "Allow Related Companies"
        CreateSegmentHeaderInteraction(SegmentHeader);
        LibraryVariableStorage.Enqueue(false);
        RunAddContactsWithMailingGroup(SegmentHeader, ContactMailingGroup);

        // [THEN] Contacts "B", "C" suggested (because "B" and "C" in mailing group, "A" is not in mailing group and associated companies are not allowed)
        VerifySegmentLinesPerContact(SegmentHeader, Contact, 2, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CampaignTargetGrpAddSegLineToTarget()
    var
        Campaign: Record Campaign;
        CampaignStatus: Record "Campaign Status";
        CampaignTargetGr: Record "Campaign Target Group";
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313965] "Campaign Target Group Mgt" codeunit creates "Campaign Target Group"
        Initialize();

        // [GIVEN] Created new Campaign Status and Campaign. Linked the Campaign Status to the Campaign
        LibraryMarketing.CreateCampaignStatus(CampaignStatus);
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Status Code", CampaignStatus.Code);
        Campaign.Modify(true);

        // [GIVEN] Created Segment with Segment Line. Linked Segment Line to the Contact and Campaign
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        LibraryMarketing.CreateCompanyContact(Contact);
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Validate("Campaign No.", Campaign."No.");
        SegmentLine.Validate("Campaign Target", true);
        SegmentLine.Modify(true);

        // [WHEN] Add Segment Line to Target Group using "Campaign Target Group Mgt"
        CampaignTargetGroupMgt.AddSegLinetoTargetGr(SegmentLine);

        // [THEN] Campaign Target Group is successfully created
        VerifyCampaignTargetGroupExists(
          CampaignTargetGr.Type::Contact, SegmentLine."Contact Company No.", SegmentLine."Campaign No.");
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalFormHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignTargetGrpActivateCampaign()
    var
        Campaign: Record Campaign;
        CampaignStatus: Record "Campaign Status";
        CampaignTargetGr: Record "Campaign Target Group";
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313965] "Campaign Target Group Mgt" codeunit creates "Campaign Target Group"
        Initialize();

        // [GIVEN] Created new Campaign Status and Campaign. Linked the Campaign Status to the Campaign
        LibraryMarketing.CreateCampaignStatus(CampaignStatus);
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Status Code", CampaignStatus.Code);
        Campaign.Modify(true);

        // [GIVEN] Created new Interaction Template
        CampaignNo2 := Campaign."No.";  // Set global variable for form handler.
        CreateInteractionTemplate(InteractionTemplate);

        // [GIVEN] Created Interaction for a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateInteraction();

        // [GIVEN] Activated Campaign Target on Interaction Log Entry
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.FindLast();
        InteractionLogEntry.Validate("Campaign Target", true);
        InteractionLogEntry.Modify(true);

        // [WHEN] Activate Campaign using "Campaign Target Group Mgt"
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // [THEN] Campaign Target Group is successfully created
        VerifyCampaignTargetGroupExists(
          CampaignTargetGr.Type::Contact, InteractionLogEntry."Contact Company No.", InteractionLogEntry."Campaign No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLineUpdateDescriptionOnUpdateInteractionTemplateCode()
    var
        SegmentLine: Record "Segment Line";
        InteractionTemplate: Array[2] of Record "Interaction Template";
    begin
        // [SCENARIO 398630] Segment Line Description should update on Interaction Template change
        Initialize();

        // [GIVEN] Segment Header with Description 'X1' and Segment Line
        LibraryMarketing.CreateSegmentLine(SegmentLine, '');
        SegmentLine.Validate("Contact No.", LibraryMarketing.CreateCompanyContactNo());
        SegmentLine.Modify(true);

        // [GIVEN] Interaction Template 'IT1' with Description 'X2'
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate[1]);

        // [GIVEN] Interaction Template 'IT2' with Description 'X3'
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate[2]);

        // [WHEN] Segment Line Interaction Template Code = "IT1"
        SegmentLine.Find();
        SegmentLine.Validate("Interaction Template Code", InteractionTemplate[1].Code);
        SegmentLine.Modify(true);

        // [THEN] Segment Line Description = "X2"
        SegmentLine.TestField(Description, InteractionTemplate[1].Description);

        // [WHEN] Segment Line Interaction Template Code = "IT2"
        SegmentLine.Validate("Interaction Template Code", InteractionTemplate[2].Code);
        SegmentLine.Modify(true);

        // [THEN] Segment Line Description = "X3"
        SegmentLine.TestField(Description, InteractionTemplate[2].Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CampaignInsertTargetGroupContactCompContact()
    var
        SegmentLine: Array[2] of Record "Segment Line";
        Contact: Record Contact;
        CompanyContact: Record Contact;
        Campaign: Record Campaign;
        CampaignTargetGroup: Record "Campaign Target Group";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        // [SCENARIO 404832] Creation of Campaign Target Group from Segment Lines with Company Contact and its' related Contact should not show error
        Initialize();

        // [GIVEN] Company Contact 'CompC' and related Contact 'C'
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);
        CompanyContact.Get(Contact."Company No.");

        // [GIVEN] Campaign "C"
        LibraryMarketing.CreateCampaign(Campaign);

        // [GIVEN] Segment Line with Company Contact 'CompC' and Campaign 'C'
        CreateSegmentLineWithContCampaign(SegmentLine[1], CompanyContact."No.", Campaign."No.");

        // [GIVEN] Segment Line with Contact 'C' and Campaign 'C'
        CreateSegmentLineWithContCampaign(SegmentLine[2], Contact."No.", Campaign."No.");

        // [GIVEN] Segment Line with Company Contact added to Campaign Target Group
        CampaignTargetGroupMgt.AddSegLinetoTargetGr(SegmentLine[1]);

        // [WHEN] Segment Line with Contact 'C' added to Campaign Target Group
        CampaignTargetGroupMgt.AddSegLinetoTargetGr(SegmentLine[2]);

        // [THEN] No error appears and Campaing Target Group for "CompC" exists
        VerifyCampaignTargetGroupExists(CampaignTargetGroup.Type::Contact, CompanyContact."No.", Campaign."No.");
    end;

    [Test]
    [HandlerFunctions('CallVeryPositiveModalFormHandler')]
    [Scope('OnPrem')]
    procedure VerifySegmentNoExistOnCreatedOpportunity()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Opportunity: Record Opportunity;
        MakePhoneCall: TestPage "Make Phone Call";
        Segment: TestPage Segment;
    begin
        // [SCENARIO 486119] No opportunity is created from segments, when choosing Yes in the dialog.
        Initialize();

        // [GIVEN] Setup: Create new Segment Header, Segment Line, Campaign, Opportunity for Contact in Segment Line.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineWithContact(SegmentLine, SegmentHeader."No.");

        // [GIVEN] Open Segment Card and Invoke Make Phone Call action for the Segment Line
        Segment.OpenView();
        Segment.GoToRecord(SegmentHeader);
        MakePhoneCall.Trap();
        Segment.SegLines."Make &Phone Call".Invoke();
        Segment.Close();

        // [THEN] Get newly created opportunity
        Opportunity.Get(LibraryVariableStorage.DequeueText());

        // [VERIFY] Verify: Opportunity "Segment No." field values equals to the Segment "No." field
        Assert.AreEqual(
            SegmentHeader."No.",
            Opportunity."Segment No.",
            StrSubstNo(
                ValueMustBeEqualErr,
                Opportunity.FieldCaption("Segment No."),
                SegmentHeader."No.",
                Opportunity.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Campaign Segments");
        LibrarySetupStorage.Restore();
        PriceListLine.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Campaign Segments");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Interaction Template Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Campaign Segments");
    end;

    local procedure SalesPriceDiscountScenario(var Campaign: Record Campaign; var SalesPrice: Record "Sales Price"; var CustomerNo: Code[20]; var SalesLineDiscount: Record "Sales Line Discount")
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Initialize();
        SalesAndReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryMarketing.CreateCampaign(Campaign);
        UpdateCampaign(Campaign);
        CreateSalesPrice(SalesPrice, Campaign."No.");
        CreateSalesLineDiscount(SalesLineDiscount, SalesPrice);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSegmentWithCampaign(Campaign."No.", ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
    end;

    local procedure ActivatedSalesCampaignScenario(var Campaign: Record Campaign; var SalesPrice: Record "Sales Price"; var CustomerNo: Code[20])
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
        ContactBusinessRelation: Record "Contact Business Relation";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplateSetup.Get();
        InteractionTemplateSetup.Validate("Sales Invoices", InteractionTemplate.Code);
        InteractionTemplateSetup.Modify(true);
        LibraryMarketing.CreateCampaign(Campaign);
        UpdateCampaign(Campaign);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSegmentWithCampaign(Campaign."No.", ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
        CreateSalesPrice(SalesPrice, Campaign."No.");
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);
        Campaign.Find(); // get latest version after activation
    end;

    local procedure AddCampaignToSegment(var SegmentHeader: Record "Segment Header")
    begin
        SegmentHeader.Validate("Campaign No.", FindCampaign());
        SegmentHeader.Modify(true);
    end;

    local procedure AddContactsToSegment(var Contact: Record Contact; SegmentHeader: Record "Segment Header")
    var
        LibraryVariableStorageVariant: Codeunit "Library - Variable Storage";
    begin
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        LibraryVariableStorageVariant.Enqueue(Contact);
        LibraryVariableStorageVariant.Enqueue(SegmentHeader);
        LibraryMarketing.RunAddContactsReport(LibraryVariableStorageVariant, false);
    end;

    local procedure AddSalespersonToSegment(var SegmentHeader: Record "Segment Header")
    begin
        SegmentHeader.Validate("Salesperson Code", FindSalespersonPurchaser());
        SegmentHeader.Modify(true);
    end;

    local procedure ApplyMailingGroupToSegment(SegmentHeader: Record "Segment Header"; MailingGroupCode: Code[10])
    var
        MailingGroup: Record "Mailing Group";
        ApplyMailingGroup: Report "Apply Mailing Group";
    begin
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        ApplyMailingGroup.SetTableView(SegmentHeader);
        MailingGroup.SetRange(Code, MailingGroupCode);
        ApplyMailingGroup.SetTableView(MailingGroup);
        ApplyMailingGroup.UseRequestPage(false);
        ApplyMailingGroup.RunModal();
    end;

    local procedure CreateCampaignPriceDiscount(var Campaign: Record Campaign; var SalesPrice: Record "Sales Price"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate());
        Campaign.Modify(true);
        CreateSalesPrice(SalesPrice, Campaign."No.");
        CreateSalesLineDiscount(SalesLineDiscount, SalesPrice);
    end;

    local procedure CreateCampaignWithDetails(SalespersonCode: Code[20]; StatusCode: Code[10]) CampaignNo: Code[20]
    var
        CampaignCard: TestPage "Campaign Card";
    begin
        CampaignCard.OpenNew();
        CampaignCard."No.".Activate();
        CampaignCard."Salesperson Code".SetValue(SalespersonCode);
        CampaignCard."Starting Date".SetValue(WorkDate());
        CampaignCard."Ending Date".SetValue(WorkDate());
        CampaignCard."Status Code".SetValue(StatusCode);
        CampaignNo := CampaignCard."No.".Value();
        CampaignCard.OK().Invoke();
    end;

    local procedure CreateInteractionTemplate(var InteractionTemplate: Record "Interaction Template")
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Unit Cost (LCY)", LibraryRandom.RandInt(100));
        InteractionTemplate.Validate("Unit Duration (Min.)", LibraryRandom.RandInt(100));
        InteractionTemplate.Modify(true);
        InteractionTemplateCode := InteractionTemplate.Code;  // Set global variable for form handler.
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; SalesPrice: Record "Sales Price")
    begin
        LibraryMarketing.CreateSalesLineDiscount(SalesLineDiscount, SalesPrice."Sales Code", SalesPrice."Item No.");
        // Add random number to input Minimum Quantity greater than Minimum Quantity of Sales Price.
        SalesLineDiscount.Rename(
          SalesLineDiscount.Type, SalesLineDiscount.Code, SalesLineDiscount."Sales Type", SalesLineDiscount."Sales Code",
          SalesLineDiscount."Starting Date", SalesLineDiscount."Currency Code", SalesLineDiscount."Variant Code",
          SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity" + LibraryRandom.RandInt(10));
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(99));  // Any percentage between 1 and 99.
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateSalesOrderForCampaign(SalesPrice: Record "Sales Price"; CustomerNo: Code[20]; SalesLineDiscountQuantity: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Validate("Currency Code", SalesPrice."Currency Code");
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesPrice."Item No.", SalesPrice."Minimum Quantity" - 1);  // For not meeting Sales Price condition.
        CreateSalesLine(SalesHeader, SalesPrice."Item No.", SalesPrice."Minimum Quantity");
        CreateSalesLine(SalesHeader, SalesPrice."Item No.", SalesLineDiscountQuantity);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; CampaignNo: Code[20])
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));  // To generate large decimal value.
        Item.Modify(true);
        LibraryMarketing.CreateSalesPriceForCampaign(SalesPrice, Item."No.", CampaignNo);
        SalesPrice.Rename(
          SalesPrice."Item No.", SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice."Starting Date", SalesPrice."Currency Code",
          SalesPrice."Variant Code", Item."Base Unit of Measure", LibraryRandom.RandInt(10) + 1);
        // Addition by 1 ensures that Quantity is greater than 1.
        SalesPrice.Validate("Unit Price", 10000 + LibraryRandom.RandDec(1000, 2));  // To generate large decimal value.
        SalesPrice.Modify(true);
    end;

    local procedure ActivatePagePriceLineDiscount(No: Code[20])
    var
        CampaignCard: TestPage "Campaign Card";
    begin
        CampaignCard.OpenView();
        CampaignCard.FILTER.SetFilter("No.", No);
        CampaignCard.ActivateSalesPricesLineDisc.Invoke();
    end;

    local procedure SalesOrderPageOpenNew(var SalesOrderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".Activate();
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.OK().Invoke();
    end;

    local procedure SalesOrderPageOpenEdit(SalesOrder: TestPage "Sales Order"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure SalesOrderPageOpenView(SalesOrder: TestPage "Sales Order"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure CreateSegmentHeaderInteraction(var SegmentHeader: Record "Segment Header")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplate.Code);
        SegmentHeader.Modify(true);
    end;

    local procedure CreateSegmentLineWithContact(var SegmentLine: Record "Segment Line"; SegmentHeaderNo: Code[20])
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        if Contact."Phone No." = '' then begin
            Contact.Validate("Phone No.", Format(LibraryRandom.RandInt(10000)));  // Required field - value is not important to test case.
            Contact.Modify(true);
        end;

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeaderNo);
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentWithCampaign(CampaignNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table"; AccountNo: Code[20])
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);

        Contact.SetRange("No.", GetContactBusinessRelation(LinkToTable, AccountNo));
        AddContactsToSegment(Contact, SegmentHeader);

        ModifyCampaignTargetLines(SegmentHeader."No.");
    end;

    local procedure CreateSegmentWithContact(var SegmentHeader: Record "Segment Header"; var Contact: Record Contact) SecondContactSalespersonCode: Code[20]
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SecondContactSalespersonCode := FilterContacts(Contact);
        AddContactsToSegment(Contact, SegmentHeader);
    end;

    local procedure CreateTemporarySegmentLine(var TempSegmentLine: Record "Segment Line" temporary)
    var
        Contact: Record Contact;
    begin
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        Contact.Get(TempSegmentLine."Contact No.");
        TempSegmentLine.Validate("Contact Via", Contact."Phone No.");
        TempSegmentLine.Validate(Description, TempSegmentLine."Contact No.");
        TempSegmentLine.Validate("Salesperson Code", Contact."Salesperson Code");
    end;

    local procedure FilterContacts(var Contact: Record Contact): Code[10]
    var
        Contact2: Record Contact;
    begin
        Contact.SetFilter("Salesperson Code", '<>''''');  // It is necessary to have Sales Person for the test case.
        Contact.FindFirst();
        Contact2.SetFilter("Salesperson Code", '<>%1&<>%2', Contact."Salesperson Code", '');
        Contact2.SetFilter("No.", '<>%1', Contact."No.");
        Contact2.FindFirst();
        Contact.SetRange("No.", Contact."No.", Contact2."No.");
        exit(Contact2."Salesperson Code");
    end;

    local procedure FindCampaign(): Code[20]
    var
        Campaign: Record Campaign;
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        exit(Campaign."No.");
    end;

    local procedure FindSalesOrderLines(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
    end;

    local procedure FindSalespersonPurchaser(): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        exit(SalespersonPurchaser.Code);
    end;

    local procedure FinishMakePhoneCallWizard(var TempSegmentLine: Record "Segment Line" temporary)
    begin
        TempSegmentLine.Modify();
        TempSegmentLine.CheckPhoneCallStatus();
        TempSegmentLine.LogSegLinePhoneCall()
    end;

    local procedure ModifyCampaignTargetLines(SegmentHeaderNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindSet();
        repeat
            SegmentLine.Validate("Campaign Target", true);
            SegmentLine.Modify(true);
        until SegmentLine.Next() = 0;
    end;

    local procedure NextStepMakePhoneCallWizard(var TempSegmentLine: Record "Segment Line" temporary)
    begin
        TempSegmentLine.Modify();
        TempSegmentLine.CheckPhoneCallStatus();
    end;

    local procedure RefineContactsOnSegment(var Contact: Record Contact; SegmentHeader: Record "Segment Header")
    var
        RemoveContactsRefine: Report "Remove Contacts - Refine";
    begin
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        RemoveContactsRefine.SetTableView(SegmentHeader);
        RemoveContactsRefine.SetTableView(Contact);
        RemoveContactsRefine.UseRequestPage(false);
        RemoveContactsRefine.RunModal();
    end;

    local procedure RemoveContactsFromSegment(var Contact: Record Contact; SegmentHeader: Record "Segment Header")
    var
        RemoveContactsReduce: Report "Remove Contacts - Reduce";
    begin
        SegmentHeader.SetRange("No.", SegmentHeader."No.");
        RemoveContactsReduce.SetTableView(SegmentHeader);
        RemoveContactsReduce.SetTableView(Contact);
        RemoveContactsReduce.UseRequestPage(false);
        RemoveContactsReduce.RunModal();
    end;

    local procedure GetContactBusinessRelation(LinkToTable: Enum "Contact Business Relation Link To Table"; AccountNo: Code[20]): Code[20]
    var
        ContBusRelation: Record "Contact Business Relation";
    begin
        ContBusRelation.SetRange("Link to Table", LinkToTable);
        ContBusRelation.SetRange("No.", AccountNo);
        ContBusRelation.FindFirst();
        exit(ContBusRelation."Contact No.");
    end;

    local procedure RunAddContactsWithMailingGroup(SegmentHeader: Record "Segment Header"; ContactMailingGroup: Record "Contact Mailing Group")
    var
        LibraryVariableStorageVariant: Codeunit "Library - Variable Storage";
    begin
        SegmentHeader.SetRecFilter();
        ContactMailingGroup.SetRange("Mailing Group Code", ContactMailingGroup."Mailing Group Code");

        LibraryVariableStorageVariant.Enqueue(SegmentHeader);
        LibraryVariableStorageVariant.Enqueue(ContactMailingGroup);

        Commit();
        LibraryMarketing.RunAddContactsReport(LibraryVariableStorageVariant, true);
    end;

    local procedure UpdateCampaign(Campaign: Record Campaign)
    begin
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        Campaign.Modify(true);
    end;

    local procedure UpdateSalesOrderForCampaign(SalesPrice: Record "Sales Price"; No: Code[20]; CustomerName: Text; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrderPageOpenEdit(SalesOrder, No);
        SalesOrder."Sell-to Customer Name".SetValue(CustomerName);
        SalesOrder."Bill-to Name".SetValue(CustomerName);
        SalesOrder."Currency Code".SetValue(SalesPrice."Currency Code");
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(SalesPrice."Item No.");
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.OK().Invoke();
    end;

    local procedure MockInteractionLogEntry(DocType: Enum "Interaction Log Entry Document Type"; DocNo: Code[20]; ContactNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        SegManagement: Codeunit SegManagement;
    begin
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(InteractionLogEntry, InteractionLogEntry.FieldNo("Entry No."));
        InteractionLogEntry."Contact No." := ContactNo;
        InteractionLogEntry."Document Type" := DocType;
        InteractionLogEntry."Document No." := DocNo;
        InteractionTemplate.Get(SegManagement.FindInteractionTemplateCode(DocType));
        InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;
        InteractionLogEntry."Interaction Group Code" := InteractionTemplate."Interaction Group Code";
        InteractionLogEntry.Insert();
    end;

    local procedure VerifyCampaignEntry(InteractionTemplate: Record "Interaction Template"; CampaignNo: Code[20])
    var
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.SetRange("Campaign No.", CampaignNo);
        CampaignEntry.FindFirst();
        CampaignEntry.CalcFields("No. of Interactions", "Cost (LCY)", "Duration (Min.)");
        CampaignEntry.TestField("No. of Interactions", 1);  // Number of interactions should be only 1.
        CampaignEntry.TestField("Cost (LCY)", InteractionTemplate."Unit Cost (LCY)");
        CampaignEntry.TestField("Duration (Min.)", InteractionTemplate."Unit Duration (Min.)");
    end;

    local procedure VerifyCampaignWithDetails(CampaignNo: Code[20]; SalespersonCode: Code[20]; StatusCode: Code[10])
    var
        CampaignCard: TestPage "Campaign Card";
    begin
        CampaignCard.OpenView();
        CampaignCard.FILTER.SetFilter("No.", CampaignNo);
        CampaignCard."Salesperson Code".AssertEquals(SalespersonCode);
        CampaignCard."Starting Date".AssertEquals(WorkDate());
        CampaignCard."Ending Date".AssertEquals(WorkDate());
        CampaignCard."Status Code".AssertEquals(StatusCode);
        CampaignCard."Last Date Modified".AssertEquals(Today);
    end;

    local procedure VerifyContactAddedSegmentLine(Contact: Record Contact; SegmentHeaderNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindFirst();
        SegmentLine.TestField("Contact No.", Contact."No.");
        SegmentLine.TestField("Salesperson Code", Contact."Salesperson Code");
        SegmentLine.TestField("Correspondence Type", Contact."Correspondence Type");
    end;

    local procedure VerifyInteractionLogEntry(InteractionTemplate: Record "Interaction Template"; ContactNo: Code[20]; CampaignNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField("Information Flow", InteractionTemplate."Information Flow");
        InteractionLogEntry.TestField("Initiated By", InteractionTemplate."Initiated By");
        InteractionLogEntry.TestField("Interaction Group Code", InteractionTemplate."Interaction Group Code");
        InteractionLogEntry.TestField("Interaction Template Code", InteractionTemplate.Code);
        InteractionLogEntry.TestField("Attachment No.", InteractionTemplate."Attachment No.");
        InteractionLogEntry.TestField("Campaign No.", CampaignNo);
        InteractionLogEntry.TestField("Cost (LCY)", InteractionTemplate."Unit Cost (LCY)");
        InteractionLogEntry.TestField("Duration (Min.)", InteractionTemplate."Unit Duration (Min.)");
    end;

    local procedure VerifyInteractionTemplate(SegmentHeader: Record "Segment Header")
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.FindSet();
        repeat
            SegmentLine.TestField("Interaction Template Code", SegmentHeader."Interaction Template Code");
        until SegmentLine.Next() = 0;
    end;

    local procedure VerifyNeutralInteractionLog(SegmentHeaderNo: Code[20]; AttemptFailed: Boolean)
    var
        SegmentLine: Record "Segment Line";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindFirst();
        InteractionLogEntry.SetRange("Contact No.", SegmentLine."Contact No.");
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField(Evaluation, InteractionLogEntry.Evaluation::Neutral);
        InteractionLogEntry.TestField("Attempt Failed", AttemptFailed);
    end;

    local procedure VerifyPositiveInteractionLog(SegmentHeaderNo: Code[20]; OpportunityNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindFirst();
        InteractionLogEntry.SetRange("Contact No.", SegmentLine."Contact No.");
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField(Evaluation, InteractionLogEntry.Evaluation::"Very Positive");
        InteractionLogEntry.TestField("Opportunity No.", OpportunityNo);
        InteractionLogEntry.TestField("Attempt Failed", false);
    end;

    local procedure VerifyPriceDiscountsActivated(SalesPrice: Record "Sales Price"; SalesLineDiscount: Record "Sales Line Discount"; SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        FindSalesOrderLines(SalesLine, SalesHeaderNo);
        repeat
            if SalesLine.Quantity < SalesPrice."Minimum Quantity" then begin
                Item.Get(SalesLine."No.");
                SalesLine.TestField("Unit Price", Item."Unit Price");
                SalesLine.TestField("Line Discount %", 0);
            end;
            if (SalesLine.Quantity >= SalesPrice."Minimum Quantity") and (SalesLine.Quantity < SalesLineDiscount."Minimum Quantity")
            then begin
                SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
                SalesLine.TestField("Line Discount %", 0);
            end;
            if SalesLine.Quantity >= SalesLineDiscount."Minimum Quantity" then begin
                SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
                SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
            end;
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPriceDiscountDeactivated(SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        FindSalesOrderLines(SalesLine, SalesHeaderNo);
        repeat
            Item.Get(SalesLine."No.");
            SalesLine.TestField("Unit Price", Item."Unit Price");
            SalesLine.TestField("Line Discount %", 0);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalespersonCampaignLines(SegmentHeader: Record "Segment Header")
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.FindSet();
        repeat
            SegmentLine.TestField("Salesperson Code", SegmentHeader."Salesperson Code");
            SegmentLine.TestField("Campaign No.", SegmentHeader."Campaign No.");
        until SegmentLine.Next() = 0;
    end;

    local procedure VerifySaveCriteriaAndReuse(SegmentHeaderNo: Code[20]; SegmentHeaderNo3: Code[20])
    var
        SegmentLine: Record "Segment Line";
        SegmentLine2: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindSet();
        repeat
            SegmentLine2.Get(SegmentHeaderNo3, SegmentLine."Line No.");  // Line Nos. are same for both set of Segment Lines.
            SegmentLine2.TestField("Interaction Template Code", SegmentLine."Interaction Template Code");
            SegmentLine2.TestField("Contact No.", SegmentLine."Contact No.");
        until SegmentLine.Next() = 0;
    end;

    local procedure VerifyPriceDiscountActivation(SalesOrderNo: Code[20]; UnitPrice: Decimal; LineDiscountPct: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrderPageOpenView(SalesOrder, SalesOrderNo);
        SalesOrder.SalesLines."Unit Price".AssertEquals(UnitPrice);
        SalesOrder.SalesLines."Line Discount %".AssertEquals(LineDiscountPct);
    end;

    local procedure VerifyPriceDiscountDeactivate(SalesOrderNo: Code[20])
    var
        Item: Record Item;
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrderPageOpenView(SalesOrder, SalesOrderNo);
        Item.Get(SalesOrder.SalesLines."No.".Value);
        SalesOrder.SalesLines."Unit Price".AssertEquals(Item."Unit Price");
        SalesOrder.SalesLines."Line Discount %".AssertEquals(0);
    end;

    local procedure VerifyCampaignEntryExist(CampaignNo: Code[20])
    var
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.SetRange("Campaign No.", CampaignNo);
        Assert.RecordIsNotEmpty(CampaignEntry);
    end;

    local procedure VerifyCampaignEntryDoesNotExist(CampaignNo: Code[20])
    var
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.SetRange("Campaign No.", CampaignNo);
        Assert.RecordIsEmpty(CampaignEntry);
    end;

    local procedure VerifySegmentLinesPerContact(SegmentHeader: Record "Segment Header"; var Contact: array[3] of Record Contact; ExpectedCount: Integer; StartIndex: Integer)
    var
        SegmentLine: Record "Segment Line";
        Index: Integer;
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");

        for Index := StartIndex to ArrayLen(Contact) do begin
            SegmentLine.SetRange("Contact No.", Contact[Index]."No.");
            Assert.RecordIsNotEmpty(SegmentLine);
        end;

        SegmentLine.SetRange("Contact No.");
        Assert.RecordCount(SegmentLine, ExpectedCount);
    end;

    local procedure VerifyCampaignTargetGroupExists(Type: Option; ContactCompanyNo: Code[20]; CampaignNo: Code[20])
    var
        CampaignTargetGr: Record "Campaign Target Group";
    begin
        CampaignTargetGr.SetRange(Type, Type);
        CampaignTargetGr.SetRange("No.", ContactCompanyNo);
        CampaignTargetGr.SetRange("Campaign No.", CampaignNo);
        Assert.RecordIsNotEmpty(CampaignTargetGr);
    end;

    local procedure CreateSegmentLineWithContCampaign(var SegmentLine: Record "Segment Line"; ContactNo: Code[20]; CampaignNo: Code[20])
    begin
        LibraryMarketing.CreateSegmentLine(SegmentLine, '');
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine."Campaign No." := CampaignNo;
        SegmentLine."Campaign Target" := true;
        SegmentLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AttemptFailedModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        CreateTemporarySegmentLine(TempSegmentLine);
        NextStepMakePhoneCallWizard(TempSegmentLine);

        TempSegmentLine.Validate(Evaluation, TempSegmentLine.Evaluation::Neutral);
        TempSegmentLine.Validate("Interaction Successful", false);
        FinishMakePhoneCallWizard(TempSegmentLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CallNeutralModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        CreateTemporarySegmentLine(TempSegmentLine);
        NextStepMakePhoneCallWizard(TempSegmentLine);

        TempSegmentLine.Validate(Evaluation, TempSegmentLine.Evaluation::Neutral);
        FinishMakePhoneCallWizard(TempSegmentLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CallPositiveModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        Opportunity: Record Opportunity;
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        CreateTemporarySegmentLine(TempSegmentLine);
        NextStepMakePhoneCallWizard(TempSegmentLine);

        TempSegmentLine.Validate(Evaluation, TempSegmentLine.Evaluation::"Very Positive");
        NextStepMakePhoneCallWizard(TempSegmentLine);

        Opportunity.SetRange("Contact No.", TempSegmentLine."Contact No.");
        Opportunity.FindFirst();
        TempSegmentLine.Validate("Campaign No.", CampaignNo3);
        TempSegmentLine.Validate("Opportunity No.", Opportunity."No.");
        FinishMakePhoneCallWizard(TempSegmentLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractModalFormHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        TempSegmentLine.Validate("Interaction Template Code", InteractionTemplateCode);
        TempSegmentLine.Validate(Description, InteractionTemplateCode);
        TempSegmentLine.Validate("Campaign No.", CampaignNo2);
        TempSegmentLine.FinishSegLineWizard(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CriteriaListModalFormHandler(var SavedSegmentCriteriaList: Page "Saved Segment Criteria List"; var Response: Action)
    var
        SavedSegmentCriteria: Record "Saved Segment Criteria";
    begin
        SavedSegmentCriteria.SetRange(Code, InteractionTemplateCode2);
        SavedSegmentCriteria.FindFirst();
        SavedSegmentCriteriaList.SetRecord(SavedSegmentCriteria);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DescriptionModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        Contact: Record Contact;
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        Contact.Get(TempSegmentLine."Contact No.");
        TempSegmentLine.Validate("Contact Via", Contact."Phone No.");
        TempSegmentLine.Description := '';
        TempSegmentLine.Modify();
        TempSegmentLine.CheckPhoneCallStatus();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NumberErrorModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        TempSegmentLine.Validate("Contact Via", '');  // Validate Contact Via as blank to generate error.
        TempSegmentLine.Modify();
        TempSegmentLine.CheckPhoneCallStatus();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SaveSegmentModalFormHandler(var SaveSegmentCriteria: Page "Save Segment Criteria"; var Response: Action)
    var
        SavedSegmentCriteria: Record "Saved Segment Criteria";
        SegmentCriteriaLine: Record "Segment Criteria Line";
        SavedSegmentCriteriaLine: Record "Saved Segment Criteria Line";
    begin
        SavedSegmentCriteria.Init();
        SavedSegmentCriteria.Validate(Code, InteractionTemplateCode2);
        SavedSegmentCriteria.Insert(true);

        SegmentCriteriaLine.SetRange("Segment No.", SegmentHeaderNo2);
        SegmentCriteriaLine.FindSet();
        repeat
            SavedSegmentCriteriaLine.Init();
            SavedSegmentCriteriaLine.Validate("Segment Criteria Code", SavedSegmentCriteria.Code);
            SavedSegmentCriteriaLine.Validate("Line No.", SegmentCriteriaLine."Line No.");
            SavedSegmentCriteriaLine.Validate(Action, SegmentCriteriaLine.Action);
            SavedSegmentCriteriaLine.Validate(Type, SegmentCriteriaLine.Type);
            SavedSegmentCriteriaLine.Validate("Table No.", SegmentCriteriaLine."Table No.");
            SavedSegmentCriteriaLine.Validate("Table View", SegmentCriteriaLine."Table View");
            SavedSegmentCriteriaLine.Validate("Allow Existing Contacts", SegmentCriteriaLine."Allow Existing Contacts");
            SavedSegmentCriteriaLine.Validate("Expand Contact", SegmentCriteriaLine."Expand Contact");
            SavedSegmentCriteriaLine.Validate("Allow Company with Persons", SegmentCriteriaLine."Allow Company with Persons");
            SavedSegmentCriteriaLine.Validate("Ignore Exclusion", SegmentCriteriaLine."Ignore Exclusion");
            SavedSegmentCriteriaLine.Validate("Entire Companies", SegmentCriteriaLine."Entire Companies");
            SavedSegmentCriteriaLine.Validate("No. of Filters", SegmentCriteriaLine."No. of Filters");
            SavedSegmentCriteriaLine.Insert(true);
        until SegmentCriteriaLine.Next() = 0;
        Response := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CallVeryPositiveModalFormHandler(var MakePhoneCall: Page "Make Phone Call"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        OpportunityNo: Code[20];
    begin
        MakePhoneCall.GetRecord(TempSegmentLine);
        CreateTemporarySegmentLine(TempSegmentLine);
        NextStepMakePhoneCallWizard(TempSegmentLine);

        TempSegmentLine.Validate(Evaluation, TempSegmentLine.Evaluation::"Very Positive");
        NextStepMakePhoneCallWizard(TempSegmentLine);

        OpportunityNo := TempSegmentLine.CreateOpportunity();
        LibraryVariableStorage.Enqueue(OpportunityNo);

        TempSegmentLine.Validate("Opportunity No.", OpportunityNo);
        FinishMakePhoneCallWizard(TempSegmentLine);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddContactsRequestPageHandler(var AddContacts: TestRequestPage "Add Contacts")
    begin
        AddContacts.AllowRelatedCompaines.SetValue(LibraryVariableStorage.DequeueBoolean());
        AddContacts.OK().Invoke();
    end;
}
