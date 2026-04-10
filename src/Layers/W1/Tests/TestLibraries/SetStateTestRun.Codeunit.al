codeunit 130302 "Set State Test Run"
{
    SingleInstance = true;

    trigger OnRun()
    begin
        PermissionTestCatalog.InitializePermissionSetForTest(TestPermissions::Restrictive);
    end;

    var
        PermissionTestCatalog: Codeunit "Permission Test Catalog";
}