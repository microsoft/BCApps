namespace Microsoft.FabricExport;

using System.Fabric;
using System.Reflection;

codeunit 48521 "Fabric Config Package Mgt"
{
    // Activate/Deactivate go through Fabric Platform Mgt's claim API; schema-type sync
    // still writes Tenant Fabric Tables directly.
    Permissions = tabledata "Tenant Fabric Tables" = RIMD;

    var
        TablesKeptByOtherPackageMsg: Label '%1 table(s) were not removed because they are also included in at least one other active package.', Comment = '%1 = number of tables retained';
        ImportMissingCodeErr: Label 'The package file does not contain a package code.';
        InvalidPackageFileErr: Label 'The file could not be read as a valid package definition.';
        CategoryTok: Label 'MicrosoftFabricExport', Locked = true;
        PackageActivatedAuditMsg: Label 'Microsoft Fabric Open Mirroring - configuration package %1 (v%2) activated.', Comment = '%1 = package code, %2 = version', Locked = true;
        PackageDeactivatedAuditMsg: Label 'Microsoft Fabric Open Mirroring - configuration package %1 deactivated.', Comment = '%1 = package code', Locked = true;
        PackageReappliedAuditMsg: Label 'Microsoft Fabric Open Mirroring - configuration package %1 reapplied (v%2).', Comment = '%1 = package code, %2 = version', Locked = true;
        PackageRegisteredViaCodeMsg: Label 'Config package v%1 registered via code.', Comment = '%1 = version', Locked = true;
        PackageReapplySkippedMsg: Label 'Config package reapply skipped during install/upgrade: %1', Comment = '%1 = error message', Locked = true;
        PackageReapplyCapacityErr: Label 'reapply would exceed the %1-table export limit', Comment = '%1 = maximum number of tables', Locked = true;

    internal procedure Activate(var Pkg: Record "Fabric Config Package")
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        NewTableCount: Integer;
        WasNew: Boolean;
    begin
        // LockTable before counting so a concurrent Activate/Deactivate cannot change
        // Tenant Fabric Tables between the capacity check and the inserts below.
        TenantFabricTables.LockTable();

        // Count lines not yet in the platform table
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
                WasNew := not TenantFabricTables.Get(PackageLine."Table ID");
                FabricPlatformMgt.ClaimTable(PackageLine."Table ID", "Fabric Table Claim Source"::Package, Pkg."Code");
                if WasNew and TenantFabricTables.Get(PackageLine."Table ID") then begin
                    TenantFabricTables.Validate("Fabric Schema Type", PackageLine."Fabric Schema Type");
                    TenantFabricTables.Modify(true);
                end;
            until PackageLine.Next() = 0;

        Pkg.Validate(Active, true);
        Pkg.Validate("Activated On", CurrentDateTime());
        Pkg.Validate("Activated By", CopyStr(UserId(), 1, MaxStrLen(Pkg."Activated By")));
        Pkg.Validate("Last Activated Version", Pkg.Version);
        Pkg.Modify(true);

        LogPackageEvent('FAB-150', 'Config package activated.', Pkg."Code");
        Telemetry.LogAudit('FAB-150-AUD', StrSubstNo(PackageActivatedAuditMsg, Pkg."Code", Pkg.Version));
    end;

    internal procedure Deactivate(var Pkg: Record "Fabric Config Package")
    var
        PackageLine: Record "Fabric Config Package Line";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        KeptTableCount: Integer;
    begin
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                // Release this package's claim; the platform row is only deleted when no
                // other claim (manual or another package) remains.
                if FabricPlatformMgt.IsClaimedByOthers(PackageLine."Table ID", "Fabric Table Claim Source"::Package, Pkg."Code") then
                    KeptTableCount += 1;
                FabricPlatformMgt.ReleaseTable(PackageLine."Table ID", "Fabric Table Claim Source"::Package, Pkg."Code");
            until PackageLine.Next() = 0;

        Pkg.Validate(Active, false);
        Pkg.Validate("Activated On", 0DT);
        Pkg.Validate("Activated By", '');
        Pkg.Modify(true);

        LogPackageEvent('FAB-151', 'Config package deactivated.', Pkg."Code");
        Telemetry.LogAudit('FAB-151-AUD', StrSubstNo(PackageDeactivatedAuditMsg, Pkg."Code"));

        if GuiAllowed() and (KeptTableCount > 0) then
            Message(TablesKeptByOtherPackageMsg, KeptTableCount);
    end;

    internal procedure Reapply(var Pkg: Record "Fabric Config Package")
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        NewTableCount: Integer;
        WasNew: Boolean;
    begin
        // Add any missing package tables. Existing rows are left untouched — Reapply
        // never removes rows, so stale tables require an explicit Deactivate/Activate.
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
                WasNew := not TenantFabricTables.Get(PackageLine."Table ID");
                FabricPlatformMgt.ClaimTable(PackageLine."Table ID", "Fabric Table Claim Source"::Package, Pkg."Code");
                if WasNew and TenantFabricTables.Get(PackageLine."Table ID") then begin
                    TenantFabricTables.Validate("Fabric Schema Type", PackageLine."Fabric Schema Type");
                    TenantFabricTables.Modify(true);
                end;
            until PackageLine.Next() = 0;

        Pkg.Validate("Activated On", CurrentDateTime());
        Pkg.Validate("Last Activated Version", Pkg.Version);
        Pkg.Modify(true);

        LogPackageEvent('FAB-152', 'Config package reapplied.', Pkg."Code");
        Telemetry.LogAudit('FAB-152-AUD', StrSubstNo(PackageReappliedAuditMsg, Pkg."Code", Pkg.Version));
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
        RemovedTableIds: List of [Integer];
    begin
        if not UpsertPackageHeader(Pkg, PackageCode, Description, Version) then
            exit; // Already registered at this version — nothing to do

        RebuildPackageLines(PackageCode, TableIds, RemovedTableIds);

        // If it was already active, release claims on dropped tables and reapply so
        // the platform tables stay aligned with the current package definition.
        if Pkg.Active then
            ReapplyAfterRegister(Pkg, RemovedTableIds, PackageCode);

        LogPackageEvent('FAB-155', StrSubstNo(PackageRegisteredViaCodeMsg, Version), PackageCode);
    end;

    local procedure UpsertPackageHeader(var Pkg: Record "Fabric Config Package"; PackageCode: Code[20]; Description: Text[100]; Version: Code[10]): Boolean
    begin
        if not Pkg.Get(PackageCode) then begin
            Pkg.Init();
            Pkg.Validate("Code", PackageCode);
            Pkg.Validate(Description, Description);
            Pkg.Validate(Version, Version);
            Pkg.Insert(true);
            exit(true);
        end;

        if Pkg.Version = Version then
            exit(false);

        Pkg.Validate(Description, Description);
        Pkg.Validate(Version, Version);
        Pkg.Modify(true);
        exit(true);
    end;

    local procedure RebuildPackageLines(PackageCode: Code[20]; TableIds: List of [Integer]; var RemovedTableIds: List of [Integer])
    var
        PackageLine: Record "Fabric Config Package Line";
        AllObj: Record AllObjWithCaption;
        TableId: Integer;
    begin
        // Record table IDs dropped from the new set so their package claim can be
        // released by the caller — otherwise a removed table keeps its stale claim
        // and stays exported forever.
        PackageLine.SetRange("Package Code", PackageCode);
        if PackageLine.FindSet() then
            repeat
                if not TableIds.Contains(PackageLine."Table ID") then
                    RemovedTableIds.Add(PackageLine."Table ID");
            until PackageLine.Next() = 0;
        PackageLine.DeleteAll(false);

        foreach TableId in TableIds do
            if AllObj.Get(AllObj."Object Type"::Table, TableId) then begin
                PackageLine.Init();
                PackageLine.Validate("Package Code", PackageCode);
                PackageLine.Validate("Table ID", TableId);
                PackageLine.Insert(false);
            end else
                LogSkippedTableWarning(PackageCode, TableId);
    end;

    // Reapply can fail (e.g. 500-table cap) — that must not abort install/upgrade.
    // TryFunction can't be used here: AL disallows database writes (Insert/Modify/Delete)
    // inside a TryFunction's call tree, and Reapply/ClaimTable write to Tenant Fabric Tables.
    // So the capacity is checked up front instead of catching the error from Reapply.
    local procedure ReapplyAfterRegister(var Pkg: Record "Fabric Config Package"; var RemovedTableIds: List of [Integer]; PackageCode: Code[20])
    var
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        TableId: Integer;
        NewTableCount: Integer;
    begin
        foreach TableId in RemovedTableIds do
            FabricPlatformMgt.ReleaseTable(TableId, "Fabric Table Claim Source"::Package, PackageCode);

        PackageLine.SetRange("Package Code", PackageCode);
        if PackageLine.FindSet() then
            repeat
                if not TenantFabricTables.Get(PackageLine."Table ID") then
                    NewTableCount += 1;
            until PackageLine.Next() = 0;

        if FabricPlatformMgt.SelectedTableCount() + NewTableCount > FabricPlatformMgt.MaxTableCount() then begin
            LogReapplySkipped(PackageCode, StrSubstNo(PackageReapplyCapacityErr, FabricPlatformMgt.MaxTableCount()));
            exit;
        end;

        Reapply(Pkg);
    end;

    local procedure LogReapplySkipped(PackageCode: Code[20]; ErrorMessage: Text)
    var
        Telemetry: Codeunit "Fabric Platform Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('PackageCode', PackageCode);
        Telemetry.LogFailureEvent('FAB-157', StrSubstNo(PackageReapplySkippedMsg, ErrorMessage), Dimensions);
    end;

    local procedure LogPackageEvent(EventId: Text; EventMessage: Text; PackageCode: Code[20])
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('PackageCode', PackageCode);
        Session.LogMessage(EventId, EventMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure LogSkippedTableWarning(PackageCode: Code[20]; TableId: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('PackageCode', PackageCode);
        Dimensions.Add('TableId', Format(TableId));
        Session.LogMessage('FAB-156', 'Config package: skipped missing table — not found in AllObjWithCaption.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure ExportPackageToStream(var Pkg: Record "Fabric Config Package"; var OutStream: OutStream)
    var
        PackageLine: Record "Fabric Config Package Line";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        JsonText: Text;
    begin
        JsonObj.Add('code', Pkg."Code");
        JsonObj.Add('description', Pkg.Description);
        JsonObj.Add('version', Pkg.Version);
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                JsonArr.Add(PackageLine."Table ID");
            until PackageLine.Next() = 0;
        JsonObj.Add('tables', JsonArr);
        JsonObj.WriteTo(JsonText);
        OutStream.WriteText(JsonText);
    end;

    internal procedure ImportPackageFromStream(var InStream: InStream)
    var
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        TablesToken: JsonToken;
        FieldToken: JsonToken;
        TableElem: JsonToken;
        TableIds: List of [Integer];
        PackageCode: Code[20];
        Description: Text[100];
        Version: Code[10];
        JsonTextBuilder: TextBuilder;
        JsonText: Text;
        Line: Text;
    begin
        while not InStream.EOS() do begin
            InStream.ReadText(Line);
            JsonTextBuilder.Append(Line);
        end;
        JsonText := JsonTextBuilder.ToText();
        if not JsonObj.ReadFrom(JsonText) then
            Error(InvalidPackageFileErr);
        if JsonObj.Get('code', FieldToken) then
            PackageCode := CopyStr(FieldToken.AsValue().AsText(), 1, MaxStrLen(PackageCode));
        if JsonObj.Get('description', FieldToken) then
            Description := CopyStr(FieldToken.AsValue().AsText(), 1, MaxStrLen(Description));
        if JsonObj.Get('version', FieldToken) then
            Version := CopyStr(FieldToken.AsValue().AsText(), 1, MaxStrLen(Version));
        if PackageCode = '' then
            Error(ImportMissingCodeErr);
        if JsonObj.Get('tables', TablesToken) then begin
            JsonArr := TablesToken.AsArray();
            foreach TableElem in JsonArr do
                TableIds.Add(TableElem.AsValue().AsInteger());
        end;
        RegisterPackage(PackageCode, Description, Version, TableIds);
    end;
}
