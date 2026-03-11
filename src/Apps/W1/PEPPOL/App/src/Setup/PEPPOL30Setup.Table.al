// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using System.Telemetry;

/// <summary>
/// Table for PEPPOL 3.0 Setup to store e-document format configuration.
/// Contains settings for configuring electronic document formats for sales and service documents.
/// </summary>
table 37202 "PEPPOL 3.0 Setup"
{
    Caption = 'PEPPOL 3.0 Setup';
    InherentEntitlements = RIMX;
    InherentPermissions = RMX;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "PEPPOL 3.0 Sales Format"; Enum "PEPPOL 3.0 Format")
        {
            Caption = 'PEPPOL 3.0 Sales Format';
            ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type sales.';
        }
        field(3; "PEPPOL 3.0 Service Format"; Enum "PEPPOL 3.0 Format")
        {
            Caption = 'PEPPOL 3.0 Service Format';
            ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type service.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Rec."PEPPOL 3.0 Sales Format" := Rec."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - Sales";
        Rec."PEPPOL 3.0 Service Format" := Rec."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - Service";
    end;

    /// <summary>
    /// Gets the PEPPOL 3.0 Setup record. Creates it if it doesn't exist.
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"PEPPOL 3.0 Setup", 'I')]
    procedure GetSetup()
    var
        Peppol30Impl: Codeunit "PEPPOL30 Impl.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000QTW', Peppol30Impl.GetPeppolTelemetryTok(), Enum::"Feature Uptake Status"::Used);
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;
}
