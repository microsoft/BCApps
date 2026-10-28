// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

codeunit 3321 "PA Setup Update Parameters" // TODO: how could it look if we made this one more meaty, maybe a lot of the getters/setters internal exposure here could be limited quite a bit
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

    // Loads the editable proposal. Unless agent configuration is skipped, this may create Setup and
    // reconcile its stored Agent User ID before preparing the framework setup buffer.
    internal procedure InitializeFromStoredSetup()
    var
        Agent: Record Agent;
        TempLoadedAgentSetupBuffer: Record "Agent Setup Buffer";
        StoredSetup: Codeunit "PA Setup";
        PayablesAgentMetadata: Codeunit "Payables Agent Metadata";
        AgentSetup: Codeunit "Agent Setup";
    begin
        if not SkipAgentConfiguration then begin
            if StoredSetup.FindAgentAndReconcileSetup(Agent) then;
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
        DesiredSetup.GetSetup();
    end;

    procedure GetDesiredSetup(var PASetup: Codeunit "PA Setup")
    begin
        PASetup := DesiredSetup;
    end;

    procedure SetDesiredSetup(var PASetup: Codeunit "PA Setup")
    begin
        DesiredSetup := PASetup;
    end;

    procedure SetMonitorEmail(Value: Boolean)
    begin
        DesiredSetup.SetMonitorOutlook(Value);
    end;

    procedure SetEmailReviewPolicy(Value: Enum "PA Email Review Policy")
    begin
        DesiredSetup.SetEmailReviewPolicy(Value);
    end;

    procedure SetMailboxSelection(AccountId: Guid; FolderName: Text[2048]; FolderId: Text[2048])
    begin
        DesiredSetup.SetMailboxSelection(AccountId, FolderName, FolderId);
    end;

    procedure Enabling(): Boolean
    begin
        exit(TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled);
    end;

    procedure PrepareForApply()
    begin
        DesiredSetup.PrepareForApply(Enabling());
    end;

    procedure EnableAgent()
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

    procedure DisableEmailMonitoring()
    begin
        DesiredSetup.SetMonitorOutlook(false);
    end;

    procedure GetEmailReviewPolicy(): Enum "PA Email Review Policy"
    begin
        exit(DesiredSetup.GetEmailReviewPolicy());
    end;

    procedure SetLastActivated(LastActivated: DateTime)
    begin
        DesiredSetup.SetLastActivated(LastActivated);
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

    procedure GetAgentSetupBuffer(): Record "Agent Setup Buffer"
    begin
        exit(TempAgentSetupBuffer);
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

    procedure GetTrialUploadPending(): Boolean
    begin
        exit(TrialUploadPending);
    end;

    procedure GetTrialUploadFileName(): Text
    begin
        exit(TrialUploadFileName);
    end;

    procedure GetTrialUploadBlob(var TempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := TempBlobTrialUpload;
    end;

    procedure ClearTrialUpload()
    begin
        Clear(TempBlobTrialUpload);
        Clear(TrialUploadFileName);
        TrialUploadPending := false;
    end;

}