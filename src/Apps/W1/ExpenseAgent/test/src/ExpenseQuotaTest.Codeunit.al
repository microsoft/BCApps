// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;

codeunit 148298 "Expense Quota Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Expense Agent Env. Consumption" = rimd;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RetryingTrialConsumptionAfterExhaustionDoesNotChargePaidQuota()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Retrying the final trial expense does not report paid consumption
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, true);
        ConsumptionSourceSystemId := CreateGuid();

        FirstConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS', 'QUOTA TEST');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'The first consumption should exhaust the trial quota.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The first consumption should be reported as trial usage.');

        SecondConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS', 'QUOTA TEST');

        Assert.AreEqual(FirstConsumptionId, SecondConsumptionId, 'The retry should return the original consumption ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(SecondConsumptionId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Is Feature Trial", 'The retry should remain classified as trial consumption.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", ConsumptionSourceSystemId);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'The retry should not create another consumption record.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The retry should use trial reporting.');
        Assert.AreEqual(FirstConsumptionId, ExpenseAgentQuotaMock.GetLastTrialConsumptionId(), 'Trial reporting should reuse the original idempotency ID.');
        Assert.AreEqual(50, ExpenseAgentQuotaMock.GetLastTrialQuota(), 'Trial reporting should use the configured trial limit.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'The retry should not consume additional trial quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidReportCount(), 'The trial retry must not report paid consumption.');
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
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 1, false);

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
        InitializeQuotaProvider(ExpenseConsumptionHandler, ExpenseAgentQuotaMock, 0, true);
        FirstPrincipalId := CreateGuid();
        SecondPrincipalId := CreateGuid();

        Assert.IsTrue(ExpenseConsumptionHandler.CanConsume(FirstPrincipalId), 'Available paid quota should permit consumption.');
        Assert.AreEqual(FirstPrincipalId, ExpenseAgentQuotaMock.GetLastPaidQuotaPrincipalId(), 'The first quota check must use the first expense user''s principal.');

        ExpenseAgentQuotaMock.SetPaidQuotaAvailable(false);
        Assert.IsFalse(ExpenseConsumptionHandler.CanConsume(SecondPrincipalId), 'Unavailable paid quota should prevent consumption.');
        Assert.AreEqual(SecondPrincipalId, ExpenseAgentQuotaMock.GetLastPaidQuotaPrincipalId(), 'The second quota check must use the second expense user''s principal.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetPaidQuotaCheckCount(), 'Each expense user must have a separate quota check.');
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
