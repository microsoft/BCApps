// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.AI;

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
        ConsumptionSourceTypeErr: Label 'Consumption Source Type must be provided and valid.';
        ConsumptionSourceSystemIdErr: Label 'Consumption Source System ID must be provided.';
        ExpenseEmployeeCodeErr: Label 'Expense Employee Code must be provided.';
        ConsumptionUsageErr: Label 'Usage cannot be negative.';
        ModelResolvedNameErr: Label 'Model Resolved Name must be provided.';
        ActionsSummaryOrDescriptionErr: Label 'Actions Summary and Description must be provided.';
        EmptyConsumptionOperationErr: Label 'Operation must be provided.';

    [ServiceEnabled]
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

    [ServiceEnabled]
    procedure LogV2AIConsumption(
        AgentConversationSessionId: Guid;
        AgentTurnInteractionId: Guid;
        InputTokenCount: Integer;
        OutputTokenCount: Integer;
        PromptCacheReadTokenCount: Integer;
        PromptCacheCreationTokenCount: Integer;
        ModelResolvedName: Text[1024];
        ActionsSummary: Text[2048];
        ExpenseUserEntraId: Guid;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        ConsumptionSourceOperationName: Code[50]): Text[1024]
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();

        if (InputTokenCount < 0) or (OutputTokenCount < 0) or (PromptCacheReadTokenCount < 0) or (PromptCacheCreationTokenCount < 0) then
            Error(ConsumptionUsageErr);

        if ModelResolvedName = '' then
            Error(ModelResolvedNameErr);

        if ActionsSummary = '' then
            Error(ActionsSummaryOrDescriptionErr);

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
                Session.LogMessage('', MismatchingEntraIdsTelemetryErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        exit(ExpenseConsumptionHandler.LogV2AIConsumption(AgentConversationSessionId, AgentTurnInteractionId, InputTokenCount, OutputTokenCount, PromptCacheReadTokenCount, PromptCacheCreationTokenCount,
            ModelResolvedName, ActionsSummary, ExpenseUserEntraId, ConsumptionSourceType, ConsumptionSourceSystemId, ConsumptionSourceOperationName, Rec."No."));
    end;

    [ServiceEnabled]
    procedure CanConsume(): Boolean
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        exit(ExpenseConsumptionHandler.CanConsume());
    end;
}