codeunit 136404 "Resource Matrix Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource]
        IsInitialized := false;
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        TestValidationTxt: Label 'TestValidation';
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        ValueType: Option "Net Change","Balance at Date";

    [Test]
    [HandlerFunctions('AbsencesByCategoriesMatrix')]
    [Scope('OnPrem')]
    procedure AbsencesByCategories()
    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        EmployeeCard: TestPage "Employee Card";
        EmplAbsencesByCategories: TestPage "Empl. Absences by Categories";
    begin
        // Test Employee Absences by Category Matrix after creation of Employee Absence for Employee.

        // 1. Setup: Create Employee and Employee Absence for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.");
        LibraryVariableStorage.Enqueue(EmployeeAbsence."Quantity (Base)");  // Assign variable for page handler.

        // 2. Exercise: Run Employee Absences By Categories page from Employee card page and run Show Matrix from it.
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmplAbsencesByCategories.Trap();
        EmployeeCard."Absences by Ca&tegories".Invoke();
        Commit();
        EmplAbsencesByCategories.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Employee Absences by Category Matrix performed on Employee Absences by Category Matrix page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeAbsences()
    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        EmployeeCard: TestPage "Employee Card";
        EmployeeAbsences: TestPage "Employee Absences";
    begin
        // Test values on Employee Absences page after creation of Employee Absence for Employee.

        // 1. Setup: Create Employee and Employee Absence for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.");

        // 2. Exercise: Run Employee Absences page from Employee card page.
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        EmployeeAbsences.Trap();
        EmployeeCard."A&bsences".Invoke();

        // 3. Verify: Verify values on Employee Absences page.
        EmployeeAbsences."Employee No.".AssertEquals(EmployeeAbsence."Employee No.");
        EmployeeAbsences."From Date".AssertEquals(EmployeeAbsence."From Date");
        EmployeeAbsences."Cause of Absence Code".AssertEquals(EmployeeAbsence."Cause of Absence Code");
        EmployeeAbsences.Quantity.AssertEquals(EmployeeAbsence.Quantity);
    end;

    [Test]
    [HandlerFunctions('ArticlesOverviewMatrixHandler')]
    [Scope('OnPrem')]
    procedure MiscellaneousOverview()
    var
        Employee: Record Employee;
        MiscArticle: Record "Misc. Article";
        MiscArticleInformation: Record "Misc. Article Information";
        EmployeeCard: TestPage "Employee Card";
        MiscArticlesOverview: TestPage "Misc. Articles Overview";
    begin
        // Test Miscellaneous Articles Overview Matrix after creation of Miscellaneous Article Information for Employee.

        // 1. Setup: Create Employee and Miscellaneous Article Information for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        MiscArticle.FindFirst();
        LibraryHumanResource.CreateMiscArticleInformation(MiscArticleInformation, Employee."No.", MiscArticle.Code);
        LibraryVariableStorage.Enqueue(Employee."No.");  // Assign variable for page handler.

        // 2. Exercise: Run Miscellaneous Articles Overview page from Employee card page and run Show Matrix from it.
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        MiscArticlesOverview.Trap();
        EmployeeCard."Misc. Articles &Overview".Invoke();
        Commit();
        MiscArticlesOverview.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Miscellaneous Articles Overview Matrix performed on Miscellaneous Articles Overview Matrix
        // page handler.
    end;

    [Test]
    [HandlerFunctions('ConfidentialOverviewMatrix')]
    [Scope('OnPrem')]
    procedure ConfidentialOverview()
    var
        Employee: Record Employee;
        Confidential: Record Confidential;
        ConfidentialInformation: Record "Confidential Information";
        EmployeeCard: TestPage "Employee Card";
        ConfidentialInfoOverview: TestPage "Confidential Info. Overview";
    begin
        // Test Confidential Information Overview Matrix after creation of Confidential Information for Employee.

        // 1. Setup: Create Employee and Confidential Information for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        Confidential.FindFirst();
        LibraryHumanResource.CreateConfidentialInformation(ConfidentialInformation, Employee."No.", Confidential.Code);
        LibraryVariableStorage.Enqueue(Employee."No.");  // Assign variable for page handler.

        // 2. Exercise: Run Confidential Information Overview page from Employee card page and run Show Matrix from it.
        EmployeeCard.OpenEdit();
        EmployeeCard.FILTER.SetFilter("No.", Employee."No.");
        ConfidentialInfoOverview.Trap();
        EmployeeCard."Co&nfidential Info. Overview".Invoke();
        Commit();
        ConfidentialInfoOverview.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Confidential Information Overview Matrix performed on Confidential Information Overview Matrix
        // page handler.
    end;

    [Test]
    [HandlerFunctions('AbsenceOverviewByPeriodMatrix')]
    [Scope('OnPrem')]
    procedure AbsenceByPeriod()
    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        AbsenceRegistration: TestPage "Absence Registration";
        AbsenceOverviewByPeriods: TestPage "Absence Overview by Periods";
    begin
        // Test Absence Overview by Period Matrix after creation of Employee Absence for Employee.

        // 1. Setup: Create Employee and Employee Absence for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.");

        // Assign global variables for page handler.
        LibraryVariableStorage.Enqueue(Employee."No.");
        LibraryVariableStorage.Enqueue(EmployeeAbsence."Quantity (Base)");

        // 2. Exercise: Run Absence Overview by Periods page from Absence Registration page and run Show Matrix from it with
        // Cause Of Absence filter.
        AbsenceRegistration.OpenEdit();
        AbsenceRegistration.FILTER.SetFilter("Employee No.", Employee."No.");
        AbsenceOverviewByPeriods.Trap();
        AbsenceRegistration."Overview by &Periods".Invoke();
        Commit();
        AbsenceOverviewByPeriods."Cause Of Absence Filter".SetValue(EmployeeAbsence."Cause of Absence Code");
        AbsenceOverviewByPeriods.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Absence Overview by Period Matrix performed on Absence Overview by Period Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('QualificationOverviewMatrix')]
    [Scope('OnPrem')]
    procedure QualificationOverview()
    var
        Employee: Record Employee;
        EmployeeQualifications: TestPage "Employee Qualifications";
        QualificationOverview: TestPage "Qualification Overview";
        QualificationCode: Code[10];
    begin
        // Test Qualification Overview Matrix after creation of Employee Qualifications for Employee.

        // 1. Setup: Create Employee and Employee Qualification for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        QualificationCode := CreateEmployeeQualification(Employee."No.");
        LibraryVariableStorage.Enqueue(Employee."No.");  // Assign variable for page handler.

        // 2. Exercise: Run Qualification Overview page from Employee Qualifications page and run Show Matrix from it.
        EmployeeQualifications.OpenEdit();
        EmployeeQualifications.FILTER.SetFilter("Qualification Code", QualificationCode);
        QualificationOverview.Trap();
        EmployeeQualifications."Q&ualification Overview".Invoke();
        Commit();
        QualificationOverview.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Qualification Overview Matrix performed on Qualification Overview Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('AbsenceOverviewByMatrixHandler')]
    [Scope('OnPrem')]
    procedure AbsenceOverview()
    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        AbsenceRegistration: TestPage "Absence Registration";
        AbsenceOverviewByCategories: TestPage "Absence Overview by Categories";
    begin
        // Test Absence Overview by Category Matrix after creation of Employee Absence for Employee.

        // 1. Setup: Create Employee and Employee Absence for the Employee.
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        CreateEmployeeAbsence(EmployeeAbsence, Employee."No.");
        LibraryVariableStorage.Enqueue(EmployeeAbsence."Quantity (Base)");  // Assign variable for page handler.

        // 2. Exercise: Run Absence Overview By Categories page from Absence Registration page and run Show Matrix from it with
        // Employee No. filter.
        AbsenceRegistration.OpenEdit();
        AbsenceRegistration.FILTER.SetFilter("Employee No.", Employee."No.");
        AbsenceOverviewByCategories.Trap();
        AbsenceRegistration."Overview by &Categories".Invoke();
        Commit();
        AbsenceOverviewByCategories.EmployeeNoFilter.SetValue(Employee."No.");
        AbsenceOverviewByCategories.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Absence Overview by Category Matrix performed on Absence Overview by Category Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ResourceAllocatedPerJobMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceAllocatedPerJob()
    var
        Resource: Record Resource;
        ResourceCard: TestPage "Resource Card";
        ResourceAllocatedPerJob: TestPage "Resource Allocated per Job";
    begin
        // Test the Resource Allocated Per Job Matrix after Resource allocation per Job from Resource Card.

        // 1. Setup: Find VAT Posting Setup, create Resource, create Job Planning Line.
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        CreateJobPlanningLine(Resource."No.");

        // 2. Exercise: Run Resource Allocated per Job page from Resource Card.
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", Resource."No.");
        ResourceAllocatedPerJob.Trap();
        ResourceCard."Resource &Allocated per Job".Invoke();
        Commit();
        ResourceAllocatedPerJob.ShowMatrix.Invoke();

        // 3. Verify: Verify the value on Resource Allocated Per Job Matrix in Resource Allocated Per Job Matrix Handler.
    end;

    [Test]
    [HandlerFunctions('ResourceGroupAllocatedPerJobMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceGroupAllocatedPerJob()
    var
        ResourceGroup: Record "Resource Group";
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
        ResourceGroups: TestPage "Resource Groups";
        ResGrAllocatedPerJob: TestPage "Res. Gr. Allocated per Job";
    begin
        // Test Resource Group Allocated Per Job Matrix after Resource Group allocation per Job from Resource Group Card.

        // 1. Setup: Create Resource Group, create Resource with Resource Group, create Job Planning Line.
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        CreateResourceWithResourceGroup(Resource, ResourceGroup."No.");
        CreateJobPlanningLine(Resource."No.");

        // 2. Exercise: Run Resource Group Allocated per Job page from Resource Group Card.
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", ResourceGroup."No.");
        ResGrAllocatedPerJob.Trap();
        ResourceGroups."Res. Group All&ocated per Job".Invoke();
        Commit();
        ResGrAllocatedPerJob.ShowMatrix.Invoke();

        // 3. Verify: Verify the value on Resource Group Allocated Per Job Matrix in Resource Group Allocated Per Job Matrix Handler.
    end;

    [Test]
    [HandlerFunctions('ResourceAllocatedPerServiceOrderMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceAllocatedPerServiceOrder()
    var
        Resource: Record Resource;
        ServiceItem: Record "Service Item";
        ResourceCard: TestPage "Resource Card";
        ResAllocPerServiceOrder: TestPage "Res. Alloc. per Service Order";
        ServiceOrderNo: Code[20];
        AllocatedHours: Decimal;
    begin
        // Test Resource Allocated Per Service Order Matrix after Resource allocation per Service Order from Resource Card.

        // 1. Setup: Create Resource, create Service Order and allocate Resource.
        Initialize();
        CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        LibraryResource.CreateResourceNew(Resource);
        ServiceOrderNo := CreateServiceOrder(ServiceItem);
        LibraryVariableStorage.Enqueue(ServiceOrderNo);

        // Use the random value for AllocatedHours.
        AllocatedHours := LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction();
        LibraryVariableStorage.Enqueue(AllocatedHours);
        AllocateResource(Resource."No.", ServiceOrderNo, AllocatedHours);

        // 2. Exercise: Run Resource Allocated Per Service Order page from Resource Card.
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", Resource."No.");
        ResAllocPerServiceOrder.Trap();
        ResourceCard."Resource Allocated per Service &Order".Invoke();
        Commit();
        ResAllocPerServiceOrder.ShowMatrix.Invoke();

        // 3. Verify: Verify the value on Resource Allocated Per Service Order Matrix in Resource Allocated Per Service Order Matrix Handler.
    end;

    [Test]
    [HandlerFunctions('ResourceGroupAllocatedPerServiceOrderMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceGroupAllocatedPerServiceOrder()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ServiceItem: Record "Service Item";
        ResourceGroups: TestPage "Resource Groups";
        ResGrAllocPerServOrder: TestPage "Res. Gr. Alloc. per Serv Order";
        ServiceOrderNo: Code[20];
        AllocatedHours: Decimal;
    begin
        // Test Resource Group Allocated Per Service Order Matrix after Resource Group allocation per Service Order from Resource Group Card.

        // 1. Setup: Create Resource Group, create Resource with Resource Group, create Service Order and allocate Resource.
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        CreateResourceWithResourceGroup(Resource, ResourceGroup."No.");
        ServiceOrderNo := CreateServiceOrder(ServiceItem);
        LibraryVariableStorage.Enqueue(ServiceOrderNo);

        // Use the random value for AllocatedHours.
        AllocatedHours := LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction();
        LibraryVariableStorage.Enqueue(AllocatedHours);
        AllocateResource(Resource."No.", ServiceOrderNo, AllocatedHours);

        // 2. Exercise: Run Resource Group Allocated per Service Order page from Resource Group Card.
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", ResourceGroup."No.");
        ResGrAllocPerServOrder.Trap();
        ResourceGroups."Res. Group Allocated per Service &Order".Invoke();
        Commit();
        ResGrAllocPerServOrder.ShowMatrix.Invoke();

        // 3. Verify: Verify the value on Resource Group Allocated Per Service Order Matrix in Resource Group Allocated Per Service Order Matrix Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceAvailabilityFromResource()
    var
        Resource: Record Resource;
        ResourceCard: TestPage "Resource Card";
        ResourceAvailability: TestPage "Resource Availability";
    begin
        // Test Resource availability from Resource Card.

        // 1. Setup: Create Resource with Capacity.
        Initialize();
        CreateResourceWithCapacity(Resource);

        // 2. Exercise: Run Resource Availability page from Resource Card.
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", Resource."No.");
        ResourceAvailability.Trap();
        ResourceCard."Resource A&vailability".Invoke();

        // 3. Verify: Verify the values on Resource Availability page.
        ResourceAvailability.PeriodType.SetValue(PeriodType::"Accounting Period");
        ResourceAvailability.AmountType.SetValue(ValueType::"Balance at Date");
        ResourceAvailability.ResAvailLines.Capacity.AssertEquals(Resource.Capacity);
        ResourceAvailability.ResAvailLines.NetAvailability.AssertEquals(Resource.Capacity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceGroupAvailabilityFromResourceGroup()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResourceGroups: TestPage "Resource Groups";
        ResGroupAvailability: TestPage "Res. Group Availability";
    begin
        // Test Resource Group availability from Resource Group Card.

        // 1. Setup: Create Resource Group with Capacity and create Resource with Resource Group.
        Initialize();
        CreateResourceGroupWithCapacity(ResourceGroup);
        CreateResourceWithResourceGroup(Resource, ResourceGroup."No.");

        // 2. Exercise: Run Resource Group Availability page from Resource Group Card.
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", ResourceGroup."No.");
        ResGroupAvailability.Trap();
        ResourceGroups."Res. Group Availa&bility".Invoke();

        // 3. Verify: Verify the values on Resource Group Availability page.
        ResGroupAvailability.PeriodType.SetValue(PeriodType::"Accounting Period");
        ResGroupAvailability.AmountType.SetValue(ValueType::"Balance at Date");
        ResGroupAvailability.ResGrAvailLines.Capacity.AssertEquals(ResourceGroup.Capacity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceCapacityMatrixNetChange()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: array[2] of Record "Work-Hour Template";
        Date: array[2] of Date;
        i: Integer;
    begin
        // [SCENARIO 377427] Resource Capacity "View by" = Week, "View as" = Net Change.
        Initialize();
        CreateCompanyBaseCalendar(BaseCalendar);

        // [GIVEN] Resource Capacity.
        LibraryResource.CreateResourceNew(Resource);
        // [GIVEN] Set Capacity for the Resource: 4 for Date1, 6 for Date2 (Date2 > Date1).
        Date[2] := WorkDate();
        Date[1] := LibraryRandom.RandDateFrom(CalcDate('<-1M>', Date[2]), -10);
        for i := 1 to ArrayLen(Date) do begin
            CreateWorkHourTemplate(WorkHourTemplate[i]);
            SetResourceCapacitySettingByPage(Resource."No.", Date[i], Date[i], WorkHourTemplate[i].Code);
        end;

        // [WHEN] Open Resource Capacity Matrix Page with "View by" = Week, "View as" = Net Change.
        // [THEN] Resource Capacity = 6 for Date2.
        VerifyResourceCapacity(Resource."No.", PeriodType::Week, ValueType::"Net Change", WorkHourTemplate[2].Monday);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceCapacityMatrixBalanceAtDate()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: array[2] of Record "Work-Hour Template";
        Date: array[2] of Date;
        i: Integer;
    begin
        // [SCENARIO 377427] Resource Capacity "View by" = Week, "View as" = Balance at Date.
        Initialize();
        CreateCompanyBaseCalendar(BaseCalendar);

        // [GIVEN] Resource Capacity.
        LibraryResource.CreateResourceNew(Resource);
        // [GIVEN] Set Capacity for the Resource: 4 for Date1, 6 for Date2 (Date2 > Date1).
        Date[2] := WorkDate();
        Date[1] := LibraryRandom.RandDateFrom(CalcDate('<-1M>', Date[2]), -10);
        for i := 1 to ArrayLen(Date) do begin
            CreateWorkHourTemplate(WorkHourTemplate[i]);
            SetResourceCapacitySettingByPage(Resource."No.", Date[i], Date[i], WorkHourTemplate[i].Code);
        end;

        // [WHEN] Open Resource Capacity Matrix Page with "View by" = Week, "View as" = Balance at Date.
        // [THEN] Resource Capacity = 10 for Date2.
        VerifyResourceCapacity(
          Resource."No.", PeriodType::Week, ValueType::"Balance at Date", WorkHourTemplate[1].Monday + WorkHourTemplate[2].Monday);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResourceCapacityMatrixZeroWorkHourTemplate()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        // [SCENARIO 377427] Resource Capacity "View by" = Week, "View as" = Net Change, zero Work-Hour Template
        Initialize();
        CreateCompanyBaseCalendar(BaseCalendar);

        // [GIVEN] Resource Capacity.
        LibraryResource.CreateResourceNew(Resource);
        // [GIVEN] Set Capacity for the Resource: 4 for Date1.
        CreateWorkHourTemplate(WorkHourTemplate);
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);
        // [GIVEN] Set Capacity for the Resource for Date1 using zero Work-Hour Template (total week hours = 0).
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), CreateZeroWorkHourTemplate());

        // [WHEN] Open Resource Capacity Matrix Page with "View by" = Week, "View as" = Net Change.
        // [THEN] Resource Capacity = 0 for Date1.
        VerifyResourceCapacity(Resource."No.", PeriodType::Week, ValueType::"Net Change", 0);
    end;

    [Test]
    [HandlerFunctions('ResourceAllocatedMatrixHandler,ResourceGroupAvailabilityMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceGroupCapacityWithPositiveAmount()
    begin
        // Test Allocated Hours, Date and "Availability after Orders" after doing Partial Allocation with Positive Capacity on Res. Group Availability page.
        AvailabilityOfOrdersOnResourceGroup(LibraryRandom.RandDec(1000, 2));
    end;

    [Test]
    [HandlerFunctions('ResourceAllocatedMatrixHandler,ResourceGroupAvailabilityMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceGroupCapacityWithZeroAmount()
    begin
        // Test Allocated Hours, Date and "Availability after Orders" after doing Partial Allocation with Blank Capacity on Res. Group Availability page.
        AvailabilityOfOrdersOnResourceGroup(0);
    end;

    [Test]
    [HandlerFunctions('ResourceAllocatedMatrixHandler,ResourceGroupAvailabilityMatrixHandler')]
    [Scope('OnPrem')]
    procedure ResourceGroupCapacityWithNegativeAmount()
    begin
        // Test Allocated Hours, Date and "Availability after Orders" after doing Partial Allocation with Negative Capacity on Res. Group Availability page.
        AvailabilityOfOrdersOnResourceGroup(-1 * LibraryRandom.RandDec(1000, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnAssemblyOrderOnResourceAvailabilityPage()
    var
        Resource: Record Resource;
        ResourceAvailabilityPage: TestPage "Resource Availability";
        ResourceCard: TestPage "Resource Card";
        Capacity: Decimal;
        AssemblyQuantity: Decimal;
    begin
        // [FEATURE] [Resource Availability]
        // [SCENARIO 375919] Resource Availability Page should consider "Qty. on Assembly Order"
        Initialize();

        // [GIVEN] Resource "R" with Capacity = 12
        Capacity := LibraryRandom.RandDecInRange(10, 100, 2);
        LibraryResource.CreateResourceNew(Resource);
        MockResCapacityEntry(Resource."No.", Capacity);

        // [GIVEN] Assembly Order for "R" of Quantity = 3
        AssemblyQuantity := LibraryRandom.RandDec(10, 2);
        MockAssemblyLine(Resource."No.", AssemblyQuantity);

        // [WHEN] Open Resource "R" Availability Page
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", Resource."No.");
        ResourceAvailabilityPage.Trap();
        ResourceCard."Resource A&vailability".Invoke();

        // [THEN] "Qty. on Assembly Order" = 3, "Net Availability" = 9
        ResourceAvailabilityPage.PeriodType.SetValue(PeriodType::"Accounting Period");
        ResourceAvailabilityPage.AmountType.SetValue(ValueType::"Balance at Date");
        ResourceAvailabilityPage.ResAvailLines.FILTER.SetFilter("Period Start", Format(CalcDate('<-CM>', WorkDate())));
        ResourceAvailabilityPage.ResAvailLines.QtyOnAssemblyOrder.AssertEquals(AssemblyQuantity);
        ResourceAvailabilityPage.ResAvailLines.NetAvailability.AssertEquals(Capacity - AssemblyQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkHourTemplate_CapacityDayRange_UT()
    var
        WorkHourTemplate: Record "Work-Hour Template";
        WorkHourTemplates: TestPage "Work-Hour Templates";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377427] Check Work-Hour Template capacity day ranges: [0..24]
        LibraryResource.CreateWorkHourTemplate(WorkHourTemplate);
        WorkHourTemplates.OpenEdit();
        WorkHourTemplates.GotoRecord(WorkHourTemplate);

        asserterror WorkHourTemplates.Monday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Monday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Tuesday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Tuesday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Wednesday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Wednesday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Thursday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Thursday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Friday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Friday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Saturday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Saturday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Sunday.SetValue(-0.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);

        asserterror WorkHourTemplates.Sunday.SetValue(24.00001);
        Assert.ExpectedErrorCode(TestValidationTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_UpdateResourceCapacityTwice()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 377907] "Resource Capacity" should no be updated when run twice for the same day

        // [GIVEN] Resource "X"
        Initialize();
        CreateCompanyBaseCalendar(BaseCalendar);
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Work Hour Template with Day = 1
        CreateWorkHourTemplate(WorkHourTemplate);

        // [GIVEN] Resource Capacity updated for Resource "X", capacity = 1
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [WHEN] Update Resource Capacity second time for Resource "X"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" is 1 for Resource "X"
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", WorkHourTemplate.Monday);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_IncreaseResourceCapacity()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 377907] "Resource Capacity" should be updated when increase work-hour template capacity for current date
        Initialize();
        CreateCompanyBaseCalendar(BaseCalendar);
        // [GIVEN] Resource "X"
        // [GIVEN] Work Hour Template with Day = 1 for date "Y", capacity = 1
        // [GIVEN] Resource Capacity updated for Resource "X"
        // [GIVEN] Increased capacity for date "Y", capacity = 2
        CreateResourceWithWHTemplate(Resource, WorkHourTemplate, 0);

        // [WHEN] Update Resource Capacity for Resource "X", date "Y"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" is 2 for Resource "X"
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", WorkHourTemplate.Monday);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_NoResourceCapacitySetForNonWorkingDay()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 377907] "Resource Capacity" should not be updated for nonworking day

        // [GIVEN] Resource "X"
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        CreateCompanyBaseCalendar(BaseCalendar);

        // [GIVEN] "Nonworking" day in Company's Base Calendar Change for date "Y"
        CreateNonWorkingBaseCalendarChange(BaseCalendar.Code, WorkDate(), BaseCalendarChange);

        // [GIVEN] Work Hour Template with Day = 1 for date "Y"
        CreateWorkHourTemplate(WorkHourTemplate);

        // [WHEN] Update Resource Capacity for Resource "X", date "Y"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" is 0 for Resource "X"
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", 0);

        // Tear down
        BaseCalendarChange.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_UpdateCapacityAfterSwitchWorkingToNonWorking()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 377907] "Resource Capacity" should be zero out when update capacity for non-working day after switch from working

        // [GIVEN] Resource "X"
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        CreateCompanyBaseCalendar(BaseCalendar);

        // [GIVEN] Work Hour Template with Day = 1 for date "Y"
        CreateWorkHourTemplate(WorkHourTemplate);

        // [GIVEN] Resource Capacity updated for Resource "X"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [GIVEN] Change "Working" day to "Nonworking" day in Base Calendar Change for date "Y"
        CreateNonWorkingBaseCalendarChange(BaseCalendar.Code, WorkDate(), BaseCalendarChange);

        // [WHEN] Update Resource Capacity for Resource "X", date "Y"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" is 0 for Resource "X"
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", 0);

        // Tear down
        BaseCalendarChange.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToReverseMoreCapacityThenSetAfterSwitchWorkingToNonWorking()
    var
        BaseCalendar: Record "Base Calendar";
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 377907] It should be not possible to reverse more capacity then was set for Working day after switch to non-working

        // [GIVEN] Resource "X"
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        // [GIVEN] Company's base calendar is defined, where  date "Y" is a working date
        CreateCompanyBaseCalendar(BaseCalendar);
        // [GIVEN] Work Hour Template with Day = 1 for date "Y", capacity = 1
        CreateWorkHourTemplate(WorkHourTemplate);

        // [GIVEN] Resource Capacity updated for Resource "X"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [GIVEN] Change "Working" day to "Nonworking" day in Base Calendar Change for date "Y"
        CreateNonWorkingBaseCalendarChange(BaseCalendar.Code, WorkDate(), BaseCalendarChange);

        // [GIVEN] Increased capacity for date "Y", capacity = 2
        ModifyWorkHourTemplate(WorkHourTemplate, WorkHourTemplate.Monday + LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] Update Resource Capacity for Resource "X", date "Y"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" is 0 for Resource "X"
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", 0);

        // Tear down
        BaseCalendarChange.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_ResourceCapacityWithDecimals()
    var
        Resource: Record Resource;
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        // [FEATURE] [Resource Capacity] [UI]
        // [SCENARIO 379406] "Resource Capacity" can be updated to the value with decimals
        Initialize();

        // [GIVEN] Resource "X"
        // [GIVEN] New Work Hour Template with Capacity = 1
        // [GIVEN] Resource Capacity updated for Resource "X"
        // [GIVEN] Work Hour Template for date "Y" has increased capacity = 2.5
        CreateResourceWithWHTemplate(Resource, WorkHourTemplate, 0.5);

        // [WHEN] Update Resource Capacity for Resource "X", date "Y"
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);

        // [THEN] "Resource Capacity" for Resource "X" is equal to 2.5
        VerifyResourceCapacity(Resource."No.", PeriodType::Day, ValueType::"Net Change", WorkHourTemplate.Monday);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource Matrix Management");
        // Clear global variables.
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource Matrix Management");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource Matrix Management");
    end;

    local procedure CreateResourceWithWHTemplate(var Resource: Record Resource; var WorkHourTemplate: Record "Work-Hour Template"; Decimals: Decimal)
    begin
        LibraryResource.CreateResourceNew(Resource);
        CreateWorkHourTemplate(WorkHourTemplate);
        SetResourceCapacitySettingByPage(Resource."No.", WorkDate(), WorkDate(), WorkHourTemplate.Code);
        ModifyWorkHourTemplate(WorkHourTemplate, WorkHourTemplate.Monday + LibraryRandom.RandIntInRange(3, 10) + Decimals);
    end;

    local procedure AvailabilityOfOrdersOnResourceGroup(Capacity: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ResourceGroupNo: Code[20];
        QtyToAllocate: Decimal;
    begin
        // Test Allocated Hours, Date and "Availability after Orders" after doing Partial Allocation on Res. Group Availability page.
        // 1. Setup: Create Resource Group and Resource Group capacity.
        Initialize();
        QtyToAllocate := LibraryRandom.RandDec(100, 2);  // For Partial Allocation Qty To Allocate is less than capacity.
        ResourceGroupNo := UpdateResourceGroupWithCapacity(Capacity);
        LibraryVariableStorage.Enqueue(ResourceGroupNo);
        LibraryVariableStorage.Enqueue(QtyToAllocate);

        // 2. Excercise: Create Service Order And Allocate Resource on Resource Allocation page.
        CreateServiceOrderWithServiceItemLine(ServiceHeader);
        SelectResourceGroupOnServiceOrder(ServiceHeader."No.", ResourceGroupNo);
        AllocateResourceOnResGroupAvailability(ServiceHeader."No.");

        // 3. Verify: Allocated Date and hours on Resource Allocation and Availability after Orders on Res. Group Availability.
        VerifyResourceAllocatedDateAndHours(ServiceHeader."No.", QtyToAllocate);
        VerifyResGroupAvailability(ResourceGroupNo, Capacity, QtyToAllocate);
    end;

    local procedure CreateEmployeeAbsence(var EmployeeAbsence: Record "Employee Absence"; EmployeeNo: Code[20])
    begin
        LibraryHumanResource.CreateEmployeeAbsence(EmployeeAbsence);
        EmployeeAbsence.Validate("Employee No.", EmployeeNo);
        EmployeeAbsence.Validate("From Date", WorkDate());
        EmployeeAbsence.Validate("Cause of Absence Code", GetCauseOfAbsenceCode());

        // Use random for Quantity.
        EmployeeAbsence.Validate(Quantity, LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction());
        EmployeeAbsence.Modify(true);
    end;

    local procedure CreateEmployeeQualification(EmployeeNo: Code[20]): Code[10]
    var
        EmployeeQualification: Record "Employee Qualification";
        Qualification: Record Qualification;
    begin
        Qualification.FindFirst();
        LibraryHumanResource.CreateEmployeeQualification(EmployeeQualification, EmployeeNo);
        EmployeeQualification.Validate("Qualification Code", Qualification.Code);
        EmployeeQualification.Modify(true);
        exit(Qualification.Code);
    end;

    local procedure AllocateResource(ResourceNo: Code[20]; DocumentNo: Code[20]; AllocatedHours2: Decimal)
    var
        ResourceAllocations: TestPage "Resource Allocations";
    begin
        ResourceAllocations.OpenEdit();
        ResourceAllocations.FILTER.SetFilter("Document No.", DocumentNo);
        ResourceAllocations."Resource No.".SetValue(ResourceNo);
        ResourceAllocations."Allocated Hours".SetValue(AllocatedHours2);
        ResourceAllocations."Allocation Date".SetValue(WorkDate());
        ResourceAllocations.OK().Invoke();
    end;

    local procedure AllocateResourceOnResGroupAvailability(DocumentNo: Code[20])
    var
        ResourceAllocations: TestPage "Resource Allocations";
    begin
        ResourceAllocations.OpenEdit();
        ResourceAllocations.FILTER.SetFilter("Document No.", DocumentNo);
        ResourceAllocations.ResGroupAvailability.Invoke();
    end;

    local procedure CreateJobPlanningLine(No2: Code[20])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);

        // Assigning values to global variables. Use random value for Quantity.
        LibraryVariableStorage.Enqueue(Job."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No2);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction());
        JobPlanningLine.Modify(true);
        LibraryVariableStorage.Enqueue(JobPlanningLine.Quantity);
    end;

    local procedure CreateResourceGroupWithCapacity(var ResourceGroup: Record "Resource Group")
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // Use random value for the Capacity.
        ResourceGroup.Validate(Capacity, LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction());
        ResourceGroup.Modify(true);
    end;

    local procedure CreateResourceWithCapacity(var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);

        // Use random value for the Capacity.
        Resource.Validate(Capacity, LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction());
        Resource.Modify(true);
    end;

    local procedure CreateResourceWithResourceGroup(var Resource: Record Resource; ResourceGroupNo: Code[20])
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Resource Group No.", ResourceGroupNo);
        Resource.Modify(true);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100) + LibraryUtility.GenerateRandomFraction());
        ServiceLine.Validate("Order Date", WorkDate());
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(ServiceItem: Record "Service Item"): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceOrderWithServiceItemLine(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateWorkHourTemplate(var WorkHourTemplate: Record "Work-Hour Template")
    begin
        LibraryResource.CreateWorkHourTemplate(WorkHourTemplate);
        ModifyWorkHourTemplate(WorkHourTemplate, LibraryRandom.RandInt(10));
    end;

    local procedure CreateZeroWorkHourTemplate(): Code[10]
    var
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        LibraryResource.CreateWorkHourTemplate(WorkHourTemplate);
        exit(WorkHourTemplate.Code);
    end;

    local procedure CreateCompanyBaseCalendar(var BaseCalendar: Record "Base Calendar");
    var
        CompanyInfo: Record "Company Information";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CompanyInfo.Get();
        CompanyInfo."Base Calendar Code" := BaseCalendar.Code;
        CompanyInfo.Modify();
    end;

    local procedure CreateNonWorkingBaseCalendarChange(BaseCalendarCode: code[10]; TargetDate: Date; var BaseCalendarChange: Record "Base Calendar Change")
    begin
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendarCode, BaseCalendarChange."Recurring System"::" ", TargetDate, BaseCalendarChange.Day::" ");
        BaseCalendarChange.Validate(Nonworking, true);
        BaseCalendarChange.Modify(true);
    end;

    local procedure MockResCapacityEntry(ResourceNo: Code[20]; NewCapacity: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.FindLast();
        ResCapacityEntry."Entry No." += 1;
        ResCapacityEntry."Resource No." := ResourceNo;
        ResCapacityEntry.Capacity := NewCapacity;
        ResCapacityEntry.Date := WorkDate();
        ResCapacityEntry.Insert();
    end;

    local procedure MockAssemblyLine(ResourceNo: Code[20]; NewQuantity: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
        AssemblyLine."Document No." := LibraryUtility.GenerateGUID();
        AssemblyLine.Type := AssemblyLine.Type::Resource;
        AssemblyLine."No." := ResourceNo;
        AssemblyLine."Remaining Quantity (Base)" := NewQuantity;
        AssemblyLine."Due Date" := WorkDate();
        AssemblyLine.Insert();
    end;

    local procedure GetCauseOfAbsenceCode(): Code[10]
    var
        CauseOfAbsence: Record "Cause of Absence";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        if CauseOfAbsence."Unit of Measure Code" = '' then begin
            HumanResourceUnitOfMeasure.FindFirst();
            CauseOfAbsence.Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
            CauseOfAbsence.Modify(true);
        end;
        exit(CauseOfAbsence.Code);
    end;

    local procedure ModifyWorkHourTemplate(var WorkHourTemplate: Record "Work-Hour Template"; Capacity: Decimal)
    begin
        // Create Work Hour Template for a Week using Random Values.

        WorkHourTemplate.Validate(Monday, Capacity);
        WorkHourTemplate.Validate(Tuesday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate(Wednesday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate(Thursday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate(Friday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate(Saturday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate(Sunday, WorkHourTemplate.Monday);
        WorkHourTemplate.Validate("Total per Week", WorkHourTemplate.Monday * 7);  // Total Capacity for the Week.
        WorkHourTemplate.Modify(true);
    end;

    local procedure UpdateResourceGroupWithCapacity(Capacity: Decimal): Code[20]
    var
        ResourceGroup: Record "Resource Group";
        ResourceGroups: TestPage "Resource Groups";
        ResGroupCapacity: TestPage "Res. Group Capacity";
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", ResourceGroup."No.");
        ResGroupCapacity.Trap();
        ResourceGroups.ResGroupCapacity.Invoke();
        ResGroupCapacity.MatrixForm.FILTER.SetFilter("No.", ResourceGroup."No.");
        ResGroupCapacity.MatrixForm.Field1.SetValue(Capacity);
        exit(ResourceGroup."No.");
    end;

    local procedure SetResourceCapacitySettingByPage(ResourceNo: Code[20]; StartDate: Date; EndDate: Date; WorkHourTemplateCode: Code[10])
    var
        ResourceCapacitySettings: TestPage "Resource Capacity Settings";
    begin
        ResourceCapacitySettings.OpenNew();
        ResourceCapacitySettings.FILTER.SetFilter("No.", ResourceNo);
        ResourceCapacitySettings.StartDate.SetValue(StartDate);
        ResourceCapacitySettings.EndDate.SetValue(EndDate);
        ResourceCapacitySettings.WorkTemplateCode.SetValue(WorkHourTemplateCode);
        ResourceCapacitySettings.UpdateCapacity.Invoke();
    end;

    local procedure SelectResourceGroupOnServiceOrder(DocumentNo: Code[20]; ResourceGroupNo: Code[20])
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.Validate("Resource Group No.", ResourceGroupNo);
        ServiceOrderAllocation.Modify(true);
    end;

    local procedure VerifyResourceAllocatedDateAndHours(DocumentNo: Code[20]; AllocatedHours: Decimal)
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.TestField("Allocated Hours", AllocatedHours);
        ServiceOrderAllocation.TestField("Allocation Date", WorkDate());
    end;

    local procedure VerifyResGroupAvailability(ResourceGroupNo: Code[20]; Capacity: Decimal; QtyAllocated: Decimal)
    var
        ResGroupCapacity: TestPage "Res. Group Capacity";
        ResGroupAvailability: TestPage "Res. Group Availability";
    begin
        ResGroupCapacity.OpenEdit();
        ResGroupCapacity.MatrixForm.FILTER.SetFilter("No.", ResourceGroupNo);
        ResGroupAvailability.Trap();
        ResGroupCapacity.MatrixForm.ResGroupAvailability.Invoke();
        ResGroupAvailability.PeriodType.SetValue(PeriodType::Day);
        ResGroupAvailability.ResGrAvailLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ResGroupAvailability.ResGrAvailLines.Capacity.AssertEquals(Capacity);
        ResGroupAvailability.ResGrAvailLines.CapacityAfterOrders.AssertEquals(Capacity - QtyAllocated);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AbsenceOverviewByPeriodMatrix(var AbsOverviewByPeriodMatrix: TestPage "Abs. Overview by Period Matrix")
    begin
        AbsOverviewByPeriodMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        AbsOverviewByPeriodMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AbsenceOverviewByMatrixHandler(var AbsOverByCatMatrix: TestPage "Abs. Over. by Cat. Matrix")
    begin
        AbsOverByCatMatrix.FILTER.SetFilter("Period Start", Format(WorkDate()));
        AbsOverByCatMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AbsencesByCategoriesMatrix(var EmplAbsencesByCatMatrix: TestPage "Empl. Absences by Cat. Matrix")
    begin
        EmplAbsencesByCatMatrix.FILTER.SetFilter("Period Start", Format(WorkDate()));
        EmplAbsencesByCatMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ArticlesOverviewMatrixHandler(var MiscArticlesOverviewMatrix: TestPage "Misc. Articles Overview Matrix")
    begin
        MiscArticlesOverviewMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        MiscArticlesOverviewMatrix.Field1.AssertEquals('Yes');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfidentialOverviewMatrix(var ConfInfoOverviewMatrix: TestPage "Conf. Info. Overview Matrix")
    begin
        ConfInfoOverviewMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ConfInfoOverviewMatrix.Field1.AssertEquals('Yes');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QualificationOverviewMatrix(var QualificationOverviewMatrix: TestPage "Qualification Overview Matrix")
    begin
        QualificationOverviewMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        QualificationOverviewMatrix.Field1.AssertEquals('Yes');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceAllocatedPerJobMatrixHandler(var ResourceAllocPerJobMatrix: TestPage "Resource Alloc. per Job Matrix")
    begin
        ResourceAllocPerJobMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ResourceAllocPerJobMatrix.Col1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceAllocatedMatrixHandler(var ResGrAvailabilityService: TestPage "Res.Gr. Availability (Service)")
    begin
        ResGrAvailabilityService.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceGroupAvailabilityMatrixHandler(var ResGrAvailServMatrix: TestPage "Res. Gr. Avail. (Serv.) Matrix")
    var
        ResourceGroupNo: Variant;
        QtyToAllocate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ResourceGroupNo);
        LibraryVariableStorage.Dequeue(QtyToAllocate);
        ResGrAvailServMatrix.FILTER.SetFilter("No.", ResourceGroupNo);
        ResGrAvailServMatrix.Qtytoallocate.SetValue(QtyToAllocate);
        ResGrAvailServMatrix.Allocate.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceGroupAllocatedPerJobMatrixHandler(var ResGrpAllocPerJobMatrix: TestPage "ResGrp. Alloc. per Job Matrix")
    begin
        ResGrpAllocPerJobMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ResGrpAllocPerJobMatrix.Col1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceAllocatedPerServiceOrderMatrixHandler(var ResAllPerServiceMatrix: TestPage "Res. All. per Service  Matrix")
    begin
        ResAllPerServiceMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ResAllPerServiceMatrix.Col1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceGroupAllocatedPerServiceOrderMatrixHandler(var ResGrpAllPerServMatrix: TestPage "ResGrp. All. per Serv.  Matrix")
    begin
        ResGrpAllPerServMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ResGrpAllPerServMatrix.Col1.SetValue(LibraryVariableStorage.DequeueDecimal());
    end;

    local procedure VerifyResourceCapacity(ResourceNo: Code[20]; PeriodType: Option; ValueType: Option; Capacity: Decimal)
    var
        ResourceCapacity: TestPage "Resource Capacity";
    begin
        ResourceCapacity.OpenEdit();
        ResourceCapacity.PeriodType.SetValue(PeriodType);
        ResourceCapacity.QtyType.SetValue(ValueType);
        ResourceCapacity.MatrixForm.FILTER.SetFilter("No.", ResourceNo);
        ResourceCapacity.MatrixForm.Field1.AssertEquals(Capacity);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

