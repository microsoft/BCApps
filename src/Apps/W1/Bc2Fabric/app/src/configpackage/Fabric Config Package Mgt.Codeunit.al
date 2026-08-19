namespace Microsoft.Bc2Fabric;

using System.Fabric;
using System.Reflection;

codeunit 150002 "Fabric Config Package Mgt"
{

    internal procedure Activate(var Pkg: Record "Fabric Config Package")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        NewTableCount: Integer;
    begin
        // Count lines not yet in the platform table
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                if not TenantFabricTables.Get(PackageLine."Table ID") then
                    NewTableCount += 1;
            until PackageLine.Next() = 0;

        FabricPlatformMgt.EnsureCapacity(NewTableCount);

        // LockTable prevents a concurrent Activate/Deactivate from inserting or deleting
        // rows between the capacity check above and the inserts below.
        TenantFabricTables.LockTable();
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                if not TenantFabricTables.Get(PackageLine."Table ID") then
                    FabricPlatformMgt.AddTable(PackageLine."Table ID");
            until PackageLine.Next() = 0;

        Pkg.Active := true;
        Pkg."Activated On" := CurrentDateTime();
        Pkg."Activated By" := CopyStr(UserId(), 1, MaxStrLen(Pkg."Activated By"));
        Pkg."Last Activated Version" := Pkg.Version;
        Pkg.Modify(true);

        Session.LogMessage('FAB-150', StrSubstNo('Config package %1 activated.', Pkg."Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'BC2Fabric');
    end;

    internal procedure Deactivate(var Pkg: Record "Fabric Config Package")
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        OtherPackageCode: Code[20];
    begin
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                // Remove the table only when no other active package still needs it.
                // The platform Tenant Fabric Tables has no ownership column, so a table that
                // also matches a manually-added selection cannot be distinguished here.
                if not FindOtherActivePackage(PackageLine."Table ID", Pkg."Code", OtherPackageCode) then
                    if TenantFabricTables.Get(PackageLine."Table ID") then
                        TenantFabricTables.Delete(true);
            until PackageLine.Next() = 0;

        Pkg.Active := false;
        Pkg."Activated On" := 0DT;
        Pkg."Activated By" := '';
        Pkg.Modify(true);

        Session.LogMessage('FAB-151', StrSubstNo('Config package %1 deactivated.', Pkg."Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'BC2Fabric');
    end;

    local procedure FindOtherActivePackage(TableId: Integer; ExcludePackageCode: Code[20]; var OtherPackageCode: Code[20]): Boolean
    var
        PackageLine: Record "Fabric Config Package Line";
        OtherPkg: Record "Fabric Config Package";
    begin
        PackageLine.SetRange("Table ID", TableId);
        PackageLine.SetFilter("Package Code", '<>%1', ExcludePackageCode);
        if PackageLine.FindSet() then
            repeat
                if OtherPkg.Get(PackageLine."Package Code") then
                    if OtherPkg.Active then begin
                        OtherPackageCode := OtherPkg."Code";
                        exit(true);
                    end;
            until PackageLine.Next() = 0;
        exit(false);
    end;

    internal procedure Reapply(var Pkg: Record "Fabric Config Package")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        NewTableCount: Integer;
    begin
        // Add any missing package tables. Rows are not removed on reapply because the
        // platform table has no ownership column to identify stale package rows.
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                if not TenantFabricTables.Get(PackageLine."Table ID") then
                    NewTableCount += 1;
            until PackageLine.Next() = 0;

        FabricPlatformMgt.EnsureCapacity(NewTableCount);

        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                if not TenantFabricTables.Get(PackageLine."Table ID") then
                    FabricPlatformMgt.AddTable(PackageLine."Table ID");
            until PackageLine.Next() = 0;

        Pkg."Activated On" := CurrentDateTime();
        Pkg."Last Activated Version" := Pkg.Version;
        Pkg.Modify(true);

        Session.LogMessage('FAB-152', StrSubstNo('Config package %1 reapplied.', Pkg."Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'BC2Fabric');
    end;

    internal procedure IsReapplyAvailable(var Pkg: Record "Fabric Config Package"): Boolean
    begin
        exit(Pkg.Active and (Pkg.Version <> Pkg."Last Activated Version"));
    end;

    // -------------------------------------------------------------------------
    // Code-based package registration
    // -------------------------------------------------------------------------

    /// <summary>
    /// Register a configuration package with a list of table IDs. Safe to call
    /// on every install/upgrade — skips if the package already exists at this version.
    /// Per Company is derived automatically from Table Metadata.DataPerCompany.
    /// </summary>
    procedure RegisterPackage(PackageCode: Code[20]; Description: Text[100]; Version: Code[10]; TableIds: List of [Integer])
    var
        Pkg: Record "Fabric Config Package";
        PackageLine: Record "Fabric Config Package Line";
        AllObj: Record AllObjWithCaption;
        TableId: Integer;
    begin
        if not Pkg.Get(PackageCode) then begin
            Pkg.Init();
            Pkg."Code" := PackageCode;
            Pkg.Description := Description;
            Pkg.Version := Version;
            Pkg.Insert(true);
        end else begin
            if Pkg.Version = Version then
                exit; // Already registered at this version — nothing to do
            Pkg.Description := Description;
            Pkg.Version := Version;
            Pkg.Modify(true);
        end;

        // Rebuild lines
        PackageLine.SetRange("Package Code", PackageCode);
        PackageLine.DeleteAll(true);

        foreach TableId in TableIds do begin
            AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
            AllObj.SetRange("Object ID", TableId);
            if AllObj.FindFirst() then begin
                PackageLine.Init();
                PackageLine."Package Code" := PackageCode;
                PackageLine.Validate("Table ID", TableId);
                PackageLine.Insert(true);
            end else
                Session.LogMessage('FAB-156', StrSubstNo('Config package %1: skipped missing table %2 — not found in AllObjWithCaption.', PackageCode, TableId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'BC2Fabric');
        end;

        // If it was already active, reapply so the platform tables stay in sync
        if Pkg.Active then
            Reapply(Pkg);

        Session.LogMessage('FAB-155', StrSubstNo('Config package %1 v%2 registered via code.', PackageCode, Version), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'BC2Fabric');
    end;
}
