codeunit 130207 "Duplicate Method Test Runner"
{
    SingleInstance = false;
    Subtype = TestRunner;

    trigger OnRun()
    var
        AllObj: Record AllObj;
        PreviousCodeunitID: Integer;
        i: Integer;
    begin
        CompanyWorkDate := WorkDate();
        PreviousCodeunitID := -1;

        TestRunNo := TestResult.LastTestRunNo() + 1;

        // Populate Enabled Test Methods table
        CODEUNIT.Run(CODEUNIT::"Test Runner Generator");

        EnabledTestMethod.Reset();

        // Execute methods
        if EnabledTestMethod.FindSet() then
            repeat
                if AllObj.Get(AllObj."Object Type"::Codeunit, EnabledTestMethod."Test Codeunit ID") then begin
                    // every time the codeunit id changes restore backup
                    if PreviousCodeunitID <> EnabledTestMethod."Test Codeunit ID" then begin
                        // Restore backup in between codeunits only - prevent restoration in the same CU as it will be called multiple twice
                        BackupMgt.SetEnabled(true);
                        BackupMgt.DefaultFixture();
                        BackupMgt.SetEnabled(false);

                        PreviousCodeunitID := EnabledTestMethod."Test Codeunit ID";
                    end;

                    // run enabled test codeunit 3 times per each method
                    for i := 0 to 2 do
                        CODEUNIT.Run(EnabledTestMethod."Test Codeunit ID");
                end;
            until EnabledTestMethod.Next() = 0;
    end;

    var
        TestResult: Record "Test Result";
        EnabledTestMethod: Record "Enabled Test Method";
        BackupMgt: Codeunit "Backup Management";
        CompanyWorkDate: Date;
        StartTime: Time;
        TestRunNo: Integer;

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    var
        TestResult: Record "Test Result";
    begin
        StartTime := Time;
        WorkDate := CompanyWorkDate;

        if FName = '' then
            exit(true);

        ClearLastError();

        // always run OnRun
        if FName = 'OnRun' then begin
            TestResult.Create(TestRunNo, CUId, CUName, FName);
            exit(true)
        end;

        // Is method to be executed?
        if FName <> EnabledTestMethod."Test Method Name" then
            exit(false);

        TestResult.Create(TestRunNo, CUId, CUName, FName);
        exit(true)
    end;

    trigger OnAfterTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions; Success: Boolean)
    var
        TestResult: Record "Test Result";
        EndTime: Time;
    begin
        if FName = '' then
            exit;
        EndTime := Time;

        TestResult.FindLast();
        if (FName = 'OnRun') and Success then begin
            TestResult.Delete();
            exit;
        end;

        TestResult.Update(Success, EndTime - StartTime, BackupMgt.GetExecutionFlag());

        if FName = '' then
            exit;
    end;
}

