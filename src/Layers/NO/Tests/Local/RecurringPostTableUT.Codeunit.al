codeunit 144160 "Recurring Post Table UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Recurring Order] [Post]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPostSerialNo()
    var
        RecurringPost: Record "Recurring Post";
    begin
        // Purpose of the test is to validate Trigger OnInsert
        // under the following conditions:
        // 1.  "Serial No." = 0

        // Setup
        RecurringPost.DeleteAll();

        // Exercise
        RecurringPost."Serial No." := 0;
        RecurringPost.Insert(true);
        Assert.AreEqual(1, RecurringPost."Serial No.", 'First serial no must be 1');

        Clear(RecurringPost);
        RecurringPost."Serial No." := 0;
        RecurringPost.Insert(true);
        Assert.AreEqual(2, RecurringPost."Serial No.", 'Second serial no must be 2');

        Clear(RecurringPost);
        RecurringPost."Serial No." := 100;
        RecurringPost.Insert(true);
        Assert.AreEqual(100, RecurringPost."Serial No.", 'Hard coded serial no to 100 must be 100');

        // Verify
        RecurringPost.Find('-');
        Assert.AreEqual(1, RecurringPost."Serial No.", 'First serial no must be 1');
        RecurringPost.Next();
        Assert.AreEqual(2, RecurringPost."Serial No.", 'Second serial no must be 2');
        RecurringPost.Next();
        Assert.AreEqual(100, RecurringPost."Serial No.", 'Hard coded serial no to 100 must be 100');
    end;
}

