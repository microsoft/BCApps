// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Environment;
using System.Feedback;
using System.Telemetry;
using System.Text;
using System.Utilities;

codeunit 3317 "Payables Agent OCV"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit Telemetry;
        PayablesAgentFeedbackQst: Label 'We noticed you have processed several documents with Payables Agent. Before you turn it off, could you share what made you decide to disable it? Your feedback helps us improve the experience.', Comment = 'Payables Agent is a term, and should not be translated.';
        PayablesAgentDisableFeedbackQst: Label 'What could we have done better to keep Payables Agent enabled?', Comment = 'Payables Agent is a term, and should not be translated.';
        PayablesAgentThumbDownFeedbackQst: Label 'What happened that made you give a thumbs down?', Comment = 'Payables Agent is a term, and should not be translated.';
        DisableAgentFeedbackTxt: Label 'Disable agent feedback triggered', Locked = true;
        TaskThumbsFeedbackTxt: Label 'Task thumbs feedback triggered', Locked = true;
        DraftThumbsFeedbackTxt: Label 'Draft thumbs feedback triggered', Locked = true;

    procedure TriggerDisableAgentFeedback()
    var
        ConfirmMgt: Codeunit "Confirm Management";
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        if not HasProcessedEnoughDocumentsForFeedback() then
            exit;
        if not ConfirmMgt.GetResponse(PayablesAgentFeedbackQst) then
            exit;

        // Run feedback trigger after resetting the counter to avoid multiple triggers
        Feedback.SetIsAIFeedback(true);
        Feedback.WithCustomQuestion(PayablesAgentDisableFeedbackQst, PayablesAgentDisableFeedbackQst).WithCustomQuestionType(Enum::FeedbackQuestionType::Text);
        Feedback.RequestDislikeFeedback('Disabled Payables Agent', 'PayablesAgent', 'Payables Agent');

        Telemetry.LogMessage('0000QSC', DisableAgentFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
    end;

    procedure TriggerPayablesAgentTaskThumbsFeedback(FeedbackType: Text; AgentTaskId: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        Feedback: Codeunit "Microsoft User Feedback";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        Base64Data: Text;
        InvoiceFileName: Text;
        ContextProperties, ContextFiles : Dictionary of [Text, Text];
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Feedback.SetIsAIFeedback(true);
        case FeedbackType of
            'Copilot.ThumbsUp':
                begin
                    Feedback.RequestLikeFeedback('Payables Agent Task', 'PayablesAgent', 'Payables Agent');
                    CustomDimensions.Add('FeedbackType', 'ThumbsUp');
                end;
            'Copilot.ThumbsDown':
                begin
                    if GetInvoice(AgentTaskId, TempBlob, InvoiceFileName) then begin
                        TempBlob.CreateInStream(InStream);
                        Base64Data := Base64Convert.ToBase64(InStream);
                        ContextFiles.Add(InvoiceFileName, Base64Data);
                    end;

                    Feedback.WithCustomQuestion(PayablesAgentThumbDownFeedbackQst, PayablesAgentThumbDownFeedbackQst).WithCustomQuestionType(Enum::FeedbackQuestionType::Text);
                    Feedback.RequestDislikeFeedback('Payables Agent Task', 'PayablesAgent', 'Payables Agent', ContextFiles, ContextProperties);
                    CustomDimensions.Add('FeedbackType', 'ThumbsDown');
                end;
            else
                exit(false);
        end;

        Telemetry.LogMessage('0000QSD', TaskThumbsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        exit(true);
    end;

    procedure TriggerPayableAgentDraftThumbsFeedback(FeedbackType: Text): Boolean
    var
        Feedback: Codeunit "Microsoft User Feedback";
        ContextProperties, ContextFiles : Dictionary of [Text, Text];
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Feedback.SetIsAIFeedback(true);
        case FeedbackType of
            'Copilot.ThumbsUp':
                begin
                    Feedback.RequestLikeFeedback('Payables Agent Draft', 'PayablesAgent', 'Payables Agent');
                    CustomDimensions.Add('FeedbackType', 'ThumbsUp');
                end;
            'Copilot.ThumbsDown':
                begin
                    Feedback.WithCustomQuestion(PayablesAgentThumbDownFeedbackQst, PayablesAgentThumbDownFeedbackQst).WithCustomQuestionType(Enum::FeedbackQuestionType::Text);
                    Feedback.RequestDislikeFeedback('Payables Agent Draft', 'PayablesAgent', 'Payables Agent', ContextFiles, ContextProperties);
                    CustomDimensions.Add('FeedbackType', 'ThumbsDown');
                end;
            else
                exit(false);
        end;

        Telemetry.LogMessage('0000QSE', DraftThumbsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        exit(true);
    end;

    local procedure HasProcessedEnoughDocumentsForFeedback(): Boolean
    var
        PayablesAgentKPI: Record "Payables Agent KPI";
        Agent: Record Agent;
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
        PASetup: Codeunit "PA Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        LastActivated: DateTime;
    begin
        PASetup.GetSetup();
        LastActivated := PASetup.GetLastActivated();
        if PAAgentConfiguration.GetAgent(Agent) and (LastActivated = 0DT) then
            if Agent.State = Agent.State::Enabled then
                exit(true); // If never activated, it was activated before we introduced the field, so allow feedback

        PayablesAgentKPI.SetRange("Is Aggregate", false);
        PayablesAgentKPI.SetFilter(SystemCreatedAt, '>%1', LastActivated);
        PayablesAgentKPI.SetRange("KPI Scenario", PayablesAgentKPI."KPI Scenario"::"Purchase Invoices created by Agent");
        exit(PayablesAgentKPI.Count() > (EnvironmentInfo.IsSaaS() ? 10 : 2));
    end;

    local procedure GetInvoice(AgentTaskId: Text; var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    var
        PATask: Codeunit "Payables Agent Task";
        AgentTaskIdValue: BigInteger;
    begin
        if not Evaluate(AgentTaskIdValue, AgentTaskId) then
            exit(false);
        if not PATask.Load(AgentTaskIdValue) then
            exit(false);
        exit(PATask.GetSourcePdf(TempBlob, FileName));
    end;

}