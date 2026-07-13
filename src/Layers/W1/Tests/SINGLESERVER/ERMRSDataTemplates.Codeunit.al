codeunit 136601 "ERM RS Data Templates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Config. Template]
    end;

    var
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        APIMockEvents: Codeunit "API Mock Events";
        TemplateRelateToItselfError: Label 'A template cannot relate to itself. Specify a different template.';
        UnknownError: Label 'Unknown error.';
        TemplateInHierarchyErr: Label 'The template %1 is in this hierarchy and contains the same field.';
        FieldInTemplateError: Label 'Field %1 is already in the template.';
        InvalidBooleanError: Label '%1 is not a valid Boolean.';
        IncorrectFieldName: Label 'Field Name is not correct.';
        CreateRecordFailed: Label 'Create Record %1 Failed';
        ValidateRelationError: Label 'The field %1 of table Item contains a value (%2) that cannot be found in the related table (%3).';
        UnexpectedValueAfterRelationCheck: Label 'Unexpected value occurs in Config Template Line after filling default value with skip validation flag.';
        InvalidQtyOfCustomersAppliedErr: Label 'After application quantity of customer records do not matches to expected result.';
        InvalidQtyOfCustomersAfterValidateErr: Label 'After validation quantity of customer records changed.';
        ValidateCostingMethodErr: Label 'You cannot change Costing Method because there are one or more ledger entries for this item.';
        ValueNotUpdatedErr: Label 'Value was not updated despite skip validation flag was off.';
        IsInitialized: Boolean;
        InvalidDefaultValueAfterErrorOnValidationErr: Label 'Default value in Config. Template Line must not be initialized after error on validation.';
        InvalidDefaultValueAfterValidationErr: Label 'Default value was not updated after validation.';
        EmptyDefaultValueErr: Label 'The Default Value field must be filled in if the Mandatory check box is selected.';
        WrongFieldValueErr: Label 'Lookup field value is wrong.';
        BaseUnitOfMeasureErr: Label 'Value of %1 must not be deleted.';

    local procedure Cleanup(PackageCode: Code[20]; TemplateCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigPackage.SetRange(Code, PackageCode);
        ConfigPackage.DeleteAll(true);

        ConfigTemplateHeader.SetRange(Code, TemplateCode);
        ConfigTemplateHeader.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateCodeStartsWithTablePrefix()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Template Code starts with table first 4 symbols prefix for all tables.
        ConfigTemplateHeader.DeleteAll();
        InsertTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        VerifyNextAvailableCode(DATABASE::Currency, 'CURR');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CusrtomerTemplateCodeStartsWithCUST()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [UT]
        ConfigTemplateHeader.DeleteAll();
        InsertTemplateHeader(ConfigTemplateHeader, DATABASE::Currency);
        VerifyNextAvailableCode(DATABASE::Customer, 'CUST');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTemplateCodeStartsWithVEND()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [UT]
        ConfigTemplateHeader.DeleteAll();
        InsertTemplateHeader(ConfigTemplateHeader, DATABASE::Currency);
        VerifyNextAvailableCode(DATABASE::Vendor, 'VEND');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTemplateCodeStartsWithITEM()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [UT]
        ConfigTemplateHeader.DeleteAll();
        InsertTemplateHeader(ConfigTemplateHeader, DATABASE::Currency);
        VerifyNextAvailableCode(DATABASE::Item, 'ITEM');
    end;

    local procedure InsertTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; TableID: Integer)
    begin
        ConfigTemplateHeader.Init();
        ConfigTemplateHeader."Table ID" := TableID;
        ConfigTemplateHeader.Code := ConfigTemplateManagement.GetNextAvailableCode(TableID);
        ConfigTemplateHeader.Insert();
    end;

    local procedure VerifyNextAvailableCode(TableID: Integer; TablePrefix: Text[4])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        InsertTemplateHeader(ConfigTemplateHeader, TableID);

        Assert.AreEqual(TablePrefix + '000001', ConfigTemplateHeader.Code, 'Wrong ConfigTemplateHeader.Code');
        Assert.AreEqual(
          TablePrefix + '000002', ConfigTemplateManagement.GetNextAvailableCode(TableID),
          'Wrong ConfigTemplateHeader.Code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        Currency: Record Currency;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        // Test if a Master Record - Vendor can be created using Standard Master Data Templates.

        // 1. Setup: Create new Data Template Header, Data Template Line for Vendor Posting Group, Currency Code,
        // Gen. Bus. Posting Group. Create new Instance.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Vendor);

        VendorPostingGroup.Get(LibraryPurchase.FindVendorPostingGroup());
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Vendor.FieldNo("Vendor Posting Group"),
          Vendor.FieldName("Vendor Posting Group"), VendorPostingGroup.Code);

        LibraryERM.FindCurrency(Currency);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Vendor.FieldNo("Currency Code"), Vendor.FieldName("Currency Code"), Currency.Code);

        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Vendor.FieldNo("Gen. Bus. Posting Group"),
          Vendor.FieldName("Gen. Bus. Posting Group"), GenBusinessPostingGroup.Code);

        CreateNewInstance(ConfigTemplateHeader);

        // 2. Exercise: Apply Template to a new Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        ApplyTemplateToVendor(Vendor, ConfigTemplateHeader);

        // 3. Verify: Check that the Master Data Template has been applied to the Vendor.
        Vendor.Get(Vendor."No.");
        Vendor.TestField("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.TestField("Currency Code", Currency.Code);
        Vendor.TestField("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateItemFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        // Test if a Master Record - Item can be created using Standard Master Data Templates.

        // 1. Setup: Create new Data Template Header, Data Template Line for Inventory Posting Group, Gen. Product Posting Group.
        // Create new Instance.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Gen. Prod. Posting Group"),
          Item.FieldName("Gen. Prod. Posting Group"), GenProductPostingGroup.Code);

        CreateNewInstance(ConfigTemplateHeader);

        // 2. Exercise: Apply Template to a new Item.
        LibraryInventory.CreateItem(Item);
        ApplyTemplateToItem(Item, ConfigTemplateHeader);

        // 3. Verify: Check that the Master Data Template has been applied to the Item.
        Item.Get(Item."No.");
        Item.TestField("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.TestField("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContactFromTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Contact: Record Contact;
        Currency: Record Currency;
    begin
        // Test if a Master Record - Contact can be created using Standard Master Data Templates.

        // 1. Setup: Create new Data Template Header, Data Template Line for Currency Code. Create new Instance.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Contact);

        LibraryERM.FindCurrency(Currency);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Contact.FieldNo("Currency Code"), Contact.FieldName("Currency Code"), Currency.Code);

        CreateNewInstance(ConfigTemplateHeader);

        // 2. Exercise: Apply Template to a new Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        ApplyTemplateToContact(Contact, ConfigTemplateHeader);

        // 3. Verify: Check that the Master Data Template has been applied to the Contact.
        Contact.Get(Contact."No.");
        Contact.TestField("Currency Code", Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApplyMasterConfigTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        Currency: Record Currency;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        // Test if a new Master Data Template can be created and applied for Master Records.

        // 1. Setup: Create new Data Template Header, Data Template Line for Customer Posting Group, Currency Code,
        // Gen. Bus. Posting Group. Create new Instance.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);

        CustomerPostingGroup.Get(LibrarySales.FindCustomerPostingGroup());
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Customer Posting Group"),
          Customer.FieldName("Customer Posting Group"), CustomerPostingGroup.Code);

        LibraryERM.FindCurrency(Currency);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Currency Code"), Customer.FieldName("Currency Code"), Currency.Code);

        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Gen. Bus. Posting Group"),
          Customer.FieldName("Gen. Bus. Posting Group"), GenBusinessPostingGroup.Code);
        CreateNewInstance(ConfigTemplateHeader);

        // 2. Exercise: Apply Template to a new Customer.
        LibrarySales.CreateCustomer(Customer);
        ApplyTemplateToCustomer(Customer, ConfigTemplateHeader);

        // 3. Verify: Check that the Master Data Template has been applied to the Customer.
        Customer.Get(Customer."No.");
        Customer.TestField("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.TestField("Currency Code", Currency.Code);
        Customer.TestField("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMaintainTemplateManyOne()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        Currency: Record Currency;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        // Test Creation and Maintenance of templates - many to one.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create new Data Template Header, Data Template Line for Customer Posting Group, Currency Code,
        // Gen. Bus. Posting Group.
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);

        CustomerPostingGroup.Get(LibrarySales.FindCustomerPostingGroup());
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Customer Posting Group"),
          Customer.FieldName("Customer Posting Group"), CustomerPostingGroup.Code);

        LibraryERM.FindCurrency(Currency);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Currency Code"), Customer.FieldName("Currency Code"), Currency.Code);

        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Gen. Bus. Posting Group"),
          Customer.FieldName("Gen. Bus. Posting Group"), GenBusinessPostingGroup.Code);

        // 3. Verify: Check that the Master Data Template Lines have been created.
        VerifyTemplateLineCreated(
          ConfigTemplateHeader.Code, Customer.FieldNo("Customer Posting Group"),
          Customer.FieldNo("Currency Code"), Customer.FieldNo("Gen. Bus. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMaintainTemplateOneToOne()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Test Creation and Maintenance of templates - one to one.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create new Data Template Header, Data Template Line for Post Code.
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::"Company Information");

        LibraryERM.FindPostCode(PostCode);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, CompanyInformation.FieldNo("Post Code"), CompanyInformation.FieldName("Post Code"), PostCode.Code);

        // 3. Verify: Check that the Master Data Template Line has been created.
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindFirst();
        ConfigTemplateLine.TestField("Field ID", CompanyInformation.FieldNo("Post Code"));
        ConfigTemplateLine.TestField("Field Name", CompanyInformation.FieldName("Post Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateApplyToItselfError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // Test Creation and Maintenance of templates - insert same Template on Template Line.

        // 1. Setup: Create new Data Template Header, Data Template Line.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);

        // 2. Exercise: Change Type on Data Template Line to Template and try to Apply Template on Line.
        asserterror InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);

        // 3. Verify: Check that the application generates an error as "A template cannot relate to itself.".
        Assert.AreEqual(StrSubstNo(TemplateRelateToItselfError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateFieldExistOnLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ConfigTemplateHeaderCode: Code[10];
    begin
        // Test Creation and Maintenance of templates- insert Template that contains fields that are already on Template Line.

        // 1. Setup: Create two Data Template Headers with Data Template Lines having same field.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeaderCode := ConfigTemplateHeader.Code;
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        // 2. Exercise: Create new Data Template Line, change Type to Template and try to Apply first Template on Line.
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        asserterror InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode);

        // 3. Verify: Check that the application generates an error as "Template is in this hierarchy and contains the same field".
        Assert.AreEqual(StrSubstNo(TemplateInHierarchyErr, ConfigTemplateHeaderCode), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateOnlyLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ConfigTemplateHeaderCode: Code[10];
    begin
        // Test Creation and Maintenance of templates - insert template line which refers to the field.

        // 1. Setup: Create two Data Template Headers with field and template in the second one referse to this field
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeaderCode := ConfigTemplateHeader.Code;
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode);

        // 2. Exercise: Apply Template to a new Item.
        LibraryInventory.CreateItem(Item);
        ApplyTemplateToItem(Item, ConfigTemplateHeader);

        // 3. Verify: Check that the Master Data Template has been applied to the Item.
        Item.Get(Item."No.");
        Item.TestField("Inventory Posting Group", InventoryPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldExistOnTemplateLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ConfigTemplateHeaderCode: Code[10];
    begin
        // Test Creation and Maintenance of templates - insert field that exist in the related Template Line.

        // 1. Setup: Create two Data Template Headers with Data Template Lines having same field.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeaderCode := ConfigTemplateHeader.Code;
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode);

        // 2. Exercise: Create new Data Template Line with type Field and run hierarchical check
        asserterror CreateConfigTemplateLineForField(
            ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
            Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        // 3. Verify: Check that the application generates an error as "Template is in this hierarchy and contains the same field".
        Assert.AreEqual(StrSubstNo(TemplateInHierarchyErr, ConfigTemplateHeaderCode), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeveralTemplateRefError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ConfigTemplateHeaderCode: array[2] of Code[10];
    begin
        // Test Creation and Maintenance of templates - insert field that exist in the related Template Line.

        // 1. Setup: Create three Data Template Headers with field in the first one and reference/template in the others
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeaderCode[1] := ConfigTemplateHeader.Code;
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode[1]);
        ConfigTemplateHeaderCode[2] := ConfigTemplateHeader.Code;

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        // 2. Exercise: Create new Data Template Line, change Type to Template and run hierarchical check
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        asserterror InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode[2]);

        // 3. Verify: Check that the application generates an error as "Template is in this hierarchy and contains the same field".
        Assert.AreEqual(StrSubstNo(TemplateInHierarchyErr, ConfigTemplateHeaderCode[1]), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiTemplateLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ConfigTemplateHeaderCode: array[2] of Code[10];
        i: Integer;
    begin
        // Test Creation and Maintenance of templates - insert two template lines that refers to the same field.

        // 1. Setup: Create two Data Template Headers with Data Template Lines having same field.
        Initialize();
        for i := 1 to ArrayLen(ConfigTemplateHeaderCode) do begin
            LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
            ConfigTemplateHeaderCode[i] := ConfigTemplateHeader.Code;
            InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
            CreateConfigTemplateLineForField(
              ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
              Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);
        end;

        // 2. Exercise: Create new Data Template Header with two Data Template Lines refers to the both template codes

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode[1]);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        asserterror InputTemplateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode[2]);

        // 3. Verify: Check that the application generates an error as "Template is in this hierarchy and contains the same field".
        Assert.AreEqual(StrSubstNo(TemplateInHierarchyErr, ConfigTemplateHeaderCode[1]), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DuplicateFieldOnLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        // Test Creation and Maintenance of templates - insert a field that is already on Template Line.

        // 1. Setup: Create Data Template Header, Data Template Line.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
          Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        // 2. Exercise: Create new Data Template Line having same field as previous line.
        asserterror CreateConfigTemplateLineForField(
            ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
            Item.FieldName("Inventory Posting Group"), InventoryPostingGroup.Code);

        // 3. Verify: Check that the application generates an error as "Field is already in this template".
        Assert.AreEqual(StrSubstNo(FieldInTemplateError, Item.FieldCaption("Inventory Posting Group")), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvalidDefaultValueOnLineError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
    begin
        // Test Creation and Maintenance of templates - Insert invalid Default value on Data Template Line.

        // 1. Setup: Create new Data Template Header.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);

        // 2. Exercise: Create a new Data Template Line. Try to input any wrong default value on the Data Template Line.
        asserterror CreateConfigTemplateLineForField(
            ConfigTemplateHeader.Code, Customer.FieldNo("Allow Line Disc."), Customer.FieldName("Allow Line Disc."), Customer.TableCaption());

        // 3. Verify: Check that the application generates an error as "Customer is not a valid boolean".
        Assert.AreEqual(StrSubstNo(InvalidBooleanError, Customer.TableCaption()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEvaluateValues()
    var
        GLSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        ChangeLogEntry: Record "Change Log Entry";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Option
        Initialize();
        EvaluateValue(
          DATABASE::"General Ledger Setup", GLSetup.FieldNo("Local Address Format"),
          Format(GLSetup."Local Address Format"::"City+Post Code"));

        // Integer
        EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo("Entry No."), Format(999));

        // Decimal
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Inv. Rounding Precision (LCY)"), Format(12345));

        // Date
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Allow Posting From"), Format(20110101D));

        // Time
        EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo(Time), Format(123245T));

        // DateTime
        EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Date and Time"), Format('26-10-11 15:05:26'));

        // Boolean
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Register Time"), Format(false));
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Register Time"), Format(true));

        // BigInteger
        EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Entry No."), Format(12345000000000.0));

        // GUID
        EvaluateValue(DATABASE::"Job Queue Entry", JobQueueEntry.FieldNo(ID), Format(CreateGuid()));

        // Code
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Bank Account Nos."), Format(GLSetup."Bank Account Nos."));

        // Text with MAX length (TFS ID: 308679)
        EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo(Description), CopyStr(LibraryUtility.GenerateRandomXMLText(250), 1));

        // DateFormula
        EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Payment Discount Grace Period"), Format('+1Y'));

        // RecordID
        EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Record ID"), format(GLSetup.RECORDID));

    end;

    [Test]
    [HandlerFunctions('ConfigTemplateLine_LookupFieldName_Handler')]
    [Scope('OnPrem')]
    procedure ConfigTemplateLine_LookupFieldName()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Customer: Record Customer;
    begin
        // Config. Template Line: Lookup Field Name

        // 1. Setup.
        Initialize();

        // 2. Exercise: Prepare Template Header and Line
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        ConfigTemplateLine_LookupFields(ConfigTemplateHeader, ConfigTemplateLine.Type::Field);

        // 3. Verify LookupField
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindFirst();
        Assert.AreEqual(Customer.FieldName("Prices Including VAT"), ConfigTemplateLine."Field Name", IncorrectFieldName);

        // 4. Clear created data.
        Cleanup('', ConfigTemplateHeader.Code);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplateLine_LookupTemplateCode_Handler')]
    [Scope('OnPrem')]
    procedure ConfigTemplateLine_LookupTemplateCode()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        FirstConfigTemplateHeader: Code[10];
    begin
        // Config. Template Line: Lookup Template Code

        // 1. Setup.
        Initialize();

        // 2. Exercise: Prepare Template Header and Line
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        FirstConfigTemplateHeader := ConfigTemplateHeader.Code;
        LibraryVariableStorage.Enqueue(FirstConfigTemplateHeader);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        ConfigTemplateLine_LookupFields(ConfigTemplateHeader, ConfigTemplateLine.Type::Template);

        // 3. Verify LookupField
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindFirst();
        ConfigTemplateLine.TestField("Template Code", FirstConfigTemplateHeader);

        // 4. Clear created data.
        Cleanup('', ConfigTemplateHeader.Code);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplateHeader_CreateInstance_MessageHandler')]
    [Scope('OnPrem')]
    procedure ConfigTemplateHeader_CreateInstance()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        PaymentTerms: Record "Payment Terms";
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
        PaymentTermsCode: Code[10];
    begin
        // Config. Template Header: Create Instance

        // 1. Setup.
        Initialize();

        // 2. Exercise: Prepare Template Header and Line
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);

        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::"Payment Terms");
        PaymentTermsCode := LibraryUtility.GenerateRandomCode(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms");
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, PaymentTerms.FieldNo(Code),
          PaymentTerms.FieldName(Code), PaymentTermsCode);

        // 3. Apply Create Instance on created ConfigTemplateHeader
        ConfigTemplateHeaderPage.OpenView();
        ConfigTemplateHeaderPage.GotoRecord(ConfigTemplateHeader);
        ConfigTemplateHeaderPage.CreateInstance.Invoke();

        // 4. Verify Payment Terms record created.
        Assert.IsTrue(PaymentTerms.Get(PaymentTermsCode), StrSubstNo(CreateRecordFailed, PaymentTerms.TableName));

        // 5. Clear created data.
        PaymentTerms.Delete(true);
        Cleanup('', ConfigTemplateHeader.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindTemplateOnEmptyTable()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DummyConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        Contact: Record Contact;
        RecordFound: Boolean;
    begin
        // Setup
        Initialize();
        ConfigTmplSelectionRules.SetRange("Table ID", DATABASE::Contact);
        ConfigTmplSelectionRules.DeleteAll();
        Contact.Init();
        Contact.Insert();

        // Execute
        RecordFound := DummyConfigTmplSelectionRules.FindTemplateBasedOnRecordFields(Contact, ConfigTemplateHeader);

        // Verify
        Assert.IsFalse(RecordFound, 'Record should not have been found for given filter');
        Assert.AreEqual('', ConfigTemplateHeader.Code, 'Template code should not have been set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindTemplateOnNonRecord()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DummyConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        RecordFound: Boolean;
    begin
        // Setup
        Initialize();

        // Execute
        RecordFound := DummyConfigTmplSelectionRules.FindTemplateBasedOnRecordFields(RecordFound, ConfigTemplateHeader);

        // Verify
        Assert.IsFalse(RecordFound, 'Record should not have been found for given filter');
        Assert.AreEqual('', ConfigTemplateHeader.Code, 'Template code should not have been set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNonSingleInstanceLineDefaultValue_ValidateWithoutSkipRelationCheckFlag_ErrorOnValidateRelation()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        asserterror
          CreateConfigTemplateLineForField(
            ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"),
            Item.FieldName("Inventory Posting Group"), Item.TableCaption());

        Assert.ExpectedError(
          StrSubstNo(
            ValidateRelationError, Item.FieldName("Inventory Posting Group"),
            UpperCase(Item.TableCaption()), InventoryPostingGroup.TableCaption()));

        Cleanup('', ConfigTemplateHeader.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNonSingleInstanceLineDefaultValue_ValidateWithSkipRelationCheckFlag_ErrorOnValidateRelation()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputFieldInConfigTemplateLine(
          ConfigTemplateLine, Item.FieldNo("Base Unit of Measure"), Item.FieldName("Base Unit of Measure"), Item.TableCaption(), true);

        Assert.AreEqual(ConfigTemplateLine."Default Value", UpperCase(Item.TableCaption()), UnexpectedValueAfterRelationCheck);

        Cleanup('', ConfigTemplateHeader.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageWithTemplateAttached_CustomerWithEmptyNo_OnlyOneCustomerCreated()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        InitialCustCount: Integer;
        ConfigTemplateCode: Code[20];
    begin
        Initialize();
        GenerateTemplateAndPackageForTableWithSeriesNo(ConfigPackage, ConfigTemplateCode);

        InitialCustCount := Customer.Count();
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        Assert.IsTrue(Customer.Count - InitialCustCount = 1, InvalidQtyOfCustomersAppliedErr);

        Cleanup(ConfigPackage.Code, ConfigTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePackageDataWithTemplateAttached_CustomerWithEmptyNo_NoCustomersCreated()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        InitialCustCount: Integer;
        ConfigTemplateCode: Code[20];
    begin
        Initialize();
        GenerateTemplateAndPackageForTableWithSeriesNo(ConfigPackage, ConfigTemplateCode);

        InitialCustCount := Customer.Count();
        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        Assert.IsTrue(Customer.Count = InitialCustCount, InvalidQtyOfCustomersAfterValidateErr);

        Cleanup(ConfigPackage.Code, ConfigTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFieldWithTrigger_SkipValidationFalse_TriggerError()
    var
        Item: Record Item;
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Initialize();
        CreateItemWithFIFOandILE(Item);
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(Item.FieldNo("Costing Method"));
        asserterror ConfigValidateManagement.ValidateFieldValue(
            RecRef, FieldRef, Format(Item."Costing Method"::Standard), false, GlobalLanguage);

        Assert.ExpectedError(ValidateCostingMethodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFieldWithTrigger_SkipValidationTrue_NoErrors()
    var
        Item: Record Item;
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Initialize();
        CreateItemWithFIFOandILE(Item);
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(Item.FieldNo("Costing Method"));
        ConfigValidateManagement.ValidateFieldValue(RecRef, FieldRef, Format(Item."Costing Method"::Standard), true, GlobalLanguage);

        Assert.AreEqual(Format(FieldRef.Value), Format(Item."Costing Method"::Standard), ValueNotUpdatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateLineWithTriggerDependencyOnOtherField_OtherFieldPresentInTemplate_NoError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        NoSeries: Record "No. Series";
        WrongDefaultValue: Text[250];
    begin
        // [SCENARIO 205993] The "Default Value" field are validated and table relation is verified in Configuration Template Line against other Configuration Template Lines.
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);

        // [GIVEN] Item Tracking entry with Code = "X"
        // [GIVEN] No Series with Code = "Y"
        // [GIVEN] Configuration Template "T" for Item table
        // [GIVEN] Cannot set "Default Value" Configuration Template Line[1] in "T" for field "Lot Nos." due to specified "Item Tracking Code" required.
        // [GIVEN] Configuration Template Line[1] in "T" for field "Item Tracking Code" with default value "X".
        // [GIVEN] Configuration Template Line[2] in "T" for field "Lot Nos." with default value "Y"

        // Lot Nos. have TestField for item tracking code
        Commit();
        asserterror CreateConfigTemplateLineForFieldAndValidate(
            ConfigTemplateHeader.Code, Item.FieldNo("Lot Nos."), Item.FieldName("Lot Nos."),
            NoSeries.Code, false);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Item Tracking Code"), '');

        CreateConfigTemplateLineForFieldAndValidate(
          ConfigTemplateHeader.Code, Item.FieldNo("Item Tracking Code"), Item.FieldName("Item Tracking Code"),
          LibraryUtility.GenerateRandomCode(Item.FieldNo("Item Tracking Code"), DATABASE::Item), true);

        // Lot Nos. have TestField for item tracking code
        CreateConfigTemplateLineForFieldAndValidate(
          ConfigTemplateHeader.Code, Item.FieldNo("Lot Nos."), Item.FieldName("Lot Nos."),
          NoSeries.Code, false);

        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindLast();
        Assert.AreEqual(NoSeries.Code, ConfigTemplateLine."Default Value", InvalidDefaultValueAfterValidationErr);

        // [WHEN] Set "Lot Nos." = "Ywrong" in Configuration Template Line[2]
        WrongDefaultValue := '---';
        asserterror ConfigTemplateLine.Validate("Default Value", WrongDefaultValue);

        // [THEN] The error "The field Lot Nos. of table Item contains a value (Ywrong) that cannot be found in the related table (No. Series)." thrown
        Assert.ExpectedError(
          StrSubstNo(
            'The field Lot Nos. of table Item contains a value (%1) that cannot be found in the related table (No. Series).',
            WrongDefaultValue));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TemplateLineWithTriggerDependencyOnOtherField_RelatedFieldNotPresentInTemplate_ErrorOnValidateDefaultValue()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
        NoSeries: Record "No. Series";
    begin
        Initialize();
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);

        // Lot Nos. have TestField for item tracking code
        asserterror CreateConfigTemplateLineForFieldAndValidate(
            ConfigTemplateHeader.Code, Item.FieldNo("Lot Nos."), Item.FieldName("Lot Nos."),
            NoSeries.Code, false);

        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindFirst();
        Assert.AreEqual('', ConfigTemplateLine."Default Value", InvalidDefaultValueAfterErrorOnValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingBOM()
    var
        BOMComponent: Record "BOM Component";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is BOM Component with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] BOM Component with blank Item's "No."
        LibraryInventory.CreateBOMComponent(BOMComponent, LibraryInventory.CreateItem(Item), BOMComponent.Type::Item, '', 1, '');

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing BOM with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Purchase Order with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line with "Item" and blank "No."
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("No.", '');
        PurchaseLine.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Purchase Order lines with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Sales Order with line with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line with "Item" and blank "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("No.", '');
        SalesLine.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Sales Order Lines with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Production Order with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Production Order with Line with blank "No."
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, '', 1);
        CreateProdOrderLine(ProductionOrder, ProdOrderLine);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Production Order Lines with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingProdOrderComp()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Prod Order Component with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Production Order Component with blank "Item No."
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, '', 1);
        CreateProdOrderLine(ProductionOrder, ProdOrderLine);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Production Order Components with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingPlanningComp()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Planning Component with blank "Item No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Purchase Order with Line with blank "Item No."
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", '');
        PlanningComponent.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Planning Components with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingTransLine()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ConfigTemplateLine: Record "Config. Template Line";
        IntransitLocation: Record Location;
        Location: Record Location;
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Transfer Line with blank "Item No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Transfer Header with Line with blank "No."
        LibraryWarehouse.CreateLocation(IntransitLocation);
        IntransitLocation.Validate("Use As In-Transit", true);
        IntransitLocation.Modify(true);
        LibraryInventory.CreateTransferHeader(
          TransferHeader, LibraryWarehouse.CreateLocation(Location), LibraryWarehouse.CreateLocation(Location), IntransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, LibraryInventory.CreateItemNo(), 1);
        TransferLine.Validate("Item No.", '');
        TransferLine.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Transfers with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingServInv()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Service Invoice Component with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Service Invoice with Line with blank "No."
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, '', 1);
        ServiceLine.Validate("No.", '');
        ServiceLine.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Service Invoices with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingProdBOM()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Production BOM with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Production BOM with Line with blank "No."
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, '');
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionBOMLine."No." := ''; // Cannot be validated blank
        ProductionBOMLine.Modify();

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Production BOMs with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Service Contract with line with blank Item's "No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Service Contract with Line with blank "No."
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Service Contracts with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingAsmHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Assembly Header with blank "Item No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Assembly Header with blank "Item No."
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', 1, '');
        AssemblyHeader.Validate("Item No.", '');
        AssemblyHeader.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Assembly Headers with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingAsmLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Assembly Header with line with blank "Item No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Assembly Header with line with blank "Item No."
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', 1, '');
        AssemblyHeader.Validate("Item No.", '');
        AssemblyHeader.Modify(true);
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, '', '', 1, 0, '');

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Assembly lines with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingConfigTemplateWithServiceDefaultValueAndExistingJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [FEATURE] [Config. Template]
        // [SCENARIO 381095] If there is Job Planning Line with blank "Item No.", then User should be able to create Item Config. Template with "Service" Default Value for Item's "Type"
        Initialize();

        // [GIVEN] Job Planning Line with blank "Item No."
        LibraryTimeSheet.CreateJobPlanningLine(JobPlanningLine, '', '', '', WorkDate());
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Modify(true);

        // [GIVEN] Config. Template Header for Item
        // [WHEN] Validate "Service" as "Default Value" for Item's "Type" in Config. Template Line
        CreateConfigTemplateHeaderAndLineForItem(ConfigTemplateLine);

        // [THEN] No error appears about existing Job Planning Lines with such items
        ConfigTemplateLine.Insert(true);
        ConfigTemplateLine.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateLineErrorEmptyDefaultValueOnMandatoryValidate()
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [SCENARIO 268381] An error appears if Mandatory is checked when Default Value is empty.
        Initialize();

        // [GIVEN] Configuration Template Line with empty Default Value.
        CreateConfigTemplateLineWithDefaultValueAndMandatory(ConfigTemplateLine, '', false);

        // [WHEN] Check Mandatory field.
        asserterror ConfigTemplateLine.Validate(Mandatory, true);

        // [THEN] Default Value must be filled in.
        Assert.ExpectedError(EmptyDefaultValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateLineNotEmptyDefaultValueOnMandatoryValidate()
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [SCENARIO 268381] Validation is passed if Mandatory is checked when Default Value is not empty.
        Initialize();

        // [GIVEN] Configuration Template Line with Default Value.
        CreateConfigTemplateLineWithDefaultValueAndMandatory(
          ConfigTemplateLine, CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 250), false);

        // [WHEN] Check Mandatory field.
        ConfigTemplateLine.Validate(Mandatory, true);

        // [THEN] Mandatory was validated.
        ConfigTemplateLine.TestField(Mandatory, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateLineErrorDefaultValueEmptyMandatoryChecked()
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [SCENARIO 268381] An error appears if empty Default Value is set when Mandatory is checked.
        Initialize();

        // [GIVEN] Configuration Template Line with checked Mandatory.
        CreateConfigTemplateLineWithDefaultValueAndMandatory(
          ConfigTemplateLine, CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 250), true);

        // [WHEN] Set empty Default Value.
        asserterror ConfigTemplateLine.Validate("Default Value", '');

        // [THEN] Default Value must be filled in.
        Assert.ExpectedError(EmptyDefaultValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateLineDefaultValueNotEmptyMandatoryChecked()
    var
        ConfigTemplateLine: Record "Config. Template Line";
        NewDefaultValue: Text[250];
    begin
        // [SCENARIO 268381] Validation is passed if not empty Default Value is set when Mandatory is checked.
        Initialize();
        NewDefaultValue := CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 250);

        // [GIVEN] Configuration Template Line with checked Mandatory.
        CreateConfigTemplateLineWithDefaultValueAndMandatory(
          ConfigTemplateLine, CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 250), true);

        // [WHEN] Set Default Value.
        ConfigTemplateLine.Validate("Default Value", NewDefaultValue);

        // [THEN] Default Value was validated.
        ConfigTemplateLine.TestField("Default Value", NewDefaultValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyConfigTemplateFromConfigTemplate()
    var
        FromConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220779] Copy master templates
        Initialize();

        // [GIVEN] Configuration template CT1, with line
        CreateConfigTemplateHeaderAndLineForItem(FromConfigTemplateLine);
        FromConfigTemplateLine.Insert();
        // [GIVEN] Configuration template CT2, empty
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        // [WHEN] Copy from CT1 to CT2
        ConfigTemplateHeader.CopyConfigTemplate(FromConfigTemplateLine."Data Template Code");
        // [THEN] CT2 contains the same data as CT1
        VerifyCopiedTemplate(FromConfigTemplateLine."Data Template Code", ConfigTemplateHeader.Code);
    end;

    [Test]
    [HandlerFunctions('ConfigTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure CopyConfigTemplateFromConfigTemplateUI()
    var
        FromConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 220779] Copy master templates
        Initialize();

        // [GIVEN] Configuration template CT1, with line
        CreateConfigTemplateHeaderAndLineForItem(FromConfigTemplateLine);
        FromConfigTemplateLine.Insert();
        // [GIVEN] Configuration template CT2, empty
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        Commit();
        // [WHEN] Copy from CT1 to CT2 (ConfigTemplateListPageHandler)
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        LibraryVariableStorage.Enqueue(FromConfigTemplateLine."Data Template Code");
        ConfigTemplateHeaderPage.Trap();
        ConfigTemplateHeaderPage.OpenEdit();
        ConfigTemplateHeaderPage.GotoRecord(ConfigTemplateHeader);
        ConfigTemplateHeaderPage.CopyConfigTemplate.Invoke();
        // [THEN] CT2 contains the same data as CT1
        VerifyCopiedTemplate(FromConfigTemplateLine."Data Template Code", ConfigTemplateHeader.Code);
    end;

    [Test]
    [HandlerFunctions('StdTextCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookStdTextFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "Standard Text" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = " "
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::" "));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "Standard Text Codes" page opened (StdTextCodesModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookGLAccFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "G/L Account" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = "G/L Account"
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::"G/L Account"));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "G/L Account List" page opened (GLAccountListModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookItemFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "Item" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = "Item"
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::Item));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "Item List" page opened (ItemLookupModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ResourceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookResourceFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "Resource" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = "Resource"
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::Resource));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "Resource List" page opened (ResourceListModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('FixedAssetListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookFixedAssetFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "Fixed Asset" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = "Fixed Asset"
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::"Fixed Asset"));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "Fixed Asset List" page opened (FixedAssetListModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemChargesModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookItemChargeFieldValueFromConfigTemplateLineSalesLine()
    var
        SalesLine: Record "Sales Line";
        TypeConfigTemplateLine: Record "Config. Template Line";
        NoConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FieldValue: Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 287430] User is able to lookup "Item Charge" from Config. Template Line
        Initialize();

        // [GIVEN] Config. Template Header with "Sales Line" table
        // [GIVEN] Config. Template Line with "Type" field
        // [GIVEN] Config. Template Line with "No." field
        CreateSalesLineConfigTemplate(TypeConfigTemplateLine, NoConfigTemplateLine);
        // [WHEN] Lookup to "No." with "Type" = "Charge (Item)"
        SetSalesLineTypeConfigTemplateLine(TypeConfigTemplateLine, Format(SalesLine.Type::"Charge (Item)"));
        ConfigTemplateManagement.LookupFieldValueFromConfigTemplateLine(NoConfigTemplateLine, FieldValue);
        // [THEN] "Item Charges" page opened (ItemChargesModalPageHandler)
        VerifyLookupFieldValue(FieldValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateDefaultValueExpectingRelatedFieldDefaultValue()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
    begin
        // [SCENARIO 383383] In Configuration Template it is possible to use Default Value for field depending on value of another field.
        Initialize();

        // [GIVEN] Configuratrion Template with lines:
        // [GIVEN] Line 1 "Field Name" = "Replenishment System", "Default Value" = "Assembly";
        // [GIVEN] Line 2 "Field Name" = "Assembly Policy", "Default Value" is blank.
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        InputFieldInConfigTemplateLine(
          ConfigTemplateLine, Item.FieldNo("Replenishment System"),
          Item.FieldName("Replenishment System"), Format(Item."Replenishment System"::Assembly), false);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);

        // [WHEN] Line 2 "Default Value" is validated with "Assemble-to-Order".
        InputFieldInConfigTemplateLine(
          ConfigTemplateLine, Item.FieldNo("Assembly Policy"),
          Item.FieldName("Assembly Policy"), Format(Item."Assembly Policy"::"Assemble-to-Order"), false);

        // [THEN] Line 2 "Default Value" = "Assemble-to-Order".
        ConfigTemplateLine.TestField("Default Value", Format(Item."Assembly Policy"::"Assemble-to-Order"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ConfigTemplateHeader_CreateInstance_MessageHandler')]
    procedure PackageItemProductionBOMNoOnValidatePackage();
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ConfigPackageCard: TestPage "Config. Package Card";
        BaseUnitOfMeasureCode: Code[20];
    begin
        // [SCENARIO 558341] Validation Package in Configuration Package is not deleting certain fields data in Item Card.
        Initialize();

        // [GIVEN] Enable Dynamic Low Level Code in Manufacturing Setup.
        ManufacturingSetup.GetRecordOnce();
        ManufacturingSetup.Validate("Dynamic Low-Level Code", true);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN]  Create Production BOM and Certify.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Item."No.", LibraryRandom.RandInt(2));

        // [GIVEN] Store Base Unit of Measure.
        BaseUnitOfMeasureCode := Item."Base Unit of Measure";

        // [GIVEN] Create a Package.
        LibraryRapidStart.CreatePackage(ConfigPackage);

        // [GIVEN] Create Package Table for Item.
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, Database::Item);

        // [GIVEN] Enable Validate Field in Configuration Package Field for Production BOM No.
        ConfigPackageField.Get(ConfigPackage.Code, Database::Item, Item.FieldNo("Production BOM No."));
        ConfigPackageField.Validate("Validate Field", true);
        ConfigPackageField.Modify(true);

        // [GIVEN] Create Package Data for "No.".
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, Database::Item, 1, Item.FIELDNO("No."), Item."No.");

        // [GIVEN] Create Package Data for "Production BOM No.".
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, Database::Item, 1, Item.FIELDNO("Production BOM No."), ProductionBOMHeader."No.");

        // [WHEN] Validate Package on Configuration Package Card.
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.GoToRecord(ConfigPackage);
        ConfigPackageCard.ValidatePackage.Invoke();

        // [THEN] Base Unit of Measure must not be deleted.
        Item.Get(Item."No.");
        Assert.AreEqual(
            BaseUnitOfMeasureCode,
            Item."Base Unit of Measure",
            StrSubstNo(
                BaseUnitOfMeasureErr,
                Item.FieldCaption("Base Unit of Measure")));
    end;

    local procedure Initialize()
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Data Templates");
        LibraryVariableStorage.Clear();
        ConfigTmplSelectionRules.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Data Templates");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        APIMockEvents.SetAPIServicesEnabled(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Data Templates");
    end;

    local procedure CreateConfigTemplateHeaderAndLineForItem(var ConfigTemplateLine: Record "Config. Template Line")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        RecRef: RecordRef;
    begin
        ConfigTemplateHeader.Init();
        ConfigTemplateHeader.Validate(
          Code, LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header"));
        ConfigTemplateHeader.Validate("Table ID", DATABASE::Item);
        ConfigTemplateHeader.Insert(true);

        ConfigTemplateLine.Init();
        ConfigTemplateLine.Validate("Data Template Code", ConfigTemplateHeader.Code);
        RecRef.GetTable(ConfigTemplateLine);
        ConfigTemplateLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ConfigTemplateLine.FieldNo("Line No.")));
        ConfigTemplateLine.Validate("Table ID", DATABASE::Item);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Field ID", Item.FieldNo(Type));
        ConfigTemplateLine.Validate("Default Value", Format(Item.Type::Service));
    end;

    local procedure EvaluateValue(TableNo: Integer; FieldNo: Integer; Value: Text[250])
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        ConfigValidateMgt.EvaluateValue(FieldRef, Value, false);
        ConfigValidateMgt.EvaluateTextToFieldRef(Value, FieldRef, false);
    end;

    local procedure GeneratePackageForTableWithSeriesNo(var ConfigPackage: Record "Config. Package"; var CustomerName: Text[50])
    var
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        CustomerName := Customer."No.";

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::Customer,
          Customer.FieldNo("No."),
          '',
          1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::Customer,
          Customer.FieldNo(Name),
          CustomerName,
          1);

        Customer.Delete();
    end;

    local procedure GenerateTemplateAndPackageForTableWithSeriesNo(var ConfigPackage: Record "Config. Package"; var ConfigTemplateCode: Code[20])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        CustomerName: Text[50];
    begin
        GeneratePackageForTableWithSeriesNo(ConfigPackage, CustomerName);

        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Customer);
        CreateConfigTemplateLineForField(
          ConfigTemplateHeader.Code, Customer.FieldNo("Name 2"), Customer.FieldName("Name 2"), CustomerName);

        ConfigTemplateCode := ConfigTemplateHeader.Code;
    end;

    local procedure ApplyTemplateToContact(Contact: Record Contact; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Contact);
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    local procedure ApplyTemplateToCustomer(Customer: Record Customer; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Customer);
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    local procedure ApplyTemplateToItem(Item: Record Item; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Item);
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    local procedure ApplyTemplateToVendor(Vendor: Record Vendor; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Vendor);
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    local procedure CreateConfigTemplateLineForField(ConfigTemplateHeaderCode: Code[10]; FieldID: Integer; FieldName: Text[30]; DefaultValue: Text[50])
    begin
        CreateConfigTemplateLineForFieldAndValidate(
          ConfigTemplateHeaderCode, FieldID, FieldName, DefaultValue, false);
    end;

    local procedure CreateConfigTemplateLineForFieldAndValidate(ConfigTemplateHeaderCode: Code[10]; FieldID: Integer; FieldName: Text[30]; DefaultValue: Text[50]; SkipValidateRelation: Boolean)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode);
        InputFieldInConfigTemplateLine(ConfigTemplateLine, FieldID, FieldName, DefaultValue, SkipValidateRelation);
    end;

    local procedure CreateConfigTemplateLineWithDefaultValueAndMandatory(var ConfigTemplateLine: Record "Config. Template Line"; DefaultValue: Text[250]; Mandatory: Boolean)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        InputTableInConfigTemplateHeader(ConfigTemplateHeader, DATABASE::Item);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);

        ConfigTemplateLine."Default Value" := DefaultValue;
        ConfigTemplateLine.Mandatory := Mandatory;
        ConfigTemplateLine.Modify();
    end;

    local procedure CreateProdOrderLine(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    var
        RecRef: RecordRef;
    begin
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        RecRef.GetTable(ProdOrderLine);
        ProdOrderLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, ProdOrderLine.FieldNo("Line No."));
        ProdOrderLine."Item No." := '';
        ProdOrderLine.Insert();
    end;

    local procedure CreateNewInstance(ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(ConfigTemplateHeader."Table ID");
        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    local procedure CreateSalesLineConfigTemplate(var TypeConfigTemplateLine: Record "Config. Template Line"; var NoConfigTemplateLine: Record "Config. Template Line")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", DATABASE::"Sales Line");
        ConfigTemplateHeader.Modify(true);

        LibraryRapidStart.CreateConfigTemplateLine(TypeConfigTemplateLine, ConfigTemplateHeader.Code);
        TypeConfigTemplateLine.Validate("Skip Relation Check", true);
        TypeConfigTemplateLine.Validate("Field ID", SalesLine.FieldNo(Type));
        TypeConfigTemplateLine.Modify(true);

        LibraryRapidStart.CreateConfigTemplateLine(NoConfigTemplateLine, ConfigTemplateHeader.Code);
        NoConfigTemplateLine.Validate("Skip Relation Check", true);
        NoConfigTemplateLine.Validate("Field ID", SalesLine.FieldNo("No."));
        NoConfigTemplateLine.Modify(true);
    end;

    local procedure InputFieldInConfigTemplateLine(var ConfigTemplateLine: Record "Config. Template Line"; FieldID: Integer; FieldName: Text[30]; DefaultValue: Text[50]; SkipRelationValidation: Boolean)
    begin
        ConfigTemplateLine.Validate("Field ID", FieldID);
        ConfigTemplateLine.Validate("Field Name", FieldName);
        ConfigTemplateLine.Validate("Skip Relation Check", SkipRelationValidation);
        ConfigTemplateLine.Validate("Default Value", DefaultValue);
        ConfigTemplateLine.Modify(true);
    end;

    local procedure InputTableInConfigTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; TableID: Integer)
    begin
        ConfigTemplateHeader.Validate("Table ID", TableID);
        ConfigTemplateHeader.Modify(true);
    end;

    local procedure InputTemplateConfigTemplateLine(ConfigTemplateLine: Record "Config. Template Line"; TemplateCode: Code[10])
    begin
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Template);
        ConfigTemplateLine.Validate("Template Code", TemplateCode);
        ConfigTemplateLine.Modify(true);
    end;

    local procedure SetSalesLineTypeConfigTemplateLine(var TypeConfigTemplateLine: Record "Config. Template Line"; SalesLineTypeText: Text)
    begin
        TypeConfigTemplateLine.Validate("Default Value", CopyStr(SalesLineTypeText, 1, MaxStrLen(TypeConfigTemplateLine."Default Value")));
        TypeConfigTemplateLine.Modify(true);
    end;

    local procedure VerifyTemplateLineCreated(ConfigTemplateCode: Code[10]; CustomerPostingGroupFieldID: Integer; CurrencyFieldID: Integer; GenBusinessPostingGroupFieldID: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateCode);
        ConfigTemplateLine.FindSet();
        ConfigTemplateLine.TestField("Field ID", CustomerPostingGroupFieldID);

        ConfigTemplateLine.Next();
        ConfigTemplateLine.TestField("Field ID", CurrencyFieldID);

        ConfigTemplateLine.Next();
        ConfigTemplateLine.TestField("Field ID", GenBusinessPostingGroupFieldID);
    end;

    local procedure VerifyCopiedTemplate(SourceConfigTemplateCode: Code[10]; ConfigTemplateCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        SourceConfigTemplateHeader: Record "Config. Template Header";
        SourceConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateHeader.Get(ConfigTemplateCode);
        SourceConfigTemplateHeader.Get(SourceConfigTemplateCode);
        ConfigTemplateHeader.TestField("Table ID", SourceConfigTemplateHeader."Table ID");
        ConfigTemplateHeader.TestField(Enabled, SourceConfigTemplateHeader.Enabled);

        SourceConfigTemplateLine.SetRange("Data Template Code", SourceConfigTemplateCode);
        SourceConfigTemplateLine.FindSet();
        repeat
            ConfigTemplateLine.Get(ConfigTemplateCode, SourceConfigTemplateLine."Line No.");
            ConfigTemplateLine.TestField(Type, SourceConfigTemplateLine.Type);
            ConfigTemplateLine.TestField("Field ID", SourceConfigTemplateLine."Field ID");
            ConfigTemplateLine.TestField("Table ID", SourceConfigTemplateLine."Table ID");
            ConfigTemplateLine.TestField("Default Value", SourceConfigTemplateLine."Default Value");
        until SourceConfigTemplateLine.Next() = 0;
    end;

    local procedure VerifyLookupFieldValue(FieldValue: Text)
    var
        LookupFieldValue: Text;
    begin
        LookupFieldValue := LibraryVariableStorage.DequeueText();

        Assert.AreEqual(LookupFieldValue, FieldValue, WrongFieldValueErr);
        Assert.AreNotEqual('', LookupFieldValue, WrongFieldValueErr);
        Assert.AreNotEqual('', FieldValue, WrongFieldValueErr);
    end;

    local procedure ConfigTemplateLine_LookupFields(var ConfigTemplateHeader: Record "Config. Template Header"; LineType: Enum "Config. Template Line Type")
    var
        ConfigTemplateHeaderPage: TestPage "Config. Template Header";
    begin
        ConfigTemplateHeaderPage.OpenEdit();
        ConfigTemplateHeaderPage.GotoRecord(ConfigTemplateHeader);
        ConfigTemplateHeaderPage.ConfigTemplateSubform.New();
        ConfigTemplateHeaderPage.ConfigTemplateSubform.Type.SetValue(LineType);
        if LineType = LineType::Field then
            ConfigTemplateHeaderPage.ConfigTemplateSubform."Field Name".Lookup()
        else
            ConfigTemplateHeaderPage.ConfigTemplateSubform."Template Code".Lookup();
        ConfigTemplateHeaderPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateLine_LookupFieldName_Handler(var FieldsLookup: TestPage "Fields Lookup")
    var
        "Field": Record "Field";
        Customer: Record Customer;
    begin
        Field.Get(DATABASE::Customer, Customer.FieldNo("Prices Including VAT"));
        FieldsLookup.GotoRecord(Field);
        FieldsLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateLine_LookupTemplateCode_Handler(var ConfigTemplateList: TestPage "Config. Template List")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateHeaderCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ConfigTemplateHeaderCode);
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.SetFilter(Code, ConfigTemplateHeaderCode);
        ConfigTemplateHeader.FindFirst();
        ConfigTemplateList.GotoRecord(ConfigTemplateHeader);
        ConfigTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateHeader_CreateInstance_MessageHandler(MessageStr: Text[1024])
    begin
    end;

    local procedure CreateItemWithFIFOandILE(var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
    begin
        LibraryInventory.CreateItem(Item);

        ItemLedgerEntry.FindLast();
        EntryNo := ItemLedgerEntry."Entry No.";
        Clear(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := EntryNo + 1;
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplateListPageHandler(var ConfigTemplateList: TestPage "Config. Template List")
    begin
        asserterror ConfigTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        ConfigTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        ConfigTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StdTextCodesModalPageHandler(var StandardTextCodes: TestPage "Standard Text Codes")
    begin
        StandardTextCodes.First();
        LibraryVariableStorage.Enqueue(StandardTextCodes.Code.Value);
        StandardTextCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListModalPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        GLAccountList.First();
        LibraryVariableStorage.Enqueue(GLAccountList."No.".Value);
        GLAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLookupModalPageHandler(var ItemLookup: TestPage "Item Lookup")
    begin
        ItemLookup.First();
        LibraryVariableStorage.Enqueue(ItemLookup."No.".Value);
        ItemLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListModalPageHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.First();
        LibraryVariableStorage.Enqueue(ResourceList."No.".Value);
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetListModalPageHandler(var FixedAssetList: TestPage "Fixed Asset List")
    begin
        FixedAssetList.First();
        LibraryVariableStorage.Enqueue(FixedAssetList."No.".Value);
        FixedAssetList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargesModalPageHandler(var ItemCharges: TestPage "Item Charges")
    begin
        ItemCharges.First();
        LibraryVariableStorage.Enqueue(ItemCharges."No.".Value);
        ItemCharges.OK().Invoke();
    end;
}

