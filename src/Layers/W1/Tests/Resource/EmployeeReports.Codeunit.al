codeunit 136903 "Employee Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Employee]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PostCodeCityTextErr: Label 'Wrong value of PostCodeCityText.';
        CountyTextErr: Label 'Wrong value of CountyText.';

    [Test]
    [HandlerFunctions('EmployeeRelativeReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeRelative()
    var
        Employee: Record Employee;
        EmployeeRelative: Record "Employee Relative";
        EmployeeRelatives: Report "Employee - Relatives";
    begin
        // Test that value of First Name and Birth Date in Employee - Relatives matches the value of First Name and Birth Date
        // in corresponding Employee Relative.

        // 1. Setup: Create Employee and Relative.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeRelative(EmployeeRelative, Employee."No.");

        // 2. Exercise: Generate the Employee - Relatives Report.
        Commit();
        Clear(EmployeeRelatives);
        EmployeeRelative.SetRange("Employee No.", EmployeeRelative."Employee No.");
        EmployeeRelatives.SetTableView(EmployeeRelative);
        EmployeeRelatives.Run();

        // 3. Verify: Test that value of First Name and Birth Date in Employee - Relatives matches the value of First Name and Birth Date
        // in corresponding Employee Relative Report.
        VerifyEmployeeRelative(EmployeeRelative);
    end;

    [Test]
    [HandlerFunctions('EmployeeConfidentialInfoReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeConfidentialInfo()
    var
        ConfidentialInformation: Record "Confidential Information";
        Employee: Record Employee;
        EmployeeConfidentialInfo: Report "Employee - Confidential Info.";
    begin
        // Test that value of Description in Employee - Confidential Info. matches the value of Description
        // in corresponding Confidential Information.

        // 1. Setup: Create Employee and Find Confidential.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryHumanResource.CreateConfidentialInformation(ConfidentialInformation, Employee."No.", FindConfidential());

        // 2. Exercise: Generate the Employee - Confidential Info. Report.
        Commit();
        Clear(EmployeeConfidentialInfo);
        ConfidentialInformation.SetRange("Employee No.", ConfidentialInformation."Employee No.");
        EmployeeConfidentialInfo.SetTableView(ConfidentialInformation);
        EmployeeConfidentialInfo.Run();

        // 3. Verify: Verify that value of Description in Employee - Confidential Info. matches the value of Description
        // in corresponding Confidential Information.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Confidential_Information__Confidential_Code_', ConfidentialInformation."Confidential Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the confidential code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Confidential_Information_Description', ConfidentialInformation.Description);
    end;

    [Test]
    [HandlerFunctions('EmployeeMiscellaneousArticleReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeMiscellaneousArticle()
    var
        Employee: Record Employee;
        MiscArticleInformation: Record "Misc. Article Information";
        EmployeeMiscArticleInfo: Report "Employee - Misc. Article Info.";
    begin
        // Test that value of Description and Serial No in Employee - Misc. Article Info. matches the value of Description
        // and Serial No in corresponding Misc. Article Information.

        // 1. Setup: Create Employee, Find Misc. Article and Modify Misc. Article Information.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        ModifyMiscellaneousArticle(MiscArticleInformation, Employee."No.");

        // 2. Exercise: Generate the Employee - Misc. Article Info. Report.
        Commit();
        Clear(EmployeeMiscArticleInfo);
        MiscArticleInformation.SetRange("Employee No.", MiscArticleInformation."Employee No.");
        EmployeeMiscArticleInfo.SetTableView(MiscArticleInformation);
        EmployeeMiscArticleInfo.Run();

        // 3. Verify: Verify that value of Description and Serial No in Employee - Misc. Article Info. matches the value of Description
        // and Serial No in corresponding Misc. Article Information.
        VerifyMiscellaneousArticle(MiscArticleInformation);
    end;

    [Test]
    [HandlerFunctions('EmployeeQualificationsArticleReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeQualifications()
    var
        EmployeeQualification: Record "Employee Qualification";
        Employee: Record Employee;
        EmployeeQualifications: Report "Employee - Qualifications";
    begin
        // Test that value of Description and From Date in Employee - Qualifications matches the value of Description
        // and From Date in corresponding Employee Qualification.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeQualifications(EmployeeQualification, Employee."No.");

        // 2. Exercise: Generate the Employee - Qualifications Report.
        Commit();
        Clear(EmployeeQualifications);
        EmployeeQualification.SetRange("Employee No.", EmployeeQualification."Employee No.");
        EmployeeQualifications.SetTableView(EmployeeQualification);
        EmployeeQualifications.Run();

        // 3. Verify: Verify that value of Description and From Date in Employee - Qualifications matches the value of Description
        // and From Date in corresponding Employee Qualification.
        VerifyEmployeeQualifications(EmployeeQualification);
    end;

    [Test]
    [HandlerFunctions('EmployeeContractsReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeContracts()
    var
        Employee: Record Employee;
        EmploymentContract: Record "Employment Contract";
        EmployeeContracts: Report "Employee - Contracts";
    begin
        // Test that the values of Code in Employee - Contracts Report must match in Corresponding Employment Contract Table values.

        // 1. Setup: Find Employment Contract and Modify Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        FindEmploymentContract(EmploymentContract);
        ModifyEmployeeContracts(Employee, EmploymentContract.Code);

        // 2. Exercise: Generate Employee - Contracts Report.
        Commit();
        Clear(EmployeeContracts);
        EmploymentContract.SetRange(Code, EmploymentContract.Code);
        EmployeeContracts.SetTableView(EmploymentContract);
        EmployeeContracts.Run();

        // 3. Verify: Verify that the values of Code in Employee - Contracts Report must match in Corresponding
        // Employment Contract Table values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employment_Contract_Code', EmploymentContract.Code);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract code');
    end;

    [Test]
    [HandlerFunctions('EmployeeUnionsReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeUnions()
    var
        Employee: Record Employee;
        Union: Record Union;
        EmployeeUnions: Report "Employee - Unions";
    begin
        // Test that the values of Code in Employee - Unions Report must match in Corresponding Employee Table values.

        // 1. Setup: Find Union and Modify Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryHumanResource.CreateUnion(Union);
        ModifyEmployeeUnions(Employee, Union.Code);

        // 2. Exercise: Generate Employee - Unions Report.
        Commit();
        Clear(EmployeeUnions);
        Union.SetRange(Code, Union.Code);
        EmployeeUnions.SetTableView(Union);
        EmployeeUnions.Run();

        // 3. Verify: Verify that the values of Code in Employee - Unions Report must match in Corresponding Employee Table values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Union_Code', Union.Code);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the union code');
    end;

    [Test]
    [HandlerFunctions('EmployeePhoneNosReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeePhoneNos()
    var
        Employee: Record Employee;
        EmployeePhoneNos: Report "Employee - Phone Nos.";
    begin
        // Test that the values of Phone No and Mobile Phone No in Employee - Phone Nos. Report must match in Corresponding
        // Employee Table values.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        ModifyEmployeePhoneNos(Employee);

        // 2. Exercise: Generate Employee - Phone Nos Report.
        Commit();
        Clear(EmployeePhoneNos);
        Employee.SetRange("No.", Employee."No.");
        EmployeePhoneNos.SetTableView(Employee);
        EmployeePhoneNos.Run();

        // 3. Verify: Verify that the values of Phone No and Mobile Phone No in Employee - Phone Nos. Report must match
        // in Corresponding Employee Table values.
        VerifyEmployeePhoneNos(Employee);
    end;

    [Test]
    [HandlerFunctions('EmployeeBirthdaysReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeBirthdays()
    var
        Employee: Record Employee;
        EmployeeBirthdays: Report "Employee - Birthdays";
    begin
        // Test that the values of Birth Date in Employee - Birthdays Report must match in Corresponding Employee Table values.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        AttachBirthDate(Employee);

        // 2. Exercise: Generate Employee - Birthdays Report.
        Commit();
        Clear(EmployeeBirthdays);
        Employee.SetRange("No.", Employee."No.");
        EmployeeBirthdays.SetTableView(Employee);
        EmployeeBirthdays.Run();

        // 3. Verify: Verify that the values of Birth Date in Employee - Birthdays Report must match in
        // Corresponding Employee Table values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee__No__', Employee."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Birth_Date_', Format(Employee."Birth Date"));
    end;

    [Test]
    [HandlerFunctions('EmployeeAddressesReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAddresses()
    var
        Employee: Record Employee;
        EmployeeAddresses: Report "Employee - Addresses";
    begin
        // Test that the values of Address in Employee - Addresses Report must match in Corresponding Employee Table values.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        AttachAddress(Employee);

        // 2. Exercise: Generate Employee - Addresses Report.
        Commit();
        Clear(EmployeeAddresses);
        Employee.SetRange("No.", Employee."No.");
        EmployeeAddresses.SetTableView(Employee);
        EmployeeAddresses.Run();

        // 3. Verify: Verify that the values of Address in Employee - Addresses Report must match in
        // Corresponding Employee Table values.
        VerifyEmployeeAddresses(Employee);
    end;

    [Test]
    [HandlerFunctions('EmployeeAlternativeAddressReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAlternativeAddress()
    var
        Employee: Record Employee;
        AlternativeAddress: Record "Alternative Address";
        EmployeeAltAddresses: Report "Employee - Alt. Addresses";
    begin
        // Test that the values of Alternative Address and Post Code in Employee - Alt. Addresses Report must match
        // in Corresponding Employee Table values.

        // 1. Setup: Create Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateAlternativeAddress(AlternativeAddress, Employee."No.");
        AttachAlternativeAddress(Employee, AlternativeAddress.Code);

        // 2. Exercise: Generate Employee - Alt. Addresses Report.
        Commit();
        Clear(EmployeeAltAddresses);
        Employee.SetRange("No.", Employee."No.");
        EmployeeAltAddresses.SetTableView(Employee);
        EmployeeAltAddresses.Run();

        // 3. Verify: Test that the values of Alternative Address and Post Code in Employee - Alt. Addresses Report must match
        // Corresponding Employee Table values.
        VerifyAlternativeAddress(Employee, AlternativeAddress);
    end;

    [Test]
    [HandlerFunctions('EmployeeListReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeList()
    var
        Employee: Record Employee;
        EmployeeList: Report "Employee - List";
    begin
        // Test that the values of Department Code and Statistics Group Code in Employee - List Report must
        // match in Corresponding Employee Table values.

        // 1. Setup: Create Employee.
        Initialize();
        CreateEmployeeList(Employee);

        // 2. Exercise: Generate Resource Journal - Test.
        Commit();
        Clear(EmployeeList);
        Employee.SetRange("No.", Employee."No.");
        EmployeeList.SetTableView(Employee);
        EmployeeList.Run();

        // 3. Verify: Verify that the values of Department Code and Statistics Group Code in Employee - List Report must
        // match in Corresponding Employee Table values.
        VerifyEmployee(Employee);
    end;

    [Test]
    [HandlerFunctions('EmployeeAbsencesByCausesReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAbsencesByCauses()
    var
        EmployeeAbsence: Record "Employee Absence";
        Employee: Record Employee;
        EmployeeAbsencesByCauses: Report "Employee - Absences by Causes";
        EmployeeNo: Code[20];
    begin
        // Test that the values of Employee No,To Date in Employee - Absences by Causes Report must
        // match in Corresponding Employee Absence Table values.

        // 1. Setup: Find Cause of Absence.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.", WorkDate());
        EmployeeNo := EmployeeAbsence."Employee No.";
        CreateEmployeeAbsence(EmployeeAbsence, EmployeeNo, CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));

        // 2. Exercise: Generate Employee - Absences by Causes Report.
        Commit();
        Clear(EmployeeAbsencesByCauses);
        EmployeeAbsence.SetRange("Employee No.", EmployeeAbsence."Employee No.");
        EmployeeAbsencesByCauses.SetTableView(EmployeeAbsence);
        EmployeeAbsencesByCauses.Run();

        // 3. Verify: Verify that the values of Employee No,To Date in Employee - Absences by Causes Report must
        // match in Corresponding Employee Absence Table values.
        VerifyEmployeeAbsencesByCauses(EmployeeAbsence);
    end;

    [Test]
    [HandlerFunctions('EmployeeStaffAbsencesReportHandler')]
    [Scope('OnPrem')]
    procedure EmployeeStaffAbsences()
    var
        EmployeeAbsence: Record "Employee Absence";
        Employee: Record Employee;
        EmployeeStaffAbsences: Report "Employee - Staff Absences";
    begin
        // Test that the values of Cause of Absence Code and Unit of Measure Code in Employee - Staff Absences Report must
        // match in Corresponding Employee Absence Table values.

        // 1. Setup: Find Cause of Absence.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.", WorkDate());

        // 2. Exercise: Generate Employee - Staff Absences Report.
        Commit();
        Clear(EmployeeStaffAbsences);
        EmployeeAbsence.SetRange("Employee No.", EmployeeAbsence."Employee No.");
        EmployeeStaffAbsences.SetTableView(EmployeeAbsence);
        EmployeeStaffAbsences.Run();

        // 3. Verify: Verify that the values of Cause of Absence Code and Unit of Measure Code in
        // Employee - Staff Absences Report must match in Corresponding Employee Absence Table values.
        VerifyEmployeeStaffAbsences(EmployeeAbsence);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryPostCodeCity()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and "Country/Region"."Address Format" = "Post Code+City"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "Post Code+City"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"Post Code+City");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, CountryRegion.Code);

        // [THEN] PostCodeCityText = '123456 Moscow'
        Assert.AreEqual(PostCode + ' ' + City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryPostCodeCityWithPostCodeIsBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and PostCode is blank, and "Country/Region"."Address Format" = "Post Code+City"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "Post Code+City"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"Post Code+City");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1" and PostCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityCountyPostCode()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and "Country/Region"."Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+County+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow, Moscowia 123456'
        Assert.AreEqual(
          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - StrLen(County) - 3) + ', ' + County + ' ' + PostCode,
          PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityCountyPostCodeWithPostCodeIsBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and PostCode is blank, and "Country/Region"."Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+County+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1" and PostCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityCountyPostCodeWithCountyIsBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        PostCode: Code[20];
        City: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and County is blank, and "Country/Region"."Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+County+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = ''

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1" and County = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, '', CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow, 123456'
        Assert.AreEqual(
          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityCountyPostCodeWithPostCodeAndCountyAreBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and PostCode and County are blank, and "Country/Region"."Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+County+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = ''

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1" and PostCode = '' and County = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', '', CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityPostCode()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and "Country/Region"."Address Format" = "City+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow, 123456'
        Assert.AreEqual(City + ', ' + PostCode, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryCityPostCodeWithPostCodeIsBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and PostCode = '', and "Country/Region"."Address Format" = "City+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+Post Code"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"City+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryBlankLinePostCodeCity()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and "Country/Region"."Address Format" = "Blank Line+Post Code+City"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "Blank Line+Post Code+City"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"Blank Line+Post Code+City");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, CountryRegion.Code);

        // [THEN] PostCodeCityText = '123456 Moscow'
        Assert.AreEqual(PostCode + ' ' + City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressCountryBlankLinePostCodeCityWithPostCodeIsBlank()
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country <> '', and PostCode = '', and "Country/Region"."Address Format" = "Blank Line+Post Code+City"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "Blank Line+Post Code+City"
        CreateCountryRegionWithAddressFormat(CountryRegion, CountryRegion."Address Format"::"Blank Line+Post Code+City");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = "CR1"
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, CountryRegion.Code);

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupPostCodeCity()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and "General Ledger Setup"."Local Address Format" = "Post Code+City"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "Post Code+City"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"Post Code+City");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, '');

        // [THEN] PostCodeCityText = '123456 Moscow'
        Assert.AreEqual(PostCode + ' ' + City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupPostCodeCityWithPostCodeIsBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and PostCode is blank, and "General Ledger Setup"."Local Address Format" = "Post Code+City"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "Post Code+City"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"Post Code+City");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = '' and PostCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, '');

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityCountyPostCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and "General Ledger Setup"."Local Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] "General Ledger Setup" "Local Address Format" = "City+County+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, '');

        // [THEN] PostCodeCityText = 'Moscow, Moscowia 123456'
        Assert.AreEqual(
          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - StrLen(County) - 3) + ', ' + County + ' ' + PostCode,
          PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityCountyPostCodeWithPostCodeIsBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and PostCode is blank, and "General Ledger Setup"."Local Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "City+County+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = '' and PostCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, '');

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityCountyPostCodeWithCountyIsBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        PostCode: Code[20];
        City: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and County is blank, and "General Ledger Setup"."Local Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "City+County+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = ''

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = '' and County = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, '', '');

        // [THEN] PostCodeCityText = 'Moscow, 123456'
        Assert.AreEqual(
          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityCountyPostCodeWithPostCodeAndCountyAreBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and PostCode and County are blank, and "General Ledger Setup"."Local Address Format" = "City+County+Post Code"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "City+County+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+County+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = ''

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = '' and PostCode = '' and County = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', '', '');

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = ''
        Assert.AreEqual('', CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityPostCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and "General Ledger Setup"."Local Address Format" = "City+Post Code"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "City+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+Post Code");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, '');

        // [THEN] PostCodeCityText = 'Moscow, 123456'
        Assert.AreEqual(City + ', ' + PostCode, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupCityPostCodeWithPostCodeIsBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and PostCode = '', and "General Ledger Setup"."Local Address Format" = "City+Post Code"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "City+Post Code"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"City+Post Code");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, '');

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupBlankLinePostCodeCity()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and "General Ledger Setup"."Local Address Format" = "Blank Line+Post Code+City"
        Initialize();

        // [GIVEN] Record "Country/Region" with Code = "CR1" and "Address Format" = "Blank Line+Post Code+City"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"Blank Line+Post Code+City");

        // [GIVEN] "Post Code" = '123456'
        PostCode := LibraryUtility.GenerateGUID();

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, '');

        // [THEN] PostCodeCityText = '123456 Moscow'
        Assert.AreEqual(PostCode + ' ' + City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CheckFormatAddressGLSetupBlankLinePostCodeCityWithPostCodeIsBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PostCodeCityText: Text[90];
        CountyText: Text[50];
        City: Text[50];
        County: Text[50];
    begin
        // [FEATURE] [UT] [Format Address]
        // [SCENARIO 212227] FormatPostCodeCity returns correct Address if Country = '', and PostCode = '', and "General Ledger Setup"."Local Address Format" = "Blank Line+Post Code+City"
        Initialize();

        // [GIVEN] "General Ledger Setup" with "Local Address Format" = "Blank Line+Post Code+City"
        UpdateGLSetupAddressFormat(GeneralLedgerSetup."Local Address Format"::"Blank Line+Post Code+City");

        // [GIVEN] "Post Code" = ''

        // [GIVEN] "City" = 'Moscow'
        City := LibraryUtility.GenerateGUID();

        // [GIVEN] "County" = 'Moscowia'
        County := LibraryUtility.GenerateGUID();

        // [WHEN] Invoike FormatPostCodeCity of "Format Address" (codeunit 365) with CountryCode = ''
        FormatAddress.FormatPostCodeCity(PostCodeCityText, CountyText, City, '', County, '');

        // [THEN] PostCodeCityText = 'Moscow'
        Assert.AreEqual(City, PostCodeCityText, PostCodeCityTextErr);

        // [THEN] CountyText = 'Moscowia'
        Assert.AreEqual(County, CountyText, CountyTextErr);
    end;

    [Test]
    [HandlerFunctions('EmployeeAbsencesByCausesToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAbsenceByCauseTotalAbsence()
    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        CauseOfAbsence: Record "Cause of Absence";
        CauseOfAbsenceDescription: array[3] of Text[100];
        TotalAbsence: array[3] of Decimal;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 352774] Total Absence calcualtion for groups of "Cause of Absence" of "Employee - Absences by Causes" report.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Employee. Three Causes of Absence, each one have several "Employee Absence".
        LibraryHumanResource.CreateEmployee(Employee);

        for i := 1 to ArrayLen(TotalAbsence) do begin
            LibraryTimeSheet.CreateCauseOfAbsence(CauseOfAbsence);
            CauseOfAbsenceDescription[i] := CauseOfAbsence.Description;
            for j := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
                CreateEmployeeAbsenceWithCause(EmployeeAbsence, Employee."No.", LibraryRandom.RandDate(50), CauseOfAbsence.Code);
                TotalAbsence[i] += EmployeeAbsence."Quantity (Base)";
            end;
        end;
        Commit();

        // [WHEN] Run report "Employee - Absences by Causes" for Employee.
        EmployeeAbsence.SetRange("Employee No.", Employee."No.");
        Report.Run(Report::"Employee - Absences by Causes", true, false, EmployeeAbsence);

        // [THEN] Total Absence for each "Cause of Absence" is equal to summ of "Quantity (Base)" of corresponding "Employee Absence" records.
        VerifyTotalAbsenceEmployeeAbsencesByCauses(CauseOfAbsenceDescription, TotalAbsence);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Employee Reports");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Employee Reports");

        LibraryService.SetupServiceMgtNoSeries();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Employee Reports");
    end;

    local procedure AttachAddress(var Employee: Record Employee)
    var
        PostCode: Record "Post Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Using Random Values for Address, Value is not important for test.
        LibraryERM.CreatePostCode(PostCode);
        Employee.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo(Address), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo(Address))));
        Employee.Validate("Country/Region Code", PostCode."Country/Region Code");
        Employee.Validate("Post Code", PostCode.Code);
        Employee.Modify(true);
    end;

    local procedure AttachAlternativeAddress(Employee: Record Employee; AltAddressCode: Code[10])
    begin
        // Use TODAY instead of WORKDATE because original code uses TODAY.
        Employee.Validate("Alt. Address Code", AltAddressCode);
        Employee.Validate("Alt. Address Start Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', Today));
        Employee.Validate("Alt. Address End Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', Today));
        Employee.Modify(true);
    end;

    local procedure AttachBirthDate(var Employee: Record Employee)
    begin
        Employee.Validate("Birth Date", WorkDate());
        Employee.Modify(true);
    end;

    local procedure CreateAlternativeAddress(var AlternativeAddress: Record "Alternative Address"; EmployeeNo: Code[20])
    var
        PostCode: Record "Post Code";
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        LibraryERM.CreatePostCode(PostCode);  // Creation of Post Code is required to avoid special characters in existing ones.

        LibraryHumanResource.CreateAlternativeAddress(AlternativeAddress, EmployeeNo);
        AlternativeAddress.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(AlternativeAddress.FieldNo(Address), DATABASE::"Alternative Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Alternative Address", AlternativeAddress.FieldNo(Address))));
        AlternativeAddress.Validate("Country/Region Code", PostCode."Country/Region Code");
        AlternativeAddress.Validate("Post Code", PostCode.Code);
        AlternativeAddress.Modify(true);
    end;

    local procedure CreateEmployeeAbsence(var EmployeeAbsence: Record "Employee Absence"; EmployeeNo: Code[20]; FromDate: Date)
    var
        CauseOfAbsence: Record "Cause of Absence";
    begin
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        CreateEmployeeAbsenceWithCause(EmployeeAbsence, EmployeeNo, FromDate, CauseOfAbsence.Code);
    end;

    local procedure CreateEmployeeAbsenceWithCause(var EmployeeAbsence: Record "Employee Absence"; EmployeeNo: Code[20]; FromDate: Date; CauseOfAbsenceCode: Code[10])
    begin
        LibraryHumanResource.CreateEmployeeAbsence(EmployeeAbsence);
        EmployeeAbsence.Validate("Employee No.", EmployeeNo);
        EmployeeAbsence.Validate("From Date", FromDate);
        EmployeeAbsence.Validate("To Date", FromDate);
        EmployeeAbsence.Validate("Cause of Absence Code", CauseOfAbsenceCode);
        EmployeeAbsence.Validate(Quantity, LibraryRandom.RandDecInRange(100, 200, 2));
        EmployeeAbsence.Modify(true);
    end;

    local procedure CreateEmployeeQualifications(var EmployeeQualification: Record "Employee Qualification"; EmployeeNo: Code[20])
    begin
        LibraryHumanResource.CreateEmployeeQualification(EmployeeQualification, EmployeeNo);
        EmployeeQualification.Validate("Qualification Code", FindQualification());
        EmployeeQualification.Validate("From Date", WorkDate());
        EmployeeQualification.Validate("To Date", WorkDate());
        EmployeeQualification.Validate(Type, EmployeeQualification.Type::Internal);
        EmployeeQualification.Validate(
          "Institution/Company",
          CopyStr(
            LibraryUtility.GenerateRandomCode(EmployeeQualification.FieldNo("Institution/Company"), DATABASE::"Employee Qualification"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Employee Qualification", EmployeeQualification.FieldNo("Institution/Company"))));

        EmployeeQualification.Modify(true);
    end;

    local procedure CreateEmployeeRelative(var EmployeeRelative: Record "Employee Relative"; EmployeeNo: Code[20])
    begin
        LibraryHumanResource.CreateEmployeeRelative(EmployeeRelative, EmployeeNo);
        EmployeeRelative.Validate("Relative Code", FindRelative());
        EmployeeRelative.Validate("First Name", FindRelative());
        EmployeeRelative.Validate("Birth Date", WorkDate());
        EmployeeRelative.Modify(true);
    end;

    local procedure CreateEmployeeList(var Employee: Record Employee)
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PostCode: Record "Post Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreatePostCode(PostCode);
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.FindFirst();
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Global Dimension 1 Code", DimensionValue.Code);
        Employee.Validate("Statistics Group Code", FindEmployeeStatisticsGroup());
        Employee.Validate("Country/Region Code", PostCode."Country/Region Code");
        Employee.Validate("Post Code", PostCode.Code);
        Employee.Validate("Employment Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'Y>'));
        Employee.Modify(true);
    end;

    local procedure CreateCountryRegionWithAddressFormat(var CountryRegion: Record "Country/Region"; AddressFormat: Enum "Country/Region Address Format")
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region");
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
    end;

    local procedure UpdateGLSetupAddressFormat(AddressFormat: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Local Address Format" := AddressFormat;
        GeneralLedgerSetup.Modify();
    end;

    local procedure FindRelative(): Code[10]
    var
        Relative: Record Relative;
    begin
        LibraryHumanResource.CreateRelative(Relative);
        exit(Relative.Code);
    end;

    local procedure FindMiscellaneousArticle(): Code[10]
    var
        MiscArticle: Record "Misc. Article";
    begin
        LibraryHumanResource.CreateMiscArticle(MiscArticle);
        exit(MiscArticle.Code);
    end;

    local procedure FindConfidential(): Code[10]
    var
        Confidential: Record Confidential;
    begin
        LibraryHumanResource.CreateConfidential(Confidential);
        exit(Confidential.Code);
    end;

    local procedure FindEmploymentContract(var EmploymentContract: Record "Employment Contract")
    begin
        LibraryHumanResource.CreateEmploymentContract(EmploymentContract);
    end;

    local procedure FindEmployeeStatisticsGroup(): Code[10]
    var
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
    begin
        LibraryHumanResource.CreateEmployeeStatGroup(EmployeeStatisticsGroup);
        exit(EmployeeStatisticsGroup.Code);
    end;

    local procedure FindQualification(): Code[10]
    var
        Qualification: Record Qualification;
    begin
        LibraryHumanResource.CreateQualification(Qualification);
        exit(Qualification.Code);
    end;

    local procedure ModifyMiscellaneousArticle(var MiscArticleInformation: Record "Misc. Article Information"; EmployeeNo: Code[20])
    begin
        LibraryHumanResource.CreateMiscArticleInformation(MiscArticleInformation, EmployeeNo, FindMiscellaneousArticle());
        MiscArticleInformation.Validate(
          "Serial No.",
          LibraryUtility.GenerateRandomCode(MiscArticleInformation.FieldNo("Serial No."), DATABASE::"Misc. Article Information"));
        MiscArticleInformation.Modify(true);
    end;

    local procedure ModifyEmployeeUnions(var Employee: Record Employee; UnionCode: Code[10])
    begin
        Employee.Validate("Union Code", UnionCode);
        Employee.Modify(true);
    end;

    local procedure ModifyEmployeeContracts(var Employee: Record Employee; EmplymtContractCode: Code[10])
    begin
        Employee.Validate("Emplymt. Contract Code", EmplymtContractCode);
        Employee.Modify(true);
    end;

    local procedure ModifyEmployeePhoneNos(var Employee: Record Employee)
    begin
        Employee.Validate(
          "Phone No.",
          Format(LibraryRandom.RandInt(100) + LibraryRandom.RandInt(100) + LibraryRandom.RandInt(100)));
        Employee.Validate(
          "Mobile Phone No.",
          Format(LibraryRandom.RandInt(100) + LibraryRandom.RandInt(100) + LibraryRandom.RandInt(100)));
        Employee.Modify(true);
    end;

    local procedure VerifyAlternativeAddress(Employee: Record Employee; AlternativeAddress: Record "Alternative Address")
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee__No__', Employee."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('AlternativeAddr_Address', AlternativeAddress.Address);

        CountryRegion.Get(AlternativeAddress."Country/Region Code");
        FormatAddress.FormatPostCodeCity(
          PostCodeCity, County, AlternativeAddress.City, AlternativeAddress."Post Code", AlternativeAddress.County, CountryRegion.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostCodeCityText', PostCodeCity);
    end;

    local procedure VerifyEmployee(Employee: Record Employee)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee__No__', Employee."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Global_Dimension_1_Code_', Employee."Global Dimension 1 Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Global_Dimension_2_Code_', Employee."Global Dimension 2 Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Statistics_Group_Code_', Employee."Statistics Group Code");
    end;

    local procedure VerifyEmployeeAddresses(Employee: Record Employee)
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee__No__', Employee."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Address', Employee.Address);

        CountryRegion.Get(Employee."Country/Region Code");
        FormatAddress.FormatPostCodeCity(
          PostCodeCity, County, Employee.City, Employee."Post Code", Employee.County, CountryRegion.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostCodeCityText', PostCodeCity);
    end;

    local procedure VerifyEmployeeAbsencesByCauses(EmployeeAbsence: Record "Employee Absence")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee_Absence__Employee_No__', EmployeeAbsence."Employee No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Absence__Quantity__Base__', EmployeeAbsence."Quantity (Base)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Absence__From_Date_', Format(EmployeeAbsence."From Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Absence__To_Date_', Format(EmployeeAbsence."To Date"));
    end;

    local procedure VerifyEmployeePhoneNos(Employee: Record Employee)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee__No__', Employee."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Mobile_Phone_No__', Employee."Mobile Phone No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee__Phone_No__', Employee."Phone No.");
    end;

    local procedure VerifyMiscellaneousArticle(MiscArticleInformation: Record "Misc. Article Information")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Misc__Article_Information__Misc__Article_Code_', MiscArticleInformation."Misc. Article Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the confidential code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Misc__Article_Information_Description', MiscArticleInformation.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Misc__Article_Information__Serial_No__', MiscArticleInformation."Serial No.");
    end;

    local procedure VerifyEmployeeQualifications(EmployeeQualification: Record "Employee Qualification")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee_Qualification__Qualification_Code_', EmployeeQualification."Qualification Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the confidential code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Qualification_Description', EmployeeQualification.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Qualification__From_Date_', Format(EmployeeQualification."From Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Qualification__Institution_Company_',
          EmployeeQualification."Institution/Company");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Qualification__To_Date_', Format(EmployeeQualification."To Date"));
    end;

    local procedure VerifyEmployeeRelative(EmployeeRelative: Record "Employee Relative")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee_Relative__Relative_Code_', EmployeeRelative."Relative Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the relative code');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Relative__First_Name_', EmployeeRelative."First Name");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Relative__Birth_Date_', Format(EmployeeRelative."Birth Date"));
    end;

    local procedure VerifyEmployeeStaffAbsences(EmployeeAbsence: Record "Employee Absence")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Employee_Absence__Employee_No__', EmployeeAbsence."Employee No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the employee no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Absence__From_Date_', Format(EmployeeAbsence."From Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Employee_Absence__Cause_of_Absence_Code_', EmployeeAbsence."Cause of Absence Code");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Employee_Absence__Unit_of_Measure_Code_', EmployeeAbsence."Unit of Measure Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Employee_Absence_Quantity', EmployeeAbsence.Quantity);
    end;

    local procedure VerifyTotalAbsenceEmployeeAbsencesByCauses(CauseOfAbsenceDescription: array[3] of Text[100]; TotalAbsence: array[3] of Decimal)
    var
        RowNo: Integer;
        ColumnNo: Integer;
        i: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();

        for i := 1 to ArrayLen(TotalAbsence) do begin
            LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(CauseOfAbsenceDescription[i], 1, RowNo, ColumnNo);
            RowNo :=
              LibraryReportValidation.FindRowNoFromColumnNoAndValueInsideArea(
                ColumnNo, CauseOfAbsenceDescription[i], StrSubstNo('>%1', Format(RowNo)));
            ColumnNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Base Unit of Measure');
            LibraryReportValidation.VerifyCellValue(RowNo, ColumnNo, LibraryReportValidation.FormatDecimalValue(TotalAbsence[i]));
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeRelativeReportHandler(var EmployeeRelatives: TestRequestPage "Employee - Relatives")
    begin
        EmployeeRelatives.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeConfidentialInfoReportHandler(var EmployeeConfidentialInfo: TestRequestPage "Employee - Confidential Info.")
    begin
        EmployeeConfidentialInfo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeMiscellaneousArticleReportHandler(var EmployeeMiscArticleInfo: TestRequestPage "Employee - Misc. Article Info.")
    begin
        EmployeeMiscArticleInfo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeQualificationsArticleReportHandler(var EmployeeQualifications: TestRequestPage "Employee - Qualifications")
    begin
        EmployeeQualifications.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeContractsReportHandler(var EmployeeContracts: TestRequestPage "Employee - Contracts")
    begin
        EmployeeContracts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeUnionsReportHandler(var EmployeeUnions: TestRequestPage "Employee - Unions")
    begin
        EmployeeUnions.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeePhoneNosReportHandler(var EmployeePhoneNos: TestRequestPage "Employee - Phone Nos.")
    begin
        EmployeePhoneNos.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeBirthdaysReportHandler(var EmployeeBirthdays: TestRequestPage "Employee - Birthdays")
    begin
        EmployeeBirthdays.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeAddressesReportHandler(var EmployeeAddresses: TestRequestPage "Employee - Addresses")
    begin
        EmployeeAddresses.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeAlternativeAddressReportHandler(var EmployeeAltAddresses: TestRequestPage "Employee - Alt. Addresses")
    begin
        EmployeeAltAddresses.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeListReportHandler(var EmployeeList: TestRequestPage "Employee - List")
    begin
        EmployeeList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeAbsencesByCausesReportHandler(var EmployeeAbsencesbyCauses: TestRequestPage "Employee - Absences by Causes")
    begin
        EmployeeAbsencesbyCauses.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeStaffAbsencesReportHandler(var EmployeeStaffAbsences: TestRequestPage "Employee - Staff Absences")
    begin
        EmployeeStaffAbsences.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeAbsencesByCausesToExcelRequestPageHandler(var EmployeeAbsencesByCauses: TestRequestPage "Employee - Absences by Causes")
    begin
        EmployeeAbsencesByCauses.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

