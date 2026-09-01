codeunit 130202 "Lab Test Runner"
{
    // This is the test runner used in the lab.

    Subtype = TestRunner;

    trigger OnRun()
    var
        BackupMgt: Codeunit "Backup Management";
    begin
        SnapTestRunner.RunTests(false, true);
        BackupMgt.SetEnabled(true);
        BackupMgt.DefaultFixture();
    end;

    var
        SnapTestRunner: Codeunit "Snap Test Runner";
        BackupSubscriber: Codeunit "Backup Subscriber";

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    begin
        if IsBackupMgtException(CUId, FName) then
            UnbindSubscription(BackupSubscriber);
        exit(SnapTestRunner.OnBeforeTestRunImpl(CUId, CUName, FName, FTestPermissions))
    end;

    trigger OnAfterTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions; Success: Boolean)
    begin
        SnapTestRunner.OnAfterTestRunImpl(CUId, CUName, FName, FTestPermissions, Success);
        if IsBackupMgtException(CUId, FName) then
            BindSubscription(BackupSubscriber);
    end;

    local procedure IsBackupMgtException(CUId: Integer; FName: Text): Boolean
    begin
        if CUId = 137100 then
            exit(FName in ['TstAddlRefactTC1_2_2_5a_6b', 'TstAddlRefactTC1_3_3_9', 'TstAddlRefactTC1_5_2_16']);
    end;
}

