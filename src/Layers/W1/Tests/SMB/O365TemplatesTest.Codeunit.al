codeunit 138012 "O365 Templates Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Template]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;
        NewActionTok: Label 'New';
        CancelActionTok: Label 'Cancel';
        EditActionTok: Label 'Edit';
        NoActionTok: Label 'NoAction';
        OKActionTok: Label 'OK';
        GlobalTemplateName: Text[50];
        TemplateMustBeEnabledErr: Label 'New configuration template must be enabled';
        StartingNumberTxt: Label 'ABC00010D';
        EndingNumberTxt: Label 'ABC00090D';
        InsertedItemErr: Label 'Item inserted with wrong data';

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerTemplateFromBlankCustomer()
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemTemplateFromBlankItem()
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize();

        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorTemplateFromBlankVendor()
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerTemplateFromCustomerWithAllTemplateFieldsSet()
    var
        Customer: Record Customer;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateCustomerWithTemplateFieldsSet(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        ValidateCustomerVsConfigTemplateWithEmptyDim(Customer, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemTemplateFromItemWithAllTemplateFieldsSet()
    var
        Item: Record Item;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize();

        CreateItemWithTemplateFieldsSet(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        ValidateItemVsConfigTemplateWithEmptyDim(Item, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorTemplateFromVendorWithAllTemplateFieldsSet()
    var
        Vendor: Record Vendor;
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateVendorWithTemplateFieldsSet(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        ValidateVendorVsConfigTemplateWithEmptyDim(Vendor, ConfigTemplHeaderCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveCustomerWithDimensionsAsTemplate()
    var
        Customer: Record Customer;
        CustomerConfigTemplateHeaderCode: Code[20];
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateCustomerWithDimensions(Customer);
        CreateTemplateFromCustomer(Customer, CustomerConfigTemplateHeaderCode);

        ValidateCustomerVsConfigTemplate(Customer, CustomerConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Customer."No.", DATABASE::Customer, CustomerConfigTemplateHeaderCode, Database::"Customer Templ.");
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveItemWithDimensionsAsTemplate()
    var
        Item: Record Item;
        ItemConfigTemplateHeaderCode: Code[20];
    begin
        // [FEATURE] [Item]
        Initialize();

        CreateItemWithDimensions(Item);
        CreateTemplateFromItem(Item, ItemConfigTemplateHeaderCode);

        ValidateItemVsConfigTemplate(Item, ItemConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Item."No.", DATABASE::Item, ItemConfigTemplateHeaderCode, Database::"Item Templ.");
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure SaveVendorWithDimensionsAsTemplate()
    var
        Vendor: Record Vendor;
        VendorConfigTemplateHeaderCode: Code[20];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateVendorWithDimensions(Vendor);
        CreateTemplateFromVendor(Vendor, VendorConfigTemplateHeaderCode);

        ValidateVendorVsConfigTemplate(Vendor, VendorConfigTemplateHeaderCode);
        VerifyDimensionsSavedCorrectly(Vendor."No.", DATABASE::Vendor, VendorConfigTemplateHeaderCode, Database::"Vendor Templ.");
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerTemplateFromConfigTemplateList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        CustomerList.OpenNew();
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewVendorTemplateFromConfigTemplateList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        VendorList.OpenNew();
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateNewItemTemplateFromConfigTemplateList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize();

        LibrarySmallBusiness.CreateItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(NewActionTok);
        LibraryVariableStorage.Enqueue(CancelActionTok);

        ItemList.OpenNew();
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditCustomerTemplateInConfigTemplateList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        CustomerList.OpenNew();
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditVendorTemplateInConfigTemplateList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        VendorList.OpenNew();
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure EditItemTemplateInConfigTemplateList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
        ConfigTemplHeaderCode: Code[10];
    begin
        // [FEATURE] [Item]
        Initialize();

        LibrarySmallBusiness.CreateItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);

        LibraryVariableStorage.Enqueue(EditActionTok);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(CancelActionTok);

        ItemList.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateCity()
    var
        PostCodeRec: Record "Post Code";
        NoreturnCity: Code[10];
        ExpectedPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        NoreturnCity := 'Noreturn';

        PostCodeRec.SetFilter(City, NoreturnCity);
        PostCodeRec.DeleteAll();
        ExpectedPostCode := '';
        ExpectedRegionCode := '';
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := '';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateCustCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplatePostCode()
    var
        PostCodeRec: Record "Post Code";
        ExpectedCity: Code[10];
        NoreturnPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Customer]
        Initialize();

        NoreturnPostCode := 'Noreturn';

        PostCodeRec.SetFilter(Code, NoreturnPostCode);
        PostCodeRec.DeleteAll();
        ExpectedCity := '';
        ExpectedRegionCode := '';
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := '';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateCustPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateCity()
    var
        PostCodeRec: Record "Post Code";
        NoreturnCity: Code[10];
        ExpectedPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        NoreturnCity := 'Noreturn';

        PostCodeRec.SetFilter(City, NoreturnCity);
        PostCodeRec.DeleteAll();
        ExpectedPostCode := '';
        ExpectedRegionCode := '';
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := '';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);

        ExpectedPostCode := 'TEST.PC';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
        ValidateVendCity(NoreturnCity, ExpectedPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplatePostCode()
    var
        PostCodeRec: Record "Post Code";
        ExpectedCity: Code[10];
        NoreturnPostCode: Code[10];
        ExpectedRegionCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        NoreturnPostCode := 'Noreturn';

        PostCodeRec.SetFilter(Code, NoreturnPostCode);
        PostCodeRec.DeleteAll();
        ExpectedCity := '';
        ExpectedRegionCode := '';
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := '';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := '';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);

        ExpectedCity := 'TEST.City';
        ExpectedRegionCode := 'TEST C/R';
        InsertPostCodeRec(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
        ValidateVendPostCode(ExpectedCity, NoreturnPostCode, ExpectedRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomeWhenNoTemplatesDefined()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer]
        Initialize();

        CustomerCard.OpenNew();

        Assert.AreEqual(CustomerCard.Name.Value, '', 'Blank customer should be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorWhenNoTemplatesDefined()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor]
        Initialize();

        VendorCard.OpenNew();

        Assert.AreEqual(VendorCard.Name.Value, '', 'Blank vendor should be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateItemWhenNoTemplatesDefined()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item]
        Initialize();

        ItemCard.OpenNew();

        Assert.AreEqual(ItemCard.Description.Value, '', 'Blank Item should be opened');
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerWhenOneTemplateDefined()
    var
        CustomerFromTemplate: Record Customer;
        CustomerWithTemplateFieldsSet: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Variant;
        CustomerTemplateCode: Code[20];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Customer]
        Initialize();

        // [GIVEN] One Customer template with field set, blank No. Series, no dimensions
        CreateCustomerWithTemplateFieldsSet(CustomerWithTemplateFieldsSet);
        CreateTemplateFromCustomer(CustomerWithTemplateFieldsSet, CustomerTemplateCode);
        GetDefaultCustomerNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Customer from the template
        CustomerCard.OpenNew();

        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();

        // [THEN] Fields in new customer matches template's fields, no dimensions assigned
        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);

        // [THEN] Customer is created with No. and "No. Series" from Sales&Receivables Setup (TFS 229503)
        VerifyCustomerNoWithSeries(CustomerNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorWhenOneTemplateDefined()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Variant;
        VendorTemplateCode: Code[10];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Vendor]
        Initialize();

        // [GIVEN] One Vendor template with field set, blank No. Series, no dimensions
        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);
        GetDefaultVendorNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Vendor from the template
        VendorCard.OpenNew();
        VendorCard.Name.SetValue('Test');

        VendorNo := VendorCard."No.".Value();
        VendorCard.Close();

        // [THEN] Fields in new vendor matches template's fields, no dimensions assigned
        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);

        // [THEN] Vendor is created with No. and "No. Series" from Purchase&Payables Setup (TFS 229503)
        VerifyVendorNoWithSeries(VendorNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemWhenOneTemplateDefined()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        ItemCard: TestPage "Item Card";
        ItemNo: Variant;
        ItemTemplateCode: Code[10];
        NoSeries: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [Item]
        Initialize();

        // [GIVEN] One Item template with field set, blank No. Series, no dimensions
        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);
        GetDefaultItemNoWithSeries(ExpectedNo, NoSeries);

        // [WHEN] Create new Item from the template
        ItemCard.OpenNew();
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        // [THEN] Fields in new item matches template's fields, no dimensions assigned
        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);

        // [THEN] Item is created with No. and "No. Series" from Inventory Setup (TFS 229503)
        VerifyItemNoWithSeries(ItemNo, ExpectedNo, NoSeries);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromTemplateWhenMultipleTemplatesDefined()
    var
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerTemplateCode: Code[20];
        BlankCustomerTemplateCode: Code[20];
        CustomerNo: Text;
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateBlankCustomerTemplateFromCustomer(CustomerTemplateCode, BlankCustomerTemplateCode);

        LibraryVariableStorage.Enqueue(CustomerTemplateCode);

        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();

        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplateWithEmptyDim(CustomerFromTemplate, CustomerTemplateCode);
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorFromTemplateWhenMultipleTemplatesDefined()
    var
        VendorFromTemplate: Record Vendor;
        VendorWithTemplateFieldsSet: Record Vendor;
        BlankVendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorTemplateCode: Code[10];
        BlankVendorTemplateCode: Code[10];
        VendorNo: Text;
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateVendorWithTemplateFieldsSet(VendorWithTemplateFieldsSet);
        CreateTemplateFromVendor(VendorWithTemplateFieldsSet, VendorTemplateCode);
        LibraryVariableStorage.Enqueue(VendorTemplateCode);

        CreateBlankVendor(BlankVendor);
        CreateTemplateFromVendor(BlankVendor, BlankVendorTemplateCode);

        VendorCard.OpenNew();

        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value();
        VendorCard.Close();

        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplateWithEmptyDim(VendorFromTemplate, VendorTemplateCode);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromTemplateWhenMultipleTemplatesDefined()
    var
        ItemFromTemplate: Record Item;
        ItemWithTemplateFieldsSet: Record Item;
        BlankItem: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTemplateCode: Code[20];
        BlankItemTemplateCode: Code[20];
        ItemNo: Text;
    begin
        // [FEATURE] [Item]
        Initialize();

        CreateItemWithTemplateFieldsSet(ItemWithTemplateFieldsSet);
        CreateTemplateFromItem(ItemWithTemplateFieldsSet, ItemTemplateCode);
        LibraryVariableStorage.Enqueue(ItemTemplateCode);

        CreateBlankItem(BlankItem);
        CreateTemplateFromItem(BlankItem, BlankItemTemplateCode);

        ItemCard.OpenNew();
        ItemCard.Description.SetValue('Test');

        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplateWithEmptyDim(ItemFromTemplate, ItemTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomerFromTemplateVerifyContacts()
    var
        CustomerTempl: Record "Customer Templ.";
        Contact: Record Contact;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Code[20];
        ContactsCount: Integer;
    begin
        // [FEATURE] [Customer] [Contact]
        // [SCENARIO] One related Contact is created when create Customer from template
        Initialize();

        // [GIVEN] Customer Template
        UpdateMarketingSetup();
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);
        ContactsCount := Contact.Count();

        // [WHEN] Create Customer from Template
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();

        // [THEN] One Contact created for Customer
        VerifyOneCustomerContactDoesExist(CustomerNo, ContactsCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorFromTemplateVerifyContacts()
    var
        VendorTempl: Record "Vendor Templ.";
        Contact: Record Contact;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Code[20];
        ContactsCount: Integer;
    begin
        // [FEATURE] [Vendor] [Contact]
        // [SCENARIO] One related Contact is created when create Vendor from template
        Initialize();

        // [GIVEN] Vendor Template
        UpdateMarketingSetup();
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        LibraryVariableStorage.Enqueue(VendorTempl.Code);
        ContactsCount := Contact.Count();

        // [WHEN] Create Vendor from Template
        VendorCard.OpenNew();
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value();
        VendorCard.Close();

        // [THEN] One Contact created for Vendor
        VerifyOneVendorContactDoesExist(VendorNo, ContactsCount);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerWithDimensionsFromTemplate()
    var
        Customer: Record Customer;
        CustomerFromTemplate: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerConfigTemplateHeaderCode: Code[10];
        CustomerNo: Text;
    begin
        // [FEATURE] [Customer]
        Initialize();

        CreateCustomerWithDimensions(Customer);
        CreateTemplateFromCustomer(Customer, CustomerConfigTemplateHeaderCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue('Test');
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();

        CustomerFromTemplate.Get(CustomerNo);
        ValidateCustomerVsConfigTemplate(CustomerFromTemplate, CustomerConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorWithDimensionsFromTemplate()
    var
        Vendor: Record Vendor;
        VendorFromTemplate: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorConfigTemplateHeaderCode: Code[10];
        VendorNo: Text;
    begin
        // [FEATURE] [Vendor]
        Initialize();

        CreateVendorWithDimensions(Vendor);
        CreateTemplateFromVendor(Vendor, VendorConfigTemplateHeaderCode);

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        VendorCard.OpenNew();
        VendorCard.Name.SetValue('Test');
        VendorNo := VendorCard."No.".Value();
        VendorCard.Close();

        VendorFromTemplate.Get(VendorNo);
        ValidateVendorVsConfigTemplate(VendorFromTemplate, VendorConfigTemplateHeaderCode);
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemWithDimensionsFromTemplate()
    var
        Item: Record Item;
        ItemFromTemplate: Record Item;
        ItemCard: TestPage "Item Card";
        ItemConfigTemplateHeaderCode: Code[10];
        ItemNo: Text;
    begin
        // [FEATURE] [Item] [Dimension]
        Initialize();

        CreateItemWithDimensions(Item);
        CreateTemplateFromItem(Item, ItemConfigTemplateHeaderCode);

        ItemCard.Trap();

        LibraryVariableStorage.Enqueue(NoActionTok);
        LibraryVariableStorage.Enqueue(OKActionTok);

        ItemCard.OpenNew();
        ItemCard.Description.SetValue('Test');
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        ItemFromTemplate.Get(ItemNo);
        ValidateItemVsConfigTemplate(ItemFromTemplate, ItemConfigTemplateHeaderCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewGeneralTemplateInConfigTemplateList()
    var
        ConfigTemplates: TestPage "Config Templates";
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
    begin
        Initialize();

        ConfigTemplates.OpenView();
        ConfigTemplateHeaderPage.Trap();
        ConfigTemplates.NewConfigTemplate.Invoke();
        Assert.IsTrue(ConfigTemplateHeaderPage.Code.Editable(), 'Template page opened in read-only mode.');
        Assert.AreEqual('', ConfigTemplateHeaderPage.Code.Value, 'Template not opened in new mode.');
        ConfigTemplateHeaderPage.Close();
        ConfigTemplates.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewConfigTemplateIsEnabledByDefault()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [SCENARIO 159448] When a new config. template is created in UI it is enabled by default

        Initialize();

        // [GIVEN] Create new configuration template
        ConfigTemplateHeader.Init();

        // [THEN] New template is created with "Enabled" = TRUE
        Assert.IsTrue(ConfigTemplateHeader.Enabled, TemplateMustBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateValidateTableRelations()
    var
        ItemTemplate: Record "Item Templ.";
    begin
        // [SCENARIO] Item Template does not allow non-existing values in table relation fields.

        // [GIVEN] An item template
        ItemTemplate.Init();

        // [WHEN] Assigning a non-existing "Base Unit of Measure"
        asserterror ItemTemplate.Validate("Base Unit of Measure", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Inventory Posting Group"
        asserterror ItemTemplate.Validate("Inventory Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Item Disc. Group"
        asserterror ItemTemplate.Validate("Item Disc. Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Gen. Prod. Posting Group"
        asserterror ItemTemplate.Validate("Gen. Prod. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Tax Group Code"
        asserterror ItemTemplate.Validate("Tax Group Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "VAT Prod. Posting Group"
        asserterror ItemTemplate.Validate("VAT Prod. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Item Category Code"
        asserterror ItemTemplate.Validate("Item Category Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Service Item Group"
        asserterror ItemTemplate.Validate("Service Item Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Warehouse Class Code"
        asserterror ItemTemplate.Validate("Warehouse Class Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown
        Assert.AssertPrimRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateValidateTableRelations()
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        // [SCENARIO] Customer Template does not allow non-existing values in table relation fields.

        // [GIVEN] A customer template
        CustomerTempl.Init();

        // [WHEN] Assigning a non-existing "Document Sending Profile"
        asserterror CustomerTempl.Validate("Document Sending Profile", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Customer Posting Group"
        asserterror CustomerTempl.Validate("Customer Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Currency Code"
        asserterror CustomerTempl.Validate("Currency Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Customer Price Group"
        asserterror CustomerTempl.Validate("Customer Price Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Language Code"
        asserterror CustomerTempl.Validate("Language Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Payment Terms Code"
        asserterror CustomerTempl.Validate("Payment Terms Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Fin. Charge Terms Code"
        asserterror CustomerTempl.Validate("Fin. Charge Terms Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Customer Disc. Group"
        asserterror CustomerTempl.Validate("Customer Disc. Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Country/Region Code"
        asserterror CustomerTempl.Validate("Country/Region Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Payment Method Code"
        asserterror CustomerTempl.Validate("Payment Method Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Gen. Bus. Posting Group"
        asserterror CustomerTempl.Validate("Gen. Bus. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Reminder Terms Code"
        asserterror CustomerTempl.Validate("Reminder Terms Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "VAT Bus. Posting Group"
        asserterror CustomerTempl.Validate("VAT Bus. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateValidateTableRelations()
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        // [SCENARIO] Vendor Template does not allow non-existing values in table relation fields.

        // [GIVEN] A vendor template
        VendorTempl.Init();

        // [WHEN] Assigning a non-existing "Vendor Posting Group"
        asserterror VendorTempl.Validate("Vendor Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Currency Code"
        asserterror VendorTempl.Validate("Currency Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Language Code"
        asserterror VendorTempl.Validate("Language Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Payment Terms Code"
        asserterror VendorTempl.Validate("Payment Terms Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Fin. Charge Terms Code"
        asserterror VendorTempl.Validate("Fin. Charge Terms Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Invoice Disc. Code"
        asserterror VendorTempl.Validate("Invoice Disc. Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Country/Region Code"
        asserterror VendorTempl.Validate("Country/Region Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Payment Method Code"
        asserterror VendorTempl.Validate("Payment Method Code", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "Gen. Bus. Posting Group"
        asserterror VendorTempl.Validate("Gen. Bus. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();

        // [WHEN] Assigning a non-existing "VAT Bus. Posting Group"
        asserterror VendorTempl.Validate("VAT Bus. Posting Group", LibraryUtility.GenerateGUID());
        // [THEN] An error is thrown.
        Assert.AssertPrimRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodNewTemplate()
    var
        InventorySetup: Record "Inventory Setup";
        ItemTemplateCard: TestPage "Item Templ. Card";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] New Item Templates take the costing method from Inventory Setup

        // [GIVEN] Default Costing Method = Average
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [WHEN] Opening the Item Template Card
        ItemTemplateCard.OpenNew();

        // [THEN] The Costing Method equals Average
        ItemTemplateCard."Costing Method".AssertEquals(InventorySetup."Default Costing Method"::Average);
        ItemTemplateCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodNoTemplate()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] Item created manually take the costing method from Inventory Setup

        // [GIVEN] Default Costing Method Average in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [WHEN] Create new item manually without template
        Item.Init();
        Item.Validate("No.", LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item));

        // [THEN] The Costing method is Average
        Assert.AreEqual(Item."Costing Method"::Average, Item."Costing Method", 'Costing Method should be Average');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateDefaultCostingMethodRenaming()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [UT] [Item]
        // [SCENARIO] Rename item created manually keep costing method unchanged

        // [GIVEN] Default Costing Method Average in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Average);
        InventorySetup.Modify();

        // [GIVEN] New item with Costing Method Average
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Default Costing Method Standard in the Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Default Costing Method", InventorySetup."Default Costing Method"::Standard);
        InventorySetup.Modify();

        // [THEN] Rename item
        Item.Rename(LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item));

        // [WHEN] The Costing method is still Average
        Assert.AreEqual(Item."Costing Method"::Average, Item."Costing Method", 'Costing Method should be Average');
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromItemTemplateWithNoSeries()
    var
        ItemTempl: Record "Item Templ.";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemNo: Variant;
        ConfigTemplHeaderCode: Code[20];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Item]
        // [SCENARIO 229503] When new item is created from template, No. and No. Series are assigned from Item Template No. Series
        Initialize();

        // [GIVEN] Configuration Template for blank Item with No. Series = "S" and next No. = "N"
        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        ItemTempl.Get(ConfigTemplHeaderCode);
        ItemTempl."No. Series" := NoSeriesCode;
        ItemTempl.Modify(true);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate());

        // [WHEN] Create new Item
        ItemCard.OpenNew();
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        // [THEN] Item is created with No. = "N" and "No. Series" = "S"
        VerifyItemNoWithSeries(ItemNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromCustomerTemplateWithNoSeries()
    var
        CustomerTempl: Record "Customer Templ.";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Variant;
        ConfigTemplHeaderCode: Code[20];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Customer]
        // [SCENARIO 229503] When new customer is created from template, No. and No. Series are assigned from Customer Template No. Series
        Initialize();

        // [GIVEN] Configuration Template for blank Customer with No. Series = "S" and next No. = "N"
        CreateBlankCustomer(Customer);
        CreateTemplateFromCustomer(Customer, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CustomerTempl.Get(ConfigTemplHeaderCode);
        CustomerTempl."No. Series" := NoSeriesCode;
        CustomerTempl.Modify(true);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate());

        // [WHEN] Create new Customer
        CustomerCard.OpenNew();
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.Close();

        // [THEN] Customer is created with No. = "N" and "No. Series" = "S"
        VerifyCustomerNoWithSeries(CustomerNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('VendorTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorFromVendorTemplateWithNoSeries()
    var
        VendorTempl: Record "Vendor Templ.";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorNo: Variant;
        ConfigTemplHeaderCode: Code[20];
        NoSeriesCode: Code[20];
        ExpectedNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Vendor]
        // [SCENARIO 229503] When new vendor is created from template, No. and No. Series are assigned from Vendor Template No. Series
        Initialize();

        // [GIVEN] Configuration Template for blank Vendor with No. Series = "S" and next No. = "N"
        CreateBlankVendor(Vendor);
        CreateTemplateFromVendor(Vendor, ConfigTemplHeaderCode);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        VendorTempl.Get(ConfigTemplHeaderCode);
        VendorTempl."No. Series" := NoSeriesCode;
        VendorTempl.Modify(true);
        ExpectedNo := LibraryUtility.GetNextNoFromNoSeries(NoSeriesCode, WorkDate());

        // [WHEN] Create new Vendor
        VendorCard.OpenNew();
        VendorNo := VendorCard."No.".Value();
        VendorCard.Close();

        // [THEN] Vendor is created with No. = "N" and "No. Series" = "S"
        VerifyVendorNoWithSeries(VendorNo, ExpectedNo, NoSeriesCode);
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateLookupCity()
    var
        CustomerTempl: Record "Customer Templ.";
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Customer Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of City field for Customer Template page
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustTemplateCard.OpenEdit();
        CustTemplateCard.GoToRecord(CustomerTempl);

        // [WHEN] Lookup for City field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard.City.Lookup();

        // [THEN] Customer template Post Code = "PC", Country/Region Code = "CRC"
        CustTemplateCard."Post Code".AssertEquals(PostCode.Code);
        CustTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        CustTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateLookupPostCode()
    var
        CustomerTempl: Record "Customer Templ.";
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Customer Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of Post Code field for Customer Template page
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustTemplateCard.OpenEdit();
        CustTemplateCard.GoToRecord(CustomerTempl);

        // [WHEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard."Post Code".Lookup();

        // [THEN] Customer template City = "CITY", Country/Region Code = "CRC"
        CustTemplateCard.City.AssertEquals(PostCode.City);
        CustTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        CustTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplateValidateCountryCode()
    var
        CustomerTempl: Record "Customer Templ.";
        PostCode: Record "Post Code";
        CustTemplateCard: TestPage "Customer Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Changing Country/Region Code on Customer Template page leads to clear Country and Post Code fields
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open customer template card from configuration templates list
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustTemplateCard.OpenEdit();
        CustTemplateCard.GoToRecord(CustomerTempl);

        // [GIVEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        CustTemplateCard."Post Code".Lookup();

        // [WHEN] Country/Region Code is being cleared
        CustTemplateCard."Country/Region Code".SetValue('');

        // [THEN] Customer template City = '', Post Code = ''
        CustTemplateCard.City.AssertEquals('');
        CustTemplateCard."Post Code".AssertEquals('');
        CustTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateLookupCity()
    var
        VendorTempl: Record "Vendor Templ.";
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of City field for Vendor Template page
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTemplateCard.OpenEdit();
        VendorTemplateCard.GoToRecord(VendorTempl);

        // [WHEN] Lookup for City field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard.City.Lookup();

        // [THEN] Vendor Template Post Code = "PC", Country/Region Code = "CRC"
        VendorTemplateCard."Post Code".AssertEquals(PostCode.Code);
        VendorTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        VendorTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateLookupPostCode()
    var
        VendorTempl: Record "Vendor Templ.";
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Post Codes page used for lookup of Post Code field for Vendor Template page
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTemplateCard.OpenEdit();
        VendorTemplateCard.GoToRecord(VendorTempl);

        // [WHEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard."Post Code".Lookup();

        // [THEN] Vendor Template City = "CITY", Country/Region Code = "CRC"
        VendorTemplateCard.City.AssertEquals(PostCode.City);
        VendorTemplateCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
        VendorTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostCodeModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplateValidateCountryCode()
    var
        VendorTempl: Record "Vendor Templ.";
        PostCode: Record "Post Code";
        VendorTemplateCard: TestPage "Vendor Templ. Card";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 291491] Changing Country/Region Code on Vendor Template page leads to clear Country and Post Code fields
        Initialize();

        // [GIVEN] Create post code record with City = "CITY", Post Code = "PC", Country/Region Code = "CRC"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Open Vendor Template card from configuration templates list
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTemplateCard.OpenEdit();
        VendorTemplateCard.GoToRecord(VendorTempl);

        // [GIVEN] Lookup for Post Code field is being invoked and Post Code record with "PC", "CITY" picked
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode.City);
        VendorTemplateCard."Post Code".Lookup();

        // [WHEN] Country/Region Code is being cleared
        VendorTemplateCard."Country/Region Code".SetValue('');

        // [THEN] Vendor Template City = '', Post Code = ''
        VendorTemplateCard.City.AssertEquals('');
        VendorTemplateCard."Post Code".AssertEquals('');
        VendorTemplateCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTemplateCardHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromItemTemplateWit()
    var
        ItemTempl: Record "Item Templ.";
        Item: Record Item;
        NoSeries: Record "No. Series";
        ItemCard: TestPage "Item Card";
        ItemNo: Variant;
        ConfigTemplHeaderCode: Code[20];
    begin
        // [SCENARIO 446206] No Series Lines are no longer automatically closing when the last number is reached.
        Initialize();

        // [GIVEN] Create No. Series and No. Series Line
        CreateNewNumberSeries(NoSeries);
        CreateNumberSeriesLine(NoSeries, StartingNumberTxt, StartingNumberTxt, 1, 10000, Enum::"No. Series Implementation"::Normal);
        CreateNumberSeriesLine(NoSeries, EndingNumberTxt, EndingNumberTxt, 1, 20000, Enum::"No. Series Implementation"::Normal);

        // [GIVEN] Configuration Template for blank Item with No. Series.
        CreateBlankItem(Item);
        CreateTemplateFromItem(Item, ConfigTemplHeaderCode);
        ItemTempl.Get(ConfigTemplHeaderCode);
        ItemTempl."No. Series" := NoSeries.Code;
        ItemTempl.Modify(true);

        // [WHEN] Create new Item
        ItemCard.OpenNew();
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        // [VERIFY] Item is created with No. = "ABC00010D"
        VerifyItemNoWithSeries(ItemNo, StartingNumberTxt, NoSeries.Code);

        // [WHEN] Create new Item
        ItemCard.OpenNew();
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        // [VERIFy] Item is created with No. = "ABC00090D".
        VerifyItemNoWithSeries(ItemNo, EndingNumberTxt, NoSeries.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemTemplApplyTemplateFromItemTemplatesUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 475184] Item Template is not working as expected: some fields get overwritten unexpectedly
        Initialize();

        // [GIVEN] Create new Item Template "T1" with data, and enquue Item Template Code
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        UpdateItemTemplate(ItemTempl);
        LibraryVariableStorage.Enqueue(ItemTempl.Code);

        // [GIVEN] Create new Item "I", and set Default values for different item fields
        LibraryInventory.CreateItem(Item);

        // [WHEN] Apply "T1" to "I"
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [THEN] "I" filled with data from "T2", Fields in new item matches template's fields
        Item.Get(Item."No.");

        // [VERIFY] Verify: Values on Item record after applying Item Template
        VerifyItemAfterApplyTemplate(Item, ItemTempl);

        // [WHEN] Clear different fields on Item Template T1, and Apply "T1" to "I"
        ClearItemTemplate(ItemTempl);
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [VERIFY] Verify: Values on Item record after applying Item Template
        VerifyItemDataNotEqualAfterApplyTemplate(Item, ItemTempl);

        // [THEN] Enum values are updated from the template.
        Assert.IsTrue(Item."Reordering Policy" = ItemTempl."Reordering Policy", InsertedItemErr);
        Assert.IsTrue(Item."Replenishment System" = ItemTempl."Replenishment System", InsertedItemErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyCountingDatesUpdatedWhenPhysInvtCountingPeriodUpdatedOnItemFromItemTempl()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 491210] An issue with the item template card where the physical inventory period value is not validated on the item card, resulting in missing inventory dates and new items not being inventoried.
        Initialize();

        // [GIVEN] Create new Item Template "T1" with Phys Invt Counting Period
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        ItemTempl.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        ItemTempl.Modify(true);

        // [GIVEN] Create new Item "I", and set Default values for different item fields
        LibraryInventory.CreateItem(Item);

        // [WHEN] Apply "T1" to "I"
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [THEN] "I" filled with data from "T2", Fields in new item matches template's fields
        Item.Get(Item."No.");

        // [VERIFY] Verify: Values on Item record after applying Item Template
        VerifyItemAfterApplyTemplateWithPhysInvtCountingPeriod(Item, ItemTempl);
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Templates Test");
        DeleteConfigurationTemplates();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Templates Test");

        LibraryTemplates.EnableTemplatesFeature();
        ClearTable(DATABASE::"Item Identifier");
        ClearTable(DATABASE::Job);
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        ClearTable(DATABASE::"Resource Skill");
        ClearTable(DATABASE::"Service Item Component");
        ClearTable(DATABASE::"Troubleshooting Setup");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Templates Test");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        ProductionBOMLine: Record "Production BOM Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ResourceSkill: Record "Resource Skill";
        ItemIdentifier: Record "Item Identifier";
        ServiceItemComponent: Record "Service Item Component";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::"Job Planning Line":
                JobPlanningLine.DeleteAll();
            DATABASE::Job:
                Job.DeleteAll();
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::"Troubleshooting Setup":
                TroubleshootingSetup.DeleteAll();
            DATABASE::"Resource Skill":
                ResourceSkill.DeleteAll();
            DATABASE::"Item Identifier":
                ItemIdentifier.DeleteAll();
            DATABASE::"Service Item Component":
                ServiceItemComponent.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateBlankCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer.Insert(true);
    end;

    local procedure CreateBlankItem(var Item: Record Item)
    begin
        Item.Init();
        Item.Insert(true);
    end;

    local procedure CreateBlankVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor.Insert(true);
    end;

    local procedure CreateCustomerWithTemplateFieldsSet(var Customer: Record Customer)
    var
        Customer2: Record Customer;
        Currency: Record Currency;
        CustomerPriceGroup: Record "Customer Price Group";
        Language: Record Language;
        PaymentTerms: Record "Payment Terms";
        FinChargeTerms: Record "Finance Charge Terms";
        CustDiscGroup: Record "Customer Discount Group";
        PaymentMethod: Record "Payment Method";
        ReminderTerms: Record "Reminder Terms";
    begin
        LibrarySales.CreateCustomer(Customer2);
        Customer.Init();
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate("Address 2", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Post Code"), DATABASE::Customer));
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDecInRange(1, 10000, 1));
        Customer.Validate("Customer Posting Group", Customer2."Customer Posting Group");

        Customer.Validate("Currency Code", EnsureRecordExistAndGetValue(Currency.FieldNo(Code), DATABASE::Currency));
        Customer.Validate(
          "Customer Price Group", EnsureRecordExistAndGetValue(CustomerPriceGroup.FieldNo(Code), DATABASE::"Customer Price Group"));
        Customer.Validate("Language Code", EnsureRecordExistAndGetValue(Language.FieldNo(Code), DATABASE::Language));
        Customer.Validate("Payment Terms Code", EnsureRecordExistAndGetValue(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms"));
        Customer.Validate(
          "Fin. Charge Terms Code", EnsureRecordExistAndGetValue(FinChargeTerms.FieldNo(Code), DATABASE::"Finance Charge Terms"));
        Customer.Validate(
          "Customer Disc. Group", EnsureRecordExistAndGetValue(CustDiscGroup.FieldNo(Code), DATABASE::"Customer Discount Group"));

        Customer.Validate("Print Statements", not Customer."Print Statements");
        Customer.Validate("Payment Method Code", EnsureRecordExistAndGetValue(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method"));
        Customer.Validate("Application Method", LibraryRandom.RandIntInRange(0, 1));
        Customer.Validate("Prices Including VAT", not Customer."Prices Including VAT");
        Customer.Validate("Gen. Bus. Posting Group", Customer2."Gen. Bus. Posting Group");
        Customer.Validate("Reminder Terms Code", EnsureRecordExistAndGetValue(ReminderTerms.FieldNo(Code), DATABASE::"Reminder Terms"));
        Customer.Validate("VAT Bus. Posting Group", Customer2."VAT Bus. Posting Group");
        Customer.Validate("Block Payment Tolerance", not Customer."Block Payment Tolerance");
        Customer.Validate("Allow Line Disc.", not Customer."Allow Line Disc.");
        Customer.Validate("Validate EU Vat Reg. No.", Customer."Validate EU Vat Reg. No.");
        Customer.Insert(true);
    end;

    local procedure CreateItemWithTemplateFieldsSet(var Item: Record Item)
    var
        Item2: Record Item;
        ItemDiscGroup: Record "Item Discount Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryInventory.CreateItem(Item2);
        CreateBlankItem(Item);
        Item.Validate("Base Unit of Measure", Item2."Base Unit of Measure");
        Item.Validate("Inventory Posting Group", Item2."Inventory Posting Group");
        Item.Validate("Item Disc. Group", EnsureRecordExistAndGetValue(ItemDiscGroup.FieldNo(Code), DATABASE::"Item Discount Group"));
        Item.Validate("Allow Invoice Disc.", not Item."Allow Invoice Disc.");
        Item.Validate("Price/Profit Calculation", LibraryRandom.RandIntInRange(0, 1));
        Item.Validate("Costing Method", LibraryRandom.RandIntInRange(0, 1));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDecInRange(1, 100, 1));
        Item.Validate("Gen. Prod. Posting Group", Item2."Gen. Prod. Posting Group");
        Item.Validate("Automatic Ext. Texts", not Item."Automatic Ext. Texts");
        Item.Validate("VAT Prod. Posting Group", Item2."VAT Prod. Posting Group");

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        EditSalesSetupWithVATBusPostGrPrice(VATBusinessPostingGroup.Code);

        LibrarySmallBusiness.SetVATBusPostingGrPriceSetup(Item."VAT Prod. Posting Group", not Item."Price Includes VAT");
        Item.Validate("Price Includes VAT", not Item."Price Includes VAT");
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);
    end;

    local procedure CreateVendorWithTemplateFieldsSet(var Vendor: Record Vendor)
    var
        Vendor2: Record Vendor;
        Currency: Record Currency;
        Language: Record Language;
        PaymentTerms: Record "Payment Terms";
        FinChargeTerms: Record "Finance Charge Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor.Init();
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate("Address 2", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Post Code"), DATABASE::Vendor));
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor.Validate("Vendor Posting Group", Vendor2."Vendor Posting Group");

        Vendor.Validate("Currency Code", EnsureRecordExistAndGetValue(Currency.FieldNo(Code), DATABASE::Currency));
        Vendor.Validate("Language Code", EnsureRecordExistAndGetValue(Language.FieldNo(Code), DATABASE::Language));
        Vendor.Validate("Payment Terms Code", EnsureRecordExistAndGetValue(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms"));
        Vendor.Validate(
          "Fin. Charge Terms Code", EnsureRecordExistAndGetValue(FinChargeTerms.FieldNo(Code), DATABASE::"Finance Charge Terms"));

        Vendor.Validate("Payment Method Code", EnsureRecordExistAndGetValue(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method"));
        Vendor.Validate("Shipment Method Code", Vendor2."Shipment Method Code");
        Vendor.Validate("Application Method", LibraryRandom.RandIntInRange(0, 1));
        Vendor.Validate("Prices Including VAT", not Vendor."Prices Including VAT");
        Vendor.Validate("Gen. Bus. Posting Group", Vendor2."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", Vendor2."VAT Bus. Posting Group");
        Vendor.Validate("Block Payment Tolerance", not Vendor."Block Payment Tolerance");
        Vendor.Validate("Validate EU Vat Reg. No.", Vendor."Validate EU Vat Reg. No.");
        Vendor.Insert(true);
    end;

    local procedure CreateTemplateFromCustomer(Customer: Record Customer; var ConfigTemplHeaderCode: Code[20])
    var
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        GlobalTemplateName := Customer."No.";
        CustomerTemplMgt.SaveAsTemplate(Customer);

        CustomerTempl.SetRange(Description, GlobalTemplateName);
        CustomerTempl.FindLast();
        ConfigTemplHeaderCode := CustomerTempl.Code;
    end;

    local procedure CreateTemplateFromItem(Item: Record Item; var ConfigTemplHeaderCode: Code[20])
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        GlobalTemplateName := Item."No.";
        ItemTemplMgt.SaveAsTemplate(Item);

        ItemTempl.SetRange(Description, GlobalTemplateName);
        ItemTempl.FindLast();
        ConfigTemplHeaderCode := ItemTempl.Code;
    end;

    local procedure CreateTemplateFromVendor(Vendor: Record Vendor; var ConfigTemplHeaderCode: Code[20])
    var
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
    begin
        GlobalTemplateName := Vendor."No.";
        VendorTemplMgt.SaveAsTemplate(Vendor);

        VendorTempl.SetRange(Description, GlobalTemplateName);
        VendorTempl.FindLast();
        ConfigTemplHeaderCode := VendorTempl.Code;
    end;

    local procedure CreateBlankCustomerTemplateFromCustomer(var CustomerTemplateCode: Code[20]; var BlankCustomerTemplateCode: Code[20])
    var
        CustomerWithTemplateFieldsSet: Record Customer;
        BlankCustomer: Record Customer;
    begin
        CreateCustomerWithTemplateFieldsSet(CustomerWithTemplateFieldsSet);
        CreateTemplateFromCustomer(CustomerWithTemplateFieldsSet, CustomerTemplateCode);

        CreateBlankCustomer(BlankCustomer);
        CreateTemplateFromCustomer(BlankCustomer, BlankCustomerTemplateCode);
    end;

    local procedure GetDefaultItemNoWithSeries(var ItemNo: Code[20]; var NoSeries: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        NoSeries := InventorySetup."Item Nos.";
        ItemNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate());
    end;

    local procedure GetDefaultCustomerNoWithSeries(var CustomerNo: Code[20]; var NoSeries: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        NoSeries := SalesReceivablesSetup."Customer Nos.";
        CustomerNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate());
    end;

    local procedure GetDefaultVendorNoWithSeries(var VendorNo: Code[20]; var NoSeries: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries := PurchasesPayablesSetup."Vendor Nos.";
        VendorNo := LibraryUtility.GetNextNoFromNoSeries(NoSeries, WorkDate());
    end;

    local procedure ValidateCustomerVsConfigTemplate(Customer: Record Customer; ConfigTemplHeaderCode: Code[20])
    var
        CustomerTempl: Record "Customer Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        CustomerTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(CustomerTempl);
        RecRef.GetTable(Customer);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyCustomerDimensionsVsTemplate(Customer, ConfigTemplHeaderCode);
    end;

    local procedure ValidateCustomerVsConfigTemplateWithEmptyDim(Customer: Record Customer; ConfigTemplHeaderCode: Code[20])
    var
        CustomerTempl: Record "Customer Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        CustomerTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(CustomerTempl);
        RecRef.GetTable(Customer);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyEmptyDefaultDimension(DATABASE::Customer, Customer."No.");
    end;

    local procedure ValidateItemVsConfigTemplate(Item: Record Item; ConfigTemplHeaderCode: Code[20])
    var
        ItemTempl: Record "Item Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        ItemTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(ItemTempl);
        RecRef.GetTable(Item);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyItemDimensionsVsTemplate(Item, ConfigTemplHeaderCode);
    end;

    local procedure ValidateItemVsConfigTemplateWithEmptyDim(Item: Record Item; ConfigTemplHeaderCode: Code[20])
    var
        ItemTempl: Record "Item Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        ItemTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(ItemTempl);
        RecRef.GetTable(Item);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyEmptyDefaultDimension(DATABASE::Item, Item."No.");
    end;

    local procedure ValidateVendorVsConfigTemplate(Vendor: Record Vendor; ConfigTemplHeaderCode: Code[20])
    var
        VendorTempl: Record "Vendor Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        VendorTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(VendorTempl);
        RecRef.GetTable(Vendor);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyVendorDimensionsVsTemplate(Vendor, ConfigTemplHeaderCode);
    end;

    local procedure ValidateVendorVsConfigTemplateWithEmptyDim(Vendor: Record Vendor; ConfigTemplHeaderCode: Code[10])
    var
        VendorTempl: Record "Vendor Templ.";
        TemplateRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        VendorTempl.Get(ConfigTemplHeaderCode);
        TemplateRecRef.GetTable(VendorTempl);
        RecRef.GetTable(Vendor);
        ValidateRecRefVsConfigTemplate(RecRef, TemplateRecRef);
        VerifyEmptyDefaultDimension(DATABASE::Vendor, Vendor."No.");
    end;

    local procedure ValidateRecRefVsConfigTemplate(RecRef: RecordRef; TemplateRecRef: RecordRef)
    var
        TemplateField: Record Field;
        InstanceField: Record Field;
        TemplateFieldRef: FieldRef;
        InstanceFieldRef: FieldRef;
        TableId: Integer;
        SkipCopy: Boolean;
    begin
        TableId := TemplateRecRef.Number;
        TemplateField.SetRange(TableNo, TableId);
        case TableId of
            1381:
                TemplateField.SetFilter("No.", '<>%1&<>%2&<>%3&<%4', 1, 2, 107, 2000000000);
            1383:
                TemplateField.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<%5', 1, 2, 107, 5050, 2000000000);
            1382:
                TemplateField.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<%5', 1, 2, 90, 97, 2000000000);
        end;
        TemplateField.FindSet();
        repeat
            SkipCopy := false;
            if InstanceField.Get(RecRef.Number, TemplateField."No.") then
                if InstanceField.ObsoleteState = InstanceField.ObsoleteState::Removed then
                    SkipCopy := true;

            if not SkipCopy then begin // skip field "Registration No." because it ha sbeen removed from the source table in CH
                InstanceFieldRef := RecRef.Field(TemplateField."No.");
                TemplateFieldRef := TemplateRecRef.Field(TemplateField."No.");
                Assert.AreEqual(Format(InstanceFieldRef), Format(TemplateFieldRef), StrSubstNo('<%1> field was different than in the template.', InstanceFieldRef.Caption));
            end;
        until TemplateField.Next() = 0;
    end;

    local procedure ValidateCustCity(CityName: Code[10]; ExpectedPostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempCustomerTempl: Record "Customer Templ." temporary;
    begin
        TempCustomerTempl.Insert();
        TempCustomerTempl.Validate(City, CityName);
        Assert.AreEqual(ExpectedPostCode, TempCustomerTempl."Post Code", 'Wrong "Post Code"');
        Assert.AreEqual(ExpectedCountryRegionCode, TempCustomerTempl."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateCustPostCode(ExpectedCityName: Code[10]; PostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempCustomerTempl: Record "Customer Templ." temporary;
    begin
        TempCustomerTempl.Insert();
        TempCustomerTempl.Validate("Post Code", PostCode);
        Assert.AreEqual(ExpectedCityName, TempCustomerTempl.City, 'Wrong City');
        Assert.AreEqual(ExpectedCountryRegionCode, TempCustomerTempl."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateVendCity(CityName: Code[10]; ExpectedPostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempVendorTempl: Record "Vendor Templ." temporary;
    begin
        TempVendorTempl.Insert();
        TempVendorTempl.Validate(City, CityName);
        Assert.AreEqual(ExpectedPostCode, TempVendorTempl."Post Code", 'Wrong "Post Code"');
        Assert.AreEqual(ExpectedCountryRegionCode, TempVendorTempl."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure ValidateVendPostCode(ExpectedCityName: Code[10]; PostCode: Code[10]; ExpectedCountryRegionCode: Code[10])
    var
        TempVendorTempl: Record "Vendor Templ." temporary;
    begin
        TempVendorTempl.Insert();
        TempVendorTempl.Validate("Post Code", PostCode);
        Assert.AreEqual(ExpectedCityName, TempVendorTempl.City, 'Wrong City');
        Assert.AreEqual(ExpectedCountryRegionCode, TempVendorTempl."Country/Region Code", 'Wrong "Country/Region Code"');
    end;

    local procedure DeleteConfigurationTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
        ItemTempl: Record "Item Templ.";
    begin
        ConfigTemplateHeader.DeleteAll(true);
        CustomerTempl.DeleteAll(true);
        VendorTempl.DeleteAll(true);
        ItemTempl.DeleteAll(true);
    end;

    local procedure EnsureRecordExistAndGetValue(FieldNo: Integer; TableNo: Integer): Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);

        if not RecordRef.FindFirst() then begin
            RecordRef.Init();
            FieldRef := RecordRef.Field(FieldNo);
            FieldRef.Value := LibraryUtility.GenerateRandomCode(FieldNo, TableNo);
            RecordRef.Insert(true);
        end else
            FieldRef := RecordRef.Field(FieldNo);

        exit(FieldRef.Value);
    end;

    local procedure CreateDimension(var Dimension: Record Dimension)
    var
        DimensionValue: Record "Dimension Value";
        NumberOfDimensionValues: Integer;
        I: Integer;
    begin
        Dimension.Init();
        Dimension.Code := LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension);
        Dimension.Insert(true);

        NumberOfDimensionValues := LibraryRandom.RandIntInRange(2, 10);

        for I := 1 to NumberOfDimensionValues do begin
            DimensionValue.Init();
            DimensionValue.Code := LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value");
            DimensionValue."Dimension Code" := Dimension.Code;
            DimensionValue.Insert();
        end;
    end;


    local procedure AddDefaultDimensionsToRecord(RecordNo: Code[20]; TableID: Integer; NumberOfDimensions: Integer)
    var
        I: Integer;
    begin
        for I := 1 to NumberOfDimensions do
            AddDefaultDimension(RecordNo, TableID);
    end;

    local procedure AddDefaultDimension(RecordNo: Code[20]; TableID: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        CreateDimension(Dimension);
        DefaultDimension.Init();
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."No." := RecordNo;
        DefaultDimension."Dimension Code" := Dimension.Code;

        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindLast();
        DefaultDimension."Dimension Value Code" := DimensionValue.Code;
        DefaultDimension.Insert();
    end;

    local procedure VerifyDimensionsSavedCorrectly(MasterRecordNo: Code[20]; TableID: Integer; ConfigTemplateHeaderCode: Code[20]; DstTableId: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        DstDefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("No.", MasterRecordNo);
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.FindSet();

        DstDefaultDimension.SetRange("Table ID", DstTableId);
        DstDefaultDimension.SetRange("No.", ConfigTemplateHeaderCode);
        repeat
            DstDefaultDimension.SetRange("Dimension Code", DefaultDimension."Dimension Code");
            DstDefaultDimension.SetRange("Dimension Value Code", DefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DstDefaultDimension);
        until DefaultDimension.Next() = 0;

    end;

    local procedure InsertPostCodeRec(CityName: Code[10]; PostCode: Code[10]; ExpectedRegionCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
    begin
        PostCodeRec.SetFilter(City, CityName);
        PostCodeRec.DeleteAll();
        PostCodeRec.Reset();
        PostCodeRec.SetFilter(Code, PostCode);
        PostCodeRec.DeleteAll();

        PostCodeRec.Init();
        PostCodeRec.Code := PostCode;
        PostCodeRec.City := CityName;
        PostCodeRec."Search City" := CityName;
        PostCodeRec."Country/Region Code" := ExpectedRegionCode;
        PostCodeRec.Insert(true);
    end;

    local procedure UpdateMarketingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        BusinessRelation: Record "Business Relation";
    begin
        MarketingSetup.Get();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusinessRelation.Code);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusinessRelation.Code);
        MarketingSetup.Modify(true);
    end;

    local procedure VerifyItemDimensionsVsTemplate(Item: Record Item; ConfigTemplateHeaderCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        SourceDefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Item);
        DefaultDimension.SetRange("No.", Item."No.");

        SourceDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        SourceDefaultDimension.SetRange("No.", ConfigTemplateHeaderCode);
        SourceDefaultDimension.FindSet();
        repeat
            DefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    local procedure VerifyCustomerDimensionsVsTemplate(Customer: Record Customer; ConfigTemplateHeaderCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        SourceDefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", Customer."No.");

        SourceDefaultDimension.SetRange("Table ID", Database::"Customer Templ.");
        SourceDefaultDimension.SetRange("No.", ConfigTemplateHeaderCode);
        SourceDefaultDimension.FindSet();
        repeat
            DefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    local procedure VerifyVendorDimensionsVsTemplate(Vendor: Record Vendor; ConfigTemplateHeaderCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        SourceDefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Vendor);
        DefaultDimension.SetRange("No.", Vendor."No.");

        SourceDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        SourceDefaultDimension.SetRange("No.", ConfigTemplateHeaderCode);
        SourceDefaultDimension.FindSet();
        repeat
            DefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    local procedure VerifyEmptyDefaultDimension(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        Assert.RecordIsEmpty(DefaultDimension);
    end;

    local procedure VerifyOneCustomerContactDoesExist(CustomerNo: Code[20]; ContactsCount: Integer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        Assert.RecordCount(Contact, ContactsCount + 1);

        MarketingSetup.Get();
        ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        Assert.RecordCount(ContactBusinessRelation, 1);
    end;

    local procedure VerifyOneVendorContactDoesExist(VendorNo: Code[20]; ContactsCount: Integer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        Assert.RecordCount(Contact, ContactsCount + 1);

        MarketingSetup.Get();
        ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", VendorNo);
        Assert.RecordCount(ContactBusinessRelation, 1);
    end;

    local procedure VerifyItemNoWithSeries(ItemNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField("No.", ExpectedNo);
        Item.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure VerifyCustomerNoWithSeries(CustomerNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.TestField("No.", ExpectedNo);
        Customer.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure VerifyVendorNoWithSeries(VendorNo: Code[20]; ExpectedNo: Code[20]; ExpectedNoSeries: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.TestField("No.", ExpectedNo);
        Vendor.TestField("No. Series", ExpectedNoSeries);
    end;

    local procedure CreateCustomerWithDimensions(var Customer: Record Customer)
    var
        NumberOfDimensions: Integer;
    begin
        CreateCustomerWithTemplateFieldsSet(Customer);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Customer."No.", DATABASE::Customer, NumberOfDimensions);
    end;

    local procedure CreateVendorWithDimensions(var Vendor: Record Vendor)
    var
        NumberOfDimensions: Integer;
    begin
        CreateVendorWithTemplateFieldsSet(Vendor);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Vendor."No.", DATABASE::Vendor, NumberOfDimensions);
    end;

    local procedure CreateItemWithDimensions(var Item: Record Item)
    var
        NumberOfDimensions: Integer;
    begin
        CreateItemWithTemplateFieldsSet(Item);
        NumberOfDimensions := LibraryRandom.RandIntInRange(2, 10);
        AddDefaultDimensionsToRecord(Item."No.", DATABASE::Item, NumberOfDimensions);
    end;

    local procedure CreateNewNumberSeries(var NoSeries: Record "No. Series")
    var
        NoSerCode: Code[20];
    begin
        NoSerCode := LibraryRandom.RandText(20);
        NoSeries.Code := NoSerCode;
        NoSeries.Description := NoSerCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();
    end;

    local procedure CreateNumberSeriesLine(NoSeries: Record "No. Series";
                                           StartingNumber: Code[20];
                                           EndingNumber: Code[20];
                                           IncrementBy: Integer;
                                           LineNo: Integer;
                                           Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := LineNo;
        NoSeriesLine.Validate("Starting No.", StartingNumber);
        NoSeriesLine.Validate("Ending No.", EndingNumber);
        NoSeriesLine."Increment-by No." := IncrementBy;
        NoSeriesLine.Insert();
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine.Modify();
    end;

    local procedure EditSalesSetupWithVATBusPostGrPrice(BusPostingGroupVal: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."VAT Bus. Posting Gr. (Price)" := BusPostingGroupVal;
        SalesSetup.Modify();
    end;

    local procedure UpdateItemTemplate(var ItemTempl: Record "Item Templ.")
    begin
        // Field Type: Text
        ItemTempl.Validate("Vendor Item No.", LibraryRandom.RandText(50));

        // Field Type: Code
        ItemTempl.Validate("Shelf No.", LibraryRandom.RandText(10));

        // Field Type: DateFormula
        Evaluate(ItemTempl."Lead Time Calculation", '<10D>');

        // Field Type: Option
        ItemTempl.Validate("Reordering Policy", ItemTempl."Reordering Policy"::"Fixed Reorder Qty.");

        ItemTempl.Validate("Replenishment System", ItemTempl."Replenishment System"::"Prod. Order");

        ItemTempl.Modify(true);
    end;

    local procedure ClearItemTemplate(var ItemTempl: Record "Item Templ.")
    begin
        // Field Type: Text
        ItemTempl.Validate("Vendor Item No.", '');

        // Field Type: Code
        ItemTempl.Validate("Shelf No.", '');
        ItemTempl.Validate("Gen. Prod. Posting Group", '');

        // Field Type: DateFormula
        Evaluate(ItemTempl."Lead Time Calculation", '');

        // Field Type: Option
        ItemTempl.Validate("Reordering Policy", ItemTempl."Reordering Policy"::" ");
        ItemTempl.Validate("Replenishment System", ItemTempl."Replenishment System"::Purchase);

        ItemTempl.Modify(true);
    end;

    local procedure VerifyItemAfterApplyTemplate(Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        Assert.IsTrue(Item."Vendor Item No." = ItemTempl."Vendor Item No.", InsertedItemErr);
        Assert.IsTrue(Item."Gen. Prod. Posting Group" = ItemTempl."Gen. Prod. Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."Shelf No." = ItemTempl."Shelf No.", InsertedItemErr);
        Assert.IsTrue(Item."Lead Time Calculation" = ItemTempl."Lead Time Calculation", InsertedItemErr);
    end;

    local procedure VerifyItemDataNotEqualAfterApplyTemplate(Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        Assert.IsFalse(Item."Vendor Item No." = ItemTempl."Vendor Item No.", InsertedItemErr);
        Assert.IsFalse(Item."Gen. Prod. Posting Group" = ItemTempl."Gen. Prod. Posting Group", InsertedItemErr);
        Assert.IsFalse(Item."Shelf No." = ItemTempl."Shelf No.", InsertedItemErr);
        Assert.IsFalse(Item."Lead Time Calculation" = ItemTempl."Lead Time Calculation", InsertedItemErr);
    end;

    local procedure VerifyItemAfterApplyTemplateWithPhysInvtCountingPeriod(Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        Assert.IsTrue(Item."Phys Invt Counting Period Code" = ItemTempl."Phys Invt Counting Period Code", InsertedItemErr);
        Assert.IsTrue(Item."Next Counting Start Date" <> 0D, InsertedItemErr);
        Assert.IsTrue(Item."Next Counting End Date" <> 0D, InsertedItemErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorTemplateCardHandler(var VendorTemplateCard: TestPage "Vendor Templ. Card")
    begin
        VendorTemplateCard.Description.SetValue(GlobalTemplateName);
        VendorTemplateCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateCardHandler(var CustTemplateCard: TestPage "Customer Templ. Card")
    begin
        CustTemplateCard.Description.SetValue(GlobalTemplateName);
        CustTemplateCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTemplateCardHandler(var ItemTemplateCard: TestPage "Item Templ. Card")
    begin
        ItemTemplateCard.Description.SetValue(GlobalTemplateName);
        ItemTemplateCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectTemplList: TestPage "Select Customer Templ. List")
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Get(LibraryVariableStorage.DequeueText());
        SelectTemplList.GotoRecord(CustomerTempl);
        SelectTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectTemplList: TestPage "Select Vendor Templ. List")
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.Get(LibraryVariableStorage.DequeueText());
        SelectTemplList.GotoRecord(VendorTempl);
        SelectTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectTemplList: TestPage "Select Item Templ. List")
    var
        ItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Get(LibraryVariableStorage.DequeueText());
        SelectTemplList.GotoRecord(ItemTempl);
        SelectTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeModalPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        PostCodes.FILTER.SetFilter(City, LibraryVariableStorage.DequeueText());
        PostCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateListModalPageHandler(var ConfigTemplateList: TestPage "Config. Template List")
    begin
        ConfigTemplateList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ConfigTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Queation: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
