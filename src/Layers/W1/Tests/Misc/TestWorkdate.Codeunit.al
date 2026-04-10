codeunit 139028 "Test Workdate"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Default WorkDate]
    end;

    var
        CRONUSTxt: Label 'CRONUS', Locked = true;
        Assert: Codeunit Assert;
        WrongWorkdateErr: Label 'Wrong work date ';

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkDate()
    var
        LogInManagement: Codeunit LogInManagement;
        FoundWorkDate: Date;
    begin
        FoundWorkDate := LogInManagement.GetDefaultWorkDate();
        if StrPos(CompanyName, CRONUSTxt) = 1 then
            Assert.AreEqual(WorkDate(), LogInManagement.GetDefaultWorkDate(), WrongWorkdateErr)
        else
            Assert.IsTrue(WorkDate() in [CalcDate('<-1D>', FoundWorkDate), FoundWorkDate, CalcDate('<+1D>', FoundWorkDate)], WrongWorkdateErr)
    end;
}

