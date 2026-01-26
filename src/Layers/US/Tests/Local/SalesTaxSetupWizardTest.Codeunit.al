codeunit 140552 "Sales Tax Setup Wizard Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TaxAccErr: Label 'Wrong Tax Account';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitEarly()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        GuidedExperience: Codeunit "Guided Experience";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is canceled
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.Close();

        // [THEN] Status of the setup step is still set to Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Sales Tax Setup Wizard"), 'Guided Experience status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitEarlyAndSayNo()
    var
        GLAccount: Record "G/L Account";
        GuidedExperience: Codeunit "Guided Experience";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);

        // [WHEN] Sales tax setup wizard is canceled
        SalesTaxSetupWizard.Trap();
        PAGE.Run(PAGE::"Sales Tax Setup Wizard");
        SalesTaxSetupWizard.Close();

        // [THEN] Status of the setup step is still set to Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Sales Tax Setup Wizard"), 'Guided Experience status should not be completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        GuidedExperience: Codeunit "Guided Experience";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is completed
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Sales Tax Setup Wizard"), 'Guided Experience status should be completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxGroup()
    var
        TaxGroup: Record "Tax Group";
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is completed
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] A tax group is created
        TaxGroup.Get('TAXABLE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxArea()
    var
        TaxArea: Record "Tax Area";
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is completed
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] The tax area is created
        TaxArea.Get(TempSalesTaxSetupWizard."Tax Area Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxAreaBasedOnCityWithNoState()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] City and state are entered in the wizard
        TempSalesTaxSetupWizard.City := 'Little Rock';

        // [WHEN] Wizard is stepped through to the end
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] A default area code is created based on the city and state
        SalesTaxSetupWizard."Tax Area Code".AssertEquals('LITTLE ROCK');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxAreaBasedOnStateWithNoCity()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] City and state are entered in the wizard
        TempSalesTaxSetupWizard.State := 'AR';

        // [WHEN] Wizard is stepped through to the end
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] A default area code is created based on the city and state
        SalesTaxSetupWizard."Tax Area Code".AssertEquals('AR');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxAreaBasedOnCityAndState()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] City and state are entered in the wizard
        TempSalesTaxSetupWizard.City := 'Little Rock';
        TempSalesTaxSetupWizard.State := 'AR';

        // [WHEN] Wizard is stepped through to the end
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] A default area code is created based on the city and state
        SalesTaxSetupWizard."Tax Area Code".AssertEquals('LITTLE ROCK, AR');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateTaxAreaBasedOnTruncatedCityAndState()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        ExpectedValue: Text;
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] City and state are entered in the wizard
        TempSalesTaxSetupWizard.City := 'Llanfairpwllgwyngyll';
        TempSalesTaxSetupWizard.State := 'MN';

        // [WHEN] Wizard is stepped through to the end
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] A default area code is created based on the city and state
        ExpectedValue := StrSubstNo('%1, %2', UpperCase(CopyStr(TempSalesTaxSetupWizard.City, 1, 16)), TempSalesTaxSetupWizard.State);
        SalesTaxSetupWizard."Tax Area Code".AssertEquals(ExpectedValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidationErrorWhenCityBlankButCityRateGtZero()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] A city tax rate is entered but not a city name
        TempSalesTaxSetupWizard."City Rate" := 2;

        // [WHEN] Wizard is stepped through and the values are entered
        asserterror RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] Validation error is thrown about the city name.
        if StrPos(GetLastErrorText, 'city tax') = 0 then
            Error(GetLastErrorText);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidationErrorWhenCountyBlankButCountyRateGtZero()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] A county tax rate is entered but not a county name
        TempSalesTaxSetupWizard."County Rate" := 2;

        // [WHEN] Wizard is stepped through and the values are entered
        asserterror RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] Validation error is thrown about the county name
        if StrPos(GetLastErrorText, 'county tax') = 0 then
            Error(GetLastErrorText);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidationErrorWhenStateBlankButStateRateGtZero()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";

        // [WHEN] A state tax rate is entered but not a state code
        TempSalesTaxSetupWizard."State Rate" := 2;

        // [WHEN] Wizard is stepped through and the values are entered
        asserterror RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] Validation error is thrown about the state code
        if StrPos(GetLastErrorText, 'state tax') = 0 then
            Error(GetLastErrorText);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidationErrorWhenBothTaxAccountsAreBlank()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);

        // [WHEN] Wizard is stepped through and no values are entered for the tax accounts
        asserterror RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);

        // [THEN] Validation error is thrown about the state code
        if StrPos(GetLastErrorText, 'must specify') = 0 then
            Error(GetLastErrorText);

        // [THEN] Next button is disabled
        Assert.AreEqual(false, SalesTaxSetupWizard.ActionNextStep.Enabled(), 'Next should be disabled when no accounts have been entered');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateRecordsWhenCityEmpty()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        TaxArea: Code[20];
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Account (Purchases)" := GLAccount."No.";

        // [WHEN] County and state tax information is entered, but city is empty
        TempSalesTaxSetupWizard.County := CopyStr(CreateGuid(), 2, 30);
        TempSalesTaxSetupWizard."County Rate" := LibraryRandom.RandDec(3, 2);
        TempSalesTaxSetupWizard.State := CopyStr(CreateGuid(), 2, 2);
        TempSalesTaxSetupWizard."State Rate" := LibraryRandom.RandDec(3, 2);

        // [WHEN] Wizard is stepped through to completion with the values
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        TaxArea := SalesTaxSetupWizard."Tax Area Code".Value();
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] Tax area has been created
        CheckTaxArea(TaxArea);

        // [THEN] Tax jurisdictions have been created
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.County, TempSalesTaxSetupWizard.State, GLAccount."No.");
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.State, TempSalesTaxSetupWizard.State, GLAccount."No.");

        // [THEN] Tax area lines have been created
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.County);
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.State);

        // [THEN] Tax details have been created
        CheckTaxDetail(TempSalesTaxSetupWizard.County, TempSalesTaxSetupWizard."County Rate");
        CheckTaxDetail(TempSalesTaxSetupWizard.State, TempSalesTaxSetupWizard."State Rate");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateRecordsWhenCountyEmpty()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        TaxArea: Code[20];
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Account (Purchases)" := GLAccount."No.";

        // [WHEN] City and state tax information is entered, but county is empty
        TempSalesTaxSetupWizard.City := CopyStr(CreateGuid(), 2, 30);
        TempSalesTaxSetupWizard."City Rate" := LibraryRandom.RandDec(3, 2);
        TempSalesTaxSetupWizard.State := CopyStr(CreateGuid(), 2, 2);
        TempSalesTaxSetupWizard."State Rate" := LibraryRandom.RandDec(3, 2);

        // [WHEN] Wizard is stepped through to completion with the values
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        TaxArea := SalesTaxSetupWizard."Tax Area Code".Value();
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] Tax area has been created
        CheckTaxArea(TaxArea);

        // [THEN] Tax jurisdictions have been created
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.City, TempSalesTaxSetupWizard.State, GLAccount."No.");
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.State, TempSalesTaxSetupWizard.State, GLAccount."No.");

        // [THEN] Tax area lines have been created
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.City);
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.State);

        // [THEN] Tax details have been created
        CheckTaxDetail(TempSalesTaxSetupWizard.City, TempSalesTaxSetupWizard."City Rate");
        CheckTaxDetail(TempSalesTaxSetupWizard.State, TempSalesTaxSetupWizard."State Rate");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyCreateRecordsWhenStateEmpty()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        TaxArea: Code[20];
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Account (Purchases)" := GLAccount."No.";

        // [WHEN] City and county tax information is entered, but state is empty
        TempSalesTaxSetupWizard.City := CopyStr(CreateGuid(), 2, 30);
        TempSalesTaxSetupWizard."City Rate" := LibraryRandom.RandDec(3, 2);
        TempSalesTaxSetupWizard.County := CopyStr(CreateGuid(), 2, 2);
        TempSalesTaxSetupWizard."County Rate" := LibraryRandom.RandDec(3, 2);

        // [WHEN] Wizard is stepped through to completion with the values
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        TaxArea := SalesTaxSetupWizard."Tax Area Code".Value();
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] Tax area has been created
        CheckTaxArea(TaxArea);

        // [THEN] Tax jurisdictions have been created
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.City, '', GLAccount."No.");
        CheckTaxJurisdiction(TempSalesTaxSetupWizard.County, '', GLAccount."No.");

        // [THEN] Tax area lines have been created
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.City);
        CheckTaxAreaLine(TaxArea, TempSalesTaxSetupWizard.County);

        // [THEN] Tax details have been created
        CheckTaxDetail(TempSalesTaxSetupWizard.City, TempSalesTaxSetupWizard."City Rate");
        CheckTaxDetail(TempSalesTaxSetupWizard.County, TempSalesTaxSetupWizard."County Rate");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerCustomer')]
    [Scope('OnPrem')]
    procedure VerifyTaxAreaCodeIsSetForSelectedCustomers()
    var
        Customer: Record Customer;
        Customer1: Record Customer;
        Customer2: Record Customer;
        Customer3: Record Customer;
        AssignTaxAreatoCustomer: Report "Assign Tax Area to Customer";
        BaseCount: Integer;
        CountWithNewTaxAreaCode: Integer;
    begin
        // [FEATURE] [Mass Assign Tax Area To Customers]
        // [GIVEN] Multiple customers without 'Tax Area Code' assigned to them
        CreateTempCustomer(Customer1, 'IL', false);
        CreateTempCustomer(Customer2, 'IL', false);
        CreateTempCustomer(Customer3, 'NY', false);

        // [WHEN] 'Tax Area Code' is set for a particular 'County'
        Commit();
        Customer.SetRange(County, 'IL');
        AssignTaxAreatoCustomer.SetTableView(Customer);
        AssignTaxAreatoCustomer.InitializeRequest(false, 'testCode');
        AssignTaxAreatoCustomer.Run();

        // [THEN] 'Tax Area Code' should be set to all cutomers with County set to 'IL'
        BaseCount := Customer.Count();
        Customer.SetRange("Tax Area Code", UpperCase('testCode'));
        CountWithNewTaxAreaCode := Customer.Count();
        Assert.AreEqual(
          CountWithNewTaxAreaCode, BaseCount, 'All Customers belonging to the selected County did not get assigned to a Tax Area Code');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerCustomer')]
    [Scope('OnPrem')]
    procedure VerifyTaxLiableIsSetForSelectedCustomers()
    var
        Customer: Record Customer;
        Customer1: Record Customer;
        Customer2: Record Customer;
        Customer3: Record Customer;
        AssignTaxAreatoCustomer: Report "Assign Tax Area to Customer";
        BaseCount: Integer;
        CountWithNewTaxAreaCode: Integer;
    begin
        // [FEATURE] [Mass Assign Tax Area To Customers]
        // [GIVEN] Multiple customers with 'Tax Liable' set to False
        CreateTempCustomer(Customer1, 'IL', false);
        CreateTempCustomer(Customer2, 'IL', false);
        CreateTempCustomer(Customer3, 'NY', true);

        // [WHEN] 'Tax Area Code' is set for a particular 'County'
        Commit();
        Customer.SetRange(County, 'IL');
        AssignTaxAreatoCustomer.SetTableView(Customer);
        AssignTaxAreatoCustomer.InitializeRequest(true, 'testCode');
        AssignTaxAreatoCustomer.Run();

        // [THEN] 'Tax Area Code' should be set to all cutomers with County set to 'IL'
        BaseCount := Customer.Count();
        Customer.SetRange("Tax Liable", true);
        CountWithNewTaxAreaCode := Customer.Count();
        Assert.AreEqual(
          CountWithNewTaxAreaCode, BaseCount, 'All Customers belonging to the selected County did not get set to be tax liable');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerVendor')]
    [Scope('OnPrem')]
    procedure VerifyTaxAreaCodeIsSetForSelectedVendor()
    var
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        AssignTaxAreatoVendor: Report "Assign Tax Area to Vendor";
        BaseCount: Integer;
        CountWithNewTaxAreaCode: Integer;
    begin
        // [FEATURE] [Mass Assign Tax Area To Vendors]
        // [GIVEN] Multiple vendors without 'Tax Area Code' assigned to them
        CreateTempVendor(Vendor1, 'IL', false);
        CreateTempVendor(Vendor2, 'IL', false);
        CreateTempVendor(Vendor3, 'NY', false);

        // [WHEN] 'Tax Area Code' is set for a particular 'County'
        Commit();
        Vendor.SetRange(County, 'IL');
        AssignTaxAreatoVendor.SetTableView(Vendor);
        AssignTaxAreatoVendor.InitializeRequest(false, 'testCode');
        AssignTaxAreatoVendor.Run();

        // [THEN] 'Tax Area Code' should be set to all vendors with County set to 'IL'
        BaseCount := Vendor.Count();
        Vendor.SetRange("Tax Area Code", UpperCase('testCode'));
        CountWithNewTaxAreaCode := Vendor.Count();
        Assert.AreEqual(
          CountWithNewTaxAreaCode, BaseCount, 'All vendors belonging to the selected County did not get assigned to a Tax Area Code');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerVendor')]
    [Scope('OnPrem')]
    procedure VerifyTaxLiableIsSetForSelectedVendor()
    var
        Vendor: Record Vendor;
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        AssignTaxAreatoVendor: Report "Assign Tax Area to Vendor";
        BaseCount: Integer;
        CountWithNewTaxAreaCode: Integer;
    begin
        // [FEATURE] [Mass Assign Tax Area To Vendors]
        // [GIVEN] Multiple vendors with 'Tax Liable' set to False
        CreateTempVendor(Vendor1, 'IL', false);
        CreateTempVendor(Vendor2, 'IL', false);
        CreateTempVendor(Vendor3, 'NY', true);

        // [WHEN] 'Tax Liable' is set for a particular 'County'
        Commit();
        Vendor.SetRange(County, 'IL');
        AssignTaxAreatoVendor.SetTableView(Vendor);
        AssignTaxAreatoVendor.InitializeRequest(true, 'testCode');
        AssignTaxAreatoVendor.Run();

        // [THEN] 'Tax Liable' should be set to all vendors with County set to 'IL'
        BaseCount := Vendor.Count();
        Vendor.SetRange("Tax Liable", true);
        CountWithNewTaxAreaCode := Vendor.Count();
        Assert.AreEqual(
          CountWithNewTaxAreaCode, BaseCount, 'All vendors belonging to the selected County did not get set to be tax liable');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerLocation')]
    [Scope('OnPrem')]
    procedure VerifyTaxAreaCodeIsSetForSelectedLocations()
    var
        Location: Record Location;
        Location1: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        AssignTaxAreatoLocation: Report "Assign Tax Area to Location";
        BaseCount: Integer;
        CountWithNewTaxAreaCode: Integer;
    begin
        // [FEATURE] [Mass Assign Tax Area To Locations]
        // [GIVEN] Multiple locations without 'Tax Area Code' assigned to them
        LibraryWarehouse.CreateLocation(Location1);
        Location1.Name := 'Test Warehouse';
        Location1.Modify();
        LibraryWarehouse.CreateLocation(Location2);
        Location2.Name := 'Test Warehouse';
        Location2.Modify();
        LibraryWarehouse.CreateLocation(Location3);
        Location3.Name := 'Test2 Warehouse';
        Location3.Modify();

        // [WHEN] 'Tax Area Code' is set for a particular 'County'
        Commit();
        Location.SetRange(Name, 'Test Warehouse');
        AssignTaxAreatoLocation.SetTableView(Location);
        AssignTaxAreatoLocation.InitializeRequest('testCode');
        AssignTaxAreatoLocation.Run();

        // [THEN] 'Tax Area Code' should be set to all Locations with County set to 'IL'
        BaseCount := Location.Count();
        Location.SetRange("Tax Area Code", UpperCase('testCode'));
        CountWithNewTaxAreaCode := Location.Count();
        Assert.AreEqual(
          CountWithNewTaxAreaCode, BaseCount, 'All locations belonging to the selected County did not get assigned to a Tax Area Code');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerAutoAssignCustomer')]
    [Scope('OnPrem')]
    procedure VerifyCreateAndAssignTaxArea_Customer()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is semi-completed with the option to assign new tax code to customers set to true
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.AssignToCustomers.SetValue(true);

        // [THEN] Upon closing the wizard the page to assign customers to tax area code opens
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        SalesTaxSetupWizard.Finish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerAutoAssignVendor')]
    [Scope('OnPrem')]
    procedure VerifyCreateAndAssignTaxArea_Vendor()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is semi-completed with the option to assign new tax code to vendors set to true
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.AssignToVendors.SetValue(true);

        // [THEN] Upon closing the wizard the page to assign vendors to tax area code opens
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        SalesTaxSetupWizard.Finish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerAutoAssignLocation')]
    [Scope('OnPrem')]
    procedure VerifyCreateAndAssignTaxArea_Location()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TempSalesTaxSetupWizard."Tax Area Code" := CopyStr(CreateGuid(), 2, 20);

        // [WHEN] Sales tax setup wizard is semi-completed with the option to assign new tax code to vendors set to true
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.AssignToLocations.SetValue(true);

        // [THEN] Upon closing the wizard the page to assign vendors to tax area code opens
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        SalesTaxSetupWizard.Finish.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCreateAndAssignTaxArea_CompanyInfo()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        CompanyInformation: Record "Company Information";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        TaxCode: Code[20];
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TaxCode := CopyStr(CreateGuid(), 2, 20);
        TempSalesTaxSetupWizard."Tax Area Code" := TaxCode;

        // [WHEN] Sales tax setup wizard is semi-completed with the option to assign new tax code to locations set to true
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.AssignToCompanyInfo.SetValue(true);
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] tax area code is assigned to company information
        if CompanyInformation.FindFirst() then
            Assert.AreEqual(CompanyInformation."Tax Area Code", TaxCode,
              'Company Tax Area Code must be equal to the new TaxCode');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerAutoAssignCustomer,RequestPageHandlerAutoAssignVendor,RequestPageHandlerAutoAssignLocation')]
    [Scope('OnPrem')]
    procedure VerifyCreateAndAssignTaxArea_All()
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        GLAccount: Record "G/L Account";
        CompanyInformation: Record "Company Information";
        SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard";
        TaxCode: Code[20];
    begin
        // [GIVEN] A G/L account exists
        Initialize(GLAccount);
        Clear(SalesTaxSetupWizard);

        // [WHEN] Some arbitrary information is entered into the wizard
        TempSalesTaxSetupWizard."Tax Account (Sales)" := GLAccount."No.";
        TaxCode := CopyStr(CreateGuid(), 2, 20);
        TempSalesTaxSetupWizard."Tax Area Code" := TaxCode;

        // [WHEN] Sales tax setup wizard is semi-completed with the option to assign new tax code to customers,vendors, and locations set to true
        RunWizardToCompletion(SalesTaxSetupWizard, TempSalesTaxSetupWizard);
        SalesTaxSetupWizard.AssignToCompanyInfo.SetValue(true);
        SalesTaxSetupWizard.AssignToCustomers.SetValue(true);
        SalesTaxSetupWizard.AssignToVendors.SetValue(true);
        SalesTaxSetupWizard.AssignToLocations.SetValue(true);

        // [THEN] Upon closing the wizard the pages to assign customers,vendors, and locations to tax area code open
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        LibraryVariableStorage.Enqueue(TempSalesTaxSetupWizard."Tax Area Code");
        SalesTaxSetupWizard.Finish.Invoke();

        // [THEN] tax area code is assigned to company information
        if CompanyInformation.FindFirst() then
            Assert.AreEqual(CompanyInformation."Tax Area Code", TaxCode,
              'Company Tax Area Code must be equal to the new TaxCode');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifySalesTaxSetupWizardInitializedWhenAccDeletedUT()
    var
        GLAccount: Record "G/L Account";
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxSetup: Record "Tax Setup";
    begin
        // [SCENARIO 286191] Run Sales Tax Guided Experience Wizard when g/l account in defaults is removed
        InitializeSetup();
        // [GIVEN] G/L account "ACC"
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] Tax setup (defaults) with "ACC"
        TaxSetup.Init();
        TaxSetup.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxSetup.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxSetup.Insert(true);
        // [GIVEN] Deleted "ACC"
        GLAccount.Delete(true);
        // [WHEN] Sales Tax Setup Wizard record initialized (on wizard run)
        SalesTaxSetupWizard.Initialize();
        // [THEN] Wizard is not failed, record is initialized, tax accounts are empty
        Assert.IsTrue(SalesTaxSetupWizard."Tax Account (Sales)" = '', TaxAccErr);
        Assert.IsTrue(SalesTaxSetupWizard."Tax Account (Purchases)" = '', TaxAccErr);
    end;

    local procedure RunWizardToCompletion(var SalesTaxSetupWizard: TestPage "Sales Tax Setup Wizard"; var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary)
    begin
        SalesTaxSetupWizard.Trap();
        PAGE.Run(PAGE::"Sales Tax Setup Wizard", TempSalesTaxSetupWizard);

        // Transfer fields from record to page
        SalesTaxSetupWizard.ActionNextStep.Invoke();
        // To tax group created page
        SalesTaxSetupWizard.Back.Invoke();
        SalesTaxSetupWizard.ActionNextStep.Invoke();

        SalesTaxSetupWizard.ActionNextStep.Invoke();
        // To tax account page
        SalesTaxSetupWizard."Tax Account (Sales)".SetValue(TempSalesTaxSetupWizard."Tax Account (Sales)");
        SalesTaxSetupWizard."Tax Account (Purchases)".SetValue(TempSalesTaxSetupWizard."Tax Account (Purchases)");

        SalesTaxSetupWizard.ActionNextStep.Invoke();
        // To tax rate page
        SalesTaxSetupWizard.City.SetValue(TempSalesTaxSetupWizard.City);
        SalesTaxSetupWizard."City Rate".SetValue(TempSalesTaxSetupWizard."City Rate");

        SalesTaxSetupWizard.County.SetValue(TempSalesTaxSetupWizard.County);
        SalesTaxSetupWizard."County Rate".SetValue(TempSalesTaxSetupWizard."County Rate");

        SalesTaxSetupWizard.State.SetValue(TempSalesTaxSetupWizard.State);
        SalesTaxSetupWizard."State Rate".SetValue(TempSalesTaxSetupWizard."State Rate");

        SalesTaxSetupWizard.ActionNextStep.Invoke();
        // To tax area code page
        if SalesTaxSetupWizard."Tax Area Code".Value = '' then
            SalesTaxSetupWizard."Tax Area Code".SetValue(TempSalesTaxSetupWizard."Tax Area Code");

        SalesTaxSetupWizard.ActionNextStep.Invoke();
        // To finish page
        SalesTaxSetupWizard.Back.Invoke();
        SalesTaxSetupWizard.ActionNextStep.Invoke();
    end;

    local procedure Initialize(var GLAccount: Record "G/L Account")
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        if not GLAccount.FindFirst() then begin
            GLAccount.Init();
            GLAccount.Insert(true);
        end;
    end;

    local procedure InitializeSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxSetup: Record "Tax Setup";
    begin
        GeneralLedgerSetup."Allow G/L Acc. Deletion Before" := WorkDate();
        GeneralLedgerSetup.Modify();

        SalesTaxSetupWizard.DeleteAll();
        TaxSetup.DeleteAll();
    end;

    local procedure CheckTaxArea("Code": Code[20])
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Get(Code);
    end;

    local procedure CheckTaxAreaLine(TaxArea: Code[20]; Jurisdiction: Text[30])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        Truncate(Jurisdiction, 10);
        TaxAreaLine.Get(TaxArea, Jurisdiction);
    end;

    local procedure CheckTaxJurisdiction(Jurisdiction: Text[30]; ReportToJurisdiction: Text[30]; GLAccount: Code[20])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        Truncate(Jurisdiction, 10);
        Truncate(ReportToJurisdiction, 10);
        TaxJurisdiction.Get(Jurisdiction);
        Assert.AreEqual(ReportToJurisdiction, TaxJurisdiction."Report-to Jurisdiction", 'Unexpected Report-to Jurisdiction.');
        Assert.AreEqual(GLAccount, TaxJurisdiction."Tax Account (Sales)", 'Unexpected Tax Account (Sales).');
        Assert.AreEqual(GLAccount, TaxJurisdiction."Tax Account (Purchases)", 'Unexpected Tax Account (Purchases).');
    end;

    local procedure CheckTaxDetail(Jurisdiction: Text[30]; TaxRate: Decimal)
    var
        TaxDetail: Record "Tax Detail";
    begin
        Truncate(Jurisdiction, 10);
        TaxDetail.Get(Jurisdiction, 'TAXABLE', TaxDetail."Tax Type"::"Sales and Use Tax", Today);
        Assert.AreEqual(TaxRate, TaxDetail."Tax Below Maximum", 'Unexpected tax rate.');
        Assert.AreEqual(0, TaxDetail."Maximum Amount/Qty.", 'Maximum tax amount is greater than zero.');
    end;

    [Normal]
    local procedure Truncate(var Value: Text; Length: Integer)
    begin
        Value := CopyStr(Value, 1, Length);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure CreateTempVendor(var Vendor: Record Vendor; NewCounty: Text[30]; NewTaxLiable: Boolean)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Address)));
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Validate(County, NewCounty);
        Vendor.Validate("Tax Liable", NewTaxLiable);
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Contact)), 1, MaxStrLen(Vendor.Contact));
        Vendor.Modify(true);
    end;

    local procedure CreateTempCustomer(var Customer: Record Customer; NewCounty: Text[30]; NewTaxLiable: Boolean)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        Customer.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Validate(County, NewCounty);
        Customer.Validate("Tax Liable", NewTaxLiable);
        Customer.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Contact)), 1, MaxStrLen(Customer.Contact));
        Customer.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerCustomer(var AssignTaxAreatoCustomer: TestRequestPage "Assign Tax Area to Customer")
    begin
        AssignTaxAreatoCustomer.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerVendor(var AssignTaxAreatoVendor: TestRequestPage "Assign Tax Area to Vendor")
    begin
        AssignTaxAreatoVendor.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerLocation(var AssignTaxAreatoLocation: TestRequestPage "Assign Tax Area to Location")
    begin
        AssignTaxAreatoLocation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerAutoAssignCustomer(var AssignTaxAreatoCustomer: TestRequestPage "Assign Tax Area to Customer")
    var
        ExpectedTaxAreaCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedTaxAreaCode);
        Assert.IsTrue(StrPos(AssignTaxAreatoCustomer."Tax Area Code Name".Value, ExpectedTaxAreaCode) > 0,
          AssignTaxAreatoCustomer."Tax Area Code Name".Value);
        AssignTaxAreatoCustomer.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerAutoAssignVendor(var AssignTaxAreatoVendor: TestRequestPage "Assign Tax Area to Vendor")
    var
        ExpectedTaxAreaCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedTaxAreaCode);
        Assert.IsTrue(StrPos(AssignTaxAreatoVendor."Tax Area Code".Value, ExpectedTaxAreaCode) > 0,
          AssignTaxAreatoVendor."Tax Area Code".Value);
        AssignTaxAreatoVendor.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerAutoAssignLocation(var AssignTaxAreatoLocation: TestRequestPage "Assign Tax Area to Location")
    var
        ExpectedTaxAreaCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedTaxAreaCode);
        Assert.IsTrue(StrPos(AssignTaxAreatoLocation."Tax Area Code".Value, ExpectedTaxAreaCode) > 0,
          AssignTaxAreatoLocation."Tax Area Code".Value);
        AssignTaxAreatoLocation.Cancel().Invoke();
    end;
}

