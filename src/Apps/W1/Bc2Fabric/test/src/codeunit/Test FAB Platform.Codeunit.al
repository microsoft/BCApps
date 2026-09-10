namespace Microsoft.FabricExport;

using System.Fabric;

codeunit 150203 "Test FAB Platform"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
    begin
        TenantFabricTables.DeleteAll(false);
        TenantFabricSetup.DeleteAll(false);
        PlatformTestSub.Reset();
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    [Test]
    procedure EnsureSetupCreatesPlatformRecord()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] The adapter reads/creates the platform setup singleton (Story 1)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] EnsureSetup is called
        FabricPlatformMgt.EnsureSetup(TenantFabricSetup);

        //[THEN] Exactly one platform setup record exists
        Assert.AreEqual(1, TenantFabricSetup.Count(), 'Expected exactly one Tenant Fabric Setup record.');
    end;

    [Test]
    procedure AddTableWritesPlatformSystemTable()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding a valid table writes directly to Tenant Fabric Tables (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] A valid table is added
        FabricPlatformMgt.AddTable(Database::"Tenant Fabric Setup");

        //[THEN] The row exists in the platform table
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Setup"), 'Expected the added table row in Tenant Fabric Tables.');
    end;

    [Test]
    procedure AddTableRejectedAtLimit()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        i: Integer;
    begin
        //[SCENARIO] The 500-table platform limit is enforced (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] 500 table rows already exist
        for i := 1 to FabricPlatformMgt.MaxTableCount() do begin
            TenantFabricTables.Init();
            TenantFabricTables."Table ID" := i;
            TenantFabricTables.Insert(false);
        end;
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Platform Admin');

        //[WHEN] Another table add is attempted
        asserterror FabricPlatformMgt.CheckCanAddTable();

        //[THEN] The operation is rejected
        Assert.ExpectedError('maximum');
    end;

    [Test]
    procedure EnableUsesSeamWithoutCallingPlatform()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Enable routes through the lifecycle seam (Story 3)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The lifecycle subscriber is bound so no real ADF call happens
        BindSubscription(PlatformTestSub);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] Enable is requested
        FabricPlatformMgt.EnableExport();

        //[THEN] The seam fired and the real platform call was bypassed
        Assert.IsTrue(PlatformTestSub.WasEnableCalled(), 'Expected the enable seam to fire.');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure StartStopDisableUseSeam()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Start, Stop, and Disable route through the lifecycle seam (Stories 4-5)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The lifecycle subscriber is bound
        BindSubscription(PlatformTestSub);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] Start, Stop, and Disable are requested
        FabricPlatformMgt.StartExport();
        FabricPlatformMgt.StopExport();
        FabricPlatformMgt.DisableExport();

        //[THEN] All three seams fired
        Assert.IsTrue(PlatformTestSub.WasStartCalled(), 'Expected the start seam to fire.');
        Assert.IsTrue(PlatformTestSub.WasStopCalled(), 'Expected the stop seam to fire.');
        Assert.IsTrue(PlatformTestSub.WasDisableCalled(), 'Expected the disable seam to fire.');
        UnbindSubscription(PlatformTestSub);
    end;
}
