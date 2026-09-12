namespace Microsoft.FabricExport;

using System.Fabric;
using System.Utilities;

codeunit 140011 "Test FAB Config Package"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        ExpectedMessage: Text[1024];
        TableKeptMsg: Label '1 table(s) were not removed because they are also included in at least one other active package.';

    local procedure Initialize()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        TenantFabricTables.DeleteAll(false);
        PackageLine.DeleteAll(false);
        Pkg.DeleteAll(false);
        FabricTableClaim.DeleteAll(false);
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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
    [HandlerFunctions('MessageHandler')]
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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] Expected kept-table notification
        ExpectedMessage := TableKeptMsg;

        //[WHEN] Package A is deactivated
        Pkg.Get('PKG-A');
        FabricConfigPkgMgt.Deactivate(Pkg);

        //[THEN] Table 18 remains (still owned by active PKG-B), table 27 is removed
        Assert.IsTrue(TenantFabricTables.Get(18), 'Expected shared table 18 to remain.');
        Assert.IsFalse(TenantFabricTables.Get(27), 'Expected exclusive table 27 to be removed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeactivateKeepsManuallyAddedTable()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] A manually-added table is never removed by deactivating a package that also lists it
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Table 18 is added manually, outside of any package
        FabricPlatformMgt.AddTable(18);
        //[GIVEN] A package that also lists table 18, then activated
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] Expected kept-table notification
        ExpectedMessage := TableKeptMsg;

        //[WHEN] The package is deactivated
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Deactivate(Pkg);

        //[THEN] The manually-added table 18 remains, exclusive table 27 is removed
        Assert.IsTrue(TenantFabricTables.Get(18), 'Expected the manually-added table to remain.');
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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

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
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Deletion of the active package is attempted
        Pkg.Get('MS-STD');
        asserterror Pkg.Delete(true);

        //[THEN] The deletion is blocked
        Assert.ExpectedError('active');
    end;

    [Test]
    procedure RegisterPackageSkipsTableIdNotFoundInObjects()
    var
        PackageLine: Record "Fabric Config Package Line";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIds: List of [Integer];
    begin
        //[SCENARIO] RegisterPackage skips a table ID that does not exist as an object
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A list containing one valid and one non-existent table ID
        TableIds.Add(18);
        TableIds.Add(999999);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is registered
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIds);

        //[THEN] Only the valid table produces a line
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(1, PackageLine.Count(), 'Expected only the valid table id to produce a line.');
        Assert.IsTrue(PackageLine.Get('MS-STD', 18), 'Expected table 18 to be registered.');
    end;

    [Test]
    procedure RegisterPackageRebuildsLinesOnVersionBump()
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIdsV1: List of [Integer];
        TableIdsV2: List of [Integer];
    begin
        //[SCENARIO] Registering a new version rebuilds the package lines
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The package registered at v1.0 with two tables
        TableIdsV1.Add(18);
        TableIdsV1.Add(27);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIdsV1);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is re-registered at v2.0 with a single, different table
        TableIdsV2.Add(36);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '2.0', TableIdsV2);

        //[THEN] The version is updated and only the new line remains
        Assert.IsTrue(Pkg.Get('MS-STD'), 'Expected the package header to exist.');
        Assert.AreEqual('2.0', Pkg.Version, 'Expected the version to be updated.');
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(1, PackageLine.Count(), 'Expected exactly one line after rebuild.');
        Assert.IsTrue(PackageLine.Get('MS-STD', 36), 'Expected the new table to be the only line.');
    end;

    [Test]
    procedure RegisterPackageReappliesWhenPackageIsAlreadyActive()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIdsV1: List of [Integer];
        TableIdsV2: List of [Integer];
    begin
        //[SCENARIO] Re-registering an active package at a new version reapplies it automatically
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package at v1.0
        TableIdsV1.Add(18);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIdsV1);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is re-registered at v2.0 with an additional table
        TableIdsV2.Add(18);
        TableIdsV2.Add(27);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '2.0', TableIdsV2);

        //[THEN] The new table is added to the platform without a manual reapply
        Assert.IsTrue(TenantFabricTables.Get(27), 'Expected the new v2.0 table to be applied automatically.');
    end;

    [Test]
    procedure RegisterPackageReleasesClaimForTableDroppedFromActivePackage()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIdsV1: List of [Integer];
        TableIdsV2: List of [Integer];
    begin
        //[SCENARIO] Re-registering an active package with a smaller table set releases the dropped table's claim
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package at v1.0 with two tables
        TableIdsV1.Add(18);
        TableIdsV1.Add(27);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIdsV1);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is re-registered at v2.0 without table 27
        TableIdsV2.Add(18);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '2.0', TableIdsV2);

        //[THEN] The dropped table's claim is released and it is removed from the platform
        Assert.IsTrue(TenantFabricTables.Get(18), 'Expected table 18 to remain.');
        Assert.IsFalse(TenantFabricTables.Get(27), 'Expected dropped table 27 to be removed, not left with a stale claim.');
    end;

    [Test]
    procedure RegisterPackageKeepsTableDroppedFromActivePackageWhenSharedWithAnotherActivePackage()
    var
        Pkg: Record "Fabric Config Package";
        OtherPkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TableIdsV1: List of [Integer];
        TableIdsV2: List of [Integer];
    begin
        //[SCENARIO] A table dropped from a re-registered package stays exported while another active package still claims it
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Two active packages, both selecting table 27
        TableIdsV1.Add(18);
        TableIdsV1.Add(27);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '1.0', TableIdsV1);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        GivenPackage('PKG-B', 27, 36);
        OtherPkg.Get('PKG-B');
        FabricConfigPkgMgt.Activate(OtherPkg);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] MS-STD is re-registered at v2.0 without table 27
        TableIdsV2.Add(18);
        FabricConfigPkgMgt.RegisterPackage('MS-STD', 'Microsoft Standard', '2.0', TableIdsV2);

        //[THEN] Table 27 remains because PKG-B still claims it
        Assert.IsTrue(TenantFabricTables.Get(27), 'Expected table 27 to remain claimed by PKG-B.');
    end;

    [Test]
    procedure ActivateFailsWhenExceedingPlatformLimit()
    var
        Pkg: Record "Fabric Config Package";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        i: Integer;
    begin
        //[SCENARIO] Activation is blocked when it would exceed the platform table limit
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The platform table is already at its maximum capacity
        for i := 1 to FabricPlatformMgt.MaxTableCount() do begin
            TenantFabricTables.Init();
            TenantFabricTables."Table ID" := i;
            TenantFabricTables.Insert(false);
        end;
        //[GIVEN] A registered package with two tables not yet selected
        GivenPackage('MS-STD', 100000, 100001);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is activated
        asserterror FabricConfigPkgMgt.Activate(Pkg);

        //[THEN] The activation is rejected
        Assert.ExpectedError('maximum');
    end;

    [Test]
    procedure IsReapplyAvailableIsTrueAfterVersionBump()
    var
        Pkg: Record "Fabric Config Package";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] IsReapplyAvailable reports true once an active package's version differs from the last activated version
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package version is bumped
        Pkg.Validate(Version, '2.0');
        Pkg.Modify(true);

        //[THEN] Reapply is reported as available
        Assert.IsTrue(FabricConfigPkgMgt.IsReapplyAvailable(Pkg), 'Expected reapply to be available after a version bump.');
    end;

    [Test]
    procedure IsReapplyAvailableIsFalseAfterReapply()
    var
        Pkg: Record "Fabric Config Package";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        //[SCENARIO] IsReapplyAvailable reports false once the package has been reapplied at the current version
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An activated package whose version was bumped
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        FabricConfigPkgMgt.Activate(Pkg);
        Pkg.Get('MS-STD');
        Pkg.Validate(Version, '2.0');
        Pkg.Modify(true);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is reapplied
        FabricConfigPkgMgt.Reapply(Pkg);

        //[THEN] Reapply is no longer reported as available
        Pkg.Get('MS-STD');
        Assert.IsFalse(FabricConfigPkgMgt.IsReapplyAvailable(Pkg), 'Expected reapply to be unavailable once the last activated version matches.');
    end;

    [Test]
    procedure TableIdValidationSetsTableNameAndPerCompany()
    var
        PackageLine: Record "Fabric Config Package Line";
    begin
        //[SCENARIO] Validating Table ID looks up the table name and per-company flag
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A new package line
        PackageLine.Init();
        PackageLine."Package Code" := 'MS-STD';
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Table ID is validated with the Customer table
        PackageLine.Validate("Table ID", 18); // 18 = Customer

        //[THEN] The table name and per-company flag are populated from metadata
        Assert.AreEqual('Customer', PackageLine."Table Name", 'Expected the table name to be looked up.');
        Assert.IsTrue(PackageLine."Per Company", 'Expected Customer to be flagged per company.');
    end;

    [Test]
    procedure TableIdValidationResetsFieldsWhenClearedToZero()
    var
        PackageLine: Record "Fabric Config Package Line";
    begin
        //[SCENARIO] Clearing Table ID back to zero resets the derived fields
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A package line with the table already validated
        PackageLine.Init();
        PackageLine."Package Code" := 'MS-STD';
        PackageLine.Validate("Table ID", 18); // 18 = Customer
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Table ID is cleared back to zero
        PackageLine.Validate("Table ID", 0);

        //[THEN] The table name is cleared and per-company reverts to true
        Assert.AreEqual('', PackageLine."Table Name", 'Expected the table name to be cleared.');
        Assert.IsTrue(PackageLine."Per Company", 'Expected Per Company to revert to true.');
    end;

    [Test]
    procedure DeleteInactivePackageRemovesItsLines()
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
    begin
        //[SCENARIO] Deleting an inactive package removes its lines
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] An inactive registered package with two lines
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package is deleted
        Pkg.Delete(true);

        //[THEN] Its lines are removed as well
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(0, PackageLine.Count(), 'Expected the package lines to be deleted along with the header.');
    end;

    [Test]
    procedure ExportThenImportRoundTripsPackageDefinition()
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        //[SCENARIO] A package exported to a stream can be re-imported unchanged
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A registered package with two tables
        GivenPackage('MS-STD', 18, 27);
        Pkg.Get('MS-STD');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] The package is exported to a stream
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        FabricConfigPkgMgt.ExportPackageToStream(Pkg, OutStr);
        //[GIVEN] The original package definition is removed so the import recreates it
        Pkg.Delete(true);

        //[WHEN] The stream is imported
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FabricConfigPkgMgt.ImportPackageFromStream(InStr);

        //[THEN] The package header and lines are recreated
        Assert.IsTrue(Pkg.Get('MS-STD'), 'Expected the package header to be recreated.');
        PackageLine.SetRange("Package Code", 'MS-STD');
        Assert.AreEqual(2, PackageLine.Count(), 'Expected two package lines after import.');
    end;

    [Test]
    procedure ImportFailsWhenPackageCodeIsMissing()
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        //[SCENARIO] Import is rejected when the package file has no code
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A JSON payload without a code field
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('{"description":"No Code","version":"1.0","tables":[18]}');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The stream is imported
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        asserterror FabricConfigPkgMgt.ImportPackageFromStream(InStr);

        //[THEN] The import is rejected
        Assert.ExpectedError('package code');
    end;

    [Test]
    procedure ImportFailsForInvalidJson()
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        //[SCENARIO] Import is rejected when the file is not valid JSON
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A non-JSON payload
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('not valid json');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The stream is imported
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        asserterror FabricConfigPkgMgt.ImportPackageFromStream(InStr);

        //[THEN] The import is rejected
        Assert.ExpectedError('valid package definition');
    end;

    #region Handlers

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    #endregion Handlers
}
