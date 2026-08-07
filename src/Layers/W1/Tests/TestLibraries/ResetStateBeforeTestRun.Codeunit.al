codeunit 130301 "Reset State Before Test Run"
{
    SingleInstance = true;

    trigger OnRun()
    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Any: Codeunit "Any";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
    begin
        if ConfiguredRandomSeed.IsSet() then begin
            // A test run (for example stability mode) asked the random libraries to use a specific
            // seed. Use the existing SetSeed methods so a test that later sets its own seed still wins.
            LibraryRandom.SetSeed(ConfiguredRandomSeed.GetSeed());
            Any.SetSeed(ConfiguredRandomSeed.GetSeed());
        end else
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