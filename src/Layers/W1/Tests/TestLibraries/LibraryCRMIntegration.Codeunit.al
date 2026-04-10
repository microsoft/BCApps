codeunit 139164 "Library - CRM Integration"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        CRMBusLogicSimulator: Codeunit "CRM Bus. Logic Simulator";
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        LibraryMockCRMConnection: Codeunit "Library - Mock CRM Connection";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        DefaultUoMNameTxt: Label 'BOX';
        TempMappingNotFoundErr: Label 'Temp Table Mapping is not found.';
        CRMTimeDiffSeconds: Integer;

    [Scope('OnPrem')]
    procedure AddCRMCaseToCRMAccount(CRMAccount: Record "CRM Account"): Guid
    var
        CRMIncident: Record "CRM Incident";
    begin
        exit(AddCRMCaseWithStatusToCRMAccount(CRMAccount, CRMIncident.StateCode::Active));
    end;

    [Scope('OnPrem')]
    procedure AddCRMCaseWithStatusToCRMAccount(CRMAccount: Record "CRM Account"; Status: Option): Guid
    var
        CRMIncident: Record "CRM Incident";
    begin
        CRMIncident.Init();
        CRMIncident.CustomerId := CRMAccount.AccountId;
        CRMIncident.Title := 'Test CRM Case';
        CRMIncident.StateCode := Status;
        CRMIncident.Insert();
        exit(CRMIncident.IncidentId);
    end;

    [Scope('OnPrem')]
    procedure AddCRMOpportunityToCRMAccount(CRMAccount: Record "CRM Account"): Guid
    var
        CRMOpportunity: Record "CRM Opportunity";
    begin
        exit(AddCRMOpportunityWithStatusToCRMAccount(CRMAccount, CRMOpportunity.StateCode::Open));
    end;

    [Scope('OnPrem')]
    procedure AddCRMOpportunityWithStatusToCRMAccount(CRMAccount: Record "CRM Account"; Status: Option): Guid
    var
        CRMOpportunity: Record "CRM Opportunity";
    begin
        CRMOpportunity.Init();
        CRMOpportunity.ParentAccountId := CRMAccount.AccountId;
        CRMOpportunity.TotalAmount := 10;
        CRMOpportunity.StateCode := Status;
        CRMOpportunity.Insert(true);
        exit(CRMOpportunity.OpportunityId);
    end;

    [Scope('OnPrem')]
    procedure AddCRMQuoteToCRMAccount(CRMAccount: Record "CRM Account"): Guid
    var
        CRMQuote: Record "CRM Quote";
    begin
        exit(AddCRMQuoteWithStatusToCRMAccount(CRMAccount, CRMQuote.StateCode::Active));
    end;

    [Scope('OnPrem')]
    procedure AddCRMQuoteWithStatusToCRMAccount(CRMAccount: Record "CRM Account"; Status: Option): Guid
    var
        CRMQuote: Record "CRM Quote";
    begin
        CRMQuote.Init();
        CRMQuote.CustomerId := CRMAccount.AccountId;
        CRMQuote.Name := 'Test CRM Quote';
        CRMQuote.StateCode := Status;
        CRMQuote.Insert();
        exit(CRMQuote.QuoteId);
    end;

    [Scope('OnPrem')]
    procedure AddCRMTransactionCurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; ISOName: Text[5])
    begin
        CRMTransactioncurrency.Init();
        CRMTransactioncurrency.TransactionCurrencyId := CreateGuid();
        CRMTransactioncurrency.ISOCurrencyCode := ISOName;
        CRMTransactioncurrency.CurrencyPrecision := 2;
        CRMTransactioncurrency.CurrencyName := ISOName;
        CRMTransactioncurrency.ExchangeRate := 1;
        CRMTransactioncurrency.Insert();
    end;

    [Scope('OnPrem')]
    procedure AssertVisibilityOnHostPage(HostPageName: Option CustomerCard,CustomerList; CustomerNo: Code[20]; IsCRMStatisticsFactBoxVisible: Boolean)
    var
        CustomerCard: TestPage "Customer Card";
        CustomerList: TestPage "Customer List";
    begin
        case HostPageName of
            HostPageName::CustomerCard:
                begin
                    OpenAndFilterCustomerCard(CustomerCard, CustomerNo);
                    Assert.AreEqual(
                      IsCRMStatisticsFactBoxVisible, CustomerCard.Control39.Opportunities.Visible(), 'Incorrect visibility');
                end;
            HostPageName::CustomerList:
                begin
                    OpenAndFilterCustomerList(CustomerList, CustomerNo);
                    Assert.AreEqual(
                      IsCRMStatisticsFactBoxVisible, CustomerList.Control99.Opportunities.Visible(), 'Incorrect visibility');
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ChangeCRMProductFields(var CRMProduct: Record "CRM Product")
    begin
        CRMProduct.PriceLevelId := CreateGuid();
        CRMProduct.DefaultUoMId := CreateGuid();
        CRMProduct.DefaultUoMScheduleId := CreateGuid();
        CRMProduct.Price := LibraryRandom.RandDec(1, 3);
        CRMProduct.TransactionCurrencyId := CreateGuid();
        CRMProduct.ProductNumber := Format(CreateGuid());
        CRMProduct.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledCurrencyAndNotLCYTransactionCurrency(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        CreateCurrency(Currency);
        CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(Currency.Code, 1, 5));
        CoupleRecordIdToCRMId(Currency.RecordId, CRMTransactioncurrency.TransactionCurrencyId);
        Currency.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledCurrencyAndTransactionCurrency(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        CreateCurrency(Currency);
        CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(LibraryERM.GetLCYCode(), 1, 5));
        CoupleRecordIdToCRMId(Currency.RecordId, CRMTransactioncurrency.TransactionCurrencyId);
        Currency.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledCustomerAndAccount(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
    begin
        CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibrarySales.CreateCustomer(Customer);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        CreateCRMAccount(CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Customer.RecordId, CRMAccount.AccountId);
        Customer.Find();
        CouplePaymentTerms(Customer);
        CoupleShippingAgent(Customer);
        CoupleShipmentMethod(Customer);
    end;

    [Scope('OnPrem')]
    procedure CouplePaymentTerms(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        if Customer."Payment Terms Code" <> '' then
            PaymentTerms.Get(Customer."Payment Terms Code")
        else begin
            PaymentTerms.FindFirst();
            Customer."Payment Terms Code" := PaymentTerms.Code;
            Customer.Modify();
        end;

        CRMOptionMapping."Record ID" := PaymentTerms.RecordId;
        CRMOptionMapping."Option Value" := 1;
        CRMOptionMapping."Option Value Caption" := PaymentTerms.Code;
        CRMOptionMapping."Table ID" := Database::"Payment Terms";
        CRMOptionMapping."Integration Table ID" := Database::"CRM Account";
        CRMOptionMapping."Integration Field ID" := CRMAccount.FieldNo(CRMAccount.PaymentTermsCodeEnum);
        if CRMOptionMapping.Insert() then;
    end;

    local procedure CoupleShippingAgent(var Customer: Record Customer)
    var
        ShippingAgent: Record "Shipping Agent";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        if Customer."Shipping Agent Code" <> '' then
            ShippingAgent.Get(Customer."Shipping Agent Code")
        else begin
            if not ShippingAgent.FindFirst() then begin
                ShippingAgent.Init();
                ShippingAgent.Code := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ShippingAgent.Code)), 1, MaxStrLen(ShippingAgent.Code));
                ShippingAgent.Insert();
            end;
            Customer."Shipping Agent Code" := ShippingAgent.Code;
            Customer.Modify();
        end;

        CRMOptionMapping."Record ID" := ShippingAgent.RecordId;
        CRMOptionMapping."Option Value" := 1;
        CRMOptionMapping."Option Value Caption" := ShippingAgent.Code;
        CRMOptionMapping."Table ID" := Database::"Shipping Agent";
        CRMOptionMapping."Integration Table ID" := Database::"CRM Account";
        CRMOptionMapping."Integration Field ID" := CRMAccount.FieldNo(CRMAccount.Address1_ShippingMethodCodeEnum);
        if CRMOptionMapping.Insert() then;
    end;

    local procedure CoupleShipmentMethod(var Customer: Record Customer)
    var
        ShipmentMethod: Record "Shipment Method";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        if Customer."Shipment Method Code" <> '' then
            ShipmentMethod.Get(Customer."Shipping Agent Code")
        else begin
            if not ShipmentMethod.FindFirst() then begin
                ShipmentMethod.Init();
                ShipmentMethod.Code := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ShipmentMethod.Code)), 1, MaxStrLen(ShipmentMethod.Code));
                ShipmentMethod.Insert();
            end;
            Customer."Shipment Method Code" := ShipmentMethod.Code;
            Customer.Modify();
        end;

        CRMOptionMapping."Record ID" := ShipmentMethod.RecordId;
        CRMOptionMapping."Option Value" := 1;
        CRMOptionMapping."Option Value Caption" := ShipmentMethod.Code;
        CRMOptionMapping."Table ID" := Database::"Shipment Method";
        CRMOptionMapping."Integration Table ID" := Database::"CRM Account";
        CRMOptionMapping."Integration Field ID" := CRMAccount.FieldNo(CRMAccount.Address1_FreightTermsCodeEnum);
        if CRMOptionMapping.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledContactAndContact(var Contact: Record Contact; var CRMContact: Record "CRM Contact")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CreateCRMContactWithCoupledOwner(CRMContact);
        CreateContact(Contact);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId, CRMContact.ContactId);
        Contact.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledPriceGroupAndPricelevel(var CustomerPriceGroup: Record "Customer Price Group"; var CRMPricelevel: Record "CRM Pricelevel")
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        // Create the NAV Customer Price Group
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);

        // Create prerequisites: currency
        CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);

        CreateCoupledPriceGroupAndPricelevelWithTransactionCurrency(CustomerPriceGroup, CRMPricelevel, CRMTransactioncurrency);
    end;

    [Scope('OnPrem')]
    procedure CreatePricelevelAndCoupleWithPriceGroup(var CustomerPriceGroup: Record "Customer Price Group"; var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[20])
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        // Get CRM Transaction Currency for the Customer Price Group
        CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(CurrencyCode));

        CreateCoupledPriceGroupAndPricelevelWithTransactionCurrency(CustomerPriceGroup, CRMPricelevel, CRMTransactioncurrency);
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledPriceGroupAndPricelevelWithTransactionCurrency(var CustomerPriceGroup: Record "Customer Price Group"; var CRMPricelevel: Record "CRM Pricelevel"; CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        // Create the CRM Pricelevel
        CreateCRMPriceList(CRMPricelevel, CRMTransactioncurrency);

        // Couple NAV Customer Price Group and CRM Pricelevel
        CoupleRecordIdToCRMId(CustomerPriceGroup.RecordId, CRMPricelevel.PriceLevelId);
        CustomerPriceGroup.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup: Record "Customer Price Group"; var SalesPrice: Record "Sales Price"; var CRMProductpricelevel: Record "CRM Productpricelevel")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProduct: Record "CRM Product";
        Item: Record Item;
    begin
        // requires a coupled CustomerPriceGroup and CRMPricelevel
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', Item."Base Unit of Measure", 0, LibraryRandom.RandDec(1000, 2));
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CreateCRMPricelistLine(CRMProductpricelevel, CRMPricelevel, CRMProduct);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(SalesPrice.RecordId, CRMProductpricelevel.ProductPriceLevelId);
        SalesPrice.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledPriceListHeaderAndPricelevel(var PriceListHeader: Record "Price List Header"; var CRMPricelevel: Record "CRM Pricelevel")
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        // Create prerequisites: currency
        CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // Create the NAV PriceListHeader
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Currency Code" := Currency.Code;
        PriceListHeader.Modify();

        CreateCoupledPriceListHeaderAndPricelevelWithTransactionCurrency(PriceListHeader, CRMPricelevel, CRMTransactioncurrency);
        PriceListHeader.Find();
    end;

    [Scope('OnPrem')]
    procedure CreatePricelevelAndCoupleWithPriceListHeader(var PriceListHeader: Record "Price List Header"; var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[20])
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        // Get CRM Transaction Currency for the PriceListHeader
        CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(CurrencyCode));

        CreateCoupledPriceListHeaderAndPricelevelWithTransactionCurrency(PriceListHeader, CRMPricelevel, CRMTransactioncurrency);
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledPriceListHeaderAndPricelevelWithTransactionCurrency(var PriceListHeader: Record "Price List Header"; var CRMPricelevel: Record "CRM Pricelevel"; CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        // Create the CRM Pricelevel
        CreateCRMPriceList(CRMPricelevel, CRMTransactioncurrency);

        // Couple NAV PriceListHeader and CRM Pricelevel
        CoupleRecordIdToCRMId(PriceListHeader.RecordId, CRMPricelevel.PriceLevelId);
        PriceListHeader.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledPriceListLineAndCRMPricelistLine(PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line"; var CRMProductpricelevel: Record "CRM Productpricelevel")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProduct: Record "CRM Product";
        Item: Record Item;
    begin
        // requires a coupled PriceListHeader and CRMPricelevel
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CreateCoupledItemAndProduct(Item, CRMProduct);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CreateCRMPricelistLine(CRMProductpricelevel, CRMPricelevel, CRMProduct);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(PriceListLine.RecordId, CRMProductpricelevel.ProductPriceLevelId);
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledResourceAndProduct(var Resource: Record Resource; var CRMProduct: Record "CRM Product")
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Resource.Modify();

        CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        CRMProduct.Modify();

        CoupleRecordIdToCRMId(Resource.RecordId, CRMProduct.ProductId);
        Resource.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledItemAndProduct(var Item: Record Item; var CRMProduct: Record "CRM Product")
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify();

        CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);

        CoupleRecordIdToCRMId(Item.RecordId, CRMProduct.ProductId);
        Item.Find();
    end;

    [Scope('OnPrem')]
    procedure CoupleItem(var Item: Record Item; CRMUom: Record "CRM Uom"; var CRMProduct: Record "CRM Product")
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        CoupleRecordIdToCRMId(Item.RecordId, CRMProduct.ProductId);
        Item.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledSalespersonAndSystemUser(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var CRMSystemuser: Record "CRM Systemuser")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateCRMSystemUser(CRMSystemuser);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(SalespersonPurchaser.RecordId, CRMSystemuser.SystemUserId);
        SalesPersonPurchaser.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledUnitOfMeasureAndUomSchedule(var UnitOfMeasure: Record "Unit of Measure"; var CRMUom: Record "CRM Uom"; var CRMUomschedule: Record "CRM Uomschedule")
    begin
        // Create the NAV Unit of Measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // Create the CRM UoM and UoM Schedule
        CRMUom.Name := UnitOfMeasure.Code;
        CreateCRMUomAndUomSchedule(CRMUom, CRMUomschedule);

        // Couple NAV Unit of Measure and CRM UoM Schedule
        CoupleRecordIdToCRMId(UnitOfMeasure.RecordId, CRMUomschedule.UoMScheduleId);
        UnitOfMeasure.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledItemUnitGroupAndUomSchedule(var UnitGroup: Record "Unit Group"; var CRMUomschedule: Record "CRM Uomschedule")
    var
        Item: Record Item;
    begin
        // Create the NAV Item
        LibraryInventory.CreateItem(Item);
        UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId);

        // Create the CRM Uomschedule
        CreateCRMUomschedule(CRMUomschedule, UnitGroup.GetCode());

        // Couple NAV Unit of Measure and CRM UoM Schedule
        CoupleRecordIdToCRMId(UnitGroup.RecordId, CRMUomschedule.UoMScheduleId);
        UnitGroup.Find();
    end;

    [Scope('OnPrem')]
    procedure CoupleItemUnitOfMeasure(ItemUnitOfMeasure: Record "Item Unit of Measure"; CRMUomschedule: Record "CRM Uomschedule"; var CRMUom: Record "CRM Uom")
    begin
        CreateCRMUom(CRMUomschedule, CRMUom, ItemUnitOfMeasure.Code);
        CoupleRecordIdToCRMId(ItemUnitOfMeasure.RecordId, CRMUom.UoMId);
        CRMUom.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledResourceUnitGroupAndUomSchedule(var UnitGroup: Record "Unit Group"; var CRMUomschedule: Record "CRM Uomschedule")
    var
        Resource: Record Resource;
    begin
        // Create the NAV Resource
        LibraryResource.CreateResourceNew(Resource);
        UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId);

        // Create the CRM Uomschedule
        CreateCRMUomschedule(CRMUomschedule, UnitGroup.GetCode());

        // Couple NAV Unit of Measure and CRM UoM Schedule
        CoupleRecordIdToCRMId(UnitGroup.RecordId, CRMUomschedule.UoMScheduleId);
        UnitGroup.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCoupledOpportunityAndOpportunity(var Opportunity: Record Opportunity; var CRMOpportunity: Record "CRM Opportunity")
    begin
        // Create the NAV Opportunity
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreatePersonContactNo());

        // Create the CRM Opportunity
        CreateCRMOpportunity(CRMOpportunity);

        // Couple NAV Opportunity and CRM Opportunity
        CoupleRecordIdToCRMId(Opportunity.RecordId, CRMOpportunity.OpportunityId);
        Opportunity.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateCurrencyCoupledToTransactionBaseCurrency(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField(BaseCurrencyId);
        CRMTransactioncurrency.Get(CRMConnectionSetup.BaseCurrencyId);
        CreateCurrency(Currency);
        CoupleRecordIdToCRMId(Currency.RecordId, CRMTransactioncurrency.TransactionCurrencyId);
        Currency.Find();
    end;

    [Scope('OnPrem')]
    procedure CreateContact(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Type := Contact.Type::Person;
        Contact."First Name" := LibraryUtility.GenerateGUID();
        Contact.Surname := LibraryUtility.GenerateGUID();
        Contact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContactForCustomer(var Contact: Record Contact; Customer: Record Customer)
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("No.", Customer."No.");
        if not ContBusRel.FindFirst() then
            Assert.Fail('Existing customers should have a contact business relationship');

        CreateContact(Contact);
        Contact."Company No." := ContBusRel."Contact No.";
        Contact."Salesperson Code" := Customer."Salesperson Code";
        Contact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMAccount(var CRMAccount: Record "CRM Account")
    var
        CRMSystemuserId: Guid;
    begin
        if IsNullGuid(CRMAccount.OwnerId) then
            CRMSystemuserId := EnsureCRMSystemUser()
        else
            CRMSystemuserId := CRMAccount.OwnerId;

        Clear(CRMAccount);
        CRMAccount.Init();
        CRMAccount.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CRMAccount.Name)), 1, MaxStrLen(CRMAccount.Name));
        CRMAccount.CustomerTypeCode := CRMAccount.CustomerTypeCode::Customer;
        CRMAccount.CreatedBy := CRMSystemuserId;
        CRMAccount.ModifiedBy := CRMSystemuserId;
        CRMAccount.CreatedOn := CurrentCRMDateTime();
        CRMAccount.ModifiedOn := CRMAccount.CreatedOn;
        CRMAccount.OwnerId := CRMSystemuserId;
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::systemuser;
        CRMAccount.TransactionCurrencyId := GetGLSetupCRMTransactionCurrencyID();
        CRMAccount.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMAccountWithCoupledOwner(var CRMAccount: Record "CRM Account")
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        CreateCRMAccount(CRMAccount);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMContact(var CRMContact: Record "CRM Contact")
    var
        CRMSystemuserId: Guid;
    begin
        if IsNullGuid(CRMContact.OwnerId) then
            CRMSystemuserId := EnsureCRMSystemUser()
        else
            CRMSystemuserId := CRMContact.OwnerId;

        Clear(CRMContact);
        CRMContact.Init();
        CRMContact.FullName :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CRMContact.FullName)), 1, MaxStrLen(CRMContact.FullName));
        CRMContact.MobilePhone := LibraryUtility.GenerateRandomPhoneNo();
        CRMContact.CreatedBy := CRMSystemuserId;
        CRMContact.ModifiedBy := CRMSystemuserId;
        CRMContact.CreatedOn := CurrentCRMDateTime();
        CRMContact.ModifiedOn := CRMContact.CreatedOn;
        CRMContact.OwnerId := CRMSystemuserId;
        CRMContact.OwnerIdType := CRMContact.OwnerIdType::systemuser;
        CRMContact.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMContactWithCoupledOwner(var CRMContact: Record "CRM Contact")
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMContact.OwnerId := CRMSystemuser.SystemUserId;
        CreateCRMContact(CRMContact);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMContactWithParentAccount(var CRMContact: Record "CRM Contact"; ParentCRMAccount: Record "CRM Account")
    begin
        CRMContact.OwnerId := ParentCRMAccount.OwnerId;
        CreateCRMContact(CRMContact);
        CRMContact.ParentCustomerId := ParentCRMAccount.AccountId;
        CRMContact.ParentCustomerIdType := CRMContact.ParentCustomerIdType::account;
        Clear(CRMContact.ModifiedBy); // to avoid filter 'ModifiedBy<>IntegrationUserId' in COD5340
        CRMContact.Modify();
    end;

    procedure CreateCoupledSalesHeaderAndSalesorder(var SalesHeader: Record "Sales Header"; var CRMSalesorder: Record "CRM Salesorder")
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        SalesLine: Record "Sales Line";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateCRMSalesOrder(CRMSalesorder);
        CRMSalesorder.OrderNumber := LibraryUtility.GenerateGUID();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::InProgress;
        CRMSalesorder.CustomerId := CRMAccount.AccountId;
        CRMSalesorder.CustomerIdType := CRMSalesorder.CustomerIdType::account;
        CRMSalesorder.Modify();
        CoupleRecordIdToCRMId(SalesHeader.RecordId, CRMSalesorder.SalesOrderId);
        PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", CRMSalesorderdetail.Quantity);
        CoupleRecordIdToCRMId(SalesLine.RecordId, CRMSalesorderdetail.SalesOrderDetailId);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMConnectionSetup(PrimaryKey: Code[10]; HostName: Text; IsEnabledVar: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get(PrimaryKey) then
            CRMConnectionSetup.Delete();
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Primary Key" := PrimaryKey;
        CRMConnectionSetup."Server Address" := CopyStr(HostName, 1, MaxStrLen(CRMConnectionSetup."Server Address"));
        CRMConnectionSetup."Is Enabled" := IsEnabledVar;
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup.Validate("User Name", 'UserName@asEmail.net');
        // Empty username triggers username/password dialog
        CRMConnectionSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMOrganization()
    begin
        CreateCRMOrganizationWithCurrencyPrecision(2);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMOrganizationWithCurrencyPrecision(CurrencyPrecision: Integer)
    var
        CRMOrganization: Record "CRM Organization";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CreateCRMTransactionCurrency(CRMTransactioncurrency, GetBaseCRMTestCurrencySymbol());
        CRMOrganization.Init();
        CRMOrganization.CurrencyDecimalPrecision := CurrencyPrecision;
        CRMOrganization.BaseCurrencyPrecision := CurrencyPrecision;
        CRMOrganization.BaseCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMOrganization.BaseCurrencySymbol := CopyStr(CRMTransactioncurrency.CurrencySymbol, 1, 5);
        CRMOrganization.BaseCurrencyIdName := CRMTransactioncurrency.CurrencyName;
        CRMOrganization.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMProduct(var CRMProduct: Record "CRM Product"; CRMTransactioncurrency: Record "CRM Transactioncurrency"; CRMUom: Record "CRM Uom")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMProduct);
        CRMProduct.Init();
        CRMProduct.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMProduct.DefaultUoMId := CRMUom.UoMId;
        CRMProduct.DefaultUoMScheduleId := CRMUom.UoMScheduleId;
        CRMProduct.PriceLevelId := CreateGuid();
        CRMProduct.ProductId := CreateGuid();
        CRMProduct.Price := LibraryRandom.RandDec(1, 2);
        CRMProduct.ProductNumber := Format(CreateGuid());
        CRMProduct.CreatedBy := CRMSystemuser.SystemUserId;
        CRMProduct.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMProduct.CreatedOn := CurrentCRMDateTime();
        CRMProduct.ModifiedOn := CRMProduct.CreatedOn;
        CRMProduct.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CRMProduct.Name)), 1, MaxStrLen(CRMProduct.Name));
        CRMProduct.StateCode := CRMProduct.StateCode::Active;
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::SalesInventory;
        CRMProduct.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMPriceList(var CRMPricelevel: Record "CRM Pricelevel"; CRMTransactioncurrency: Record "CRM Transactioncurrency")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMPricelevel);
        CRMPricelevel.Init();
        CRMPricelevel.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMPricelevel.OrganizationId := CreateGuid();
        CRMPricelevel.Name := 'Test Price List';
        CRMPricelevel.CreatedBy := CRMSystemuser.SystemUserId;
        CRMPricelevel.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMPricelevel.CreatedOn := CurrentCRMDateTime();
        CRMPricelevel.ModifiedOn := CRMPricelevel.CreatedOn;
        CRMPricelevel.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMPricelistLine(var CRMProductpricelevel: Record "CRM Productpricelevel"; CRMPricelevel: Record "CRM Pricelevel"; CRMProduct: Record "CRM Product")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMProductpricelevel);
        CRMProductpricelevel.ProductPriceLevelId := CreateGuid();
        CRMProductpricelevel.OrganizationId := CRMPricelevel.OrganizationId;
        CRMProductpricelevel.PriceLevelId := CRMPricelevel.PriceLevelId;
        CRMProductpricelevel.TransactionCurrencyId := CRMPricelevel.TransactionCurrencyId;
        CRMProductpricelevel.ProductId := CRMProduct.ProductId;
        CRMProductpricelevel.UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
        CRMProductpricelevel.UoMId := CRMProduct.DefaultUoMId;
        CRMProductpricelevel.PricingMethodCode := CRMProductpricelevel.PricingMethodCode::CurrencyAmount;
        CRMProductpricelevel.Amount := LibraryRandom.RandDec(100, 2);
        CRMProductpricelevel.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMSalesorder);
        CRMSalesorder.Name := 'Test CRM Sales Order';
        CRMSalesorder.Init();
        CRMSalesorder.CreatedBy := CRMSystemuser.SystemUserId;
        CRMSalesorder.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMSalesorder.CreatedOn := CurrentCRMDateTime();
        CRMSalesorder.ModifiedOn := CRMSalesorder.CreatedOn;
        CRMSalesorder.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetCRMSalesOrderDiscount(var CRMSalesorder: Record "CRM Salesorder"; DiscountPercentage: Decimal; DiscountAmount: Decimal)
    begin
        CRMSalesorder.DiscountPercentage := DiscountPercentage;
        CRMSalesorder.DiscountAmount := DiscountAmount;

        CRMSalesorder.TotalAmountLessFreight -= CRMSalesorder.TotalAmountLessFreight * DiscountPercentage / 100;
        CRMSalesorder.TotalAmountLessFreight -= DiscountAmount;

        CRMSalesorder.ModifiedOn := CurrentCRMDateTime();
        CRMSalesorder.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetCRMQuoteDiscount(var CRMQuote: Record "CRM Quote"; DiscountPercentage: Decimal; DiscountAmount: Decimal)
    begin
        CRMQuote.DiscountPercentage := DiscountPercentage;
        CRMQuote.DiscountAmount := DiscountAmount;

        CRMQuote.TotalAmountLessFreight -= CRMQuote.TotalAmountLessFreight * DiscountPercentage / 100;
        CRMQuote.TotalAmountLessFreight -= DiscountAmount;

        CRMQuote.ModifiedOn := CurrentCRMDateTime();
        CRMQuote.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMSalesOrderWithCustomerFCY(var CRMSalesorder: Record "CRM Salesorder"; AccountId: Guid; CurrencyId: Guid)
    begin
        CreateCRMSalesOrder(CRMSalesorder);
        CRMSalesorder.OrderNumber := LibraryUtility.GenerateGUID();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::InProgress;
        Clear(CRMSalesorder.LastBackofficeSubmit);
        CRMSalesorder.CustomerId := AccountId;
        CRMSalesorder.CustomerIdType := CRMSalesorder.CustomerIdType::account;
        CRMSalesorder.TransactionCurrencyId := CurrencyId;
        CRMSalesorder.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMSalesOrderLine(var CRMSalesorder: Record "CRM Salesorder"; var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
    begin
        CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.Modify();
        PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMSalesOrderLineWithResource(var CRMSalesorder: Record "CRM Salesorder"; var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
    begin
        CreateCoupledResourceAndProduct(Resource, CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        CRMProduct.Modify();
        PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);
    end;

    [Scope('OnPrem')]
    procedure PrepareCRMSalesOrderLine(var CRMSalesorder: Record "CRM Salesorder"; var CRMSalesorderdetail: Record "CRM Salesorderdetail"; CRMProductId: Guid)
    begin
        CRMSalesorderdetail.Init();
        CRMSalesorderdetail.SalesOrderId := CRMSalesorder.SalesOrderId;
        CRMSalesorderdetail.LineItemNumber := 1;
        CRMSalesorderdetail.ExchangeRate := 1;
        // LCY
        CRMSalesorderdetail.CreatedBy := CRMSalesorder.CreatedBy;
        CRMSalesorderdetail.CreatedOn := CRMSalesorder.CreatedOn;
        CRMSalesorderdetail.Insert();

        CRMSalesorderdetail.ProductId := CRMProductId;
        CRMSalesorderdetail.Quantity := LibraryRandom.RandIntInRange(10, 20);
        CRMSalesorderdetail.PricePerUnit := LibraryRandom.RandDecInRange(100, 200, 2);
        CRMSalesorderdetail.ModifiedBy := CRMSalesorder.ModifiedBy;
        CRMSalesorderdetail.ModifiedOn := CRMSalesorder.ModifiedOn;
        CRMSalesorderdetail.Modify(); // handled by subscriber COD139184.ValidateSalesOrderDetailOnAfterModify
    end;

    [Scope('OnPrem')]
    procedure CreateCRMSystemUser(var CRMSystemuser: Record "CRM Systemuser")
    begin
        Clear(CRMSystemuser);
        CRMSystemuser.Init();
        CRMSystemuser.FullName :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(20, 0), 1, MaxStrLen(CRMSystemuser.FullName));
        CRMSystemuser.CreatedOn := CurrentCRMDateTime();
        CRMSystemuser.ModifiedOn := CRMSystemuser.CreatedOn;
        CRMSystemuser.InternalEMailAddress :=
          CopyStr(CRMSystemuser.FullName + '@ORG.INT', 1, MaxStrLen(CRMSystemuser.InternalEMailAddress));
        CRMSystemuser.IsLicensed := true;
        CRMSystemuser.IsIntegrationUser := false;
        CRMSystemuser.IsDisabled := false;
        CRMSystemuser.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMTeam(var CRMTeam: Record "CRM Team")
    var
        CDSCompany: Record "CDS Company";
    begin
        EnsureCDSCompany(CDSCompany);
        CreateCRMTeam(
            CRMTeam,
            CopyStr(LibraryUtility.GenerateRandomAlphabeticText(20, 0), 1, MaxStrLen(CRMTeam.Name)),
            CDSCompany.OwningBusinessUnit);
    end;

    local procedure CreateCRMTeam(var CRMTeam: Record "CRM Team"; Name: Text[160]; BusinessunitId: Guid)
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureAdminCRMSystemUser();
        FindAdminCRMSystemUser(CRMSystemuser);

        Clear(CRMTeam);
        CRMTeam.Init();
        CRMTeam.Name := Name;
        CRMTeam.BusinessUnitId := BusinessunitId;
        CRMTeam.CreatedBy := CRMSystemuser.SystemUserId;
        CRMTeam.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMTeam.CreatedOn := CurrentCRMDateTime();
        CRMTeam.ModifiedOn := CRMTeam.CreatedOn;
        CRMTeam.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMBusinessunit(var CRMBusinessunit: Record "CRM Businessunit"; Name: Text[160])
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureAdminCRMSystemUser();
        FindAdminCRMSystemUser(CRMSystemuser);

        Clear(CRMBusinessunit);
        CRMBusinessunit.Init();
        CRMBusinessunit.Name := Name;
        CRMBusinessunit.CreatedBy := CRMSystemuser.SystemUserId;
        CRMBusinessunit.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMBusinessunit.CreatedOn := CurrentCRMDateTime();
        CRMBusinessunit.ModifiedOn := CRMBusinessunit.CreatedOn;
        CRMBusinessunit.Insert();
    end;

    [Scope('OnPrem')]
    procedure EnsureCDSCompany(var CDSCompany: Record "CDS Company")
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMBusinessunit: Record "CRM Businessunit";
        CRMSystemuser: Record "CRM Systemuser";
        CRMTeam: Record "CRM Team";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ExternalId: Text[36];
    begin
        ExternalId := GetCompanyExternalId();
        CDSCompany.SetRange(ExternalId, ExternalId);
        if CDSCompany.FindFirst() then
            exit;
        EnsureAdminCRMSystemUser();
        FindAdminCRMSystemUser(CRMSystemuser);
        CreateCRMBusinessunit(CRMBusinessunit, CDSIntegrationImpl.GetDefaultBusinessUnitName());
        CDSConnectionSetup.Get();
        CDSConnectionSetup."Business Unit Id" := CRMBusinessunit.BusinessUnitId;
        CDSConnectionSetup."Business Unit Name" := CRMBusinessunit.Name;
        CDSConnectionSetup.Modify(true);
        CreateCRMTeam(CRMTeam, StrSubstNo('BCI - %1', CRMBusinessunit.Name), CRMBusinessunit.BusinessUnitId);
        CDSCompany.ExternalId := GetCompanyExternalId();
        CDSCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(CDSCompany.Name));
        CDSCompany.OwningBusinessUnit := CRMBusinessunit.BusinessUnitId;
        CDSCompany.OwnerIdType := CDSCompany.OwnerIdType::team;
        CDSCompany.OwnerId := CRMTeam.TeamId;
        CDSCompany.DefaultOwningTeam := CRMTeam.TeamId;
        CDSCompany.CreatedBy := CRMSystemuser.SystemUserId;
        CDSCompany.ModifiedBy := CRMSystemuser.SystemUserId;
        CDSCompany.CreatedOn := CurrentCRMDateTime();
        CDSCompany.ModifiedOn := CDSCompany.CreatedOn;
        CDSCompany.Insert();
    end;

    local procedure GetCompanyExternalId(): Text[36]
    var
        Company: Record Company;
        ExternalId: Text[36];
    begin
        Company.Get(CompanyName());
        ExternalId := CopyStr(Format(Company.SystemId).ToLower().Replace('{', '').Replace('}', ''), 1, MaxStrLen(ExternalId));
        exit(ExternalId);
    end;

    [Scope('OnPrem')]
    procedure CreateCDSSolution(var CDSSolution: Record "CDS Solution"; UniqueName: Text[65]; FriendlyName: Text[250]; Version: Text[250])
    begin
        Clear(CDSSolution);
        CDSSolution.Init();
        CDSSolution.UniqueName := UniqueName;
        CDSSolution.FriendlyName := FriendlyName;
        CDSSolution.Version := Version;
        CDSSolution.IsManaged := true;
        CDSSolution.IsVisible := true;
        CDSSolution.InstalledOn := CurrentCRMDateTime();
        CDSSolution.CreatedOn := CDSSolution.InstalledOn;
        CDSSolution.ModifiedOn := CDSSolution.InstalledOn;
        CDSSolution.Insert();
    end;

    [Scope('OnPrem')]
    procedure EnsureAdminCRMSystemUser(): Guid
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        if not FindAdminCRMSystemUser(CRMSystemuser) then begin
            CreateCRMSystemUser(CRMSystemuser);
            CRMSystemuser.FirstName := 'Administrator';
            CRMSystemuser.LastName := 'User';
            CRMSystemuser.Modify();
        end;
        CRMSystemuser.Reset();
        CRMSystemuser.SetFilter(SystemUserId, '<>%1', CRMSystemuser.SystemUserId);
        if not CRMSystemuser.FindFirst() then begin
            Clear(CRMSystemuser);
            CreateCRMSystemUser(CRMSystemuser);
        end;
        exit(CRMSystemuser.SystemUserId);
    end;

    local procedure FindAdminCRMSystemUser(var CRMSystemuser: Record "CRM Systemuser"): Boolean
    begin
        CRMSystemuser.SetRange(FirstName, 'Administrator');
        CRMSystemuser.SetRange(LastName, 'User');
        exit(CRMSystemuser.FindFirst());
    end;

    [Scope('OnPrem')]
    procedure CreateCRMTransactionCurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; ISOCurrencyCode: Text[5])
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMTransactioncurrency);
        CRMTransactioncurrency.Init();
        CRMTransactioncurrency.ExchangeRate := 1;
        CRMTransactioncurrency.CurrencySymbol := ISOCurrencyCode;
        CRMTransactioncurrency.ISOCurrencyCode := ISOCurrencyCode;
        CRMTransactioncurrency.CurrencyName := ISOCurrencyCode;
        CRMTransactioncurrency.CreatedBy := CRMSystemuser.SystemUserId;
        CRMTransactioncurrency.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMTransactioncurrency.CreatedOn := CurrentCRMDateTime();
        CRMTransactioncurrency.ModifiedOn := CRMTransactioncurrency.CreatedOn;
        CRMTransactioncurrency.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMUomschedule(var CRMUomschedule: Record "CRM Uomschedule"; CRMUomscheduleName: Text[200])
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMUomschedule);
        CRMUomschedule.Init();
        CRMUomschedule.Name := CRMUomscheduleName;
        CRMUomschedule.CreatedBy := CRMSystemuser.SystemUserId;
        CRMUomschedule.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMUomschedule.CreatedOn := CurrentCRMDateTime();
        CRMUomschedule.ModifiedOn := CRMUomschedule.CreatedOn;
        CRMUomschedule.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMUom(CRMUomschedule: Record "CRM Uomschedule"; var CRMUom: Record "CRM Uom"; CRMUomName: Text[200])
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMUom);
        CRMUom.Init();
        CRMUom.Name := CopyStr(CRMUomName, 1, MaxStrLen(CRMUom.Name));
        CRMUom.UoMScheduleId := CRMUomschedule.UoMScheduleId;
        CRMUom.CreatedBy := CRMSystemuser.SystemUserId;
        CRMUom.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMUom.CreatedOn := CurrentCRMDateTime();
        CRMUom.ModifiedOn := CRMUomschedule.CreatedOn;
        CRMUom.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMUomAndUomSchedule(var CRMUom: Record "CRM Uom"; var CRMUomschedule: Record "CRM Uomschedule")
    var
        CRMSystemuser: Record "CRM Systemuser";
        CRMUomName: Text[100];
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        if CRMUom.Name <> '' then
            CRMUomName := CRMUom.Name
        else
            CRMUomName := DefaultUoMNameTxt;

        Clear(CRMUomschedule);
        CRMUomschedule.Init();
        CRMUomschedule.Name := StrSubstNo('NAV %1', CRMUomName);
        CRMUomschedule.CreatedBy := CRMSystemuser.SystemUserId;
        CRMUomschedule.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMUomschedule.CreatedOn := CurrentCRMDateTime();
        CRMUomschedule.ModifiedOn := CRMUomschedule.CreatedOn;
        CRMUomschedule.Insert();

        Clear(CRMUom);
        CRMUom.Init();
        CRMUom.UoMScheduleId := CRMUomschedule.UoMScheduleId;
        CRMUom.Name := CRMUomName;
        CRMUom.Quantity := 1;
        CRMUom.IsScheduleBaseUoM := true;
        CRMUom.CreatedBy := CRMSystemuser.SystemUserId;
        CRMUom.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMUom.CreatedOn := CurrentCRMDateTime();
        CRMUom.ModifiedOn := CRMUom.CreatedOn;
        CRMUom.Insert();

        CRMUomschedule.BaseUoMName := CRMUom.Name;
        CRMUomschedule.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMOpportunity(var CRMOpportunity: Record "CRM Opportunity")
    begin
        Clear(CRMOpportunity);
        CRMOpportunity.Init();
        CRMOpportunity.Name :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(20, 0), 1, MaxStrLen(CRMOpportunity.Name));
        CRMOpportunity.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCurrency(var Currency: Record Currency)
    begin
        Currency.Init();
        Currency.Validate(Code, LibraryUtility.GenerateRandomCodeWithLength(Currency.FieldNo(Code), DATABASE::Currency, 5));
        Currency.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMQuote(var CRMQuote: Record "CRM Quote")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        EnsureCRMSystemUser();
        CRMSystemuser.SetFilter(FirstName, '<>Integration');
        CRMSystemuser.FindFirst();

        Clear(CRMQuote);
        CRMQuote.Name := 'Test CRM Quote';
        CRMQuote.Init();
        CRMQuote.CreatedBy := CRMSystemuser.SystemUserId;
        CRMQuote.ModifiedBy := CRMSystemuser.SystemUserId;
        CRMQuote.CreatedOn := CurrentCRMDateTime();
        CRMQuote.ModifiedOn := CRMQuote.CreatedOn;
        CRMQuote.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMQuoteWithCustomerFCY(var CRMQuote: Record "CRM Quote"; AccountId: Guid; CurrencyId: Guid)
    begin
        CreateCRMQuote(CRMQuote);
        CRMQuote.QuoteNumber := LibraryUtility.GenerateGUID();
        CRMQuote.StateCode := CRMQuote.StateCode::Active;
        CRMQuote.StatusCode := CRMQuote.StatusCode::InProgress;
        CRMQuote.AccountId := AccountId;
        CRMQuote.CustomerId := AccountId;
        CRMQuote.CustomerIdType := CRMQuote.CustomerIdType::account;
        CRMQuote.TransactionCurrencyId := CurrencyId;

        CRMQuote.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateCRMQuoteLine(var CRMQuote: Record "CRM Quote"; var CRMQuotedetail: Record "CRM Quotedetail")
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
    begin
        CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.Modify();
        PrepareCRMQuoteLine(CRMQuote, CRMQuotedetail, CRMProduct.ProductId);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMQuoteLineWithResource(var CRMQuote: Record "CRM Quote"; var CRMQuotedetail: Record "CRM Quotedetail")
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
    begin
        CreateCoupledResourceAndProduct(Resource, CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        CRMProduct.Modify();
        PrepareCRMQuoteLine(CRMQuote, CRMQuotedetail, CRMProduct.ProductId);
    end;

    [Scope('OnPrem')]
    procedure PrepareCRMQuoteLine(var CRMQuote: Record "CRM Quote"; var CRMQuotedetail: Record "CRM Quotedetail"; CRMProductId: Guid)
    begin
        CRMQuotedetail.Init();
        CRMQuotedetail.QuoteId := CRMQuote.QuoteId;
        CRMQuotedetail.LineItemNumber := 1;
        CRMQuotedetail.ExchangeRate := 1;
        // LCY
        CRMQuotedetail.CreatedBy := CRMQuote.CreatedBy;
        CRMQuotedetail.CreatedOn := CRMQuote.CreatedOn;
        CRMQuotedetail.Insert();

        CRMQuotedetail.ProductId := CRMProductId;
        CRMQuotedetail.Quantity := LibraryRandom.RandIntInRange(10, 20);
        CRMQuotedetail.PricePerUnit := LibraryRandom.RandDecInRange(100, 200, 2);
        CRMQuotedetail.ModifiedBy := CRMQuote.ModifiedBy;
        CRMQuotedetail.ModifiedOn := CRMQuote.ModifiedOn;
        CRMQuotedetail.Modify(); // handled by subscriber COD139184.ValidateSalesOrderDetailOnAfterModify
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationTableData(UnitOfMeasureRecordCount: Integer; IntegrationTableRecordCount: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TestIntegrationTable: Record "Test Integration Table";
        UnitOfMeasure: Record "Unit of Measure";
        Counter: Integer;
    begin
        CRMIntegrationRecord.SetRange("Table ID", DATABASE::"Unit of Measure");
        CRMIntegrationRecord.DeleteAll();
        UnitOfMeasure.DeleteAll();

        for Counter := 1 to UnitOfMeasureRecordCount do begin
            UnitOfMeasure.Init();
            UnitOfMeasure.Code := 'MEAS' + Format(Counter);
            UnitOfMeasure.Description := 'Desc ' + Format(Counter);
            UnitOfMeasure."International Standard Code" := 'MEAS' + Format(100 + Counter);
            UnitOfMeasure.Insert();
        end;

        TestIntegrationTable.DeleteAll();

        for Counter := 1 to IntegrationTableRecordCount do begin
            TestIntegrationTable.Init();
            TestIntegrationTable."Integration Uid" := CreateGuid();
            TestIntegrationTable."Integration Field Value" := 'FMEAS' + Format(Counter);
            TestIntegrationTable."Integration Modified Field" := CurrentDateTime;
            TestIntegrationTable."Integration Slave Field Value" := '';
            TestIntegrationTable.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // Integration Table Mapping definition
        IntegrationTableMapping.DeleteAll();

        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'TEST';
        IntegrationTableMapping."Table ID" := DATABASE::"Unit of Measure";
        IntegrationTableMapping."Integration Table ID" := DATABASE::"Test Integration Table";
        IntegrationTableMapping."Integration Table UID Fld. No." := 10;
        // Integration Table Uid
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := 11;
        // Integration Table Last Modified Field
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Insert();
        // Map columns. Bidirectional, ToIntegrationTable, FromIntegrationTable
        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := 'TEST';
        IntegrationFieldMapping."Field No." := 2;
        // Description
        IntegrationFieldMapping."Integration Table Field No." := 2;
        // Integration Table Field No
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::Bidirectional;
        IntegrationFieldMapping.Insert(true);

        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := 'TEST';
        IntegrationFieldMapping."Field No." := 3;
        // International Standard Code
        IntegrationFieldMapping."Integration Table Field No." := 3;
        // Integration Table Slave Field Value
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::ToIntegrationTable;
        IntegrationFieldMapping.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationTableMappingResourceProduct()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // Integration Table Mapping definition
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'TEST RESOURCE-PROD';
        IntegrationTableMapping."Table ID" := DATABASE::Resource;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Product";
        IntegrationTableMapping."Integration Table UID Fld. No." := 1;
        // Integration Table Uid
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := 24;
        // Integration Table Last Modified Field
        IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";
        IntegrationTableMapping.Insert();
        // Map columns, "No." -> ProductNumber
        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := 'TEST RESOURCE-PROD';
        IntegrationFieldMapping."Field No." := Resource.FieldNo("No.");
        IntegrationFieldMapping."Integration Table Field No." := CRMProduct.FieldNo(ProductNumber);
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::ToIntegrationTable;
        IntegrationFieldMapping.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationTableMappingCustomer(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping."Integration Table UID Fld. No." := CRMAccount.FieldNo(AccountId);
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := CRMAccount.FieldNo(ModifiedOn);
        IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";
        IntegrationTableMapping.Insert();

        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := Customer.FieldNo("No.");
        IntegrationFieldMapping."Integration Table Field No." := CRMAccount.FieldNo(AccountNumber);
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::ToIntegrationTable;
        IntegrationFieldMapping.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationTableMappingCurrency(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := DATABASE::Currency;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Transactioncurrency";
        IntegrationTableMapping."Integration Table UID Fld. No." := CRMTransactioncurrency.FieldNo(TransactionCurrencyId);
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := CRMTransactioncurrency.FieldNo(ModifiedOn);
        IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";
        IntegrationTableMapping.Insert();

        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := Currency.FieldNo(Code);
        IntegrationFieldMapping."Integration Table Field No." := CRMTransactioncurrency.FieldNo(ISOCurrencyCode);
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::ToIntegrationTable;
        IntegrationFieldMapping.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ConfigureCRM()
    begin
        RegisterTestTableConnection();
        EnsureCRMSystemUser();
    end;

    local procedure CoupleRecordIdToCRMId(RecordID: RecordID; CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        NullGUID: Guid;
    begin
        CRMIntegrationRecord.CoupleRecordIdToCRMID(RecordID, CRMID);
        CRMIntegrationRecord.SetLastSynchModifiedOns(CRMID, RecordID.TableNo, CurrentCRMDateTime(), CurrentDateTime, NullGUID, 0);
    end;

    [Scope('OnPrem')]
    procedure EnsureCDSSystemUser(): Guid
    var
        CRMSystemuser: Record "CRM Systemuser";
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        CDSConnectionSetup.Get();
        if not FindIntegrationSystemUser(CDSConnectionSetup, CRMSystemuser) then begin
            CreateCRMSystemUser(CRMSystemuser);
            CRMSystemuser.FirstName := 'Integration';
            CRMSystemuser.LastName := 'User';
            case CDSConnectionSetup."Authentication Type" of
                CDSConnectionSetup."Authentication Type"::Office365, CDSConnectionSetup."Authentication Type"::OAuth:
                    CRMSystemuser.InternalEMailAddress :=
                      CopyStr(CDSConnectionSetup."User Name", 1, MaxStrLen(CRMSystemuser.InternalEMailAddress));
                CDSConnectionSetup."Authentication Type"::AD, CDSConnectionSetup."Authentication Type"::IFD:
                    CRMSystemuser.DomainName :=
                      CopyStr(CDSConnectionSetup."User Name", 1, MaxStrLen(CRMSystemuser.DomainName));
            end;
            CRMSystemuser.Modify();
        end;
        CRMSystemuser.Reset();
        CRMSystemuser.SetFilter(SystemUserId, '<>%1', CRMSystemuser.SystemUserId);
        if not CRMSystemuser.FindFirst() then begin
            Clear(CRMSystemuser);
            CreateCRMSystemUser(CRMSystemuser);
        end;
        exit(CRMSystemuser.SystemUserId);
    end;

    [Scope('OnPrem')]
    procedure EnsureCRMSystemUser(): Guid
    var
        CRMSystemuser: Record "CRM Systemuser";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        if not FindIntegrationSystemUser(CRMConnectionSetup, CRMSystemuser) then begin
            CreateCRMSystemUser(CRMSystemuser);
            CRMSystemuser.FirstName := 'Integration';
            CRMSystemuser.LastName := 'User';
            case CRMConnectionSetup."Authentication Type" of
                CRMConnectionSetup."Authentication Type"::Office365, CRMConnectionSetup."Authentication Type"::OAuth:
                    CRMSystemuser.InternalEMailAddress :=
                      CopyStr(CRMConnectionSetup."User Name", 1, MaxStrLen(CRMSystemuser.InternalEMailAddress));
                CRMConnectionSetup."Authentication Type"::AD, CRMConnectionSetup."Authentication Type"::IFD:
                    CRMSystemuser.DomainName :=
                      CopyStr(CRMConnectionSetup."User Name", 1, MaxStrLen(CRMSystemuser.DomainName));
            end;
            CRMSystemuser.Modify();
        end;
        CRMSystemuser.Reset();
        CRMSystemuser.SetFilter(SystemUserId, '<>%1', CRMSystemuser.SystemUserId);
        if not CRMSystemuser.FindFirst() then begin
            Clear(CRMSystemuser);
            CreateCRMSystemUser(CRMSystemuser);
        end;
        exit(CRMSystemuser.SystemUserId);
    end;

    local procedure FindIntegrationSystemUser(CDSConnectionSetup: Record "CDS Connection Setup"; var CRMSystemuser: Record "CRM Systemuser"): Boolean
    begin
        case CDSConnectionSetup."Authentication Type" of
            CDSConnectionSetup."Authentication Type"::Office365, CDSConnectionSetup."Authentication Type"::OAuth:
                CRMSystemuser.SetRange(InternalEMailAddress, CDSConnectionSetup."User Name");
            CDSConnectionSetup."Authentication Type"::AD, CDSConnectionSetup."Authentication Type"::IFD:
                CRMSystemuser.SetRange(DomainName, CDSConnectionSetup."User Name");
        end;
        exit(CRMSystemuser.FindFirst());
    end;

    local procedure FindIntegrationSystemUser(CRMConnectionSetup: Record "CRM Connection Setup"; var CRMSystemuser: Record "CRM Systemuser"): Boolean
    begin
        case CRMConnectionSetup."Authentication Type" of
            CRMConnectionSetup."Authentication Type"::Office365, CRMConnectionSetup."Authentication Type"::OAuth:
                CRMSystemuser.SetRange(InternalEMailAddress, CRMConnectionSetup."User Name");
            CRMConnectionSetup."Authentication Type"::AD, CRMConnectionSetup."Authentication Type"::IFD:
                CRMSystemuser.SetRange(DomainName, CRMConnectionSetup."User Name");
        end;
        exit(CRMSystemuser.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure GetBaseCRMTestCurrencySymbol(): Text[5]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(Format(GeneralLedgerSetup."LCY Code", 5));
    end;

    [Scope('OnPrem')]
    procedure GetGLSetupCRMTransactionCurrencyID(): Guid
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        GeneralLedgerSetup.Get();
        CRMTransactioncurrency.SetFilter(ISOCurrencyCode,
          CopyStr(GeneralLedgerSetup."LCY Code", 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        if not CRMTransactioncurrency.FindFirst() then
            AddCRMTransactionCurrency(CRMTransactioncurrency,
              CopyStr(GeneralLedgerSetup."LCY Code", 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        exit(CRMTransactioncurrency.TransactionCurrencyId);
    end;

    [Scope('OnPrem')]
    procedure SetCRMDefaultPriceList(var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        if not IsNullGuid(CRMConnectionSetup."Default CRM Price List ID") then
            if CRMPricelevel.Get(CRMConnectionSetup."Default CRM Price List ID") then
                exit;

        CRMPricelevel.Init();
        CRMPricelevel.Name := CRMSynchHelper.GetDefaultPriceListName();
        CRMPriceLevel.TransactionCurrencyId := GetGLSetupCRMTransactionCurrencyID();
        CRMPricelevel.Insert();

        CRMConnectionSetup.Validate("Default CRM Price List ID", CRMPricelevel.PriceLevelId);
        CRMConnectionSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure IsCRMTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.TableType = TableMetadata.TableType::CRM);
    end;

    [Scope('OnPrem')]
    procedure MockSyncJob(TableID: Integer; Msg: Text) JobID: Guid
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        JobID := CreateGuid();
        IntegrationSynchJob.ID := JobID;
        if CRMIntegrationManagement.IsCRMTable(TableID) then begin
            IntegrationSynchJob."Synch. Direction" := IntegrationSynchJob."Synch. Direction"::FromIntegrationTable;
            IntegrationTableMapping.SetRange("Integration Table ID", TableID);
        end else begin
            IntegrationSynchJob."Synch. Direction" := IntegrationSynchJob."Synch. Direction"::ToIntegrationTable;
            IntegrationTableMapping.SetRange("Table ID", TableID);
        end;
        IntegrationTableMapping.FindFirst();
        IntegrationSynchJob."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationSynchJob."Start Date/Time" := CurrentDateTime - 5;
        IntegrationSynchJob."Finish Date/Time" := CurrentDateTime;
        IntegrationSynchJob.Message := CopyStr(Msg, 1, 250);
        IntegrationSynchJob.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockSyncJobError(SourceRecId: RecordID; DestRecId: RecordID; ErrorMsg: Text; FailedOn: DateTime) JobID: Guid
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        JobID := MockSyncJob(SourceRecId.TableNo, ErrorMsg);

        IntegrationSynchJobErrors."Source Record ID" := SourceRecId;
        IntegrationSynchJobErrors."Destination Record ID" := DestRecId;
        IntegrationSynchJobErrors."Integration Synch. Job ID" := JobID;
        IntegrationSynchJobErrors.Message :=
          CopyStr(ErrorMsg, 1, MaxStrLen(IntegrationSynchJobErrors.Message));
        IntegrationSynchJobErrors."Date/Time" := FailedOn;
        IntegrationSynchJobErrors.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockFailedSynchToCRMIntegrationRecord(SourceRecId: RecordID; DestRecId: RecordID; ErrorMsg: Text; FailedOn: DateTime; Skipped: Boolean) JobID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        JobID := MockSyncJobError(SourceRecId, DestRecId, ErrorMsg, FailedOn);
        CRMIntegrationRecord.FindByRecordID(SourceRecId);
        CRMIntegrationRecord."Last Synch. CRM Result" := CRMIntegrationRecord."Last Synch. CRM Result"::Failure;
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID;
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentCRMDateTime();
        CRMIntegrationRecord.Skipped := Skipped;
        CRMIntegrationRecord.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockFailedSynchToNAVIntegrationRecord(CRMID: Guid; SourceRecId: RecordID; DestRecId: RecordID; ErrorMsg: Text; FailedOn: DateTime; Skipped: Boolean) JobID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        JobID := MockSyncJobError(SourceRecId, DestRecId, ErrorMsg, FailedOn);
        CRMIntegrationRecord.FindByCRMID(CRMID);
        CRMIntegrationRecord."Last Synch. Result" := CRMIntegrationRecord."Last Synch. Result"::Failure;
        CRMIntegrationRecord."Last Synch. Job ID" := JobID;
        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime;
        CRMIntegrationRecord.Skipped := Skipped;
        CRMIntegrationRecord.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockSuccessSynchToCRMIntegrationRecord(SourceRecID: RecordID; Msg: Text) JobID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        JobID := MockSyncJob(SourceRecID.TableNo, Msg);
        CRMIntegrationRecord.FindByRecordID(SourceRecID);
        CRMIntegrationRecord."Last Synch. CRM Result" := CRMIntegrationRecord."Last Synch. CRM Result"::Success;
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID;
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentCRMDateTime();
        CRMIntegrationRecord.Skipped := false;
        CRMIntegrationRecord.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockSuccessSynchToNAVIntegrationRecord(CRMID: Guid; SourceRecID: RecordID; Msg: Text) JobID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        JobID := MockSyncJob(SourceRecID.TableNo, Msg);
        CRMIntegrationRecord.FindByCRMID(CRMID);
        CRMIntegrationRecord."Last Synch. Result" := CRMIntegrationRecord."Last Synch. Result"::Success;
        CRMIntegrationRecord."Last Synch. Job ID" := JobID;
        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime;
        CRMIntegrationRecord.Skipped := false;
        CRMIntegrationRecord.Modify();
    end;

    local procedure OpenAndFilterCustomerCard(var CustomerCard: TestPage "Customer Card"; CustomerNo: Code[20])
    begin
        CustomerCard.OpenView();
        CustomerCard.FILTER.SetFilter("No.", CustomerNo);
    end;

    local procedure OpenAndFilterCustomerList(var CustomerList: TestPage "Customer List"; CustomerNo: Code[20])
    begin
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", CustomerNo);
    end;

    local procedure OpenAndFilterCurrencyCard(var CurrencyCard: TestPage "Currency Card"; CurrencyCode: Code[10])
    begin
        CurrencyCard.OpenView();
        CurrencyCard.FILTER.SetFilter(Code, CurrencyCode);
    end;

    local procedure OpenAndFilterCurrencyList(var Currencies: TestPage Currencies; CurrencyCode: Code[10])
    begin
        Currencies.OpenView();
        Currencies.FILTER.SetFilter(Code, CurrencyCode);
    end;

    [Scope('OnPrem')]
    procedure OpenCRMAccountHyperLinkOnHostPage(HostPageName: Option CustomerCard,CustomerList; CustomerNo: Code[20])
    var
        CustomerCard: TestPage "Customer Card";
        CustomerList: TestPage "Customer List";
    begin
        case HostPageName of
            HostPageName::CustomerCard:
                begin
                    OpenAndFilterCustomerCard(CustomerCard, CustomerNo);
                    CustomerCard.CRMGotoAccount.Invoke();
                end;
            HostPageName::CustomerList:
                begin
                    OpenAndFilterCustomerList(CustomerList, CustomerNo);
                    CustomerList.CRMGotoAccount.Invoke();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenCRMTransactionCurrencyHyperLinkOnHostPage(HostPageName: Option CurrencyCard,CurrencyList; CurrencyCode: Code[10])
    var
        CurrencyCard: TestPage "Currency Card";
        Currencies: TestPage Currencies;
    begin
        case HostPageName of
            HostPageName::CurrencyCard:
                begin
                    OpenAndFilterCurrencyCard(CurrencyCard, CurrencyCode);
                    CurrencyCard.CRMGotoTransactionCurrency.Invoke();
                end;
            HostPageName::CurrencyList:
                begin
                    OpenAndFilterCurrencyList(Currencies, CurrencyCode);
                    Currencies.CRMGotoTransactionCurrency.Invoke();
                end;
        end;
    end;

    local procedure OpenLinkedPageOnCustomerCard(CustomerCard: TestPage "Customer Card"; LinkedPageName: Option Cases,Opportunities,Quotes)
    begin
        case LinkedPageName of
            LinkedPageName::Cases:
                CustomerCard.Control39.Cases.DrillDown();
            LinkedPageName::Opportunities:
                CustomerCard.Control39.Opportunities.DrillDown();
            LinkedPageName::Quotes:
                CustomerCard.Control39.Quotes.DrillDown();
        end;
    end;

    local procedure OpenLinkedPageOnCustomerList(CustomerList: TestPage "Customer List"; LinkedPageName: Option Cases,Opportunities,Quotes)
    begin
        case LinkedPageName of
            LinkedPageName::Cases:
                CustomerList.Control99.Cases.DrillDown();
            LinkedPageName::Opportunities:
                CustomerList.Control99.Opportunities.DrillDown();
            LinkedPageName::Quotes:
                CustomerList.Control99.Quotes.DrillDown();
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenNAVLinkOnHostPage(HostPageName: Option CustomerCard,CustomerList; LinkedPageName: Option Cases,Opportunities,Quotes; CustomerNo: Code[20])
    var
        CustomerCard: TestPage "Customer Card";
        CustomerList: TestPage "Customer List";
    begin
        case HostPageName of
            HostPageName::CustomerCard:
                begin
                    OpenAndFilterCustomerCard(CustomerCard, CustomerNo);
                    OpenLinkedPageOnCustomerCard(CustomerCard, LinkedPageName);
                end;
            HostPageName::CustomerList:
                begin
                    OpenAndFilterCustomerList(CustomerList, CustomerNo);
                    OpenLinkedPageOnCustomerList(CustomerList, LinkedPageName);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrepareWriteInProductItem(var Item: Record Item)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify();
        SetSalesSetupWriteInProduct(SalesSetup."Write-in Product Type"::Item, Item."No.");
    end;

    [Scope('OnPrem')]
    procedure PrepareWriteInProductResource(var Resource: Record Resource)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryResource.CreateResourceNew(Resource);
        SetSalesSetupWriteInProduct(SalesSetup."Write-in Product Type"::Resource, Resource."No.");
    end;

    [Scope('OnPrem')]
    procedure SetSalesSetupWriteInProduct(ProductType: Integer; ProductNo: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Write-in Product Type", ProductType);
        SalesSetup.Validate("Write-in Product No.", ProductNo);
        SalesSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetDoNotHandleCodeunitJobQueueEnqueueEvent(NewDoNotHandleCodeunitJobQueueEnqueueEvent: Boolean)
    begin
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(NewDoNotHandleCodeunitJobQueueEnqueueEvent);
    end;

    [Scope('OnPrem')]
    procedure MockConnection()
    begin
        LibraryMockCRMConnection.MockConnection();
    end;

    [Scope('OnPrem')]
    procedure RegisterTestTableConnection()
    begin
        LibraryMockCRMConnection.MockConnection();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        LibraryMockCRMConnection.RegisterTestConnection();
        CreateCRMConnectionSetup('', '@@test@@', true);
    end;

    [Scope('OnPrem')]
    procedure ResetEnvironment()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntTableSynchSubscriber: Codeunit "Int. Table Synch. Subscriber";
    begin
        CRMConnectionSetup.DeleteAll();
        CRMIntegrationRecord.DeleteAll();
        IntegrationSynchJob.DeleteAll();
        IntegrationSynchJobErrors.DeleteAll();
        IntegrationTableMapping.DeleteAll(true);
        ManIntegrationTableMapping.DeleteAll();

        IntTableSynchSubscriber.Reset();
        CRMIntegrationManagement.ClearState();
        CRMIntTableSubscriber.ClearCache();
        CRMSynchHelper.ClearCache();
        Clear(CRMIntTableSubscriber);
        Clear(CRMBusLogicSimulator);
        Assert.IsTrue(BindSubscription(CRMBusLogicSimulator), 'CRMBusLogicSimulator should be bind.');
        Clear(LibraryMockCRMConnection);
        LibraryMockCRMConnection.SkipRead();
        LibraryMockCRMConnection.MockConnection();
        Assert.IsTrue(BindSubscription(LibraryMockCRMConnection), 'LibraryMockCRMConnection should be bind.')
    end;

    [Scope('OnPrem')]
    procedure SynchronizeNowForTable(TableNo: Integer): Code[20]
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableNo);
        IntegrationTableMapping.FindFirst();
        IntegrationTableMapping.SynchronizeNow(false);
        exit(IntegrationTableMapping.Name);
    end;

    [Scope('OnPrem')]
    procedure SetFreightGLAccNo(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", LibraryERM.CreateGLAccountWithSalesSetup());
        SalesReceivablesSetup.Modify(true);
        exit(SalesReceivablesSetup."Freight G/L Acc. No.");
    end;

    [Scope('OnPrem')]
    procedure MockLastSyncModifiedOn(RecID: RecordID; SyncDateTime: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        CRMIntegrationRecord."Last Synch. Modified On" := SyncDateTime;
        CRMIntegrationRecord."Last Synch. CRM Modified On" := SyncDateTime;
        CRMIntegrationRecord.Modify();
    end;

    [Scope('OnPrem')]
    procedure UnbindBusLogicSimulator()
    begin
        Clear(CRMBusLogicSimulator);
    end;

    [Scope('OnPrem')]
    procedure UnbindMockConnection()
    begin
        Clear(LibraryMockCRMConnection);
    end;

    [Scope('OnPrem')]
    procedure DisableConnection()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        UnbindBusLogicSimulator();
        UnbindMockConnection();
        CRMConnectionSetup.DeleteAll();
        CDSConnectionSetup.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure EnableReadingCRMData()
    begin
        LibraryMockCRMConnection.EnableRead();
    end;

    [Scope('OnPrem')]
    procedure SkipReadingCRMData()
    begin
        LibraryMockCRMConnection.SkipRead();
    end;

    [Scope('OnPrem')]
    procedure DisableTaskOnBeforeJobQueueScheduleTask()
    begin
        UnbindLibraryJobQueue();
        BindSubscription(LibraryJobQueue);
    end;

    [Scope('OnPrem')]
    procedure UnbindLibraryJobQueue()
    begin
        Clear(LibraryJobQueue);
    end;

    [Scope('OnPrem')]
    procedure RunJobQueueEntryForIntTabMapping(IntegrationTableMapping: Record "Integration Table Mapping") JobQueueEntryID: Guid
    begin
        JobQueueEntryID := RunJobQueueEntryForIntTabMapping(IntegrationTableMapping, false);
    end;

    [Scope('OnPrem')]
    procedure RunJobQueueEntryForIntTabMapping(IntegrationTableMapping: Record "Integration Table Mapping"; HandleError: Boolean) JobQueueEntryID: Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.FindFirst();
        JobQueueEntryID := JobQueueEntry.ID;
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        if HandleError then begin
            asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
        end else
            LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
    end;

    [Scope('OnPrem')]
    procedure RunJobQueueEntry(TableID: Integer; View: Text; var IntegrationTableMapping: Record "Integration Table Mapping"): Guid
    begin
        if IsCRMTable(TableID) then
            FindTempIntegrationTableMapingFrom(IntegrationTableMapping, TableID, View)
        else
            FindTempIntegrationTableMapingTo(IntegrationTableMapping, TableID, View);
        exit(RunJobQueueEntryForIntTabMapping(IntegrationTableMapping));
    end;

    local procedure FindTempIntegrationTableMapingFrom(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; View: Text): Code[20]
    begin
        IntegrationTableMapping.SetRange("Integration Table ID", TableID);
        IntegrationTableMapping.FindSet();
        repeat
            if View = IntegrationTableMapping.GetIntegrationTableFilter() then
                exit(IntegrationTableMapping.Name);
        until IntegrationTableMapping.Next() = 0;
        Error(TempMappingNotFoundErr);
    end;

    local procedure FindTempIntegrationTableMapingTo(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; View: Text): Code[20]
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindSet();
        repeat
            if View = IntegrationTableMapping.GetTableFilter() then
                exit(IntegrationTableMapping.Name);
        until IntegrationTableMapping.Next() = 0;
        Error(TempMappingNotFoundErr);
    end;

    local procedure VerifySyncJobExecuted(JobQueueEntryID: Guid; IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationSynchJob: Record "Integration Synch. Job")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        Assert.IsFalse(IsNullGuid(JobQueueEntryID), 'JobQueueEntryID should not be Null');
        Assert.IsFalse(JobQueueEntry.Get(JobQueueEntryID), 'Job Queue Entry should be deleted');
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        JobQueueLogEntry.FindLast();
        IntegrationSynchJob.SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
        IntegrationSynchJob.SetRange("Synch. Direction", IntegrationTableMapping.Direction);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'IntegrationSynchJob should be found');
        IntegrationSynchJob.TestField("Integration Table Mapping Name", IntegrationTableMapping."Parent Name");
        Assert.IsFalse(IntegrationTableMapping.Get(IntegrationTableMapping.Name), 'Temp mapping record should be deleted.');
    end;

    [Scope('OnPrem')]
    procedure VerifySyncJob(JobQueueEntryID: Guid; IntegrationTableMapping: Record "Integration Table Mapping"; ExpectedIntegrationSynchJob: Record "Integration Synch. Job"): Guid
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        VerifySyncJobExecuted(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        VerifySyncRecCount(ExpectedIntegrationSynchJob, IntegrationSynchJob);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
        if ExpectedIntegrationSynchJob.Message = '' then
            Assert.RecordIsEmpty(IntegrationSynchJobErrors)
        else begin
            IntegrationSynchJobErrors.FindFirst();
            Assert.ExpectedMessage(ExpectedIntegrationSynchJob.Message, IntegrationSynchJobErrors.Message);
        end;
        exit(IntegrationSynchJob.ID);
    end;

    [Scope('OnPrem')]
    procedure VerifySyncJobFailedOneRecord(JobQueueEntryID: Guid; IntegrationTableMapping: Record "Integration Table Mapping"; ErrorMessage: Text)
    var
        ExpectedIntegrationSynchJob: Record "Integration Synch. Job";
    begin
        ExpectedIntegrationSynchJob.Failed := 1;
        ExpectedIntegrationSynchJob.Message :=
          CopyStr(ErrorMessage, 1, MaxStrLen(ExpectedIntegrationSynchJob.Message));
        VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, ExpectedIntegrationSynchJob);
    end;

    [Scope('OnPrem')]
    procedure VerifySyncRecCount(ExpectedIntegrationSynchJob: Record "Integration Synch. Job"; IntegrationSynchJob: Record "Integration Synch. Job")
    begin
        Assert.AreEqual(ExpectedIntegrationSynchJob.Inserted, IntegrationSynchJob.Inserted, 'count of Inserted');
        Assert.AreEqual(ExpectedIntegrationSynchJob.Modified, IntegrationSynchJob.Modified, 'count of Modified');
        Assert.AreEqual(ExpectedIntegrationSynchJob.Failed, IntegrationSynchJob.Failed, 'count of Failed');
        Assert.AreEqual(ExpectedIntegrationSynchJob.Deleted, IntegrationSynchJob.Deleted, 'count of Deleted');
        Assert.AreEqual(ExpectedIntegrationSynchJob.Unchanged, IntegrationSynchJob.Unchanged, 'count of Unchanged');
        Assert.AreEqual(ExpectedIntegrationSynchJob.Skipped, IntegrationSynchJob.Skipped, 'count of Skipped');
    end;

    [Scope('OnPrem')]
    procedure InitializeCRMSynchStatus()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.InitializeCRMSynchStatus();
    end;

    [Scope('OnPrem')]
    procedure GetLastestSDKVersion(): Integer
    var
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        CurrentVersion: DotNet Version;
        MinVersion: DotNet Version;
        DataverseServiceClientVersion: DotNet Version;
    begin
        DataverseServiceClientVersion := MinVersion.Parse('21.0.43087.0');
        MinVersion := MinVersion.Parse('16.0.11346.0');
        CurrentVersion := NavTenantSettingsHelper.GetPlatformVersion();
        if (CurrentVersion.CompareTo(MinVersion) >= 0) and (CurrentVersion.CompareTo(DataverseServiceClientVersion) < 0) then
            exit(91);
        if (CurrentVersion.CompareTo(MinVersion) >= 0) and (CurrentVersion.CompareTo(DataverseServiceClientVersion) >= 0) then
            exit(100);
        exit(9);
    end;

    [Scope('OnPrem')]
    procedure SetCRMTimeDiff(TimeDiffSeconds: Integer)
    begin
        CRMTimeDiffSeconds := TimeDiffSeconds;
        CRMBusLogicSimulator.SetCRMTimeDiff(TimeDiffSeconds);
    end;

    local procedure CurrentCRMDateTime(): DateTime
    begin
        exit(CurrentDateTime() + (CRMTimeDiffSeconds * 1000));
    end;
}
