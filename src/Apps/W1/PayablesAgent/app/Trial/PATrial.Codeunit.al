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

    /// <summary>
    /// Checks whether the current company is eligible to start a trial.
    /// Returns true only when no trial has been started and no agent exists in this company.
    /// </summary>
    [Scope('OnPrem')]
    procedure IsEligibleToStart(): Boolean
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
        Agent: Record Agent;
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // If trial has already ended or started, no company is eligible for trial
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) or IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            exit(false);

        // Only production environments
        if not EnvironmentInformation.IsProduction() then
            exit(false);

        PayablesAgentSetup.GetSetup();
        if Agent.Get(PayablesAgentSetup."User Security Id") then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Initializes the trial mode by marking trial as started and setting the invoice count to zero.
    /// </summary>
    [Scope('OnPrem')]
    procedure StartTrial()
    var
        PayablesAgent: Codeunit "Payables Agent";
    begin
        // If trial has already ended or started, no company is eligible for trial
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) or IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            exit;

        IsolatedStorage.Set(PayablesAgentTrialStartedTok, 'true');
        IsolatedStorage.Set(PayablesAgentTrialInvoiceCountTok, '0');
        Session.LogMessage('0000SEH', TrialModeInitializedTelemetryTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());
    end;

    [Scope('OnPrem')]
    internal procedure ResetTrial()
    var
        PayablesAgent: Codeunit "Payables Agent";
    begin
        if IsolatedStorage.Contains(PayablesAgentTrialStartedTok) then
            IsolatedStorage.Delete(PayablesAgentTrialStartedTok);
        if IsolatedStorage.Contains(PayablesAgentTrialEndedTok) then
            IsolatedStorage.Delete(PayablesAgentTrialEndedTok);
        if IsolatedStorage.Contains(PayablesAgentTrialInvoiceCountTok) then
            IsolatedStorage.Delete(PayablesAgentTrialInvoiceCountTok);
        Session.LogMessage('0000SEI', TrialStateResetTelemetryTok, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());
    end;

    /// <summary>
    /// Checks whether the current company is in trial mode and has not exceeded the invoice limit.
    /// </summary>
    /// <returns>True if in trial mode and under the limit; otherwise, false.</returns>
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

    /// <summary>
    /// Increments the count of invoices processed during the trial period.
    /// </summary>
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

    /// <summary>
    /// Gets the current count of invoices processed during the trial period.
    /// </summary>
    /// <returns>The number of invoices processed.</returns>
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

    /// <summary>
    /// Gets the maximum number of invoices allowed during the trial period.
    /// </summary>
    /// <returns>The trial invoice limit.</returns>
    [Scope('OnPrem')]
    procedure GetTrialInvoiceLimit(): Integer
    begin
        exit(50);
    end;

    /// <summary>
    /// Marks the trial as ended at the module (tenant) scope, preventing any company from starting a trial.
    /// </summary>
    [Scope('OnPrem')]
    internal procedure MarkTrialEnded()
    begin
        IsolatedStorage.Set(PayablesAgentTrialEndedTok, 'true');
    end;

    var
        PayablesAgentTrialStartedTok: Label 'PayablesAgentTrialStarted', Locked = true;
        PayablesAgentTrialInvoiceCountTok: Label 'PayablesAgentTrialInvoiceCount', Locked = true;
        PayablesAgentTrialEndedTok: Label 'PayablesAgentTrialEnded', Locked = true;
        TrialModeInitializedTelemetryTok: Label 'Trial mode initialized.', Locked = true;
        TrialStateResetTelemetryTok: Label 'Trial state reset.', Locked = true;
}
