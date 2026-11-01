// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

codeunit 3321 "PA Setup Update Parameters"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        DesiredSetup: Codeunit "PA Setup";
        TempBlobTrialUpload: Codeunit "Temp Blob";
        TrialUploadFileName: Text;
        TrialUploadPending: Boolean;
        SkipAgentConfiguration: Boolean;
        SkipEmailVerification: Boolean;

    internal procedure GetSkipAgentConfiguration(): Boolean
    begin
        exit(SkipAgentConfiguration);
    end;

    internal procedure SetSkipAgentConfiguration(LocalSkipAgentConfiguration: Boolean)
    begin
        SkipAgentConfiguration := LocalSkipAgentConfiguration;
    end;

    internal procedure GetSkipEmailVerification(): Boolean
    begin
        exit(SkipEmailVerification);
    end;

    internal procedure SetSkipEmailVerification(LocalSkipEmailVerification: Boolean)
    begin
        SkipEmailVerification := LocalSkipEmailVerification;
    end;

    // Prepares an editable proposal and framework buffer without creating Setup or repairing its association.
    internal procedure InitializeFromStoredSetup()
    var
        Agent: Record Agent;
        TempLoadedAgentSetupBuffer: Record "Agent Setup Buffer";
        StoredSetup: Codeunit "PA Setup";
        PayablesAgentMetadata: Codeunit "Payables Agent Metadata";
        AgentSetup: Codeunit "Agent Setup";
    begin
        if not SkipAgentConfiguration then begin
            if StoredSetup.TryFindAgent(Agent) then;
            AgentSetup.GetSetupRecord(
                TempLoadedAgentSetupBuffer,
                Agent."User Security ID",
                "Agent Metadata Provider"::"Payables Agent",
                StoredSetup.AgentUserName(),
                PayablesAgentMetadata.AgentDisplayName(),
                PayablesAgentMetadata.AgentSummary()
            );
            SetAgentSetupBuffer(TempLoadedAgentSetupBuffer);
        end;

        Clear(DesiredSetup);
        DesiredSetup.LoadStoredOrDefaults();
    end;

    procedure CopyProposal(var Proposal: Codeunit "PA Setup")
    begin
        Proposal := DesiredSetup;
    end;

    procedure SetEmailMonitoring(Enabled: Boolean; ReviewPolicy: Enum "PA Email Review Policy"; AccountId: Guid; FolderName: Text[2048]; FolderId: Text[2048])
    begin
        DesiredSetup.SetMonitorOutlook(Enabled);
        DesiredSetup.SetEmailReviewPolicy(ReviewPolicy);
        DesiredSetup.SetMailboxSelection(AccountId, FolderName, FolderId);
    end;

    procedure Activating(): Boolean
    begin
        exit(TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled);
    end;

    procedure ActivateAgent()
    var
        TempLocalAgentSetupBuffer: Record "Agent Setup Buffer";
    begin
        GetAgentSetupBuffer(TempLocalAgentSetupBuffer);
        TempLocalAgentSetupBuffer.Validate(State, TempLocalAgentSetupBuffer.State::Enabled);
        SetAgentSetupBuffer(TempLocalAgentSetupBuffer);
    end;

    procedure MonitorEmail(): Boolean
    begin
        exit(DesiredSetup.GetMonitorOutlook());
    end;

    procedure DisactivateEmailMonitoring()
    begin
        DesiredSetup.SetMonitorOutlook(false);
    end;

    procedure GetEmailAccount(): Record "Email Account"
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        if IsNullGuid(DesiredSetup.GetEmailAccountId()) then
            exit(TempEmailAccount);
        EmailAccount.GetAllAccounts(false, TempEmailAccount);
        if not TempEmailAccount.Get(DesiredSetup.GetEmailAccountId(), "Email Connector"::"Microsoft 365") then
            Clear(TempEmailAccount);
        exit(TempEmailAccount);
    end;

    procedure GetAgentSetupBuffer(var TargetAgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetup: Codeunit "Agent Setup";
    begin
        AgentSetup.CopySetupRecord(TargetAgentSetupBuffer, TempAgentSetupBuffer);
    end;

    procedure SetAgentSetupBuffer(var SourceAgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetup: Codeunit "Agent Setup";
    begin
        AgentSetup.CopySetupRecord(TempAgentSetupBuffer, SourceAgentSetupBuffer);
    end;


    procedure SetTrialUpload(FileName: Text; InStream: InStream)
    var
        OutStream: OutStream;
    begin
        TempBlobTrialUpload.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TrialUploadFileName := FileName;
        TrialUploadPending := true;
    end;

    procedure HasTrialUpload(): Boolean
    begin
        exit(TrialUploadPending);
    end;

    // Retrieval does not consume the upload; the flow clears it only after successful handoff.
    procedure TryGetTrialUpload(var FileName: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        Clear(FileName);
        Clear(TempBlob);
        if not TrialUploadPending then
            exit(false);
        FileName := TrialUploadFileName;
        TempBlob := TempBlobTrialUpload;
        exit(true);
    end;

    procedure ClearTrialUpload()
    begin
        Clear(TempBlobTrialUpload);
        Clear(TrialUploadFileName);
        TrialUploadPending := false;
    end;

}