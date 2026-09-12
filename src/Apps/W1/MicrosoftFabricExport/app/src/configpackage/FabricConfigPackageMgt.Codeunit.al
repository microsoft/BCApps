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

    internal procedure Activate(var Pkg: Record "Fabric Config Package")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
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
                if WasNew then begin
                    TenantFabricTables.Get(PackageLine."Table ID");
                    TenantFabricTables.Validate("Fabric Schema Type", PackageLine."Fabric Schema Type");
                    TenantFabricTables.Modify(true);
                end;
            until PackageLine.Next() = 0;

        Pkg.Active := true;
        Pkg."Activated On" := CurrentDateTime();
        Pkg."Activated By" := CopyStr(UserId(), 1, MaxStrLen(Pkg."Activated By"));
        Pkg."Last Activated Version" := Pkg.Version;
        Pkg.Modify(true);

        LogPackageEvent('FAB-150', 'Config package activated.', Pkg."Code");
        Telemetry.LogAudit('FAB-150-AUD', StrSubstNo('Microsoft Fabric Open Mirroring - configuration package %1 (v%2) activated.', Pkg."Code", Pkg.Version));
    end;

    internal procedure Deactivate(var Pkg: Record "Fabric Config Package")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        PackageLine: Record "Fabric Config Package Line";
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

        Pkg.Active := false;
        Pkg."Activated On" := 0DT;
        Pkg."Activated By" := '';
        Pkg.Modify(true);

        LogPackageEvent('FAB-151', 'Config package deactivated.', Pkg."Code");
        Telemetry.LogAudit('FAB-151-AUD', StrSubstNo('Microsoft Fabric Open Mirroring - configuration package %1 deactivated.', Pkg."Code"));

        if GuiAllowed() and (KeptTableCount > 0) then
            Message(TablesKeptByOtherPackageMsg, KeptTableCount);
    end;

    internal procedure Reapply(var Pkg: Record "Fabric Config Package")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
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
                if WasNew then begin
                    TenantFabricTables.Get(PackageLine."Table ID");
                    TenantFabricTables.Validate("Fabric Schema Type", PackageLine."Fabric Schema Type");
                    TenantFabricTables.Modify(true);
                end;
            until PackageLine.Next() = 0;

        Pkg."Activated On" := CurrentDateTime();
        Pkg."Last Activated Version" := Pkg.Version;
        Pkg.Modify(true);

        LogPackageEvent('FAB-152', 'Config package reapplied.', Pkg."Code");
        Telemetry.LogAudit('FAB-152-AUD', StrSubstNo('Microsoft Fabric Open Mirroring - configuration package %1 reapplied (v%2).', Pkg."Code", Pkg.Version));
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
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        RemovedTableIds: List of [Integer];
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

        // Rebuild lines. Record table IDs dropped from the new set so their package
        // claim can be released below — otherwise a table removed from the package
        // keeps its stale claim and stays exported forever.
        PackageLine.SetRange("Package Code", PackageCode);
        if PackageLine.FindSet() then
            repeat
                if not TableIds.Contains(PackageLine."Table ID") then
                    RemovedTableIds.Add(PackageLine."Table ID");
            until PackageLine.Next() = 0;
        PackageLine.DeleteAll(true);

        foreach TableId in TableIds do begin
            if AllObj.Get(AllObj."Object Type"::Table, TableId) then begin
                PackageLine.Init();
                PackageLine."Package Code" := PackageCode;
                PackageLine.Validate("Table ID", TableId);
                PackageLine.Insert(true);
            end else
                LogSkippedTableWarning(PackageCode, TableId);
        end;

        // If it was already active, release claims on dropped tables and reapply so
        // the platform tables stay aligned with the current package definition.
        if Pkg.Active then begin
            foreach TableId in RemovedTableIds do
                FabricPlatformMgt.ReleaseTable(TableId, "Fabric Table Claim Source"::Package, PackageCode);
            Reapply(Pkg);
        end;

        LogPackageEvent('FAB-155', StrSubstNo('Config package v%1 registered via code.', Version), PackageCode);
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
