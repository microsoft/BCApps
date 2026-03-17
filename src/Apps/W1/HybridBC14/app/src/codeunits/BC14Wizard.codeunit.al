// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using Microsoft.Utilities;
using System.Environment;

codeunit 50161 "BC14 Wizard"
{
    var
        MigrationProviderIdTxt: Label '50150-BC14Re-Implementation', Locked = true;
        ProductDescriptionTxt: Label 'Use this option if you are migrating from Business Central 14 on-premises. The migration process transforms selected BC14 data to the Business Central online format.';
        AdditionalProcessesInProgressErr: Label 'Cannot start a new migration until the previous migration run and additional/posting processes have completed.';

    procedure GetMigrationProviderId(): Text[250]
    begin
        exit(CopyStr(MigrationProviderIdTxt, 1, 250));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnGetHybridProductDescription', '', false, false)]
    local procedure HandleGetHybridProductDescription(ProductId: Text; var ProductDescription: Text)
    begin
        if ProductId = MigrationProviderIdTxt then
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

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'CheckAdditionalProcesses', '', false, false)]
    local procedure CheckAdditionalProcesses(var AdditionalProcessesRunning: Boolean; var ErrorMessage: Text)
    begin
        AdditionalProcessesRunning := ProcessesAreRunning();

        if AdditionalProcessesRunning then
            ErrorMessage := AdditionalProcessesInProgressErr;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'OnResetAllCloudData', '', false, false)]
    local procedure OnResetAllCloudData()
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
    begin
        BC14CompanySettings.Reset();
        if BC14CompanySettings.FindSet() then
            BC14CompanySettings.ModifyAll(ProcessesAreRunning, false);

        if not BC14CompanySettings.IsEmpty() then
            BC14CompanySettings.DeleteAll();

        if not HybridCompanyStatus.IsEmpty() then
            HybridCompanyStatus.DeleteAll();

        if not HybridCompany.IsEmpty() then
            HybridCompany.DeleteAll();

        if not HybridReplicationDetail.IsEmpty() then
            HybridReplicationDetail.DeleteAll();

        if not BC14MigrationErrorOverview.IsEmpty() then
            BC14MigrationErrorOverview.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CompanyOnAfterDelete(var Rec: Record Company; RunTrigger: Boolean)
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
    begin
        if Rec.IsTemporary() then
            exit;

        if BC14CompanySettings.Get(Rec.Name) then
            BC14CompanySettings.Delete();

        if HybridCompanyStatus.Get(Rec.Name) then
            HybridCompanyStatus.Delete();

        if HybridCompany.Get(Rec.Name) then
            HybridCompany.Delete();

        HybridReplicationDetail.SetRange("Company Name", Rec.Name);
        if not HybridReplicationDetail.IsEmpty() then
            HybridReplicationDetail.DeleteAll();

        BC14MigrationErrorOverview.SetRange("Company Name", Rec.Name);
        if not BC14MigrationErrorOverview.IsEmpty() then
            BC14MigrationErrorOverview.DeleteAll();
    end;

    local procedure ProcessesAreRunning(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanySettings.SetRange(ProcessesAreRunning, true);
        exit(not BC14CompanySettings.IsEmpty());
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
        exit(ProductId = MigrationProviderIdTxt);
    end;
}
