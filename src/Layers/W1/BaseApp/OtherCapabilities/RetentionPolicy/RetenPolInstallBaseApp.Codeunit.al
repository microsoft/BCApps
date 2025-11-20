namespace System.DataAdministration;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Projects.Project.Archive;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.Archive;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using System.Automation;
using System.Diagnostics;
using System.Environment.Configuration;
using System.IO;
using System.Threading;
using System.Upgrade;
using System.Utilities;

#pragma warning disable AA0235
codeunit 3999 "Reten. Pol. Install - BaseApp"
#pragma warning restore AA0235
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "Retention Period" = ri, tabledata "Retention Policy Setup" = ri;

    trigger OnInstallAppPerCompany()
    begin
        AddAllowedTables();
    end;

    procedure AddAllowedTables()
    begin
        AddAllowedTables(false);
    end;

    procedure AddAllowedTables(ForceUpdate: Boolean)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsInitialSetup: Boolean;
    begin
        // if you add a new table here, also update codeunit 3995 "Base Application Logs Delete"
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddChangeLogEntryToAllowedTables(IsInitialSetup);
            RetenPolAllowedTables.AddAllowedTable(Database::"Job Queue Log Entry", JobQueueLogEntry.FieldNo("End Date/Time"));
            RetenPolAllowedTables.AddAllowedTable(Database::"Workflow Step Instance Archive");
            RetenPolAllowedTables.AddAllowedTable(Database::"Report Inbox");
            RetenPolAllowedTables.AddAllowedTable(Database::"Error Message");
            RetenPolAllowedTables.AddAllowedTable(Database::"Error Message Register");
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddDocumentArchiveTablesToAllowedTables();
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolDataverseEntityChangeUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddDataverseEntityChange(IsInitialSetup);
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolDataverseEntityChangeUpgradeTag());
        end;

        if (not UpgradeTag.HasUpgradeTag(GetRetenPolActivityLogUpgradeTag())) or ForceUpdate then begin
            RetenPolAllowedTables.AddAllowedTable(Database::"Activity Log");
            if not UpgradeTag.HasUpgradeTag(GetRetenPolActivityLogUpgradeTag()) then
                UpgradeTag.SetUpgradeTag(GetRetenPolActivityLogUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolProtectedChangeLogUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddChangeLogEntryToAllowedTables(IsInitialSetup);
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolProtectedChangeLogUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolPostedWhseTablesUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddRegisteredWhseActivityHdrToAllowedTables(IsInitialSetup);
            AddPostedWhseShipmentHeaderToAllowedTables(IsInitialSetup);
            AddPostedWhseReceiptHeaderToAllowedTables();
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolPostedWhseTablesUpgradeTag());

            IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolSentNotifcationEntryUpgradeTag());
            if IsInitialSetup or ForceUpdate then begin
                AddSentNotifcationEntryToAllowedTables();
                if IsInitialSetup then
                    UpgradeTag.SetUpgradeTag(GetRetenPolSentNotifcationEntryUpgradeTag());
            end;
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolCRMIntegrationSynchUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddCRMIntegrationSynch(IsInitialSetup);
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolCRMIntegrationSynchUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolInventoryTablesUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddPostedInvtPickHeaderToAllowedTables(IsInitialSetup);
            AddPostedInvtPutawayHeaderToAllowedTables(IsInitialSetup);
            AddRegisteredInvtMovementHdrToAllowedTables(IsInitialSetup);
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolInventoryTablesUpgradeTag());
        end;

        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetRetenPolDataExchUpgradeTag());
        if IsInitialSetup or ForceUpdate then begin
            AddDataExchangeToAllowedTables();
            if IsInitialSetup then
                UpgradeTag.SetUpgradeTag(GetRetenPolDataExchUpgradeTag());
        end;
    end;

    local procedure AddChangeLogEntryToAllowedTables(IsInitialSetup: Boolean)
    var
        ChangeLogEntry: Record "Change Log Entry";
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        ChangeLogEntry.SetRange(Protected, true);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"1 Year", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeLogEntry."Field Log Entry Feature"::All);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"28 Days", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetRange(Protected, false);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"1 Year", ChangeLogEntry.FieldNo(SystemCreatedAt), true, false, RecRef);

        RetenPolAllowedTables.AddAllowedTable(Database::"Change Log Entry", ChangeLogEntry.FieldNo(SystemCreatedAt), TableFilters);

        if not IsInitialSetup then
            exit;

        if RetentionPolicySetup.Get(Database::"Change Log Entry") then
            exit;

        RetentionPolicySetup.Validate("Table Id", Database::"Change Log Entry");
        RetentionPolicySetup.Insert(true);
    end;

    local procedure AddRegisteredWhseActivityHdrToAllowedTables(IsInitialSetup: Boolean)
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Registered Whse. Activity Hdr.", RegisteredWhseActivityHdr.FieldNo("Registering Date"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Registered Whse. Activity Hdr.", FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Year"));
    end;

    local procedure AddPostedWhseShipmentHeaderToAllowedTables(IsInitialSetup: Boolean)
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin

        RetenPolAllowedTables.AddAllowedTable(Database::"Posted Whse. Shipment Header", PostedWhseShipmentHeader.FieldNo("Posting Date"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Posted Whse. Shipment Header", FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Year"));
    end;

    local procedure AddPostedWhseReceiptHeaderToAllowedTables()
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        RetentionPeriod: Enum "Retention Period Enum";
        TableFilters: JsonArray;
    begin
        PostedWhseReceiptHeader.SetRange("Document Status", PostedWhseReceiptHeader."Document Status"::"Partially Put Away");
        RecRef.GetTable(PostedWhseReceiptHeader);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", PostedWhseReceiptHeader.FieldNo("Posting Date"), true, true, RecRef);  // locked
        PostedWhseReceiptHeader.Reset();
        PostedWhseReceiptHeader.SetRange("Document Status", PostedWhseReceiptHeader."Document Status"::"Completely Put Away");
        RecRef.GetTable(PostedWhseReceiptHeader);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"1 Year", PostedWhseReceiptHeader.FieldNo("Posting Date"), true, false, RecRef);  // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Posted Whse. Receipt Header", PostedWhseReceiptHeader.FieldNo("Posting Date"), TableFilters);
    end;

    local procedure AddDocumentArchiveTablesToAllowedTables()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        JobArchive: Record "Job Archive";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        SalesHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        SalesHeaderArchive.Reset();
        SalesHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Sales Header Archive", SalesHeaderArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);

        Clear(TableFilters);
        PurchaseHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(PurchaseHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        PurchaseHeaderArchive.Reset();
        PurchaseHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(PurchaseHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Purchase Header Archive", PurchaseHeaderArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);

        Clear(TableFilters);
        JobArchive.SetFilter(Status, '<>%1', JobArchive.Status::"Completed");
        RecRef.GetTable(JobArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", JobArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Job Archive", JobArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);

        OnAfterAddDocumentArchiveTablesToAllowedTables();
    end;

    local procedure AddPostedInvtPickHeaderToAllowedTables(IsInitialSetup: Boolean)
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Posted Invt. Pick Header", PostedInvtPickHeader.FieldNo("Registering Date"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Posted Invt. Pick Header", FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Year"));
    end;

    local procedure AddPostedInvtPutawayHeaderToAllowedTables(IsInitialSetup: Boolean)
    var
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Posted Invt. Put-away Header", PostedInvtPutawayHeader.FieldNo("Registering Date"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Posted Invt. Put-away Header", FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Year"));
    end;

    local procedure AddRegisteredInvtMovementHdrToAllowedTables(IsInitialSetup: Boolean)
    var
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Registered Invt. Movement Hdr.", RegisteredInvtMovementHdr.FieldNo("Registering Date"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Registered Invt. Movement Hdr.", FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Year"));
    end;

    local procedure AddDataverseEntityChange(IsInitialSetup: Boolean)
    var
        DataverseEntityChange: Record "Dataverse Entity Change";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Dataverse Entity Change", DataverseEntityChange.FieldNo(SystemCreatedAt));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Dataverse Entity Change", FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Week"));
        EnableRetentionPolicySetup(Database::"Dataverse Entity Change");
    end;

    local procedure AddSentNotifcationEntryToAllowedTables()
    var
        SentNotificationEntry: Record "Sent Notification Entry";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        RecRef.GetTable(SentNotificationEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, Enum::"Retention Period Enum"::"6 Months", SentNotificationEntry.FieldNo("Sent Date-Time"), true, false, RecRef);  // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Sent Notification Entry", SentNotificationEntry.FieldNo("Sent Date-Time"), TableFilters);
    end;

    local procedure AddCRMIntegrationSynch(IsInitialSetup: Boolean)
    var
        IntegrationSyncJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job", IntegrationSyncJob.FieldNo("Finish Date/Time"));
        RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job Errors", IntegrationSynchJobErrors.FieldNo("Date/Time"));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Integration Synch. Job", FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Month"));
        EnableRetentionPolicySetup(Database::"Integration Synch. Job");

        CreateRetentionPolicySetup(Database::"Integration Synch. Job Errors", FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Month"));
        EnableRetentionPolicySetup(Database::"Integration Synch. Job Errors");
    end;

    local procedure AddDataExchangeToAllowedTables()
    var
        DataExch: Record "Data Exch.";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Data Exch.", DataExch.FieldNo(SystemCreatedAt));
    end;

    local procedure FindOrCreateRetentionPeriod(RetentionPeriodEnum: Enum "Retention Period Enum"): Code[20]
    var
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        exit(RetentionPolicySetup.FindOrCreateRetentionPeriod(RetentionPeriodEnum))
    end;

    local procedure CreateRetentionPolicySetup(TableId: Integer; RetentionPeriodCode: Code[20])
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(TableId) then
            exit;
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate(Enabled, false);
        RetentionPolicySetup.Insert(true);
    end;

    local procedure EnableRetentionPolicySetup(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TaskScheduler.CanCreateTask() then
            exit;

        if not (JobQueueEntry.ReadPermission() and JobQueueEntry.WritePermission()) then
            exit;

        if not JobQueueEntry.HasRequiredPermissions() then
            exit;

        if not RetentionPolicySetup.Get(TableId) then
            exit;

        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Modify(true);
    end;

    local procedure GetRetenPolBaseAppTablesUpgradeTag(): Code[250]
    begin
        exit('MS-334067-RetenPolBaseAppTables-20200801');
    end;

    local procedure GetRetenPolDocArchivesTablesUpgradeTag(): Code[250]
    begin
        exit('MS-378964-RetenPolDocArchives-20210423');
    end;

    local procedure GetRetenPolDataverseEntityChangeUpgradeTag(): Code[250]
    begin
        exit('MS-434662-RetenPolDataverseEntityChange-20220428');
    end;

    local procedure GetRetenPolActivityLogUpgradeTag(): Code[250]
    begin
        exit('MS-436257-RetenPolActivityLog-20220526');
    end;

    local procedure GetRetenPolProtectedChangeLogUpgradeTag(): Code[250]
    begin
        exit('MS-447066-RetenPolProtectedChangeLog-20221003');
    end;

    local procedure GetRetenPolPostedWhseTablesUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-9-RetenPolPostedWhseTables-20230823');
    end;

    local procedure GetRetenPolSentNotifcationEntryUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-422-RetenPolSentNotifcationEntry-20230829');
    end;

    local procedure GetRetenPolCRMIntegrationSynchUpgradeTag(): Code[250]
    begin
        exit('MS-542758-RetenPolCRMIntegrationSynch-20240820');
    end;

    local procedure GetRetenPolInventoryTablesUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-1268-RetenPolInventoryTables-20250608');
    end;

    local procedure GetRetenPolDataExchUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-704-RetenPolDataExch-20250713');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", 'OnRefreshAllowedTables', '', false, false)]
    local procedure AddAllowedTablesOnRefreshAllowedTables()
    begin
        AddAllowedTables(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeOnRun', '', false, false)]
    local procedure AddAllowedTablesOnBeforeCompanyInit()
    begin
        AddAllowedTables();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddDocumentArchiveTablesToAllowedTables()
    begin
    end;
}