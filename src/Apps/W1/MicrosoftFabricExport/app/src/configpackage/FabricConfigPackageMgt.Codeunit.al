namespace Microsoft.FabricExport;

using System.Fabric;
using System.Reflection;

codeunit 9121 "Fabric Config Package Mgt"
{

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
                if not TenantFabricTables.Get(PackageLine."Table ID") then begin
                    FabricPlatformMgt.AddTable(PackageLine."Table ID");
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
        Telemetry: Codeunit "Fabric Platform Telemetry";
        PackageLine: Record "Fabric Config Package Line";
        TenantFabricTables: Record "Tenant Fabric Tables";
        OtherPackageCode: Code[20];
        KeptTableCount: Integer;
    begin
        PackageLine.SetRange("Package Code", Pkg."Code");
        if PackageLine.FindSet() then
            repeat
                // Remove the table only when no other active package still needs it.
                // The platform Tenant Fabric Tables has no ownership column, so a table that
                // also matches a manually-added selection cannot be distinguished here.
                if not FindOtherActivePackage(PackageLine."Table ID", Pkg."Code", OtherPackageCode) then begin
                    if TenantFabricTables.Get(PackageLine."Table ID") then
                        TenantFabricTables.Delete(true);
                end else
                    KeptTableCount += 1;
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
        Telemetry: Codeunit "Fabric Platform Telemetry";
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
                if not TenantFabricTables.Get(PackageLine."Table ID") then begin
                    FabricPlatformMgt.AddTable(PackageLine."Table ID");
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
                LogSkippedTableWarning(PackageCode, TableId);
        end;

        // If it was already active, reapply so the platform tables stay in sync
        if Pkg.Active then
            Reapply(Pkg);

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
