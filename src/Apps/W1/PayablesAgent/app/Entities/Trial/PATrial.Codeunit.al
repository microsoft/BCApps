// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Environment;
using System.Security;

codeunit 3318 "PA Trial"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    // IMPORTANT: This codeunit MUST NOT have any subscribers.

    var
        PayablesAgentTrialStartedTok: Label 'PayablesAgentTrialStarted', Locked = true;
        PayablesAgentTrialInvoiceCountTok: Label 'PayablesAgentTrialInvoiceCount', Locked = true;
        PayablesAgentTrialEndedTok: Label 'PayablesAgentTrialEnded', Locked = true;

    [Scope('OnPrem')]
    procedure IsEligibleToStart(): Boolean
    var
        Agent: Record Agent;
        PASetup: Codeunit "PA Setup";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // If trial has already ended or started, no company is eligible for trial
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) or IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            exit(false);

        // Only production environments
        if not EnvironmentInformation.IsProduction() then
            exit(false);

        PASetup.GetSetup();
        if Agent.Get(PASetup.GetUserSecurityId()) then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure StartTrial()
    var
        PATelemetry: Codeunit "PA Telemetry";
    begin
        // If trial has already ended or started, no company is eligible for trial
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) or IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            exit;

        IsolatedStorage.Set(PayablesAgentTrialStartedTok, 'true');
        IsolatedStorage.Set(PayablesAgentTrialInvoiceCountTok, '0');
        PATelemetry.LogTrialStarted();
    end;

    [Scope('OnPrem')]
    internal procedure ResetTrial()
    var
        PATelemetry: Codeunit "PA Telemetry";
    begin
        if IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            IsolatedStorage.Delete(PayablesAgentTrialStartedTok);
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) then
            IsolatedStorage.Delete(PayablesAgentTrialEndedTok);
        if IsolatedStorage.Contains(PayablesAgentTrialInvoiceCountTok) then
            IsolatedStorage.Delete(PayablesAgentTrialInvoiceCountTok);
        PATelemetry.LogTrialReset();
    end;

    [Scope('OnPrem')]
    procedure IsActive(): Boolean
    var
        StartedText: Text;
        CanContinue: Boolean;
    begin
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) then
            exit(false);
        if not IsolatedStorage.Get(PayablesAgentTrialStartedTok, StartedText) then
            exit(false);

        CanContinue := (GetTrialInvoiceCount() < GetTrialInvoiceLimit());
        if not CanContinue then
            MarkTrialEnded();
        exit(CanContinue);
    end;

    [Scope('OnPrem')]
    procedure IncrementTrialInvoiceCount()
    var
        IsolatedStorageRec: Record "Isolated Storage";
        CurrentCount: Integer;
    begin
        IsolatedStorageRec.LockTable();
        CurrentCount := GetTrialInvoiceCount();
        IsolatedStorage.Set(PayablesAgentTrialInvoiceCountTok, Format(CurrentCount + 1, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure GetTrialInvoiceCount(): Integer
    var
        CountText: Text;
        CountValue: Integer;
    begin
        if not IsolatedStorage.Get(PayablesAgentTrialInvoiceCountTok, CountText) then
            exit(0);
        if not Evaluate(CountValue, CountText, 9) then
            exit(0);

        exit(CountValue);
    end;

    [Scope('OnPrem')]
    procedure GetTrialInvoiceLimit(): Integer
    begin
        exit(50);
    end;

    [Scope('OnPrem')]
    internal procedure MarkTrialEnded()
    begin
        IsolatedStorage.Set(PayablesAgentTrialEndedTok, 'true');
    end;
}
