// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6986 "Tenant Feedback Setting API"
{
    PageType = API;

    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityName = 'tenantFeedbackSetting';
    EntitySetName = 'tenantFeedbackSettings';

    EntityCaption = 'Tenant Feedback Setting';
    EntitySetCaption = 'Tenant Feedback Settings';
    AboutText = 'Allows retrieving tenant feedback settings.';

    SourceTable = "Tenant Feedback Setting";
    SourceTableTemporary = true;
    ODataKeyFields = "Tenant ID";

    DelayedInsert = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(copilotFeedbackEnabled; Rec."Copilot Feedback Enabled")
                {
                    Caption = 'Copilot Feedback Enabled';
                }
                field(surveyFeedbackEnabled; Rec."Survey Feedback Enabled")
                {
                    Caption = 'Survey Feedback Enabled';
                }
                field(feedbackAttachmentsEnabled; Rec."Feedback Attachments Enabled")
                {
                    Caption = 'Feedback Attachments Enabled';
                }
                field(feedbackReachoutEnabled; Rec."Feedback Reachout Enabled")
                {
                    Caption = 'Feedback Reachout Enabled';
                }
                field(userInitiatedFeedbackEnabled; Rec."User Init. Feedback Enabled")
                {
                    Caption = 'User Initiated Feedback Enabled';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        Rec.Load();
    end;
}