namespace Microsoft.Bc2Fabric;

using System.Fabric;
using System.Reflection;

codeunit 150001 "Fabric Platform Mgt"
{
    Access = Internal;

    var
        MaxTablesErr: Label 'A maximum of %1 tables can be exported to Microsoft Fabric. Remove a table before adding another.', Comment = '%1 = maximum number of tables';
        TableInvalidErr: Label 'Table %1 does not exist or is not accessible.', Comment = '%1 = table id';
        TableExistsErr: Label 'Table %1 is already selected for export.', Comment = '%1 = table id';
        EnableRequestedMsg: Label 'Enable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StartRequestedMsg: Label 'Start was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StopRequestedMsg: Label 'Stop was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        DisableRequestedMsg: Label 'Disable was requested. The platform runs asynchronously; open Export Summary to follow progress.';

    procedure MaxTableCount(): Integer
    begin
        // Platform limit for the number of exported tables.
        exit(500);
    end;

    // -------------------------------------------------------------------------
    // Platform setup singleton
    // -------------------------------------------------------------------------

    procedure EnsureSetup(var TenantFabricSetup: Record "Tenant Fabric Setup")
    begin
        if TenantFabricSetup.FindFirst() then
            exit;

        TenantFabricSetup.Init();
        TenantFabricSetup.Insert(true);
    end;

    procedure HasSetup(): Boolean
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
    begin
        exit(TenantFabricSetup.FindFirst());
    end;

    // -------------------------------------------------------------------------
    // Table selection (500-table platform limit enforced here)
    // -------------------------------------------------------------------------

    procedure SelectedTableCount(): Integer
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
    begin
        exit(TenantFabricTables.Count());
    end;

    procedure CheckCanAddTable()
    var
        MaxTables: Integer;
    begin
        MaxTables := MaxTableCount();
        if SelectedTableCount() >= MaxTables then
            Error(MaxTablesErr, MaxTables);
    end;

    procedure EnsureCapacity(AdditionalCount: Integer)
    var
        MaxTables: Integer;
    begin
        MaxTables := MaxTableCount();
        if SelectedTableCount() + AdditionalCount > MaxTables then
            Error(MaxTablesErr, MaxTables);
    end;

    procedure AddTable(TableId: Integer)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableId);
        if AllObjWithCaption.IsEmpty() then
            Error(TableInvalidErr, TableId);

        if TenantFabricTables.Get(TableId) then
            Error(TableExistsErr, TableId);

        CheckCanAddTable();

        TenantFabricTables.Init();
        TenantFabricTables.Validate("Table ID", TableId);
        TenantFabricTables.Insert(true);
    end;

    // -------------------------------------------------------------------------
    // Lifecycle — thin wrappers over the platform Fabric Export Manager.
    // Every operation is asynchronous: the platform acknowledges quickly and
    // reports progress through the Tenant Fabric Export Summary/Details tables.
    // The OnBefore* events are the testability seam so lifecycle can be verified
    // without triggering a real ADF pipeline run.
    // -------------------------------------------------------------------------

    procedure EnableExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        IsHandled: Boolean;
    begin
        // Parameterless overload = Microsoft first-party authentication.
        OnBeforeEnableExport(IsHandled);
        if not IsHandled then
            FabricExportManager.EnableFabricExport();
        if GuiAllowed() then
            Message(EnableRequestedMsg);
    end;

    procedure StartExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        IsHandled: Boolean;
    begin
        OnBeforeStartExport(IsHandled);
        if not IsHandled then
            FabricExportManager.StartFabricExport();
        if GuiAllowed() then
            Message(StartRequestedMsg);
    end;

    procedure StopExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        IsHandled: Boolean;
    begin
        OnBeforeStopExport(IsHandled);
        if not IsHandled then
            FabricExportManager.StopFabricExport();
        if GuiAllowed() then
            Message(StopRequestedMsg);
    end;

    procedure DisableExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        IsHandled: Boolean;
    begin
        OnBeforeDisableExport(IsHandled);
        if not IsHandled then
            FabricExportManager.DisableFabricExport();
        if GuiAllowed() then
            Message(DisableRequestedMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnableExport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartExport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStopExport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisableExport(var IsHandled: Boolean)
    begin
    end;
}
