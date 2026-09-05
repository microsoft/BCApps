codeunit 130301 "Reset State Before Test Run"
{
    SingleInstance = true;

    trigger OnRun()
    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Any: Codeunit "Any";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
        SeedToUse: Integer;
    begin
        // The stability state is checked before every test method so entering or exiting stability
        // mode takes effect immediately and cannot leak into later runs.
        if ConfiguredRandomSeed.IsStabilityMode() then begin
            // Seed both libraries deterministically so a configuration that does not set its own seed
            // still starts from a known state and one configuration cannot affect the next.
            if ConfiguredRandomSeed.IsSet() then
                SeedToUse := ConfiguredRandomSeed.GetSeed()
            else
                SeedToUse := 1;
            LibraryRandom.SetSeed(SeedToUse);
            Any.SetSeed(SeedToUse);
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