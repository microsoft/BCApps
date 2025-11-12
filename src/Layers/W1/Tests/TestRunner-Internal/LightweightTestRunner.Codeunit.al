codeunit 130203 "Lightweight Test Runner"
{
    SingleInstance = false;
    Subtype = TestRunner;

    trigger OnRun()
    var
        EnabledTestCodeunit: Record "Enabled Test Codeunit";
        AllObj: Record AllObj;
    begin
        if EnabledTestCodeunit.Find('-') then
            repeat
                if AllObj.Get(AllObj."Object Type"::Codeunit, EnabledTestCodeunit."Test Codeunit ID") then
                    // run enabled test codeunit
                    CODEUNIT.Run(EnabledTestCodeunit."Test Codeunit ID");
            until EnabledTestCodeunit.Next() = 0
    end;

    var
        StartTime: Time;

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    var
        TestResult: Record "Test Result";
        TestCodeunit: Record "Test Codeunit";
    begin
        StartTime := Time;

        if FName = '' then
            exit(true);

        ClearLastError();

        TestResult.Init();
        TestResult.Validate(CUName, CUName);
        TestResult.Validate(CUId, CUId);
        TestResult.Validate(FName, FName);

        TestResult.Validate(Platform, TestResult.Platform::ServiceTier);

        if TestCodeunit.Get(CUId) then
            TestResult.Validate(File, TestCodeunit.File);

        TestResult.Insert(true);

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

        if Success then begin
            TestResult.Validate(Result, TestResult.Result::Passed);
            ClearLastError();
        end
        else begin
            TestResult.Validate(Result, TestResult.Result::Failed);
            TestResult.Validate("Error Message", CropTo(GetLastErrorText, MaxStrLen(TestResult."Error Message")))
        end;

        TestResult.Validate("Execution Time", EndTime - StartTime);
        TestResult.Modify(true)
    end;

    local procedure CropTo(String: Text[1024]; Length: Integer): Text
    begin
        if StrLen(String) > Length then
            exit(PadStr(String, Length));
        exit(String)
    end;
}

