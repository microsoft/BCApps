// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;
using System.Environment.Consumption;
using System.TestLibraries.Environment;

codeunit 148299 "Expense Consumption Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Expense Agent Env. Consumption" = rimd,
                  tabledata "User AI Consumption Data" = rimd,
                  tabledata "AI Consumption Log Entry" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure ValidConsumptionJsonIsAccepted()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON with valid model and version objects is accepted
        Initialize();

        // [GIVEN] A consumption request with the Daybreak model shape
        AiConsumptionRequestJson := CreateValidConsumptionJson();

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is accepted
        Assert.IsTrue(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'The valid consumption request should be accepted.');
    end;

    [Test]
    procedure ConsumptionJsonWithoutModelIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON without a model is rejected
        Initialize();

        // [GIVEN] A consumption request without a model
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        AiConsumptionRequestJson.Remove('model');

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request without a model should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithNonObjectModelIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON with a non-object model is rejected
        Initialize();

        // [GIVEN] A consumption request with a text model
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        AiConsumptionRequestJson.Replace('model', 'claude-opus-4-7');

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request with a non-object model should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithoutVersionIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON without a version object is rejected
        Initialize();

        // [GIVEN] A consumption request without a version object
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        AiConsumptionRequestJson.Remove('v1');

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request without a version object should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithNonObjectVersionIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON with a non-object version is rejected
        Initialize();

        // [GIVEN] A consumption request with a numeric version
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        AiConsumptionRequestJson.Replace('v1', 1);

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request with a non-object version should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithoutVersionUsageIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
        VersionJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON without version usage is rejected
        Initialize();

        // [GIVEN] A consumption request without usage in the version object
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        VersionJson := AiConsumptionRequestJson.GetObject('v1');
        VersionJson.Remove('usage');

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request without version usage should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithNullVersionUsageIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
        VersionJson: JsonObject;
        NullValue: JsonValue;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON with null version usage is rejected
        Initialize();

        // [GIVEN] A consumption request with null usage in the version object
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        VersionJson := AiConsumptionRequestJson.GetObject('v1');
        NullValue.SetValueToNull();
        VersionJson.Replace('usage', NullValue);

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected without a conversion error
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request with null version usage should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithoutVersionUsageTypeIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
        VersionJson: JsonObject;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON without a version usage type is rejected
        Initialize();

        // [GIVEN] A consumption request without a usage type in the version object
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        VersionJson := AiConsumptionRequestJson.GetObject('v1');
        VersionJson.Remove('usageType');

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request without a version usage type should be rejected.');
    end;

    [Test]
    procedure ConsumptionJsonWithNullVersionUsageTypeIsRejected()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        AiConsumptionRequestJson: JsonObject;
        VersionJson: JsonObject;
        NullValue: JsonValue;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Consumption JSON with a null version usage type is rejected
        Initialize();

        // [GIVEN] A consumption request with a null usage type in the version object
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        VersionJson := AiConsumptionRequestJson.GetObject('v1');
        NullValue.SetValueToNull();
        VersionJson.Replace('usageType', NullValue);

        // [WHEN] The consumption JSON is validated
        // [THEN] The request is rejected without a conversion error
        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(AiConsumptionRequestJson), 'A consumption request with a null version usage type should be rejected.');
    end;

    [Test]
    procedure TrialQuotaIsFiftyExpenses()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The Expense Agent trial includes fifty expenses
        Initialize();

        // [WHEN] The trial quota is retrieved
        // [THEN] The quota is fifty expenses
        Assert.AreEqual(50, ExpenseConsumptionHandler.TrialQuota(), 'The Expense Agent trial quota should be fifty expenses.');
    end;

    [Test]
    procedure LogConsumptionV2WithoutExpenseUserEntraIdIsRejected()
    var
        ExpenseUser: Record "Expense User";
        ExpenseUserConsAPI: Page "Expense User Cons. API";
        AiConsumptionRequestJson: JsonObject;
        AiConsumptionRequest: Text;
        ExpenseUserEntraId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] V2 consumption without an Expense User Entra ID is rejected
        Initialize();

        // [GIVEN] Expense User "U" and a valid V2 consumption request
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUserConsAPI.SetRecord(ExpenseUser);
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        AiConsumptionRequestJson.WriteTo(AiConsumptionRequest);

        // [WHEN] Consumption is logged without an Expense User Entra ID
        asserterror ExpenseUserConsAPI.LogAIConsumptionV2(
            AiConsumptionRequest, CreateGuid(), CreateGuid(), 'Processed expense', ExpenseUserEntraId,
            Enum::"Expense Agent Cons. Source"::Expense, CreateGuid(), 'PROCESS EXPENSE');

        // [THEN] The request is rejected before consumption is logged
        Assert.ExpectedError('Expense User Entra ID must be provided.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CanConsumeWithoutStoredExpenseUserEntraIdIsRejected()
    var
        ExpenseUser: Record "Expense User";
        ExpenseUserConsAPI: Page "Expense User Cons. API";
    begin
        // [SCENARIO] Quota evaluation never falls back to the integration session when the expense user's Entra ID is missing
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Clear(ExpenseUser."Entra Id");
        ExpenseUserConsAPI.SetRecord(ExpenseUser);

        asserterror ExpenseUserConsAPI.CanConsume();

        Assert.ExpectedTestFieldError(ExpenseUser.FieldCaption("Entra Id"), '');
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure LoggingConsumptionCreatesEnvironmentConsumption()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseUser: Record "Expense User";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        ConsumptionId: Guid;
        ExpectedUniqueId: Text[1024];
        Operation: Code[50];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging consumption creates an environment consumption record
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [GIVEN] Expense User "U" and an expense source
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ConsumptionSourceSystemId := CreateGuid();
        Operation := 'TODO policy eval';

        // [WHEN] Consumption is logged
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, Operation, ExpenseUser."No.");

        // [THEN] One environment consumption record contains the source details and numeric capability ID
        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        ExpectedUniqueId := CopyStr(
            UpperCase(StrSubstNo('6968-1-%1-%2', Format(ConsumptionSourceSystemId, 0, 9), Format(Operation, 0, 9))),
            1, MaxStrLen(ExpectedUniqueId));
        VerifyEnvironmentConsumption(
            ExpenseAgentEnvConsumption, ExpectedUniqueId, ExpenseUser."No.", ConsumptionSourceSystemId, Operation);
    end;

    [Test]
    procedure LoggingSameConsumptionTwiceIsIdempotent()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseUser: Record "Expense User";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
        Operation: Code[50];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging the same consumption twice returns the existing record
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(2);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [GIVEN] Expense User "U" and a logged expense consumption
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ConsumptionSourceSystemId := CreateGuid();
        Operation := 'TODO policy eval';
        FirstConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, Operation, ExpenseUser."No.");

        // [WHEN] The same consumption is logged again
        SecondConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, Operation, ExpenseUser."No.");

        // [THEN] The existing record is returned without creating another record
        Assert.AreEqual(FirstConsumptionId, SecondConsumptionId, 'Repeated consumption should return the existing environment consumption record.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source Type", Enum::"Expense Agent Cons. Source"::Expense);
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", ConsumptionSourceSystemId);
        ExpenseAgentEnvConsumption.SetRange("Consumption Source Operation", Operation);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'Repeated consumption should create one environment consumption record.');
    end;

    [Test]
    procedure LoggingDifferentOperationsCreatesDistinctConsumptions()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseUser: Record "Expense User";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging different operations for one source creates distinct records
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(2);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [GIVEN] Expense User "U" and an expense source
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ConsumptionSourceSystemId := CreateGuid();

        // [WHEN] Two different operations are logged for the source
        FirstConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Evaluated policy', 'Evaluated policy',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'TODO policy eval', ExpenseUser."No.");
        SecondConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, ConsumptionSourceSystemId, 'PROCESS EXPENSE', ExpenseUser."No.");

        // [THEN] Two distinct environment consumption records are created
        Assert.AreNotEqual(FirstConsumptionId, SecondConsumptionId, 'Different operations should create distinct environment consumption records.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source Type", Enum::"Expense Agent Cons. Source"::Expense);
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", ConsumptionSourceSystemId);
        Assert.AreEqual(2, ExpenseAgentEnvConsumption.Count(), 'Different operations should create two environment consumption records.');
    end;

    [Test]
    procedure V2ConsumptionReportsBothPipelinesWithSharedIdentity()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        RequestJson: JsonObject;
        ModelJson: JsonObject;
        ActualUsageJson: JsonObject;
        ActualModelJson: JsonObject;
        ConsumptionId: Guid;
        SessionId: Guid;
        InteractionId: Guid;
        PrincipalId: Guid;
        ActualSessionId: Guid;
        ActualInteractionId: Guid;
        ActualPrincipalId: Guid;
        ExpectedPayload: Text;
        ActualPayload: Text;
        ActualModelPayload: Text;
        ActualDisplayName: Text;
        ActualDescription: Text;
        IsFeatureTrial: Boolean;
        Usage: Integer;
        UsageType: Enum "Copilot Quota Usage Type";
        ActionsSummary: Text[1024];
        ActionsDescription: Text;
    begin
        // [SCENARIO] V2 requests submit both pipelines with the companion row's stable identity and request context
        Initialize();
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        RequestJson := CreateValidConsumptionJson();
        ModelJson := RequestJson.GetObject('model');
        ModelJson.WriteTo(ExpectedPayload);
        SessionId := CreateGuid();
        InteractionId := CreateGuid();
        PrincipalId := CreateGuid();

        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumptionV2(RequestJson, 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, CreateGuid(), 'PROCESS EXPENSE', 'CONSUMPTION TEST',
            SessionId, InteractionId, PrincipalId, 'Expense user');

        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must be submitted once.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must be submitted once.');
        Assert.AreEqual(ExpenseAgentEnvConsumption."Consumption Unique ID", ExpenseAgentQuotaMock.GetLastV1UniqueId(), 'V1 must use the companion text key.');
        Assert.AreEqual(ConsumptionId, ExpenseAgentQuotaMock.GetLastV2ConsumptionId(), 'V2 must use the companion SystemId.');
        ExpenseAgentQuotaMock.GetLastV1Usage(Usage, UsageType, ActionsSummary, ActionsDescription);
        Assert.AreEqual(1, Usage, 'V1 must use the legacy usage amount.');
        Assert.AreEqual(Enum::"Copilot Quota Usage Type"::"Autonomous Action", UsageType, 'V1 must use the legacy usage type.');
        Assert.AreEqual('Processed expense', ActionsSummary, 'V1 must receive the actions summary.');
        Assert.AreEqual('Processed expense', ActionsDescription, 'V1 must receive the full description.');
        ExpenseAgentQuotaMock.GetLastV2Context(ActualSessionId, ActualInteractionId, ActualPayload,
            ActualPrincipalId, ActualDisplayName, ActualDescription, IsFeatureTrial);
        Assert.AreEqual(SessionId, ActualSessionId, 'V2 must receive the conversation session ID.');
        Assert.AreEqual(InteractionId, ActualInteractionId, 'V2 must receive the turn interaction ID.');
        Assert.AreEqual(PrincipalId, ActualPrincipalId, 'V2 must receive the expense user principal ID.');
        Assert.AreEqual('Expense user', ActualDisplayName, 'V2 must receive the principal display name.');
        Assert.IsTrue(ActualUsageJson.ReadFrom(ActualPayload), 'V2 must receive a JSON usage object.');
        Assert.IsTrue(ActualUsageJson.Contains('model'), 'V2 must retain the top-level model member.');
        Assert.IsFalse(ActualUsageJson.Contains('v1'), 'V2 must not receive V1 quantities.');
        ActualModelJson := ActualUsageJson.GetObject('model');
        ActualModelJson.WriteTo(ActualModelPayload);
        Assert.AreEqual(ExpectedPayload, ActualModelPayload, 'V2 must preserve all model usage dimensions.');
        Assert.AreEqual('Processed expense', ActualDescription, 'V2 must receive the full description.');
        Assert.IsFalse(IsFeatureTrial, 'Paid consumption must not be marked as a trial.');
        Assert.IsFalse(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'Paid V1 consumption must not be excluded from billing.');
    end;

    [Test]
    procedure V1ProcessReplayAfterCutoverDoesNotRecordV2()
    begin
        // [SCENARIO] A paid PROCESS recorded in V1 is not recorded again in V2 after cutover
        VerifyV1ReplayAfterCutover('PROCESS');
    end;

    [Test]
    procedure V1PolicyReplayAfterCutoverDoesNotRecordV2()
    begin
        // [SCENARIO] A paid policy evaluation recorded in V1 is not recorded again in V2 after cutover
        VerifyV1ReplayAfterCutover('PE:EVALUATE');
    end;

    [Test]
    procedure V2TrialReplayAfterExhaustionReportsBothWithoutCharging()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        SecondId: Guid;
    begin
        // [SCENARIO] Repeating the final trial consumption submits both pipelines without consuming another trial
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');
        SecondId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(FirstId, SecondId, 'Repeated requests must reuse the companion ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(FirstId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Is Feature Trial", 'The original trial classification must survive exhaustion.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must be submitted on both requests.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must be submitted on both requests.');
        Assert.IsTrue(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'Trial V1 reporting must be excluded from billing.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetPaidReportCount(), 'Trial requests must not report paid usage.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Repeated requests must not decrement the trial again.');
        Assert.AreEqual(FirstId, ExpenseAgentQuotaMock.GetLastTrialConsumptionId(), 'Trial reporting must reuse the same ID.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
    end;

    [Test]
    procedure V2PolicyEvaluationDoesNotIncrementTrial()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] Trial policy evaluations report both pipelines without consuming an expense trial
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PE:EVALUATE');

        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must receive the policy evaluation.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must receive the policy evaluation.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Policy evaluations must not increment the trial counter.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Policy evaluations must preserve trial quota.');
        Assert.IsTrue(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'Trial policy evaluations must not be billed.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
    end;

    [Test]
    procedure V2NonProcessingOperationsDoNotIncrementTrial()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] Only the exact PROCESS operation consumes an expense trial
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'MATCH');
        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PROCESS EXPENSE');
        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), '');

        Assert.AreEqual(3, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must receive all non-processing operations.');
        Assert.AreEqual(3, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must receive all non-processing operations.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Non-processing operations must not increment the trial counter.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Non-processing operations must preserve trial quota.');
        Assert.IsTrue(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'Trial non-processing operations must not be billed.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
    end;

    [Test]
    procedure V2ReportingFailurePreservesCompanionIdForReplay()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        OriginalId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] A failure after the companion commit leaves the same ID available for a repeated request
        Initialize();
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        ExpenseAgentQuotaMock.SetFailV2Reporting(true);
        SourceId := CreateGuid();

        asserterror LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS EXPENSE');
        Assert.ExpectedError('V2 consumption reporting failed.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", SourceId);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'The committed companion must survive a reporting failure.');
        ExpenseAgentEnvConsumption.FindFirst();
        OriginalId := ExpenseAgentEnvConsumption.SystemId;
        Assert.AreEqual(OriginalId, ExpenseAgentQuotaMock.GetLastV2ConsumptionId(), 'The failed attempt must have used the committed ID.');

        ExpenseAgentQuotaMock.SetFailV2Reporting(false);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS EXPENSE');

        Assert.AreEqual(OriginalId, RepeatedId, 'A repeated request must reuse the committed ID.');
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'A repeated request must not create another companion.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must be resubmitted after a failure.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must be resubmitted after a failure.');
    end;

    [Test]
    procedure V2RequestReusesLegacyCompanion()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        LegacyId: Guid;
        V2Id: Guid;
    begin
        // [SCENARIO] A V2 request for an existing legacy event keeps its original companion
        Initialize();
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        LegacyId := ExpenseConsumptionHandler.LogAIConsumption(1, Enum::"Copilot Quota Usage Type"::"Autonomous Action",
            'Processed expense', 'Processed expense', Enum::"Expense Agent Cons. Source"::Expense,
            SourceId, 'PROCESS EXPENSE', 'CONSUMPTION TEST');
        ExpenseAgentQuotaMock.SetTrialQuota(1);

        V2Id := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS EXPENSE');

        Assert.AreEqual(LegacyId, V2Id, 'V2 must reuse the legacy companion SystemId.');
        ExpenseAgentEnvConsumption.GetBySystemId(V2Id);
        Assert.IsFalse(ExpenseAgentEnvConsumption."Is Feature Trial", 'V2 must preserve the legacy paid classification.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'New trial quota must not change a paid event.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", SourceId);
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'Both pipelines must share one companion.');
    end;

    [Test]
    procedure BillingDetailsWithoutLedgerArePending()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
        DescriptionInStream: InStream;
    begin
        // [SCENARIO] A companion without a platform entry has no billing details yet
        Initialize();
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        TempUserAIConsumptionData."Copilot Credits" := 99;

        Assert.IsFalse(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'Neither ledger means pending consumption.');
        Assert.AreEqual(0, TempUserAIConsumptionData."Copilot Credits", 'Pending consumption must not retain a previous row''s credits.');
        Assert.IsFalse(TempUserAIConsumptionData."Processed For Billing", 'Pending consumption must not appear processed.');
        Assert.AreEqual(CompanyName(), TempUserAIConsumptionData."Company Name", 'Pending consumption must retain the source company.');
        Assert.IsFalse(ExpenseAgentEnvConsumption.GetBillingDescription(DescriptionInStream), 'Neither ledger means no description is available.');
    end;

    [Test]
    procedure BillingDetailsResolveV1Ledger()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        UserAIConsumptionData: Record "User AI Consumption Data";
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
        DescriptionOutStream: OutStream;
    begin
        // [SCENARIO] Existing V1 ledger details and descriptions remain available
        Initialize();
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        UserAIConsumptionData."Unique Id" := ExpenseAgentEnvConsumption."Consumption Unique ID";
        UserAIConsumptionData."Consumption DateTime" := CurrentDateTime();
        UserAIConsumptionData."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(UserAIConsumptionData."Company Name"));
        UserAIConsumptionData.Actions := 'Legacy action';
        UserAIConsumptionData."Copilot Credits" := 7;
        UserAIConsumptionData."Copilot Studio Feature" := 'AutonomousAction';
        UserAIConsumptionData."Copilot Studio Feature Quantity" := 2;
        UserAIConsumptionData."Processed For Billing" := true;
        UserAIConsumptionData.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('Legacy description');
        UserAIConsumptionData.Insert();

        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V1 details must be found by the text key.');
        Assert.AreEqual(7, TempUserAIConsumptionData."Copilot Credits", 'V1 credits must remain unchanged.');
        Assert.AreEqual('Legacy action', TempUserAIConsumptionData.Actions, 'V1 actions must remain unchanged.');
        Assert.AreEqual(2, TempUserAIConsumptionData."Copilot Studio Feature Quantity", 'V1 quantities must remain unchanged.');
        Assert.IsTrue(TempUserAIConsumptionData."Processed For Billing", 'V1 processing state must remain unchanged.');
        UserAIConsumptionData.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('Updated legacy description');
        UserAIConsumptionData.Modify();
        VerifyBillingDescription(ExpenseAgentEnvConsumption, 'Updated legacy description');
    end;

    [Test]
    procedure BillingDetailsResolveV2LedgerAndReportingState()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
        DescriptionOutStream: OutStream;
    begin
        // [SCENARIO] V2 details resolve by companion SystemId without inventing V1 feature quantities
        Initialize();
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        AIConsumptionLogEntry.SystemId := ExpenseAgentEnvConsumption.SystemId;
        AIConsumptionLogEntry."Consumption DateTime" := CurrentDateTime();
        AIConsumptionLogEntry."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AIConsumptionLogEntry."Company Name"));
        AIConsumptionLogEntry."AI Credits" := 3.5;
        AIConsumptionLogEntry."Reporting State" := Enum::"AI Consumption Reporting State"::Pending;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('Model action');
        AIConsumptionLogEntry.Insert(false, true);
        TempUserAIConsumptionData.Actions := 'Previous action';

        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V2 details must be found by SystemId.');
        Assert.AreEqual(3.5, TempUserAIConsumptionData."Copilot Credits", 'The overview must use V2 AI credits.');
        Assert.AreEqual('', TempUserAIConsumptionData.Actions, 'V2 actions must remain empty without retaining a previous row''s value.');
        Assert.IsFalse(TempUserAIConsumptionData.Description.HasValue(), 'V2 list details must not load the description.');
        Assert.AreEqual('', TempUserAIConsumptionData."Copilot Studio Feature", 'V2 must not invent a V1 feature.');
        Assert.IsFalse(TempUserAIConsumptionData."Processed For Billing", 'Pending V2 reporting is not completed.');
        VerifyBillingDescription(ExpenseAgentEnvConsumption, 'Model action');

        AIConsumptionLogEntry."Reporting State" := Enum::"AI Consumption Reporting State"::Completed;
        AIConsumptionLogEntry.Modify();
        ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData);
        Assert.IsTrue(TempUserAIConsumptionData."Processed For Billing", 'Completed V2 reporting must appear processed.');
    end;

    [Test]
    procedure BillingDetailsLoadV2DescriptionOnDemand()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
        DescriptionOutStream: OutStream;
        Description: Text;
    begin
        // [SCENARIO] V2 summaries omit description data and drilldown loads the latest full description
        Initialize();

        // [GIVEN] A V2 ledger entry with a description longer than the legacy action field
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        Description := PadStr('Model action ', MaxStrLen(TempUserAIConsumptionData.Actions) + 1, 'x');
        AIConsumptionLogEntry.SystemId := ExpenseAgentEnvConsumption.SystemId;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText(Description);
        AIConsumptionLogEntry.Insert(false, true);

        // [WHEN] The list loads the billing summary
        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V2 details must be found by SystemId.');

        // [THEN] No action prefix or description is loaded
        Assert.AreEqual('', TempUserAIConsumptionData.Actions, 'V2 actions must remain empty.');
        Assert.IsFalse(TempUserAIConsumptionData.Description.HasValue(), 'V2 list details must not load the description.');

        // [GIVEN] The description changes after the list was loaded
        Description := 'Updated ' + Description;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText(Description);
        AIConsumptionLogEntry.Modify();

        // [WHEN] [THEN] Drilldown loads the latest description without truncation
        VerifyBillingDescription(ExpenseAgentEnvConsumption, Description);
    end;

    local procedure LogV2Consumption(var ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler"; SourceId: Guid; Operation: Code[50]): Guid
    begin
        exit(ExpenseConsumptionHandler.LogAIConsumptionV2(CreateValidConsumptionJson(), 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, SourceId, Operation, 'CONSUMPTION TEST',
            CreateGuid(), CreateGuid(), CreateGuid(), 'Expense user'));
    end;

    local procedure VerifyLastV2Trial(ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock")
    var
        SessionId: Guid;
        InteractionId: Guid;
        PrincipalId: Guid;
        Payload: Text;
        DisplayName: Text;
        Description: Text;
        IsFeatureTrial: Boolean;
    begin
        ExpenseAgentQuotaMock.GetLastV2Context(SessionId, InteractionId, Payload, PrincipalId, DisplayName, Description, IsFeatureTrial);
        Assert.IsTrue(IsFeatureTrial, 'V2 must retain the original trial classification.');
    end;

    local procedure CreateBillingCompanion(var ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption")
    begin
        ExpenseAgentEnvConsumption.Init();
        ExpenseAgentEnvConsumption."Consumption Unique ID" := Format(CreateGuid());
        ExpenseAgentEnvConsumption."Source Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ExpenseAgentEnvConsumption."Source Company Name"));
        ExpenseAgentEnvConsumption.Insert();
    end;

    local procedure VerifyBillingDescription(ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption"; ExpectedDescription: Text)
    var
        DescriptionInStream: InStream;
        Description: Text;
    begin
        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDescription(DescriptionInStream), 'The billing description must be available on demand.');
        DescriptionInStream.ReadText(Description);
        Assert.AreEqual(ExpectedDescription, Description, 'The full billing description must remain available.');
    end;

    local procedure VerifyV1ReplayAfterCutover(Operation: Code[50])
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        RepeatedId: Guid;
    begin
        Initialize();
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();

        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, Operation);

        Assert.IsTrue(ExpenseAgentQuotaMock.IsConsumptionLogged(ExpenseAgentQuotaMock.GetLastV1UniqueId()), 'V1 must contain the consumption before cutover.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Consumption recorded in V1 must not be sent to V2.');

        ExpenseAgentQuotaMock.SetV1RecordingEnabled(false);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, Operation);

        Assert.AreEqual(FirstId, RepeatedId, 'A retry across cutover must reuse the companion ID.');
        Assert.AreEqual(2, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 must receive both recording attempts.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'A retry after cutover must not record completed V1 consumption in V2.');

        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), Operation);
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'New consumption after cutover must still be sent to V2.');
    end;

    local procedure Initialize()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        InstallExpenseAgentSetup: Codeunit "Install Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Consumption Test");
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InstallExpenseAgentSetup.RegisterCapability();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        ExpenseAgentEnvConsumption.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Consumption Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Consumption Test");
    end;

    local procedure CreateValidConsumptionJson() AiConsumptionRequestJson: JsonObject
    var
        ModelJson: JsonObject;
        VersionJson: JsonObject;
    begin
        ModelJson.Add('modelResolvedName', 'claude-opus-4-7');
        ModelJson.Add('inputTokenCount', 1200);
        ModelJson.Add('outputTokenCount', 600);
        ModelJson.Add('promptCacheReadTokenCount', 0);
        ModelJson.Add('promptCacheCreationTokenCount', 0);
        VersionJson.Add('usage', 1);
        VersionJson.Add('usageType', 'Autonomous Action');

        AiConsumptionRequestJson.Add('model', ModelJson);
        AiConsumptionRequestJson.Add('v1', VersionJson);
    end;

    local procedure VerifyEnvironmentConsumption(
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpectedUniqueId: Text;
        ExpenseUserNo: Code[20];
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50])
    begin
        Assert.AreEqual(ExpectedUniqueId, ExpenseAgentEnvConsumption."Consumption Unique ID", 'The consumption unique ID is incorrect.');
        Assert.AreEqual(ExpenseUserNo, ExpenseAgentEnvConsumption."Expense User No.", 'The expense user number is incorrect.');
        Assert.AreEqual(Enum::"Expense Agent Cons. Source"::Expense, ExpenseAgentEnvConsumption."Consumption Source Type", 'The consumption source type is incorrect.');
        Assert.AreEqual(ConsumptionSourceSystemId, ExpenseAgentEnvConsumption."Consumption Source System ID", 'The consumption source system ID is incorrect.');
        Assert.AreEqual(Operation, ExpenseAgentEnvConsumption."Consumption Source Operation", 'The consumption source operation is incorrect.');
    end;
}
