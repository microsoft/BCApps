codeunit 130301 "Reset State Before Test Run"
{
    SingleInstance = true;

    trigger OnRun()
    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
    begin
        if ConfiguredRandomSeed.IsSet() then
            LibraryRandom.SetSeed(ConfiguredRandomSeed.GetSeed())
        else
            LibraryRandom.SetSeed(1);
        RunLegacyPermissionSet();
        LibraryNotificationMgt.ClearTemporaryNotificationContext();
    end;

    procedure RunLegacyPermissionSet()
    begin
        Clear(PermissionTestCatalog);
        PermissionTestCatalog.InitializePermissionSetForTest(TestPermissions::Disabled);
    end;

    var
        PermissionTestCatalog: Codeunit "Permission Test Catalog";
}