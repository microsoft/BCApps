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

    procedure GetDesiredSetup(var PASetup: Codeunit "PA Setup")
    begin
        PASetup := DesiredSetup;
    end;

    procedure SetDesiredSetup(var PASetup: Codeunit "PA Setup")
    begin
        DesiredSetup := PASetup;
    end;

    procedure SetDesiredPageRecord(PageRecord: Record "Payables Agent Setup")
    begin
        DesiredSetup.SetPageRecord(PageRecord);
    end;

    procedure GetDesiredPageRecord(): Record "Payables Agent Setup"
    begin
        exit(DesiredSetup.GetPageRecord());
    end;

    procedure Enabling(): Boolean
    begin
        exit(TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled);
    end;

    procedure EnableAgent()
    var
        LocalAgentSetupBuffer: Record "Agent Setup Buffer";
    begin
        GetAgentSetupBuffer(LocalAgentSetupBuffer);
        LocalAgentSetupBuffer.Validate(State, LocalAgentSetupBuffer.State::Enabled);
        SetAgentSetupBuffer(LocalAgentSetupBuffer);
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