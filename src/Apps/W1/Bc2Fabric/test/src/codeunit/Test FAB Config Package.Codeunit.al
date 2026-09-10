namespace Microsoft.FabricExport;

using System.Fabric;

codeunit 150202 "Test FAB Config Package"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
    begin
        TenantFabricTables.DeleteAll(false);
        PackageLine.DeleteAll(false);
        Pkg.DeleteAll(false);
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    local procedure GivenPackage(PackageCode: Code[20]; TableId1: Integer; TableId2: Integer)
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
    begin
        Pkg.Init();
        Pkg."Code" := PackageCode;
        Pkg.Description := PackageCode;
        Pkg.Version := '1.0';
        Pkg.Insert(false);

        PackageLine.Init();
        PackageLine."Package Code" := PackageCode;
        PackageLine."Table ID" := TableId1;
        PackageLine.Insert(false);

        PackageLine.Init();
        PackageLine."Package Code" := PackageCode;
        PackageLine."Table ID" := TableId2;
        PackageLine.Insert(false);
    end;

    [Test]
    procedure RegisterPackageCreatesHeaderAndLines()
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIds: List of [Integer];
    begin
        //[SCENARIO] RegisterPackage creates a package header and its lines
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A list of two valid table IDs
        TableIds.Add(18);
        TableIds.Add(27);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The package is registered
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIds);

        //[THEN] The header exists and two lines are created
        Assert.IsTrue(Pkg.Get('MS-STD'), 'Expected the package header to exist.');
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(2, PackageLine.Count(), 'Expected two package lines.');
    end;

    [Test]
    procedure RegisterPackageIsIdempotentForSameVersion()
    var
        PackageLine: Record "Fabric Config Package Line";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIds: List of [Integer];
    begin
        //[SCENARIO] Registering the same version twice does not duplicate lines
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A package already registered at v1.0
        TableIds.Add(18);
        TableIds.Add(27);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIds);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The same version is registered again
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIds);

        //[THEN] There are still exactly two lines
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(2, PackageLine.Count(), 'Expected registration to be idempotent.');
    end;

    [Test]
    procedure ActivateAddsPackageTablesToPlatform()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] Activating a package writes its tables to Tenant Fabric Tables
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A registered package with two tables
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The package is activated
        FabricConfigPkgMgt.Activate(Pkg);

        //[THEN] Both tables exist in the platform table and the package is active
        Assert.IsTrue(TenantFabricTables.Get(18), 'Expected table 18 in Tenant Fabric Tables.');
        Assert.IsTrue(TenantFabricTables.Get(27), 'Expected table 27 in Tenant Fabric Tables.');
        Pkg.Get('MS-STD');
        Assert.IsTrue(Pkg.Active, 'Expected the package to be active.');
    end;

    [Test]
    procedure ActivateSkipsExistingTable()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] Activation skips a table that is already selected
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Table 18 is already present in the platform table
        TenantFabricTables.Init();
        TenantFabricTables."Table ID" := 18;
        TenantFabricTables.Insert(false);
        //[GIVEN] A registered package containing tables 18 and 27
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The package is activated
        FabricConfigPkgMgt.Activate(Pkg);

        //[THEN] Table 27 is added and the total count is two
        Assert.IsTrue(TenantFabricTables.Get(27), 'Expected table 27 to be added.');
        Assert.AreEqual(2, TenantFabricTables.Count(), 'Expected exactly two selected tables.');
    end;

    [Test]
    procedure DeactivateRemovesPackageTables()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] Deactivating a package removes its tables from the platform table
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package with two tables
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The package is deactivated
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Deactivate(Pkg);

        //[THEN] Both tables are removed and the package is inactive
        Assert.IsFalse(TenantFabricTables.Get(18), 'Expected table 18 to be removed.');
        Assert.IsFalse(TenantFabricTables.Get(27), 'Expected table 27 to be removed.');
        Pkg.Get('MS-STD');
        Assert.IsFalse(Pkg.Active, 'Expected the package to be inactive.');
    end;

    [Test]
    procedure DeactivateKeepsTableSharedWithOtherActivePackage()
    var
        Pkg: Record "Fabric Config Package";
        OtherPkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] A table shared with another active package is kept on deactivate
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Two active packages that both contain table 18
        GivenPackage('PKG-A', 18, 27);
        GivenPackage('PKG-B', 18, 36);
        Pkg.Get('PKG-A');
        FabricConfigPkgMgt.Activate(Pkg);
        OtherPkg.Get('PKG-B');
        FabricConfigPkgMgt.Activate(OtherPkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] Package A is deactivated
        Pkg.Get('PKG-A');
        FabricConfigPkgMgt.Deactivate(Pkg);

        //[THEN] Table 18 remains (still owned by active PKG-B), table 27 is removed
        Assert.IsTrue(TenantFabricTables.Get(18), 'Expected shared table 18 to remain.');
        Assert.IsFalse(TenantFabricTables.Get(27), 'Expected exclusive table 27 to be removed.');
    end;

    [Test]
    procedure ReapplyAddsMissingTables()
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] Reapply adds package tables that are missing from the platform table
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package, then a new line added to it
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        PackageLine.Init();
        PackageLine."Package Code" := 'MS-STD';
        PackageLine."Table ID" := 36;
        PackageLine.Insert(false);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] The package is reapplied
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Reapply(Pkg);

        //[THEN] The newly added table is present
        Assert.IsTrue(TenantFabricTables.Get(36), 'Expected the new table 36 to be added on reapply.');
    end;

    [Test]
    procedure DeleteActivePackageIsBlocked()
    var
        Pkg: Record "Fabric Config Package";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] An active package cannot be deleted
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Plat Admin');

        //[WHEN] Deletion of the active package is attempted
        Pkg.Get('MS-STD');
        asserterror Pkg.Delete(true);

        //[THEN] The deletion is blocked
        Assert.ExpectedError('active');
    end;
}
