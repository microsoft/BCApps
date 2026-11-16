#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Upgrade;

codeunit 6967 "Upgrade Exp. Agent Consumption"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Expense Agent Consumption" = r,
                  tabledata "Expense Agent Env. Consumption" = ri;

    trigger OnUpgradePerCompany()
    begin
        MigrateConsumptionToEnvTable();
    end;

    local procedure MigrateConsumptionToEnvTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetMigrateConsumptionUpgradeTag()) then
            exit;

        CopyConsumptionRecords();
        UpgradeTag.SetUpgradeTag(GetMigrateConsumptionUpgradeTag());
    end;

    local procedure CopyConsumptionRecords()
    var
        OldConsumption: Record "Expense Agent Consumption";
        NewConsumption: Record "Expense Agent Env. Consumption";
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        DuplicateEntryTxt: Label 'Skipping duplicate consumption entry during migration.';
    begin
        if not OldConsumption.FindSet() then
            exit;

        repeat
            NewConsumption.Init();
            NewConsumption."Consumption Unique ID" := OldConsumption."Consumption Unique ID";
            NewConsumption."Expense User No." := OldConsumption."Expense User No.";
            NewConsumption."Consumption Source Type" := OldConsumption."Consumption Source Type";
            NewConsumption."Consumption Source System ID" := OldConsumption."Consumption Source System ID";
            NewConsumption."Consumption Source Operation" := OldConsumption."Consumption Source Operation";
            if not NewConsumption.Insert() then
                Session.LogMessage('0000UE2', DuplicateEntryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());
        until OldConsumption.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetMigrateConsumptionUpgradeTag());
    end;

    local procedure GetMigrateConsumptionUpgradeTag(): Code[250]
    begin
        exit('MS-ExpenseAgent-MigrateConsumptionToEnvTable-20260608');
    end;
}
#endif
