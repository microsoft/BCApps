// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

codeunit 133722 "PA Trial Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATestFixtures: Codeunit "PA Test Fixtures";
        PATrial: Codeunit "PA Trial";
        Assert: Codeunit Assert;

    [Test]
    procedure IsEligibleForTrialWhenNoAgentExists()
    begin
        // [GIVEN] No agent exists and trial has not been started
        ResetTrialState();
        ResetPayablesAgent();


        // [WHEN] Checking trial eligibility
        // [THEN] User is eligible for trial
        Assert.IsTrue(PATrial.IsEligibleToStart(), 'Should be eligible for trial when no agent exists');

        ResetPayablesAgent();
    end;

    [Test]
    procedure IsNotEligibleForTrialWhenTrialAlreadyStarted()
    begin
        // [GIVEN] No agent exists but trial has been started
        ResetTrialState();
        ResetPayablesAgent();
        PATrial.StartTrial();

        // [WHEN] Checking trial eligibility
        // [THEN] User is not eligible (trial already started)
        Assert.IsFalse(PATrial.IsEligibleToStart(), 'Should not be eligible for trial when trial has already been started');

        ResetTrialState();
        ResetPayablesAgent();
    end;

    [Test]
    procedure IsNotEligibleForTrialWhenAgentIsActive()
    begin
        // [GIVEN] The Payables Agent is activated
        ResetTrialState();
        ResetPayablesAgent();
        SetupPayablesAgent();

        // [WHEN] Checking trial eligibility
        // [THEN] User is not eligible (agent already active)
        Assert.IsFalse(PATrial.IsEligibleToStart(), 'Should not be eligible for trial when agent is already active');

        ResetPayablesAgent();
    end;

    [Test]
    procedure InitializeTrialModeSetsCountToZero()
    begin
        // [GIVEN] Trial has not been started
        ResetTrialState();

        // [WHEN] Initializing trial mode
        PATrial.StartTrial();

        // [THEN] Invoice count is 0
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 after initialization');

        ResetTrialState();
    end;

    [Test]
    procedure IncrementTrialInvoiceCountIncreasesByOne()
    begin
        // [GIVEN] Trial is initialized with 0 invoices
        ResetTrialState();
        PATrial.StartTrial();

        // [WHEN] Incrementing the trial invoice count
        PATrial.IncrementTrialInvoiceCount();

        // [THEN] Count is 1
        Assert.AreEqual(1, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 1 after one increment');

        // [WHEN] Incrementing again
        PATrial.IncrementTrialInvoiceCount();

        // [THEN] Count is 2
        Assert.AreEqual(2, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 2 after two increments');

        ResetTrialState();
    end;

    [Test]
    procedure IsInTrialModeWhenTrialStartedAndUnderLimit()
    begin
        // [GIVEN] Trial is initialized with 0 invoices processed
        ResetTrialState();
        PATrial.StartTrial();

        // [WHEN] Checking if in trial mode
        // [THEN] Should be in trial mode (0 < 20)
        Assert.IsTrue(PATrial.IsActive(), 'Should be in trial mode when under the limit');

        ResetTrialState();
    end;

    [Test]
    procedure IsNotInTrialModeWhenTrialNotStarted()
    begin
        // [GIVEN] Trial has not been started
        ResetTrialState();

        // [WHEN] Checking if in trial mode
        // [THEN] Should not be in trial mode
        Assert.IsFalse(PATrial.IsActive(), 'Should not be in trial mode when trial has not been started');
    end;

    [Test]
    procedure IsNotInTrialModeWhenLimitReached()
    var
        i: Integer;
    begin
        // [GIVEN] Trial is initialized and invoice limit has been reached
        ResetTrialState();
        PATrial.StartTrial();
        for i := 1 to PATrial.GetTrialInvoiceLimit() do
            PATrial.IncrementTrialInvoiceCount();

        // [WHEN] Checking if in trial mode
        // [THEN] Should not be in trial mode (count >= limit)
        Assert.IsFalse(PATrial.IsActive(), 'Should not be in trial mode when limit is reached');
        Assert.AreEqual(PATrial.GetTrialInvoiceLimit(), PATrial.GetTrialInvoiceCount(), 'Count should equal limit');

        ResetTrialState();
    end;

    [Test]
    procedure GetTrialInvoiceLimitReturnsFifty()
    begin
        // [WHEN] Getting the trial invoice limit
        // [THEN] Limit is 50
        Assert.AreEqual(50, PATrial.GetTrialInvoiceLimit(), 'Trial invoice limit should be 50');
    end;

    [Test]
    procedure GetTrialInvoiceCountReturnsZeroWhenNotInitialized()
    begin
        // [GIVEN] Trial has not been initialized
        ResetTrialState();

        // [WHEN] Getting the trial invoice count
        // [THEN] Count is 0
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 when not initialized');
    end;

    [Test]
    procedure TrialInitializedOnFirstActivation()
    begin
        // [GIVEN] Agent has not been activated before and trial is eligible
        ResetTrialState();
        ResetPayablesAgent();
        Assert.IsTrue(PATrial.IsEligibleToStart(), 'Should be eligible before first activation');

        // [WHEN] Activating the agent for the first time
        SetupPayablesAgent();

        // [THEN] Trial mode is initialized
        Assert.IsFalse(PATrial.IsEligibleToStart(), 'Should no longer be eligible after activation');

        ResetTrialState();
        ResetPayablesAgent();
    end;

    local procedure SetupPayablesAgent()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
    begin
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.Activate(PASetupUpdateParameters);
    end;

    local procedure ResetPayablesAgent()
    begin
        PATestFixtures.Reset();
    end;

    local procedure ResetTrialState()
    begin
        PATrial.ResetTrial();
    end;

}
