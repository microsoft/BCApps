codeunit 144124 "ReturnError Table UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Waiting Journal] [Return Error]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure ProvideSerialNumberFromLastRow()
    var
        ReturnError: Record "Return Error";
    begin
        // Purpose of the test is to validate Trigger OnInsert
        // under the following conditions:
        // 1.  "Serial Number" = 0 ,
        // 2.   ReturnError.FINDLAST  = TRUE
        // Setup
        ReturnError.DeleteAll();

        ReturnError."Serial Number" := 0;
        ReturnError.Insert(true);

        // Exercise
        ReturnError."Serial Number" := 0;
        ReturnError.Insert(true);

        // Verify
        Assert.AreEqual(2, ReturnError."Serial Number", 'Serial number should have been two since it is the first row');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProvideSerialNumberWithNoRows()
    var
        ReturnError: Record "Return Error";
    begin
        ReturnError.DeleteAll();

        // Purpose of the test is to validate Trigger OnInsert
        // under the following conditions:
        // 1.  "Serial Number" = 0 ,
        // 2.   ReturnError.FINDLAST  = FALSE

        // Exercise
        ReturnError."Serial Number" := 0;

        ReturnError.Insert(true);
        // Verify
        Assert.AreEqual(1, ReturnError."Serial Number", 'Serial number should have been one since it is the first row');
    end;
}

