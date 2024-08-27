// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.DataAdministration;
using System.Upgrade;
using System.Environment.Configuration;
using System.Reflection;

#pragma warning disable AA0235
codeunit 1596 "Email Installer"
#pragma warning restore AA0235
{
    Subtype = Install;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata Field = r;

    trigger OnInstallAppPerCompany()
    var
        EmailViewPolicy: Codeunit "Email View Policy";
    begin
        AddRetentionPolicyAllowedTables();
        EmailViewPolicy.CheckForDefaultEntry(Enum::"Email View Policy"::AllRelatedRecordsEmails); // Default record is AllRelatedRecords for new tenants
    end;

    procedure AddRetentionPolicyAllowedTables()
    begin
        AddRetentionPolicyAllowedTables(false);
        AddRetentionPolicyEmailInboxAllowedTable(false);
        CreateRetentionPolicySetup(false);
    end;

    procedure AddRetentionPolicyAllowedTables(ForceUpdate: Boolean)
    var
        Field: Record Field;
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsInitialSetup: Boolean;
    begin
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetEmailTablesAddedToAllowedListUpgradeTag());
        if not (IsInitialSetup or ForceUpdate) then
            exit;

        RetenPolAllowedTables.AddAllowedTable(Database::"Email Outbox", Field.FieldNo(SystemCreatedAt), 7);
        RetenPolAllowedTables.AddAllowedTable(Database::"Sent Email", Field.FieldNo(SystemCreatedAt), 7);

        if IsInitialSetup then
            UpgradeTag.SetUpgradeTag(GetEmailTablesAddedToAllowedListUpgradeTag());
    end;

    procedure AddRetentionPolicyEmailInboxAllowedTable(ForceUpdate: Boolean)
    var
        Field: Record Field;
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsInitialSetup: Boolean;
    begin
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetEmailInboxAddedToAllowedListUpgradeTag());
        if not (IsInitialSetup or ForceUpdate) then
            exit;

        RetenPolAllowedTables.AddAllowedTable(Database::"Email Inbox", Field.FieldNo(SystemCreatedAt), 2);

        if IsInitialSetup then
            UpgradeTag.SetUpgradeTag(GetEmailInboxAddedToAllowedListUpgradeTag());
    end;

    procedure CreateRetentionPolicySetup(ForceUpdate: Boolean)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupCU: Codeunit "Retention Policy Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        DateFormula: DateFormula;
        IsInitialSetup: Boolean;
    begin
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetEmailInboxPolicyAddedToAllowedListUpgradeTag());
        if not (IsInitialSetup or ForceUpdate) then
            exit;

        RetentionPolicySetup.SetRange("Table Id", Database::"Email Inbox");
        if not RetentionPolicySetup.IsEmpty() then
            exit;

        Evaluate(DateFormula, '<-2D>');

        RetentionPolicySetup.Validate("Table Id", Database::"Email Inbox");
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPolicySetupCU.FindOrCreateRetentionPeriod('2 DAYS', "Retention Period Enum"::"Custom", DateFormula));
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Insert(true);

        if IsInitialSetup then
            UpgradeTag.SetUpgradeTag(GetEmailInboxPolicyAddedToAllowedListUpgradeTag());
    end;

    local procedure GetEmailTablesAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-373161-EmailLogEntryAdded-20201005');
    end;

    local procedure GetEmailInboxAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-539754-EmailInboxAdded-20240827');
    end;

    local procedure GetEmailInboxPolicyAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-539754-EmailInboxPolicyAdded-20240827');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", OnRefreshAllowedTables, '', false, false)]
    local procedure AddAllowedTablesOnRefreshAllowedTables()
    begin
        AddRetentionPolicyAllowedTables(true);
        AddRetentionPolicyEmailInboxAllowedTable(true);
        CreateRetentionPolicySetup(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterLogin, '', false, false)]
    local procedure AddAllowedTablesOnAfterSystemInitialization()
    begin
        AddRetentionPolicyAllowedTables();
    end;
}