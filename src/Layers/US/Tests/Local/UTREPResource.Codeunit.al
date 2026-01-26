codeunit 144001 "UT REP Resource"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource] [Reports]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('CostBreakdownRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCostBreakdown()
    var
        Resource: Record Resource;
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10195 - Cost Breakdown.

        // Setup: Create Resource and Resource Ledger Entry.
        Initialize();
        CreateResource(Resource);
        CreateResourceLedgerEntry(ResLedgerEntry, Resource."No.");

        // Exercise.
        REPORT.Run(REPORT::"Cost Breakdown");

        // Verify: Verify Resource No and TotalDirectCost on Report Cost Breakdown.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Resource_No_', ResLedgerEntry."Resource No.");
        LibraryReportDataset.AssertElementWithValueExists('TotalDirectCost', ResLedgerEntry.Quantity * ResLedgerEntry."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ResourceRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordResourceRegister()
    var
        ResourceRegister: Record "Resource Register";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Resource Register, Trigger of Report 10198 - Resource Register.

        // Setup: Create Resource, Resource Ledger Entry and Resource Register.
        Initialize();
        CreateResourceLedgerEntry(ResLedgerEntry, LibraryUTUtility.GetNewCode());
        CreateResourceRegister(ResourceRegister, ResLedgerEntry."Entry No.");
        ResourceRegister."Source Code" := LibraryUTUtility.GetNewCode10();
        ResourceRegister.Modify();

        // Exercise.
        REPORT.Run(REPORT::"Resource Register");

        // Verify: Verify SourceCodeText on Report Resource Register.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('SourceCodeText', StrSubstNo('Source Code: %1', ResourceRegister."Source Code"));
    end;

    [Test]
    [HandlerFunctions('ResourceRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordResLedgerEntryResourceRegister()
    var
        ResourceRegister: Record "Resource Register";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - ResLedgerEntry, Trigger of Report 10198 - Resource Register.

        // Setup: Create Resource, Resource Ledger Entry and Resource Register.
        Initialize();
        CreateResourceLedgerEntry(ResLedgerEntry, LibraryUTUtility.GetNewCode());
        ResLedgerEntry.Description := 'Description';
        ResLedgerEntry.Modify();
        CreateResourceRegister(ResourceRegister, ResLedgerEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"Resource Register");

        // Verify: Verify ResDescription on Report Resource Register.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ResDescription', ResLedgerEntry.Description);
    end;

    [Test]
    [HandlerFunctions('ResourceListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportResourceList()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10197 - Resource List.

        // Setup: Create Resource and run report - Resource List.
        Initialize();
        RunResourceReport(REPORT::"Resource List");
    end;

    [Test]
    [HandlerFunctions('ResourceStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportResourceStatistics()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10199 - Resource Statistics.

        // Setup: Create Resource and run report - Resource Statistics.
        Initialize();
        RunResourceReport(REPORT::"Resource Statistics");
    end;

    [Test]
    [HandlerFunctions('ResourceUsageRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportResourceUsage()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10200 - Resource Usage.

        // Setup: Create Resource and run report - Resource Usage.
        Initialize();
        RunResourceReport(REPORT::"Resource Usage");
    end;

    local procedure RunResourceReport(ReportID: Integer)
    var
        Resource: Record Resource;
    begin
        CreateResource(Resource);

        // Exercise: Run report - Resource List, Resource Statistics, Resource Usage.
        REPORT.Run(ReportID);

        // Verify: Verify Resource No and Resource filter on generated xml file.
        VerifyResourceReports(Resource."No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateResource(var Resource: Record Resource)
    begin
        Resource."No." := LibraryUTUtility.GetNewCode();
        Resource.Insert();
        LibraryVariableStorage.Enqueue(Resource."No.");  // Enqueue for Request Page Handler.
    end;

    local procedure CreateResourceLedgerEntry(var ResLedgerEntry: Record "Res. Ledger Entry"; ResourceNo: Code[20])
    begin
        ResLedgerEntry."Entry No." := SelectResourceLedgerEntryNo();
        ResLedgerEntry."Entry Type" := ResLedgerEntry."Entry Type"::Usage;
        ResLedgerEntry."Resource No." := ResourceNo;
        ResLedgerEntry.Quantity := LibraryRandom.RandDec(10, 2);
        ResLedgerEntry."Direct Unit Cost" := LibraryRandom.RandDec(10, 2);
        ResLedgerEntry.Insert();
    end;

    local procedure CreateResourceRegister(var ResourceRegister: Record "Resource Register"; EntryNo: Integer)
    begin
        ResourceRegister."No." := SelectResourceRegisterNo();
        ResourceRegister."From Entry No." := EntryNo;
        ResourceRegister."To Entry No." := EntryNo;
        ResourceRegister.Insert();
        LibraryVariableStorage.Enqueue(ResourceRegister."No.");  // Enqueue for Request Page Handler- ResourceRegisterRequestPageHandler
    end;

    local procedure SelectResourceLedgerEntryNo(): Integer
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        if ResLedgerEntry.FindLast() then
            exit(ResLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectResourceRegisterNo(): Integer
    var
        ResourceRegister: Record "Resource Register";
    begin
        if ResourceRegister.FindLast() then
            exit(ResourceRegister."No." + 1);
        exit(1);
    end;

    local procedure VerifyResourceReports(ResourceNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Resource__No__', ResourceNo);
        LibraryReportDataset.AssertElementWithValueExists('ResFilter', StrSubstNo('No.: %1', ResourceNo));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostBreakdownRequestPageHandler(var CostBreakdown: TestRequestPage "Cost Breakdown")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CostBreakdown.Resource.SetFilter("No.", No);
        CostBreakdown.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListRequestPageHandler(var ResourceList: TestRequestPage "Resource List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ResourceList.Resource.SetFilter("No.", No);
        ResourceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceRegisterRequestPageHandler(var ResourceRegister: TestRequestPage "Resource Register")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ResourceRegister."Resource Register".SetFilter("No.", Format(No));  // Format required for Integer value.
        ResourceRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceStatisticsRequestPageHandler(var ResourceStatistics: TestRequestPage "Resource Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ResourceStatistics.Resource.SetFilter("No.", No);
        ResourceStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ResourceUsageRequestPageHandler(var ResourceUsage: TestRequestPage "Resource Usage")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ResourceUsage.Resource.SetFilter("No.", No);
        ResourceUsage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

