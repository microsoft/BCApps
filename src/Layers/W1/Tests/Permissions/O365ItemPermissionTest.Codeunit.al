codeunit 139451 "O365 Item Permission Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Permissions]
    end;

    var
        LibraryPermissionsVerify: Codeunit "Library - Permissions Verify";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestO365ItemEdit()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] A user with O365 Basic and Item Edit permissions
        Initialize();
        LibraryLowerPermissions.SetItemEdit();
        ExcludedTables := ExcludedTables.List();
        InsertTablesExcludedFromItemCreate(ExcludedTables);

        // [THEN] The user can insert/delete items
        RecordRef.Open(DATABASE::Item);
        LibraryPermissionsVerify.VerifyWritePermissionTrue(RecordRef);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetOutsideO365Scope();
        RecordRefWithAllRelations.Open(DATABASE::Item);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestO365ItemView()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] An Item with related records and a user with O365 Basic and Item View
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        RecordRefWithAllRelations.Open(DATABASE::Item);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        ExcludedTables := ExcludedTables.List();
        InsertTablesExcludedFromItemView(ExcludedTables);

        LibraryLowerPermissions.SetVendorView();
        RecordRef.Open(DATABASE::Item);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetItemView();
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // mandatory fields for Vendor creation
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        InventorySetup.Get();
        InventorySetup."Item Nos." := NoSeries.Code;
        InventorySetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromItemView(var ExcludedTables: DotNet GenericList1)
    begin
        ExcludedTables.Add(DATABASE::Bin);
        ExcludedTables.Add(DATABASE::Manufacturer);
        ExcludedTables.Add(DATABASE::Purchasing);
        ExcludedTables.Add(DATABASE::"Service Item Group");
        ExcludedTables.Add(DATABASE::"Item Tracking Code");
        ExcludedTables.Add(DATABASE::"Put-away Template Header");
        ExcludedTables.Add(DATABASE::"Phys. Invt. Counting Period");
        ExcludedTables.Add(DATABASE::"Routing Header");
        ExcludedTables.Add(DATABASE::"Production BOM Header");
        ExcludedTables.Add(DATABASE::"Production Forecast Name");
        ExcludedTables.Add(DATABASE::"Special Equipment");
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromItemCreate(var ExcludedTables: DotNet GenericList1)
    begin
        ExcludedTables.Add(DATABASE::Bin);
        ExcludedTables.Add(DATABASE::Manufacturer);
        ExcludedTables.Add(DATABASE::Purchasing);
        ExcludedTables.Add(DATABASE::"Service Item Group");
        ExcludedTables.Add(DATABASE::"Item Tracking Code");
        ExcludedTables.Add(DATABASE::"Put-away Template Header");
        ExcludedTables.Add(DATABASE::"Phys. Invt. Counting Period");
        ExcludedTables.Add(DATABASE::"Routing Header");
        ExcludedTables.Add(DATABASE::"Production BOM Header");
        ExcludedTables.Add(DATABASE::"Production Forecast Name");
    end;
}

