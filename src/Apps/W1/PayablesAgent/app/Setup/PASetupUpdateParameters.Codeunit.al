// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

/// <summary>
/// Input of one setup update run (see "PA Setup Update"): the desired setup as edited on the setup page, the agent
/// framework setup buffer, and what else the update needs (trial upload, skip flags). Pure data: it neither branches
/// on the Payables Agent version nor performs the update.
/// </summary>
codeunit 3321 "PA Setup Update Parameters"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        TempPADetailedSetup: Record "PA Detailed Setup";
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

    procedure GetDesiredSetup(): Record "PA Detailed Setup"
    begin
        exit(TempPADetailedSetup);
    end;

    procedure SetDesiredSetup(NewPADetailedSetup: Record "PA Detailed Setup")
    begin
        TempPADetailedSetup := NewPADetailedSetup;
    end;

    /// <summary>
    /// Whether the update leaves the agent enabled.
    /// </summary>
    procedure Enabling(): Boolean
    begin
        exit(TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled);
    end;

    /// <summary>
    /// Sets the agent to be enabled by the update.
    /// </summary>
    procedure EnableAgent()
    var
        LocalAgentSetupBuffer: Record "Agent Setup Buffer";
    begin
        GetAgentSetupBuffer(LocalAgentSetupBuffer);
        LocalAgentSetupBuffer.Validate(State, LocalAgentSetupBuffer.State::Enabled);
        SetAgentSetupBuffer(LocalAgentSetupBuffer);
    end;

    /// <summary>
    /// Whether the desired setup monitors the mailbox.
    /// </summary>
    procedure MonitorEmail(): Boolean
    begin
        exit(TempPADetailedSetup."Monitor Outlook");
    end;

    /// <summary>
    /// Turns off mailbox monitoring in the desired setup.
    /// </summary>
    procedure DisableEmailMonitoring()
    begin
        TempPADetailedSetup."Monitor Outlook" := false;
    end;

    procedure GetEmailReviewPolicy(): Enum "PA Email Review Policy"
    begin
        exit(TempPADetailedSetup."Email Review Policy");
    end;

    procedure SetLastActivated(LastActivated: DateTime)
    begin
        TempPADetailedSetup."Last Activated" := LastActivated;
    end;

    procedure GetEmailAccount(): Record "Email Account"
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        if IsNullGuid(TempPADetailedSetup."Email Account Id") then
            exit(TempEmailAccount);
        EmailAccount.GetAllAccounts(false, TempEmailAccount);
        if not TempEmailAccount.Get(TempPADetailedSetup."Email Account Id", "Email Connector"::"Microsoft 365") then
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


    /// <summary>
    /// Stores the trial upload file data for later processing.
    /// </summary>
    /// <param name="FileName">The name of the uploaded file.</param>
    /// <param name="InStream">The stream containing the file data.</param>
    procedure SetTrialUpload(FileName: Text; InStream: InStream)
    var
        OutStream: OutStream;
    begin
        TempBlobTrialUpload.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TrialUploadFileName := FileName;
        TrialUploadPending := true;
    end;

    /// <summary>
    /// Checks if there is a pending trial upload to process.
    /// </summary>
    /// <returns>True if a trial upload is pending; otherwise, false.</returns>
    procedure GetTrialUploadPending(): Boolean
    begin
        exit(TrialUploadPending);
    end;

    /// <summary>
    /// Gets the file name of the pending trial upload.
    /// </summary>
    /// <returns>The file name.</returns>
    procedure GetTrialUploadFileName(): Text
    begin
        exit(TrialUploadFileName);
    end;

    /// <summary>
    /// Gets the blob containing the trial upload file content.
    /// </summary>
    /// <param name="TempBlob">The Temp Blob codeunit to receive the file data.</param>
    procedure GetTrialUploadBlob(var TempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := TempBlobTrialUpload;
    end;

    /// <summary>
    /// Clears the pending trial upload data.
    /// </summary>
    procedure ClearTrialUpload()
    begin
        Clear(TempBlobTrialUpload);
        Clear(TrialUploadFileName);
        TrialUploadPending := false;
    end;

}