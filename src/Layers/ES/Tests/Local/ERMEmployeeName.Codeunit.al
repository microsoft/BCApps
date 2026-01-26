codeunit 144046 "ERM Employee Name"
{
    // 1. Test to verify Name field of the Employee Alternative Address is filled automatically with the First Family Name of the Employee.
    // 2. Test to verify First Family Name and Second Family Name Captions are available on Employee Relatives page.
    // 3. Test to verify Name, First Family Name and Second Family Name are available on Employee Card Caption.
    // 4. Test to verify Full Name on the Employee list page consist of Name, First Family Name and Second Family Name.
    // 
    // Covers Test Cases for WI - 351290
    // ---------------------------------------------------------------------------------
    // Test Function Name                                                         TFS ID
    // ---------------------------------------------------------------------------------
    // AlternativeAddressNameAsFirstFamilyNameOfEmployee                          151055
    // FamilyNameCaptionsOnEmployeeRelativesPage                                  151056
    // NamesAvailableOnEmployeeCardCaption,FullNameOnEmployeeListPage             151057

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        CaptionMustBeSameMsg: Label 'Caption must be same.';
        FirstFamilyNameCap: Label 'First Family Name';
        FullNameTxt: Label '%1 %2 %3';
        NameMustExistOnCaptionMsg: Label 'Name must exist on Caption.';
        SecondFamilyNameCap: Label 'Second Family Name';
        PictureTxt: Label 'Picture';
        ImagePathTxt: Label '\App\Test\Files\ImageAnalysis\AllowedImage.jpg';
        SecondFamilyNameMustBeBlankErr: Label 'Second Family Name must be blank.';

    [Test]
    [Scope('OnPrem')]
    procedure AlternativeAddressNameAsFirstFamilyNameOfEmployee()
    var
        AlternativeAddress: Record "Alternative Address";
        Employee: Record Employee;
    begin
        // Test to verify Name field of the Employee Alternative Address is filled automatically with the First Family Name of the Employee.

        // Setup.
        CreateEmployee(Employee);

        // Exercise.
        LibraryHumanResource.CreateAlternativeAddress(AlternativeAddress, Employee."No.");

        // Verify.
        AlternativeAddress.TestField(Name, Employee."First Family Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FamilyNameCaptionsOnEmployeeRelativesPage()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
        EmployeeRelatives: TestPage "Employee Relatives";
    begin
        // Test to verify First Family Name and Second Family Name Captions are available on Employee Relatives page.

        // Setup: Create Employee. Open Employee Card.
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmployeeRelatives.Trap();

        // Exercise.
        EmployeeCard."&Relatives".Invoke();

        // Verify.
        Assert.AreEqual(StrSubstNo(FirstFamilyNameCap), EmployeeRelatives."First Family Name".Caption, CaptionMustBeSameMsg);
        Assert.AreEqual(StrSubstNo(SecondFamilyNameCap), EmployeeRelatives."Second Family Name".Caption, CaptionMustBeSameMsg);
        EmployeeRelatives.Close();
        EmployeeCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NamesAvailableOnEmployeeCardCaption()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // Test to verify Name, First Family Name and Second Family Name are available on Employee Card Caption.

        // Setup.
        CreateEmployee(Employee);
        EmployeeCard.OpenEdit();

        // Exercise.
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");

        // Verify.
        Assert.IsTrue(StrPos(EmployeeCard.Caption, Employee.Name) > 0, NameMustExistOnCaptionMsg);
        Assert.IsTrue(StrPos(EmployeeCard.Caption, Employee."First Family Name") > 0, NameMustExistOnCaptionMsg);
        Assert.IsTrue(StrPos(EmployeeCard.Caption, Employee."Second Family Name") > 0, NameMustExistOnCaptionMsg);
        EmployeeCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullNameOnEmployee()
    var
        Employee: Record Employee;
    begin
        // Test to verify Full Name in Employee table consists of Name, First Family Name and Second Family Name.

        // Setup.
        CreateEmployee(Employee);

        // Exercise.
        Employee."First Family Name" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Employee."First Family Name")), 1, MaxStrLen(Employee."First Family Name"));

        // Verify.
        Assert.AreEqual(
          StrSubstNo(FullNameTxt, Employee.Name, Employee."First Family Name", Employee."Second Family Name"), Employee.FullName(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure BlankSecondFamilyNameShouldGiveNoErrorWhenImportEmployeePicture()
    var
        Employee: Record Employee;
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 487554] Wrong Testfield in ES version in EmployeePicture.Page.al which prevents users to import a picturerd 

        // [GIVEN] Create an Employee.
        LibraryHumanResource.CreateEmployee(Employee);

        // [GIVEN] Import a Picture of Employee.
        Employee.Image.ImportFile(GetImagePath(), PictureTxt);

        // [GIVEN] Validate Name, First Family Name & keep Second Family Name as blank.
        Employee.Validate(Name, LibraryUtility.GenerateGUID());
        Employee.Validate("First Family Name", LibraryUtility.GenerateGUID());
        Employee.Validate("Second Family Name", '');
        Employee.Modify();

        // [WHEN] Open Employee Card Page & run Import Picture action.
        EmployeeCard.OpenEdit();
        EmployeeCard.Filter.SetFilter("No.", Employee."No.");
        EmployeeCard.Control3.ImportPicture.Invoke();
        EmployeeCard.Close();

        // [VERIFY] Verify Second Family Name is blank.
        Assert.AreEqual('', Employee."Second Family Name", SecondFamilyNameMustBeBlankErr);

        // [GIVEN] Validate Name as blank, First Family Name & Second Family Name.
        Employee.Validate(Name, '');
        Employee.Validate("First Family Name", LibraryUtility.GenerateGUID());
        Employee.Validate("Second Family Name", LibraryUtility.GenerateGUID());
        Employee.Modify();

        // [WHEN] Open Employee Card Page & run Import Picture action.
        EmployeeCard.OpenEdit();
        EmployeeCard.Filter.SetFilter("No.", Employee."No.");

        // [VERIFY] Verify that Import Picture gives an error when Name is blank.
        asserterror EmployeeCard.Control3.ImportPicture.Invoke();
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate(Name, LibraryUtility.GenerateGUID());
        Employee.Validate("First Family Name", LibraryUtility.GenerateGUID());
        Employee.Validate("Second Family Name", LibraryUtility.GenerateGUID());
        Employee.Modify(true);
    end;

    local procedure GetImagePath(): Text
    var
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + ImagePathTxt);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

