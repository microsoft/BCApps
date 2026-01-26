codeunit 144071 "UT PAG ABBREV"
{
    // 1. Purpose of the test is to verify caption on Resource Capacity Matrix Page.
    // 2. Purpose of the test is to verify caption on Res. Group Capacity Matrix Page.
    // 3. Purpose of the test is to verify caption on Resource Allocated per Job Matrix Page.
    // 4. Purpose of the test is to verify caption on To-Dos Matrix Page.
    // 5. Purpose of the test is to verify caption on Res. Gr. Allocated per Job Matrix Page.
    // 6. Purpose of the test is to verify caption on Opportunities Matrix Page.
    // 7. Purpose of the test is to verify caption on Absence Overview by Periods Matrix Page.
    // 8. Purpose of the test is to verify caption on Res. Availability (Service) Matrix Page.
    // 9. Purpose of the test is to verify caption on Res. Gr. Availability (Service) Matrix Page.
    // 10. Purpose of the test is to verify caption on Res. Alloc. per Service Order Matrix Page.
    // 11. Purpose of the test is to verify caption on Res. Gr. Alloc. per Service Order Matrix Page.
    // 12. Purpose of the test is to verify caption on Work Center Calendar Matrix Page.
    // 13. Purpose of the test is to verify caption on Machine Center Calendar Matrix Page.
    // 14. Purpose of the test is to verify caption on Work Ctr. Group Calendar Matrix Page.
    // 15. Purpose of the test is to verify caption on Production Forecast Matrix Page.
    // 
    // Covers Test Cases for WI - 343942
    // ------------------------------------------------------------------
    // Test Function Name                                         TFS ID
    // ------------------------------------------------------------------
    // ResourceCapacityWithPeriodTypeMonth                        152125
    // ResGroupCapacityWithPeriodTypeMonth                        152126
    // ResourceAllocatedPerJobWithPeriodTypeMonth                 152127
    // ToDosWithPeriodTypeMonth                                   152128
    // ResGrAllocatedPerJobWithPeriodTypeMonth                    152129
    // OpportunitiesWithPeriodTypeMonth                           152130
    // AbsenceOverviewByPeriodsPeriodTypeMonth                    152131
    // ResAvailabilityServiceWithPeriodTypeMonth                  152132
    // ResGrAvailabilityServiceWithPeriodTypeMonth                152133
    // ResAllocPerServiceOrderWithPeriodTypeMonth                 152134
    // ResGrAllocPerServOrderWithPeriodTypeMonth                  152135
    // WorkCenterCalendarWithPeriodTypeMonth                      152136
    // MachineCenterCalendarWithPeriodTypeMonth                   152137
    // WorkCtrGroupCalendarWithPeriodTypeMonth                    152138
    // ProductionForecastWithPeriodTypeMonth                      152139

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CaptionErr: Label 'Caption must be the same.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceCapacityWithPeriodTypeMonth()
    var
        ResourceCapacity: TestPage "Resource Capacity";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Resource Capacity Matrix Page.

        // Setup: Create Resource and generate Column Captions.
        Initialize();
        No := CreateResource();
        GeneratePeriodMatrixData();
        ResourceCapacity.OpenEdit();
        ResourceCapacity.FILTER.SetFilter("No.", No);

        // Exercise: Set Period Type on Resource Capacity Page.
        ResourceCapacity.PeriodType.SetValue(PeriodType::Month);

        // Verify: Verify Column Captions on Resource Capacity Matrix Page.
        VerifyCaptionJanToJune(
          ResourceCapacity.MatrixForm.Field1.Caption, ResourceCapacity.MatrixForm.Field2.Caption,
          ResourceCapacity.MatrixForm.Field3.Caption,
          ResourceCapacity.MatrixForm.Field4.Caption, ResourceCapacity.MatrixForm.Field5.Caption,
          ResourceCapacity.MatrixForm.Field6.Caption);
        VerifyCaptionJulToDec(
          ResourceCapacity.MatrixForm.Field7.Caption, ResourceCapacity.MatrixForm.Field8.Caption,
          ResourceCapacity.MatrixForm.Field9.Caption,
          ResourceCapacity.MatrixForm.Field10.Caption, ResourceCapacity.MatrixForm.Field11.Caption,
          ResourceCapacity.MatrixForm.Field12.Caption);
        ResourceCapacity.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResGroupCapacityWithPeriodTypeMonth()
    var
        ResGroupCapacity: TestPage "Res. Group Capacity";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Res. Group Capacity Matrix Page.

        // Setup: Create Resource Group and generate Column Captions.
        Initialize();
        No := CreateResourceGroup();
        GeneratePeriodMatrixData();
        ResGroupCapacity.OpenEdit();
        ResGroupCapacity.FILTER.SetFilter("No.", No);

        // Exercise: Set Period Type on Res.Group Capacity Page.
        ResGroupCapacity.PeriodType.SetValue(PeriodType::Month);

        // Verify: Verify Column Captions on Res. Group Capacity Matrix Page.
        VerifyCaptionJanToJune(
          ResGroupCapacity.MatrixForm.Field1.Caption, ResGroupCapacity.MatrixForm.Field2.Caption,
          ResGroupCapacity.MatrixForm.Field3.Caption,
          ResGroupCapacity.MatrixForm.Field4.Caption, ResGroupCapacity.MatrixForm.Field5.Caption,
          ResGroupCapacity.MatrixForm.Field6.Caption);
        VerifyCaptionJulToDec(
          ResGroupCapacity.MatrixForm.Field7.Caption, ResGroupCapacity.MatrixForm.Field8.Caption,
          ResGroupCapacity.MatrixForm.Field9.Caption,
          ResGroupCapacity.MatrixForm.Field10.Caption, ResGroupCapacity.MatrixForm.Field11.Caption,
          ResGroupCapacity.MatrixForm.Field12.Caption);
        ResGroupCapacity.Close();
    end;

    [Test]
    [HandlerFunctions('ResourceAllocPerJobMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ResourceAllocatedPerJobWithPeriodTypeMonth()
    var
        ResourceAllocatedPerJob: TestPage "Resource Allocated per Job";
        ResourceNo: Code[20];
        JobNo: Code[20];
    begin
        // Purpose of the test is to verify caption on Resource Allocated per Job Matrix Page.

        // Setup: Create Resource,Job and generate Column Captions.
        Initialize();
        ResourceNo := CreateResource();
        JobNo := CreateJob(ResourceNo, '');  // Using blank for Resource Group.
        OpenResourceAllocatedPerJobPage(ResourceAllocatedPerJob, ResourceNo);
        LibraryVariableStorage.Enqueue(JobNo);  // Enqueue Values for Page Handler - ResourceAllocPerJobMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        ResourceAllocatedPerJob.ShowMatrix.Invoke();
        ResourceAllocatedPerJob.Close();

        // Verify: Verify Column Captions on Resource Allocated per Job Matrix Page on Page Handler ResourceAllocPerJobMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ToDosMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ToDosWithPeriodTypeMonth()
    var
        ToDos: TestPage Microsoft.CRM.Analysis.Tasks;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on To-Dos Matrix Page.

        // Setup: Create To-dos and generate Column Captions.
        Initialize();
        No := CreateToDos();
        LibraryVariableStorage.Enqueue(No);  // Enqueue Values for Page Handler - ToDosMatrixPageHandler.
        GeneratePeriodMatrixData();
        ToDos.OpenEdit();
        ToDos.FILTER.SetFilter("No.", No);
        ToDos.PeriodType.SetValue(PeriodType::Month);

        // Exercise: Open Show Matrix.
        ToDos.ShowMatrix.Invoke();
        ToDos.Close();

        // Verify: Verify Column Captions on To-Dos Matrix Page on Page Handler ToDosMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ResGrpAllocPerJobMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ResGrAllocatedPerJobWithPeriodTypeMonth()
    var
        ResGrAllocatedPerJob: TestPage "Res. Gr. Allocated per Job";
        ResourceGroupNo: Code[20];
        JobNo: Code[20];
    begin
        // Purpose of the test is to verify caption on Res. Gr. Allocated per Job Matrix Page.

        // Setup: Create Resource Group,Job and generate Column Captions.
        Initialize();
        ResourceGroupNo := CreateResourceGroup();
        JobNo := CreateJob('', ResourceGroupNo);  // Using blank for Resource.
        OpenResGrAllocatedPerJobPage(ResGrAllocatedPerJob, ResourceGroupNo);
        LibraryVariableStorage.Enqueue(JobNo);  // Enqueue Values for Page Handler - ResGrpAllocPerJobMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        ResGrAllocatedPerJob.ShowMatrix.Invoke();
        ResGrAllocatedPerJob.Close();

        // Verify: Verify Column Captions on Res. Gr. Allocated per Job Matrix Page on Page Handler ResGrpAllocPerJobMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('OpportunitiesMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OpportunitiesWithPeriodTypeMonth()
    var
        Opportunities: TestPage Opportunities;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Opportunities Matrix Page.

        // Setup: Create Opportunity and generate Column Captions.
        Initialize();
        No := CreateOpportunity();
        LibraryVariableStorage.Enqueue(No);  // Enqueue Values for Page Handler - OpportunitiesMatrixPageHandler.
        GeneratePeriodMatrixData();
        Opportunities.OpenEdit();
        Opportunities.FILTER.SetFilter("No.", No);
        Opportunities.PeriodType.SetValue(PeriodType::Month);

        // Exercise: Open Show Matrix.
        Opportunities.ShowMatrix.Invoke();
        Opportunities.Close();

        // Verify: Verify Column Captions on Opportunities Matrix Page on Page Handler OpportunitiesMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('AbsOverviewByPeriodMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AbsenceOverviewByPeriodsPeriodTypeMonth()
    var
        AbsenceOverviewByPeriods: TestPage "Absence Overview by Periods";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Absence Overview by Periods Matrix Page.

        // Setup: Create Employee and generate Column Captions.
        Initialize();
        No := CreateEmployee();
        LibraryVariableStorage.Enqueue(No);  // Enqueue Values for Page Handler - AbsOverviewByPeriodMatrixPageHandler.
        GeneratePeriodMatrixData();
        AbsenceOverviewByPeriods.OpenEdit();
        AbsenceOverviewByPeriods.FILTER.SetFilter("No.", No);
        AbsenceOverviewByPeriods.PeriodType.SetValue(PeriodType::Month);

        // Exercise: Open Show Matrix.
        AbsenceOverviewByPeriods.ShowMatrix.Invoke();
        AbsenceOverviewByPeriods.Close();

        // Verify: Verify Column Captions on Absence Overview by Periods Matrix Page on Page Handler AbsOverviewByPeriodMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ResAvailServiceMatrixPageHandler,ResAvailabilityServicePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResAvailabilityServiceWithPeriodTypeMonth()
    var
        OrderNo: Code[20];
        ResourceNo: Code[20];
    begin
        // Purpose of the test is to verify caption on Res. Availability (Service) Matrix Page.

        // Setup: Create Resource and generate Column Captions.
        Initialize();
        ResourceNo := CreateResource();
        OrderNo := CreateServiceOrder(ResourceNo, '');  // Using blank for Resource Group.
        CreateServiceOrderAllocation(ResourceNo, '', OrderNo);  // Using blank for Resource Group.
        LibraryVariableStorage.Enqueue(ResourceNo);  // Enqueue Values for Page Handler - ResAvailServiceMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise.
        OpenResourceAllocation(OrderNo, ResourceNo);

        // Verify: Verification done in ResAvailServiceMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ResGrAvailabilityServicePageHandler,ResGrAvailServMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResGrAvailabilityServiceWithPeriodTypeMonth()
    var
        OrderNo: Code[20];
        ResourceGroupNo: Code[20];
    begin
        // Purpose of the test is to verify caption on Res. Gr. Availability (Service) Matrix Page.

        // Setup: Create Resource Group,Service Order,Service Order Allocation and generate Column Captions.
        Initialize();
        ResourceGroupNo := CreateResourceGroup();
        OrderNo := CreateServiceOrder('', ResourceGroupNo);  // Using blank for Resource.
        CreateServiceOrderAllocation('', ResourceGroupNo, OrderNo);  // Using blank for Resource.
        LibraryVariableStorage.Enqueue(ResourceGroupNo);  // Enqueue Values for Page Handler - ResGrAvailServMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise.
        OpenResourceAllocationResGroupAvailability(OrderNo, ResourceGroupNo);

        // Verify: Verification done in ResGrAvailServMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ResAllPerServiceMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ResAllocPerServiceOrderWithPeriodTypeMonth()
    var
        ResAllocPerServiceOrder: TestPage "Res. Alloc. per Service Order";
        OrderNo: Code[20];
        ResourceNo: Code[20];
    begin
        // Purpose of the test is to verify caption on Res. Alloc. per Service Order Matrix Page.

        // Setup: Create Resource,Service Order and generate Column Captions.
        Initialize();
        ResourceNo := CreateResource();
        OrderNo := CreateServiceOrder(ResourceNo, '');  // Using blank for Resource Group.
        OpenResAllocPerServiceOrderPage(ResAllocPerServiceOrder, ResourceNo);
        LibraryVariableStorage.Enqueue(OrderNo);  // Enqueue Values for Page Handler - ResAllPerServiceMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        ResAllocPerServiceOrder.ShowMatrix.Invoke();
        ResAllocPerServiceOrder.Close();

        // Verify: Verify Column Captions on Res. Alloc. per Service Order Matrix Page on Page Handler ResAllPerServiceMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ResGrpAllPerServMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ResGrAllocPerServOrderWithPeriodTypeMonth()
    var
        ResGrAllocPerServOrder: TestPage "Res. Gr. Alloc. per Serv Order";
        OrderNo: Code[20];
        ResourceGroupNo: Code[20];
    begin
        // Purpose of the test is to verify caption on  Res. Gr. Alloc. per Service Order Matrix Page.

        // Setup: Create Resource Group,Service Order and generate Column Captions.
        Initialize();
        ResourceGroupNo := CreateResourceGroup();
        OrderNo := CreateServiceOrder('', ResourceGroupNo);  // Using blank for Resource.
        OpenResGrAllocPerServOrderPage(ResGrAllocPerServOrder, ResourceGroupNo);
        LibraryVariableStorage.Enqueue(OrderNo);  // Enqueue Values for Page Handler - ResGrpAllPerServMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        ResGrAllocPerServOrder.ShowMatrix.Invoke();
        ResGrAllocPerServOrder.Close();

        // Verify: Verify Column Captions on Res. Gr. Alloc. per Service Order Matrix Page on Page Handler ResGrpAllPerServMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeMonth()
    var
        WorkCenterCalendar: TestPage "Work Center Calendar";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Work Center Calendar Matrix Page.

        // Setup: Create Work Center and generate Column Captions.
        Initialize();
        No := CreateWorkCenter();
        OpenWorkCenterCalendarPage(WorkCenterCalendar, No);
        LibraryVariableStorage.Enqueue(No);  // Enqueue Values for Page Handler - WorkCenterCalendarMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        WorkCenterCalendar.ShowMatrix.Invoke();
        WorkCenterCalendar.Close();

        // Verify: Verify Column Captions on Work Center Calendar Matrix Page on Page Handler WorkCenterCalendarMatrixPage.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeMonth()
    var
        MachineCenterCalendar: TestPage "Machine Center Calendar";
        No: Code[20];
    begin
        // Purpose of the test is to verify caption on Machine Center Calendar Matrix Page.

        // Setup: Create Machine Center and generate Column Captions.
        Initialize();
        No := CreateMachineCenter();
        OpenMachineCenterCalendarPage(MachineCenterCalendar, No);
        LibraryVariableStorage.Enqueue(No);  // Enqueue Values for Page Handler - MachineCenterCalendarMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        MachineCenterCalendar.ShowMatrix.Invoke();
        MachineCenterCalendar.Close();

        // Verify: Verify Column Captions on Work Center Calendar Matrix Page on Page Handler MachineCenterCalendarMatrixPage.
    end;

    [Test]
    [HandlerFunctions('WorkCtrGrpCalendarMatrixPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WorkCtrGroupCalendarWithPeriodTypeMonth()
    var
        WorkCtrGroupCalendar: TestPage "Work Ctr. Group Calendar";
        "Code": Code[20];
    begin
        // Purpose of the test is to verify caption on Work Ctr. Group Calendar Matrix Page.

        // Setup: Create Work Center Group and generate Column Captions.
        Initialize();
        Code := CreateWorkCenterGroup();
        OpenWorkCenterGroupPage(WorkCtrGroupCalendar, Code);
        LibraryVariableStorage.Enqueue(Code);  // Enqueue Values for Page Handler - WorkCtrGrpCalendarMatrixPageHandler.
        GeneratePeriodMatrixData();

        // Exercise: Open Show Matrix.
        WorkCtrGroupCalendar.ShowMatrix.Invoke();
        WorkCtrGroupCalendar.Close();

        // Verify: Verify Column Captions on Work Ctr Group Calendar Matrix Page on Page Handler WorkCtrGrpCalendarMatrixPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DemandForecastWithPeriodTypeMonth()
    var
        DemandForecast: TestPage "Demand Forecast Card";
        PeriodType: Enum "Analysis Period Type";
        Name: Code[10];
    begin
        // Purpose of the test is to verify caption on Production Forecast Matrix Page.

        // Setup: Create Production Forecast Name and generate Column Captions.
        Initialize();
        Name := CreateProductionForeCastName();
        GeneratePeriodMatrixData();
        DemandForecast.OpenEdit();
        DemandForecast.Name.SetValue(Name);

        // Exercise: Set Period Type on Production Forecast Page.
        DemandForecast."View By".SetValue(PeriodType::Month);

        // Verify: Verify Column Captions on Production Forecast Matrix Page.
        VerifyCaptionJanToJune(DemandForecast.Matrix.Field1.Caption, DemandForecast.Matrix.Field2.Caption, DemandForecast.Matrix.Field3.Caption, DemandForecast.Matrix.Field4.Caption, DemandForecast.Matrix.Field5.Caption, DemandForecast.Matrix.Field6.Caption);
        VerifyCaptionJulToDec(DemandForecast.Matrix.Field7.Caption, DemandForecast.Matrix.Field8.Caption, DemandForecast.Matrix.Field9.Caption, DemandForecast.Matrix.Field10.Caption, DemandForecast.Matrix.Field11.Caption, DemandForecast.Matrix.Field12.Caption);
        DemandForecast.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee."No." := LibraryUTUtility.GetNewCode();
        Employee.Insert();
        exit(Employee."No.");
    end;

    local procedure CreateJob(ResourceFilter: Code[20]; ResourceGrFilter: Code[20]): Code[20]
    var
        Job: Record Job;
    begin
        Job."No." := LibraryUTUtility.GetNewCode();
        Job."Resource Filter" := ResourceFilter;
        Job."Resource Gr. Filter" := ResourceGrFilter;
        Job.Insert();
        exit(Job."No.");
    end;

    local procedure CreateMachineCenter(): Code[20]
    var
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter."No." := LibraryUTUtility.GetNewCode();
        MachineCenter.Insert();
        exit(MachineCenter."No.");
    end;

    local procedure CreateOpportunity(): Code[20]
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity."No." := LibraryUTUtility.GetNewCode();
        Opportunity.Insert();
        exit(Opportunity."No.");
    end;

    local procedure CreateProductionForeCastName(): Code[10]
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        ProductionForecastName.Name := LibraryUTUtility.GetNewCode10();
        ProductionForecastName.Insert();
        exit(ProductionForecastName.Name);
    end;

    local procedure CreateResource(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource."No." := LibraryUTUtility.GetNewCode();
        Resource.Insert();
        exit(Resource."No.");
    end;

    local procedure CreateResourceGroup(): Code[20]
    var
        ResourceGroup: Record "Resource Group";
    begin
        ResourceGroup."No." := LibraryUTUtility.GetNewCode();
        ResourceGroup.Insert();
        exit(ResourceGroup."No.");
    end;

    local procedure CreateServiceOrder(ResourceFilter: Code[20]; ResourceGroupFilter: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Resource Filter" := ResourceFilter;
        ServiceHeader."Resource Group Filter" := ResourceGroupFilter;
        ServiceHeader.Insert();
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceOrderAllocation(ResourceNo: Code[20]; ResourceGroupNo: Code[20]; DocumentNo: Code[20])
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServiceOrderAllocation2: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation."Entry No." := 1;
        if ServiceOrderAllocation2.FindLast() then
            ServiceOrderAllocation."Entry No." := ServiceOrderAllocation2."Entry No." + 1;
        ServiceOrderAllocation.Status := ServiceOrderAllocation.Status::Active;
        ServiceOrderAllocation."Resource No." := ResourceNo;
        ServiceOrderAllocation."Resource Group No." := ResourceGroupNo;
        ServiceOrderAllocation."Document Type" := ServiceOrderAllocation."Document Type"::Order;
        ServiceOrderAllocation."Document No." := DocumentNo;
        ServiceOrderAllocation.Insert();
    end;

    local procedure CreateToDos(): Code[20]
    var
        ToDo: Record "To-do";
    begin
        ToDo."No." := LibraryUTUtility.GetNewCode();
        ToDo.Type := ToDo.Type::Meeting;
        ToDo.Priority := ToDo.Priority::Normal;
        ToDo.Date := WorkDate();
        ToDo."Start Time" := Time;
        ToDo."Ending Date" := WorkDate();
        ToDo."Ending Time" := Time;
        ToDo.Insert();
        exit(ToDo."No.");
    end;

    local procedure CreateWorkCenter(): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter."No." := LibraryUTUtility.GetNewCode();
        WorkCenter.Insert();
        exit(WorkCenter."No.");
    end;

    local procedure CreateWorkCenterGroup(): Code[10]
    var
        WorkCenterGroup: Record "Work Center Group";
    begin
        WorkCenterGroup.Code := LibraryUTUtility.GetNewCode10();
        WorkCenterGroup.Insert();
        exit(WorkCenterGroup.Code);
    end;

    local procedure DequeueText(): Text[200]
    var
        ExpectedValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedValue);  // Dequeue Code or Text type variable.
        exit(Format(ExpectedValue));
    end;

    local procedure EnqueueCaptionJanToJune(MatrixColumnCaptions: Text[200]; MatrixColumnCaptions2: Text[200]; MatrixColumnCaptions3: Text[200]; MatrixColumnCaptions4: Text[200]; MatrixColumnCaptions5: Text[200]; MatrixColumnCaptions6: Text[200])
    begin
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions2);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions3);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions4);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions5);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions6);
    end;

    local procedure EnqueueCaptionJulToDec(MatrixColumnCaptions: Text[200]; MatrixColumnCaptions2: Text[200]; MatrixColumnCaptions3: Text[200]; MatrixColumnCaptions4: Text[200]; MatrixColumnCaptions5: Text[200]; MatrixColumnCaptions6: Text[200])
    begin
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions2);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions3);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions4);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions5);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions6);
    end;

    local procedure GeneratePeriodMatrixData()
    var
        MatrixRecords: array[32] of Record Date;
        MatrixManagement: Codeunit "Matrix Management";
        ColumnSet: Text;
        MatrixColumnCaptions: array[32] of Text[80];
        PrimaryKeyFirstRecordInCurrentSet: Text;
        SetPosition: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        CurrentSetLength: Integer;
    begin
        MatrixManagement.GeneratePeriodMatrixData(
          SetPosition, ArrayLen(MatrixRecords), false, "Analysis Period Type"::Month, '', PrimaryKeyFirstRecordInCurrentSet, MatrixColumnCaptions,
          ColumnSet,
          CurrentSetLength, MatrixRecords);  // Using Blank for DateFilter.
        EnqueueCaptionJanToJune(
          MatrixColumnCaptions[1], MatrixColumnCaptions[2], MatrixColumnCaptions[3],
          MatrixColumnCaptions[4], MatrixColumnCaptions[5], MatrixColumnCaptions[6]);
        EnqueueCaptionJulToDec(
          MatrixColumnCaptions[7], MatrixColumnCaptions[8], MatrixColumnCaptions[9],
          MatrixColumnCaptions[10], MatrixColumnCaptions[11], MatrixColumnCaptions[12]);
    end;

    local procedure OpenMachineCenterCalendarPage(var MachineCenterCalendar: TestPage "Machine Center Calendar"; No: Code[20])
    var
        MachineCenterCard: TestPage "Machine Center Card";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        MachineCenterCard.OpenEdit();
        MachineCenterCard.FILTER.SetFilter("No.", No);
        MachineCenterCalendar.Trap();
        MachineCenterCard."&Calendar".Invoke();
        MachineCenterCalendar.PeriodType.SetValue(PeriodType::Month);
        MachineCenterCard.Close();
    end;

    local procedure OpenResAllocPerServiceOrderPage(var ResAllocPerServiceOrder: TestPage "Res. Alloc. per Service Order"; No: Code[20])
    var
        ResourceCard: TestPage "Resource Card";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", No);
        ResAllocPerServiceOrder.Trap();
        ResourceCard."Resource Allocated per Service &Order".Invoke();
        ResAllocPerServiceOrder.PeriodType.SetValue(PeriodType::Month);
        ResourceCard.Close();
    end;

    local procedure OpenResGrAllocatedPerJobPage(var ResGrAllocatedPerJob: TestPage "Res. Gr. Allocated per Job"; No: Code[20])
    var
        ResourceGroups: TestPage "Resource Groups";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", No);
        ResGrAllocatedPerJob.Trap();
        ResourceGroups."Res. Group All&ocated per Job".Invoke();
        ResGrAllocatedPerJob.PeriodType.SetValue(PeriodType::Month);
        ResourceGroups.Close();
    end;

    local procedure OpenResGrAllocPerServOrderPage(var ResGrAllocPerServOrder: TestPage "Res. Gr. Alloc. per Serv Order"; No: Code[20])
    var
        ResourceGroups: TestPage "Resource Groups";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        ResourceGroups.OpenEdit();
        ResourceGroups.FILTER.SetFilter("No.", No);
        ResGrAllocPerServOrder.Trap();
        ResourceGroups."Res. Group Allocated per Service &Order".Invoke();
        ResGrAllocPerServOrder.PeriodType.SetValue(PeriodType::Month);
        ResourceGroups.Close();
    end;

    local procedure OpenResourceAllocatedPerJobPage(var ResourceAllocatedPerJob: TestPage "Resource Allocated per Job"; No: Code[20])
    var
        ResourceCard: TestPage "Resource Card";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", No);
        ResourceAllocatedPerJob.Trap();
        ResourceCard."Resource &Allocated per Job".Invoke();
        ResourceAllocatedPerJob.PeriodType.SetValue(PeriodType::Month);
        ResourceCard.Close();
    end;

    local procedure OpenResourceAllocation(DocumentNo: Code[20]; ResourceNo: Code[20])
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceAllocations: TestPage "Resource Allocations";
    begin
        ResourceAllocations.OpenEdit();
        ResourceAllocations.FILTER.SetFilter("Document Type", Format(ServiceOrderAllocation."Document Type"::Order));
        ResourceAllocations.FILTER.SetFilter("Document No.", DocumentNo);
        ResourceAllocations.FILTER.SetFilter("Resource No.", ResourceNo);
        ResourceAllocations.ResourceAvailability.Invoke();
        ResourceAllocations.Close();
    end;

    local procedure OpenResourceAllocationResGroupAvailability(DocumentNo: Code[20]; ResourceGroupNo: Code[20])
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceAllocations: TestPage "Resource Allocations";
    begin
        ResourceAllocations.OpenEdit();
        ResourceAllocations.FILTER.SetFilter("Resource Group No.", ResourceGroupNo);
        ResourceAllocations.FILTER.SetFilter("Document Type", Format(ServiceOrderAllocation."Document Type"::Order));
        ResourceAllocations.FILTER.SetFilter("Document No.", DocumentNo);
        ResourceAllocations.ResGroupAvailability.Invoke();
        ResourceAllocations.Close();
    end;

    local procedure OpenWorkCenterCalendarPage(var WorkCenterCalendar: TestPage "Work Center Calendar"; No: Code[20])
    var
        WorkCenterCard: TestPage "Work Center Card";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        WorkCenterCard.OpenEdit();
        WorkCenterCard.FILTER.SetFilter("No.", No);
        WorkCenterCalendar.Trap();
        WorkCenterCard."&Calendar".Invoke();
        WorkCenterCalendar.PeriodType.SetValue(PeriodType::Month);
        WorkCenterCard.Close();
    end;

    local procedure OpenWorkCenterGroupPage(var WorkCtrGroupCalendar: TestPage "Work Ctr. Group Calendar"; "Code": Code[20])
    var
        WorkCenterGroups: TestPage "Work Center Groups";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        WorkCenterGroups.OpenEdit();
        WorkCenterGroups.FILTER.SetFilter(Code, Code);
        WorkCtrGroupCalendar.Trap();
        WorkCenterGroups.Calendar.Invoke();
        WorkCtrGroupCalendar.PeriodType.SetValue(PeriodType::Month);
    end;

    local procedure VerifyCaptionJanToJune(MatrixColumnCaptions: Text[200]; MatrixColumnCaptions2: Text[200]; MatrixColumnCaptions3: Text[200]; MatrixColumnCaptions4: Text[200]; MatrixColumnCaptions5: Text[200]; MatrixColumnCaptions6: Text[200])
    begin
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions2, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions3, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions4, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions5, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions6, CaptionErr);
    end;

    local procedure VerifyCaptionJulToDec(MatrixColumnCaptions: Text[200]; MatrixColumnCaptions2: Text[200]; MatrixColumnCaptions3: Text[200]; MatrixColumnCaptions4: Text[200]; MatrixColumnCaptions5: Text[200]; MatrixColumnCaptions6: Text[200])
    begin
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions2, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions3, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions4, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions5, CaptionErr);
        Assert.AreEqual(DequeueText(), MatrixColumnCaptions6, CaptionErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AbsOverviewByPeriodMatrixPageHandler(var AbsOverviewByPeriodMatrix: TestPage "Abs. Overview by Period Matrix")
    begin
        AbsOverviewByPeriodMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          AbsOverviewByPeriodMatrix.Field1.Caption, AbsOverviewByPeriodMatrix.Field2.Caption, AbsOverviewByPeriodMatrix.Field3.Caption,
          AbsOverviewByPeriodMatrix.Field4.Caption, AbsOverviewByPeriodMatrix.Field5.Caption, AbsOverviewByPeriodMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          AbsOverviewByPeriodMatrix.Field7.Caption, AbsOverviewByPeriodMatrix.Field8.Caption, AbsOverviewByPeriodMatrix.Field9.Caption,
          AbsOverviewByPeriodMatrix.Field10.Caption, AbsOverviewByPeriodMatrix.Field11.Caption, AbsOverviewByPeriodMatrix.Field12.Caption);
        AbsOverviewByPeriodMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarMatrixPageHandler(var MachineCenterCalendarMatrix: TestPage "Machine Center Calendar Matrix")
    begin
        MachineCenterCalendarMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          MachineCenterCalendarMatrix.Field1.Caption, MachineCenterCalendarMatrix.Field2.Caption,
          MachineCenterCalendarMatrix.Field3.Caption,
          MachineCenterCalendarMatrix.Field4.Caption, MachineCenterCalendarMatrix.Field5.Caption,
          MachineCenterCalendarMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          MachineCenterCalendarMatrix.Field7.Caption, MachineCenterCalendarMatrix.Field8.Caption,
          MachineCenterCalendarMatrix.Field9.Caption,
          MachineCenterCalendarMatrix.Field10.Caption, MachineCenterCalendarMatrix.Field11.Caption,
          MachineCenterCalendarMatrix.Field12.Caption);
        MachineCenterCalendarMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OpportunitiesMatrixPageHandler(var OpportunitiesMatrix: TestPage "Opportunities Matrix")
    begin
        OpportunitiesMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          OpportunitiesMatrix.Field1.Caption, OpportunitiesMatrix.Field2.Caption, OpportunitiesMatrix.Field3.Caption,
          OpportunitiesMatrix.Field4.Caption, OpportunitiesMatrix.Field5.Caption, OpportunitiesMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          OpportunitiesMatrix.Field7.Caption, OpportunitiesMatrix.Field8.Caption, OpportunitiesMatrix.Field9.Caption,
          OpportunitiesMatrix.Field10.Caption, OpportunitiesMatrix.Field11.Caption, OpportunitiesMatrix.Field12.Caption);
        OpportunitiesMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResAllPerServiceMatrixPageHandler(var ResAllPerServiceMatrix: TestPage "Res. All. per Service  Matrix")
    begin
        ResAllPerServiceMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResAllPerServiceMatrix.Col1.Caption, ResAllPerServiceMatrix.Col2.Caption, ResAllPerServiceMatrix.Col3.Caption,
          ResAllPerServiceMatrix.Col4.Caption, ResAllPerServiceMatrix.Col5.Caption, ResAllPerServiceMatrix.Col6.Caption);
        VerifyCaptionJulToDec(
          ResAllPerServiceMatrix.Col7.Caption, ResAllPerServiceMatrix.Col8.Caption, ResAllPerServiceMatrix.Col9.Caption,
          ResAllPerServiceMatrix.Col10.Caption, ResAllPerServiceMatrix.Col11.Caption, ResAllPerServiceMatrix.Col12.Caption);
        ResAllPerServiceMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResAvailabilityServicePageHandler(var ResAvailabilityService: TestPage "Res. Availability (Service)")
    var
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        ResAvailabilityService.PeriodType.SetValue(PeriodType::Month);
        ResAvailabilityService.ShowMatrix.Invoke();
        ResAvailabilityService.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResAvailServiceMatrixPageHandler(var ResAvailServiceMatrix: TestPage "Res. Avail. (Service) Matrix")
    begin
        ResAvailServiceMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResAvailServiceMatrix.Field1.Caption, ResAvailServiceMatrix.Field2.Caption, ResAvailServiceMatrix.Field3.Caption,
          ResAvailServiceMatrix.Field4.Caption, ResAvailServiceMatrix.Field5.Caption, ResAvailServiceMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          ResAvailServiceMatrix.Field7.Caption, ResAvailServiceMatrix.Field8.Caption, ResAvailServiceMatrix.Field9.Caption,
          ResAvailServiceMatrix.Field10.Caption, ResAvailServiceMatrix.Field11.Caption, ResAvailServiceMatrix.Field12.Caption);
        ResAvailServiceMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrAvailabilityServicePageHandler(var ResGrAvailabilityService: TestPage "Res.Gr. Availability (Service)")
    var
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        ResGrAvailabilityService.PeriodType.SetValue(PeriodType::Month);
        ResGrAvailabilityService.ShowMatrix.Invoke();
        ResGrAvailabilityService.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrAvailServMatrixPageHandler(var ResGrAvailServMatrix: TestPage "Res. Gr. Avail. (Serv.) Matrix")
    begin
        ResGrAvailServMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResGrAvailServMatrix.Field1.Caption, ResGrAvailServMatrix.Field2.Caption, ResGrAvailServMatrix.Field3.Caption,
          ResGrAvailServMatrix.Field4.Caption, ResGrAvailServMatrix.Field5.Caption, ResGrAvailServMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          ResGrAvailServMatrix.Field7.Caption, ResGrAvailServMatrix.Field8.Caption, ResGrAvailServMatrix.Field9.Caption,
          ResGrAvailServMatrix.Field10.Caption, ResGrAvailServMatrix.Field11.Caption, ResGrAvailServMatrix.Field12.Caption);
        ResGrAvailServMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrpAllocPerJobMatrixPageHandler(var ResGrpAllocPerJobMatrix: TestPage "ResGrp. Alloc. per Job Matrix")
    begin
        ResGrpAllocPerJobMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResGrpAllocPerJobMatrix.Col1.Caption, ResGrpAllocPerJobMatrix.Col2.Caption, ResGrpAllocPerJobMatrix.Col3.Caption,
          ResGrpAllocPerJobMatrix.Col4.Caption, ResGrpAllocPerJobMatrix.Col5.Caption, ResGrpAllocPerJobMatrix.Col6.Caption);
        VerifyCaptionJulToDec(
          ResGrpAllocPerJobMatrix.Col7.Caption, ResGrpAllocPerJobMatrix.Col8.Caption, ResGrpAllocPerJobMatrix.Col9.Caption,
          ResGrpAllocPerJobMatrix.Col10.Caption, ResGrpAllocPerJobMatrix.Col11.Caption, ResGrpAllocPerJobMatrix.Col12.Caption);
        ResGrpAllocPerJobMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrpAllPerServMatrixPageHandler(var ResGrpAllPerServMatrix: TestPage "ResGrp. All. per Serv.  Matrix")
    begin
        ResGrpAllPerServMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResGrpAllPerServMatrix.Col1.Caption, ResGrpAllPerServMatrix.Col2.Caption, ResGrpAllPerServMatrix.Col3.Caption,
          ResGrpAllPerServMatrix.Col4.Caption, ResGrpAllPerServMatrix.Col5.Caption, ResGrpAllPerServMatrix.Col6.Caption);
        VerifyCaptionJulToDec(
          ResGrpAllPerServMatrix.Col7.Caption, ResGrpAllPerServMatrix.Col8.Caption, ResGrpAllPerServMatrix.Col9.Caption,
          ResGrpAllPerServMatrix.Col10.Caption, ResGrpAllPerServMatrix.Col11.Caption, ResGrpAllPerServMatrix.Col12.Caption);
        ResGrpAllPerServMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceAllocPerJobMatrixPageHandler(var ResourceAllocPerJobMatrix: TestPage "Resource Alloc. per Job Matrix")
    begin
        ResourceAllocPerJobMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ResourceAllocPerJobMatrix.Col1.Caption, ResourceAllocPerJobMatrix.Col2.Caption, ResourceAllocPerJobMatrix.Col3.Caption,
          ResourceAllocPerJobMatrix.Col4.Caption, ResourceAllocPerJobMatrix.Col5.Caption, ResourceAllocPerJobMatrix.Col6.Caption);
        VerifyCaptionJulToDec(
          ResourceAllocPerJobMatrix.Col7.Caption, ResourceAllocPerJobMatrix.Col8.Caption, ResourceAllocPerJobMatrix.Col9.Caption,
          ResourceAllocPerJobMatrix.Col10.Caption, ResourceAllocPerJobMatrix.Col11.Caption, ResourceAllocPerJobMatrix.Col12.Caption);
        ResourceAllocPerJobMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ToDosMatrixPageHandler(var ToDosMatrix: TestPage "Tasks Matrix")
    begin
        ToDosMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          ToDosMatrix.Field1.Caption, ToDosMatrix.Field2.Caption, ToDosMatrix.Field3.Caption,
          ToDosMatrix.Field4.Caption, ToDosMatrix.Field5.Caption, ToDosMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          ToDosMatrix.Field7.Caption, ToDosMatrix.Field8.Caption, ToDosMatrix.Field9.Caption,
          ToDosMatrix.Field10.Caption, ToDosMatrix.Field11.Caption, ToDosMatrix.Field12.Caption);
        ToDosMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarMatrixPageHandler(var WorkCenterCalendarMatrix: TestPage "Work Center Calendar Matrix")
    begin
        WorkCenterCalendarMatrix.FILTER.SetFilter("No.", DequeueText());
        VerifyCaptionJanToJune(
          WorkCenterCalendarMatrix.Field1.Caption, WorkCenterCalendarMatrix.Field2.Caption, WorkCenterCalendarMatrix.Field3.Caption,
          WorkCenterCalendarMatrix.Field4.Caption, WorkCenterCalendarMatrix.Field5.Caption, WorkCenterCalendarMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          WorkCenterCalendarMatrix.Field7.Caption, WorkCenterCalendarMatrix.Field8.Caption, WorkCenterCalendarMatrix.Field9.Caption,
          WorkCenterCalendarMatrix.Field10.Caption, WorkCenterCalendarMatrix.Field11.Caption, WorkCenterCalendarMatrix.Field12.Caption);
        WorkCenterCalendarMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkCtrGrpCalendarMatrixPageHandler(var WorkCtrGrpCalendarMatrix: TestPage "Work Ctr. Grp. Calendar Matrix")
    begin
        WorkCtrGrpCalendarMatrix.FILTER.SetFilter(Code, DequeueText());
        VerifyCaptionJanToJune(
          WorkCtrGrpCalendarMatrix.Field1.Caption, WorkCtrGrpCalendarMatrix.Field2.Caption, WorkCtrGrpCalendarMatrix.Field3.Caption,
          WorkCtrGrpCalendarMatrix.Field4.Caption, WorkCtrGrpCalendarMatrix.Field5.Caption, WorkCtrGrpCalendarMatrix.Field6.Caption);
        VerifyCaptionJulToDec(
          WorkCtrGrpCalendarMatrix.Field7.Caption, WorkCtrGrpCalendarMatrix.Field8.Caption, WorkCtrGrpCalendarMatrix.Field9.Caption,
          WorkCtrGrpCalendarMatrix.Field10.Caption, WorkCtrGrpCalendarMatrix.Field11.Caption, WorkCtrGrpCalendarMatrix.Field12.Caption);
        WorkCtrGrpCalendarMatrix.OK().Invoke();
    end;
}

