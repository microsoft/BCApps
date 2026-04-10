codeunit 139250 "Test Object Ranges"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Object Range]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloudManagerObjectRangeUnused()
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object ID", 8000, 8299);
        Assert.RecordIsEmpty(AllObj);
    end;
}

