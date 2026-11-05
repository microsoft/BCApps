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
        PATrial.ResetTrial();
        PATrial.StartTrial();
        Assert.IsFalse(PATrial.IsEligibleToStart(), 'Should not be eligible for trial when trial has already been started');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure InitializeTrialModeSetsCountToZero()
    begin
        PATrial.ResetTrial();
        PATrial.StartTrial();
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 after initialization');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IncrementTrialInvoiceCountIncreasesByOne()
    begin
        PATrial.ResetTrial();
        PATrial.StartTrial();
        PATrial.IncrementTrialInvoiceCount();
        Assert.AreEqual(1, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 1 after one increment');
        PATrial.IncrementTrialInvoiceCount();
        Assert.AreEqual(2, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 2 after two increments');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IsInTrialModeWhenTrialStartedAndUnderLimit()
    begin
        PATrial.ResetTrial();
        PATrial.StartTrial();
        Assert.IsTrue(PATrial.CheckActiveAndEndIfExhausted(), 'Should be in trial mode when under the limit');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure IsNotInTrialModeWhenTrialNotStarted()
    begin
        PATrial.ResetTrial();
        Assert.IsFalse(PATrial.CheckActiveAndEndIfExhausted(), 'Should not be in trial mode when trial has not been started');
    end;

    [Test]
    procedure IsNotInTrialModeWhenLimitReached()
    var
        i: Integer;
    begin
        PATrial.ResetTrial();
        PATrial.StartTrial();
        for i := 1 to PATrial.GetTrialInvoiceLimit() do
            PATrial.IncrementTrialInvoiceCount();
        Assert.IsFalse(PATrial.CheckActiveAndEndIfExhausted(), 'Should not be in trial mode when limit is reached');
        Assert.AreEqual(PATrial.GetTrialInvoiceLimit(), PATrial.GetTrialInvoiceCount(), 'Count should equal limit');
        PATrial.ResetTrial();
    end;

    [Test]
    procedure GetTrialInvoiceLimitReturnsFifty()
    begin
        Assert.AreEqual(50, PATrial.GetTrialInvoiceLimit(), 'Trial invoice limit should be 50');
    end;

    [Test]
    procedure GetTrialInvoiceCountReturnsZeroWhenNotInitialized()
    begin
        PATrial.ResetTrial();
        Assert.AreEqual(0, PATrial.GetTrialInvoiceCount(), 'Trial invoice count should be 0 when not initialized');
    end;
}
