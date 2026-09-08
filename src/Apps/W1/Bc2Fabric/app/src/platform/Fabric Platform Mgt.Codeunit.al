namespace Microsoft.Bc2Fabric;

using Microsoft.Utilities;
using System.Environment;
using System.Fabric;
using System.Reflection;

#if not PTE
codeunit 150001 "Fabric Platform Mgt"
#else
codeunit 50101 "Fabric Platform Mgt"
#endif
{
    Access = Internal;

    var
        MaxTablesErr: Label 'A maximum of %1 tables can be exported to Microsoft Fabric. Remove a table before adding another.', Comment = '%1 = maximum number of tables';
        TableInvalidErr: Label 'Table %1 does not exist or is not accessible.', Comment = '%1 = table id';
        TableExistsErr: Label 'Table %1 is already selected for export.', Comment = '%1 = table id';
        CompanyInvalidErr: Label 'Company %1 does not exist.', Comment = '%1 = company name';
        CompanyExistsErr: Label 'Company %1 is already selected for export.', Comment = '%1 = company name';
        EnableRequestedMsg: Label 'Enable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StartRequestedMsg: Label 'Start was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StopRequestedMsg: Label 'Stop was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        DisableRequestedMsg: Label 'Disable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        TestConnectionSuccessMsg: Label 'Connection to Microsoft Fabric succeeded.';
        ClientIdRequiredErr: Label 'Client ID must be filled in on the Fabric Platform Setup page before enabling export.';
        ClientIdInvalidErr: Label 'Client ID %1 is not a valid GUID.', Comment = '%1 = client ID';
        ClientSecretRequiredErr: Label 'Client Secret must be filled in on the Fabric Platform Setup page before enabling export.';

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
        TenantFabricSetup.Validate("Max Consecutive Failed Runs", 2);
        TenantFabricSetup.Validate("Fabric Data Namespace", 'BusinessCentral');
        TenantFabricSetup.Validate("Fabric Logging Namespace", 'BusinessCentral_log');
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
        TableMetadata: Record "Table Metadata";
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableId);
        if not AllObjWithCaption.FindFirst() then
            Error(TableInvalidErr, TableId);

        if TenantFabricTables.Get(TableId) then
            Error(TableExistsErr, TableId);

        CheckCanAddTable();

        TenantFabricTables.Init();
        TenantFabricTables.Validate("Table ID", TableId);
        TenantFabricTables."Table Name" := CopyStr(AllObjWithCaption."Object Name", 1, MaxStrLen(TenantFabricTables."Table Name"));
        TenantFabricTables."Fabric Entity Name" := CopyStr(AllObjWithCaption."Object Name", 1, MaxStrLen(TenantFabricTables."Fabric Entity Name"));
        if TableMetadata.Get(TableId) then
            TenantFabricTables."Per Company" := TableMetadata.DataPerCompany
        else
            TenantFabricTables."Per Company" := true;
        TenantFabricTables.Insert(true);
    end;

    procedure AddTables(var AllObjWithCaption: Record AllObjWithCaption)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        NewTableCount: Integer;
    begin
        if AllObjWithCaption.FindSet() then
            repeat
                if not TenantFabricTables.Get(AllObjWithCaption."Object ID") then
                    NewTableCount += 1;
            until AllObjWithCaption.Next() = 0;

        EnsureCapacity(NewTableCount);

        if AllObjWithCaption.FindSet() then
            repeat
                if not TenantFabricTables.Get(AllObjWithCaption."Object ID") then
                    AddTable(AllObjWithCaption."Object ID");
            until AllObjWithCaption.Next() = 0;
    end;

    // -------------------------------------------------------------------------
    // Company selection
    // -------------------------------------------------------------------------

    procedure AddCompany(CompanyName: Text[30])
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        Company: Record Company;
    begin
        if not Company.Get(CompanyName) then
            Error(CompanyInvalidErr, CompanyName);

        if TenantFabricCompanies.Get(CompanyName) then
            Error(CompanyExistsErr, CompanyName);

        TenantFabricCompanies.Init();
        TenantFabricCompanies.Validate("Company Name", CompanyName);
        TenantFabricCompanies.Enabled := true;
        TenantFabricCompanies.Insert(true);
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
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        ClientId: Guid;
        ClientIdText: Text;
        IsHandled: Boolean;
    begin
        // Delegated auth overload: Microsoft first-party authentication is not yet available.
        OnBeforeEnableExport(IsHandled);
        if not IsHandled then begin
            ClientIdText := CredMgt.GetClientId();
            if ClientIdText = '' then
                Error(ClientIdRequiredErr);
            if not Evaluate(ClientId, ClientIdText) then
                Error(ClientIdInvalidErr, ClientIdText);
            if not CredMgt.IsClientSecretSet() then
                Error(ClientSecretRequiredErr);
            FabricExportManager.EnableFabricExport(ClientId, CredMgt.GetClientSecret());
        end;
        Telemetry.LogEvent('FAB-100', 'Fabric export enable requested.');
        Telemetry.LogAudit('FAB-100-AUD', 'Microsoft Fabric Open Mirroring - export enable requested.');
        if GuiAllowed() then
            Message(EnableRequestedMsg);
    end;

    procedure StartExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        IsHandled: Boolean;
    begin
        OnBeforeStartExport(IsHandled);
        if not IsHandled then
            FabricExportManager.StartFabricExport();
        Telemetry.LogEvent('FAB-101', 'Fabric export start requested.');
        Telemetry.LogAudit('FAB-101-AUD', 'Microsoft Fabric Open Mirroring - export start requested.');
        if GuiAllowed() then
            Message(StartRequestedMsg);
    end;

    procedure StopExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        IsHandled: Boolean;
    begin
        OnBeforeStopExport(IsHandled);
        if not IsHandled then
            FabricExportManager.StopFabricExport();
        Telemetry.LogEvent('FAB-102', 'Fabric export stop requested.');
        Telemetry.LogAudit('FAB-102-AUD', 'Microsoft Fabric Open Mirroring - export stop requested.');
        if GuiAllowed() then
            Message(StopRequestedMsg);
    end;

    procedure DisableExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        IsHandled: Boolean;
    begin
        OnBeforeDisableExport(IsHandled);
        if not IsHandled then
            FabricExportManager.DisableFabricExport();
        Telemetry.LogEvent('FAB-103', 'Fabric export disable requested.');
        Telemetry.LogAudit('FAB-103-AUD', 'Microsoft Fabric Open Mirroring - export disable requested.');
        if GuiAllowed() then
            Message(DisableRequestedMsg);
    end;

    procedure TestConnection()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        TempBuffer: Record "Name/Value Buffer" temporary;
        IsHandled: Boolean;
    begin
        OnBeforeTestConnection(IsHandled);
        if not IsHandled then
            AdminClient.GetWorkspaces(TempBuffer);
        Telemetry.LogEvent('FAB-104', 'Fabric connection test succeeded.');
        if GuiAllowed() then
            Message(TestConnectionSuccessMsg);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestConnection(var IsHandled: Boolean)
    begin
    end;
}
