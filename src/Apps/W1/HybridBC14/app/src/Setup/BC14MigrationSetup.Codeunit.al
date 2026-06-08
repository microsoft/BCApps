// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

codeunit 46851 "BC14 Migration Setup"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";

    /// <summary>
    /// Sets up replication table mappings for all per-company tables we replicate:
    /// Setup/Configuration, Master Data, Transaction, and Historical.
    /// </summary>
    /// <remarks>
    /// Setup/Configuration tables (Dimension, Payment Terms, ...) are intentionally registered
    /// here through the Replication Table Mapping path and NOT via
    /// Hybrid Cloud Management.CreateMigrationSetupMapping. The platform's setup-phase
    /// pipeline ("Migration Setup Table Mapping", table 40033) runs before the SaaS production
    /// companies are created, so per-company mappings sent through that channel are silently
    /// dropped -- there is no destination company yet for the data to land in. Per-company
    /// configuration data must therefore wait for the regular replication phase, same as
    /// master/transaction/historical data.
    /// </remarks>
    procedure SetupReplicationTableMappings()
    var
        HybridCompany: Record "Hybrid Company";
        SkipDefaultRegistration: Boolean;
    begin
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                // Each migrator owns its own source-to-buffer mapping registration via
                // RegisterReplicationMappings. Adding a new migrator only requires adding an
                // enum value and implementing the interface — no edit to this codeunit needed.
                SkipDefaultRegistration := false;
                OnBeforeRegisterMappingsForAllMigrators(HybridCompany.Name, SkipDefaultRegistration);
                if SkipDefaultRegistration then
                    Session.LogMessage('0000TXQ', StrSubstNo(RegisterMappingsOverriddenLbl, HybridCompany.Name), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory())
                else
                    RegisterMappingsForAllMigrators(HybridCompany.Name);

                OnAfterSetupReplicationMappings(HybridCompany.Name);
            until HybridCompany.Next() = 0;

        InsertPerDatabaseSetupRecord(TenantMediaLbl, TenantMediaLbl);

        OnAfterSetupReplicationTableMapping();
    end;

    local procedure RegisterMappingsForAllMigrators(CompanyName: Text)
    var
        SetupEnum: Enum "BC14 Setup Migrator";
        MasterEnum: Enum "BC14 Master Migrator";
        TransactionEnum: Enum "BC14 Transaction Migrator";
        HistoricalEnum: Enum "BC14 Historical Migrator";
        Migrator: Interface "BC14 Migrator";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"BC14 Setup Migrator".Ordinals() do begin
            SetupEnum := Enum::"BC14 Setup Migrator".FromInteger(Ordinal);
            Migrator := SetupEnum;
            Migrator.RegisterReplicationMappings(CompanyName);
        end;
        foreach Ordinal in Enum::"BC14 Master Migrator".Ordinals() do begin
            MasterEnum := Enum::"BC14 Master Migrator".FromInteger(Ordinal);
            Migrator := MasterEnum;
            Migrator.RegisterReplicationMappings(CompanyName);
        end;
        foreach Ordinal in Enum::"BC14 Transaction Migrator".Ordinals() do begin
            TransactionEnum := Enum::"BC14 Transaction Migrator".FromInteger(Ordinal);
            Migrator := TransactionEnum;
            Migrator.RegisterReplicationMappings(CompanyName);
        end;
        foreach Ordinal in Enum::"BC14 Historical Migrator".Ordinals() do begin
            HistoricalEnum := Enum::"BC14 Historical Migrator".FromInteger(Ordinal);
            Migrator := HistoricalEnum;
            Migrator.RegisterReplicationMappings(CompanyName);
        end;
    end;

    procedure InsertPerCompanyMapping(CompanyName: Text; SourceTableID: Integer; DestinationTableID: Integer)
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        HybridCloudManagement.CreateReplicationMapping(CompanyName, SourceTableID, DestinationTableID);
    end;

    local procedure InsertPerDatabaseSetupRecord(SourceTableName: Text[128]; DestinationTableName: Text[128])
    var
        ExistingReplicationMapping: Record "Replication Table Mapping";
        ReplicationMapping: Record "Replication Table Mapping";
    begin
        ReplicationMapping."Source Sql Table Name" := SourceTableName;
        ReplicationMapping."Destination Sql Table Name" := DestinationTableName;
        ReplicationMapping."Company Name" := '';
        ReplicationMapping."Table Name" := DestinationTableName;
        ReplicationMapping."Preserve Cloud Data" := true;
        if ExistingReplicationMapping.Get(ReplicationMapping.RecordId) then
            exit;

        ReplicationMapping.Insert(true);
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupReplicationTableMapping()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterMappingsForAllMigrators(CompanyName: Text; var SkipDefaultRegistration: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupReplicationMappings(CompanyName: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'OnOpenNewUI', '', false, false)]
    local procedure HandleOnOpenNewUI(var OpenNewUI: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if BC14Wizard.GetBC14MigrationEnabled() then
            OpenNewUI := true;
    end;

    var
        TenantMediaLbl: Label 'Tenant Media', Locked = true;
        RegisterMappingsOverriddenLbl: Label 'Replication mapping registration for company %1 was overridden by an extension.', Locked = true, Comment = '%1 = Company Name';

}
