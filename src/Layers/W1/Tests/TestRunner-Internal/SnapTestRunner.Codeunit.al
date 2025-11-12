codeunit 130200 "Snap Test Runner"
{
    // This runner is used in the SNAP queues.

    Subtype = TestRunner;
    TestIsolation = Codeunit;
    Permissions = tabledata "Test Runner Argument" = rmid,
                  tabledata "Test Coverage Map" = rmid,
                  tabledata "Enabled Test Codeunit" = rmid,
                  tabledata "Test Result" = rmid,
                  tabledata "Enabled Test Method" = rmid,
                  tabledata "Disabled Test Method" = rmid,
                  tabledata AllObjWithCaption = rmid;

    trigger OnRun()
    var
        TestRunnerArgument: Record "Test Runner Argument";
    begin
        ProduceTCM := TestRunnerArgument.Get('producetestcoveragemap');
        RunTests(TestRunnerArgument.Get('parallel'), false)
    end;

    var
        TestCoverageMap: Record "Test Coverage Map";
        BackupMgt: Codeunit "Backup Management";
        LibraryRandom: Codeunit "Library - Random";
        PermissionTestCatalog: Codeunit "Permission Test Catalog";
        CompanyWorkDate: Date;
        StartTime: Time;
        TempFilePath: Text;
        TestRunNo: Integer;
        FilePath: Label '%1\%2.altesttmp', Comment = 'file path';
        ProduceTCM: Boolean;
        TestAlreadyAssignedToTenantErr: Label 'Test already started by another tenant.';

    [Scope('OnPrem')]
    procedure RunTests(Concurrent: Boolean; BackupRestore: Boolean)
    var
        EnabledTestCodeunit: Record "Enabled Test Codeunit";
        AllObjWithCaption: Record AllObjWithCaption;
        TestProxy: Codeunit "Test Proxy";
        Enabled: Boolean;
    begin
        Initialize();

        if ProduceTCM then
            ClearTestCoverageMap();

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", 'Test');

        TestProxy.Initialize();

        if EnabledTestCodeunit.FindSet() then
            repeat
                // we are only running test codenits
                AllObjWithCaption.SetRange("Object ID", EnabledTestCodeunit."Test Codeunit ID");
                Enabled := not AllObjWithCaption.IsEmpty();

                // in concurrent mode, we also need to acquire a lock
                if Enabled and Concurrent then
                    Enabled := Lock(EnabledTestCodeunit."Test Codeunit ID");
                if Enabled then
                    RunTestCodeunit(EnabledTestCodeunit."Test Codeunit ID", BackupRestore);
            until EnabledTestCodeunit.Next() = 0;

        if ProduceTCM then
            ExportTestCoverageMap();
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        TestResult: Record "Test Result";
    begin
        TestRunNo := TestResult.LastTestRunNo() + 1;
        CompanyWorkDate := WorkDate()
    end;

    [Scope('OnPrem')]
    procedure GetTempFilePath(): Text
    var
        SystemIOPath: DotNet Path;
    begin
        if TempFilePath = '' then
            TempFilePath := SystemIOPath.GetTempPath();

        exit(TempFilePath)
    end;

    local procedure Lock(CUId: Integer): Boolean
    var
        LockFile: File;
        TestAssignedToTenantFile: File;
        LockFileName: Text;
        TestAssignedToTenantFileName: Text;
        Acquired: Boolean;
    begin
        LockFileName := StrSubstNo(FilePath, GetTempFilePath(), CUId);
        TestAssignedToTenantFileName := StrSubstNo(FilePath, GetTempFilePath(), StrSubstNo('%1_Assigned', CUId));

        // File operations are not atomic, so this may still go wrong.
        Commit();
        asserterror
        begin
            LockFile.Create(LockFileName);

            if FILE.Exists(TestAssignedToTenantFileName) then
                Error(TestAlreadyAssignedToTenantErr);
            TestAssignedToTenantFile.Create(TestAssignedToTenantFileName);
            TestAssignedToTenantFile.Close();

            LockFile.Close();
            Error('Acquired')
        end;

        // If we did not acquire the lock, we assume somebody else did and return false.
        Acquired := GetLastErrorText = 'Acquired';
        ClearLastError();
        exit(Acquired)
    end;

    local procedure RunTestCodeunit(CUId: Integer; EnableRestore: Boolean)
    var
        BackupStorage: Codeunit "Backup Storage";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
    begin
        BackupMgt.SetEnabled(EnableRestore);

        if EnableRestore then begin
            BackupMgt.DefaultFixture();
            Commit();
        end;

        if ProduceTCM then
            CodeCoverageLog(true, false);

        AzureKeyVaultTestLibrary.ClearSecrets(); // Cleanup key vault cache

        Codeunit.Run(CUId);
        BackupStorage.SetWorkDate();

        if ProduceTCM then begin
            CodeCoverageLog(false, false);
            ExportCodeCoverageDetails(CUId);
            UpdateTestCoverageMap(CUId);
        end;
    end;

    local procedure ClearTestCoverageMap()
    begin
        TestCoverageMap.DeleteAll();
        Commit();
    end;

    local procedure UpdateTestCoverageMap(TestCodeunitID: Integer)
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Object);
        if CodeCoverage.FindSet() then
            repeat
                TestCoverageMap.Init();
                TestCoverageMap."Test Codeunit ID" := TestCodeunitID;
                TestCoverageMap."Object Type" := CodeCoverage."Object Type";
                TestCoverageMap."Object ID" := CodeCoverage."Object ID";
                TestCoverageMap.Insert();
            until CodeCoverage.Next() = 0;

        Commit();
    end;

    local procedure ExportTestCoverageMap()
    var
        TestRunnerArgument: Record "Test Runner Argument";
        TestCoverageMap2: XMLport "Test Coverage Map";
        File: File;
        OutStream: OutStream;
    begin
        File.Create(
          TestRunnerArgument.TryGet('producetestcoveragemap') +
          StrSubstNo('_%1.txt', BackupMgt.GetDatabase()));
        File.CreateOutStream(OutStream);
        TestCoverageMap2.SetDestination(OutStream);
        TestCoverageMap2.ImportFile(false);
        TestCoverageMap2.Export();
        File.Close();
    end;

    local procedure ExportCodeCoverageDetails(TestCodeunitID: Integer)
    var
        TestRunnerArgument: Record "Test Runner Argument";
        CodeCoverageDetailed: XMLport "Code Coverage Internal";
        File: File;
        OutStream: OutStream;
    begin
        File.Create(
          TestRunnerArgument.TryGet('producetestcoveragemap') +
          StrSubstNo('_%1_%2.dat', BackupMgt.GetDatabase(), TestCodeunitID));
        File.CreateOutStream(OutStream);
        CodeCoverageDetailed.SetDestination(OutStream);
        CodeCoverageDetailed.ImportFile(false);
        CodeCoverageDetailed.Export();
        File.Close();
    end;

    [Scope('OnPrem')]
    procedure GetCallStack(No: Integer) CallStackText: Text
    var
        TestResult: Record "Test Result";
        InStr: InStream;
    begin
        TestResult.Get(No);
        TestResult.CalcFields("Call Stack");
        TestResult."Call Stack".CreateInStream(InStr);
        InStr.ReadText(CallStackText)
    end;

    [Scope('OnPrem')]
    procedure OnBeforeTestRunImpl(CUId: Integer; CUName: Text[30]; FName: Text[128]; FTestPermissions: TestPermissions): Boolean
    var
        TestResult: Record "Test Result";
        EnabledTestMethod: Record "Enabled Test Method";
        DisabledTestMethod: Record "Disabled Test Method";
        TestProxy: Codeunit "Test Proxy";
    begin
        StartTime := Time;
        WorkDate := CompanyWorkDate;

        if FName = '' then
            exit(true);

        if DisabledTestMethod.Get(CUId, '*') then
            exit(false);

        If DisabledTestMethod.Get(CUId, FName) then
            exit(false);

        EnabledTestMethod.SetRange("Test Codeunit ID", CUId);
        if EnabledTestMethod.FindFirst() and (not EnabledTestMethod.Get(CUId, FName)) then
            exit(false);

        ClearLastError();
        LibraryRandom.SetSeed(1);
        ApplicationArea('');
        BindStopSystemTableChanges();

        TestResult.Create(TestRunNo, CUId, CUName, FName);

        TestProxy.InvokeOnBeforeTestFunctionRun(CUId, CUName, FName, FTestPermissions);

        // todo: move to subscribers
        Clear(PermissionTestCatalog);
        if FName <> 'OnRun' then
            PermissionTestCatalog.InitializePermissionSetForTest(FTestPermissions);

        exit(true)
    end;

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    begin
        exit(OnBeforeTestRunImpl(CUId, CUName, FName, FTestPermissions));
    end;

    [Scope('OnPrem')]
    procedure OnAfterTestRunImpl(CUId: Integer; CUName: Text[30]; FName: Text[128]; FTestPermissions: TestPermissions; Success: Boolean)
    var
        TestResult: Record "Test Result";
        TestProxy: Codeunit "Test Proxy";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        EndTime: Time;
        PermissionErrors: Text;
    begin
        if FName = '' then
            exit;
        EndTime := Time;

        TestResult.FindLast();
        if (FName = 'OnRun') and Success then begin
            TestResult.Delete();
            exit;
        end;

        TestProxy.InvokeOnAfterTestFunctionRun(CUId, CUName, FName, FTestPermissions, Success);

        // todo: move to subscribers
        if (FName <> '') and (FName <> 'OnRun') then begin
            PermissionErrors := PermissionTestCatalog.GetPermissionErrors(FTestPermissions);
            if Success and (PermissionErrors <> '') then begin
                asserterror Error(PermissionErrors);
                Success := false;
            end;
        end;

        LibraryNotificationMgt.ClearTemporaryNotificationContext();

        // Make sure a call to DefaultFixture is made before any test in the codeunit is run
        // Assert.IsTrue(BackupMgt.GetExecutionFlag,STRSUBSTNO(NOBACKUPMGMTCALL,CUId,FName));
        TestResult.Update(Success, EndTime - StartTime, BackupMgt.GetExecutionFlag());
        BackupMgt.ClearExecutionFlag();

        ApplicationArea('');
    end;

    procedure BindStopSystemTableChanges()
    var
        AllObj: Record AllObj;
        BlockChangestoSystemTables: Integer;
    begin
        BlockChangestoSystemTables := 132553; // codeunit 132553 "Block Changes to System Tables"
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.SetRange("Object ID", BlockChangestoSystemTables);
        if not AllObj.IsEmpty() then
            Codeunit.Run(BlockChangestoSystemTables);
    end;


    trigger OnAfterTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions; Success: Boolean)
    begin
        OnAfterTestRunImpl(CUId, CUName, FName, FTestPermissions, Success);
    end;
}

