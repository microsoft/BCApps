codeunit 132218 "Permission Test Catalog"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        MustChangePermissionsErr: Label 'You must change permissions at least once in your tests (at least the execute step).';

    procedure InitializePermissionSetForTest(FunctionTestPermissions: TestPermissions): Boolean
    begin
        // initialize Permissionset level based on all available information
        // case 1 - Test Permission DISABLED - no change
        // case 2 - TestPermissions not Restrictive or Restrictive - D365 FULL ACCESS

        // check if test permission DISABLED
        if FunctionTestPermissions = TESTPERMISSIONS::Disabled then
            LibraryLowerPermissions.StartLoggingNAVPermissions()
        else
            LibraryLowerPermissions.StartLoggingNAVPermissions('D365 Full Access');
    end;


    procedure GetPermissionErrors(FunctionTestPermissions: TestPermissions): Text
    var
        Disable: Boolean;
    begin
        LibraryLowerPermissions.StopLoggingNAVPermissions();

        if FunctionTestPermissions = TESTPERMISSIONS::Disabled then
            exit;
        if FunctionTestPermissions = TESTPERMISSIONS::NonRestrictive then
            exit;

        LibraryLowerPermissions.OnGetDisableEnforcingPermissionChange(Disable);
        if Disable then
            exit;

        if not LibraryLowerPermissions.HasChangedPermissions() then
            exit(MustChangePermissionsErr);
    end;
}

