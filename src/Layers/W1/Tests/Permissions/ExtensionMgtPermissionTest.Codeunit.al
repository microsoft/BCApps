codeunit 139455 "Extension Mgt. Permission Test"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure SetupPagesOpenWithBusinessFullTest()
    var
        AssistedSetup: TestPage "Assisted Setup";
        ManualSetup: TestPage "Manual Setup";
    begin
        // [GIVEN] A user with D365 Business Full Access
        LibraryLowerPermissions.SetO365BusFull();

        // [WHEN] Assisted Setup page is opened
        AssistedSetup.Trap();
        AssistedSetup.OpenView();
        AssistedSetup.Close();

        // [WHEN] Manual Setup page is opened
        ManualSetup.Trap();
        ManualSetup.OpenView();
        ManualSetup.Close();

        // [THEN] No errors are thrown 
    end;
}

