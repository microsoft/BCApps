codeunit 130206 "Random Test Runner"
{
    SingleInstance = false;
    Subtype = TestRunner;

    trigger OnRun()
    var
        AllObj: Record AllObj;
        EnabledTestCodeunit: Record "Enabled Test Codeunit";
        NoOfMethods: Integer;
    begin
        CompanyWorkDate := WorkDate();
        TestRunNo := TestResult.LastTestRunNo() + 1;

        // Populate the Enabled Test methods table
        CODEUNIT.Run(CODEUNIT::"Test Runner Generator");

        EnabledTestCodeunit.Reset();

        // Execute codeunits
        if EnabledTestCodeunit.FindSet() then
            repeat
                if AllObj.Get(AllObj."Object Type"::Codeunit, EnabledTestCodeunit."Test Codeunit ID") then begin
                    // Restore backup in between codeunits
                    BackupMgt.SetEnabled(true);
                    BackupMgt.DefaultFixture();
                    BackupMgt.SetEnabled(false);

                    // Copy enabled methods to temp
                    CopyToTemp(EnabledTestCodeunit."Test Codeunit ID");
                    TempEnabledTestMethod.Reset();
                    NoOfMethods := TempEnabledTestMethod.Count();

                    // Execute methods
                    while NoOfMethods > 0 do begin
                        // Pick method randomly
                        Randomize();
                        TempEnabledTestMethod.Next(Random(TempEnabledTestMethod.Count));

                        // Execute Test CU
                        CODEUNIT.Run(TempEnabledTestMethod."Test Codeunit ID");

                        // Remove enabled method after executed
                        TempEnabledTestMethod.Delete(true);

                        // Clear for a new iteration
                        Clear(TempEnabledTestMethod);
                        NoOfMethods -= 1;
                    end;
                end;
            until EnabledTestCodeunit.Next() = 0;
    end;

    var
        TestResult: Record "Test Result";
        TempEnabledTestMethod: Record "Enabled Test Method" temporary;
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
        if FName <> TempEnabledTestMethod."Test Method Name" then
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

    [Scope('OnPrem')]
    procedure CopyToTemp(CodeunitID: Integer)
    var
        EnabledTestMethod: Record "Enabled Test Method";
    begin
        EnabledTestMethod.Reset();
        EnabledTestMethod.SetRange("Test Codeunit ID", CodeunitID);
        if EnabledTestMethod.FindSet() then
            repeat
                TempEnabledTestMethod.Copy(EnabledTestMethod);
                TempEnabledTestMethod.Insert(true);
            until EnabledTestMethod.Next() = 0;
    end;
}

