namespace Microsoft.Integration.MDM;

using Microsoft.Integration.SyncEngine;
using System.Automation;
using System.Integration;
using System.Threading;
using System.Upgrade;

/// <summary>
/// Codeunit Master Data Mgt. Upgrade (ID 7238).
/// </summary>
codeunit 7238 "Master Data Mgt. Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    Permissions = tabledata "Integration Field Mapping" = rimd,
                  tabledata "Integration Table Mapping" = rimd,
                  tabledata "Tenant Web Service" = rimd;

    trigger OnUpgradePerCompany()
    begin
        UpgradeJobQueueEntryFrequencies();
    end;

    trigger OnUpgradePerDatabase()
    begin
        RegisterCrossEnvSourceWebService();
    end;

    // Guaranteed provisioning path: install codeunits are skipped when BC is pre-baked into a package and mounted per tenant.
    internal procedure RegisterCrossEnvSourceWebService()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetCrossEnvWebServiceUpgradeTag()) then
            exit;

        // Idempotent: creates or updates the service. Access stays gated by the dedicated "Cross Env" permission set, not by publishing.
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Codeunit, Codeunit::"MDM Cross-Env Source API", CrossEnvSourceWebServiceName(), true);

        UpgradeTag.SetDatabaseUpgradeTag(GetCrossEnvWebServiceUpgradeTag());
    end;

    internal procedure CrossEnvSourceWebServiceName(): Text[240]
    begin
        exit('MDMCrossEnvSource');
    end;

    internal procedure UpgradeJobQueueEntryFrequencies()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RestrictedRecord: Record "Restricted Record";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        UpgradeTag: Codeunit "Upgrade Tag";
        MDMMappingsExist: Boolean;
        NotAllJobQueueEntriesModified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetJobQueueFrequencyUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        MDMMappingsExist := not IntegrationTableMapping.IsEmpty();
        IntegrationTableMapping.Reset();

        if MDMMappingsExist then begin
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
            JobQueueEntry.SetRange("Recurring Job", true);
            // change only those who have default values. if they are not default, customer has changed them, and we don't touch
            JobQueueEntry.SetRange("Inactivity Timeout Period", 30);
            if JobQueueEntry.FindSet() then
                repeat
                    if IntegrationTableMapping.Get(JobQueueEntry."Record ID to Process") then
                        if IntegrationTableMapping.Type = IntegrationTableMapping.Type::"Master Data Management" then
                            if IntegrationTableMapping."Disable Event Job Resch." = false then begin
                                // only change if it had default value
                                if JobQueueEntry."No. of Minutes between Runs" = 1 then
                                    JobQueueEntry."No. of Minutes between Runs" := MasterDataMgtSetupDefault.DefaultNumberOfMinutesBetweenRuns();
                                // we filtered for the default value of this one already
                                JobQueueEntry."Inactivity Timeout Period" := MasterDataMgtSetupDefault.DefaultInactivityTimeoutPeriod();
                                RestrictedRecord.SetRange("Record ID", JobQueueEntry.RecordId());
                                if RestrictedRecord.IsEmpty() then
                                    if not JobQueueEntry.Modify() then
                                        NotAllJobQueueEntriesModified := true;
                            end;
                until JobQueueEntry.Next() = 0;
        end;

        if NotAllJobQueueEntriesModified then
            Session.LogMessage('0000NJM', 'Decreasing frequency of all MDM job queue entries failed for at least one of them. Will retry with next upgrade.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL Master Data Management')
        else
            UpgradeTag.SetUpgradeTag(GetJobQueueFrequencyUpgradeTag());
    end;

    internal procedure UpgradeSynchTableCaptions()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSynchTableCaptionUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                if IntegrationTableMapping."Table Caption" = '' then begin
                    IntegrationTableMapping."Table Caption" := MasterDataMgtSetupDefault.GetTableCaption(IntegrationTableMapping."Table ID");
                    IntegrationTableMapping.Modify();
                end
            until IntegrationTableMapping.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetSynchTableCaptionUpgradeTag());
    end;


    local procedure GetSynchTableCaptionUpgradeTag(): Code[250]
    begin
        exit('MS-490934-MDMSynchTableCaption-20231125');
    end;

    local procedure GetJobQueueFrequencyUpgradeTag(): Code[250]
    begin
        exit('MS-543635-MDMJobQueueFrequency-20240830');
    end;

    local procedure GetCrossEnvWebServiceUpgradeTag(): Code[250]
    begin
        exit('MS-647660-MDMCrossEnvWebService-20260826');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetSynchTableCaptionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobQueueFrequencyUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetCrossEnvWebServiceUpgradeTag());
    end;
}