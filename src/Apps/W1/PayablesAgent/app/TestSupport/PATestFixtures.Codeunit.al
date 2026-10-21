// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

/// <summary>
/// The surface the Payables Agent tests interact with the app through: configuring the agent with a test
/// configuration, handing it tasks, and recognizing what the agent asks for along a run. It is composed only of the
/// app's own flows and entities, so it stays the same for the draft-based (v1) and the task-based (v2) agent; the tests
/// built on it do not know which one is active.
/// Only visible to the test apps (internalsVisibleTo). Not used by the app itself.
/// </summary>
codeunit 3326 "PA Test Fixtures"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = RD, tabledata "Agent Task" = R;

    #region Configuration

    /// <summary>
    /// Loads the stored setup as the configuration to apply, in test mode: the mailbox is never contacted.
    /// </summary>
    /// <param name="CreateAgentUser">Whether applying the configuration creates and configures the agent user in the agent framework. Tests that only exercise the app's own state can skip it.</param>
    internal procedure LoadConfiguration(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; CreateAgentUser: Boolean)
    begin
        Clear(PASetupUpdateParameters);
        PASetupUpdateParameters.SetSkipAgentConfiguration(not CreateAgentUser);
        PASetupUpdateParameters.SetSkipEmailVerification(true);
        PASetupUpdate.Load(PASetupUpdateParameters);
    end;

    /// <summary>
    /// Sets whether the agent monitors a mailbox, which one, and when the emails it receives need review.
    /// </summary>
    internal procedure SetEmailMonitoring(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; MonitorEmail: Boolean; EmailAccountId: Guid; ReviewPolicy: Enum "PA Email Review Policy")
    var
        TempPageRecord: Record "Payables Agent Setup" temporary;
    begin
        TempPageRecord := PASetupUpdateParameters.GetDesiredPageRecord();
        TempPageRecord."Monitor Outlook" := MonitorEmail;
        TempPageRecord."Email Account Id" := EmailAccountId;
        TempPageRecord."Email Review Policy" := ReviewPolicy;
        PASetupUpdateParameters.SetDesiredPageRecord(TempPageRecord);
    end;

    /// <summary>
    /// Applies the configuration with the agent enabled, through the same flow as the setup page.
    /// </summary>
    internal procedure Activate(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Enabled;
        PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupUpdate.Update(PASetupUpdateParameters);
    end;

    /// <summary>
    /// Brings the agent back to never having been configured: deactivates and deletes the agent user, and clears the
    /// stored setup (including whatever the active version projects it onto).
    /// </summary>
    internal procedure Reset()
    var
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        TempBlankPageRecord: Record "Payables Agent Setup" temporary;
        PASetup: Codeunit "PA Setup";
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
    begin
        if PAAgentConfiguration.GetAgent(Agent, false) then begin
            LoadConfiguration(PASetupUpdateParameters, true);
            PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
            TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Disabled;
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
            PASetupUpdate.Update(PASetupUpdateParameters);
            if Agent.Get(Agent."User Security ID") then
                Agent.Delete();
        end;

        PASetup.GetSetup();
        TempBlankPageRecord.Init();
        PASetup.SetPageRecord(TempBlankPageRecord);
        PASetup.ApplySetup(false);
        PASetup.DeleteSetup(CopyStr(CompanyName(), 1, 30));
    end;

    #endregion

    #region Tasks

    /// <summary>
    /// Hands a PDF to the agent the way an upload does, and loads the task the agent was given for it.
    /// </summary>
    /// <returns>False when the agent was not given a task, for example because it is not active.</returns>
    internal procedure CreateTaskFromPdf(FileName: Text; PdfInStream: InStream; var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        PATaskIntake: Codeunit "PA Task Intake";
        LastAgentTaskIdBefore: BigInteger;
        LastAgentTaskId: BigInteger;
    begin
        LastAgentTaskIdBefore := GetLastAgentTaskId();
        PATaskIntake.CreateTask(FileName, PdfInStream);
        LastAgentTaskId := GetLastAgentTaskId();
        if LastAgentTaskId = LastAgentTaskIdBefore then
            exit(false);
        exit(PATask.Load(LastAgentTaskId));
    end;

    #endregion

    #region Checkpoints along a run

    /// <summary>
    /// Whether a review the agent requested is the review of what it prepared for the task: the draft of the task's
    /// source (v1) or the purchase invoice registered as the task's outcome (v2).
    /// </summary>
    internal procedure IsReviewOfTaskResult(AgentTaskId: BigInteger; ReviewRecordId: RecordId): Boolean
    var
        PATask: Codeunit "Payables Agent Task";
    begin
        if ReviewRecordId.TableNo() = 0 then
            exit(false);
        if not PATask.Load(AgentTaskId) then
            exit(false);
        exit(PATask.IsResultRecord(ReviewRecordId));
    end;

    /// <summary>
    /// The code of the suggestion the agent offers to create the vendor it could not find.
    /// </summary>
    internal procedure GetCreateVendorSuggestionCode(): Code[20]
    var
        TempRequestDetails: Record "Agent User Int Request Details" temporary;
        TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        PAAgentTaskExecution: Codeunit "PA Agent Task Execution";
    begin
        PAAgentTaskExecution.GetAgentTaskUserInterventionSuggestions(TempRequestDetails, TempSuggestion);
        if TempSuggestion.FindFirst() then
            exit(TempSuggestion.Code);
        exit('');
    end;

    #endregion

    local procedure GetLastAgentTaskId(): BigInteger
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
    begin
        if not PAAgentConfiguration.GetAgent(Agent, false) then
            exit(0);
        AgentTask.SetRange("Agent User Security ID", Agent."User Security ID");
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetLoadFields(ID);
        if AgentTask.FindLast() then
            exit(AgentTask.ID);
        exit(0);
    end;

    var
        PASetupUpdate: Codeunit "PA Setup Update";
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
}
