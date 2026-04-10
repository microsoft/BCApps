codeunit 136214 "Marketing Campaign Pricing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Campaign] [Marketing]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        SalesPriceConfirmMessage: Label 'There are no Sales Prices or Sales Line Discounts currently linked to this %1. Do you still want to activate?';
        SalesPriceError: Label 'To activate the sales prices and/or line discounts, you must apply the relevant Segment Line(s) to the Campaign and place a check mark in the Campaign Target field on the Segment Line.';
        CampaignActivatedMessage: Label 'Campaign %1 is now activated.';
        PriceDateChangeError: Label 'If Sales Type = Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';
        DiscountDateChangeError: Label 'You can only change the Starting Date and Ending Date from the Campaign Card when Sales Type = Campaign';
        CustomerCreationMessage: Label 'The %1 record has been created.', Comment = 'The Customer record has been created.';
        ValueMustNotMatch: Label 'Value must not match.';
        ValueMustMatch: Label 'Value must match.';
        FeatureIsOnErr: Label 'This page is no longer available. It was used by a feature that has been replaced or removed.';

    [Test]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceDateChangeError()
    var
        Campaign: Record Campaign;
        SalesPrice: Record "Sales Price";
    begin
        // Verify error when change the date on Campaign Sales Prices.

        // Setup: Create Campaign with Sales Price.
        Initialize();
        CreateAndUpdateCampaign(Campaign);
        LibraryMarketing.CreateSalesPriceForCampaign(SalesPrice, CreateItem(), Campaign."No.");

        // Exercise.
        asserterror ChangeDateOnSalesPricePage(Campaign."No.");

        // Verify: Verify error when change date on Campaign Sales Prices.
        Assert.ExpectedError(PriceDateChangeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CampaignSalesLineDiscountDateChangeError()
    var
        Campaign: Record Campaign;
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify error when change the date on Campaign Sales Line Discounts.

        // Setup: Create Campaign with Sales Line Discount.
        Initialize();
        CreateAndUpdateCampaign(Campaign);
        LibraryMarketing.CreateSalesLineDiscount(SalesLineDiscount, Campaign."No.", CreateItem());

        // Exercise.
        asserterror ChangeDateOnSalesLineDiscountPage(Campaign."No.");

        // Verify: Verify error when change the date on Campaign Sales Line Discounts.
        Assert.ExpectedError(DiscountDateChangeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDateOnSalesPriceAndLineDiscount()
    var
        Campaign: Record Campaign;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
        CampaignCard: TestPage "Campaign Card";
        SalesPrices: TestPage "Sales Prices";
        SalesLineDiscounts: TestPage "Sales Line Discounts";
    begin
        // Verify dates on Sales Prices and Sales Line Discounts after changing Campaign dates.

        // Setup: Create Campaign with Sales Price and Line Discount.
        Initialize();
        CreateAndUpdateCampaign(Campaign);
        LibraryMarketing.CreateSalesPriceForCampaign(SalesPrice, CreateItem(), Campaign."No.");
        LibraryMarketing.CreateSalesLineDiscount(SalesLineDiscount, Campaign."No.", SalesPrice."Item No.");

        // Exercise.
        ChangeDateOnCampaignCard(CampaignCard, Campaign."No.");

        // Verify: Verify dates on Sales Price and Line Discount.
        SalesPrices.Trap();
        CampaignCard."Sales &Prices".Invoke();
        Assert.AreEqual(CampaignCard."Starting Date".AsDate(), SalesPrices."Starting Date".AsDate(), ValueMustMatch);

        SalesLineDiscounts.Trap();
        CampaignCard."Sales &Line Discounts".Invoke();
        Assert.AreEqual(CampaignCard."Starting Date".AsDate(), SalesLineDiscounts."Starting Date".AsDate(), ValueMustMatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPriceWithSegment()
    var
        Contact: Record Contact;
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // Verify price on Sales Order without activating Campaign while Segment is created for the Campaign.

        // Setup: Create Campaign with Sales Price. Create Contact with Customer and create Segment.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        CreateCustomerForContact(Contact);
        CreateSegment(SalesPrice."Sales Code", Contact."No.");
        CustomerNo := FindContactBusinessRelation(Contact."No.");
        UpdateCustomerPaymentTermsCode(CustomerNo);  // Added fix for G1 Country

        // Exercise.
        CreateSalesOrder(SalesLine, CustomerNo, SalesPrice."Item No.", SalesPrice."Minimum Quantity", SalesPrice."Sales Code");

        // Verify: Verify price on Sales Order.
        Assert.AreNotEqual(SalesPrice."Unit Price", SalesLine."Unit Price", ValueMustNotMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ActivateCampaignWithoutPrice()
    var
        Campaign: Record Campaign;
    begin
        // Verify error when activate Campaign having no price and no Segment.

        // Setup: Create Campaign without Sales Price.
        Initialize();
        CreateAndUpdateCampaign(Campaign);
        LibraryVariableStorage.Enqueue(StrSubstNo(SalesPriceConfirmMessage, Campaign.TableCaption()));  // Enqueue for ConfirmHandler.

        // Exercise.
        asserterror ActivatePriceLineDiscountPage(Campaign."No.");

        // Verify: Verify error when activate Campaign having no price and no Segment.
        Assert.ExpectedError(SalesPriceError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ActivateCampaignWithSegmentAndNoPrice()
    var
        Campaign: Record Campaign;
        Contact: Record Contact;
    begin
        // Verify Campaign is activated without Agreement when create a Segment for the Campaign.

        // Setup: Create Campaign without Sales Price. Create Segment.
        Initialize();
        CreateAndUpdateCampaign(Campaign);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateSegment(Campaign."No.", Contact."No.");

        // Enqueue for ConfirmHandler and MessageHandler.
        LibraryVariableStorage.Enqueue(StrSubstNo(SalesPriceConfirmMessage, Campaign.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, Campaign."No."));

        // Exercise.
        ActivatePriceLineDiscountPage(Campaign."No.");

        // Verify: Verification is done in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ActivateCampaignWithLog()
    begin
        // Verify Sales Order when Campaign is activated with a logged Segment and Campaign Target is True.
        ActivateCampaignFollowUpSeg(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActivateCampaignWithLogAndCampaignTargetFalse()
    var
        Contact: Record Contact;
        SalesPrice: Record "Sales Price";
    begin
        // Verify error when activate Campaign with logged Segment and Campaign Target is False.

        // Setup: Create Campaign with Sales Price. Create Contact. Create a logged Segment.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateLoggedSegment(SalesPrice."Sales Code", Contact."No.", false, false);

        // Exercise.
        asserterror ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        // Verify: Verify error when activate Campaign with logged Segment and Campaign Target is False.
        Assert.ExpectedError(SalesPriceError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ActivateCampaignWithLogWithFollowUpSeg()
    begin
        // Verify Sales Order Price when Campaign is activated with a logged Segment and Follow-up Segment is True.
        ActivateCampaignFollowUpSeg(true);
    end;

    local procedure ActivateCampaignFollowUpSeg(FollowUpSeg: Boolean)
    var
        Contact: Record Contact;
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // Setup: Create Campaign with Sales Price. Create Contact with Customer. Create a logged Segment. Activate Campaign Price.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        CreateCustomerForContact(Contact);
        CreateLoggedSegment(SalesPrice."Sales Code", Contact."No.", true, FollowUpSeg);
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, SalesPrice."Sales Code"));  // Enqueue for MessageHandler.
        ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        CustomerNo := FindContactBusinessRelation(Contact."No.");
        UpdateCustomerPaymentTermsCode(CustomerNo);  // Added fix for G1 Country

        // Exercise: Create Sales Order.
        CopyAllSalesPriceToPriceListLine();
        CreateSalesOrder(SalesLine, CustomerNo, SalesPrice."Item No.", SalesPrice."Minimum Quantity", SalesPrice."Sales Code");

        // Verify: Verify price on Sales Order.
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    local procedure CopyAllSalesPriceToPriceListLine()
    var
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
    begin
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPriceDeleteContactFromSeg()
    var
        SalesPrice: Record "Sales Price";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order Price after deleting Contact from Segment.

        // Setup & Exercise: Create Campaign with Sales Price.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        SalesOrderAfterRemovingContactFromSegment(SalesLine, SalesPrice."Sales Code", SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // Verify: Verify price on Sales Order.
        Assert.AreNotEqual(SalesPrice."Unit Price", SalesLine."Unit Price", ValueMustNotMatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderDiscountDeleteContactFromSeg()
    var
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Sales Order Line Discount after deleting Customer for Contact.

        // Setup & Exercise: Create Campaign and Sales Line Discount.
        Initialize();
        CreateSalesLineDiscountForCampaign(SalesLineDiscount);
        SalesOrderAfterRemovingContactFromSegment(
          SalesLine, SalesLineDiscount."Sales Code", SalesLineDiscount.Code, SalesLineDiscount."Minimum Quantity");

        // Verify: Verify Line Discount on Sales Order.
        Assert.AreNotEqual(SalesLine."Line Discount %", SalesLineDiscount."Line Discount %", ValueMustNotMatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPriceAddNewContactToSeg()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        SegmentNo: Code[20];
    begin
        // Verify Sales Order Price after deleting existing Contact from Segment and adding a new Contact.

        // Setup: Create Campaign with Sales Price. Create Contact with Customer and create Segment. Activate Campaign.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        CreateCustomerForContact(Contact);
        SegmentNo := CreateSegment(SalesPrice."Sales Code", Contact."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, SalesPrice."Sales Code"));  // Enqueue for MessageHandler.
        ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        // Remove Contact from Segment. Create and add new Contact to Segment.
        RemoveContactFromSegment(Contact."No.", SegmentNo);
        CreateCustomerForContact(Contact2);
        AddContactsToSegment(Contact2."No.", SegmentNo);

        // Exercise: Create Sales Orders for both Contacts.
        CreateSalesOrder(
          SalesLine, FindContactBusinessRelation(Contact."No."), SalesPrice."Item No.", SalesPrice."Minimum Quantity",
          SalesPrice."Sales Code");
        CreateSalesOrder(
          SalesLine2, FindContactBusinessRelation(Contact2."No."), SalesPrice."Item No.", SalesPrice."Minimum Quantity",
          SalesPrice."Sales Code");

        // Verify: Verify price on Sales Orders.
        Assert.AreNotEqual(SalesPrice."Unit Price", SalesLine."Unit Price", ValueMustNotMatch);
        Assert.AreNotEqual(SalesPrice."Unit Price", SalesLine2."Unit Price", ValueMustNotMatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesPriceWorksheet()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        LibraryCosting: Codeunit "Library - Costing";
    begin
        // Verify price after suggesting Sales Price on Sales Price Worksheet.

        // Setup: Create Campaign and Sales Line Discount. Create Contact with Customer and create Segment. Activate Campaign
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        Item.Get(SalesPrice."Item No.");

        // Exercise: Suggest Sales Price on Worksheet.
        LibraryCosting.SuggestSalesPriceWorksheet(Item, SalesPrice."Sales Code", SalesPrice."Sales Type", 0, 1);  // Use 0 for PriceLowerLimit  and 1 for UnitPriceFactor.

        // Verify: Verify Sales Price Worksheet for suggested prices.
        VerifySalesPriceWksht(SalesPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,GetSalesPricePageHandler')]
    [Scope('OnPrem')]
    procedure GetPriceOnSalesLine()
    var
        Contact: Record Contact;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
    begin
        // Verify price after using Get Price on Sales Line.

        // Setup: Create Campaign and Sales Line Discount. Create Contact with Customer and create Segment. Activate Campaign.
        Initialize();
        CreateSalesPriceForCampaign(SalesPrice);
        CreateCustomerForContact(Contact);
        CreateSegment(SalesPrice."Sales Code", Contact."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, SalesPrice."Sales Code"));  // Enqueue for MessageHandler.
        ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        // Create Sales Order.
        CreateSalesOrder(
          SalesLine, FindContactBusinessRelation(Contact."No."), SalesPrice."Item No.", SalesPrice."Minimum Quantity",
          SalesPrice."Sales Code");
        LibraryVariableStorage.Enqueue(SalesPrice."Unit Price");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Get Sales Price on Sales Line.
        Clear(SalesPriceCalcMgt);
        SalesPriceCalcMgt.GetSalesLinePrice(SalesHeader, SalesLine);

        // Verify: Verify prices on Get Sales Price Page in GetSalesPricePageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPricesItemNoCanBeValidatedInCaseOfBlankedItemFilter()
    var
        SalesPrices: TestPage "Sales Prices";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales Price] [UI]
        // [SCENARIO 253682] "Item No" can be validated on page 7002 "Sales Prices" in case of blanked "Item No. Filter" field value.
        // [SCENARIO 256758] "Item No" has filter value and can be validated on page 7002 "Sales Prices" in case of "Item No. Filter" field value (TFS 256758).
        Initialize();

        // [GIVEN] Page 7002 "Sales Prices"
        SalesPrices.OpenEdit();
        SalesPrices.New();
        // [GIVEN] Set "Item No. Filter" = 1000
        ItemNo := CreateItem();
        SalesPrices.ItemNoFilterCtrl.SetValue(ItemNo);
        // [GIVEN] "Item No." = 1000 (editable)
        Assert.IsTrue(SalesPrices."Item No.".Editable(), ''); // (TFS 256758)
        SalesPrices."Item No.".AssertEquals(ItemNo);
        // [GIVEN] Set "Item No. Filter" = ''
        SalesPrices.ItemNoFilterCtrl.SetValue('');

        // [WHEN] Validate "Item No." = 1000
        ItemNo := CreateItem();
        SalesPrices."Item No.".SetValue(ItemNo);

        // [THEN] "Item No." = 1000 (editable)
        Assert.IsTrue(SalesPrices."Item No.".Editable(), '');
        SalesPrices."Item No.".AssertEquals(ItemNo);
        SalesPrices.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ActivatedCampaignSalesPriceForCompanyContactAndCustomer()
    var
        Campaign: Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        // [FEATURE] [Sales Prices] [UT]
        // [SCENARIO] Sales Price exists in customer's "Special Prices & Discounts" for Sales Price->Campaign (activated)->Segment->Contact (Company)->Customer
        Initialize();

        // [GIVEN] Company contact "Cont1" related to customer "Cust1"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Campcaign "Camp1" and Sales Price "SP1" for "Camp1"
        CreateSalesPriceForCampaign(SalesPrice);
        // [GIVEN] Segment with "Cont1" contact
        CreateSegment(SalesPrice."Sales Code", Contact."No.");
        // [GIVEN] Activated "Camp1" campaign
        Campaign.Get(SalesPrice."Sales Code");
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, SalesPrice."Sales Code"));
        ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        // [WHEN] Load sales prices for "Cust1" in a buffer
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        // [THEN] Sales Price buffer contains "SP1" for "Cust1"
        VerifySalesPriceBuffer(TempSalesPriceAndLineDiscBuff, SalesPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ActivatedCampaignSalesPriceForPersonContactAndCustomer()
    var
        Campaign: Record Campaign;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        // [FEATURE] [Sales Prices] [UT]
        // [SCENARIO] Sales Price exists in customer's "Special Prices & Discounts" for Sales Price->Campaign (activated)->Segment->Contact (Person)->Contact (Company)->Customer
        Initialize();

        // [GIVEN] Company contact "Cont1" related to customer "Cust1"
        LibraryMarketing.CreateContactWithCustomer(CompanyContact, Customer);
        // [GIVEN] Person contact "Cont2" related to "Cont1"
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify(true);
        // [GIVEN] Campcaign "Camp1" and Sales Price "SP1" for "Camp1"
        CreateSalesPriceForCampaign(SalesPrice);
        // [GIVEN] Segment with "Cont2" contact
        CreateSegment(SalesPrice."Sales Code", PersonContact."No.");
        // [GIVEN] Activated "Camp1" campaign
        Campaign.Get(SalesPrice."Sales Code");
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, SalesPrice."Sales Code"));
        ActivatePriceLineDiscountPage(SalesPrice."Sales Code");

        // [WHEN] Load sales prices for "Cust1" in a buffer
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        // [THEN] Sales Price buffer contains "SP1" for "Cust1"
        VerifySalesPriceBuffer(TempSalesPriceAndLineDiscBuff, SalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPricesStartingDateIsEditableWithStartingDateFilterIsSet()
    var
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEATURE] [Sales Price] [UI]
        // [SCENARIO 261907] "Starting Date" value can be set for a new record on the page "Sales Prices" if "Starting Date Filter" page field is set.
        Initialize();

        // [GIVEN] Page 7002 "Sales Prices".
        SalesPrices.OpenEdit();
        SalesPrices.New();

        // [WHEN] Set "Starting Date Filter" = D1.
        SalesPrices.StartingDateFilter.SetValue(LibraryRandom.RandDate(100));

        // [THEN] "Starting Date" field is editable.
        Assert.IsTrue(SalesPrices."Starting Date".Editable(), '');
    end;

    [Test]
    procedure CannotOpenSalesPriceWorksheetIfNewPricingIsOn()
    begin
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        asserterror Page.Run(Page::"Sales Price Worksheet");
        Assert.ExpectedError(FeatureIsOnErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Campaign Pricing");
        LibraryVariableStorage.Clear();
        PriceListLine.DeleteAll();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Campaign Pricing");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Campaign Pricing");
    end;

    local procedure ActivatePriceLineDiscountPage(No: Code[20])
    var
        CampaignCard: TestPage "Campaign Card";
    begin
        CampaignCard.OpenView();
        CampaignCard.FILTER.SetFilter("No.", No);
        CampaignCard.ActivateSalesPricesLineDisc.Invoke();
    end;

    local procedure AddContactsToSegment(ContactNo: Code[20]; SegmentNo: Code[20])
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        LibraryVariableStorageVariant: Codeunit "Library - Variable Storage";
    begin
        Contact.SetRange("No.", ContactNo);
        SegmentHeader.SetRange("No.", SegmentNo);

        LibraryVariableStorageVariant.Enqueue(Contact);
        LibraryVariableStorageVariant.Enqueue(SegmentHeader);

        LibraryMarketing.RunAddContactsReport(LibraryVariableStorageVariant, false);
    end;

    local procedure ChangeDateOnSalesPricePage(CampaignNo: Code[20])
    var
        SalesPrices: TestPage "Sales Prices";
    begin
        SalesPrices.OpenEdit();
        SalesPrices.FILTER.SetFilter("Sales Type", SalesPrices."Sales Type".GetOption(4));  // Take Index 4 for Campaign option.
        SalesPrices.FILTER.SetFilter("Sales Code", CampaignNo);
        SalesPrices."Starting Date".SetValue(CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use RandInt to change Date.
    end;

    local procedure ChangeDateOnSalesLineDiscountPage(CampaignNo: Code[20])
    var
        SalesLineDiscounts: TestPage "Sales Line Discounts";
    begin
        SalesLineDiscounts.OpenEdit();
        SalesLineDiscounts.FILTER.SetFilter("Sales Type", SalesLineDiscounts."Sales Type".GetOption(4));  // Take Index 4 for Campaign option.
        SalesLineDiscounts.FILTER.SetFilter("Sales Code", CampaignNo);
        SalesLineDiscounts."Starting Date".SetValue(CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use RandInt to change Date.
    end;

    local procedure ChangeDateOnCampaignCard(var CampaignCard: TestPage "Campaign Card"; CampaignNo: Code[20])
    begin
        CampaignCard.OpenEdit();
        CampaignCard.FILTER.SetFilter("No.", CampaignNo);
        CampaignCard."Starting Date".SetValue(CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use RandInt to change Date.
    end;

    local procedure CreateAndUpdateCampaign(var Campaign: Record Campaign)
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use RandInt to validate Date.
        Campaign.Modify(true);
    end;

    local procedure CreateCustomerForContact(var Contact: Record Contact)
    var
        Customer: Record Customer;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(StrSubstNo(CustomerCreationMessage, Customer.TableCaption()));  // Enqueue for MessageHandler.
        Contact.CreateCustomerFromTemplate(GetCustomerTemplateCode());
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateLogForSegment(SegmentNo: Code[20]; FollowUp: Boolean)
    var
        LogSegment: Report "Log Segment";
    begin
        LogSegment.SetSegmentNo(SegmentNo);
        LogSegment.InitializeRequest(false, FollowUp);
        LogSegment.UseRequestPage(false);
        LogSegment.Run();
    end;
    local procedure CreateLoggedSegment(CampaignNo: Code[20]; ContactNo: Code[20]; CampaignTarget: Boolean; FollowUp: Boolean)
    var
        SegmentNo: Code[20];
    begin
        SegmentNo := CreateSegment(CampaignNo, ContactNo);
        UpdateSegmentWithInteractionTemplate(SegmentNo, CampaignTarget);
        CreateLogForSegment(SegmentNo, FollowUp);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; CampaignNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Campaign No.", CampaignNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesPriceForCampaign(var SalesPrice: Record "Sales Price")
    var
        Campaign: Record Campaign;
        Item: Record Item;
    begin
        // Create Campaign and Sales Price for it.
        CreateAndUpdateCampaign(Campaign);
        Item.Get(CreateItem());
        LibraryMarketing.CreateSalesPriceForCampaign(SalesPrice, Item."No.", Campaign."No.");
        SalesPrice.Rename(
          SalesPrice."Item No.", SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice."Starting Date", SalesPrice."Currency Code",
          SalesPrice."Variant Code", Item."Base Unit of Measure",
          LibraryRandom.RandDec(50, 2));  // Use Random value for Minimum Quantity.
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Random value for Unit Price.
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesLineDiscountForCampaign(var SalesLineDiscount: Record "Sales Line Discount")
    var
        Campaign: Record Campaign;
    begin
        // Create Campaign and Sales Line Discount for it.
        CreateAndUpdateCampaign(Campaign);
        LibraryMarketing.CreateSalesLineDiscount(SalesLineDiscount, Campaign."No.", CreateItem());
        SalesLineDiscount.Rename(
          SalesLineDiscount.Type, SalesLineDiscount.Code, SalesLineDiscount."Sales Type", SalesLineDiscount."Sales Code",
          SalesLineDiscount."Starting Date", SalesLineDiscount."Currency Code", SalesLineDiscount."Variant Code",
          SalesLineDiscount."Unit of Measure Code", LibraryRandom.RandDec(50, 2));  // Use Random value for Minimum Quantity.
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(99, 2));  // Any Random percentage between 1 and 99.
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateSegment(CampaignNo: Code[20]; ContactNo: Code[20]): Code[20]
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Validate("Campaign Target", true);
        SegmentHeader.Modify(true);

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Modify(true);
        exit(SegmentHeader."No.");
    end;

    local procedure GetCustomerTemplateCode(): Code[20]
    var
        CustomerTemplate: Record "Customer Templ.";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CustomerTemplate.SetRange("Currency Code", '');
        CustomerTemplate.FindFirst();
        if CustomerTemplate."VAT Bus. Posting Group" = '' then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            CustomerTemplate.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            CustomerTemplate.Modify(true);
        end;
        exit(CustomerTemplate.Code);
    end;

    local procedure FindContactBusinessRelation(ContactNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst();
        UpdateCustomerPaymentTermsCode(ContactBusinessRelation."No.");  // Added fix for G1 Country
        exit(ContactBusinessRelation."No.");
    end;

    local procedure RemoveContactFromSegment(ContactNo: Code[20]; SegmentNo: Code[20])
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        RemoveContactsReduce: Report "Remove Contacts - Reduce";
    begin
        Contact.SetRange("No.", ContactNo);
        SegmentHeader.SetRange("No.", SegmentNo);
        RemoveContactsReduce.SetTableView(SegmentHeader);
        RemoveContactsReduce.SetTableView(Contact);
        RemoveContactsReduce.UseRequestPage(false);
        RemoveContactsReduce.Run();
    end;

    local procedure SalesOrderAfterRemovingContactFromSegment(var SalesLine: Record "Sales Line"; CampaignNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        SegmentNo: Code[20];
    begin
        // Create Contact with Customer and create Segment. Activate Campaign.
        CreateCustomerForContact(Contact);
        SegmentNo := CreateSegment(CampaignNo, Contact."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(CampaignActivatedMessage, CampaignNo));  // Enqueue for MessageHandler.
        ActivatePriceLineDiscountPage(CampaignNo);

        // Create Sales Order. Remove Contact from Segment.
        CreateSalesOrder(SalesLine, FindContactBusinessRelation(Contact."No."), ItemNo, Quantity, CampaignNo);
        RemoveContactFromSegment(Contact."No.", SegmentNo);

        // Exercise: Add a new line to Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure UpdateCustomerPaymentTermsCode(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Customer.Get(CustomerNo);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure UpdateSegmentWithInteractionTemplate(SegmentNo: Code[20]; CampaignTarget: Boolean)
    var
        InteractionTemplate: Record "Interaction Template";
        SegmentHeader: Record "Segment Header";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        SegmentHeader.Get(SegmentNo);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplate.Code);
        SegmentHeader.Validate("Campaign Target", CampaignTarget);
        SegmentHeader.Modify(true);
    end;

    local procedure VerifySalesPriceWksht(SalesPrice: Record "Sales Price")
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.SetRange("Sales Type", SalesPrice."Sales Type");
        SalesPriceWorksheet.SetRange("Sales Code", SalesPrice."Sales Code");
        SalesPriceWorksheet.FindFirst();
        SalesPriceWorksheet.TestField("Item No.", SalesPrice."Item No.");
        SalesPriceWorksheet.TestField("Minimum Quantity", SalesPrice."Minimum Quantity");
        SalesPriceWorksheet.TestField("Current Unit Price", SalesPrice."Unit Price");
    end;

    local procedure VerifySalesPriceBuffer(var SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; SalesPrice: Record "Sales Price")
    begin
        SalesPriceAndLineDiscBuff.SetRange("Sales Type", SalesPrice."Sales Type");
        SalesPriceAndLineDiscBuff.SetRange("Sales Code", SalesPrice."Sales Code");
        SalesPriceAndLineDiscBuff.SetRange("Minimum Quantity", SalesPrice."Minimum Quantity");
        SalesPriceAndLineDiscBuff.SetRange("Unit Price", SalesPrice."Unit Price");
        Assert.RecordIsNotEmpty(SalesPriceAndLineDiscBuff);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesPricePageHandler(var GetSalesPrice: TestPage "Get Sales Price")
    var
        UnitPrice: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitPrice);  // Dequeue Variable.
        Assert.AreEqual(GetSalesPrice."Unit Price".AsDecimal(), UnitPrice, ValueMustMatch);
        GetSalesPrice.OK().Invoke();
    end;
}
