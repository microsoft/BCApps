// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using System.Privacy;
using System.Telemetry;

table 800 "Online Map Setup"
{
    Caption = 'Online Map Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Map Parameter Setup Code"; Code[10])
        {
            Caption = 'Map Parameter Setup Code';
            ToolTip = 'Specifies the map parameter code that is set up in the Online Map Parameter Setup window.';
            TableRelation = "Online Map Parameter Setup";
        }
        field(3; "Distance In"; Option)
        {
            Caption = 'Distance In';
            ToolTip = 'Specifies if distances in your online map should be shown in miles or kilometers.';
            OptionCaption = 'Miles,Kilometers';
            OptionMembers = Miles,Kilometers;
        }
        field(4; Route; Option)
        {
            Caption = 'Route';
            ToolTip = 'Specifies whether to use the quickest or shortest route for calculation.';
            OptionCaption = 'Quickest,Shortest';
            OptionMembers = Quickest,Shortest;
        }
        field(13; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies if the connection to online map service should be enabled';

            trigger OnValidate()
            var
                AuditLog: Codeunit "Audit Log";
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                OnlineMapSetupEnabledLbl: Label 'Online Map Setup enabled by UserSecurityId %1', Locked = true;
            begin
                if not xRec."Enabled" and Rec."Enabled" then begin
                    Rec."Enabled" := CustomerConsentMgt.ConfirmUserConsentToMicrosoftService();
                    AuditLog.LogAuditMessage(StrSubstNo(OnlineMapSetupEnabledLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

