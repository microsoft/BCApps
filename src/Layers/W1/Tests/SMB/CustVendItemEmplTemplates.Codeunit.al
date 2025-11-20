codeunit 138008 "Cust/Vend/Item/Empl Templates"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [New Templates]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        IsInitialized: Boolean;
        TemplateFeatureEnabled: Boolean;
        GlobalDimCodeTemplateErr: Label 'Value of template Global Dimension Code is wrong';
        CopyTemplateDataErr: Label 'Data in copied template is wrong';
        InsertedVendorErr: Label 'Vendor inserted with wrong data';
        InsertedCustomerErr: Label 'Customer inserted with wrong data';
        InsertedItemErr: Label 'Item inserted with wrong data';
        InsertedEmployeeErr: Label 'Employee inserted with wrong data';
        InsertedTemplateErr: Label 'Template inserted with wrong data';
        PaymentMethodErr: Label 'that cannot be found in the related table';
        ItemTemplateAllowInvoiceDiscErr: Label 'Item template should have value "Allow Invoice Disc." set to %1', Comment = '%1 = value of "Allow Invoice Disc." field which can be either true or false.';
        ItemAllowInvoiceDiscErr: Label 'Item should have received the value "Allow Invoice Disc." = % from the Item Template', Comment = '%1 = value of "Allow Invoice Disc." field which can be either true or false.';

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplValidateTemplateGlobalDimensionCodeUT()
    var
        VendorTempl: Record "Vendor Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        VendorTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        VendorTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        VendorTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Vendor Templ.", VendorTempl.Code, VendorTempl."Global Dimension 1 Code", VendorTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        VendorTempl: Record "Vendor Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Vendor Templ.", VendorTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Vendor Templ.", VendorTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        VendorTempl.Get(VendorTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Vendor Templ.", VendorTempl.Code, VendorTempl."Global Dimension 1 Code", VendorTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCopyTemplateUT()
    var
        SourceVendorTempl: Record "Vendor Templ.";
        DestVendorTempl: Record "Vendor Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(SourceVendorTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateVendorTemplate(DestVendorTempl);

        // [WHEN] Copy "DT" from "ST"
        DestVendorTempl.CopyFromTemplate(SourceVendorTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedVendorTemplateData(DestVendorTempl, SourceVendorTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Vendor Templ.", DestVendorTempl.Code, Database::"Vendor Templ.", SourceVendorTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorOneTemplateUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new vendor with one template
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor inserted with data from "T"
        VerifyVendor(Vendor, VendorTempl);
        // [THEN] Vendor dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListHandler')]
    procedure VendorTemplCreateVendorTwoTemplatesUT()
    var
        Vendor: Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new vendor with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [WHEN] Create new vendor from "T2" (VendorTemplListHandler)
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor filled with data from "T2"
        VerifyVendor(Vendor, VendorTempl2);
        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateBlockedVendorTemplateUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new vendor from template with filled "Blocked"
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = "Payment"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTempl.Blocked := VendorTempl.Blocked::Payment;
        VendorTempl.Modify(true);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor "Blocked" = "Payment"
        Assert.IsTrue(Vendor.Blocked = Vendor.Blocked::Payment, InsertedVendorErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplAdditionalFields()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        Location: Record Location;
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        VendorTemplCard: TestPage "Vendor Templ. Card";
        PartnerType: Enum "Partner Type";
        ShipmentMethodCode: Code[10];
    begin
        // [SCENARIO 406122] Additional fields copied between Vendor and Vendor Templ.
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);
        // [GIVEN] Template with "Partner Type","Location Code", "Shipment Method Code"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTemplCard.OpenEdit();
        VendorTemplCard.Filter.SetFilter(Code, VendorTempl.Code);
        VendorTemplCard."Partner Type".SetValue(PartnerType::Person);
        LibraryWarehouse.CreateLocation(Location);
        VendorTemplCard."Location Code".SetValue(Location.Code);
        ShipmentMethodCode := CreateShipmentMethodCode();
        VendorTemplCard."Shipment Method Code".SetValue(ShipmentMethodCode);
        VendorTemplCard.Close();

        // [WHEN] Create new Vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor contains fields: "Partner Type","Location Code", "Shipment Method Code"
        Vendor.TestField("Partner Type", PartnerType::Person);
        Vendor.TestField("Location Code", Location.Code);
        Vendor.TestField("Shipment Method Code", ShipmentMethodCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplValidateTemplateGlobalDimensionCodeUT()
    var
        CustomerTempl: Record "Customer Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        CustomerTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        CustomerTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        CustomerTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Customer Templ.", CustomerTempl.Code, CustomerTempl."Global Dimension 1 Code", CustomerTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        CustomerTempl: Record "Customer Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Customer Templ.", CustomerTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Customer Templ.", CustomerTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        CustomerTempl.Get(CustomerTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Customer Templ.", CustomerTempl.Code, CustomerTempl."Global Dimension 1 Code", CustomerTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCopyTemplateUT()
    var
        SourceCustomerTempl: Record "Customer Templ.";
        DestCustomerTempl: Record "Customer Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(SourceCustomerTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateCustomerTemplate(DestCustomerTempl);

        // [WHEN] Copy "DT" from "ST"
        DestCustomerTempl.CopyFromTemplate(SourceCustomerTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedCustomerTemplateData(DestCustomerTempl, SourceCustomerTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Customer Templ.", DestCustomerTempl.Code, Database::"Customer Templ.", SourceCustomerTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerOneTemplateUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new customer with one template
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with data from "T"
        VerifyCustomer(Customer, CustomerTempl);
        // [THEN] Customer dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerOneTemplateDocSendingProfileUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        DocumentSendingProfile: Record "Document Sending Profile";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 389638] Create new customer with one template and filled in "Document Sending Profile"
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        UpdateDocSendingProfile(DocumentSendingProfile, CustomerTempl);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with data from "T"
        VerifyCustomer(Customer, CustomerTempl);
        // [THEN] Customer dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl.Code);
        // [THEN] "Document Sending Profile" filled in customer
        Assert.AreEqual(DocumentSendingProfile.Code, Customer."Document Sending Profile", 'Wrong document sending profile');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectCustomerTemplListHandler')]
    procedure CustomerTemplCreateCustomerTwoTemplatesUT()
    var
        Customer: Record Customer;
        CustomerTempl1: Record "Customer Templ.";
        CustomerTempl2: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new customer with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl2);
        LibraryVariableStorage.Enqueue(CustomerTempl2.Code);

        // [WHEN] Create new customer from "T2" (CustomerTemplListHandler)
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Vendor filled with data from "T2"
        VerifyCustomer(Customer, CustomerTempl2);
        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateBlockedCustomerTemplateUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new customer from template with filled "Blocked"
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = "All"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustomerTempl.Blocked := CustomerTempl.Blocked::All;
        CustomerTempl.Modify(true);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer "Blocked" = "All"
        Assert.IsTrue(Customer.Blocked = Customer.Blocked::All, InsertedCustomerErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplAdditionalFields()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        Location: Record Location;
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        CustomerTemplCard: TestPage "Customer Templ. Card";
        PartnerType: Enum "Partner Type";
    begin
        // [SCENARIO 406122] Additional fields copied between Customer and Customer Templ.
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);
        // [GIVEN] Template with "Partner Type","Location Code"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustomerTemplCard.OpenEdit();
        CustomerTemplCard.Filter.SetFilter(Code, CustomerTempl.Code);
        CustomerTemplCard."Partner Type".SetValue(PartnerType::Company);
        LibraryWarehouse.CreateLocation(Location);
        CustomerTemplCard."Location Code".SetValue(Location.Code);
        CustomerTemplCard.Close();

        // [WHEN] Create new Customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer contains fields: "Partner Type","Location Code"
        Customer.TestField("Partner Type", PartnerType::Company);
        Customer.TestField("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplValidateTemplateGlobalDimensionCodeUT()
    var
        ItemTempl: Record "Item Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        ItemTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        ItemTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        ItemTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Item Templ.", ItemTempl.Code, ItemTempl."Global Dimension 1 Code", ItemTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        ItemTempl: Record "Item Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Item Templ.", ItemTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Item Templ.", ItemTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        ItemTempl.Get(ItemTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Item Templ.", ItemTempl.Code, ItemTempl."Global Dimension 1 Code", ItemTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCopyTemplateUT()
    var
        SourceItemTempl: Record "Item Templ.";
        DestItemTempl: Record "Item Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(SourceItemTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateItemTemplate(DestItemTempl);

        // [WHEN] Copy "DT" from "ST"
        DestItemTempl.CopyFromTemplate(SourceItemTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedItemTemplateData(DestItemTempl, SourceItemTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Item Templ.", DestItemTempl.Code, Database::"Item Templ.", SourceItemTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemOneTemplateUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item with one template
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with data from template
        VerifyItem(Item, ItemTempl);
        // [THEN] Item dimensions inserted from template dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectItemTemplListHandler')]
    procedure ItemTemplCreateItemTwoTemplatesUT()
    var
        Item: Record Item;
        ItemTempl1: Record "Item Templ.";
        ItemTempl2: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl2);
        LibraryVariableStorage.Enqueue(ItemTempl2.Code);

        // [WHEN] Create new Item from "T2" (ItemTemplListHandler)
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item filled with data from "T2"
        VerifyItem(Item, ItemTempl2);
        // [THEN] Item dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateBlockedItemTemplateUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 363951] Create new item from template with filled "Blocked"
        // [SCENARIO 378441] Add "Service Blocked"
        // [SCENARIO 382546] Add "Production Blocked"
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with "Blocked" = true, "Sales Blocked" = true, "Service Blocked" = true, "Production Blocked" = Output, "Purchasing Blocked" = true
        LibraryTemplates.CreateItemTemplate(ItemTempl);
        ItemTempl.Blocked := true;
        ItemTempl."Sales Blocked" := true;
        ItemTempl."Service Blocked" := true;
        ItemTempl."Production Blocked" := ItemTempl."Production Blocked"::Output;
        ItemTempl."Purchasing Blocked" := true;
        ItemTempl.Modify(true);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item "Blocked" = true
        // [THEN] Item "Sales Blocked" = true
        // [THEN] Item "Service Blocked" = true
        // [THEN] Item "Production Blocked" = Output
        // [THEN] Item "Purchasing Blocked" = true
        Assert.IsTrue(Item.Blocked, InsertedItemErr);
        Assert.IsTrue(Item."Sales Blocked", InsertedItemErr);
        Assert.IsTrue(Item."Service Blocked", InsertedItemErr);
        Assert.AreEqual(ItemTempl."Production Blocked", Item."Production Blocked", InsertedItemErr);
        Assert.IsTrue(Item."Purchasing Blocked", InsertedItemErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplAdditionalFields()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        ItemTemplCard: TestPage "Item Templ. Card";
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNosCode: Code[20];
        LotNosCode: Code[20];
    begin
        // [SCENARIO 406122] Additional fields copied between Item and Item Templ.
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);
        // [GIVEN] Template with "Item Tracking Code", "Serial Nos.", "Lot Nos."
        LibraryTemplates.CreateItemTemplate(ItemTempl);
        ItemTemplCard.OpenEdit();
        ItemTemplCard.Filter.SetFilter(Code, ItemTempl.Code);
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTemplCard."Item Tracking Code".SetValue(ItemTrackingCode.Code);
        SerialNosCode := LibraryERM.CreateNoSeriesCode();
        ItemTemplCard."Serial Nos.".SetValue(SerialNosCode);
        LotNosCode := LibraryERM.CreateNoSeriesCode();
        ItemTemplCard."Lot Nos.".SetValue(LotNosCode);
        ItemTemplCard.Close();

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item contains fields: "Item Tracking Code", "Serial Nos.", "Lot Nos." 
        Item.TestField("Item Tracking Code", ItemTrackingCode.Code);
        Item.TestField("Serial Nos.", SerialNosCode);
        Item.TestField("Lot Nos.", LotNosCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplValidateTemplateGlobalDimensionCodeUT()
    var
        EmployeeTempl: Record "Employee Templ.";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 353440] Validate "Global Dimension X Code" template field inserts Default Dimension
        Initialize();

        // [GIVEN] Template
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);

        // [WHEN] Validate "Global Dimension 1 Code" with "DV1"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        EmployeeTempl.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Validate "Global Dimension 2 Code" with "DV2"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        EmployeeTempl.Validate("Global Dimension 2 Code", DimensionValue.Code);
        EmployeeTempl.Modify(true);

        // [THEN] Default dimensions "DV1" and "DV2" are inserted
        VerifyTemplateGlobalDimensionIsDefaultDimension(Database::"Employee Templ.", EmployeeTempl.Code, EmployeeTempl."Global Dimension 1 Code", EmployeeTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplInsertDefaultDimensionWithGlobalDimensionCodeUT()
    var
        EmployeeTempl: Record "Employee Templ.";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 353440] Inserting "Global Dimension X Code" Default Dimension updates "Global Dimension X Code" template field
        Initialize();

        // [GIVEN] Template with empty "Global Dimension 1 Code" and "Global Dimension 2 Code"
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);

        // [WHEN] Insert "DV1" Default Dimension related to "Global Dimension 1 Code"
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Employee Templ.", EmployeeTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Insert "DV2" Default Dimension related to "Global Dimension 2 Code"
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::"Employee Templ.", EmployeeTempl.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [THEN] Template "Global Dimension 1 Code" = "DV1"
        // [THEN] Template "Global Dimension 2 Code" = "DV2"
        EmployeeTempl.Get(EmployeeTempl.Code);
        VerifyTemplateGlobalDimensionCodeValue(Database::"Employee Templ.", EmployeeTempl.Code, EmployeeTempl."Global Dimension 1 Code", EmployeeTempl."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCopyTemplateUT()
    var
        SourceEmployeeTempl: Record "Employee Templ.";
        DestEmployeeTempl: Record "Employee Templ.";
    begin
        // [SCENARIO 353440] Copy one template from the other one
        Initialize();

        // [GIVEN] Source template "ST" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(SourceEmployeeTempl);

        // [GIVEN] Destination empty template "DT"
        LibraryTemplates.CreateEmployeeTemplate(DestEmployeeTempl);

        // [WHEN] Copy "DT" from "ST"
        DestEmployeeTempl.CopyFromTemplate(SourceEmployeeTempl);

        // [THEN] "DT" data copied from "ST"
        VerifyCopiedEmployeeTemplateData(DestEmployeeTempl, SourceEmployeeTempl);
        // [THEN] "DT" dimensions copied from "ST" dimensions
        VerifyDimensions(Database::"Employee Templ.", DestEmployeeTempl.Code, Database::"Employee Templ.", SourceEmployeeTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCreateEmployeeOneTemplateUT()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new employee with one template
        Initialize();
        EmployeeTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);

        // [WHEN] Create new employee
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee inserted with data from template
        VerifyEmployee(Employee, EmployeeTempl);
        // [THEN] Employee dimensions inserted from template dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectEmployeeTemplListHandler')]
    procedure EmployeeTemplCreateEmployeeTwoTemplatesUT()
    var
        Employee: Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new employee with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [WHEN] Create new employee from "T2" (EmployeeTemplListHandler)
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee filled with data from "T2"
        VerifyEmployee(Employee, EmployeeTempl2);
        // [THEN] Employee dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectEmployeeTemplListHandler')]
    procedure EmployeeTemplCreateEmployeeFromContactTwoTemplatesUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Employee: Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Create new employee from person contact with two templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [GIVEN] Person contact "C"
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create new employee from "C" using "T2" (EmployeeTemplListHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [THEN] Employee filled with data from "C" and "T2"
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No.");
        Employee.Get(ContBusRel."No.");
        Assert.IsTrue(Employee."First Name" = Contact.Name, InsertedEmployeeErr);
        VerifyEmployee(Employee, EmployeeTempl2);

        // [THEN] Employee dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectEmployeeTemplListInvokeCancelHandler')]
    procedure EmployeeTemplCreateEmployeeFromContactTwoTemplatesInvokeCancelUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        EmployeeTempl: Record "Employee Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        i: Integer;
    begin
        // [SCENARIO 365727] Create new employee from person contact with two templates and invoke cancel the on the template list
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetEmplTemplateFeatureEnabled(true);

        // [GIVEN] Two templates
        for i := 1 to 2 do
            LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);

        // [GIVEN] Person contact "C"
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create new employee from "C" and invoke cancel on the template list (SelectEmployeeTemplListInvokeCancelHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [THEN] Employee was not created
        Assert.IsFalse(ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No."), 'Employee should not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListHandler')]
    procedure VendorTemplCreateVendorFromContactTwoTemplatesUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Vendor: Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Create new vendor from company contact with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        VendorTempl2.Get(VendorTempl2.Code);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [GIVEN] Company contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create new vendor from "C" using "T2" (VendorTemplListHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendor();

        // [THEN] Vendor filled with data from "C" and "T2"
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Vendor, Contact."No.");
        Vendor.Get(ContBusRel."No.");
        Assert.IsTrue(Vendor.Name = Contact.Name, InsertedVendorErr);
        VerifyVendor(Vendor, VendorTempl2);

        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListInvokeCancelHandler')]
    procedure VendorTemplCreateVendorFromContactTwoTemplatesInvokeCancelUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        VendorTempl: Record "Vendor Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        i: Integer;
    begin
        // [SCENARIO 365727] Create new vendor from company contact with two existing templates and invoke cancel the on the template list
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Two templates
        for i := 1 to 2 do
            CreateVendorTemplateWithDataAndDimensions(VendorTempl);

        // [GIVEN] Company contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create new vendor from "C" and invoke cancel on the template list (SelectVendorTemplListInvokeCancelHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendor();

        // [THEN] Vendor was not created
        Assert.IsFalse(ContBusRel.FindByContact(ContBusRel."Link to Table"::Vendor, Contact."No."), 'Vendor should not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListInvokeCancelHandler')]
    procedure CustomerTemplCreateCustomerFromContactTwoTemplatesInvokeCancelUT()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        CustomerTempl: Record "Customer Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        i: Integer;
    begin
        // [SCENARIO 365727] Create new customer from company contact with two existing templates and invoke cancel the on the template list
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Two templates
        for i := 1 to 2 do
            CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);

        // [GIVEN] Company contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create new customer from "C" and invoke cancel on the employee template list (SelectVendorTemplListInvokeCancelHandler)
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendor();

        // [THEN] Vendor was not created
        Assert.IsFalse(ContBusRel.FindByContact(ContBusRel."Link to Table"::Customer, Contact."No."), 'Customer should not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure VendorTemplCreateVendorFromContactNoTemplatesExistUT()
    var
        Contact: Record Contact;
        VendorTempl: Record "Vendor Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Create new vendor from company contact when no vendor templates exist
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] No Vendor Templates should exist
        if not VendorTempl.IsEmpty() then
            VendorTempl.DeleteAll();

        // [GIVEN] Company contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create new vendor from "C"
        // [THEN] Vendor was not created and message displays
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendor();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectCustomerTemplListHandler,ConfirmHandler')]
    procedure CustomerTemplApplyTemplateFromCustomerTwoTemplatesUT()
    var
        Customer: Record Customer;
        CustomerTempl1: Record "Customer Templ.";
        CustomerTempl2: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template to customer with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl2);
        CustomerTempl2.Get(CustomerTempl2.Code);
        LibraryVariableStorage.Enqueue(CustomerTempl2.Code);

        // [GIVEN] Customer "C"
        Customer.Init();
        Customer.Insert(true);

        // [WHEN] Apply "T2" to "C"
        CustomerTemplMgt.UpdateCustomerFromTemplate(Customer);

        // [THEN] "C" filled with data from "T2"
        Customer.Get(Customer."No.");
        VerifyCustomer(Customer, CustomerTempl2);

        // [THEN] Customer dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListHandler,ConfirmHandler')]
    procedure VendorTemplApplyTemplateFromVendorTwoTemplatesUT()
    var
        Vendor: Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template to vendor with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        VendorTempl2.Get(VendorTempl2.Code);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [GIVEN] Vendor "V"
        Vendor.Init();
        Vendor.Insert(true);

        // [WHEN] Apply "T2" to "V"
        VendorTemplMgt.UpdateVendorFromTemplate(Vendor);

        // [THEN] "V" filled with data from "T2"
        Vendor.Get(Vendor."No.");
        VerifyVendor(Vendor, VendorTempl2);

        // [THEN] Vendor dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectItemTemplListHandler,ConfirmHandler')]
    procedure ItemTemplApplyTemplateFromItemTwoTemplatesUT()
    var
        Item: Record Item;
        ItemTempl1: Record "Item Templ.";
        ItemTempl2: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template to item with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl2);
        ItemTempl2.Get(ItemTempl2.Code);
        LibraryVariableStorage.Enqueue(ItemTempl2.Code);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [WHEN] Apply "T2" to "I"
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [THEN] "I" filled with data from "T2"
        Item.Get(Item."No.");
        VerifyItem(Item, ItemTempl2);

        // [THEN] Item dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectCustomerTemplListHandler,ConfirmHandler')]
    procedure CustomerTemplApplyTemplateForTwoCustomersTwoTemplatesUT()
    var
        Customer: array[3] of Record Customer;
        CustomerTempl1: Record "Customer Templ.";
        CustomerTempl2: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template for two customers with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl2);
        CustomerTempl2.Get(CustomerTempl2.Code);
        LibraryVariableStorage.Enqueue(CustomerTempl2.Code);

        // [GIVEN] Tow customers "C1" and "C2"
        Customer[1].Init();
        Customer[1].Insert(true);
        Customer[2].Init();
        Customer[2].Insert(true);
        Customer[3].SetFilter("No.", '%1|%2', Customer[1]."No.", Customer[2]."No.");

        // [WHEN] Apply "T2" for "C1" and "C2" at one time
        CustomerTemplMgt.UpdateCustomersFromTemplate(Customer[3]);

        // [THEN] "C1" filled with data from "T2"
        Customer[1].Get(Customer[1]."No.");
        VerifyCustomer(Customer[1], CustomerTempl2);

        // [THEN] "C1" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Customer, Customer[1]."No.", Database::"Customer Templ.", CustomerTempl2.Code);

        // [THEN] "C2" filled with data from "T2"
        Customer[2].Get(Customer[2]."No.");
        VerifyCustomer(Customer[2], CustomerTempl2);

        // [THEN] "C2" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Customer, Customer[2]."No.", Database::"Customer Templ.", CustomerTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectVendorTemplListHandler,ConfirmHandler')]
    procedure VendorTemplApplyTemplateForTwoVendorsTwoTemplatesUT()
    var
        Vendor: array[3] of Record Vendor;
        VendorTempl1: Record "Vendor Templ.";
        VendorTempl2: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template for two vendors with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl2);
        VendorTempl2.Get(VendorTempl2.Code);
        LibraryVariableStorage.Enqueue(VendorTempl2.Code);

        // [GIVEN] Two vendors "V1" and "V2"
        Vendor[1].Init();
        Vendor[1].Insert(true);
        Vendor[2].Init();
        Vendor[2].Insert(true);
        Vendor[3].SetFilter("No.", '%1|%2', Vendor[1]."No.", Vendor[2]."No.");

        // [WHEN] Apply "T2" for "V1" and "V2" at one time
        VendorTemplMgt.UpdateVendorsFromTemplate(Vendor[3]);

        // [THEN] "V1" filled with data from "T2"
        Vendor[1].Get(Vendor[1]."No.");
        VerifyVendor(Vendor[1], VendorTempl2);

        // [THEN] "V1" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor[1]."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        // [THEN] "V2" filled with data from "T2"
        Vendor[2].Get(Vendor[2]."No.");
        VerifyVendor(Vendor[2], VendorTempl2);

        // [THEN] "V2" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Vendor, Vendor[2]."No.", Database::"Vendor Templ.", VendorTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectItemTemplListHandler,ConfirmHandler')]
    procedure ItemTemplApplyTemplateForTwoItemsTwoTemplatesUT()
    var
        Item: array[3] of Record Item;
        ItemTempl1: Record "Item Templ.";
        ItemTempl2: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 365727] Apply template for two items with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl2);
        ItemTempl2.Get(ItemTempl2.Code);
        LibraryVariableStorage.Enqueue(ItemTempl2.Code);

        // [GIVEN] Two items "I1" and "I2"
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        Item[3].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");

        // [WHEN] Apply "T2" for "I1" and "I2" at one time
        ItemTemplMgt.UpdateItemsFromTemplate(Item[3]);

        // [THEN] "I1" filled with data from "T2"
        Item[1].Get(Item[1]."No.");
        VerifyItem(Item[1], ItemTempl2);

        // [THEN] "I1" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Item, Item[1]."No.", Database::"Item Templ.", ItemTempl2.Code);

        // [THEN] "I2" filled with data from "T2"
        Item[2].Get(Item[2]."No.");
        VerifyItem(Item[1], ItemTempl2);

        // [THEN] "I2" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Item, Item[2]."No.", Database::"Item Templ.", ItemTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemPriceIncludesVATVATPostingSetupExistsUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item via template with "Price Includes VAT" = true
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions, "Price Includes VAT" = true
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl."Price Includes VAT" := true;
        ItemTempl.Modify(true);

        // [GIVEN] Sales setup "VAT Bus. Posting Gr. (Price)" filled with data in order "Price Includes VAT" can be enabled
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        SalesReceivablesSetup.Modify();
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, ItemTempl."VAT Prod. Posting Group");

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with data from template
        VerifyItem(Item, ItemTempl);
        // [THEN] Item dimensions inserted from template dimensions
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
        // [THEN] Item "Price Includes VAT" = true
        Assert.IsTrue(Item."Price Includes VAT", 'Price Includes VAT should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemPriceIncludesVATVATPostingSetupDoesNotExistUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new item via template with "Price Includes VAT" = true
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions, "Price Includes VAT" = true
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl."Price Includes VAT" := true;
        ItemTempl.Modify(true);

        // [GIVEN] Sales setup "VAT Bus. Posting Gr. (Price)" filled with data in order "Price Includes VAT" cannot be enabled
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        SalesReceivablesSetup.Modify();

        // [WHEN] Create new Item
        asserterror ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item is not created, error message thrown by system
        Assert.ExpectedErrorCannotFind(Database::"VAT Posting Setup");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerTemplCardHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplSaveCustomerAsTemplate()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        DimensionValue: Record "Dimension Value";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384191] Save customer as a template
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Customer with dimensions
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        Customer.Validate("Global Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        Customer.Validate("Global Dimension 2 Code", DimensionValue.Code);
        Customer.Modify(true);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] Save customer as template
        CustomerTemplMgt.SaveAsTemplate(Customer);

        // [THEN] New customer template with dimensions is created (UI part verified in CustomerTemplCardHandler)
        CustomerTempl.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Customer."Customer Posting Group", CustomerTempl."Customer Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Customer."Gen. Bus. Posting Group", CustomerTempl."Gen. Bus. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Customer."VAT Bus. Posting Group", CustomerTempl."VAT Bus. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Customer."Global Dimension 1 Code", CustomerTempl."Global Dimension 1 Code", InsertedTemplateErr);
        Assert.AreEqual(Customer."Global Dimension 2 Code", CustomerTempl."Global Dimension 2 Code", InsertedTemplateErr);
        VerifyDimensions(Database::"Customer Templ.", CustomerTempl.Code, Database::Customer, Customer."No.");
    end;

    [Test]
    [HandlerFunctions('VendorTemplCardHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplSaveVendorAsTemplate()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        DimensionValue: Record "Dimension Value";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384191] Save vendor as a template
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Vendor with dimensions
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        Vendor.Validate("Global Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        Vendor.Validate("Global Dimension 2 Code", DimensionValue.Code);
        Vendor.Modify(true);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [WHEN] Save vendor as template
        VendorTemplMgt.SaveAsTemplate(Vendor);

        // [THEN] New vendor template with dimensions is created (UI part verified in VendorTemplCardHandler)
        VendorTempl.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Vendor."Vendor Posting Group", VendorTempl."Vendor Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Vendor."Gen. Bus. Posting Group", VendorTempl."Gen. Bus. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Vendor."VAT Bus. Posting Group", VendorTempl."VAT Bus. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Vendor."Global Dimension 1 Code", VendorTempl."Global Dimension 1 Code", InsertedTemplateErr);
        Assert.AreEqual(Vendor."Global Dimension 2 Code", VendorTempl."Global Dimension 2 Code", InsertedTemplateErr);
        VerifyDimensions(Database::"Vendor Templ.", VendorTempl.Code, Database::Vendor, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTemplCardHandler')]
    [Scope('OnPrem')]
    procedure ItemTemplSaveItemAsTemplate()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        DimensionValue: Record "Dimension Value";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384191] Save item as a template
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Item with dimensions
        LibraryInventory.CreateItem(Item);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        Item.Validate("Global Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        Item.Validate("Global Dimension 2 Code", DimensionValue.Code);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Save item as template
        ItemTemplMgt.SaveAsTemplate(Item);

        // [THEN] New item template with dimensions is created (UI part verified in ItemTemplCardHandler)
        ItemTempl.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Item."Inventory Posting Group", ItemTempl."Inventory Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Item."Gen. Prod. Posting Group", ItemTempl."Gen. Prod. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Item."VAT Prod. Posting Group", ItemTempl."VAT Prod. Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Item."Global Dimension 1 Code", ItemTempl."Global Dimension 1 Code", InsertedTemplateErr);
        Assert.AreEqual(Item."Global Dimension 2 Code", ItemTempl."Global Dimension 2 Code", InsertedTemplateErr);
        ItemTempl.TestField("Reordering Policy", Item."Reordering Policy");
        ItemTempl.TestField("Replenishment System", Item."Replenishment System");
        VerifyDimensions(Database::"Item Templ.", ItemTempl.Code, Database::Item, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorWithNoSeriesUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 388434] Create new vendor with "No. Series" assigned in template
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "No. Series" ("NS") filled in
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        VendorTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('VT'));
        VendorTempl.Modify(true);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor inserted with "No." assigned from "NS"
        VerifyCustVendItemEmplNo(VendorTempl."No. Series", Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorWithoutNoSeriesUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 388434] Create new vendor with empty "No. Series" in template
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] "Vendor Nos." filled in "Purchases & Payables Setup"
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Vendor Nos." := LibraryERM.CreateNoSeriesCode('PPS');
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Template with empty "No. Series"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [WHEN] Create new vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor inserted with "No." assigned from "Purchases & Payables Setup"
        VerifyCustVendItemEmplNo(PurchasesPayablesSetup."Vendor Nos.", Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerWithNoSeriesUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 388434] Create new Customer with "No. Series" assigned in template
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "No. Series" ("NS") filled in
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        CustomerTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('CT'));
        CustomerTempl.Modify(true);

        // [WHEN] Create new Customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with "No." assigned from "NS"
        VerifyCustVendItemEmplNo(CustomerTempl."No. Series", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerWithoutNoSeriesUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 388434] Create new Customer with empty "No. Series" in template
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] "Customer Nos." filled in "Sales & Receivables Setup"
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Customer Nos." := LibraryERM.CreateNoSeriesCode('SRS');
        SalesReceivablesSetup.Modify();

        // [GIVEN] Template with empty "No. Series"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [WHEN] Create new Customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with "No." assigned from "Sales & Receivables Setup"
        VerifyCustVendItemEmplNo(SalesReceivablesSetup."Customer Nos.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemWithNoSeriesUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 388434] Create new Item with "No. Series" assigned in template
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "No. Series" ("NS") filled in
        LibraryTemplates.CreateItemTemplate(ItemTempl);
        ItemTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('IT'));
        ItemTempl.Modify(true);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with "No." assigned from "NS"
        VerifyCustVendItemEmplNo(ItemTempl."No. Series", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemWithoutNoSeriesUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        InventorySetup: Record "Inventory Setup";
        SavedItemNosCode: Code[20];
    begin
        // [SCENARIO 388434] Create new Item with empty "No. Series" in template
        Initialize();
        ItemTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] "Item Nos." filled in "Inventory Setup"
        InventorySetup.Get();
        SavedItemNosCode := InventorySetup."Item Nos.";
        InventorySetup."Item Nos." := LibraryERM.CreateNoSeriesCode('IS');
        InventorySetup.Modify();

        // [GIVEN] Template with empty "No. Series"
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with "No." assigned from "Inventory Setup"
        VerifyCustVendItemEmplNo(InventorySetup."Item Nos.", Item."No.");

        InventorySetup."Item Nos." := SavedItemNosCode;
        InventorySetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCreateEmployeeWithNoSeriesUT()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendEmployeeEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 388434] Create new Employee with "No. Series" assigned in template
        Initialize();
        EmployeeTempl.DeleteAll();
        BindSubscription(CustVendEmployeeEmplTemplates);
        CustVendEmployeeEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template with "No. Series" ("NS") filled in
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);
        EmployeeTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('ET'));
        EmployeeTempl.Modify(true);

        // [WHEN] Create new Employee
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee inserted with "No." assigned from "NS"
        VerifyCustVendItemEmplNo(EmployeeTempl."No. Series", Employee."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeTemplCreateEmployeeWithoutNoSeriesUT()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendEmployeeEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        HumanResourcesSetup: Record "Human Resources Setup";
        SavedEmployeeNosCode: code[20];
    begin
        // [SCENARIO 388434] Create new Employee with empty "No. Series" in template
        Initialize();
        EmployeeTempl.DeleteAll();
        BindSubscription(CustVendEmployeeEmplTemplates);
        CustVendEmployeeEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] "Employee Nos." filled in "Human Resources Setup"
        HumanResourcesSetup.Get();
        SavedEmployeeNosCode := HumanResourcesSetup."Employee Nos.";
        HumanResourcesSetup."Employee Nos." := LibraryERM.CreateNoSeriesCode('HRS');
        HumanResourcesSetup.Modify();

        // [GIVEN] Template with empty "No. Series"
        LibraryTemplates.CreateEmployeeTemplate(EmployeeTempl);

        // [WHEN] Create new Employee
        EmployeeTemplMgt.InsertEmployeeFromTemplate(Employee);

        // [THEN] Employee inserted with "No." assigned from "Human Resources Setup"
        VerifyCustVendItemEmplNo(HumanResourcesSetup."Employee Nos.", Employee."No.");

        HumanResourcesSetup."Employee Nos." := SavedEmployeeNosCode;
        HumanResourcesSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectEmployeeTemplListHandler,ConfirmHandler')]
    procedure EmployeeTemplApplyTemplateFromEmployeeTwoTemplatesUT()
    var
        Employee: Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384920] Apply template to Employee with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        EmployeeTempl2.Get(EmployeeTempl2.Code);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [GIVEN] Employee "E"
        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Apply "T2" to "E"
        EmployeeTemplMgt.UpdateEmployeeFromTemplate(Employee);

        // [THEN] "E" filled with data from "T2"
        Employee.Get(Employee."No.");
        VerifyEmployee(Employee, EmployeeTempl2);

        // [THEN] Employee dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectEmployeeTemplListHandler,ConfirmHandler')]
    procedure EmployeeTemplApplyTemplateForTwoEmployeesTwoTemplatesUT()
    var
        Employee: array[3] of Record Employee;
        EmployeeTempl1: Record "Employee Templ.";
        EmployeeTempl2: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384920] Apply template for two Employees with two existing templates
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T1" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl1);

        // [GIVEN] Template "T2" with data and dimensions
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl2);
        EmployeeTempl2.Get(EmployeeTempl2.Code);
        LibraryVariableStorage.Enqueue(EmployeeTempl2.Code);

        // [GIVEN] Tow Employees "E1" and "E2"
        LibraryHumanResource.CreateEmployee(Employee[1]);
        LibraryHumanResource.CreateEmployee(Employee[2]);
        Employee[3].SetFilter("No.", '%1|%2', Employee[1]."No.", Employee[2]."No.");

        // [WHEN] Apply "T2" for "E1" and "E2" at one time
        EmployeeTemplMgt.UpdateEmployeesFromTemplate(Employee[3]);

        // [THEN] "E1" filled with data from "T2"
        Employee[1].Get(Employee[1]."No.");
        VerifyEmployee(Employee[1], EmployeeTempl2);

        // [THEN] "E1" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee[1]."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        // [THEN] "E2" filled with data from "T2"
        Employee[2].Get(Employee[2]."No.");
        VerifyEmployee(Employee[2], EmployeeTempl2);

        // [THEN] "E2" dimensions inserted from "T2" dimensions
        VerifyDimensions(Database::Employee, Employee[2]."No.", Database::"Employee Templ.", EmployeeTempl2.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EmployeeTemplCardHandler')]
    [Scope('OnPrem')]
    procedure EmployeeTemplSaveEmployeeAsTemplate()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        DimensionValue: Record "Dimension Value";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 384920] Save Employee as a template
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Employee with dimensions
        CreateEmployeeWithData(Employee);

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        Employee.Validate("Global Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        Employee.Validate("Global Dimension 2 Code", DimensionValue.Code);
        Employee.Modify(true);
        LibraryVariableStorage.Enqueue(Employee."No.");

        // [WHEN] Save Employee as template
        EmployeeTemplMgt.SaveAsTemplate(Employee);

        // [THEN] New Employee template with dimensions is created (UI part verified in EmployeeTemplCardHandler)
        EmployeeTempl.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Employee."Employee Posting Group", EmployeeTempl."Employee Posting Group", InsertedTemplateErr);
        Assert.AreEqual(Employee."Statistics Group Code", EmployeeTempl."Statistics Group Code", InsertedTemplateErr);
        Assert.AreEqual(Employee."Global Dimension 1 Code", EmployeeTempl."Global Dimension 1 Code", InsertedTemplateErr);
        Assert.AreEqual(Employee."Global Dimension 2 Code", EmployeeTempl."Global Dimension 2 Code", InsertedTemplateErr);
        VerifyDimensions(Database::"Employee Templ.", EmployeeTempl.Code, Database::Employee, Employee."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemNonstockAutoItemUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        CatalogItemManagement: Codeunit "Catalog Item Management";
    begin
        // [SCENARIO 383147] Create new item from non stock item with template using NonstockAutoItem() procedure from "Catalog Item Management" codeunit
        // [SCENARIO 497759] Test non-default Costing Method in Item Template
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [GIVEN] Template with non-default Costing Method: Average
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::Average);
        ItemTempl.Modify(true);

        // [GIVEN] Nonstock item
        CreateNonstockItem(NonstockItem, ItemTempl.Code);

        // [WHEN] Create new Item
        CatalogItemManagement.NonstockAutoItem(NonstockItem);

        // [THEN] Item inserted with data from template
        Item.Get(NonstockItem."Vendor Item No.");
        VerifyItem(Item, ItemTempl);
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemFromNonstockUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        CatalogItemManagement: Codeunit "Catalog Item Management";
    begin
        // [SCENARIO 383147] Create new item from non stock item with template using CreateItemFromNonstock() procedure from "Catalog Item Management" codeunit
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Reordering Policy", ItemTempl."Reordering Policy"::Order);
        ItemTempl.Modify(true);
        // [GIVEN] Nonstock item
        CreateNonstockItem(NonstockItem, ItemTempl.Code);

        // [WHEN] Create new Item
        CatalogItemManagement.CreateItemFromNonstock(NonstockItem);

        // [THEN] Item inserted with data from template
        Item.Get(NonstockItem."Vendor Item No.");
        VerifyItem(Item, ItemTempl);
        VerifyDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
        // [THEN] Item "Reordering Policy" = item template "Reordering Policy"
        Item.TestField("Reordering Policy", ItemTempl."Reordering Policy");
    end;

    [Test]
    [HandlerFunctions('CreateCustVendStrMenuHandler,SelectVendorTemplListHandler,VendorCardHandler')]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorGetVendorNoUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        VendorNo: Code[20];
    begin
        // [SCENARIO 383147] Create new vendor with template using GetVendorNo() procedure from "Vendor" record
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetVendTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl);
        LibraryVariableStorage.Enqueue(VendorTempl.Code);

        // [WHEN] Create new vendor
        VendorNo := Vendor.GetVendorNo(LibraryUtility.GenerateGUID());

        // [THEN] Vendor inserted with data from "T"
        Vendor.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(VendorNo, Vendor."No.", 'Wrong vendor card shown');
        VerifyVendor(Vendor, VendorTempl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateCustVendStrMenuHandler,SelectCustomerTemplListHandler,CustomerCardHandler')]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerGetCustNoUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 383147] Create new Customer with template using GetCustNo() procedure from "Customer" record
        Initialize();
        Customer.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);

        // [WHEN] Create new Customer
        CustomerNo := Customer.GetCustNo(LibraryUtility.GenerateGUID());

        // [THEN] Customer inserted with data from "T"
        Customer.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(CustomerNo, Customer."No.", 'Wrong Customer card shown');
        VerifyCustomer(Customer, CustomerTempl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCreateCustomerWithAdditionalFields()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 353440] Create new customer with additional fields ("Customer Discount Group", "Customer Price Group" and others)
        Initialize();
        CustomerTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with additional data and dimensions
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        UpdateCustomerTemplateAdditionalFields(CustomerTempl);

        // [WHEN] Create new customer
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Customer inserted with data from "T"
        VerifyCustomer(Customer, CustomerTempl);
        // [THEN] Customer dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Customer, Customer."No.", Database::"Customer Templ.", CustomerTempl.Code);
        // [THEN] Customer contains data from "T" additional fields
        VerifyCustomerAdditionalFields(Customer, CustomerTempl);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCreateVendorOneTemplateDocSendingProfileUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        DocumentSendingProfile: Record "Document Sending Profile";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 389638] Create new Vendor with one template and filled in "Document Sending Profile"
        Initialize();
        VendorTempl.DeleteAll();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Template "T" with data and dimensions
        CreateVendorTemplateWithDataAndDimensions(VendorTempl);
        UpdateVendorTemplDocSendingProfile(DocumentSendingProfile, VendorTempl);

        // [WHEN] Create new Vendor
        VendorTemplMgt.InsertVendorFromTemplate(Vendor);

        // [THEN] Vendor inserted with data from "T"
        VerifyVendor(Vendor, VendorTempl);
        // [THEN] Vendor dimensions inserted from "T" dimensions
        VerifyDimensions(Database::Vendor, Vendor."No.", Database::"Vendor Templ.", VendorTempl.Code);
        // [THEN] "Document Sending Profile" filled in Vendor
        Assert.AreEqual(DocumentSendingProfile.Code, Vendor."Document Sending Profile", 'Wrong document sending profile');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateApplyAddressFieldsUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        PostCode: Record "Post Code";
        Currency: Record Currency;
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 395533] Address fields should not be cleared by template if they are not empty
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Customer template with empty address fields
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [GIVEN] Customer with filled "Post Code", "City" and "Country/Region Code"
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCurrency(Currency);
        Customer."Post Code" := PostCode.Code;
        Customer.City := PostCode.City;
        Customer."Country/Region Code" := PostCode."Country/Region Code";
        Customer.County := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.County));
        Customer."Language Code" := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        Customer."Currency Code" := Currency.Code;
        Customer.Modify();

        // [WHEN] Apply customer template
        CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTempl);

        // [THEN] "Post Code", "City" and "Country/Region Code" are not changed
        Assert.AreEqual(PostCode.Code, Customer."Post Code", 'Wrong Post Code after apply template');
        Assert.AreEqual(PostCode.City, Customer.City, 'Wrong City after apply template');
        Assert.AreEqual(PostCode."Country/Region Code", Customer."Country/Region Code", 'Wrong Country after apply template');
        Customer.TestField(County);
        Customer.TestField("Language Code");
        Customer.TestField("Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateApplyAddressFieldsUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        PostCode: Record "Post Code";
        Currency: Record Currency;
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 395533] Address fields should not be cleared by template if they are not empty
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetCustTemplateFeatureEnabled(true);

        // [GIVEN] Vendor template with empty address fields
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [GIVEN] Vendor with filled "Post Code", "City" and "Country/Region Code"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCurrency(Currency);
        Vendor."Post Code" := PostCode.Code;
        Vendor.City := PostCode.City;
        Vendor."Country/Region Code" := PostCode."Country/Region Code";
        Vendor.County := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.County));
        Vendor."Language Code" := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        Vendor."Currency Code" := Currency.Code;
        Vendor.Modify();

        // [WHEN] Apply Vendor template
        VendorTemplMgt.ApplyVendorTemplate(Vendor, VendorTempl);

        // [THEN] "Post Code", "City" and "Country/Region Code" are not changed
        Assert.AreEqual(PostCode.Code, Vendor."Post Code", 'Wrong Post Code after apply template');
        Assert.AreEqual(PostCode.City, Vendor.City, 'Wrong City after apply template');
        Assert.AreEqual(PostCode."Country/Region Code", Vendor."Country/Region Code", 'Wrong Country after apply template');
        Vendor.TestField(County);
        Vendor.TestField("Language Code");
        Vendor.TestField("Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplCardControls()
    var
        CustomerCardPageControlField: Record "Page Control Field";
        CustomerTemplCardPageControlField: Record "Page Control Field";
        CustomerTemplField: Record Field;
    begin
        CustomerTemplCardPageControlField.SetRange(PageNo, Page::"Customer Templ. Card");

        CustomerCardPageControlField.SetRange(PageNo, Page::"Customer Card");
        CustomerCardPageControlField.SetFilter(FieldNo, '<>0');
        if CustomerCardPageControlField.FindSet() then
            repeat
                if CustomerTemplField.Get(Database::"Customer Templ.", CustomerCardPageControlField.FieldNo) then begin
                    CustomerTemplCardPageControlField.SetRange(FieldNo, CustomerCardPageControlField.FieldNo);
                    if CustomerTemplCardPageControlField.IsEmpty() then
                        Error('%1 should exist on the customer template card.', CustomerCardPageControlField.ControlName);
                end;
            until CustomerCardPageControlField.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplCardControls()
    var
        VendorCardPageControlField: Record "Page Control Field";
        VendorTemplCardPageControlField: Record "Page Control Field";
        VendorTemplField: Record Field;
    begin
        VendorTemplCardPageControlField.SetRange(PageNo, Page::"Vendor Templ. Card");

        VendorCardPageControlField.SetRange(PageNo, Page::"Vendor Card");
        VendorCardPageControlField.SetFilter(FieldNo, '<>0');
        if VendorCardPageControlField.FindSet() then
            repeat
                if VendorTemplField.Get(Database::"Vendor Templ.", VendorCardPageControlField.FieldNo) then begin
                    VendorTemplCardPageControlField.SetRange(FieldNo, VendorCardPageControlField.FieldNo);
                    if VendorTemplCardPageControlField.IsEmpty() then
                        Error('%1 should exist on the Vendor template card.', VendorCardPageControlField.ControlName);
                end;
            until VendorCardPageControlField.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCardControls()
    var
        ItemCardPageControlField: Record "Page Control Field";
        ItemTemplCardPageControlField: Record "Page Control Field";
        ItemField: Record Field;
        ItemTemplField: Record Field;
        FieldExclusionList: List of [Integer];
    begin
        FillItemFieldExclusionList(FieldExclusionList);

        // Verify fields in "Item" and "Item Templ." tables, all fields should match or added in the exclusion list
        ItemField.SetRange(TableNo, Database::Item);
        ItemField.SetRange(Class, ItemField.Class::Normal);
        ItemField.SetRange(ObsoleteState, ItemField.ObsoleteState::No);
        ItemField.SetRange("No.", 1, 9999); // Only check w1 fields
        if ItemField.FindSet() then
            repeat
                if not FieldExclusionList.Contains(ItemField."No.") then
                    if not ItemTemplField.Get(Database::"Item Templ.", ItemField."No.") then
                        Error('%1 field should exist in "Item Templ." table or added to exclusion list', ItemField.FieldName);
            until ItemField.Next() = 0;

        // Verify controls on "Item Card" and "Item Templ. Card" pages, all controls should match or added in the exclusion list
        ItemTemplCardPageControlField.SetRange(PageNo, Page::"Item Templ. Card");
        ItemCardPageControlField.SetRange(PageNo, Page::"Item Card");
        ItemCardPageControlField.SetFilter(FieldNo, '<>0');
        if ItemCardPageControlField.FindSet() then
            repeat
                if not FieldExclusionList.Contains(ItemCardPageControlField.FieldNo) then
                    if ItemTemplField.Get(Database::"Item Templ.", ItemCardPageControlField.FieldNo) then begin
                        ItemTemplCardPageControlField.SetRange(FieldNo, ItemCardPageControlField.FieldNo);
                        if ItemTemplCardPageControlField.IsEmpty() then
                            Error('%1 control should exist on the item template card or added to exclusion list.', ItemCardPageControlField.ControlName);
                    end;
            until ItemCardPageControlField.Next() = 0;
    end;

    [Test]
    procedure CustomerRecordAfterApplyCustomerTemplate()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 414127] CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTempl) returns the valid Customer record state
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);

        CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTempl);
        Customer.TestField("Global Dimension 1 Code", GetGlobalDim1Value());
    end;

    [Test]
    procedure VendorRecordAfterApplyVendorTemplate()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 414127] VendorTemplMgt.ApplyVendorTemplate(Vendor, VendorTempl) returns the valid Vendor record state
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorTemplateWithDataAndDimensions(VendorTempl);

        VendorTemplMgt.ApplyVendorTemplate(Vendor, VendorTempl);
        Vendor.TestField("Global Dimension 1 Code", GetGlobalDim1Value());
    end;

    [Test]
    procedure EmployeeRecordAfterApplyEmployeeTemplate()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 414127] EmployeeTemplMgt.ApplyEmployeeTemplate(Employee, EmployeeTempl) returns the valid Employee record state
        Initialize();

        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);

        EmployeeTemplMgt.ApplyEmployeeTemplate(Employee, EmployeeTempl);
        Employee.TestField("Global Dimension 1 Code", GetGlobalDim1Value());
    end;

    [Test]
    procedure ItemRecordAfterApplyItemTemplate()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 414127] ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl) returns the valid Item record state
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateItemTemplateWithDataAndDimensions(ItemTempl);

        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);
        Item.TestField("Global Dimension 1 Code", GetGlobalDim1Value());
    end;

    [Test]
    procedure CreateItemFromTemplateWithItemCategoryCode()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 418630] Creation item from template with item category code also creates item attributes
        Initialize();

        // [GIVEN] Item "I"
        Item.Init();
        Item.Insert(true);
        // [GIVEN] Item category "C", Item attribute "A"
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValueMapping(Database::"Item Category", ItemCategory.Code, ItemAttribute.ID, ItemAttributeValue.ID);
        // [GIVEN] Item template with "Item Category Code" = "C"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Item Category Code", ItemCategory.Code);
        ItemTempl.Modify(true);

        // [WHEN] Apply item template (procedure also run when item created from template)
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] "I" has attribute "A"
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);
    end;

    [Test]
    procedure CreateCustomerFromTemplateWithRemovedPaymentMethodCode()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        PaymentMethod: Record "Payment Method";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        // [SCENARIO 417672] Customer creation from template with payment method code that was removed
        Initialize();

        // [GIVEN] Customer "C"
        Customer.Init();
        Customer.Insert(true);
        // [GIVEN] Customer template "CT" with payment method "PM"
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CustomerTempl.Validate("Payment Method Code", PaymentMethod.Code);
        CustomerTempl.Modify(true);
        // [GIVEN] Removed "PM"
        PaymentMethod.Delete(true);

        // [WHEN] Apply "CT" to "C"
        asserterror CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTempl);

        // [THEN] Error message about related record is appeared
        Assert.ExpectedError(PaymentMethodErr);
    end;

    [Test]
    procedure ItemTemplateNonDefaultCostingMethod()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 426157] Creation item from template with "Costing Method" different from the inventory setup "Default Costing Method"
        Initialize();

        // Inventory setup with "Default Costing Method" = "CM1"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Standard;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "CM2"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::Average);
        ItemTempl.Modify(true);

        // [GIVEN] Create item "I"
        Item.Init();
        Item.Insert(true);
        Item.TestField("Costing Method", Item."Costing Method"::Standard);

        // [WHEN] Apply item template.
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);

        // [THEN] "I" has "Costing Method" = "CM2"
        Item.TestField("Costing Method", Item."Costing Method"::Average);
    end;

    [Test]
    procedure S481873_ItemTemplateNonDefaultCostingMethodIsEnumDefaultFIFO()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 481873] Creation item from template with "Costing Method" enum default FIFO, but different from the inventory setup "Default Costing Method"
        Initialize();

        // Inventory setup with "Default Costing Method" = "Average"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Average;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "FIFO", which is defaut value in enum, but not in Inventory Setup
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::FIFO);
        ItemTempl.Modify(true);

        // [GIVEN] Create item "I"
        Item.Init();
        Item.Insert(true);
        Item.TestField("Costing Method", Item."Costing Method"::Average);

        // [WHEN] Apply item template.
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);

        // [THEN] "I" has "Costing Method" = "FIFO"
        Item.TestField("Costing Method", Item."Costing Method"::FIFO);
    end;

    [Test]
    procedure S495720_ItemTemplate_WithoutDefaultCostingMethodFIFO_WithoutNoSeries()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        IsHandledVar: Boolean;
    begin
        // [SCENARIO 495720] Creation item from template without "No. Series" and with "Costing Method" = Average, the same as inventory setup "Default Costing Method".
        Initialize();

        // Inventory setup with "Default Costing Method" = "Average"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Average;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "Average"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::Average);
        ItemTempl.Modify(true);

        // [WHEN] Create item "I"
        ItemTemplMgt.CreateItemFromTemplate(Item, IsHandledVar, ItemTempl.Code);

        // [THEN] "I" has "Costing Method" = "Average"
        Item.TestField("Costing Method", Item."Costing Method"::Average);
    end;

    [Test]
    procedure S495720_ItemTemplate_WithoutDefaultCostingMethodFIFO_WithNoSeries()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        IsHandledVar: Boolean;
    begin
        // [SCENARIO 495720] Creation item from template with "No. Series" and with "Costing Method" = Average, the same as inventory setup "Default Costing Method".
        Initialize();

        // Inventory setup with "Default Costing Method" = "Average"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Average;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "Average"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('I1T'));
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::Average);
        ItemTempl.Modify(true);

        // [WHEN] Create item "I"
        ItemTemplMgt.CreateItemFromTemplate(Item, IsHandledVar, ItemTempl.Code);

        // [THEN] "I" has "Costing Method" = "Average" and the same "No. Series" as in item template
        Item.TestField("Costing Method", Item."Costing Method"::Average);
        Item.TestField("No. Series", ItemTempl."No. Series");
    end;

    [Test]
    procedure S495720_ItemTemplate_WithoutDefaultCostingMethodFIFO_WithoutNoSeriesAndCostingMethodFIFO()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        IsHandledVar: Boolean;
    begin
        // [SCENARIO 495720] Creation item from template without "No. Series" and with "Costing Method" = FIFO, while inventory setup "Default Costing Method" is Average.
        Initialize();

        // Inventory setup with "Default Costing Method" = "Average"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Average;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "FIFO"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::FIFO);
        ItemTempl.Modify(true);

        // [WHEN] Create item "I"
        ItemTemplMgt.CreateItemFromTemplate(Item, IsHandledVar, ItemTempl.Code);

        // [THEN] "I" has "Costing Method" = "FIFO"
        Item.TestField("Costing Method", Item."Costing Method"::FIFO);
    end;

    [Test]
    procedure S495720_ItemTemplate_WithoutDefaultCostingMethodFIFO_WithNoSeriesAndCostingMethodFIFO()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        IsHandledVar: Boolean;
    begin
        // [SCENARIO 495720] Creation item from template with "No. Series" and with "Costing Method" = FIFO, while inventory setup "Default Costing Method" is Average.
        Initialize();

        // Inventory setup with "Default Costing Method" = "Average"
        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Average;
        InventorySetup.Modify(true);

        // [GIVEN] Item template with "Costing Method" = "FIFO"
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Validate("No. Series", LibraryERM.CreateNoSeriesCode('I2T'));
        ItemTempl.Validate("Costing Method", ItemTempl."Costing Method"::FIFO);
        ItemTempl.Modify(true);

        // [WHEN] Create item "I"
        ItemTemplMgt.CreateItemFromTemplate(Item, IsHandledVar, ItemTempl.Code);

        // [THEN] "I" has "Costing Method" = "FIFO" and the same "No. Series" as in item template
        Item.TestField("Costing Method", Item."Costing Method"::FIFO);
        Item.TestField("No. Series", ItemTempl."No. Series");
    end;

    [Test]
    procedure ItemTemplateReorderingPolicyValidation()
    var
        ItemTempl: Record "Item Templ.";
    begin
        // [SCENARIO 430357] Item template field "Reordering Policy" validation should assign values to other fields
        Initialize();

        // [GIVEN] Item template
        CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [WHEN] Validate item template field "Reordering Policy" with "Lot-for-Lot" value
        ItemTempl.Validate("Reordering Policy", ItemTempl."Reordering Policy"::"Lot-for-Lot");
        ItemTempl.Modify();

        // [THEN] Item template field "Include Inventory" = true
        ItemTempl.TestField("Include Inventory");
    end;

    [Test]
    procedure ItemTemplateReorderingPolicyValidationUI()
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplCard: TestPage "Item Templ. Card";
    begin
        // [SCENARIO 430357] Item template field "Reordering Policy" validation on the page should enable other controls
        Initialize();

        // [GIVEN] Open item template via UI
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTemplCard.OpenEdit();
        ItemTemplCard.GoToRecord(ItemTempl);

        // [WHEN] Validate "Reordering Policy" with "Fixed Reorder Qty." value on the "Item Templ. Card" page
        ItemTemplCard."Reordering Policy".SetValue('Fixed Reorder Qty.');

        // [THEN] "Reorder Point" control is enabled
        Assert.IsTrue(ItemTemplCard."Reorder Point".Enabled(), 'Control should be enabled');
    end;

    [Test]
    procedure ItemTemplateZeroRoundingPrecision()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 431385] Create item from template with "Rounding Precision" = 0
        Initialize();

        // [GIVEN] Item template "IT" with "Rounding Precision" = 0
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl."Rounding Precision" := 0;
        ItemTempl.Modify();

        // [WHEN] Create item "I"
        Item.Init();
        Item.Insert(true);
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] "I"."Rounding Precision" = 1
        Item.TestField("Rounding Precision", 1);

        // [THEN] "IT"."Rounding Precision" = 1
        ItemTempl.Get(ItemTempl.Code);
        ItemTempl.TestField("Rounding Precision", 1);
    end;

    [Test]
    procedure ItemTemplateServiceTypeWithReserve()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 431385] Create item from template with "Type" = 'Service' and "Reserve" = 'Never'
        Initialize();

        // [GIVEN] Item template "IT" with "Type" = Service and "Reserve" = Never
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl."Inventory Posting Group" := '';
        ItemTempl.Type := ItemTempl.Type::Service;
        ItemTempl.Reserve := ItemTempl.Reserve::Never;
        ItemTempl.Modify();

        // [WHEN] Create item "I"
        Item.Init();
        Item.Insert(true);
        Item.TestField(Reserve, Item.Reserve::Optional);
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] "I"."Reserve" = 'Optional' as the value is not updated from template.
        Item.TestField(Reserve, Item.Reserve::Optional);

        // [THEN] "IT"."Reserve" = 'Never'
        ItemTempl.Get(ItemTempl.Code);
        ItemTempl.TestField(Reserve, ItemTempl.Reserve::Never);
    end;

    [Test]
    procedure ItemTemplateAllowInvoiceDiscount()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO] Create item from template: first with "Allow Invoice Disc." = true, next with "Allow Invoice Disc." = false
        Initialize();

        // [GIVEN] Item template "IT" with "Allow Invoice Disc." = true
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        Assert.IsTrue(ItemTempl."Allow Invoice Disc.", StrSubstNo(ItemTemplateAllowInvoiceDiscErr, true));

        // [WHEN] Create item "I"
        Item.Init();
        Item.Insert(true);
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] "I"."Allow Invoice Disc." = true
        Assert.IsTrue(Item."Allow Invoice Disc.", StrSubstNo(ItemAllowInvoiceDiscErr, true));

        // [GIVEN] Item template "IT" with "Allow Invoice Disc." = false
        ItemTempl."Allow Invoice Disc." := false;
        ItemTempl.Modify();

        // [WHEN] Update item "I"
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] "I"."Allow Invoice Disc." = false
        Assert.IsFalse(Item."Allow Invoice Disc.", StrSubstNo(ItemAllowInvoiceDiscErr, false));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateCustomerFromContactWithNoSeries()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        NoSeriesLine: Record "No. Series Line";
        CustomerTempl: Record "Customer Templ.";
        NoSeriesCode: Code[20];
        CustomerCode: Code[20];
    begin
        // [SCENARIO 430622] Create customer from contact using template with filled number series "NS"
        Initialize();

        // [GIVEN] Customer template with "No Series"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        CustomerTempl."No. Series" := NoSeriesCode;
        CustomerTempl.Modify(true);

        // [WHEN] Create customer from contact
        LibraryMarketing.CreateCompanyContact(Contact);
        CustomerCode := Contact.CreateCustomerFromTemplate(CustomerTempl.Code);

        // [THEN] Customer has number equal to last used from "NS" number series
        Customer.Get(CustomerCode);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        Customer.TestField("No.", NoSeriesLine."Last No. Used");
        NoSeriesLine.TestField("Last No. Used");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateVendorFromContactWithNoSeries()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        NoSeriesLine: Record "No. Series Line";
        VendorTempl: Record "Vendor Templ.";
        NoSeriesCode: Code[20];
        VendorCode: Code[20];
    begin
        // [SCENARIO 430622] Create Vendor from contact using template with filled number series "NS"
        Initialize();

        // [GIVEN] Vendor template with "No Series"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateVendorTemplateWithDataAndDimensions(VendorTempl);
        VendorTempl."No. Series" := NoSeriesCode;
        VendorTempl.Modify(true);

        // [WHEN] Create Vendor from contact
        LibraryMarketing.CreateCompanyContact(Contact);
        VendorCode := Contact.CreateVendorFromTemplate(VendorTempl.Code);

        // [THEN] Vendor has number equal to last used from "NS" number series
        Vendor.Get(VendorCode);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        Vendor.TestField("No.", NoSeriesLine."Last No. Used");
        NoSeriesLine.TestField("Last No. Used");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectEmployeeTemplListHandler')]
    procedure CreateEmployeeFromContactWithNoSeries()
    var
        Employee: Record Employee;
        Contact: Record Contact;
        NoSeriesLine: Record "No. Series Line";
        EmployeeTempl: Record "Employee Templ.";
        NoSeriesCode: Code[20];
        EmployeeCode: Code[20];
    begin
        // [SCENARIO 430622] Create Employee from contact using template with filled number series "NS"
        Initialize();

        // [GIVEN] Employee template with "No Series"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);
        EmployeeTempl."No. Series" := NoSeriesCode;
        EmployeeTempl.Modify(true);
        LibraryVariableStorage.Enqueue(EmployeeTempl.Code);

        // [WHEN] Create Employee from contact
        LibraryMarketing.CreatePersonContact(Contact);
        EmployeeCode := Contact.CreateEmployee();

        // [THEN] Employee has number equal to last used from "NS" number series
        Employee.Get(EmployeeCode);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        Employee.TestField("No.", NoSeriesLine."Last No. Used");
        NoSeriesLine.TestField("Last No. Used");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ItemTemplateChangeServiceType()
    var
        ItemTempl: Record "Item Templ.";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 435897] Change item template item type when there are item ledger entries with blank "Item No."
        Initialize();

        // [GIVEN] Item template with "Type" = Inventory
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Type := ItemTempl.Type::Inventory;
        ItemTempl.Modify();

        // [GIVEN] Item ledger entry with blank "Item No."
        ItemLedgerEntry.Init();
        ItemLedgerEntry.Insert();

        // [WHEN] Change "Type" = Service
        ItemTempl.Validate(Type, ItemTempl.Type::Service);
        ItemTempl.Modify();

        // [THEN] Item template with "Type" = Service
        ItemTempl.TestField(Type, ItemTempl.Type::Service);
    end;

    [Test]
    procedure CreateItemFromConfigTemplateWithInstanceNoSeries()
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        NoSeriesLine: Record "No. Series Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        // [SCENARIO 435486] "Instance No. Series" is used when create item from config. template
        Initialize();

        // [GIVEN] Config. template with "Instance No. Series" = "INS"
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", Database::Item);
        ConfigTemplateHeader.Validate("Instance No. Series", LibraryERM.CreateNoSeriesCode(LibraryUtility.GenerateRandomText(3)));
        ConfigTemplateHeader.Modify(true);

        // [WHEN] Create item from config. template
        RecRef.Open(ConfigTemplateHeader."Table ID");
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);

        // [THEN] Item."No." = last used from "INS"
        NoSeriesLine.SetRange("Series Code", ConfigTemplateHeader."Instance No. Series");
        NoSeriesLine.FindFirst();
        Item.Get(NoSeriesLine."Last No. Used");
    end;

    [Test]
    procedure CreateCustomerFromConfigTemplateWithInstanceNoSeries()
    var
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        NoSeriesLine: Record "No. Series Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        // [SCENARIO 435486] "Instance No. Series" is used when create Customer from config. template
        Initialize();

        // [GIVEN] Config. template with "Instance No. Series" = "INS"
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", Database::Customer);
        ConfigTemplateHeader.Validate("Instance No. Series", LibraryERM.CreateNoSeriesCode(LibraryUtility.GenerateRandomText(3)));
        ConfigTemplateHeader.Modify(true);

        // [WHEN] Create Customer from config. template
        RecRef.Open(ConfigTemplateHeader."Table ID");
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);

        // [THEN] Customer."No." = last used from "INS"
        NoSeriesLine.SetRange("Series Code", ConfigTemplateHeader."Instance No. Series");
        NoSeriesLine.FindFirst();
        Customer.Get(NoSeriesLine."Last No. Used");
    end;

    [Test]
    procedure CreateVendorFromConfigTemplateWithInstanceNoSeries()
    var
        Vendor: Record Vendor;
        ConfigTemplateHeader: Record "Config. Template Header";
        NoSeriesLine: Record "No. Series Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        // [SCENARIO 435486] "Instance No. Series" is used when create Vendor from config. template
        Initialize();

        // [GIVEN] Config. template with "Instance No. Series" = "INS"
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", Database::Vendor);
        ConfigTemplateHeader.Validate("Instance No. Series", LibraryERM.CreateNoSeriesCode(LibraryUtility.GenerateRandomText(3)));
        ConfigTemplateHeader.Modify(true);

        // [WHEN] Create Vendor from config. template
        RecRef.Open(ConfigTemplateHeader."Table ID");
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);

        // [THEN] Vendor."No." = last used from "INS"
        NoSeriesLine.SetRange("Series Code", ConfigTemplateHeader."Instance No. Series");
        NoSeriesLine.FindFirst();
        Vendor.Get(NoSeriesLine."Last No. Used");
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListInvokeCancelHandler,ConfirmHandler')]
    procedure OpenBlankItemCardWhenConfirmOnCancelTemplateSelection()
    var
        ItemTempl: Record "Item Templ.";
        ItemCard: TestPage "Item Card";
        i: Integer;
    begin
        // [SCENARIO 436484] Open blank item card when confirm after cancel template selection
        Initialize();

        // [GIVEN] Two item templates
        for i := 1 to 2 do
            CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [WHEN] Press 'Cancel' on the template selection page when create new item and then press 'Ok' on confirm dialog
        ItemCard.OpenNew();

        // [THEN] Blank item card is opened
        ItemCard."No.".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListInvokeCancelHandler,ConfirmHandler')]
    procedure OpenBlankCustomerCardWhenConfirmOnCancelTemplateSelection()
    var
        CustomerTempl: Record "Customer Templ.";
        CustomerCard: TestPage "Customer Card";
        i: Integer;
    begin
        // [SCENARIO 436484] Open blank customer card when confirm after cancel template selection
        Initialize();

        // [GIVEN] Two customer templates
        for i := 1 to 2 do
            CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);

        // [WHEN] Press 'Cancel' on the template selection page when create new customer and then press 'Ok' on confirm dialog
        CustomerCard.OpenNew();

        // [THEN] Blank customer card is opened
        CustomerCard."No.".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListInvokeCancelHandler,ConfirmHandler')]
    procedure OpenBlankVendorCardWhenConfirmOnCancelTemplateSelection()
    var
        VendorTempl: Record "Vendor Templ.";
        VendorCard: TestPage "Vendor Card";
        i: Integer;
    begin
        // [SCENARIO 436484] Open blank vendor card when confirm after cancel template selection
        Initialize();

        // [GIVEN] Two templates
        for i := 1 to 2 do
            CreateVendorTemplateWithDataAndDimensions(VendorTempl);

        // [WHEN] Press 'Cancel' on the template selection page when create new vendor and then press 'Ok' on confirm dialog
        VendorCard.OpenNew();

        // [THEN] Blank vendor card is opened
        VendorCard."No.".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListHandler,ConfirmHandler')]
    procedure ApplyCustomerTemplWithEmptyFieldsUT()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        // [SCENARIO 432107] Apply template with blank fields should not clear field values in customer
        Initialize();

        // [GIVEN] Blank template "T"
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);

        // [GIVEN] Customer "C" with data
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Apply "T" to "C"
        CustomerTemplMgt.UpdateCustomerFromTemplate(Customer);

        // [THEN] "C" data is not overwritten with data from "T"
        Customer.TestField("Gen. Bus. Posting Group");
        Customer.TestField("VAT Bus. Posting Group");
        Customer.TestField("Customer Posting Group");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListHandler,ConfirmHandler')]
    procedure ApplyVendorTemplWithEmptyFieldsUT()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
    begin
        // [SCENARIO 432107] Apply template with blank fields should not clear field values in Vendor
        Initialize();

        // [GIVEN] Blank template "T"
        LibraryTemplates.CreateVendorTemplate(VendorTempl);
        LibraryVariableStorage.Enqueue(VendorTempl.Code);

        // [GIVEN] Vendor "V" with data
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Apply "T" to "V"
        VendorTemplMgt.UpdateVendorFromTemplate(Vendor);

        // [THEN] "V" data is not overwritten with data from "T"
        Vendor.TestField("Gen. Bus. Posting Group");
        Vendor.TestField("VAT Bus. Posting Group");
        Vendor.TestField("Vendor Posting Group");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListHandler,ConfirmHandler')]
    procedure ApplyItemTemplWithEmptyFieldsUT()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 432107] Apply template with blank fields should not clear field values in Item
        Initialize();

        // [GIVEN] Blank template "T"
        LibraryTemplates.CreateItemTemplate(ItemTempl);
        LibraryVariableStorage.Enqueue(ItemTempl.Code);

        // [GIVEN] Item "I" with data
        LibraryInventory.CreateItem(Item);

        // [WHEN] Apply "T" to "I"
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [THEN] "I" data is not overwritten with data from "T"
        Item.TestField("VAT Prod. Posting Group");
        Item.TestField("Inventory Posting Group");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ItemTemplateChangeServiceTypeReqLine()
    var
        ItemTempl: Record "Item Templ.";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 437428] Change item template item type when there is requisition line with blank "Item No."
        Initialize();

        // [GIVEN] Item template with "Type" = Inventory
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Type := ItemTempl.Type::Inventory;
        ItemTempl.Modify();

        // [GIVEN] Requision line with blank "Item No."
        RequisitionLine.Init();
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine.Insert();

        // [WHEN] Change "Type" = Service
        ItemTempl.Validate(Type, ItemTempl.Type::Service);
        ItemTempl.Modify();

        // [THEN] Item template with "Type" = Service
        ItemTempl.TestField(Type, ItemTempl.Type::Service);
    end;

    [Test]
    procedure ItemTemplateChangeServiceTypeItemJnlLine()
    var
        ItemTempl: Record "Item Templ.";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 437428] Change item template item type when there is item journal line with blank "Item No."
        Initialize();

        // [GIVEN] Item template with "Type" = Inventory
        CreateItemTemplateWithDataAndDimensions(ItemTempl);
        ItemTempl.Type := ItemTempl.Type::Inventory;
        ItemTempl.Modify();

        // [GIVEN] Item journal line with blank "Item No."
        ItemJournalLine.Init();
        ItemJournalLine.Insert();

        // [WHEN] Change "Type" = Service
        ItemTempl.Validate(Type, ItemTempl.Type::Service);
        ItemTempl.Modify();

        // [THEN] Item template with "Type" = Service
        ItemTempl.TestField(Type, ItemTempl.Type::Service);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyItemDimensionFromItemTemplate()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
    begin
        // [SCENARIO 453082] Create new item with one template
        Initialize();
        ItemTempl.DeleteAll();
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);

        // [GIVEN] Template with data and dimensions
        CreateItemTemplateWithDataAndDimensions(ItemTempl);

        // [WHEN] Create new Item
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item inserted with data from template
        VerifyItem(Item, ItemTempl);
        // [THEN] Item dimensions inserted from template dimensions
        VerifyItemDimensions(Database::Item, Item."No.", Database::"Item Templ.", ItemTempl.Code);
    end;

    [Test]
    [HandlerFunctions('CustomerTempModalFormHandler,ConfirmHandlerFalse')]
    procedure VerifyCustomerNotUpdateWhenApplyTemplateFalse()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 459233] Customer template is applied to customer record even though a user cancels the process.
        Initialize();

        // [GIVEN] Create Customer and set Blocked as Blank
        LibrarySales.CreateCustomer(Customer);
        Customer.Blocked := Customer.Blocked::" ";
        Customer.Modify();

        // [GIVEN] Create Customer template and set blocked to Ship
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        CustomerTempl.Blocked := CustomerTempl.Blocked::Ship;
        CustomerTempl.Modify();

        // [GIVEN] Enqueue the variable 
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);

        // [WHEN] Open the Customer card and Apply template
        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);
        CustomerCard.ApplyTemplate.Invoke();

        // [VERIFY] Veriy Customer card is not modify from Customer template.
        Customer.Find();
        Assert.AreEqual(Customer.Blocked::" ", Customer.Blocked, '');
    end;

    [Test]
    [HandlerFunctions('VendorTempModalFormHandler,ConfirmHandlerFalse')]
    procedure VerifyVendorNotUpdateWhenApplyTemplateFalse()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 459233] Vendor template is applied to Vendor record even though a user cancels the process.
        Initialize();

        // [GIVEN] Create Vendor and set Blocked as Blank
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Blocked := Vendor.Blocked::" ";
        Vendor.Modify();

        // [GIVEN] Create Vendor template and set blocked to Ship
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl);
        VendorTempl.Blocked := VendorTempl.Blocked::Payment;
        VendorTempl.Modify();

        // [GIVEN] Enqueue the variable 
        LibraryVariableStorage.Enqueue(VendorTempl.Code);

        // [WHEN] Open the Vendor card and Apply template
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);
        VendorCard.ApplyTemplate.Invoke();

        // [VERIFY] Veriy Vendor card is not modify from Vendor template.
        Vendor.Find();
        Assert.AreEqual(Vendor.Blocked::" ", Vendor.Blocked, '');
    end;

    [Test]
    [HandlerFunctions('EmployeeTempModalFormHandler,ConfirmHandlerFalse')]
    procedure VerifyEmployeeNotUpdateWhenApplyTemplateFalse()
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 353440] Create new employee with one template
        Initialize();

        // [GIVEN] Create Employee and set Gender as Blank
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Gender := Employee.Gender::" ";
        Employee.Modify();

        // [GIVEN] Create Employee template and set Gender as Male
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);
        EmployeeTempl.Gender := EmployeeTempl.Gender::Male;
        EmployeeTempl.Modify();

        // [GIVEN] Enqueue the variable 
        LibraryVariableStorage.Enqueue(EmployeeTempl.Code);

        // [WHEN] Open the Employee card and Apply template
        EmployeeCard.OpenEdit();
        EmployeeCard.GoToRecord(Employee);
        EmployeeCard.ApplyTemplate.Invoke();

        // [VERIFY] Verify Employee card is not modify from Employee template.
        Employee.Find();
        Assert.AreEqual(Employee.Gender::" ", Employee.Gender, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplCreateItemFromNonstockUTWithItemTemplate()
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        CountryRegion: Record "Country/Region";
        CustVendItemEmplTemplates: Codeunit "Cust/Vend/Item/Empl Templates";
        CatalogItemManagement: Codeunit "Catalog Item Management";
    begin
        // [SCENARIO 459688] Create Item from Catalog Item with Item Template where some fields are not applied to created item
        Initialize();
        BindSubscription(CustVendItemEmplTemplates);
        CustVendItemEmplTemplates.SetItemTemplateFeatureEnabled(true);
        UnbindSubscription(CustVendItemEmplTemplates);

        // [GIVEN] Create Item Template with data
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryERM.CreateCountryRegion(CountryRegion);
        ItemTempl.Validate("Tariff No.", LibraryUtility.GenerateGUID());
        ItemTempl.Validate("Flushing Method", ItemTempl."Flushing Method"::"Pick + Forward");
        Evaluate(ItemTempl."Safety Lead Time", '<2D>');
        ItemTempl.Validate("Country/Region of Origin Code", CountryRegion.Code);
        ItemTempl.Modify(true);

        // [GIVEN] Create Nonstock item (Catalog Item)
        CreateNonstockItem(NonstockItem, ItemTempl.Code);

        // [WHEN] Create new Item
        CatalogItemManagement.CreateItemFromNonstock(NonstockItem);
        Item.Get(NonstockItem."Vendor Item No.");

        // [VERIFY] Verify: Item inserted with data from template
        VerifyItem(Item, ItemTempl);
        Item.TestField("Tariff No.", ItemTempl."Tariff No.");
        Item.TestField("Flushing Method", ItemTempl."Flushing Method");
        Item.TestField("Safety Lead Time", ItemTempl."Safety Lead Time");
        Item.TestField("Country/Region of Origin Code", ItemTempl."Country/Region of Origin Code");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Cust/Vend/Item/Empl Templates");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.Save(Database::"Inventory Setup");

        IsInitialized := true;
        Commit();
    end;

    procedure SetCustTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetVendTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetItemTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    procedure SetEmplTemplateFeatureEnabled(NewTemplateFeatureEnabled: Boolean)
    begin
        TemplateFeatureEnabled := NewTemplateFeatureEnabled;
    end;

    local procedure UpdateCustomerTemplateAdditionalFields(var CustomerTempl: Record "Customer Templ.")
    var
        ShipmentMethod: Record "Shipment Method";
        ReminderTerms: Record "Reminder Terms";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        CustomerTempl."Shipment Method Code" := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), Database::"Shipment Method");
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CustomerTempl."Reminder Terms Code" := ReminderTerms.Code;
        CustomerTempl."Print Statements" := true;
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerTempl."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        CustomerTempl."Customer Disc. Group" := CustomerDiscountGroup.Code;

        CustomerTempl.Modify(true);
    end;

    local procedure CreateEmployeeWithData(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);

        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(EmployeePostingGroup.FieldNo(Code), Database::"Employee Posting Group"));
        EmployeePostingGroup.Insert();

        EmployeeStatisticsGroup.Init();
        EmployeeStatisticsGroup.Validate(Code, LibraryUtility.GenerateRandomCode(EmployeeStatisticsGroup.FieldNo(Code), Database::"Employee Statistics Group"));
        EmployeeStatisticsGroup.Insert();

        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Validate("Statistics Group Code", EmployeeStatisticsGroup.Code);
        Employee.Modify(true);
    end;

    local procedure UpdateDocSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile"; var CustomerTempl: Record "Customer Templ.")
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Validate(Code, LibraryUtility.GenerateRandomCode(DocumentSendingProfile.FieldNo(Code), Database::"Document Sending Profile"));
        DocumentSendingProfile.Insert();

        CustomerTempl."Document Sending Profile" := DocumentSendingProfile.Code;
        CustomerTempl.Modify(true);
    end;

    local procedure UpdateVendorTemplDocSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile"; var VendorTempl: Record "Vendor Templ.")
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Validate(Code, LibraryUtility.GenerateRandomCode(DocumentSendingProfile.FieldNo(Code), Database::"Document Sending Profile"));
        DocumentSendingProfile.Insert();

        VendorTempl."Document Sending Profile" := DocumentSendingProfile.Code;
        VendorTempl.Modify(true);
    end;

    local procedure CreateNonstockItem(var NonstockItem: Record "Nonstock Item"; ItemTemplCode: Code[20])
    begin
        LibraryInventory.CreateNonStock(NonstockItem);
        NonstockItem.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        NonstockItem.Validate("Vendor Item No.", LibraryUtility.GenerateRandomCode(NonstockItem.FieldNo("Vendor Item No."), Database::"Nonstock Item"));
        NonstockItem.Validate("Item Templ. Code", ItemTemplCode);
        NonstockItem.Validate(Description, NonstockItem."Entry No.");
        NonstockItem.Modify(true);
    end;

    local procedure CreateCustomerTemplateWithDataAndDimensions(var CustomerTempl: Record "Customer Templ.")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryTemplates.CreateCustomerTemplateWithDataAndDimensions(CustomerTempl);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        CustomerTempl."Global Dimension 1 Code" := DimensionValue.Code;
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        CustomerTempl."Global Dimension 2 Code" := DimensionValue.Code;
        CustomerTempl.Modify();
    end;

    local procedure CreateVendorTemplateWithDataAndDimensions(var VendorTempl: Record "Vendor Templ.")//r01
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryTemplates.CreateVendorTemplateWithDataAndDimensions(VendorTempl);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        VendorTempl."Global Dimension 1 Code" := DimensionValue.Code;
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        VendorTempl."Global Dimension 2 Code" := DimensionValue.Code;
        VendorTempl.Modify();
    end;

    procedure CreateItemTemplateWithDataAndDimensions(var ItemTempl: Record "Item Templ.")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryTemplates.CreateItemTemplateWithDataAndDimensions(ItemTempl);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        ItemTempl."Global Dimension 1 Code" := DimensionValue.Code;
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        ItemTempl."Global Dimension 2 Code" := DimensionValue.Code;
        ItemTempl.Modify();
    end;

    local procedure CreateEmployeeTemplateWithDataAndDimensions(var EmployeeTempl: Record "Employee Templ.")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryTemplates.CreateEmployeeTemplateWithDataAndDimensions(EmployeeTempl);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        EmployeeTempl."Global Dimension 1 Code" := DimensionValue.Code;
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        EmployeeTempl."Global Dimension 2 Code" := DimensionValue.Code;
        EmployeeTempl.Modify();
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure GetGlobalDim1Value(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        exit(DimensionValue.Code);
    end;

    local procedure FillItemFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        Item: Record Item;
    begin
        FieldExclusionList.Add(Item.FieldNo("Prevent Negative Inventory"));
        FieldExclusionList.Add(Item.FieldNo("Stockout Warning"));
        FieldExclusionList.Add(Item.FieldNo("Variant Mandatory if Exists"));
        FieldExclusionList.Add(Item.FieldNo("No."));
        FieldExclusionList.Add(Item.FieldNo("No. 2"));
        FieldExclusionList.Add(Item.FieldNo("Alternative Item No."));
        FieldExclusionList.Add(Item.FieldNo("Description"));
        FieldExclusionList.Add(Item.FieldNo("Search Description"));
        FieldExclusionList.Add(Item.FieldNo("Description 2"));
        FieldExclusionList.Add(Item.FieldNo("Last Direct Cost"));
        FieldExclusionList.Add(Item.FieldNo("Cost is Adjusted"));
        FieldExclusionList.Add(Item.FieldNo("Allow Online Adjustment"));
        FieldExclusionList.Add(Item.FieldNo("Excluded from Cost Adjustment"));
        FieldExclusionList.Add(Item.FieldNo("Last DateTime Modified"));
        FieldExclusionList.Add(Item.FieldNo("Last Date Modified"));
        FieldExclusionList.Add(Item.FieldNo("Last Time Modified"));
        FieldExclusionList.Add(Item.FieldNo("Picture"));
        FieldExclusionList.Add(Item.FieldNo("Application Wksh. User ID"));
        FieldExclusionList.Add(Item.FieldNo("Low-Level Code"));
        FieldExclusionList.Add(Item.FieldNo("Last Unit Cost Calc. Date"));
        FieldExclusionList.Add(Item.FieldNo("Rolled-up Material Cost"));
        FieldExclusionList.Add(Item.FieldNo("Rolled-up Capacity Cost"));
        FieldExclusionList.Add(Item.FieldNo("Inventory Value Zero"));
        FieldExclusionList.Add(Item.FieldNo("Sales Unit of Measure"));
        FieldExclusionList.Add(Item.FieldNo("Purch. Unit of Measure"));
        FieldExclusionList.Add(Item.FieldNo("Created From Nonstock Item"));
        FieldExclusionList.Add(Item.FieldNo("Put-away Unit of Measure Code"));
        FieldExclusionList.Add(Item.FieldNo("Last Counting Period Update"));
        FieldExclusionList.Add(Item.FieldNo("Next Counting Start Date"));
        FieldExclusionList.Add(Item.FieldNo("Next Counting End Date"));
        FieldExclusionList.Add(Item.FieldNo("Unit of Measure Id"));
        FieldExclusionList.Add(Item.FieldNo("Tax Group Id"));
        FieldExclusionList.Add(Item.FieldNo("Item Category Id"));
        FieldExclusionList.Add(Item.FieldNo("Inventory Posting Group Id"));
        FieldExclusionList.Add(Item.FieldNo("Gen. Prod. Posting Group Id"));
        FieldExclusionList.Add(Item.FieldNo("Single-Level Material Cost"));
        FieldExclusionList.Add(Item.FieldNo("Single-Level Capacity Cost"));
        FieldExclusionList.Add(Item.FieldNo("Single-Level Subcontrd. Cost"));
        FieldExclusionList.Add(Item.FieldNo("Single-Level Cap. Ovhd Cost"));
        FieldExclusionList.Add(Item.FieldNo("Single-Level Mfg. Ovhd Cost"));
        FieldExclusionList.Add(Item.FieldNo("Rolled-up Subcontracted Cost"));
        FieldExclusionList.Add(Item.FieldNo("Rolled-up Mfg. Ovhd Cost"));
        FieldExclusionList.Add(Item.FieldNo("Rolled-up Cap. Overhead Cost"));
    end;

    local procedure VerifyTemplateGlobalDimensionIsDefaultDimension(TemplateTableId: Integer; TemplateCode: Code[20]; GlobalDim1CodeValue: Code[20]; GlobalDim2CodeValue: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        DefaultDimension.SetRange("Table ID", TemplateTableId);
        DefaultDimension.SetRange("No.", TemplateCode);

        DefaultDimension.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DefaultDimension.SetRange("Dimension Value Code", GlobalDim1CodeValue);
        Assert.RecordIsNotEmpty(DefaultDimension);

        DefaultDimension.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DefaultDimension.SetRange("Dimension Value Code", GlobalDim2CodeValue);
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    local procedure VerifyTemplateGlobalDimensionCodeValue(TemplateTableId: Integer; TemplateCode: Code[20]; GlobalDim1CodeValue: Code[20]; GlobalDim2CodeValue: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();

        DefaultDimension.Get(TemplateTableId, TemplateCode, GeneralLedgerSetup."Global Dimension 1 Code");
        Assert.AreEqual(DefaultDimension."Dimension Value Code", GlobalDim1CodeValue, GlobalDimCodeTemplateErr);

        DefaultDimension.Get(TemplateTableId, TemplateCode, GeneralLedgerSetup."Global Dimension 2 Code");
        Assert.AreEqual(DefaultDimension."Dimension Value Code", GlobalDim2CodeValue, GlobalDimCodeTemplateErr);
    end;

    local procedure VerifyCopiedVendorTemplateData(DestVendorTempl: Record "Vendor Templ."; SourceVendorTempl: Record "Vendor Templ.")
    begin
        Assert.IsTrue(DestVendorTempl."Vendor Posting Group" = SourceVendorTempl."Vendor Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."Gen. Bus. Posting Group" = SourceVendorTempl."Gen. Bus. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."VAT Bus. Posting Group" = SourceVendorTempl."VAT Bus. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestVendorTempl."Global Dimension 1 Code" = SourceVendorTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestVendorTempl."Global Dimension 2 Code" = SourceVendorTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedCustomerTemplateData(DestCustomerTempl: Record "Customer Templ."; SourceCustomerTempl: Record "Customer Templ.")
    begin
        Assert.IsTrue(DestCustomerTempl."Customer Posting Group" = SourceCustomerTempl."Customer Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."Gen. Bus. Posting Group" = SourceCustomerTempl."Gen. Bus. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."VAT Bus. Posting Group" = SourceCustomerTempl."VAT Bus. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestCustomerTempl."Global Dimension 1 Code" = SourceCustomerTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestCustomerTempl."Global Dimension 2 Code" = SourceCustomerTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedItemTemplateData(DestItemTempl: Record "Item Templ."; SourceItemTempl: Record "Item Templ.")
    begin
        Assert.IsTrue(DestItemTempl."Inventory Posting Group" = SourceItemTempl."Inventory Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."Gen. Prod. Posting Group" = SourceItemTempl."Gen. Prod. Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."VAT Prod. Posting Group" = SourceItemTempl."VAT Prod. Posting Group", CopyTemplateDataErr);

        Assert.IsTrue(DestItemTempl."Global Dimension 1 Code" = SourceItemTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestItemTempl."Global Dimension 2 Code" = SourceItemTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyCopiedEmployeeTemplateData(DestEmployeeTempl: Record "Employee Templ."; SourceEmployeeTempl: Record "Employee Templ.")
    begin
        Assert.IsTrue(DestEmployeeTempl."Employee Posting Group" = SourceEmployeeTempl."Employee Posting Group", CopyTemplateDataErr);
        Assert.IsTrue(DestEmployeeTempl."Statistics Group Code" = SourceEmployeeTempl."Statistics Group Code", CopyTemplateDataErr);

        Assert.IsTrue(DestEmployeeTempl."Global Dimension 1 Code" = SourceEmployeeTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(DestEmployeeTempl."Global Dimension 2 Code" = SourceEmployeeTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyVendor(Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        Assert.IsTrue(Vendor."Vendor Posting Group" = VendorTempl."Vendor Posting Group", InsertedVendorErr);
        Assert.IsTrue(Vendor."Gen. Bus. Posting Group" = VendorTempl."Gen. Bus. Posting Group", InsertedVendorErr);
        Assert.IsTrue(Vendor."VAT Bus. Posting Group" = VendorTempl."VAT Bus. Posting Group", InsertedVendorErr);

        Assert.IsTrue(Vendor."Global Dimension 1 Code" = VendorTempl."Global Dimension 1 Code", InsertedVendorErr);
        Assert.IsTrue(Vendor."Global Dimension 2 Code" = VendorTempl."Global Dimension 2 Code", InsertedVendorErr);
    end;

    local procedure VerifyCustomer(Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        Assert.IsTrue(Customer."Customer Posting Group" = CustomerTempl."Customer Posting Group", InsertedCustomerErr);
        Assert.IsTrue(Customer."Gen. Bus. Posting Group" = CustomerTempl."Gen. Bus. Posting Group", InsertedCustomerErr);
        Assert.IsTrue(Customer."VAT Bus. Posting Group" = CustomerTempl."VAT Bus. Posting Group", InsertedCustomerErr);

        Assert.IsTrue(Customer."Global Dimension 1 Code" = CustomerTempl."Global Dimension 1 Code", CopyTemplateDataErr);
        Assert.IsTrue(Customer."Global Dimension 2 Code" = CustomerTempl."Global Dimension 2 Code", CopyTemplateDataErr);
    end;

    local procedure VerifyItem(Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        Assert.IsTrue(Item."Inventory Posting Group" = ItemTempl."Inventory Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."Gen. Prod. Posting Group" = ItemTempl."Gen. Prod. Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."VAT Prod. Posting Group" = ItemTempl."VAT Prod. Posting Group", InsertedItemErr);
        Assert.IsTrue(Item."Costing Method" = ItemTempl."Costing Method", InsertedItemErr);

        Assert.IsTrue(Item."Global Dimension 1 Code" = ItemTempl."Global Dimension 1 Code", InsertedItemErr);
        Assert.IsTrue(Item."Global Dimension 2 Code" = ItemTempl."Global Dimension 2 Code", InsertedItemErr);

        ItemUnitofMeasure.SetRange(Code, Item."Base Unit of Measure");
        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ItemUnitofMeasure, 1);
    end;

    local procedure VerifyEmployee(Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        Assert.IsTrue(Employee."Employee Posting Group" = EmployeeTempl."Employee Posting Group", InsertedEmployeeErr);
        Assert.IsTrue(Employee."Statistics Group Code" = EmployeeTempl."Statistics Group Code", InsertedEmployeeErr);
    end;

    local procedure VerifyDimensions(DestTableId: Integer; DestNo: Code[20]; SourceTableid: Integer; SourceNo: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", DestTableId);
        DestDefaultDimension.SetRange("No.", DestNo);

        SourceDefaultDimension.SetRange("Table ID", SourceTableid);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        SourceDefaultDimension.FindSet();
        repeat
            DestDefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DestDefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            Assert.RecordIsNotEmpty(DestDefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    local procedure VerifyItemDimensions(DestTableId: Integer; DestNo: Code[20]; SourceTableid: Integer; SourceNo: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", DestTableId);
        DestDefaultDimension.SetRange("No.", DestNo);

        SourceDefaultDimension.SetRange("Table ID", SourceTableid);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        SourceDefaultDimension.FindSet();
        repeat
            DestDefaultDimension.SetRange("Dimension Code", SourceDefaultDimension."Dimension Code");
            DestDefaultDimension.SetRange("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
            DestDefaultDimension.SetRange("Value Posting", SourceDefaultDimension."Value Posting");
            Assert.RecordIsNotEmpty(DestDefaultDimension);
        until SourceDefaultDimension.Next() = 0;
    end;

    local procedure VerifyCustomerAdditionalFields(Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        Assert.IsTrue(Customer."Shipment Method Code" = CustomerTempl."Shipment Method Code", InsertedCustomerErr);
        Assert.IsTrue(Customer."Reminder Terms Code" = CustomerTempl."Reminder Terms Code", InsertedCustomerErr);
        Assert.IsTrue(Customer."Print Statements" = CustomerTempl."Print Statements", InsertedCustomerErr);
        Assert.IsTrue(Customer."Customer Price Group" = CustomerTempl."Customer Price Group", CopyTemplateDataErr);
        Assert.IsTrue(Customer."Customer Disc. Group" = CustomerTempl."Customer Disc. Group", CopyTemplateDataErr);
    end;

    local procedure VerifyCustVendItemEmplNo(NoSeriesCode: Code[20]; CustVendItemEmplNo: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        Assert.AreEqual(NoSeriesLine."Last No. Used", CustVendItemEmplNo, 'Wrong number assigned.');
    end;

    [ModalPageHandler]
    procedure SelectVendorTemplListHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.Get(LibraryVariableStorage.DequeueText());
        SelectVendorTemplList.GoToRecord(VendorTempl);
        SelectVendorTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectCustomerTemplListHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Get(LibraryVariableStorage.DequeueText());
        SelectCustomerTemplList.GoToRecord(CustomerTempl);
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectItemTemplListHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    var
        ItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Get(LibraryVariableStorage.DequeueText());
        SelectItemTemplList.GoToRecord(ItemTempl);
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectEmployeeTemplListHandler(var SelectEmployeeTemplList: TestPage "Select Employee Templ. List")
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        EmployeeTempl.Get(LibraryVariableStorage.DequeueText());
        SelectEmployeeTemplList.GoToRecord(EmployeeTempl);
        SelectEmployeeTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectEmployeeTemplListInvokeCancelHandler(var SelectEmployeeTemplList: TestPage "Select Employee Templ. List")
    begin
        SelectEmployeeTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectVendorTemplListInvokeCancelHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectCustomerTemplListInvokeCancelHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectItemTemplListInvokeCancelHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerTemplCardHandler(var CustomerTemplCard: TestPage "Customer Templ. Card")
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibraryVariableStorage.DequeueText());

        CustomerTemplCard."Customer Posting Group".AssertEquals(Customer."Customer Posting Group");
        CustomerTemplCard."Gen. Bus. Posting Group".AssertEquals(Customer."Gen. Bus. Posting Group");
        CustomerTemplCard."VAT Bus. Posting Group".AssertEquals(Customer."VAT Bus. Posting Group");

        LibraryVariableStorage.Enqueue(CustomerTemplCard.Code.Value);

        CustomerTemplCard.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VendorTemplCardHandler(var VendorTemplCard: TestPage "Vendor Templ. Card")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryVariableStorage.DequeueText());

        VendorTemplCard."Vendor Posting Group".AssertEquals(Vendor."Vendor Posting Group");
        VendorTemplCard."Gen. Bus. Posting Group".AssertEquals(Vendor."Gen. Bus. Posting Group");
        VendorTemplCard."VAT Bus. Posting Group".AssertEquals(Vendor."VAT Bus. Posting Group");

        LibraryVariableStorage.Enqueue(VendorTemplCard.Code.Value);

        VendorTemplCard.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTemplCardHandler(var ItemTemplCard: TestPage "Item Templ. Card")
    var
        Item: Record Item;
    begin
        Item.Get(LibraryVariableStorage.DequeueText());

        ItemTemplCard."Inventory Posting Group".AssertEquals(Item."Inventory Posting Group");
        ItemTemplCard."Gen. Prod. Posting Group".AssertEquals(Item."Gen. Prod. Posting Group");
        ItemTemplCard."VAT Prod. Posting Group".AssertEquals(Item."VAT Prod. Posting Group");

        LibraryVariableStorage.Enqueue(ItemTemplCard.Code.Value);

        ItemTemplCard.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmployeeTemplCardHandler(var EmployeeTemplCard: TestPage "Employee Templ. Card")
    var
        Employee: Record Employee;
    begin
        Employee.Get(LibraryVariableStorage.DequeueText());

        EmployeeTemplCard."Employee Posting Group".AssertEquals(Employee."Employee Posting Group");
        EmployeeTemplCard."Statistics Group Code".AssertEquals(Employee."Statistics Group Code");

        LibraryVariableStorage.Enqueue(EmployeeTemplCard.Code.Value);

        EmployeeTemplCard.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [StrMenuHandler]
    procedure CreateCustVendStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure VendorCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        LibraryVariableStorage.Enqueue(VendorCard."No.".Value);
        VendorCard.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerCardHandler(var CustomerCard: TestPage "Customer Card")
    begin
        LibraryVariableStorage.Enqueue(CustomerCard."No.".Value);
        CustomerCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTempModalFormHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        CustomerTemplate: Record "Customer Templ.";
    begin
        CustomerTemplate.Init();  // Required to initialize the variable.
        CustomerTemplate.Get(LibraryVariableStorage.DequeueText());
        CustomerTemplateList.SetRecord(CustomerTemplate);
        Reply := Action::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorTempModalFormHandler(var VendorTemplateList: Page "Select Vendor Templ. List"; var Reply: Action)
    var
        VendorTemplate: Record "Vendor Templ.";
    begin
        VendorTemplate.Init();  // Required to initialize the variable.
        VendorTemplate.Get(LibraryVariableStorage.DequeueText());
        VendorTemplateList.SetRecord(VendorTemplate);
        Reply := Action::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeTempModalFormHandler(var EmployeeTemplateList: Page "Select Employee Templ. List"; var Reply: Action)
    var
        EmployeeTemplate: Record "Employee Templ.";
    begin
        EmployeeTemplate.Init();  // Required to initialize the variable.
        EmployeeTemplate.Get(LibraryVariableStorage.DequeueText());
        EmployeeTemplateList.SetRecord(EmployeeTemplate);
        Reply := Action::LookupOK;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Queation: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure CustOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure VendOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure ItemOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure EmplOnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := TemplateFeatureEnabled;
    end;
}