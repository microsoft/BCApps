// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
#if not CLEAN30
using System.AI;
#endif

page 6968 "Expense User Cons. API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'User Consumption';
    EntitySetCaption = 'User Consumptions';
    EntityName = 'userConsumption';
    EntitySetName = 'userConsumptions';
    PageType = API;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Expense User";
    AboutText = 'Allows logging consumption for expense users.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(employeeNumber; Rec."Employee No.")
                {
                    Caption = 'Employee Number';
                }
            }
        }
    }

    trigger OnInit()
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        MismatchingEntraIdsTelemetryErr: Label 'The Expense User has an Entra Id saved in the database, but it''s different from the ID used for consumption reporting.', Locked = true;
        LogV2QuotaStartedTelemetryMsg: Label 'Started logging AI quota usage for Expense Agent.', Locked = true;
        ConsumptionSourceTypeErr: Label 'Consumption Source Type must be provided and valid.';
        AgentConversationSessionIdOrTurnInteractionIdErr: Label 'Agent Session ID and Interaction ID must be provided.';
        ConsumptionSourceSystemIdErr: Label 'Consumption Source System ID must be provided.';
        ExpenseEmployeeCodeErr: Label 'Expense Employee Code must be provided.';
        ExpenseUserEntraIdErr: Label 'Expense User Entra ID must be provided.';
        InvalidJsonConsumptionRequestErr: Label 'AI Consumption Request must be a valid JSON containing all required fields.';
        ActionsSummaryErr: Label 'Actions Summary must be provided.';
        EmptyConsumptionOperationErr: Label 'Operation must be provided.';

#if not CLEAN30
    var
        ConsumptionUsageErr: Label 'Usage cannot be negative.';
        ActionsSummaryOrDescriptionErr: Label 'Actions Summary and Description must be provided.';

    [ServiceEnabled]
    [Obsolete('Use LogAIConsumptionV2 instead.', '30.0')]
    procedure LogAIConsumption(
        CopilotQuotaUsageAmount: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
        ActionsSummary: Text[1024];
        ActionsDescription: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        ConsumptionSourceOperationName: Code[50]): Text[1024]
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();

        if CopilotQuotaUsageAmount < 0 then
            Error(ConsumptionUsageErr);

        if (ActionsSummary = '') or (ActionsDescription = '') then
            Error(ActionsSummaryOrDescriptionErr);

        if ConsumptionSourceType = ConsumptionSourceType::Invalid then
            Error(ConsumptionSourceTypeErr);

        if IsNullGuid(ConsumptionSourceSystemId) then
            Error(ConsumptionSourceSystemIdErr);

        if Rec."No." = '' then
            Error(ExpenseEmployeeCodeErr);

        if ConsumptionSourceOperationName = '' then
            Error(EmptyConsumptionOperationErr);

        exit(ExpenseConsumptionHandler.LogAIConsumption(CopilotQuotaUsageAmount, CopilotQuotaUsageType,
            ActionsSummary, ActionsDescription, ConsumptionSourceType, ConsumptionSourceSystemId, ConsumptionSourceOperationName, Rec."No."));
    end;
#endif

    [ServiceEnabled]
    procedure LogAIConsumptionV2(
        AiConsumptionRequest: Text;
        AgentConversationSessionId: Guid;
        AgentTurnInteractionId: Guid;
        ActionsSummary: Text[2048];
        ExpenseUserEntraId: Guid;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        ConsumptionSourceOperationName: Code[50]): Guid
    var
        AiConsumptionRequestJson: JsonObject;
        ModelJson: JsonObject;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        if (AiConsumptionRequest = '') or not AiConsumptionRequestJson.ReadFrom(AiConsumptionRequest) then
            Error(InvalidJsonConsumptionRequestErr);
        if not ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson) then
            Error(InvalidJsonConsumptionRequestErr);
        if IsNullGuid(AgentConversationSessionId) or IsNullGuid(AgentTurnInteractionId) then
            Error(AgentConversationSessionIdOrTurnInteractionIdErr);
        if IsNullGuid(ExpenseUserEntraId) then
            Error(ExpenseUserEntraIdErr);
        if ActionsSummary = '' then
            Error(ActionsSummaryErr);
        if ConsumptionSourceType = ConsumptionSourceType::Invalid then
            Error(ConsumptionSourceTypeErr);
        if IsNullGuid(ConsumptionSourceSystemId) then
            Error(ConsumptionSourceSystemIdErr);
        if Rec."No." = '' then
            Error(ExpenseEmployeeCodeErr);
        if ConsumptionSourceOperationName = '' then
            Error(EmptyConsumptionOperationErr);
        if not IsNullGuid(Rec."Entra Id") then
            if Rec."Entra Id" <> ExpenseUserEntraId then
                Session.LogMessage('0000W40', MismatchingEntraIdsTelemetryErr, Verbosity::Warning, DataClassification::SystemMetadata,
                    TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        ModelJson := AiConsumptionRequestJson.GetObject('model');
        TelemetryDimensions.Add('Category', ExpenseAuditSubscribers.TelemetryCategory());
        TelemetryDimensions.Add('OperationName', ConsumptionSourceOperationName);
        TelemetryDimensions.Add('ModelResolvedName', GetModelTelemetryValue(ModelJson, 'modelResolvedName'));
        TelemetryDimensions.Add('InputTokenCount', GetModelTelemetryValue(ModelJson, 'inputTokenCount'));
        TelemetryDimensions.Add('OutputTokenCount', GetModelTelemetryValue(ModelJson, 'outputTokenCount'));
        TelemetryDimensions.Add('PromptCacheReadTokenCount', GetModelTelemetryValue(ModelJson, 'promptCacheReadTokenCount'));
        TelemetryDimensions.Add('PromptCacheCreationTokenCount', GetModelTelemetryValue(ModelJson, 'promptCacheCreationTokenCount'));
        Session.LogMessage('0000W41', LogV2QuotaStartedTelemetryMsg,
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

        exit(ExpenseConsumptionHandler.LogAIConsumption(AiConsumptionRequestJson,
            ActionsSummary, ConsumptionSourceType, ConsumptionSourceSystemId, ConsumptionSourceOperationName, Rec."No."));
    end;

    [ServiceEnabled]
    procedure CanConsume(): Boolean
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        exit(ExpenseConsumptionHandler.CanConsume());
    end;

    local procedure GetModelTelemetryValue(ModelJson: JsonObject; FieldName: Text): Text
    var
        FieldToken: JsonToken;
    begin
        if not ModelJson.Get(FieldName, FieldToken) then
            exit('');
        if not FieldToken.IsValue() then
            exit('');
        if FieldToken.AsValue().IsNull() then
            exit('');

        exit(FieldToken.AsValue().AsText());
    end;
}