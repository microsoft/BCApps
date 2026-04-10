codeunit 139430 "Permission Test Verification"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [G/L Entry] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPermissionTestEnabled()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [GIVEN] Permission testing is enabled (by default O365 Full Access it applied)

        if GLEntry.FindLast() then
            GLEntry."Entry No." += 1;
        GLEntry.Init();

        // [WHEN] User tries to INSERT data into G/L Entry without indirect permissions
        // [THEN] An error is thrown that you do not have permissions to insert directly into the G/L entry table
        LibraryLowerPermissions.SetO365Full();

        asserterror GLEntry.Insert();
        Assert.ExpectedError('Sorry, the current permissions prevented the action. (TableData');
    end;
}

