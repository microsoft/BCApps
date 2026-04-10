codeunit 135022 "Data Migration Facade Tests"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Migration Facade]
    end;

    var
        Assert: Codeunit Assert;
        InteralVendorNotSetErr: Label 'Internal Vendor is not set. Create it first.';
        InternalCustomerNotSetErr: Label 'Internal Customer is not set. Create it first.';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        InternalGenJournalLineNotSetErr: Label 'Internal Gen. Journal Line is not set. Create it first.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DataMigrationFacadeTests: Codeunit "Data Migration Facade Tests";
        InternalItemNotSetErr: Label 'Internal item is not set. Create it first.';
        InternalItemJnlLIneNotSetErr: Label 'Internal item journal line is not set. Create it first.';
        InternalGLAccountNotSetErr: Label 'Internal G/L Account is not set. Create it first.';
        InternalGeneralPostingSetupNotSetErr: Label 'Internal General Posting Setup is not set. Create it first.';
        TaxAreaCodeDoesNotExistErr: Label 'The field Tax Area Code of table Customer contains a value (123) that cannot be found in the related table (Tax Area).';
        ExtendedPriceCalculationEnabled: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateUpdateVendor()
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Contact: Record Contact;
        PrimaryContact: Record Contact;
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        VendorPostingGroup: Record "Vendor Posting Group";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ShipmentMethod: Record "Shipment Method";
        CountryRegion: Record "Country/Region";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ExRateDataMigrationFacade: Codeunit "Ex. Rate Data Migration Facade";
        VendorDataMigrationFacade: Codeunit "Vendor Data Migration Facade";
        PaymentTermsFormula: DateFormula;
        LastModifiedDate: Date;
        LastModifiedDateTime: DateTime;
        CountryCode: Code[10];
        LanguageCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO] Vendor can be created and updated
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] CreateVendorIfNeeded is called
        VendorDataMigrationFacade.CreateVendorIfNeeded('VEND1', 'Name');

        // [THEN] Vendor is created
        Assert.IsTrue(VendorDataMigrationFacade.DoesVendorExist('VEND1'), 'Vendor was expected to have been created');
        Vendor.Get('VEND1');
        Assert.AreEqual('Name', Vendor.Name, 'A different name was expected');

        // [WHEN] The Vendor exists
        // [THEN] It is not created
        Assert.IsFalse(VendorDataMigrationFacade.CreateVendorIfNeeded('VEND1', 'Name'), 'Vendor should have not been created');

        // [THEN] Vendor dependencies can be created and updated
        VendorDataMigrationFacade.CreateCountryIfNeeded('DK', 'Denmark', 1, 1);
        CountryRegion.Get('DK');
        Assert.AreEqual('Denmark', CountryRegion.Name, 'A diffrent name was expected');
        Assert.AreEqual(1, CountryRegion."Address Format", 'A different address format was expected');
        Assert.AreEqual(1, CountryRegion."Contact Address Format", 'A different format was expected');
        Assert.IsTrue(VendorDataMigrationFacade.SearchCountry('DK', 'Denmark', '', '', CountryCode),
          'Country was expected to have been found');

        VendorDataMigrationFacade.CreatePaymentMethodIfNeeded('PM', 'Payment Method');
        // Already existing Payment method does not throw error
        VendorDataMigrationFacade.CreatePaymentMethodIfNeeded('PM', 'Payment Method');
        PaymentMethod.Get('PM');
        Assert.AreEqual('Payment Method', PaymentMethod.Description, 'A different description was expected');

        Evaluate(PaymentTermsFormula, '<14D>');
        VendorDataMigrationFacade.CreatePaymentTermsIfNeeded('PT', 'Payment Terms', PaymentTermsFormula);
        // Already existing Payment Terms does not throw error
        VendorDataMigrationFacade.CreatePaymentTermsIfNeeded('PT', 'Payment Terms', PaymentTermsFormula);

        PaymentTerms.Get('PT');
        Assert.AreEqual('Payment Terms', PaymentTerms.Description, 'A different description was expected');
        Assert.AreEqual(PaymentTermsFormula, PaymentTerms."Due Date Calculation", 'A different due date calculation was expected');

        Assert.IsTrue(VendorDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'Lyngby', '', 'DK'),
          'Post Code was expected to be created');
        Assert.IsFalse(VendorDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'Lyngby', '', 'DK'),
          'Post Code was not expected to be created');
        Assert.IsFalse(VendorDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'LYNGBY', '', 'DK'),
          'Post Code was not expected to be created');

        PostCode.Get('2600', 'Lyngby');
        Assert.AreEqual('DK', PostCode."Country/Region Code", 'A different Country region code was expected');
        Assert.IsTrue(VendorDataMigrationFacade.DoesPostCodeExist('2600', 'Lyngby'), 'Post code was expected to have been created');

        CreateGLAcount('GL0001');
        VendorDataMigrationFacade.CreatePostingSetupIfNeeded('VPG', 'Description', 'GL0001');
        VendorPostingGroup.Get('VPG');
        Assert.AreEqual('GL0001', VendorPostingGroup."Payables Account", 'A different payables account was expected.');

        CreateGLAcount('GL0002');
        // Posting setup is updated if it exists
        VendorDataMigrationFacade.CreatePostingSetupIfNeeded('VPG', 'Description', 'GL0002');
        VendorPostingGroup.Get('VPG');
        Assert.AreEqual('GL0002', VendorPostingGroup."Payables Account", 'A different payables account was expected.');

        VendorDataMigrationFacade.CreateSalespersonPurchaserIfNeeded('PURCH', 'Purchaser', '123456789', '123@mail.com');
        // Already existing salesperson does not throw error
        VendorDataMigrationFacade.CreateSalespersonPurchaserIfNeeded('PURCH', 'Purchaser', '123456789', '123@mail.com');

        SalespersonPurchaser.Get('PURCH');
        Assert.AreEqual('Purchaser', SalespersonPurchaser.Name, 'A different name was expected');
        Assert.AreEqual('123456789', SalespersonPurchaser."Phone No.", 'A different phone number was expected');
        Assert.AreEqual('123@mail.com', SalespersonPurchaser."E-Mail", 'A different email was expected');

        VendorDataMigrationFacade.CreateShipmentMethodIfNeeded('SM', 'Shipment method');
        // Already existing Shipment method does not throw error
        VendorDataMigrationFacade.CreateShipmentMethodIfNeeded('SM', 'Shipment method');

        ShipmentMethod.Get('SM');
        Assert.AreEqual('Shipment method', ShipmentMethod.Description, 'A different description was expected');

        Assert.IsTrue(VendorDataMigrationFacade.CreateVendorInvoiceDiscountIfNeeded('VID', 'DKK', 123, 0.2),
          'Vendor Invoice Discound Should have been created');

        VendorInvoiceDisc.Get('VID', 'DKK', 123);
        Assert.AreEqual(0.2, VendorInvoiceDisc."Discount %", 'A different discount % was expected');

        // [WHEN] CreateVendorInvoiceDiscountIfNeeded is called again
        // [THEN] The Vendor Ivoice Discount is not created again
        Assert.IsFalse(VendorDataMigrationFacade.CreateVendorInvoiceDiscountIfNeeded('VID', 'DKK', 123, 0),
          'Vendor Invoice Discound Should not have been created');

        VendorDataMigrationFacade.CreateVendorIfNeeded('VEND2', 'Name2');
        Vendor.Get('VEND2');
        Assert.AreEqual('Name2', Vendor.Name, 'A different name was expected');

        Assert.IsTrue(VendorDataMigrationFacade.SearchLanguage('DAN', LanguageCode), 'Danish languasge should have been found');

        // [GIVEN] Vendor values are set
        VendorDataMigrationFacade.SetGlobalVendor('VEND1');
        VendorDataMigrationFacade.SetAddress('Address1', 'Address2', 'DK', '2600', 'Lyngby');
        VendorDataMigrationFacade.SetBlocked("vendor Blocked"::Payment);
        VendorDataMigrationFacade.SetContact('Contact');
        VendorDataMigrationFacade.SetCurrencyCode('DKK');
        VendorDataMigrationFacade.SetFaxNo('123456789');
        VendorDataMigrationFacade.SetHomePage('Homepage');
        VendorDataMigrationFacade.SetLanguageCode('DANISH');
        VendorDataMigrationFacade.SetInvoiceDiscCode('VID');
        VendorDataMigrationFacade.SetOurAccountNo('GL0001');
        VendorDataMigrationFacade.SetPaymentTermsCode('PT');
        VendorDataMigrationFacade.SetPaymentMethod('PM');
        VendorDataMigrationFacade.SetPayToVendorNo('VEND2');
        VendorDataMigrationFacade.SetPhoneNo('123456789');
        VendorDataMigrationFacade.SetPurchaserCode('PURCH');
        VendorDataMigrationFacade.SetSearchName('Search Name');
        VendorDataMigrationFacade.SetShipmentMethodCode('SM');
        VendorDataMigrationFacade.SetTelexNo('123456789');
        VendorDataMigrationFacade.SetVATRegistrationNo('12345678');
        VendorDataMigrationFacade.SetVendorPostingGroup('VPG');
        VendorDataMigrationFacade.SetEmail('me@here.com');

        // [WHEN] VendorModify is called
        VendorDataMigrationFacade.ModifyVendor(true);

        // [THEN] The Vendor is update
        Vendor.Get('VEND1');
        Assert.AreEqual('Address1', Vendor.Address, 'A different address was expected');
        Assert.AreEqual('Address2', Vendor."Address 2", 'A different address was expected');
        Assert.AreEqual('Lyngby', Vendor.City, 'A different city was expected');
        Assert.AreEqual('2600', Vendor."Post Code", 'A different post code was expected');
        Assert.AreEqual('DK', Vendor."Country/Region Code", 'A different country code was expected');
        Assert.AreEqual(1, Vendor.Blocked, 'A different Blocked was expected.');
        Assert.AreEqual('Contact', Vendor.Contact, 'A different contact was expected');
        Assert.AreEqual('DKK', Vendor."Currency Code", 'A different currency code was expected');
        Assert.AreEqual('123456789', Vendor."Fax No.", 'A diffrent fax number was expected');
        Assert.AreEqual('Homepage', Vendor."Home Page", 'A different homepage was expected');
        Assert.AreEqual('DANISH', Vendor."Language Code", 'A different language code was expected');
        Assert.AreEqual('VID', Vendor."Invoice Disc. Code", 'A different Invoice discount was expected');
        Assert.AreEqual('GL0001', Vendor."Our Account No.", 'A different account number was expected');
        Assert.AreEqual('PT', Vendor."Payment Terms Code", 'A different payment terms was expected');
        Assert.AreEqual('PM', Vendor."Payment Method Code", 'A different payment method was expected');
        Assert.AreEqual('VEND2', Vendor."Pay-to Vendor No.", 'A different pay to vendor no was expected');
        Assert.AreEqual('123456789', Vendor."Phone No.", 'A different phone number was expected');
        Assert.AreEqual('PURCH', Vendor."Purchaser Code", 'A different purchaser was expected');
        Assert.AreEqual('SEARCH NAME', Vendor."Search Name", 'A different search name was expected');
        Assert.AreEqual('SM', Vendor."Shipment Method Code", 'A different shipment method was expected');
        Assert.AreEqual('123456789', Vendor."Telex No.", 'A different telex number was expected');
        Assert.AreEqual('12345678', Vendor."VAT Registration No.", 'A different VAT registration number was expected');
        Assert.AreEqual('VPG', Vendor."Vendor Posting Group", 'A different Vendor Posting Group was expected');
        Assert.AreEqual('me@here.com', Vendor."E-Mail", 'A different Vendor email address was expected');

        // [WHEN] The SetVendorAlternativeContact method is called
        VendorDataMigrationFacade.SetVendorAlternativeContact('Contact Name', 'Address', 'Address2', '2600', 'Lyngby', 'DK',
          'mail@mail.com', '123456789', '123456789', '123456789');

        // [THEN] A new Contact is created and is linked to Vendor
        Contact.SetRange(Name, 'Contact Name');
        Contact.FindFirst();
        Assert.AreEqual(Contact.Address, 'Address', 'The contact''s address was not set correctly');
        Assert.AreEqual(Contact."Address 2", 'Address2', 'The contact''s address2 was not set correctly');
        Assert.AreEqual(Contact."Post Code", '2600', 'The contact''s post code was not set correctly');
        Assert.AreEqual(Contact.City, 'Lyngby', 'The contact''s city was not set correctly');
        Assert.AreEqual(Contact."Country/Region Code", 'DK', 'The contact''s country was not set correctly');
        Assert.AreEqual(Contact."E-Mail", 'mail@mail.com', 'The contact''s email was not set correctly');
        Assert.AreEqual(Contact."Phone No.", '123456789', 'The contact''s phone was not set correctly');
        Assert.AreEqual(Contact."Fax No.", '123456789', 'The contact''s fax was not set correctly');
        Assert.AreEqual(Contact."Mobile Phone No.", '123456789', 'The contact''s mobile was not set correctly');
        PrimaryContact.SetRange(Name, 'Name');
        PrimaryContact.FindFirst();
        Assert.AreEqual(Contact."Company No.", PrimaryContact."No.", 'The Primary Contact was not set Correctly');
        Assert.AreEqual(Contact."Company Name", PrimaryContact.Name, 'The Primary Contact was not set Correctly');

        // [WHEN] The CreateDefaultDimensionAndRequirementsIfNeeded method is called
        VendorDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DIM1', 'Description', 'VAL1', 'Value');

        // [THEN] The Dimension is created
        Dimension.Get('DIM1');
        Assert.AreEqual('Description', Dimension.Description, 'A different value was expected.');
        DimensionValue.Get('DIM1', 'VAL1');
        Assert.AreEqual('Value', DimensionValue.Name, 'A different value was expected.');

        // [GIVEN] A specific Date and Datetime to set
        LastModifiedDate := CalcDate('<-1D>', WorkDate());
        LastModifiedDateTime := CreateDateTime(LastModifiedDate, Time);

        VendorDataMigrationFacade.SetLastDateModified(LastModifiedDate);
        VendorDataMigrationFacade.SetLastModifiedDateTime(LastModifiedDateTime);

        // [WHEN] ModifyVendor is called with FALSE
        VendorDataMigrationFacade.ModifyVendor(false);

        // [THEN] The given date and datetime values are set
        Vendor.Get('VEND1');
        Assert.AreEqual(LastModifiedDate, Vendor."Last Date Modified", 'A different date was expected');
        Assert.AreEqual(LastModifiedDateTime, Vendor."Last Modified Date Time", 'A different datetime was expected');

        // [WHEN] CreateGeneralJournalBatchIfNeeded is called
        VendorDataMigrationFacade.CreateGeneralJournalBatchIfNeeded('MIGRATION', '', '');

        // [THEN] The General Journal Batch and General Journal Template are Created
        GenJournalBatch.SetRange(Name, 'MIGRATION');
        Assert.RecordCount(GenJournalBatch, 1);
        GenJournalTemplate.SetRange(Name, 'MIGRATION');
        Assert.RecordCount(GenJournalTemplate, 1);

        // [GIVEN] The Currency Exchange Rate exists
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('DKK', WorkDate(), 0.2, 0.2);

        // [WHEN] CreateGeneralJournalLine is called
        // [WHEN] SetGeneralJournalLineDimension is called
        VendorDataMigrationFacade.CreateGeneralJournalLine('MIGRATION', '1', 'Document1', WorkDate(), WorkDate(), 123, 123, '', 'GL0001');
        VendorDataMigrationFacade.SetGeneralJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');

        // [THEN] The Genral Journal Line is Created
        // [THEN] The line's dimension is set
        GenJournalLine.SetRange("Journal Batch Name", 'MIGRATION');
        GenJournalLine.SetRange("Journal Template Name", 'MIGRATION');
        GenJournalLine.FindFirst();
        Assert.AreNotEqual('', GenJournalLine."Dimension Set ID", 'Dimension was expected to have been set');

        Assert.AreEqual('1', GenJournalLine."Document No.", 'A different document number was expected');
        Assert.AreEqual('Document1', GenJournalLine.Description, 'A different Description was expected');
        Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'A different Posting Date was expected');
        Assert.AreEqual(WorkDate(), GenJournalLine."Due Date", 'A different Due Date was expected');
        Assert.AreEqual(123, GenJournalLine.Amount, 'A different Amount was expected');
        Assert.AreEqual(123, GenJournalLine."Amount (LCY)", 'A different Amount LCY was expected');
        Assert.AreEqual('', GenJournalLine."Currency Code", 'A different Currency was expected');
        Assert.AreEqual('GL0001', GenJournalLine."Bal. Account No.", 'A different balance account was expected');

        // [THEN] Line can be posted
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateUpdateCustomer()
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Contact: Record Contact;
        PrimaryContact: Record Contact;
        Customer: Record Customer;
        PostCode: Record "Post Code";
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ShipmentMethod: Record "Shipment Method";
        CountryRegion: Record "Country/Region";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ExRateDataMigrationFacade: Codeunit "Ex. Rate Data Migration Facade";
        CustomerDataMigrationFacade: Codeunit "Customer Data Migration Facade";
        PaymentTermsFormula: DateFormula;
        LastModifiedDate: Date;
        LastModifiedDateTime: DateTime;
        CountryCode: Code[10];
        LanguageCode: Code[10];
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Customer can be created and updated
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] CreateCustomerIfNeeded is called
        CustomerDataMigrationFacade.CreateCustomerIfNeeded('CUST1', 'Name');

        // [THEN] Customer is created
        Assert.IsTrue(CustomerDataMigrationFacade.DoesCustomerExist('CUST1'), 'Customer was expected to have been created');
        Customer.Get('CUST1');
        Assert.AreEqual('Name', Customer.Name, 'A different name was expected');

        // [WHEN] The customer exists
        // [THEN] It is not created
        Assert.IsFalse(CustomerDataMigrationFacade.CreateCustomerIfNeeded('CUST1', 'Name'), '');

        // [THEN] Vendor dependencies can be created and updated
        CustomerDataMigrationFacade.CreateCountryIfNeeded('DK', 'Denmark', 1, 1);
        CountryRegion.Get('DK');
        Assert.AreEqual('Denmark', CountryRegion.Name, 'A diffrent name was expected');
        Assert.AreEqual(1, CountryRegion."Address Format", 'A different address format was expected');
        Assert.AreEqual(1, CountryRegion."Contact Address Format", 'A different format was expected');
        Assert.IsTrue(CustomerDataMigrationFacade.SearchCountry('DK', 'Denmark', '', '', CountryCode),
          'Country was expected to have been found');

        CustomerDataMigrationFacade.CreatePaymentMethodIfNeeded('PM', 'Payment Method');
        PaymentMethod.Get('PM');
        Assert.AreEqual('Payment Method', PaymentMethod.Description, 'A different description was expected');

        Evaluate(PaymentTermsFormula, '<14D>');
        CustomerDataMigrationFacade.CreatePaymentTermsIfNeeded('PT', 'Payment Terms', PaymentTermsFormula);
        PaymentTerms.Get('PT');
        Assert.AreEqual('Payment Terms', PaymentTerms.Description, 'A different description was expected');
        Assert.AreEqual(PaymentTermsFormula, PaymentTerms."Due Date Calculation", 'A different due date calculation was expected');

        Assert.IsTrue(CustomerDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'Lyngby', '', 'DK'),
          'Post Code was expected to be created');
        Assert.IsFalse(CustomerDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'Lyngby', '', 'DK'),
          'Post Code was not expected to be created');
        Assert.IsFalse(CustomerDataMigrationFacade.CreatePostCodeIfNeeded('2600', 'LYNGBY', '', 'DK'),
          'Post Code was not expected to be created');
        PostCode.Get('2600', 'Lyngby');
        Assert.IsTrue(CustomerDataMigrationFacade.DoesPostCodeExist('2600', 'Lyngby'), 'Post code was expected to have been created');
        Assert.AreEqual('DK', PostCode."Country/Region Code", 'A different Country region code was expected');

        CreateGLAcount('GL0001');
        CustomerDataMigrationFacade.CreatePostingSetupIfNeeded('CPG', 'Description', 'GL0001');
        CustomerPostingGroup.Get('CPG');
        Assert.AreEqual('GL0001', CustomerPostingGroup."Receivables Account", 'A different recievables account was expected.');

        CreateGLAcount('GL0002');
        CustomerDataMigrationFacade.CreatePostingSetupIfNeeded('CPG', 'Description', 'GL0002');
        CustomerPostingGroup.Get('CPG');
        Assert.AreEqual('GL0002', CustomerPostingGroup."Receivables Account", 'A different recievables account was expected.');

        CustomerDataMigrationFacade.CreateSalespersonPurchaserIfNeeded('SAL', 'SalesPerson', '123456789', '123@mail.com');
        SalespersonPurchaser.Get('SAL');
        Assert.AreEqual('SalesPerson', SalespersonPurchaser.Name, 'A different name was expected');
        Assert.AreEqual('123456789', SalespersonPurchaser."Phone No.", 'A different phone number was expected');
        Assert.AreEqual('123@mail.com', SalespersonPurchaser."E-Mail", 'A different email was expected');

        CustomerDataMigrationFacade.CreateShipmentMethodIfNeeded('SM', 'Shipment method');
        ShipmentMethod.Get('SM');
        Assert.AreEqual('Shipment method', ShipmentMethod.Description, 'A different description was expected');

        CustomerDataMigrationFacade.CreateCustomerDiscountGroupIfNeeded('CDG', 'Customer Discount Group');
        CustomerDiscountGroup.Get('CDG');
        Assert.AreEqual('Customer Discount Group', CustomerDiscountGroup.Description, 'A different description was expected');

        // [WHEN] CreateCustomerDiscountGroupIfNeeded is called again
        // [THEN] The previously created Group's code is returned
        Assert.AreEqual('CDG', CustomerDataMigrationFacade.CreateCustomerDiscountGroupIfNeeded('CDG', 'Customer Discount Group'),
          'A different Customer Discount Group was expected');

        CustomerDataMigrationFacade.CreateCustomerPriceGroupIfNeeded('CPG', 'Customer Price Group', true);
        CustomerPriceGroup.Get('CPG');
        Assert.AreEqual('Customer Price Group', CustomerPriceGroup.Description, 'A different description was expected');
        Assert.AreEqual(true, CustomerPriceGroup."Price Includes VAT", 'Prices including VAT was expected to be true');

        CustomerDataMigrationFacade.CreateCustomerIfNeeded('CUST2', 'Name2');
        Customer.Get('CUST2');
        Assert.AreEqual('Name2', Customer.Name, 'A different name was expected');

        Assert.IsTrue(CustomerDataMigrationFacade.SearchLanguage('DAN', LanguageCode), 'Danish languasge should have been found');

        // [GIVEN] Customer values are set
        CustomerDataMigrationFacade.SetGlobalCustomer('CUST1');
        CustomerDataMigrationFacade.SetAddress('Address1', 'Address2', 'DK', '2600', 'Lyngby');
        CustomerDataMigrationFacade.SetBlocked("Customer Blocked"::Ship);
        CustomerDataMigrationFacade.SetContact('Contact');
        CustomerDataMigrationFacade.SetCurrencyCode('DKK');
        CustomerDataMigrationFacade.SetInvoiceDiscCode('CDG');
        CustomerDataMigrationFacade.SetFaxNo('123456789');
        CustomerDataMigrationFacade.SetHomePage('Homepage');
        CustomerDataMigrationFacade.SetLanguageCode('DANISH');
        CustomerDataMigrationFacade.SetInvoiceDiscCode('CDG');
        CustomerDataMigrationFacade.SetPaymentTermsCode('PT');
        CustomerDataMigrationFacade.SetPhoneNo('123456789');
        CustomerDataMigrationFacade.SetSalesPersonCode('SAL');
        CustomerDataMigrationFacade.SetSearchName('Search Name');
        CustomerDataMigrationFacade.SetPaymentMethodCode('PM');
        CustomerDataMigrationFacade.SetShipmentMethodCode('SM');
        CustomerDataMigrationFacade.SetTelexNo('123456789');
        CustomerDataMigrationFacade.SetCustomerPriceGroup('CPG');
        CustomerDataMigrationFacade.SetVATRegistrationNo('12345678');
        CustomerDataMigrationFacade.SetCustomerPostingGroup('CPG');
        CustomerDataMigrationFacade.SetBillToCustomerNo('CUST2');
        CustomerDataMigrationFacade.SetCreditLimitLCY(1000);
        CustomerDataMigrationFacade.SetEmail('me@here.com');
        CustomerDataMigrationFacade.SetTaxLiable(true);

        // [WHEN] CustomerModify is called
        CustomerDataMigrationFacade.ModifyCustomer(true);

        // [THEN] The Customer is update
        Customer.Get('CUST1');
        Assert.AreEqual('Address1', Customer.Address, 'A different address was expected');
        Assert.AreEqual('Address2', Customer."Address 2", 'A different address was expected');
        Assert.AreEqual('Lyngby', Customer.City, 'A different city was expected');
        Assert.AreEqual('2600', Customer."Post Code", 'A different post code was expected');
        Assert.AreEqual('DK', Customer."Country/Region Code", 'A different country code was expected');
        Assert.AreEqual(1, Customer.Blocked, 'A different Blocked was expected.');
        Assert.AreEqual('Contact', Customer.Contact, 'A different contact was expected');
        Assert.AreEqual('DKK', Customer."Currency Code", 'A different currency code was expected');
        Assert.AreEqual('123456789', Customer."Fax No.", 'A diffrent fax number was expected');
        Assert.AreEqual('Homepage', Customer."Home Page", 'A different homepage was expected');
        Assert.AreEqual('DANISH', Customer."Language Code", 'A different language code was expected');
        Assert.AreEqual('CDG', Customer."Invoice Disc. Code", 'A different Invoice discount was expected');
        Assert.AreEqual('PT', Customer."Payment Terms Code", 'A different payment terms was expected');
        Assert.AreEqual('CUST2', Customer."Bill-to Customer No.", 'A different pay to vendor no was expected');
        Assert.AreEqual('123456789', Customer."Phone No.", 'A different phone number was expected');
        Assert.AreEqual('SAL', Customer."Salesperson Code", 'A different purchaser was expected');
        Assert.AreEqual('SEARCH NAME', Customer."Search Name", 'A different search name was expected');
        Assert.AreEqual('SM', Customer."Shipment Method Code", 'A different shipment method was expected');
        Assert.AreEqual('123456789', Customer."Telex No.", 'A different telex number was expected');
        Assert.AreEqual('12345678', Customer."VAT Registration No.", 'A different VAT registration number was expected');
        Assert.AreEqual('CPG', Customer."Customer Posting Group", 'A different Vendor Posting Group was expected');
        Assert.AreEqual('CPG', Customer."Customer Price Group", 'A different Vendor Price Group was expected');
        Assert.AreEqual(1000.0, Customer."Credit Limit (LCY)", 'Credit Limit LCY was expected to be 1000');
        Assert.AreEqual('PM', Customer."Payment Method Code", 'Payment Method was expected to be PM');
        Assert.AreEqual('me@here.com', Customer."E-Mail", 'A different email address was expected');
        Assert.AreEqual(true, Customer."Tax Liable", 'Tax Liable expected to be true');

        // [WHEN] The SetVendorAlternativeContact method is called
        CustomerDataMigrationFacade.SetCustomerAlternativeContact('Contact Name', 'Address', 'Address2', '2600', 'Lyngby', 'DK',
          'mail@mail.com', '123456789', '123456789', '123456789');

        // [THEN] A new Contact is created and is linked to Vendor
        Contact.SetRange(Name, 'Contact Name');
        Contact.FindFirst();
        Assert.AreEqual(Contact.Address, 'Address', 'The contact''s address was not set correctly');
        Assert.AreEqual(Contact."Address 2", 'Address2', 'The contact''s address2 was not set correctly');
        Assert.AreEqual(Contact."Post Code", '2600', 'The contact''s post code was not set correctly');
        Assert.AreEqual(Contact.City, 'Lyngby', 'The contact''s city was not set correctly');
        Assert.AreEqual(Contact."Country/Region Code", 'DK', 'The contact''s country was not set correctly');
        Assert.AreEqual(Contact."E-Mail", 'mail@mail.com', 'The contact''s email was not set correctly');
        Assert.AreEqual(Contact."Phone No.", '123456789', 'The contact''s phone was not set correctly');
        Assert.AreEqual(Contact."Fax No.", '123456789', 'The contact''s fax was not set correctly');
        Assert.AreEqual(Contact."Mobile Phone No.", '123456789', 'The contact''s mobile was not set correctly');
        PrimaryContact.SetRange(Name, 'Name');
        PrimaryContact.FindFirst();
        Assert.AreEqual(Contact."Company No.", PrimaryContact."No.", 'The Primary Contact was not set Correctly');
        Assert.AreEqual(Contact."Company Name", PrimaryContact.Name, 'The Primary Contact was not set Correctly');

        // [WHEN] The CreateDefaultDimensionAndRequirementsIfNeeded method is called
        CustomerDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DIM1', 'Description', 'VAL1', 'Value');

        // [THEN] The Dimension is created
        Dimension.Get('DIM1');
        Assert.AreEqual('Description', Dimension.Description, 'A different value was expected.');
        DimensionValue.Get('DIM1', 'VAL1');
        Assert.AreEqual('Value', DimensionValue.Name, 'A different value was expected.');

        // [GIVEN] A specific Date and Datetime to set
        LastModifiedDate := CalcDate('<-1D>', WorkDate());
        LastModifiedDateTime := CreateDateTime(LastModifiedDate, Time);

        CustomerDataMigrationFacade.SetLastDateModified(LastModifiedDate);
        CustomerDataMigrationFacade.SetLastModifiedDateTime(LastModifiedDateTime);

        // [WHEN] ModifyCustomer is called with FALSE
        CustomerDataMigrationFacade.ModifyCustomer(false);

        // [THEN] The given date and datetime values are set
        Customer.Get('CUST1');
        Assert.AreEqual(LastModifiedDate, Customer."Last Date Modified", 'A different date was expected');
        Assert.AreEqual(LastModifiedDateTime, Customer."Last Modified Date Time", 'A different datetime was expected');

        // [WHEN] CreateGeneralJournalBatchIfNeeded is called
        CustomerDataMigrationFacade.CreateGeneralJournalBatchIfNeeded('MIGRATION', '', '');

        // [THEN] The General Journal Batch and General Journal Template are Created
        GenJournalBatch.SetRange(Name, 'MIGRATION');
        Assert.RecordCount(GenJournalBatch, 1);
        GenJournalTemplate.SetRange(Name, 'Migration');
        Assert.RecordCount(GenJournalTemplate, 1);

        // [GIVEN] The Currency Exchange Rate exists
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('DKK', WorkDate(), 0.2, 0.2);

        // [WHEN] CreateGeneralJournalLine is called
        // [WHEN] SetGeneralJournalLineDimension is called
        CustomerDataMigrationFacade.CreateGeneralJournalLine('MIGRATION', '1', 'Document1', WorkDate(), WorkDate(), 123, 123, '', 'GL0001');
        CustomerDataMigrationFacade.SetGeneralJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');

        // [THEN] The Genral Journal Line is Created
        // [THEN] The line's dimension is set
        GenJournalLine.SetRange("Journal Batch Name", 'MIGRATION');
        GenJournalLine.SetRange("Journal Template Name", 'MIGRATION');
        GenJournalLine.FindFirst();
        Assert.AreNotEqual('', GenJournalLine."Dimension Set ID", 'Dimension was expected to have been set');

        Assert.AreEqual('1', GenJournalLine."Document No.", 'A different document number was expected');
        Assert.AreEqual('Document1', GenJournalLine.Description, 'A different Description was expected');
        Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'A different Posting Date was expected');
        Assert.AreEqual(WorkDate(), GenJournalLine."Due Date", 'A different Due Date was expected');
        Assert.AreEqual(123, GenJournalLine.Amount, 'A different Amount was expected');
        Assert.AreEqual(123, GenJournalLine."Amount (LCY)", 'A different Amount LCY was expected');
        Assert.AreEqual('', GenJournalLine."Currency Code", 'A different Currency was expected');
        Assert.AreEqual('GL0001', GenJournalLine."Bal. Account No.", 'A different balance account was expected');

        // [THEN] Line can be posted
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);

        // [WHEN] Customer Posting Group doesn't exist
        // [THEN] no error is thrown
        CustomerDataMigrationFacade.SetCustomerPostingGroupAccounts(
          '1', '', '', '', '', '', '', '', '', '', '', '', '', '', '');

        // [WHEN] Customer Posting Group does exist
        // [THEN] Accounts are updated
        CustomerDataMigrationFacade.SetCustomerPostingGroupAccounts(
          'CPG', 'GL0001', '', 'GL0001', '', '', '', '', '', '', '', '', '', '', '');
        CustomerPostingGroup.Get('CPG');
        Assert.AreEqual('GL0001', CustomerPostingGroup."Receivables Account", 'A different account was expected');
        Assert.AreEqual('GL0001', CustomerPostingGroup."Payment Disc. Debit Acc.", 'A different account was expected');

        // [WHEN] Setting additional General Journal Line fields
        // [THEN] no errors are thrown
        CustomerDataMigrationFacade.CreateGeneralJournalLine('MIGRATION', '2', 'Document2', WorkDate(), WorkDate(), 123, 123, '', 'GL0001');
        CustomerDataMigrationFacade.SetGeneralJournalLineDocumentType(DocumentType::Payment);
        CustomerDataMigrationFacade.SetGeneralJournalLineExternalDocumentNo('1234');
        CustomerDataMigrationFacade.SetGeneralJournalLineSourceCode('GENJNL');

        // [WHEN] Tax Area Code not valid
        // [THEN] Error is thrown
        asserterror CustomerDataMigrationFacade.SetTaxAreaCode('123');
        Assert.ExpectedError(TaxAreaCodeDoesNotExistErr);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    //[HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateUpdateItemsPriceDiscount()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ExRateDataMigrationFacade: Codeunit "Ex. Rate Data Migration Facade";
        ItemDataMigrationFacade: Codeunit "Item Data Migration Facade";
    begin
        // [SCENARIO] Price list line with header is created once
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] ExtendedPriceCalculation is enabled
        ExtendedPriceCalculationEnabled := true;
        if not BindSubscription(DataMigrationFacadeTests) then;

        // [GIVEN] Item 'ITEM1'
        ItemDataMigrationFacade.CreateItemIfNeeded('ITEM1', 'Description', 'Description2', "Item Type"::Inventory.AsInteger());
        // [GIVEN] The Currency Exchange Rate 'DKK'
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('DKK', WorkDate(), 0.2, 0.2);
        // [GIVEN] Customer Price Group 'CPG'
        ItemDataMigrationFacade.CreateCustomerPriceGroupIfNeeded('CPG', 'Customer Price Group', true);

        // [WHEN] CreateSalesPriceIfNeeded
        Assert.IsTrue(
            ItemDataMigrationFacade.CreateSalesPriceIfNeeded(1, 'CPG', 'ITEM1', 10, 'DKK', WorkDate(), '', 5, ''),
            'Sales Price was expected to have been created');

        // [THEN] Price List Line with header created, where "Amount Type" 'Price'
        Assert.IsTrue(PriceListLine.FindLast(), 'Price List Line for Price not found');
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", PriceListLine."Source Type"::"Customer Price Group");
        PriceListLine.TestField("Source No.", 'CPG');
        PriceListLine.TestField("Currency Code", 'DKK');
        PriceListLine.TestField("Starting Date", WorkDate());
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Item);
        PriceListLine.TestField("Asset No.", 'ITEM1');
        PriceListLine.TestField("Variant Code", '');
        PriceListLine.TestField("Unit of Measure Code", '');
        PriceListLine.TestField("Minimum Quantity", 5);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 10);
        PriceListLine.TestField("Line Discount %", 0);
        VerifyPriceListHeader(PriceListLine);

        // [THEN] Creation of the same price line, with another price should fail
        Assert.IsFalse(
            ItemDataMigrationFacade.CreateSalesPriceIfNeeded(1, 'CPG', 'ITEM1', 11, 'DKK', WorkDate(), '', 5, ''),
            'Sales Price was not expected to have been created');

        // [GIVEN] Customer Discount Group 'CDG'
        Assert.IsTrue(
            ItemDataMigrationFacade.CreateCustDiscGroupIfNeeded('CDG', 'Customer Discount Group'),
            'Customer Discount Group was expected to be created');
        // [GIVEN] Item Discount Group 'IDG'
        Assert.IsTrue(
            ItemDataMigrationFacade.CreateItemDiscGroupIfNeeded('IDG', 'Item Discount Group'),
            'Item Discount Group was expected to be created');

        // [WHEN] CreateSalesLineDiscountIfNeeded
        Assert.IsTrue(
            ItemDataMigrationFacade.CreateSalesLineDiscountIfNeeded(1, 'CDG', 1, 'IDG', 0.2),
            'Sales Line Discount was expected to have been created');

        // [THEN] Price List Line with header created, where "Amount Type" 'Discount'
        Assert.IsTrue(PriceListLine.FindLast(), 'Price List Line for Price not found');
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", PriceListLine."Source Type"::"Customer Disc. Group");
        PriceListLine.TestField("Source No.", 'CDG');
        PriceListLine.TestField("Currency Code", '');
        PriceListLine.TestField("Starting Date", 0D);
        PriceListLine.TestField("Asset Type", "Price Asset Type"::"Item Discount Group");
        PriceListLine.TestField("Asset No.", 'IDG');
        PriceListLine.TestField("Variant Code", '');
        PriceListLine.TestField("Unit of Measure Code", '');
        PriceListLine.TestField("Minimum Quantity", 0);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Line Discount %", 0.2);
        VerifyPriceListHeader(PriceListLine);

        // [THEN] Creation of the same discount line, with another discount should fail
        Assert.IsFalse(
            ItemDataMigrationFacade.CreateSalesLineDiscountIfNeeded(1, 'CDG', 1, 'IDG', 0.3),
            'Sales Line Discount was not expected to have been created');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateUpdateItem()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CustomerPriceGroup: Record "Customer Price Group";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemDiscountGroup: Record "Item Discount Group";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
        CustomerDiscountGroup: Record "Customer Discount Group";
        TariffNumber: Record "Tariff Number";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        ItemJournalLine: Record "Item Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        BOMComponent: Record "BOM Component";
        Resource: Record Resource;
        ItemDataMigrationFacade: Codeunit "Item Data Migration Facade";
        VendorDataMigrationFacade: Codeunit "Vendor Data Migration Facade";
        LastModifiedDate: Date;
        LastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [Item]
        // [SCENARIO] Item can be created and updated
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] CreateItemIfNeeded is called
        ItemDataMigrationFacade.CreateItemIfNeeded('ITEM1', 'Description', 'Description2', Item.Type::Inventory.AsInteger());

        // [THEN] Vendor is created
        Assert.IsTrue(ItemDataMigrationFacade.DoesItemExist('ITEM1'), 'Item was expected to have been created');
        Item.Get('ITEM1');
        Assert.AreEqual('Description', Item.Description, 'A different description was expected');
        Assert.AreEqual('Description2', Item."Description 2", 'A different description2 was expected');
        Assert.AreEqual(Item.Type::Inventory, Item.Type, 'A different type was expected');

        // [WHEN] The Vendor exists
        // [THEN] It is not created
        Assert.IsFalse(ItemDataMigrationFacade.CreateItemIfNeeded('ITEM1', 'Description', 'Description2', Item.Type::Inventory.AsInteger()),
          'Item should have not been created');

        // [THEN] Vendor dependencies can be created
        Assert.IsTrue(ItemDataMigrationFacade.CreateCustDiscGroupIfNeeded('CDG', 'Customer Discount Group'),
          'Customer Discount Group was expected to be created');
        CustomerDiscountGroup.Get('CDG');
        Assert.AreEqual('Customer Discount Group', CustomerDiscountGroup.Description, 'A different description was expected');
        Assert.IsFalse(ItemDataMigrationFacade.CreateCustDiscGroupIfNeeded('CDG', 'Customer Discount Group'),
          'Customer Discount Group was not expected to be created');

        ItemDataMigrationFacade.CreateCustomerPriceGroupIfNeeded('CPG', 'Customer Price Group', true);
        CustomerPriceGroup.Get('CPG');
        Assert.AreEqual('Customer Price Group', CustomerPriceGroup.Description, 'A different description was expected');
        Assert.IsTrue(CustomerPriceGroup."Price Includes VAT", 'Price Including VAT was expected to be TRUE');
        // Already existing Customer Price Group does not throw an error
        ItemDataMigrationFacade.CreateCustomerPriceGroupIfNeeded('CPG', 'Customer Price Group', true);

        Assert.IsTrue(ItemDataMigrationFacade.CreateItemDiscGroupIfNeeded('IDG', 'Item Discount Group'),
          'Item Discount Group was expected to be created');
        ItemDiscountGroup.Get('IDG');
        Assert.AreEqual('Item Discount Group', ItemDiscountGroup.Description, 'A different description was expected');
        Assert.IsFalse(ItemDataMigrationFacade.CreateItemDiscGroupIfNeeded('IDG', 'Item Discount Group'),
          'Item Discount Group was not expected to be created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateItemTrackingCodeIfNeeded('ITC', 'Item Tracking Code', true, true),
          'Item Tracking Code was expected to be created');
        ItemTrackingCode.Get('ITC');
        Assert.AreEqual('Item Tracking Code', ItemTrackingCode.Description, 'A different description was expected');
        Assert.IsTrue(ItemTrackingCode."Lot Specific Tracking", 'Lot Specific Tracking was expected to be true');
        Assert.IsTrue(ItemTrackingCode."SN Specific Tracking", 'SN Specific Tracking was expected to be true');
        Assert.IsFalse(ItemDataMigrationFacade.CreateItemTrackingCodeIfNeeded('ITC', 'Item Tracking Code', true, true),
          'Item Tracking Code was not expected to be created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateLocationIfNeeded('LOC', 'Location'), 'Location should have been created');
        Location.Get('LOC');
        Assert.AreEqual('Location', Location.Name, 'A different name was expected');
        Assert.IsFalse(ItemDataMigrationFacade.CreateLocationIfNeeded('LOC', 'Location'), 'Location should have not been created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateSalesLineDiscountIfNeeded(1, 'CDG', 1, 'IDG', 0.2),
          'Sales Line Discount was expected to have been created');
        SalesLineDiscount.SetRange("Sales Type", 1);
        SalesLineDiscount.SetRange(Type, 1);
        SalesLineDiscount.SetRange("Sales Code", 'CDG');
        SalesLineDiscount.SetRange(Code, 'IDG');
        SalesLineDiscount.FindFirst();
        Assert.AreEqual(0.2, SalesLineDiscount."Line Discount %", 'Line discount % was expected to be 0.2');
        Assert.IsFalse(ItemDataMigrationFacade.CreateSalesLineDiscountIfNeeded(1, 'CDG', 1, 'IDG', 0.2),
          'Sales Line Discount was not expected to have been created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateUnitOfMeasureIfNeeded('UOM', 'Desc.'),
          'Unit of Measure was expected to have been created');
        UnitOfMeasure.Get('UOM');
        Assert.AreEqual('Desc.', UnitOfMeasure.Description, 'A different description was expected');
        Assert.IsFalse(ItemDataMigrationFacade.CreateUnitOfMeasureIfNeeded('UOM', 'Desc.'),
          'Unit of Measure was not expected to have been created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateSalesPriceIfNeeded(1, 'CPG', 'ITEM1', 1, 'DKK', WorkDate(), '', 1, ''),
          'Sales Price was expected to have been created');
        SalesPrice.SetRange("Sales Type", 1);
        SalesPrice.SetRange("Sales Code", 'CPG');
        SalesPrice.SetRange("Item No.", 'ITEM1');
        SalesPrice.SetRange("Unit of Measure Code", '');
        SalesPrice.SetRange("Starting Date", WorkDate());
        SalesPrice.SetRange("Variant Code", '');
        SalesPrice.SetRange("Minimum Quantity", 1);
        SalesPrice.SetRange("Currency Code", 'DKK');
        SalesPrice.FindFirst();
        Assert.AreEqual(1, SalesPrice."Unit Price", 'A different unit price was expected');
        Assert.IsFalse(ItemDataMigrationFacade.CreateSalesPriceIfNeeded(1, 'CPG', 'ITEM1', 1, 'DKK', WorkDate(), '', 1, ''),
          'Sales Price was not expected to have been created');

        Assert.IsTrue(ItemDataMigrationFacade.CreateTariffNumberIfNeeded('TN', 'Tariff Number', true),
          'Tariff Number was expected to have been created');
        TariffNumber.Get('TN');
        Assert.AreEqual('Tariff Number', TariffNumber.Description, 'A different description was expected');
        Assert.IsTrue(TariffNumber."Supplementary Units", 'Supplementary units was expected to be true');
        Assert.IsFalse(ItemDataMigrationFacade.CreateTariffNumberIfNeeded('TN', 'Tariff Number', true),
          'Tariff Number was not expected to have been created');

        ItemDataMigrationFacade.CreateItemIfNeeded('ITEM2', 'Description', 'Description2', Item.Type::Inventory.AsInteger());
        VendorDataMigrationFacade.CreateVendorIfNeeded('VEND1', '');

        // [GIVEN] The Bom Components exist
        ItemDataMigrationFacade.CreateItemIfNeeded('BOM1', 'BOM1 Description', 'Description2', Item.Type::Inventory.AsInteger());
        Resource.Init();
        Resource."No." := 'BOM2';
        Resource.Name := 'BOM2 Description';
        Resource.Insert();

        ItemDataMigrationFacade.SetGlobalItem('ITEM1');

        // [WHEN] The CreateBOMComponent function is called
        ItemDataMigrationFacade.CreateBOMComponent('BOM1', 1, '', BOMComponent.Type::Item.AsInteger());
        ItemDataMigrationFacade.CreateBOMComponent('BOM2', 2, '', BOMComponent.Type::Resource.AsInteger());

        // [THEN] The BOMComponent Tables is populated
        BOMComponent.SetRange("Parent Item No.", 'ITEM1');
        Assert.RecordCount(BOMComponent, 2);

        BOMComponent.Get('ITEM1', 1000);
        Assert.AreEqual('BOM1', BOMComponent."No.", 'A different BOM No. was expected.');
        Assert.AreEqual(Format(BOMComponent.Type::Item), Format(BOMComponent.Type), 'A different BOM type was expected.');
        Assert.AreEqual('BOM1 Description', BOMComponent.Description, 'A different BOM description was expected.');

        BOMComponent.Get('ITEM1', 2000);
        Assert.AreEqual('BOM2', BOMComponent."No.", 'A different BOM No. was expected.');
        Assert.AreEqual(Format(BOMComponent.Type::Resource), Format(BOMComponent.Type), 'A different BOM type was expected.');
        Assert.AreEqual('BOM2 Description', BOMComponent.Description, 'A different BOM description was expected.');

        // [GIVEN] Item details have been set
        ItemDataMigrationFacade.SetAlternativeItemNo('ITEM2');
        ItemDataMigrationFacade.SetBaseUnitOfMeasure('UOM');
        ItemDataMigrationFacade.SetBlocked(true);
        ItemDataMigrationFacade.SetCostingMethod(Item."Costing Method"::Average.AsInteger());
        ItemDataMigrationFacade.SetItemDiscGroup('IDG');
        ItemDataMigrationFacade.SetItemTrackingCode('ITC');
        ItemDataMigrationFacade.SetNetWeight(1);
        ItemDataMigrationFacade.SetPreventNegativeInventory(true);
        ItemDataMigrationFacade.SetReorderQuantity(2);
        ItemDataMigrationFacade.SetStandardCost(3);
        ItemDataMigrationFacade.SetStockoutWarning(true);
        ItemDataMigrationFacade.SetTariffNo('TN');
        ItemDataMigrationFacade.SetUnitCost(4);
        ItemDataMigrationFacade.SetUnitVolume(5);
        ItemDataMigrationFacade.SetVendorItemNo('VIN');
        ItemDataMigrationFacade.SetVendorNo('VEND1');

        // [WHEN] ModifyItem is called
        ItemDataMigrationFacade.ModifyItem(true);

        // [THEN] The Item has the appropriate values
        Item.Get('ITEM1');
        Assert.AreEqual('ITEM2', Item."Alternative Item No.", 'A different item number was expected');
        Assert.AreEqual('UOM', Item."Base Unit of Measure", 'A different unit of measure was expected');
        Assert.IsTrue(Item.Blocked, 'Item was expected blocked');
        Assert.AreEqual(Item."Costing Method"::Average, Item."Costing Method", 'A different costing method was expected');
        Assert.AreEqual('IDG', Item."Item Disc. Group", 'A different item discount group was expected');
        Assert.AreEqual('ITC', Item."Item Tracking Code", 'A different item tracking code was expected');
        Assert.AreEqual(1, Item."Net Weight", 'A different net weight was expected');
        Assert.AreEqual(Item."Prevent Negative Inventory"::Yes, Item."Prevent Negative Inventory",
          'Prevent negative inventory was expected to be Yes');
        Assert.AreEqual(2, Item."Reorder Quantity", 'Reorder quantity was expected to be 2');
        Assert.AreEqual(3, Item."Standard Cost", 'Standard cost was expected to be 3');
        Assert.AreEqual(Item."Stockout Warning"::Yes, Item."Stockout Warning", 'Stockout warning was expected to be Yes');
        Assert.AreEqual('TN', Item."Tariff No.", 'Tariff No. was expected to be TN');
        Assert.AreEqual(4, Item."Unit Cost", 'Item unit cost was expected to be 4');
        Assert.AreEqual(5, Item."Unit Volume", 'Item unit volume was expected to be 5');
        Assert.AreEqual('VIN', Item."Vendor Item No.", 'Vendor Item Number was expected to be VIN');
        Assert.AreEqual('VEND1', Item."Vendor No.", 'Vendor Number was expected to be VEND1');

        ItemDataMigrationFacade.SetPreventNegativeInventory(false);
        ItemDataMigrationFacade.SetStockoutWarning(false);
        ItemDataMigrationFacade.ModifyItem(true);

        Item.Get('ITEM1');
        Assert.AreEqual(Item."Prevent Negative Inventory"::No, Item."Prevent Negative Inventory",
          'Prevent negative inventory was expected to be No');
        Assert.AreEqual(Item."Stockout Warning"::No, Item."Stockout Warning", 'Stockout warning was expected to be No');

        // [WHEN] The CreateDefaultDimensionAndRequirementsIfNeeded method is called
        ItemDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DIM1', 'Description', 'VAL1', 'Value');

        // [THEN] The Dimension is created
        Dimension.Get('DIM1');
        Assert.AreEqual('Description', Dimension.Description, 'A different value was expected.');
        DimensionValue.Get('DIM1', 'VAL1');
        Assert.AreEqual('Value', DimensionValue.Name, 'A different value was expected.');

        // [GIVEN] A specific Date and Datetime to set
        LastModifiedDate := CalcDate('<-1D>', WorkDate());
        LastModifiedDateTime := CreateDateTime(LastModifiedDate, Time);

        ItemDataMigrationFacade.SetLastDateModified(LastModifiedDate);
        ItemDataMigrationFacade.SetLastModifiedDateTime(LastModifiedDateTime);

        // [WHEN] ModifyItem is called with parameter FALSE
        ItemDataMigrationFacade.ModifyItem(false);

        // [THEN] Item has the set values
        Item.Get('ITEM1');
        Assert.AreEqual(LastModifiedDate, Item."Last Date Modified", 'A different date was expected');
        Assert.AreEqual(LastModifiedDateTime, Item."Last DateTime Modified", 'A different DateTime was expected');

        // [GIVEN] The related entities are created
        CreateGLAcount('GL0001');
        CreateGLAcount('GL0002');

        Assert.IsTrue(ItemDataMigrationFacade.CreateGeneralProductPostingSetupIfNeeded('GPPG', 'General Product Posting Group', ''),
          'General Product Posting Group was expected to be created');
        GenProductPostingGroup.Get('GPPG');
        Assert.AreEqual('General Product Posting Group', GenProductPostingGroup.Description, 'A diiferent description was expecetd');
        GeneralPostingSetup.Get('', 'GPPG');
        Assert.IsFalse(ItemDataMigrationFacade.CreateGeneralProductPostingSetupIfNeeded('GPPG', 'General Product Posting Group', ''),
          'General Product Posting Group was not expected to be created');
        ItemDataMigrationFacade.SetGeneralPostingSetupInventoryAdjmntAccount('GPPG', '', 'GL0001');
        GeneralPostingSetup.Get('', 'GPPG');
        Assert.AreEqual('GL0001', GeneralPostingSetup."Inventory Adjmt. Account", 'A different Account was expected');

        Assert.IsTrue(ItemDataMigrationFacade.CreateInventoryPostingSetupIfNeeded('IPG', 'Inventory Posting Group', 'LOC'),
          'Inventory posting setup was expected to be created');
        InventoryPostingGroup.Get('IPG');
        Assert.AreEqual('Inventory Posting Group', InventoryPostingGroup.Description, 'A different posting group was expected');
        InventoryPostingSetup.Get('LOC', 'IPG');
        Assert.IsFalse(ItemDataMigrationFacade.CreateInventoryPostingSetupIfNeeded('IPG', 'Inventory Posting Group', 'LOC'),
          'Inventory posting setup was not expected to be created');

        ItemDataMigrationFacade.SetInventoryPostingSetupInventoryAccount('IPG', 'LOC', 'GL0002');
        InventoryPostingSetup.Get('LOC', 'IPG');
        Assert.AreEqual('GL0002', InventoryPostingSetup."Inventory Account", 'A different account was expected');

        ItemDataMigrationFacade.SetGeneralProductPostingGroup('GPPG');
        ItemDataMigrationFacade.SetInventoryPostingGroup('IPG');

        // [WHEN] ModifyItem is called
        ItemDataMigrationFacade.ModifyItem(true);

        // [THEM] Item posting setup is set
        Item.Get('ITEM1');
        Assert.AreEqual('GPPG', Item."Gen. Prod. Posting Group", 'A different General Posting Group was expected');
        Assert.AreEqual('IPG', Item."Inventory Posting Group", 'A different Inventory Posting Group was expected');

        // [GIVEN] The required entities have been created
        ItemDataMigrationFacade.CreateItemJournalBatchIfNeeded('IJB', '', '');
        ItemJournalBatch.SetRange(Name, 'IJB');
        ItemJournalBatch.FindFirst();

        ItemDataMigrationFacade.SetBlocked(false);
        ItemDataMigrationFacade.ModifyItem(true);

        // [WHEN] CreateItemJournalLine is called
        ItemDataMigrationFacade.CreateItemJournalLine('IJB', 'DOC1', 'Description', WorkDate(), 1, 2, 'LOC', 'GPPG');

        // [THEN] the Item Journal line is created
        ItemJournalLine.SetRange("Journal Batch Name", 'IJB');
        ItemJournalLine.FindFirst();
        Assert.AreEqual('DOC1', ItemJournalLine."Document No.", 'A different Document Number was expected');
        Assert.AreEqual('Description', ItemJournalLine.Description, 'A different Description was expected');
        Assert.AreEqual(WorkDate(), ItemJournalLine."Posting Date", 'A different posting date was expected');
        Assert.AreEqual(1, ItemJournalLine.Quantity, 'A different quantity was expected');
        Assert.AreEqual(2, ItemJournalLine.Amount, 'A different amount was expected');
        Assert.AreEqual('LOC', ItemJournalLine."Location Code", 'A different location was expected');
        Assert.AreEqual('GPPG', ItemJournalLine."Gen. Prod. Posting Group", 'A different general product posting group was expected');

        // [WHEN] SetItemJournalLineDimension is called
        ItemDataMigrationFacade.SetItemJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');

        // [THEN] The dimension is created
        ItemJournalLine.SetRange("Journal Batch Name", 'IJB');
        ItemJournalLine.FindFirst();
        Assert.AreNotEqual('', ItemJournalLine."Dimension Set ID", 'Dimension Set should not be empty');

        // [WHEN] Serial Number and Lot Number are set
        ItemDataMigrationFacade.SetItemJournalLineItemTracking('SN', 'LN');

        // [THEN] The Line Can be Posted
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", ItemJournalLine);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateUpdateGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccDataMigrationFacade: Codeunit "GL Acc. Data Migration Facade";
        LastModifiedDate: Date;
        LastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO] Account can be created and updated
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [THEN] Account can be created
        Assert.IsTrue(GLAccDataMigrationFacade.CreateGLAccountIfNeeded('0003', 'Name', 2), 'Account was expected to be created');
        GLAccount.Get('0003');
        Assert.AreEqual('Name', GLAccount.Name, 'A different name was expected');
        Assert.AreEqual(2, GLAccount."Account Type", 'A different account type was expected');
        Assert.IsFalse(GLAccDataMigrationFacade.CreateGLAccountIfNeeded('0003', 'Name', 2), 'Account was not expected to be created');

        // [GIVEN] The account properties have been set
        GLAccDataMigrationFacade.SetGlobalGLAccount('0003');
        GLAccDataMigrationFacade.SetBlocked(true);
        GLAccDataMigrationFacade.SetDebitCreditType(1);
        GLAccDataMigrationFacade.SetDirectPosting(true);
        GLAccDataMigrationFacade.SetExchangeRateAdjustmentType(1);
        GLAccDataMigrationFacade.SetIncomeBalanceType(1);
        GLAccDataMigrationFacade.SetTotaling('0003');
        GLAccDataMigrationFacade.SetAccountCategory(1);
        GLAccDataMigrationFacade.SetAccountSubCategory(1);

        // [WHEN] ModifyAccount is called
        GLAccDataMigrationFacade.ModifyGLAccount(true);

        // [THEN] Account is updated
        GLAccount.Get('0003');
        Assert.IsTrue(GLAccount.Blocked, 'Account was expected Blocked');
        Assert.AreEqual(1, GLAccount."Debit/Credit", 'A different debit credit was expected');
        Assert.IsTrue(GLAccount."Direct Posting", 'Direct Posting was expected to be TRUE');
        Assert.AreEqual(1, GLAccount."Exchange Rate Adjustment", 'A different Exchange Rate Adjustment was expected');
        Assert.AreEqual(1, GLAccount."Income/Balance", 'A different Income/Balance type was expected');
        Assert.AreEqual('0003', GLAccount.Totaling, 'A different Totaling was expected');

        // [THEN] Posting groups can be created
        GLAccDataMigrationFacade.CreateGenBusinessPostingGroupIfNeeded('PC', 'PC');
        GLAccDataMigrationFacade.CreateGenProductPostingGroupIfNeeded('PC', 'PC');
        GLAccDataMigrationFacade.CreateGeneralPostingSetupIfNeeded('PC');

        // [THEN] Posting groups are not re-created
        GLAccDataMigrationFacade.CreateGenBusinessPostingGroupIfNeeded('PC', 'PC');
        GLAccDataMigrationFacade.CreateGenProductPostingGroupIfNeeded('PC', 'PC');
        GLAccDataMigrationFacade.CreateGeneralPostingSetupIfNeeded('PC');

        // [THEN] General Journal Batch can be created
        GLAccDataMigrationFacade.CreateGeneralJournalBatchIfNeeded('GJB', '', '');
        GLAccDataMigrationFacade.CreateGeneralJournalBatchIfNeeded('GJB', '', '');

        // [GIVEN] The calues are set
        LastModifiedDate := CalcDate('<-1D>', WorkDate());
        LastModifiedDateTime := CreateDateTime(LastModifiedDate, Time);

        GLAccDataMigrationFacade.SetLastDateModified(LastModifiedDate);
        GLAccDataMigrationFacade.SetLastModifiedDateTime(LastModifiedDateTime);

        // [WHEN] ModifyAccount is called with FALSE
        GLAccDataMigrationFacade.ModifyGLAccount(false);

        // [THEN] Account is updated
        GLAccount.Get('0003');
        Assert.AreEqual(LastModifiedDate, GLAccount."Last Date Modified", 'A different Last modified date was expected');
        Assert.AreEqual(LastModifiedDateTime, GLAccount."Last Modified Date Time", 'A different Last modified DateTime was expected');

        // [GIVEN] New account created
        GLAccDataMigrationFacade.CreateGLAccountIfNeeded('0010', '0010', 0);

        // [WHEN] Posting accounts are set
        // [THEN] no errors are thrown
        GLAccDataMigrationFacade.SetGeneralPostingSetupSalesAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupSalesLineDiscAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupSalesInvDiscAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupSalesPmtDiscDebitAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchLineDiscAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchInvDiscAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchCreditMemoAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupCOGSAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupInventoryAdjmtAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupSalesCreditMemoAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchPmtDiscDebitAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchPrepaymentsAccount('PC', '0010');
        GLAccDataMigrationFacade.SetGeneralPostingSetupPurchaseVarianceAccount('PC', '0010');

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestMigrateExchangeRates()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExRateDataMigrationFacade: Codeunit "Ex. Rate Data Migration Facade";
    begin
        // [FEATURE] [Exchange Rate]
        // [SCENARIO] Exchange Rates Can be created
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();
        // [WHEN] CreateSimpleExchangeRateIfNeeded is called
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('DKK', WorkDate(), 0.2, 0.2);

        // [THEN] Exchange rate is created
        CurrencyExchangeRate.Get('DKK', WorkDate());
        Assert.AreEqual(0.2, CurrencyExchangeRate."Relational Exch. Rate Amount",
          'A differentRelational Exch. Rate Amount was expected');
        Assert.AreEqual(0.2, CurrencyExchangeRate."Exchange Rate Amount", 'A different Exchange Rate Amount was expected');
        // Already existing does not throw error
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('DKK', WorkDate(), 0.2, 0.2);

        // [WHEN] CreateSimpleExchangeRateIfNeeded is called for local currency
        ExRateDataMigrationFacade.CreateSimpleExchangeRateIfNeeded('MYC', WorkDate(), 0.2, 0.2);

        // [THEN] The exchange rate is not created
        CurrencyExchangeRate.SetRange("Currency Code", 'MYC');
        CurrencyExchangeRate.SetRange("Starting Date", WorkDate());
        Assert.RecordIsEmpty(CurrencyExchangeRate);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTryUpdateVendor()
    var
        VendorDataMigrationFacade: Codeunit "Vendor Data Migration Facade";
        DummyLastModifiedDate: Date;
        DummyLastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO] Vendor must be created first
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] Vendor properties or dependencies are attempted to be created
        // [THEN] An error is thrown
        asserterror VendorDataMigrationFacade.SetAddress('Address1', 'Address2', 'DK', '2600', 'Lyngby');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetBlocked("Vendor Blocked"::Payment);
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetContact('Contact');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetCurrencyCode('DKK');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetFaxNo('123456789');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetHomePage('Homepage');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetLanguageCode('DANISH');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetInvoiceDiscCode('VID');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetOurAccountNo('GL0001');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetPaymentTermsCode('PT');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetPayToVendorNo('VEND2');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetPhoneNo('123456789');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetPurchaserCode('PURCH');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetSearchName('Search Name');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetShipmentMethodCode('SM');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetTelexNo('123456789');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetVATRegistrationNo('12345678');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetVendorPostingGroup('VPG');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DIM1', 'Description', 'VAL1', 'Value');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetLastDateModified(DummyLastModifiedDate);
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetLastModifiedDateTime(DummyLastModifiedDateTime);
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.ModifyVendor(true);
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetGeneralJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror VendorDataMigrationFacade.SetGeneralJournalLineDocumentType(1);
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror VendorDataMigrationFacade.SetGeneralJournalLineBalAccountNo('123');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror VendorDataMigrationFacade.SetGeneralJournalLineSourceCode('123');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror VendorDataMigrationFacade.SetGeneralJournalLineExternalDocumentNo('123');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror VendorDataMigrationFacade.SetPaymentMethod('123');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetGenBusPostingGroup('123');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetEmail('123');
        Assert.ExpectedError(InteralVendorNotSetErr);
        asserterror VendorDataMigrationFacade.SetVendorAlternativeContact('Contact Name', 'Address', 'Address2', '1234', 'Lyngby', 'DK',
            'mail@mail.com', '123456789', '123456789', '123456789');
        Assert.ExpectedError(InteralVendorNotSetErr);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTryUpdateCustomer()
    var
        CustomerDataMigrationFacade: Codeunit "Customer Data Migration Facade";
        DummyLastModifiedDate: Date;
        DummyLastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Customer must be created first
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] Customer properties or dependencies are attempted to be created
        // [THEN] An error is thrown
        asserterror CustomerDataMigrationFacade.SetAddress('Address1', 'Address2', 'DK', '2600', 'Lyngby');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetBlocked("Customer Blocked"::Ship);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetContact('Contact');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetCurrencyCode('DKK');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetInvoiceDiscCode('CDG');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetFaxNo('123456789');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetHomePage('Homepage');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetLanguageCode('DANISH');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetInvoiceDiscCode('CDG');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetPaymentTermsCode('PT');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetPhoneNo('123456789');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetSalesPersonCode('SAL');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetSearchName('Search Name');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetShipmentMethodCode('SM');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetTelexNo('123456789');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetCustomerPriceGroup('CPG');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetVATRegistrationNo('12345678');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetCustomerPostingGroup('CPG');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetBillToCustomerNo('CUST2');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetCreditLimitLCY(1000);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.ModifyCustomer(true);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetLastDateModified(DummyLastModifiedDate);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetLastModifiedDateTime(DummyLastModifiedDateTime);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DIM1', 'Description', 'VAL1', 'Value');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetPaymentMethodCode('PM');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetGeneralJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror CustomerDataMigrationFacade.SetGeneralJournalLineDocumentType(1);
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror CustomerDataMigrationFacade.SetGeneralJournalLineSourceCode('1');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror CustomerDataMigrationFacade.SetGeneralJournalLineExternalDocumentNo('1');
        Assert.ExpectedError(InternalGenJournalLineNotSetErr);
        asserterror CustomerDataMigrationFacade.SetGenBusPostingGroup('1');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetTaxLiable(true);
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetTaxAreaCode('1');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetEmail('1');
        Assert.ExpectedError(InternalCustomerNotSetErr);
        asserterror CustomerDataMigrationFacade.SetCustomerAlternativeContact('Contact Name', 'Address', 'Address2', '2600', 'Lyngby',
            'DK', 'mail@mail.com', '123456789', '123456789', '123456789');
        Assert.ExpectedError(InternalCustomerNotSetErr);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestGLAccountMigration()
    var
        DataMigrationParameters: Record "Data Migration Parameters";
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO] A series of events are fired in the correct order
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        DataMigrationParameters.Init();
        DataMigrationParameters.Insert();

        CODEUNIT.Run(CODEUNIT::"GL Acc. Data Migration Facade");

        Assert.AreEqual('Migrate G/L Account', LibraryVariableStorage.DequeueText(), 'OnMigrateGLAccount event was expected');

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestVendorMigration()
    var
        DataMigrationParameters: Record "Data Migration Parameters";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO] A series of events are fired in the correct order
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        DataMigrationParameters.Init();
        DataMigrationParameters.Insert();

        CODEUNIT.Run(CODEUNIT::"Vendor Data Migration Facade");

        Assert.AreEqual('Migrate Vendor', LibraryVariableStorage.DequeueText(), 'OnMigrateVendor event was expected');
        Assert.AreEqual('Migrate Vendor Dimensions', LibraryVariableStorage.DequeueText(),
          'OnMigrateVendorDimensions event was expected');
        Assert.AreEqual('Migrate Vendor Posting Groups', LibraryVariableStorage.DequeueText(),
          'OnMigrateVendorPostingGroups event was expected');
        Assert.AreEqual('Migrate Vendor Transactions', LibraryVariableStorage.DequeueText(),
          'OnMigrateVendorTransction event was expected');

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCustomerMigration()
    var
        DataMigrationParameters: Record "Data Migration Parameters";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] A series of events are fired in the correct order
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        DataMigrationParameters.Init();
        DataMigrationParameters.Insert();

        CODEUNIT.Run(CODEUNIT::"Customer Data Migration Facade");

        Assert.AreEqual('Migrate Customer', LibraryVariableStorage.DequeueText(), 'OnMigratedCustomer event was expected');
        Assert.AreEqual('Migrate Customer Dimensions', LibraryVariableStorage.DequeueText(),
          'OnMigratedCustomerDimensions event was expected');
        Assert.AreEqual('Migrate Customer Posting Groups', LibraryVariableStorage.DequeueText(),
          'OnMigratedCustomerPostingGroups event was expected');
        Assert.AreEqual('Migrate Customer Transactions', LibraryVariableStorage.DequeueText(),
          'OnMigratedCustomerTransction event was expected');

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestItemMigration()
    var
        DataMigrationParameters: Record "Data Migration Parameters";
    begin
        // [FEATURE] [Item]
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        DataMigrationParameters.Init();
        DataMigrationParameters.Insert();

        CODEUNIT.Run(CODEUNIT::"Item Data Migration Facade");

        Assert.AreEqual('Migrate Item', LibraryVariableStorage.DequeueText(), 'OnMigrateItem event was expected');
        Assert.AreEqual('Migrate Item Tracking Code', LibraryVariableStorage.DequeueText(),
          'OnMigrateTrackingCode event was expected');
        Assert.AreEqual('Migrate Item Costing Method', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemCostingMethod event was expected');
        Assert.AreEqual('Migrate Item Unit Of Measure', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemUnitOfMeasure event was expected');
        Assert.AreEqual('Migrate Item Discount Group', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemDiscountGroup event was expected');
        Assert.AreEqual('Migrate Sales Line Discount', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemSalesLineDiscount event was expected');
        Assert.AreEqual('Migrate Item Price', LibraryVariableStorage.DequeueText(), 'OnMigrateItemPrice event was expected');
        Assert.AreEqual('Migrate Item Tariff Number', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemTariffNo event was expected');
        Assert.AreEqual('Migrate Item Dimensions', LibraryVariableStorage.DequeueText(), 'OnMigrateItemDimensions event was expected');
        Assert.AreEqual('Migrate Item Posting Setup', LibraryVariableStorage.DequeueText(),
          'OnMigrateItemPostingGroups event was expected');
        Assert.AreEqual('Migrate Item Transactions', LibraryVariableStorage.DequeueText(),
          'OnMigrateInventoryTransactions event was expected');

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTryUpdateGLAccount()
    var
        GLAccDataMigrationFacade: Codeunit "GL Acc. Data Migration Facade";
        DummyLastModifiedDate: Date;
        DummyLastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO] G/L Account must be created first
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] Account properties or dependencies are attempted to be created
        // [THEN] An error is thrown
        asserterror GLAccDataMigrationFacade.SetBlocked(true);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetDebitCreditType(1);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetDirectPosting(true);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetExchangeRateAdjustmentType(1);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetIncomeBalanceType(1);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetLastDateModified(DummyLastModifiedDate);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetLastModifiedDateTime(DummyLastModifiedDateTime);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetTotaling('123');
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.ModifyGLAccount(true);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetAccountCategory(1);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetAccountSubCategory(1);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetBlocked(true);
        Assert.ExpectedError(InternalGLAccountNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupCOGSAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupInventoryAdjmtAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchCreditMemoAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchInvDiscAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchLineDiscAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupSalesAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupSalesCreditMemoAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupSalesInvDiscAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupSalesLineDiscAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupSalesPmtDiscDebitAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchPmtDiscDebitAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchPrepaymentsAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);
        asserterror GLAccDataMigrationFacade.SetGeneralPostingSetupPurchaseVarianceAccount('1', '1');
        Assert.ExpectedError(InternalGeneralPostingSetupNotSetErr);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTryUpdateItem()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        ItemDataMigrationFacade: Codeunit "Item Data Migration Facade";
        DummyLastModifiedDate: Date;
        DummyLastModifiedDateTime: DateTime;
    begin
        // [FEATURE] [Item]
        // [SCENARIO] Item must be created first
        if not BindSubscription(DataMigrationFacadeTests) then;

        Initialize();

        // [WHEN] Item properties or dependencies are attempted to be created
        // [THEN] An error is thrown
        asserterror ItemDataMigrationFacade.SetAlternativeItemNo('ITEM2');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetBaseUnitOfMeasure('UOM');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetBlocked(true);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetCostingMethod(Item."Costing Method"::Average.AsInteger());
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetItemDiscGroup('IDG');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetItemTrackingCode('ITC');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetNetWeight(1);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetPreventNegativeInventory(true);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetReorderQuantity(2);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetStandardCost(3);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetStockoutWarning(true);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetTariffNo('TN');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetUnitCost(4);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetUnitVolume(5);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetVendorItemNo('VIN');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetVendorNo('VEND1');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.CreateDefaultDimensionAndRequirementsIfNeeded('DEPARTMENT', 'Department', 'SALES', 'Sales');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetGeneralProductPostingGroup('GPPG');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetInventoryPostingGroup('IPG');
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetLastDateModified(DummyLastModifiedDate);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetLastModifiedDateTime(DummyLastModifiedDateTime);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.ModifyItem(true);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.SetItemJournalLineItemTracking('SN', 'LT');
        Assert.ExpectedError(InternalItemJnlLIneNotSetErr);
        asserterror ItemDataMigrationFacade.SetItemJournalLineDimension('DEPARTMENT', 'Department', 'SALES', 'Sales');
        Assert.ExpectedError(InternalItemJnlLIneNotSetErr);
        asserterror ItemDataMigrationFacade.SetUnitPrice(10.0);
        Assert.ExpectedError(InternalItemNotSetErr);
        asserterror ItemDataMigrationFacade.CreateBOMComponent('BOM1', 1, '', BOMComponent.Type::Item.AsInteger());
        Assert.ExpectedError(InternalItemNotSetErr);

        UnbindSubscription(DataMigrationFacadeTests);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        CustomerPriceGroup: Record "Customer Price Group";
        GLAccount: Record "G/L Account";
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        Customer: Record Customer;
        Currency: Record Currency;
        Language: Record Language;
        ItemDiscountGroup: Record "Item Discount Group";
        ItemJournalTemplate: Record "Item Journal Template";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        PostCode: Record "Post Code";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Clear(DataMigrationFacadeTests);
        Clear(LibraryVariableStorage);
        ExtendedPriceCalculationEnabled := false;

        GLAccount.DeleteAll();
        CustomerPostingGroup.DeleteAll();
        VendorPostingGroup.DeleteAll();
        CountryRegion.DeleteAll();
        Customer.DeleteAll();
        Vendor.DeleteAll();
        Currency.DeleteAll();
        Language.DeleteAll();
        GenJournalTemplate.DeleteAll();
        GenJournalLine.DeleteAll();
        CustomerDiscountGroup.DeleteAll();
        CustomerPriceGroup.DeleteAll();
        ItemDiscountGroup.DeleteAll();
        ItemJournalTemplate.DeleteAll();
        GeneralLedgerSetup.DeleteAll();
        GenJournalBatch.DeleteAll();
        PostCode.DeleteAll();
        CurrencyExchangeRate.DeleteAll();
        GeneralPostingSetup.DeleteAll();
        GenBusinessPostingGroup.DeleteAll();
        GenProductPostingGroup.DeleteAll();

        Currency.Init();
        Currency.Validate(Code, 'DKK');
        Currency.Insert(true);

        Currency.Init();
        Currency.Validate(Code, 'MYC');
        Currency.Insert(true);

        Language.Init();
        Language.Validate(Code, 'DANISH');
        Language.Validate("Windows Language ID", 1030);
        Language.Insert(true);

        GeneralLedgerSetup.Init();
        GeneralLedgerSetup."LCY Code" := 'MYC';
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 1;
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup.Insert();
    end;

    local procedure CreateGLAcount(AccountNo: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount.Insert();
    end;

    local procedure VerifyPriceListHeader(PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.Get(PriceListLine."Price List Code");
        PriceListHeader.TestField("Source Group", "Price Source Group"::Customer);
        PriceListHeader.TestField("Price Type", "Price Type"::Sale);
        PriceListHeader.TestField("Amount Type", PriceListLine."Amount Type");
        PriceListHeader.TestField("Source Type", PriceListLine."Source Type");
        PriceListHeader.TestField("Source ID", PriceListLine."Source ID");
        PriceListHeader.TestField("Currency Code", PriceListLine."Currency Code");
        PriceListHeader.TestField("Starting Date", PriceListLine."Starting Date");
        PriceListHeader.TestField("Ending Date", PriceListLine."Ending Date");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(JournalLinesPostedMsg, Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Data Migration Facade", 'OnMigrateCustomer', '', false, false)]
    local procedure OnMigrateCustomerSunscriber(var Sender: Codeunit "Customer Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Customer');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Data Migration Facade", 'OnMigrateCustomerDimensions', '', false, false)]
    local procedure OnMigrateCustomerDimensionsSubscriber(var Sender: Codeunit "Customer Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Customer Dimensions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Data Migration Facade", 'OnMigrateCustomerPostingGroups', '', false, false)]
    local procedure OnMigrateCustomerPostingGroupsSubscriber(var Sender: Codeunit "Customer Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Customer Posting Groups');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Data Migration Facade", 'OnMigrateCustomerTransactions', '', false, false)]
    local procedure OnMigrateCustomerTransactionsSubscriber(var Sender: Codeunit "Customer Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Customer Transactions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Data Migration Facade", 'OnMigrateVendor', '', false, false)]
    local procedure OnMigrateVendorSubscriber(var Sender: Codeunit "Vendor Data Migration Facade"; RecordIdToMigrate: RecordID)
    var
        EventTxt: Text;
    begin
        EventTxt := 'Migrate Vendor';
        LibraryVariableStorage.Enqueue(EventTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Data Migration Facade", 'OnMigrateVendorDimensions', '', false, false)]
    local procedure OnMigrateVendorDimensionsSubscriber(var Sender: Codeunit "Vendor Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Vendor Dimensions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Data Migration Facade", 'OnMigrateVendorPostingGroups', '', false, false)]
    local procedure OnMigrateVendorPostingGroupsSubscriber(var Sender: Codeunit "Vendor Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Vendor Posting Groups');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Data Migration Facade", 'OnMigrateVendorTransactions', '', false, false)]
    local procedure OnMigrateVendorTransactionSubscriber(var Sender: Codeunit "Vendor Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Vendor Transactions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', true, true)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItem', '', false, false)]
    local procedure OnMigrateItem(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    var
        Item: Record Item;
        ItemDataMigrationFacade: Codeunit "Item Data Migration Facade";
    begin
        LibraryVariableStorage.Enqueue('Migrate Item');
        ItemDataMigrationFacade.CreateItemIfNeeded('ITEM1', '', '', Item.Type::Inventory.AsInteger());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemTrackingCode', '', false, false)]
    local procedure OnMigrateItemTrackingCode(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Tracking Code');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateCostingMethod', '', false, false)]
    local procedure OnMigrateCostingMethod(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Costing Method');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemUnitOfMeasure', '', false, false)]
    local procedure OnMigrateItemUnitOfMeasure(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Unit Of Measure');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemDiscountGroup', '', false, false)]
    local procedure OnMigrateItemDiscountGroup(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Discount Group');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemSalesLineDiscount', '', false, false)]
    local procedure OnMigrateSalesLineDiscount(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Sales Line Discount');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemPrice', '', false, false)]
    local procedure OnMigrateItemPrice(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Price');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemTariffNo', '', false, false)]
    local procedure OnMigrateItemTariffNumber(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Tariff Number');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemDimensions', '', false, false)]
    local procedure OnMigrateItemDimension(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Dimensions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateItemPostingGroups', '', false, false)]
    local procedure OnMigrateItemPostingSetup(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Posting Setup');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Data Migration Facade", 'OnMigrateInventoryTransactions', '', false, false)]
    local procedure OnMigrateItemTransactions(var Sender: Codeunit "Item Data Migration Facade"; RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
        LibraryVariableStorage.Enqueue('Migrate Item Transactions');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GL Acc. Data Migration Facade", 'OnMigrateGlAccount', '', false, false)]
    local procedure OnMigrateGLAccount(var Sender: Codeunit "GL Acc. Data Migration Facade"; RecordIdToMigrate: RecordID)
    begin
        LibraryVariableStorage.Enqueue('Migrate G/L Account');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnIsExtendedPriceCalculationEnabled', '', false, false)]
    local procedure OnIsExtendedPriceCalculationEnabled(var Result: Boolean);
    begin
        Result := ExtendedPriceCalculationEnabled;
    end;
}
