// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Azure.Identity;
using System.Environment.Configuration;

table 6986 "Tenant Feedback Setting"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Tenant ID"; Text[50])
        {
            Caption = 'Tenant ID';
        }
        field(2; "Copilot Feedback Enabled"; Boolean)
        {
            Caption = 'Copilot Feedback Enabled';
        }
        field(3; "Survey Feedback Enabled"; Boolean)
        {
            Caption = 'Survey Feedback Enabled';
        }
        field(4; "Feedback Attachments Enabled"; Boolean)
        {
            Caption = 'Feedback Attachments Enabled';
        }
        field(5; "Feedback Reachout Enabled"; Boolean)
        {
            Caption = 'Feedback Reachout Enabled';
        }
        field(6; "User Init. Feedback Enabled"; Boolean)
        {
            Caption = 'User Initiated Feedback Enabled';
        }
    }
    keys
    {
        key(PK; "Tenant ID")
        {
            Clustered = true;
        }
    }

    procedure Load()
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        TenantFeedbackSettings: Codeunit "Tenant Feedback Settings";
    begin
        Rec.DeleteAll();

        Rec."Tenant ID" := CopyStr(AzureADTenant.GetAadTenantId(), 1, MaxStrLen(Rec."Tenant ID"));
        Rec."Copilot Feedback Enabled" := TenantFeedbackSettings.GetCopilotFeedbackEnabled();
        Rec."Survey Feedback Enabled" := TenantFeedbackSettings.GetSurveyFeedbackEnabled();
        Rec."Feedback Attachments Enabled" := TenantFeedbackSettings.GetFeedbackAttachmentsEnabled();
        Rec."Feedback Reachout Enabled" := TenantFeedbackSettings.GetFeedbackReachoutEnabled();
        Rec."User Init. Feedback Enabled" := TenantFeedbackSettings.GetUserInitiatedFeedbackEnabled();
        Rec.Insert();
    end;
}