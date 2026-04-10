codeunit 139300 "Assis. Comp. Setup Plat. Tests"
{
    // // This test is run by the platform to ensure, that the company is setup correctly
    // // after provisioning of a new client. It executes the wizard and ensures, that
    // // NAV has been set up to the point, where a sales invoice and purchase invoice
    // // can be posted.


    trigger OnRun()
    begin
        // [FEATURE] [Initial Company Setup]
    end;

    var
        Assert: Codeunit Assert;

    [Scope('OnPrem')]
    procedure TestInitialWizard()
    var
        TempConfigSetup: Record "Config. Setup" temporary;
        GLAccount: Record "G/L Account";
        CompanyInformation: Record "Company Information";
        BankAccount: Record "Bank Account";
        AccountingPeriod: Record "Accounting Period";
        ExperienceTierSetup: Record "Experience Tier Setup";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AccountingPeriodStartDate: Date;
    begin
        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeCompanyAndEnableAssistedCompanySetup();
        Assert.RecordIsEmpty(GLAccount);

        // [WHEN] The wizard is executed
        AccountingPeriodStartDate := CalcDate('<-CY>', Today);
        InsertWizardData(TempConfigSetup);
        AssistedCompanySetup.ApplyUserInput(TempConfigSetup, BankAccount, AccountingPeriodStartDate, false);
        CompleteWizardStep();

        // [THEN] The RapidStart pack was imported (e.g. Chart of Account)
        Assert.RecordIsNotEmpty(GLAccount);

        // [THEN] Company Information has been set up
        CompanyInformation.Get();
        Assert.AreEqual(TempConfigSetup.Name, CompanyInformation.Name, 'The company name was not set up correctly.');

        // [THEN] The accounting period has been created
        AccountingPeriod.SetFilter("Starting Date", '>=%1', AccountingPeriodStartDate);
        Assert.RecordIsNotEmpty(AccountingPeriod);

        // [THEN] The experience tier is either Essential or Basic depending on whether the company is a demo company
        ExperienceTierSetup.Get(CompanyName);
        Assert.AreEqual(CompanyInformation."Demo Company", ExperienceTierSetup.Basic,
          'Eval company must have basic Experience Tier');
        Assert.AreEqual(not CompanyInformation."Demo Company", ExperienceTierSetup.Essential,
          'Trial company must have Essential Experience Tier');
    end;

    [Scope('OnPrem')]
    procedure TestPostSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [GIVEN] A newly created company with the initial wizard executed
        // Assert.RecordCount(SalesInvoiceHeader,0);

        // [WHEN] A sales invoice is created and posted
        DocumentNo := CreateAndPostSalesInvoice();

        // [THEN] NAV is able to post that sales invoice
        Assert.IsTrue(SalesInvoiceHeader.Get(DocumentNo), 'Sales Invoice Header was not found');
    end;

    [Scope('OnPrem')]
    procedure SetupCompanyForTestSaasTests()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.LockTable();
        if not CompanyInformation.Get() then
            CompanyInformation.Insert();
        CompanyInformation.Name := 'Foo æoå';
        CompanyInformation.Address := 'OneDrive 2';
        CompanyInformation."Address 2" := '';
        CompanyInformation.City := 'Redmond';
        CompanyInformation.County := 'Washington';
        CompanyInformation."Post Code" := '98052';
        CompanyInformation."Country/Region Code" := 'US';
        CompanyInformation."Phone No." := '4529229677';
        CompanyInformation.Modify();
    end;

    [Scope('OnPrem')]
    procedure TestPostPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [GIVEN] A newly created company with the initial wizard executed
        // Assert.RecordCount(PurchInvHeader,0);

        // [WHEN] A purchase invoice is created
        DocumentNo := CreateAndPostPurchaseInvoice();

        // [THEN] NAV is able to post that purchase invoice
        Assert.IsTrue(PurchInvHeader.Get(DocumentNo), 'Purchase Invoice Header was not found');
    end;

    local procedure InsertWizardData(var TempConfigSetup: Record "Config. Setup" temporary)
    begin
        TempConfigSetup.Init();
        TempConfigSetup.Name := CompanyName;
        TempConfigSetup.Insert();
    end;

    local procedure CompleteWizardStep()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        // The compltion status of the wizard is usually set by the wizard, hence the following code
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Assisted Company Setup Wizard");
    end;

    local procedure CreateAndPostSalesInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoice(): Code[20]
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure InitializeCompanyAndEnableAssistedCompanySetup()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");
        AssistedCompanySetupStatus.SetEnabled(CompanyName, true, true);
    end;
}

