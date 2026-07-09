// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Utilities;
using System.Agents;
using System.AI;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.Telemetry;

codeunit 3303 "Payables Agent" implements IAgentMetadata, IAgentFactory
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;
    Permissions = tabledata "Payables Agent Setup" = R, tabledata User = R, tabledata Agent = R, tabledata "Agent Task Message" = R;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Payables Agent Setup");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Payables Agent KPI");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    begin
        PAAnnotation.GetAgentAnnotations(AgentUserId, Annotations);
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid) PageId: Integer
    var
        AgentTaskMessage: Record "Agent Task Message";
        EDocument: Record "E-Document";
        EDocumentEntryNo: Integer;
    begin
        AgentTaskMessage.SetRange(ID, MessageId);
        if not AgentTaskMessage.FindFirst() then
            exit;
        if not Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
            exit;
        if not EDocument.Get(EDocumentEntryNo) then
            exit;
        if EDocument."Outlook Mail Message Id" <> '' then
            exit(Page::"PA Agent Email Task");
        exit(Page::"PA Agent Upload Task");
    end;

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(PayablesAgentInitialsTok);
    end;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit(PayablesAgentInitialsTok);
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"Payables Agent Setup");
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        PayableAgentSetup: Codeunit "Payables Agent Setup";
    begin
        exit(PayableAgentSetup.AllowCreateNewAgent());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Payables Agent");
    end;

    /// <summary>
    /// If the current session is a payables agent session, this procedure will return the e-document being processed by the agent.
    /// </summary>
    /// <returns>The E-Document being processed by the agent, or an empty record if the session is not from a payables agent.</returns>
    procedure GetCurrentSessionsEDocument() EDocument: Record "E-Document"
    var
        AgentTaskId: BigInteger;
    begin
        if not IsPayablesAgentSession(AgentTaskId) then
            exit;
        exit(GetEDocumentForAgentTask(AgentTaskId));
    end;

    /// <summary>
    /// Given a payables agent task id, it returns the e-document associated with the task.
    /// </summary>
    /// <param name="AgentTaskId"></param>
    /// <returns></returns>
    procedure GetEDocumentForAgentTask(AgentTaskId: BigInteger) EDocument: Record "E-Document"
    var
        AgentTaskMessage: Record "Agent Task Message";
        EDocumentEntryNo: Integer;
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        if not AgentTaskMessage.FindFirst() then
            exit;
        if not Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
            exit;
        if EDocument.Get(EDocumentEntryNo) then;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", OnCreateEvaluationDataOnAfterClassifyTablesToNormal, '', false, false)]
    local procedure ClassifyDataSensitivity()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payables Agent Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payables Agent KPI");
#if not CLEAN28
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Demo File");
#endif
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Billing Log");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Billing Task Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Known Sender");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure CreateAgentTask(EDocument: Record "E-Document"; StartState: Enum "Import E-Doc. Proc. Status"; DesiredEndState: Enum "Import E-Doc. Proc. Status")
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        PayablesAgentSetupRec: Record "Payables Agent Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PayablesAgentKPI: Codeunit "Payables Agent KPI";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not EDocument.Get(EDocument."Entry No") then
            exit;
        if EDocument.GetEDocumentService().Code <> PayablesAgentEDocServiceTok then
            exit;
        if StartState <> "Import E-Doc. Proc. Status"::Unprocessed then
            exit;

        if (StartState = "Import E-Doc. Proc. Status"::Unprocessed) and (DesiredEndState <> "Import E-Doc. Proc. Status"::Unprocessed) then
            exit;

        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", Format(EDocument."Entry No"));
        if not AgentTask.IsEmpty() then
            exit;

        EDocument.CalcFields("Import Processing Status");
        if EDocument."Import Processing Status" in ["Import E-Doc. Proc. Status"::Processed] then
            exit;

        if not PayablesAgentSetup.GetAgent(Agent) then
            exit;
        if Agent.State = Agent.State::Disabled then
            exit;

        PayablesAgentSetupRec.GetSetup();
        CustomDimensions.Set('Category', PayablesAgentSetup.FeatureName());
        CustomDimensions.Set('SystemId', EDocImpSessionTelemetry.CreateSystemIdText(EDocument.SystemId));
        CustomDimensions.Set('EmailReviewPolicy', Format(PayablesAgentSetupRec."Email Review Policy", 0, 9));

        // A sender explicitly set to Reject is a blocklist: no agent task is created.
        if PayablesAgentSetup.IsSenderRejected(EDocument) then begin
            Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
            exit;
        end;

        BuildAgentTask(EDocument, Agent);

        CustomDimensions.Set('ReviewIncomingInvoice', Format(PayablesAgentSetupRec."Review Incoming Invoice", 0, 9));
        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        PayablesAgentKPI.InsertKPIEntry("PA KPI Scenario"::"Agent Tasks Received");
    end;

    procedure BuildAgentTask(EDocument: Record "E-Document"; Agent: Record Agent)
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
        PayablesAgent: Codeunit "Payables Agent";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        PATrial: Codeunit "PA Trial";
        AgentTaskTitle: Text[150];
        Message: Text;
        MustRequestReviewOfMessage: Boolean;
        ExcludeBilling: Boolean;
        TelemetryDictionary: Dictionary of [Text, Text];
        TaskTitleLbl: Label 'E-Document from %1', Comment = '%1 is the sender''s email address.';
        MessageLbl: Label 'A new electronic document %1 has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true, Comment = '%1 is the e-document entry number.';
        TrialModeTok: Label 'Agent Task created in trial mode. Skipping billing for invoice.', Locked = true;
    begin
        PayablesAgentSetup.GetSetup();
        MustRequestReviewOfMessage := PASetup.ShouldRequestReview(EDocument);
        Message := StrSubstNo(MessageLbl, EDocument."Entry No");
        AgentTaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, LowerCase(EDocument."Source Details")), 1, MaxStrLen(AgentTaskTitle));

        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            TelemetryDictionary := PayablesAgent.GetCustomDimensions();
            TelemetryDictionary.Add('TrialInvoiceCount', Format(PATrial.GetTrialInvoiceCount(), 0, 9));
            TelemetryDictionary.Add('TrialInvoiceLimit', Format(PATrial.GetTrialInvoiceLimit(), 0, 9));
            TelemetryDictionary.Add('ExcludeBilling', Format(ExcludeBilling, 0, 9));
            Session.LogMessage('0000SEE', TrialModeTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDictionary);
            ExcludeBilling := true;
        end;

        AgentTaskMessageBuilder
            .Initialize(CopyStr(EDocument."Source Details", 1, 250), Message)
            .SetRequiresReview(MustRequestReviewOfMessage)
            .SetMessageExternalID(Format(EDocument."Entry No"));

        AgentTaskBuilder
            .Initialize(Agent."User Security ID", AgentTaskTitle)
            .SetExternalId(Format(EDocument."Entry No"))
            .AddTaskMessage(AgentTaskMessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
    end;

    internal procedure SetAgentTaskTitle(AgentTaskID: BigInteger; InvoiceNo: Text[50]; VendorName: Text[100])
    var
        AgentTask: Record "Agent Task";
        TaskTitleLbl: Label 'Invoice %1 from %2', Comment = '%1 is the invoice number, %2 is the vendor name.';
    begin
        if AgentTask.Get(AgentTaskID) then begin
            AgentTask.Title := CopyStr(StrSubstNo(TaskTitleLbl, InvoiceNo, VendorName), 1, MaxStrLen(AgentTask.Title));
            AgentTask.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Inbound E-Documents", OnOpenPageEvent, '', false, false)]
    local procedure OnOpenInboundEDocumentsPage(var Rec: Record "E-Document")
    var
        EDocument: Record "E-Document";
    begin
        // Event to ensure agent can only see e-documents that are relevant to their session.
        EDocument := GetCurrentSessionsEDocument();
        if EDocument."Entry No" = 0 then
            exit;
        Rec.SetRange("Entry No", EDocument."Entry No");
    end;

    internal procedure RegisterCapability()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTok: Label 'https://go.microsoft.com/fwlink/?linkid=2304779', Locked = true;
    begin
        // It's only possible to register the copilot capability in SaaS environments
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;
        // If already registered we want to keep the capability registered, and make sure it marked as generally available
        if CopilotCapability.IsCapabilityRegistered("Copilot Capability"::"Payables Agent") then
            CopilotCapability.ModifyCapability("Copilot Capability"::"Payables Agent", "Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTok)
        else// If not registered, we register it and marked it as generally available.
            CopilotCapability.RegisterCapability("Copilot Capability"::"Payables Agent", "Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTok);
    end;

    procedure GetCustomDimensions(): Dictionary of [Text, Text]
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Set('category', GetCategory());
        exit(CustomDimensions);
    end;

    local procedure GetCategory(): Text
    begin
        exit(PayablesAgentTelemetryTok);
    end;

    /// <summary>
    /// Checks whether a Payables Agent exists in any company in the current environment.
    /// </summary>
    /// <returns>True if at least one Payables Agent is registered; otherwise, false.</returns>
    internal procedure PayablesAgentExistsAcrossAllCompanies(): Boolean
    var
        User: Record User;
        Agent: Record Agent;
    begin
        // Waiting for platform bug: 631913 to be fixed, in order to do IsEmpty with filter on Agent table.
        User.SetLoadFields("User Security ID");
        if User.FindSet() then
            repeat
                if Agent.Get(User."User Security ID") then
                    if Agent."Agent Metadata Provider" = "Agent Metadata Provider"::"Payables Agent" then
                        exit(true);

            until User.Next() = 0;
        exit(false);
    end;

    procedure IsPayablesAgentSession(var SessionTaskID: BigInteger): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        CurrentAgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not AgentSession.IsAgentSession(CurrentAgentMetadataProvider) then
            exit(false);

        if CurrentAgentMetadataProvider <> "Agent Metadata Provider"::"Payables Agent" then
            exit(false);

        SessionTaskID := AgentSession.GetCurrentSessionAgentTaskId();
        exit(true);
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        PASetup.GetDefaultProfile(TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        PASetup.GetDefaultAccessControls(TempAccessControlBuffer);
    end;

    var
        PAAnnotation: Codeunit "PA Annotation";
        PASetup: Codeunit "Payables Agent Setup";
        PayablesAgentInitialsTok: Label 'PA', Locked = true, Comment = 'Initials for payables agent.', MaxLength = 4;
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
        PayablesAgentTelemetryTok: Label 'Payables Agent', Locked = true;
}