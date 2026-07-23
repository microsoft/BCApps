// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using Microsoft.Utilities;
using System.Environment;
using System.Integration;

codeunit 46861 "BC14 Wizard"
{

    var
        ProductDescriptionTxt: Label 'Use this option if you are migrating from Business Central 14 on-premises. The migration process transforms selected Business Central 14 data to the Business Central online format.';

    procedure GetMigrationProviderId(): Text[250]
    var
        CustomMigrationProvider: Enum "Custom Migration Provider";
        CurrentLanguage: Integer;
        ProductId: Text;
    begin
        CustomMigrationProvider := CustomMigrationProvider::"BC14 Re-Implementation";
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        ProductId := Format(CustomMigrationProvider.AsInteger(), 0, 9) + '-' + Format(CustomMigrationProvider);
        ProductId := ProductId.Replace(' ', '');
        GlobalLanguage(CurrentLanguage);
        exit(CopyStr(ProductId, 1, 250));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnGetHybridProductDescription', '', false, false)]
    local procedure HandleGetHybridProductDescription(ProductId: Text; var ProductDescription: Text)
    begin
        if ProductId = GetMigrationProviderId() then
            ProductDescription := ProductDescriptionTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Companies IC", 'OnBeforeCreateCompany', '', false, false)]
    local procedure HandleOnBeforeCreateCompany(ProductId: Text; var CompanyDataType: Enum "Company Demo Data Type")
    begin
        if not CanHandle(ProductId) then
            exit;

        CompanyDataType := CompanyDataType::"Production - Setup Data Only";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'CanMapCustomTables', '', false, false)]
    local procedure OnCanMapCustomTables(var Enabled: Boolean)
    begin
        if not GetBC14MigrationEnabled() then
            exit;

        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnCanSetupAdlMigration', '', false, false)]
    local procedure OnCanSetupAdlMigration(var CanSetup: Boolean)
    begin
        if not GetBC14MigrationEnabled() then
            exit;
        CanSetup := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnBeforeShowProductSpecificSettingsPageStep', '', false, false)]
    local procedure BeforeShowProductSpecificSettingsPageStep(var HybridProductType: Record "Hybrid Product Type"; var ShowSettingsStep: Boolean)
    begin
        if not CanHandle(HybridProductType.ID) then
            exit;

        ShowSettingsStep := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'CanShowUpdateReplicationCompanies', '', false, false)]
    local procedure OnCanShowUpdateReplicationCompanies(var Enabled: Boolean)
    begin
        if not GetBC14MigrationEnabled() then
            exit;

        Enabled := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'OnResetAllCloudData', '', false, false)]
    local procedure OnResetAllCloudData()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompany: Record "Hybrid Company";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        DataMigrationError: Record "Data Migration Error";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // Clean per-company Data Migration Error rows BEFORE deleting Hybrid Company,
        // otherwise we lose the company list needed for ChangeCompany().
        if HybridCompany.FindSet() then
            repeat
                DataMigrationError.ChangeCompany(HybridCompany.Name);
                if not DataMigrationError.IsEmpty() then
                    DataMigrationError.DeleteAll();
            until HybridCompany.Next() = 0;

        if not BC14CompanySettings.IsEmpty() then
            BC14CompanySettings.DeleteAll();

        BC14StatusMgr.DeleteAllCompanyStatus();

        if not HybridCompany.IsEmpty() then
            HybridCompany.DeleteAll();

        if not HybridReplicationDetail.IsEmpty() then
            HybridReplicationDetail.DeleteAll();

        // Global timing/flag state is meaningless after a reset (e.g. Data Upgrade Started
        // would otherwise mis-filter ErrorOccurredInCurrentCompany on the next run).
        if not BC14GlobalSettings.IsEmpty() then
            BC14GlobalSettings.DeleteAll();

        // Stale Hybrid Replication Summary rows for our provider would otherwise leave
        // ValidateReplicationBeforeUpgrade looking at an old Run ID / status.
        HybridReplicationSummary.SetRange(Source, GetMigrationProviderId());
        if not HybridReplicationSummary.IsEmpty() then
            HybridReplicationSummary.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CompanyOnAfterDelete(var Rec: Record Company; RunTrigger: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompany: Record "Hybrid Company";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        if Rec.IsTemporary() then
            exit;

        if BC14CompanySettings.Get(Rec.Name) then
            BC14CompanySettings.Delete();

        BC14StatusMgr.DeleteCompanyStatus(CopyStr(Rec.Name, 1, 30));

        if HybridCompany.Get(Rec.Name) then
            HybridCompany.Delete();

        HybridReplicationDetail.SetRange("Company Name", Rec.Name);
        if not HybridReplicationDetail.IsEmpty() then
            HybridReplicationDetail.DeleteAll();
    end;

    internal procedure GetBC14MigrationEnabled(): Boolean
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        if not IntelligentCloudSetup.Get() then
            exit(false);

        exit(IntelligentCloudSetup."Product ID" = GetMigrationProviderId());
    end;

    local procedure CanHandle(ProductId: Text): Boolean
    begin
        exit(ProductId = GetMigrationProviderId());
    end;
}
