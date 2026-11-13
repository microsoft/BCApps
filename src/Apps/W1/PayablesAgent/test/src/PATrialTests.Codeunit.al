// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

// PA-owned trial storage/count contracts; framework agent eligibility and activation need runtime validation.
codeunit 133722 "PA Trial Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATrial: Codeunit "PA Trial";
        Assert: Codeunit Assert;

    [Test]
    procedure IsNotEligibleForTrialWhenTrialAlreadyStarted()
    begin
        // [SCENARIO] A company that already started the trial is no longer eligible to start it.
        // [GIVEN] A reset trial state.
        PATrial.ResetTrial();

        // [WHEN] The trial is started.
        PATrial.StartTrial();

        // [THEN] The company is not eligible to start the trial again.
        Assert.IsFalse(PATrial.IsEligibleToStart(), 'Should not be eligible for trial when trial has already been started');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure InitializeTrialModeSetsCountToZero()
    begin
        // [SCENARIO] Starting the trial initializes the invoice count to zero.
        // [GIVEN] A reset trial state.
        PATrial.ResetTrial();

        // [WHEN] The trial is started.
        PATrial.StartTrial();

        // [THEN] The trial invoice count is zero.
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 after initialization');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IncrementTrialInvoiceCountIncreasesByOne()
    begin
        // [SCENARIO] Each trial invoice increments the trial invoice count by one.
        // [GIVEN] A started trial.
        PATrial.ResetTrial();
        PATrial.StartTrial();

        // [WHEN] The trial invoice count is incremented once.
        PATrial.IncrementTrialInvoiceCount();

        // [THEN] The count is one.
        Assert.AreEqual(1, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 1 after one increment');

        // [WHEN] It is incremented again.
        PATrial.IncrementTrialInvoiceCount();

        // [THEN] The count is two.
        Assert.AreEqual(2, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 2 after two increments');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IsInTrialModeWhenTrialStartedAndUnderLimit()
    begin
        // [SCENARIO] A started trial under its invoice limit is active.
        // [GIVEN] A started trial with no invoices counted.
        PATrial.ResetTrial();
        PATrial.StartTrial();

        // [WHEN] The trial state is checked.
        // [THEN] The trial is active.
        Assert.IsTrue(PATrial.CheckActiveAndEndIfExhausted(), 'Should be in trial mode when under the limit');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IsNotInTrialModeWhenTrialNotStarted()
    begin
        // [SCENARIO] A trial that was never started is not active.
        // [GIVEN] A reset trial state.
        PATrial.ResetTrial();

        // [WHEN] The trial state is checked.
        // [THEN] The trial is not active.
        Assert.IsFalse(PATrial.CheckActiveAndEndIfExhausted(), 'Should not be in trial mode when trial has not been started');
    end;

    [Test]
    procedure IsNotInTrialModeWhenLimitReached()
    var
        i: Integer;
    begin
        // [SCENARIO] A trial that reached its invoice limit is no longer active.
        // [GIVEN] A started trial.
        PATrial.ResetTrial();
        PATrial.StartTrial();

        // [WHEN] The invoice count reaches the trial limit.
        for i := 1 to PATrial.GetTrialInvoiceLimit() do
            PATrial.IncrementTrialInvoiceCount();

        // [THEN] The trial is not active and the count equals the limit.
        Assert.IsFalse(PATrial.CheckActiveAndEndIfExhausted(), 'Should not be in trial mode when limit is reached');
        Assert.AreEqual(PATrial.GetTrialInvoiceLimit(), PATrial.GetTrialInvoiceCount(), 'Count should equal limit');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure GetTrialInvoiceLimitReturnsFifty()
    begin
        // [SCENARIO] The trial allows 50 invoices.
        // [WHEN] The trial invoice limit is read.
        // [THEN] It is 50.
        Assert.AreEqual(50, PATrial.GetTrialInvoiceLimit(), 'Trial invoice limit should be 50');
    end;

    [Test]
    procedure GetTrialInvoiceCountReturnsZeroWhenNotInitialized()
    begin
        // [SCENARIO] Without a started trial, the trial invoice count is zero.
        // [GIVEN] A reset trial state.
        PATrial.ResetTrial();

        // [WHEN] The trial invoice count is read.
        // [THEN] It is zero.
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 when not initialized');
    end;
}
