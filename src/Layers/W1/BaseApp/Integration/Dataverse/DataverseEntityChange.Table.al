// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;
using System.Reflection;

table 5395 "Dataverse Entity Change"
{
    Caption = 'Dataverse Entity Change';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Entity Name"; Text[248])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        TableMetadata: Record "Table Metadata";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        TableMetadata.SetRange(ExternalName, "Entity Name");
        TableMetadata.SetRange(TableType, TableMetadata.TableType::CRM);
        if not TableMetadata.FindSet() then
            exit;

        repeat
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Integration Table ID", TableMetadata.ID);
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            if IntegrationTableMapping.FindSet() then
                repeat
                    if IntegrationTableMapping.Direction <> IntegrationTableMapping.Direction::ToIntegrationTable then begin
                        Session.LogMessage('0000HDR', StrSubstNo(ReschedulingJobForIntMappingTxt, IntegrationTableMapping.Name), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                        CRMIntegrationManagement.ReactivateJobForTable(IntegrationTableMapping."Table ID");
                    end
                until IntegrationTableMapping.Next() = 0;
        until TableMetadata.Next() = 0;
    end;

    var
        ReschedulingJobForIntMappingTxt: Label 'Rescheduling synch job for integration table mapping %1 based on a Dataverse entity change', Locked = true;
        TelemetryCategoryTok: Label 'AL Dataverse Integration', Locked = true;
}
