namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.Environment;
using System.Fabric;
using System.Reflection;

codeunit 48520 "Fabric Platform Mgt"
{
    // Mediates writes to the platform selection tables (500-table cap, existence checks),
    // so callers only need read access to these tables directly.
    Permissions = tabledata "Fabric Table Claim" = RIMD,
                  tabledata "Tenant Fabric Companies" = RIMD,
                  tabledata "Tenant Fabric Tables" = RIMD;

    var
        MaxTablesErr: Label 'A maximum of %1 tables can be exported to Microsoft Fabric. Remove a table before adding another.', Comment = '%1 = maximum number of tables';
        TableInvalidErr: Label 'Table %1 does not exist or is not accessible.', Comment = '%1 = table id';
        TableExistsErr: Label 'Table %1 is already selected for export.', Comment = '%1 = table id';
        CompanyInvalidErr: Label 'Company %1 does not exist.', Comment = '%1 = company name';
        CompanyExistsErr: Label 'Company %1 is already selected for export.', Comment = '%1 = company name';
        EnableRequestedMsg: Label 'Enable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StartRequestedMsg: Label 'Start was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StopRequestedMsg: Label 'Stop was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        DisableRequestedMsg: Label 'Reset was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        EnableOnCooldownErr: Label 'Enable was already requested recently. Try again in %1 minute(s).', Comment = '%1 = minutes remaining';
        SyncAlreadyRunningMsg: Label 'A synchronization run is already in progress. Use Stop synchronization before starting a new run.';
        TestConnectionSuccessMsg: Label 'Connection to Microsoft Fabric succeeded.';
        ClientIdRequiredErr: Label 'Client ID must be filled in on the Fabric Platform Setup page before enabling export.';
        ClientIdInvalidErr: Label 'Client ID %1 is not a valid GUID.', Comment = '%1 = client ID';
        ClientSecretRequiredErr: Label 'Client Secret must be filled in on the Fabric Platform Setup page before enabling export.';
        OpenFabricSetupLbl: Label 'Open Fabric Platform Setup';
        SetupRequiredTitleLbl: Label 'Setup required';
        SetupRequiredDetailedMsg: Label 'Open the Fabric Platform Setup page, fill in the missing value described above, and run Enable again.';

    internal procedure MaxTableCount(): Integer
    begin
        // Platform limit for the number of exported tables.
        exit(500);
    end;

    // -------------------------------------------------------------------------
    // Platform setup singleton
    // -------------------------------------------------------------------------

    internal procedure EnsureSetup(var TenantFabricSetup: Record "Tenant Fabric Setup")
    begin
        if TenantFabricSetup.FindFirst() then
            exit;

        TenantFabricSetup.Init();
        TenantFabricSetup.Validate("Max Consecutive Failed Runs", 2);
        TenantFabricSetup.Validate("Fabric Data Namespace", 'BusinessCentral');
        TenantFabricSetup.Validate("Fabric Logging Namespace", 'BusinessCentral_log');
        TenantFabricSetup.Insert(true);
    end;

    internal procedure HasSetup(): Boolean
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
    begin
        exit(not TenantFabricSetup.IsEmpty());
    end;

    // -------------------------------------------------------------------------
    // Table selection (500-table platform limit enforced here)
    // -------------------------------------------------------------------------

    internal procedure SelectedTableCount(): Integer
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
    begin
        exit(TenantFabricTables.Count());
    end;

    internal procedure CheckCanAddTable()
    var
        MaxTables: Integer;
    begin
        MaxTables := MaxTableCount();
        if SelectedTableCount() >= MaxTables then
            Error(MaxTablesErr, MaxTables);
    end;

    internal procedure EnsureCapacity(AdditionalCount: Integer)
    var
        MaxTables: Integer;
    begin
        MaxTables := MaxTableCount();
        if SelectedTableCount() + AdditionalCount > MaxTables then
            Error(MaxTablesErr, MaxTables);
    end;

    internal procedure AddTable(TableId: Integer)
    begin
        CheckCanAddTable();
        InsertTable(TableId);
        InsertClaim(TableId, "Fabric Table Claim Source"::Manual, '');
    end;

    local procedure InsertTable(TableId: Integer)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        AllObjWithCaption: Record AllObjWithCaption;
        TableMetadata: Record "Table Metadata";
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableId) then
            Error(TableInvalidErr, TableId);

        if TenantFabricTables.Get(TableId) then
            Error(TableExistsErr, TableId);

        TenantFabricTables.Init();
        TenantFabricTables.Validate("Table ID", TableId);
        TenantFabricTables.Validate("Table Name", CopyStr(AllObjWithCaption."Object Name", 1, MaxStrLen(TenantFabricTables."Table Name")));
        TenantFabricTables.Validate("Fabric Entity Name", CopyStr(AllObjWithCaption."Object Name", 1, MaxStrLen(TenantFabricTables."Fabric Entity Name")));
        if TableMetadata.Get(TableId) then
            TenantFabricTables.Validate("Per Company", TableMetadata.DataPerCompany)
        else
            TenantFabricTables.Validate("Per Company", true);
        TenantFabricTables.Insert(true);
    end;

    internal procedure AddTables(var AllObjWithCaption: Record AllObjWithCaption)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        NewTableCount: Integer;
    begin
        AllObjWithCaption.SetLoadFields("Object ID");

        if AllObjWithCaption.FindSet() then
            repeat
                if not TenantFabricTables.Get(AllObjWithCaption."Object ID") then
                    NewTableCount += 1;
            until AllObjWithCaption.Next() = 0;

        EnsureCapacity(NewTableCount);

        if AllObjWithCaption.FindSet() then
            repeat
                if not TenantFabricTables.Get(AllObjWithCaption."Object ID") then begin
                    InsertTable(AllObjWithCaption."Object ID");
                    InsertClaim(AllObjWithCaption."Object ID", "Fabric Table Claim Source"::Manual, '');
                end;
            until AllObjWithCaption.Next() = 0;
    end;

    // -------------------------------------------------------------------------
    // Table selection ownership (claims)
    // A Tenant Fabric Tables row is kept while any claim exists and is removed only
    // when its last claim is released, so a manual selection is never deleted by
    // package deactivation. Coordination is limited to claims recorded through this
    // app; see docs/PlatformRequest-TableOwnership.md for the platform-level design.
    // -------------------------------------------------------------------------

    internal procedure ClaimTable(TableId: Integer; SourceType: Enum "Fabric Table Claim Source"; PackageCode: Code[20])
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
    begin
        if TenantFabricTables.Get(TableId) then begin
            // Adopt a pre-existing (manually added) selection so a later package
            // release cannot delete it.
            if not HasAnyClaim(TableId) then
                InsertClaim(TableId, "Fabric Table Claim Source"::Manual, '');
        end else begin
            CheckCanAddTable();
            InsertTable(TableId);
        end;

        InsertClaim(TableId, SourceType, PackageCode);
    end;

    internal procedure ReleaseTable(TableId: Integer; SourceType: Enum "Fabric Table Claim Source"; PackageCode: Code[20])
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        Claim: Record "Fabric Table Claim";
    begin
        if Claim.Get(TableId, SourceType, PackageCode) then
            Claim.Delete(true);

        if not HasAnyClaim(TableId) then
            if TenantFabricTables.Get(TableId) then
                TenantFabricTables.Delete(true);
    end;

    internal procedure IsClaimedByOthers(TableId: Integer; SourceType: Enum "Fabric Table Claim Source"; PackageCode: Code[20]): Boolean
    var
        Claim: Record "Fabric Table Claim";
    begin
        Claim.SetRange("Table ID", TableId);
        Claim.SetFilter("Source Type", '<>%1', SourceType);
        if not Claim.IsEmpty() then
            exit(true);

        Claim.SetRange("Source Type", SourceType);
        Claim.SetFilter("Package Code", '<>%1', PackageCode);
        exit(not Claim.IsEmpty());
    end;

    local procedure HasAnyClaim(TableId: Integer): Boolean
    var
        Claim: Record "Fabric Table Claim";
    begin
        Claim.SetRange("Table ID", TableId);
        exit(not Claim.IsEmpty());
    end;

    local procedure InsertClaim(TableId: Integer; SourceType: Enum "Fabric Table Claim Source"; PackageCode: Code[20])
    var
        Claim: Record "Fabric Table Claim";
    begin
        if Claim.Get(TableId, SourceType, PackageCode) then
            exit;
        Claim.Init();
        Claim.Validate("Table ID", TableId);
        Claim.Validate("Source Type", SourceType);
        Claim.Validate("Package Code", PackageCode);
        Claim.Insert(true);
    end;

    // -------------------------------------------------------------------------
    // Company selection
    // -------------------------------------------------------------------------

    internal procedure AddCompany(CompanyName: Text[30])
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
        TenantFabricCompanies.Validate(Enabled, true);
        TenantFabricCompanies.Insert(true);
    end;

    // -------------------------------------------------------------------------
    // Lifecycle — thin wrappers over the platform Fabric Export Manager.
    // Every operation is asynchronous: the platform acknowledges quickly and
    // reports progress through the Tenant Fabric Export Summary/Details tables.
    // The OnBefore* events are the testability seam so lifecycle can be verified
    // without triggering a real ADF pipeline run.
    // -------------------------------------------------------------------------

    internal procedure EnableExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        ClientId: Guid;
        ClientIdText: Text;
        IsHandled: Boolean;
    begin
        CheckEnableNotOnCooldown(CredMgt);

        // Privacy approval is a compliance gate and must not be skippable via the seam below.
        FabricPrivacyNotice.EnsureApproved();

        // Delegated auth overload: Microsoft first-party authentication is not yet available.
        CredMgt.SetLastEnableRequestedAt(CurrentDateTime());
        OnBeforeEnableExport(IsHandled);
        if not IsHandled then begin
            ClientIdText := CredMgt.GetClientId();
            if ClientIdText = '' then
                Error(CreateSetupErrorInfo(ClientIdRequiredErr));
            if not Evaluate(ClientId, ClientIdText) then
                Error(CreateSetupErrorInfo(StrSubstNo(ClientIdInvalidErr, ClientIdText)));
            if not CredMgt.IsClientSecretSet() then
                Error(CreateSetupErrorInfo(ClientSecretRequiredErr));
            FabricExportManager.EnableFabricExport(ClientId, CredMgt.GetClientSecret());
        end;
        Telemetry.LogEvent('FAB-100', 'Fabric export enable requested.');
        Telemetry.LogAudit('FAB-100-AUD', 'Microsoft Fabric Open Mirroring - export enable requested.');
        if GuiAllowed() then
            Message(EnableRequestedMsg);
    end;

    local procedure CheckEnableNotOnCooldown(var CredMgt: Codeunit "Fabric Platform Credential Mgt")
    var
        LastEnableRequestedAt: DateTime;
        RemainingMs: Duration;
    begin
        LastEnableRequestedAt := CredMgt.GetLastEnableRequestedAt();
        if LastEnableRequestedAt = 0DT then
            exit;
        RemainingMs := EnableCooldownDuration() - (CurrentDateTime() - LastEnableRequestedAt);
        if RemainingMs <= 0 then
            exit;
        // A new Enable is safe only after the Setup run triggered by the prior request has finished.
        if IsSetupRunFinishedSince(LastEnableRequestedAt) then
            exit;
        Error(EnableOnCooldownErr, (RemainingMs div 60000) + 1);
    end;

    local procedure IsSetupRunFinishedSince(EnableRequestedAt: DateTime): Boolean
    var
        TenantFabricExportSummary: Record "Tenant Fabric Export Summary";
    begin
        TenantFabricExportSummary.SetRange(Type, TenantFabricExportSummary.Type::Setup);
        TenantFabricExportSummary.SetFilter("Start Time", '>=%1', EnableRequestedAt);
        TenantFabricExportSummary.SetFilter(State, '<>%1', TenantFabricExportSummary.State::Running);
        exit(not TenantFabricExportSummary.IsEmpty());
    end;

    local procedure EnableCooldownDuration(): Duration
    begin
        // Prevents duplicate platform enable requests fired in quick succession.
        exit(15 * 60 * 1000);
    end;

    local procedure CreateSetupErrorInfo(ErrorMessage: Text) SetupErrorInfo: ErrorInfo
    begin
        SetupErrorInfo := ErrorInfo.Create(ErrorMessage);
        SetupErrorInfo.Title(SetupRequiredTitleLbl);
        SetupErrorInfo.DetailedMessage(SetupRequiredDetailedMsg);
        SetupErrorInfo.PageNo(Page::"Fabric Platform Setup");
        SetupErrorInfo.AddNavigationAction(OpenFabricSetupLbl);
    end;

    internal procedure StartExport()
    var
        FabricExportManager: Codeunit "Fabric Export Manager";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        IsHandled: Boolean;
    begin
        if IsSyncAlreadyRunning() then begin
            if GuiAllowed() then
                Message(SyncAlreadyRunningMsg);
            exit;
        end;

        // Privacy approval is a compliance gate and must not be skippable via the seam below.
        FabricPrivacyNotice.EnsureApproved();

        OnBeforeStartExport(IsHandled);
        if not IsHandled then
            FabricExportManager.StartFabricExport();
        Telemetry.LogEvent('FAB-101', 'Fabric export start requested.');
        Telemetry.LogAudit('FAB-101-AUD', 'Microsoft Fabric Open Mirroring - export start requested.');
        if GuiAllowed() then
            Message(StartRequestedMsg);
    end;

    local procedure IsSyncAlreadyRunning(): Boolean
    var
        TenantFabricExportSummary: Record "Tenant Fabric Export Summary";
    begin
        TenantFabricExportSummary.SetRange(Type, TenantFabricExportSummary.Type::Export);
        TenantFabricExportSummary.SetRange(State, TenantFabricExportSummary.State::Running);
        exit(not TenantFabricExportSummary.IsEmpty());
    end;

    internal procedure StopExport()
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

    internal procedure DisableExport()
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

    internal procedure TestConnection()
    var
        TempBuffer: Record "Name/Value Buffer" temporary;
        AdminClient: Codeunit "Fabric Platform Admin Client";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        IsHandled: Boolean;
        IsSuccess: Boolean;
    begin
        OnBeforeTestConnection(IsHandled, IsSuccess);
        if not IsHandled then begin
            AdminClient.GetWorkspaces(TempBuffer);
            IsSuccess := true;
        end;
        // A subscriber must explicitly confirm success; skipping the probe no longer implies it.
        if not IsSuccess then
            exit;
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
    local procedure OnBeforeTestConnection(var IsHandled: Boolean; var IsSuccess: Boolean)
    begin
    end;
}
