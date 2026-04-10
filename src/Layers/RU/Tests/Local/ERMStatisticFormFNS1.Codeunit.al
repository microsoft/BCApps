codeunit 147150 "ERM Statistic Form FNS-1"
{
    // // [FEATURE] [Employee] [Statistics] [Export EXCEL]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        TempItemJournalBuffer: Record "Item Journal Buffer" temporary;
        StatisticFormFNS1: Report "Statistic Form FNS-1";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        ResponsibleEmployeeNo: Code[20];
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('StatisticFormFNS1_RPH')]
    [Scope('OnPrem')]
    procedure EmployeesStatistics()
    var
        StatisticalLines: Integer;
    begin
        // [SCENARIO TFS=127423.1] Verify report data (Sheet2) when there are employees in all salary categories
        Initialize();

        // [GIVEN] Statistics for all 21 categories of employees
        StatisticalLines := 21;
        ResponsibleEmployeeNo := CreateResponsibleEmployee;
        CreateEmployeeStatisticalBuffer(StatisticalLines);
        // [WHEN] Statistic Form FNS-1 is created
        RunStatisticReport;

        // [THEN] The EXCEL report contains information about the number and the total salary of the employees of each salary category
        VerifyStatisticReportFNS1;
    end;

    local procedure Initialize()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        if IsInitialized then
            exit;

        HumanResourcesSetup.Get();
        if HumanResourcesSetup."FSN-1 Template Code" = '' then begin
            HumanResourcesSetup.Validate("FSN-1 Template Code", 'FSN 1');
            HumanResourcesSetup.Modify(true);
        end;

        IsInitialized := true;
    end;

    local procedure CreateResponsibleEmployee(): Code[20]
    var
        ResponsibleEmployee: Record Employee;
    begin
        LibraryHumanResource.CreateEmployee(ResponsibleEmployee);

        with ResponsibleEmployee do begin
            Validate("First Name", LibraryUtility.GenerateRandomXMLText(MaxStrLen("First Name")));
            Validate("Middle Name", LibraryUtility.GenerateRandomXMLText(MaxStrLen("Middle Name")));
            Validate("Last Name", LibraryUtility.GenerateRandomXMLText(MaxStrLen("Last Name")));
            Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
            Validate("Phone No.", LibraryUtility.GenerateRandomXMLText(MaxStrLen("Phone No.")));
            Validate("Job Title", LibraryUtility.GenerateRandomXMLText(MaxStrLen("Job Title")));
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure RunStatisticReport()
    var
        ResponsibleEmployee: Record Employee;
    begin
        StatisticFormFNS1.UseRequestPage(true);
        ResponsibleEmployee.Get(ResponsibleEmployeeNo);
        StatisticFormFNS1.SetSilentResponsibleEmployee(ResponsibleEmployee);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        StatisticFormFNS1.SetSilentFilename(LibraryReportValidation.GetFileName());
        StatisticFormFNS1.SetSilentEmployeeStatisticalBuffer(TempItemJournalBuffer);
        Commit();
        StatisticFormFNS1.Run();
    end;

    local procedure CreateEmployeeStatisticalBuffer(StatisticalLines: Integer)
    var
        I: Integer;
    begin
        TempItemJournalBuffer.Reset();
        TempItemJournalBuffer.DeleteAll();

        for I := 0 to StatisticalLines + 1 do begin
            TempItemJournalBuffer.Init();
            TempItemJournalBuffer."Line No." := I;
            TempItemJournalBuffer.Quantity := LibraryRandom.RandInt(100);
            TempItemJournalBuffer."Inventory Value (Calculated)" := LibraryRandom.RandIntInRange(5000, 10000000);
            TempItemJournalBuffer.Insert();
        end;
    end;

    local procedure VerifyStatisticReportFNS1()
    var
        StartLine: Integer;
        StatisticalLines: Integer;
        I: Integer;
    begin
        // Verify values on Sheet2
        StartLine := 35;
        StatisticalLines := 21;

        for I := StartLine to StatisticalLines + StartLine do begin
            TempItemJournalBuffer.Get(I - StartLine);
            LibraryReportValidation.VerifyCellValueOnWorksheet(I, 48, Format(TempItemJournalBuffer.Quantity), '2');
            LibraryReportValidation.VerifyCellValueOnWorksheet(
              I, 80, FormatValue(TempItemJournalBuffer."Inventory Value (Calculated)"), '2');
        end;

        TempItemJournalBuffer.Get(StatisticalLines + 1); // Contains the number of employees with salary below the minimum wage
        LibraryReportValidation.VerifyCellValueOnWorksheet(59, 55, Format(TempItemJournalBuffer.Quantity), '2');

        VerifyResponsibleEmployeeInfo;
    end;

    local procedure VerifyResponsibleEmployeeInfo()
    var
        ResponsibleEmployee: Record Employee;
        ResponsibleEmployeeFullName: Text;
    begin
        ResponsibleEmployee.Get(ResponsibleEmployeeNo);

        with ResponsibleEmployee do begin
            LibraryReportValidation.VerifyCellValueOnWorksheet(71, 48, "Phone No.", '2');
            LibraryReportValidation.VerifyCellValueOnWorksheet(71, 82, "E-Mail", '2');
            LibraryReportValidation.VerifyCellValueOnWorksheet(68, 48, "Job Title", '2');
            ResponsibleEmployeeFullName := "First Name" + ' ' + "Middle Name" + ' ' + "Last Name";
            LibraryReportValidation.VerifyCellValueOnWorksheet(68, 83, ResponsibleEmployeeFullName, '2');
        end;
    end;

    local procedure FormatValue(Value: Decimal): Text
    begin
        exit(LibraryReportValidation.FormatDecimalValue(Value));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatisticFormFNS1_RPH(var StatisticFormFNS1: TestRequestPage "Statistic Form FNS-1")
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := DMY2Date(1, 4, Date2DMY(WorkDate(), 3));
        EndDate := CalcDate('<CM>', StartDate);
        StatisticFormFNS1.StartDate.SetValue(StartDate);
        StatisticFormFNS1.EndDate.SetValue(EndDate);
        StatisticFormFNS1.OK().Invoke();
    end;
}

