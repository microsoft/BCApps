codeunit 136400 "Resource Employee"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Employee]
        IsInitialized := false;
    end;

    var
        LibraryHumanResource: Codeunit "Library - Human Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        IncrementMessageErr: Label 'Employee No must be incremented as per the setup.';
        EditableErr: Label '%1 should not be editable.';
        ValidationErr: Label '%1 %2 must not exist after deletion.';
        EmployeeNoSeriesCode: Code[20];
        InvalidEmailAddressTxt: Label 'invalidemail';
        ValidEmailTxt: Label 'valid@contoso.com';
        TextValue: Text[100];

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeNoIncrement()
    var
        Employee: Record Employee;
        NoSeries: Codeunit "No. Series";
        NextEmployeeNo: Code[20];
    begin
        // Covers document number TC00062 - refer to TFS ID 21680.
        // Test Employee No. is incremented automatically as per the setup.

        // 1. Setup: Get next employee no from No Series.
        Initialize();
        NextEmployeeNo := NoSeries.PeekNextNo(LibraryHumanResource.SetupEmployeeNumberSeries());

        // 2. Exercise:  Create new Employee.
        CreateEmployee(Employee);

        // 3. Verify: Check that the application generates an error if Employee No. is not incremented automatically as per the setup.
        Assert.AreEqual(NextEmployeeNo, Employee."No.", IncrementMessageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfEmployee()
    var
        Employee: Record Employee;
    begin
        // Create new Employee and verify Employee exists after creation.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Employee.
        LibraryHumanResource.CreateEmployee(Employee);

        // 3. Verify: Check that the Employee has been created.
        Employee.Get(Employee."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletionOfEmployee()
    var
        Employee: Record Employee;
        EmployeeNo: Code[20];
    begin
        // Create new Employee, delete and verify Employee has been deleted.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeeNo := Employee."No.";

        // 2. Exercise: Delete the Employee.
        Employee.Delete(true);

        // 3. Verify: Try to get the Employee and make sure that it cannot be found.
        Assert.IsFalse(Employee.Get(EmployeeNo), StrSubstNo(ValidationErr, Employee.TableCaption(), EmployeeNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationOfEmployee()
    var
        Employee: Record Employee;
        LibraryUtility: Codeunit "Library - Utility";
        Address: Text[50];
        Address2: Text[50];
    begin
        // Create new Employee and verify Address after modification in Employee.

        // 1. Setup: Create employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);

        // 2. Exercise: Input the Employee Address.
        Address :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo(Address), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo(Address)));
        Address2 :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo("Address 2"), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo("Address 2")));
        EditEmployeeAddress(Employee, Address, Address2);

        // 3. Verify: Check Address and Address 2 have correct value in Employee.
        Employee.Get(Employee."No.");  // Get refreshed instance.
        Employee.TestField(Address, Address);
        Employee.TestField("Address 2", Address2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateEmployeeHavingExistingNo()
    var
        Employee: Record Employee;
        FirstEmployeeNo: Code[20];
    begin
        // Create new Employee with No. of existing Employee and verify that application generates an error message.

        // 1. Setup: Create first Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        FirstEmployeeNo := Employee."No.";
        Clear(Employee);

        // 2. Exercise:Try to create another Employee with No. of existing Employee.
        Employee.Init();
        Employee.Validate("No.", FirstEmployeeNo);
        Employee.Insert(true);
        asserterror Commit();

        // 3. Verify: Verify that application generates an error message.
        Assert.AssertRecordAlreadyExists();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameEmployeeHavingExistingNo()
    var
        Employee: Record Employee;
        FirstEmployeeNo: Code[20];
    begin
        // Create new Employee, rename with No. of existing Employee and verify that application generates an error message.

        // 1. Setup: Create first employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        FirstEmployeeNo := Employee."No.";
        Clear(Employee);
        LibraryHumanResource.CreateEmployee(Employee);

        // 2. Exercise: Create another employee and rename it with existing employee.
        asserterror Employee.Rename(FirstEmployeeNo);

        // 3. Verify: Verify that application generates an error message.
        Assert.AssertRecordAlreadyExists();
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalHandler')]
    [Scope('OnPrem')]
    procedure EmployeeNoAssistEdit()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
        EmployeeCard: TestPage "Employee Card";
    begin
        // Test Employee No. is incremented by AssistEdit automatically as per the setup.

        // 1. Setup: Find Next Employee No.
        HumanResourcesSetup.Get();

        // 2. Exercise: Genrate New Employee No. by click on AssistEdit Button with No. Series Code.

        commit();
        EmployeeCard.OpenNew();
        EmployeeCard."No.".AssistEdit(); // Get No. Series Code in EmployeeNoSeriesCode.

        // 3. Verify: No. Series Code must match with No. Series Code in Setup.
        HumanResourcesSetup.TestField("Employee Nos.", EmployeeNoSeriesCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeEmailValidationInvalid()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // Test Employee E-Mail and Company E-Mail validation

        // Setup: Create and open Employee Card
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);

        EmployeeCard.OpenEdit();
        EmployeeCard.GotoRecord(Employee);

        // Exercise and verify that setting an invalid email triggers error
        asserterror EmployeeCard."Company E-Mail".SetValue(InvalidEmailAddressTxt);
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid', InvalidEmailAddressTxt));
        asserterror EmployeeCard."E-Mail".SetValue(InvalidEmailAddressTxt);
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid', InvalidEmailAddressTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeEmailValidationValid()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // Test Employee E-Mail and Company E-Mail validation

        // 1. Setup: Create and open Employee Card
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        Commit();

        EmployeeCard.OpenEdit();
        EmployeeCard.GotoRecord(Employee);

        // 2. Exercise: Set E-Mail address to a valid value
        EmployeeCard."Company E-Mail".SetValue(ValidEmailTxt);
        EmployeeCard."E-Mail".SetValue(ValidEmailTxt);
        EmployeeCard.OK().Invoke();

        // 3. Verify: That the E-Mail address was updated
        Employee.Get(Employee."No.");
        Employee.TestField("Company E-Mail", ValidEmailTxt);
        Employee.TestField("E-Mail", ValidEmailTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeEmailValidationTrimSpaces()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // Test Employee E-Mail and Company E-Mail validation

        // 1. Setup: Create and open Employee Card
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        Commit();

        EmployeeCard.OpenEdit();
        EmployeeCard.GotoRecord(Employee);

        // 2. Exercise: Set E-Mail address to contain spaces
        EmployeeCard."Company E-Mail".SetValue(' ');
        EmployeeCard."E-Mail".SetValue(StrSubstNo(' %1 ', ValidEmailTxt));
        EmployeeCard.OK().Invoke();

        // 3. Verify: That the E-Mail address was trimmed
        Employee.Get(Employee."No.");
        Employee.TestField("Company E-Mail", '');
        Employee.TestField("E-Mail", ValidEmailTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEditablePostCodePage()
    var
        PostCodes: TestPage "Post Codes";
    begin
        // Test Post Codes Page is non editable in View mode.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Open Post Codes Page in View mode.
        PostCodes.OpenView();

        // 3. Verify: Verify Post Codes Page is non editable.
        // As the fields are non editable so Pages is also non editable.
        Assert.IsFalse(PostCodes.Code.Editable(), StrSubstNo(EditableErr, PostCodes.Code.Caption));
        Assert.IsFalse(PostCodes.City.Editable(), StrSubstNo(EditableErr, PostCodes.City.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEditableCountryRegionPage()
    var
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // Test Country Region Page is non editable in View mode.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Open Country Region Page in View mode.
        CountriesRegions.OpenView();

        // 3. Verify: Verify Country Region Pages is non editable.
        // As the fields are non editable so Pages is also non editable.
        Assert.IsFalse(CountriesRegions.Code.Editable(), StrSubstNo(EditableErr, CountriesRegions.Code.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEditableCausesOfInactivityPage()
    var
        CausesofInactivity: TestPage "Causes of Inactivity";
    begin
        // Test Causes Of Inactivity Page is non editable in View mode.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Open Causes Of Inactivity Page in View mode.
        CausesofInactivity.OpenView();

        // 3. Verify: Verify Causes Of Inactivity Page is non editable.
        // As the fields are non editable so Page is also non editable.
        Assert.IsFalse(CausesofInactivity.Code.Editable(), StrSubstNo(EditableErr, CausesofInactivity.Code.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEditableUnionsPage()
    var
        Unions: TestPage Unions;
    begin
        // Test Unions Page is non editable in View mode.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Open Unions Page in View mode.
        Unions.OpenView();

        // 3. Verify: Verify Unions Page is non editable.
        // As the fields are non editable so Page is also non editable.
        Assert.IsFalse(Unions.Code.Editable(), StrSubstNo(EditableErr, Unions.Code.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HumanResSetupBaseUnitOfMeasureCorrectQtyOnValidate()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
        HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
        EmployeeAbsence: Record "Employee Absence";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
    begin
        // [SCENARIO 285567] Base Unit Of Measure changed and check for quantity is performed
        Initialize();

        // [GIVEN] Human Resources Setup - HRS
        HumanResourcesSetup.Get();
        // [GIVEN] "Human Resources Unit of Measure" - X with Qty.Per Unit of Measure = 1
        LibraryTimeSheet.CreateHRUnitOfMeasure(HumanResUnitOfMeasure, 1);
        // [GIVEN] Employee Absense is empty
        EmployeeAbsence.DeleteAll();

        // [WHEN] HRS "Base Unit of Measure" validated with X
        HumanResourcesSetup.Validate("Base Unit of Measure", HumanResUnitOfMeasure.Code);
        HumanResourcesSetup.Modify(true);

        // [THEN]  HRS "Base Unit of Measure" = X.Code
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Base Unit of Measure", HumanResUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HumanResSetupBaseUnitOfMeasureWrongQtyOnValidate()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
        HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
        EmployeeAbsence: Record "Employee Absence";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryRandom: Codeunit "Library - Random";
        BaseUnitOfMeasure: Code[20];
        QtyPerUnitOfMeasure: Integer;
    begin
        // [SCENARIO 285567] Base Unit Of Measure changed and check for quantity is performed
        Initialize();

        // [GIVEN] Human Resources Setup - HRS with "Base Unit of Measure" - Y
        HumanResourcesSetup.Get();
        BaseUnitOfMeasure := HumanResourcesSetup."Base Unit of Measure";
        // [GIVEN] "Human Resources Unit of Measure" - X with Qty.Per Unit of Measure <> 1
        QtyPerUnitOfMeasure := LibraryRandom.RandIntInRange(2, 10);
        LibraryTimeSheet.CreateHRUnitOfMeasure(HumanResUnitOfMeasure, QtyPerUnitOfMeasure);
        // [GIVEN] Employee Absense is empty
        EmployeeAbsence.DeleteAll();

        // [WHEN] HRS "Base Unit of Measure" validated with X
        asserterror HumanResourcesSetup.Validate("Base Unit of Measure", HumanResUnitOfMeasure.Code);
        Assert.ExpectedTestFieldError(HumanResUnitOfMeasure.FieldCaption("Qty. per Unit of Measure"), Format(1));

        // [THEN]  HRS "Base Unit of Measure" = Y
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Base Unit of Measure", BaseUnitOfMeasure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceUpdateOnEmployeeCountyModify()
    var
        Employee: Record Employee;
        Resource: Record Resource;
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 287807] County of the resource linked to employee is being updated on modify County of employee
        Initialize();

        // [GIVEN] Employee "E" with linked resource "R"
        LibraryHumanResource.CreateEmployee(Employee);
        Resource.Get(CreateResourceNoOfTypePerson());
        Employee.Validate("Resource No.", Resource."No.");
        Employee.Modify(true);

        // [WHEN] Employee "E" County is being changed to "COUNTY"
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmployeeCard.County.SetValue(
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo(County), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo(County))));
        EmployeeCard.OK().Invoke();

        // [THEN] Resource "R" has County = "COUNTY"
        Employee.Find();
        Resource.Find();
        Resource.TestField(County, Employee.County);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceUpdateOnEmployeeCityModify()
    var
        Employee: Record Employee;
        Resource: Record Resource;
        PostCode: Record "Post Code";
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 287807] City of the resource linked to employee is being updated on modify City of employee
        Initialize();

        // [GIVEN] Employee "E" with linked resource "R"
        LibraryHumanResource.CreateEmployee(Employee);
        Resource.Get(CreateResourceNoOfTypePerson());
        Employee.Validate("Resource No.", Resource."No.");
        Employee.Modify(true);

        // [WHEN] Employee "E" City is being changed to "S"
        LibraryERM.CreatePostCode(PostCode);
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmployeeCard.City.SetValue(PostCode.City);
        EmployeeCard.OK().Invoke();

        // [THEN] Resource "R" has City = "S"
        Employee.Find();
        Resource.Find();
        Resource.TestField(City, Employee.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceUpdateOnEmployeeCountryRegionModify()
    var
        CountryRegion: Record "Country/Region";
        Employee: Record Employee;
        Resource: Record Resource;
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 287807] "Country/Region Code" of the resource linked to employee is being updated on modify "Country/Region Code" of employee
        Initialize();

        // [GIVEN] Employee "E" with linked resource "R"
        LibraryHumanResource.CreateEmployee(Employee);
        Resource.Get(CreateResourceNoOfTypePerson());
        Employee.Validate("Resource No.", Resource."No.");
        Employee.Modify(true);

        // [WHEN] Employee "E" "Country/Region Code" is being changed to "CR"
        LibraryERM.CreateCountryRegion(CountryRegion);
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmployeeCard."Country/Region Code".SetValue(CountryRegion.Code);
        EmployeeCard.OK().Invoke();

        // [THEN] Resource "R" has "Country/Region Code" = "CR"
        Resource.Find();
        Resource.TestField("Country/Region Code", CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceUpdateEvents()
    var
        Employee: Record Employee;
        Resource: Record Resource;
        ResourceEmployee: Codeunit "Resource Employee";
        ExpectedResourceName: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 287807] It is possible to use events to extend Employee/Resource Update functionality
        Initialize();

        // [GIVEN] Employee "E" with linked resource "R"
        LibraryHumanResource.CreateEmployee(Employee);
        Resource.Get(CreateResourceNoOfTypePerson());
        Employee."Resource No." := Resource."No.";
        Employee.Modify();

        // [GIVEN] Bind subscription to OnAfterCalculateResourceUpdateNeeded to set "UpdateNeeded" = "Yes"
        // [GIVEN] Bind subscription to OnAfterUpdateResource to fill in resource Name field
        BindSubscription(ResourceEmployee);

        // [WHEN] OnModify for Employee is being run
        ExpectedResourceName :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Resource.Name), 0),
            1,
            MaxStrLen(ExpectedResourceName));
        // Put expected value into the buffer to let event sibscriber OnAfterUpdateResource read it and update Name field
        ResourceEmployee.SetValue(ExpectedResourceName);
        // Mock OnModify call
        Employee.Modify(true);

        // [THEN] Field Name or resource "R" is updated
        Resource.Find();
        Resource.TestField(Name, ExpectedResourceName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeValidateCityOnResourcePostCodeModify()
    var
        Resource: Record Resource;
        PostCode: Record "Post Code";
        ResourceNo: Code[20];
        CountryCode: Code[10];
        City, County : Text[30];
    begin
        // [SCENARIO 460016] In the Resource page, fields are not populated correctly, when the Post Code is inserted manually
        Initialize();

        // [GIVEN] Create Post Code and Resouce
        LibraryERM.CreatePostCode(PostCode);
        ResourceNo := CreateResourceNoOfTypePerson();

        // [WHEN] Update Post Code on Resource
        Resource.Get(ResourceNo);
        PostCode.ValidatePostCode(City, PostCode.Code, County, CountryCode, false);
        UpdateResourcePostCodeValidation(Resource, City, PostCode.Code, County, CountryCode);
        Resource.Modify(true);

        // [VERIFY] Verify City for Resource
        Resource.Find();
        Resource.TestField(City, PostCode.City);
    end;

    [Normal]
    local procedure Initialize()
    var
        EmployeeTempl: Record "Employee Templ.";
        OnlineMapSetup: Record "Online Map Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource Employee");
        EmployeeTempl.DeleteAll(true);

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource Employee");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryHumanResource.SetupEmployeeNumberSeries();
        LibraryHumanResource.FindEmployeePostingGroup();
        OnlineMapSetup.ModifyAll(Enabled, true);

        IsInitialized := true;
        Commit();
        Clear(EmployeeNoSeriesCode);  // Clear global variable.
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource Employee");
    end;

    local procedure UpdateResourcePostCodeValidation(var Resource: Record Resource; CityTxt: Text[30]; PostCode: Code[20]; CountyTxt: Text[30]; CountryCode: Code[10])
    begin
        Resource."Post Code" := PostCode;
        Resource.City := CityTxt;
        Resource.County := CountyTxt;
        Resource."Country/Region Code" := CountryCode;
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Employment Date" := WorkDate();
        Employee.Validate("Alt. Address Start Date", WorkDate());
        Employee.Modify(true);
    end;

    local procedure EditEmployeeAddress(Employee: Record Employee; Address: Text[50]; Address2: Text[50])
    begin
        Employee.Validate(Address, Address);
        Employee.Validate("Address 2", Address2);
        Employee.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalHandler(var NoSeriesList: TestPage "No. Series")
    var
        visible: Boolean;
    begin
        visible := NoSeriesList.Code.Visible();
        EmployeeNoSeriesCode := NoSeriesList.Code.Value();
    end;

    local procedure CreateResourceNoOfTypePerson(): Code[20]
    var
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate(Type, Resource.Type::Person);
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    [Scope('OnPrem')]
    procedure SetValue(NewTextValue: Text[100])
    begin
        TextValue := NewTextValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee/Resource Update", 'OnAfterUpdateResource', '', false, false)]
    local procedure OnAfterUpdateResource(var Resource: Record Resource)
    begin
        // Update resource Name for UT ResourceUpdateEvents
        Resource.Name := TextValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee/Resource Update", 'OnAfterCalculateResourceUpdateNeeded', '', false, false)]
    local procedure OnAfterCalculateResourceUpdateNeeded(Employee: Record Employee; xEmployee: Record Employee; var UpdateNeeded: Boolean)
    begin
        // Set update required for UT ResourceUpdateEvents
        UpdateNeeded := true;
    end;
}

