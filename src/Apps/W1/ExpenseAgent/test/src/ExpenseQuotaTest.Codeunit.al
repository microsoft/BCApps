// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;

// [FEATURE] [Expense Agent] [Quota]
codeunit 148298 "Expense Quota Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Expense Agent Env. Consumption" = rimd;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RetryingV1TrialConsumptionDoesNotConsumeTrialQuota()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] V1 trial consumption and retries do not consume trial quota or report paid usage
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, true);
        ConsumptionSourceSystemId := CreateGuid();

        FirstConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS', 'QUOTA TEST');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'V1 consumption must preserve trial quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'V1 consumption must not decrement trial quota.');

        SecondConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS', 'QUOTA TEST');

        Assert.AreEqual(FirstConsumptionId, SecondConsumptionId, 'The retry should return the original consumption ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(SecondConsumptionId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Is Feature Trial", 'The retry should remain classified as trial consumption.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", ConsumptionSourceSystemId);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'The retry should not create another consumption record.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 consumption must be submitted on both requests.');
        Assert.IsTrue(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'V1 trial consumption must be excluded from billing.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'V1 retries must not decrement trial quota.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'V1 retries must preserve trial quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidReportCount(), 'The trial retry must not report paid consumption.');
    end;

    [Test]
    procedure ZeroV1TrialConsumptionIsNotReported()
    begin
        // [SCENARIO] Zero V1 usage is ignored while trial quota is available
        VerifyZeroV1ConsumptionIsNotReported(1);
    end;

    [Test]
    procedure ZeroV1PaidConsumptionIsNotReported()
    begin
        // [SCENARIO] Zero V1 usage is ignored after trial quota is exhausted
        VerifyZeroV1ConsumptionIsNotReported(0);
    end;

    [Test]
    procedure RetryingPaidConsumptionWithTrialQuotaDoesNotChangeClassification()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A paid consumption remains paid if trial quota becomes available before a retry
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 0, true);
        ConsumptionSourceSystemId := CreateGuid();
        FirstConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS EXPENSE', 'QUOTA TEST');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetPaidReportCount(), 'The first consumption should use paid reporting.');

        ExpenseAgentQuotaMock.SetTrialQuota(1);
        SecondConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS EXPENSE', 'QUOTA TEST');

        Assert.AreEqual(FirstConsumptionId, SecondConsumptionId, 'The retry should return the original consumption ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(SecondConsumptionId);
        Assert.IsFalse(ExpenseAgentEnvConsumption."Is Feature Trial", 'The retry should remain classified as paid consumption.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", ConsumptionSourceSystemId);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'The retry should not create another consumption record.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetPaidReportCount(), 'The retry should continue using paid reporting.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The paid retry must not report trial consumption.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'The paid retry must not consume trial quota.');
    end;

    [Test]
    procedure CanConsumeWithOnlyTrialQuota()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Trial quota permits consumption without paid quota
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, false);

        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(), 'Trial quota should permit consumption without paid quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Paid quota should not be queried while trial quota is available.');
    end;

    [Test]
    procedure CanConsumeWithOnlyPaidQuota()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Paid quota permits consumption after trial exhaustion
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 0, true);

        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(), 'Paid quota should permit consumption after trial exhaustion.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Paid quota should be queried after trial exhaustion.');
    end;

    [Test]
    procedure CannotConsumeWithoutTrialOrPaidQuota()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption is unavailable when neither trial nor paid quota is available
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 0, false);

        Assert.IsFalse(ExpenseConsumptionHandler.CanConsume(), 'Consumption should be unavailable without trial or paid quota.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Paid quota should be queried before consumption is rejected.');
    end;

    [Test]
    procedure CanConsumeWithTrialAndPaidQuota()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Trial quota takes precedence when both trial and paid quota are available
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, true);

        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(), 'Available trial and paid quota should permit consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Paid quota should not be queried while trial quota is available.');
    end;

    [Test]
    procedure CanConsumeForPrincipalWithTrialQuota()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] Trial quota permits consumption without evaluating the principal's paid quota
        // [GIVEN] Trial quota is available and paid quota is unavailable
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, false);

        // [WHEN] [THEN] The expense user can consume without a paid quota check
        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(CreateGuid()), 'Trial quota should permit consumption for the expense user.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Paid quota should not be queried while trial quota is available.');
    end;

    [Test]
    procedure CanConsumeChecksEachRequestedPrincipal()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        FirstPrincipalId: Guid;
        SecondPrincipalId: Guid;
    begin
        // [SCENARIO] Paid quota checks use each requested expense user's principal and preserve the decision
        // [GIVEN] Trial quota is exhausted and two expense users have distinct principals
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 0, true);
        FirstPrincipalId := CreateGuid();
        SecondPrincipalId := CreateGuid();

        // [WHEN] [THEN] The first principal's available paid quota permits consumption
        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(FirstPrincipalId), 'Available paid quota should permit consumption.');
        Assert.AreEqual(FirstPrincipalId, ExpenseAgentQuotaMock.GetLastPaidQuotaPrincipalId(), 'The first quota check must use the first expense user''s principal.');

        // [GIVEN] Paid quota is unavailable for the next check
        ExpenseAgentQuotaMock.SetPaidQuotaAvailable(false);

        // [WHEN] [THEN] The second principal's quota prevents consumption without reusing the first principal
        Assert.IsFalse(ExpenseConsumptionHandler.CanConsume(SecondPrincipalId), 'Unavailable paid quota should prevent consumption.');
        Assert.AreEqual(SecondPrincipalId, ExpenseAgentQuotaMock.GetLastPaidQuotaPrincipalId(), 'The second quota check must use the second expense user''s principal.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Each expense user must have a separate quota check.');
    end;

    local procedure VerifyZeroV1ConsumptionIsNotReported(RemainingTrialQuota: Integer)
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        ConsumptionId: Guid;
    begin
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, RemainingTrialQuota, true);
        SourceId := CreateGuid();

        // [WHEN] Zero usage is reported for PROCESS
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            0, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, SourceId, 'PROCESS', 'QUOTA TEST');

        // [THEN] No consumption or trial usage is recorded
        Assert.IsTrue(IsNullGuid(ConsumptionId), 'Zero V1 usage must not return a consumption ID.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", SourceId);
        Assert.IsTrue(ExpenseAgentEnvConsumption.IsEmpty(), 'Zero V1 usage must not create a companion record.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Zero usage must not be sent to V1.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'The V1 action must not report V2 consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Zero V1 usage must not decrement trial quota.');
        Assert.AreEqual(RemainingTrialQuota, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Zero V1 usage must preserve trial quota.');
    end;

    local procedure InitializeQuotaProvider(
        var ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        var ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        RemainingTrialQuota: Integer;
        PaidQuotaAvailable: Boolean)
    begin
        ExpenseAgentQuotaMock.SetTrialQuota(RemainingTrialQuota);
        ExpenseAgentQuotaMock.SetPaidQuotaAvailable(PaidQuotaAvailable);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
    end;
}
