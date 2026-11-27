// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;
using System.Environment.Consumption;
using System.TestLibraries.Environment;

// [FEATURE] [Expense Agent] [Consumption]
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
    procedure CanConsumeV2WithoutSuppliedExpenseUserEntraIdIsRejected()
    var
        ExpenseUser: Record "Expense User";
        ExpenseUserConsAPI: Page "Expense User Cons. API";
        ExpenseUserEntraId: Guid;
    begin
        // [SCENARIO] V2 quota evaluation requires a supplied Entra ID even when a stored ID exists
        Initialize();

        // [GIVEN] An expense user with a stored Entra ID
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser."Entra Id" := CreateGuid();
        ExpenseUserConsAPI.SetRecord(ExpenseUser);

        // [WHEN] The bound action checks consumption quota without a supplied Entra ID
        asserterror ExpenseUserConsAPI.CanConsumeV2(ExpenseUserEntraId);

        // [THEN] The missing supplied Entra ID is rejected without using the stored ID
        Assert.ExpectedError('Expense User Entra ID must be provided.');
        Assert.ExpectedErrorCode('Dialog');
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
    procedure V2ConsumptionReportsOnlyActivePipelineWithRequestContext()
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
    begin
        // [SCENARIO] V2 requests submit only the active V2 pipeline with stable identity and request context
        Initialize();

        // [GIVEN] A paid consumption request with model usage and explicit session and principal identities
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        RequestJson := CreateValidConsumptionJson();
        ModelJson := RequestJson.GetObject('model');
        ModelJson.WriteTo(ExpectedPayload);
        SessionId := CreateGuid();
        InteractionId := CreateGuid();
        PrincipalId := CreateGuid();

        // [WHEN] The request is reported
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumptionV2(RequestJson, 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, CreateGuid(), 'PROCESS EXPENSE', 'CONSUMPTION TEST',
            SessionId, InteractionId, PrincipalId, 'Expense user');

        // [THEN] Only V2 receives the companion identity and the model usage payload
        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The inactive V1 pipeline must not be called.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must be submitted once.');
        Assert.AreEqual(ConsumptionId, ExpenseAgentQuotaMock.GetLastV2ConsumptionId(), 'V2 must use the companion SystemId.');
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
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'Confirmed V2 consumption must be marked complete.');
    end;

    [Test]
    procedure V1ProcessReplayAfterCutoverDoesNotRecordV2()
    begin
        // [SCENARIO] A paid PROCESS recorded in V1 is not recorded again in V2 after cutover
        // [GIVEN] A paid PROCESS event is recorded before cutover
        // [WHEN] The event is retried after cutover
        // [THEN] V2 records only new consumption, not the completed V1 event
        VerifyV1ReplayAfterCutover('PROCESS');
    end;

    [Test]
    procedure V1PolicyReplayAfterCutoverDoesNotRecordV2()
    begin
        // [SCENARIO] A paid policy evaluation recorded in V1 is not recorded again in V2 after cutover
        // [GIVEN] A paid policy evaluation is recorded before cutover
        // [WHEN] The event is retried after cutover
        // [THEN] V2 records only new consumption, not the completed V1 event
        VerifyV1ReplayAfterCutover('PE:EVALUATE');
    end;

    [Test]
    procedure V2ProcessWithZeroV1UsageConsumesTrial()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        AiConsumptionRequestJson: JsonObject;
        V1Json: JsonObject;
        ConsumptionId: Guid;
    begin
        // [SCENARIO] Recorded V2 PROCESS consumption decrements trial quota even when V1 usage is zero
        Initialize();

        // [GIVEN] One trial expense remains and the request has zero V1 usage
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        V1Json := AiConsumptionRequestJson.GetObject('v1');
        V1Json.Replace('usage', 0);
        AiConsumptionRequestJson.Replace('v1', V1Json);

        // [WHEN] V2 consumption is recorded for PROCESS
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumptionV2(AiConsumptionRequestJson, 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, CreateGuid(), 'PROCESS', 'CONSUMPTION TEST',
            CreateGuid(), CreateGuid(), CreateGuid(), 'Expense user');

        // [THEN] V1 is not called and the recorded V2 consumption decrements trial quota
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Zero usage must not be submitted to V1.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Model usage must still be submitted to V2.');
        Assert.IsTrue(ExpenseAgentQuotaMock.IsV2ConsumptionRecorded(ConsumptionId), 'V2 consumption must be recorded.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Recorded V2 PROCESS consumption must decrement trial quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Recorded V2 consumption must consume the remaining trial expense.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
    end;

    [Test]
    procedure V1OnlyProcessConsumesTrialWithoutBillingReport()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] An inactive V2 pipeline routes PROCESS to V1 trial counting without a billing report
        Initialize();

        // [GIVEN] Trial quota is available and V1 records the consumption
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [WHEN] PROCESS consumption is submitted
        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PROCESS');

        // [THEN] V1 only decrements the trial allowance and does not report paid consumption
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 trials must not submit normal consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'The inactive V2 pipeline must not be called.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'V1 PROCESS must decrement trial quota.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'V1 PROCESS must consume the remaining trial allowance.');
    end;

    [Test]
    procedure IgnoredV2ProcessDoesNotConsumeTrial()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        AiConsumptionRequestJson: JsonObject;
        V1Json: JsonObject;
        ConsumptionId: Guid;
    begin
        // [SCENARIO] A V2 call that does not record consumption does not decrement trial quota
        Initialize();

        // [GIVEN] Trial quota is available, V1 usage is zero, and V2 recording is inactive
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseAgentQuotaMock.SetV2RecordingEnabled(false);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        AiConsumptionRequestJson := CreateValidConsumptionJson();
        V1Json := AiConsumptionRequestJson.GetObject('v1');
        V1Json.Replace('usage', 0);
        AiConsumptionRequestJson.Replace('v1', V1Json);

        // [WHEN] PROCESS consumption is submitted to V2
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumptionV2(AiConsumptionRequestJson, 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, CreateGuid(), 'PROCESS', 'CONSUMPTION TEST',
            CreateGuid(), CreateGuid(), CreateGuid(), 'Expense user');

        // [THEN] No V2 consumption is recorded and trial quota remains unchanged
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Zero usage must not be submitted to V1.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must receive the recording attempt.');
        Assert.IsFalse(ExpenseAgentQuotaMock.IsV2ConsumptionRecorded(ConsumptionId), 'Inactive V2 recording must not create consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'An ignored V2 call must not decrement trial quota.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Unrecorded V2 consumption must preserve trial quota.');
    end;

    [Test]
    procedure FailedV2ProcessDoesNotConsumeTrial()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] Failed V2 PROCESS recording does not decrement trial quota
        Initialize();

        // [GIVEN] Trial quota is available and V2 recording fails
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseAgentQuotaMock.SetFailV2Reporting(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [WHEN] PROCESS consumption is submitted
        asserterror LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PROCESS');

        // [THEN] The failure is surfaced without decrementing trial quota
        Assert.ExpectedError('V2 consumption reporting failed.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Failed V2 recording must not decrement trial quota.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Failed V2 recording must preserve trial quota.');
    end;

    [Test]
    procedure V2TrialReplayAfterExhaustionIsNotReportedAgain()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        SecondId: Guid;
    begin
        // [SCENARIO] Repeating the final completed trial consumption does not submit consumption again
        Initialize();

        // [GIVEN] The last available trial expense has been reported
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        // [WHEN] The same consumption is reported after trial exhaustion
        SecondId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        // [THEN] Both submissions retain the original trial identity without another quota decrement
        Assert.AreEqual(FirstId, SecondId, 'Repeated requests must reuse the companion ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(FirstId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Is Feature Trial", 'The original trial classification must survive exhaustion.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The inactive V1 pipeline must not be called.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Completed V2 consumption must not be resubmitted.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Completed trial consumption must not be counted again.');
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
        // [SCENARIO] Trial policy evaluations report only V2 without consuming an expense trial
        Initialize();

        // [GIVEN] One expense remains in the feature trial
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [WHEN] A policy evaluation is reported
        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PE:EVALUATE');

        // [THEN] Only V2 receives trial usage without consuming an expense allowance
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The inactive V1 pipeline must not be called.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must receive the policy evaluation.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Policy evaluations must not increment the trial counter.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Policy evaluations must preserve trial quota.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
    end;

    [Test]
    procedure V2MatchingDoesNotIncrementTrial()
    begin
        // [SCENARIO] Matching does not consume an expense trial
        VerifyV2NonProcessingOperationDoesNotIncrementTrial('MATCH');
    end;

    [Test]
    procedure V2NonexactProcessingDoesNotIncrementTrial()
    begin
        // [SCENARIO] A nonexact processing operation does not consume an expense trial
        VerifyV2NonProcessingOperationDoesNotIncrementTrial('PROCESS EXPENSE');
    end;

    [Test]
    procedure V2BlankOperationDoesNotIncrementTrial()
    begin
        // [SCENARIO] A blank operation does not consume an expense trial
        VerifyV2NonProcessingOperationDoesNotIncrementTrial('');
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

        // [GIVEN] Reporting failed after the companion ID was committed
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

        // [WHEN] The same consumption is retried with reporting available
        ExpenseAgentQuotaMock.SetFailV2Reporting(false);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS EXPENSE');

        // [THEN] The committed ID is reused without creating another companion
        Assert.AreEqual(OriginalId, RepeatedId, 'A repeated request must reuse the committed ID.');
        Assert.AreEqual(1, ExpenseAgentEnvConsumption.Count(), 'A repeated request must not create another companion.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V2 failures must not fall back to V1.');
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

        // [GIVEN] A paid legacy companion exists before new trial quota becomes available
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        LegacyId := ExpenseConsumptionHandler.LogAIConsumption(1, Enum::"Copilot Quota Usage Type"::"Autonomous Action",
            'Processed expense', 'Processed expense', Enum::"Expense Agent Cons. Source"::Expense,
            SourceId, 'PROCESS EXPENSE', 'CONSUMPTION TEST');
        ExpenseAgentQuotaMock.SetTrialQuota(1);

        // [WHEN] V2 reports the same consumption
        V2Id := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS EXPENSE');

        // [THEN] The existing companion and its paid classification are preserved
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
    begin
        // [SCENARIO] A companion without a platform entry has no billing details yet
        Initialize();

        // [GIVEN] Neither ledger contains the companion and the display buffer has previous credits
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        TempUserAIConsumptionData."Copilot Credits" := 99;

        // [WHEN] Billing details are requested
        Assert.IsFalse(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'Neither ledger means pending consumption.');

        // [THEN] The pending summary clears previous values and has no description
        Assert.AreEqual(0, TempUserAIConsumptionData."Copilot Credits", 'Pending consumption must not retain a previous row''s credits.');
        Assert.IsFalse(TempUserAIConsumptionData."Processed For Billing", 'Pending consumption must not appear processed.');
        Assert.AreEqual(CompanyName(), TempUserAIConsumptionData."Company Name", 'Pending consumption must retain the source company.');
        Assert.AreEqual('', ExpenseAgentEnvConsumption.GetBillingDescription(), 'Neither ledger means no description is available.');
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

        // [GIVEN] The companion has a completed V1 ledger entry
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
        Clear(DescriptionOutStream);
        UserAIConsumptionData.Insert();
        VerifyStoredV1BillingDescription(UserAIConsumptionData.SystemId, 'Legacy description');

        // [WHEN] The list requests billing details
        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V1 details must be found by the text key.');

        // [THEN] The V1 summary retains its existing values
        Assert.AreEqual(7, TempUserAIConsumptionData."Copilot Credits", 'V1 credits must remain unchanged.');
        Assert.AreEqual('Legacy action', TempUserAIConsumptionData.Actions, 'V1 actions must remain unchanged.');
        Assert.AreEqual(2, TempUserAIConsumptionData."Copilot Studio Feature Quantity", 'V1 quantities must remain unchanged.');
        Assert.IsTrue(TempUserAIConsumptionData."Processed For Billing", 'V1 processing state must remain unchanged.');

        // [GIVEN] The description changes after the summary is loaded
        UserAIConsumptionData.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('Updated legacy description');
        Clear(DescriptionOutStream);
        UserAIConsumptionData.Modify();
        VerifyStoredV1BillingDescription(UserAIConsumptionData.SystemId, 'Updated legacy description');

        // [WHEN] [THEN] Drilldown loads the updated description
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

        // [GIVEN] The companion has a pending V2 ledger entry and the buffer has previous action text
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        AIConsumptionLogEntry.SystemId := ExpenseAgentEnvConsumption.SystemId;
        AIConsumptionLogEntry."Consumption DateTime" := CurrentDateTime();
        AIConsumptionLogEntry."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AIConsumptionLogEntry."Company Name"));
        AIConsumptionLogEntry."AI Credits" := 3.5;
        AIConsumptionLogEntry."Reporting State" := Enum::"AI Consumption Reporting State"::Pending;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('Model action');
        Clear(DescriptionOutStream);
        AIConsumptionLogEntry.Insert(false, true);
        VerifyStoredV2BillingDescription(AIConsumptionLogEntry.SystemId, 'Model action');
        TempUserAIConsumptionData.Actions := 'Previous action';

        // [WHEN] The list requests billing details
        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V2 details must be found by SystemId.');

        // [THEN] The summary uses V2 credits without loading action text or V1 feature quantities
        Assert.AreEqual(3.5, TempUserAIConsumptionData."Copilot Credits", 'The overview must use V2 AI credits.');
        Assert.AreEqual('', TempUserAIConsumptionData.Actions, 'V2 actions must remain empty without retaining a previous row''s value.');
        Assert.IsFalse(TempUserAIConsumptionData.Description.HasValue(), 'V2 list details must not load the description.');
        Assert.AreEqual('', TempUserAIConsumptionData."Copilot Studio Feature", 'V2 must not invent a V1 feature.');
        Assert.IsFalse(TempUserAIConsumptionData."Processed For Billing", 'Pending V2 reporting is not completed.');
        VerifyBillingDescription(ExpenseAgentEnvConsumption, 'Model action');

        // [GIVEN] Platform reporting completes
        AIConsumptionLogEntry."Reporting State" := Enum::"AI Consumption Reporting State"::Completed;
        AIConsumptionLogEntry.Modify();

        // [WHEN] The list refreshes the same summary
        ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData);

        // [THEN] The completed reporting state is displayed
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
        Clear(DescriptionOutStream);
        AIConsumptionLogEntry.Insert(false, true);
        VerifyStoredV2BillingDescription(AIConsumptionLogEntry.SystemId, Description);

        // [WHEN] The list loads the billing summary
        Assert.IsTrue(ExpenseAgentEnvConsumption.GetBillingDetails(TempUserAIConsumptionData), 'V2 details must be found by SystemId.');

        // [THEN] No action prefix or description is loaded
        Assert.AreEqual('', TempUserAIConsumptionData.Actions, 'V2 actions must remain empty.');
        Assert.IsFalse(TempUserAIConsumptionData.Description.HasValue(), 'V2 list details must not load the description.');

        // [GIVEN] The description changes after the list was loaded
        Description := 'Updated ' + Description;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText(Description);
        Clear(DescriptionOutStream);
        AIConsumptionLogEntry.Modify();
        VerifyStoredV2BillingDescription(AIConsumptionLogEntry.SystemId, Description);

        // [WHEN] [THEN] Drilldown loads the latest description without truncation
        VerifyBillingDescription(ExpenseAgentEnvConsumption, Description);
    end;

    [Test]
    procedure BillingDescriptionPreservesMessageLineSeparators()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
        DescriptionOutStream: OutStream;
    begin
        // [SCENARIO] Multiline billing descriptions retain the overview's message separators
        Initialize();

        // [GIVEN] A V2 description with two lines
        CreateBillingCompanion(ExpenseAgentEnvConsumption);
        AIConsumptionLogEntry.SystemId := ExpenseAgentEnvConsumption.SystemId;
        AIConsumptionLogEntry.Description.CreateOutStream(DescriptionOutStream, TextEncoding::UTF8);
        DescriptionOutStream.WriteText('First line');
        DescriptionOutStream.WriteText();
        DescriptionOutStream.WriteText('Second line');
        Clear(DescriptionOutStream);
        AIConsumptionLogEntry.Insert(false, true);

        // [WHEN] [THEN] The returned text retains message line separators
        VerifyBillingDescription(ExpenseAgentEnvConsumption, 'First line\Second line');
    end;

    [Test]
    procedure MissingExpenseDisplayNameIncludesInvalidReceipt()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        SourceCompany: Text[30];
        TaskShortName: Text[30];
        TaskLongName: Text;
    begin
        // [SCENARIO] Missing expense sources can represent deleted expenses or invalid receipts
        Initialize();

        // [GIVEN] A consumption source that does not identify an existing expense
        ExpenseAgentEnvConsumption."Consumption Source Type" := Enum::"Expense Agent Cons. Source"::Expense;
        ExpenseAgentEnvConsumption."Consumption Source System ID" := CreateGuid();
        SourceCompany := CopyStr(CompanyName(), 1, MaxStrLen(SourceCompany));

        // [WHEN] The source display name is requested
        ExpenseAgentEnvConsumption.GetTaskDisplayName(SourceCompany, TaskShortName, TaskLongName);

        // [THEN] The label includes both explanations
        Assert.AreEqual('Deleted expense or invalid receipt', TaskLongName, 'Missing expense sources must not be described only as deleted.');
        Assert.AreEqual(CopyStr(TaskLongName, 1, MaxStrLen(TaskShortName)), TaskShortName, 'The short name must retain its existing length limit.');
    end;

    [Test]
    procedure InactiveV2RoutesPaidConsumptionToV1()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        ConsumptionId: Guid;
        Usage: Integer;
        UsageType: Enum "Copilot Quota Usage Type";
        Summary: Text[1024];
        Description: Text;
    begin
        // [SCENARIO] The inactive V2 pipeline routes positive legacy usage only to V1
        Initialize();
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        ConsumptionId := LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PROCESS');

        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'Confirmed V1 reporting must complete the companion.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Only V1 must receive paid consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Inactive V2 must not receive consumption.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetPaidReportCount(), 'V1 paid consumption must be billed.');
        Assert.IsFalse(ExpenseAgentQuotaMock.GetLastV1ExcludedFromBilling(), 'Paid V1 consumption must not be excluded from billing.');
        ExpenseAgentQuotaMock.GetLastV1Usage(Usage, UsageType, Summary, Description);
        Assert.AreEqual(1, Usage, 'The V1 usage amount must be preserved.');
        Assert.AreEqual(Enum::"Copilot Quota Usage Type"::"Autonomous Action", UsageType, 'The V1 usage type must be preserved.');
        Assert.AreEqual('Processed expense', Summary, 'The V1 summary must be preserved.');
        Assert.AreEqual(Summary, Description, 'The V1 description must use the full summary.');
    end;

    [Test]
    procedure InactiveV2SkipsZeroV1UsageDespiteModelTokens()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        RequestJson: JsonObject;
        V1Json: JsonObject;
        SourceId: Guid;
        ConsumptionId: Guid;
    begin
        // [SCENARIO] Inactive V2 ignores model tokens when legacy usage is zero
        Initialize();
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        RequestJson := CreateValidConsumptionJson();
        V1Json := RequestJson.GetObject('v1');
        V1Json.Replace('usage', 0);
        RequestJson.Replace('v1', V1Json);
        SourceId := CreateGuid();

        ConsumptionId := ReportConsumptionRequest(ExpenseConsumptionHandler, RequestJson, SourceId);

        Assert.IsTrue(IsNullGuid(ConsumptionId), 'Zero V1 usage must return no consumption ID.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", SourceId);
        Assert.IsTrue(ExpenseAgentEnvConsumption.IsEmpty(), 'Skipped usage must not create a companion.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Zero usage must not be reported to V1.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Inactive V2 must not receive model usage.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Skipped usage must not consume trial allowance.');
    end;

    [Test]
    procedure ZeroV2TokensSkipPaidConsumption()
    begin
        // [SCENARIO] Zero model usage skips paid V2 consumption even with positive V1 usage
        VerifyZeroModelUsageIsSkipped(0);
    end;

    [Test]
    procedure ZeroV2TokensPreserveTrialAllowance()
    begin
        // [SCENARIO] Zero model usage skips trial V2 consumption even with positive V1 usage
        VerifyZeroModelUsageIsSkipped(1);
    end;

    [Test]
    procedure V2InputTokensAloneAreReported()
    begin
        // [SCENARIO] Positive input tokens prevent the zero-usage exit
        VerifySingleModelCounterIsReported('inputTokenCount');
    end;

    [Test]
    procedure V2OutputTokensAloneAreReported()
    begin
        // [SCENARIO] Positive output tokens prevent the zero-usage exit
        VerifySingleModelCounterIsReported('outputTokenCount');
    end;

    [Test]
    procedure V2CacheReadTokensAloneAreReported()
    begin
        // [SCENARIO] Positive cache-read tokens prevent the zero-usage exit
        VerifySingleModelCounterIsReported('promptCacheReadTokenCount');
    end;

    [Test]
    procedure V2CacheCreationTokensAloneAreReported()
    begin
        // [SCENARIO] Positive cache-creation tokens prevent the zero-usage exit
        VerifySingleModelCounterIsReported('promptCacheCreationTokenCount');
    end;

    [Test]
    procedure PendingV1ConsumptionUsesV2AfterCutover()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] A pending paid V1 event moves to V2 without becoming a trial
        Initialize();
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        ExpenseAgentQuotaMock.SetV2ConsumptionActive(true);
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(FirstId, RepeatedId, 'Cutover must retain the original consumption identity.');
        ExpenseAgentEnvConsumption.GetBySystemId(RepeatedId);
        Assert.IsFalse(ExpenseAgentEnvConsumption."Is Feature Trial", 'Cutover must preserve the original paid classification.');
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'The retry must complete in the active pipeline.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The retry must not resubmit to inactive V1.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'The pending retry must use active V2.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'New trial availability must not reclassify the event.');
    end;

    [Test]
    procedure PendingV2ConsumptionUsesV1AfterRollback()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] A pending paid V2 event uses V1 after activation is rolled back
        Initialize();
        ExpenseAgentQuotaMock.SetV2RecordingEnabled(false);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(FirstId, RepeatedId, 'A pending retry must retain its consumption ID.');
        ExpenseAgentEnvConsumption.GetBySystemId(RepeatedId);
        Assert.IsFalse(ExpenseAgentEnvConsumption."Is Feature Trial", 'The original paid classification must survive rollback.');
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'Active V1 must complete the pending event.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'The retry must not resubmit to inactive V2.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The retry must report through V1.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The retry must not consume newly available trial allowance.');
    end;

    [Test]
    procedure CompletedV1TrialIsNotRecordedAfterCutover()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] A completed counter-only V1 trial remains complete after V2 activation
        Initialize();
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        ExpenseAgentQuotaMock.SetV2ConsumptionActive(true);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(FirstId, RepeatedId, 'A completed trial must retain its identity.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The completed trial must be counted only once.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 trials must not create paid reports.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Cutover must not record a completed V1 trial again.');
    end;

    [Test]
    procedure CompletedV2TrialIsNotReportedAfterRollback()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        FirstId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] A completed V2 trial is not billed by V1 after rollback
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(FirstId, RepeatedId, 'Rollback must retain the completed trial identity.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Rollback must not count the trial again.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Completed V2 consumption must not be repeated.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Completed V2 consumption must not be billed through V1.');
    end;

    [Test]
    procedure RecordedV2TrialRetriesOnlyFailedCounterAfterRollback()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        ConsumptionId: Guid;
    begin
        // [SCENARIO] A trial-counter failure after V2 recording retries the counter without recording again
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseAgentQuotaMock.SetFailTrialReporting(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();

        asserterror LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');
        Assert.ExpectedError('Trial consumption reporting failed.');
        ExpenseAgentQuotaMock.SetFailTrialReporting(false);
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ConsumptionId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'The counter retry must complete the event.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'The existing V2 ledger entry must not be submitted again.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Rollback must not rebill existing V2 consumption.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetTrialReportCount(), 'The failed trial counter must be retried once.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'The trial allowance must be consumed once.');
    end;

    [Test]
    procedure ExistingV1LedgerPreventsV2ReplayWithoutCompletionFlag()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        SourceId: Guid;
        ConsumptionId: Guid;
        RepeatedId: Guid;
    begin
        // [SCENARIO] Preexisting V1 ledger entries prevent V2 replay even without a completion flag
        Initialize();
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();
        ConsumptionId := ExpenseConsumptionHandler.LogAIConsumption(
            1, Enum::"Copilot Quota Usage Type"::"Autonomous Action", 'Processed expense', 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, SourceId, 'PROCESS', 'CONSUMPTION TEST');
        ExpenseAgentEnvConsumption.GetBySystemId(ConsumptionId);
        ExpenseAgentEnvConsumption."Consumption Reported" := false;
        ExpenseAgentEnvConsumption.Modify();

        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, 'PROCESS');

        Assert.AreEqual(ConsumptionId, RepeatedId, 'The ledger lookup must retain the existing companion.');
        ExpenseAgentEnvConsumption.GetBySystemId(RepeatedId);
        Assert.IsTrue(ExpenseAgentEnvConsumption."Consumption Reported", 'The existing ledger must complete the companion.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The existing V1 consumption must not be submitted again.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'A historical V1 entry must not be billed through V2.');
    end;

    [Test]
    procedure V1TrialPolicyEvaluationPreservesAllowance()
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        // [SCENARIO] V1 trial policy evaluation doesn't decrement allowance or report paid consumption
        Initialize();
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), 'PE:EVALUATE');

        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Only PROCESS must consume trial allowance.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Policy evaluation must preserve trial allowance.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V1 trial operations must not report paid consumption.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Inactive V2 must not receive the operation.');
    end;

    [Test]
    procedure MissingModelTokenCountIsRejected()
    begin
        // [SCENARIO] Missing model counters are invalid rather than silently treated as zero
        VerifyInvalidModelTokenCount('inputTokenCount', '');
    end;

    [Test]
    procedure NullModelTokenCountIsRejected()
    begin
        // [SCENARIO] Null model counters are invalid rather than silently treated as zero
        VerifyInvalidModelTokenCount('outputTokenCount', 'null');
    end;

    [Test]
    procedure NonnumericModelTokenCountIsRejected()
    begin
        // [SCENARIO] Nonnumeric model counters are rejected
        VerifyInvalidModelTokenCount('promptCacheReadTokenCount', '"invalid"');
    end;

    [Test]
    procedure NegativeModelTokenCountIsRejected()
    begin
        // [SCENARIO] Negative model counters are rejected
        VerifyInvalidModelTokenCount('promptCacheCreationTokenCount', '-1');
    end;

    [Test]
    procedure FractionalModelTokenCountIsRejected()
    begin
        // [SCENARIO] Token counters must be whole numbers
        VerifyInvalidModelTokenCount('inputTokenCount', '0.5');
    end;

    local procedure VerifyInvalidModelTokenCount(FieldName: Text; ValueJson: Text)
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        RequestJson: JsonObject;
        ModelJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        RequestJson := CreateValidConsumptionJson();
        ModelJson := RequestJson.GetObject('model');
        if ValueJson = '' then
            ModelJson.Remove(FieldName)
        else begin
            Token.ReadFrom(ValueJson);
            ModelJson.Replace(FieldName, Token);
        end;
        RequestJson.Replace('model', ModelJson);

        Assert.IsFalse(ExpenseConsumptionHandler.ValidateConsumptionJson(RequestJson), 'Invalid model token counts must be rejected.');
    end;

    local procedure CreateZeroModelConsumptionJson() RequestJson: JsonObject
    var
        ModelJson: JsonObject;
    begin
        RequestJson := CreateValidConsumptionJson();
        ModelJson := RequestJson.GetObject('model');
        ModelJson.Replace('inputTokenCount', 0);
        ModelJson.Replace('outputTokenCount', 0);
        RequestJson.Replace('model', ModelJson);
    end;

    local procedure ReportConsumptionRequest(var ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler"; RequestJson: JsonObject; SourceId: Guid): Guid
    begin
        exit(ExpenseConsumptionHandler.LogAIConsumptionV2(RequestJson, 'Processed expense',
            Enum::"Expense Agent Cons. Source"::Expense, SourceId, 'PROCESS', 'CONSUMPTION TEST',
            CreateGuid(), CreateGuid(), CreateGuid(), 'Expense user'));
    end;

    local procedure VerifyZeroModelUsageIsSkipped(TrialQuota: Integer)
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        RequestJson: JsonObject;
        SourceId: Guid;
        ConsumptionId: Guid;
    begin
        Initialize();
        ExpenseAgentQuotaMock.SetTrialQuota(TrialQuota);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        RequestJson := CreateZeroModelConsumptionJson();
        Assert.IsTrue(ExpenseConsumptionHandler.ValidateConsumptionJson(RequestJson), 'Zero counters are valid input.');
        SourceId := CreateGuid();

        ConsumptionId := ReportConsumptionRequest(ExpenseConsumptionHandler, RequestJson, SourceId);

        Assert.IsTrue(IsNullGuid(ConsumptionId), 'Zero model usage must not return a consumption ID.');
        ExpenseAgentEnvConsumption.SetRange("Consumption Source System ID", SourceId);
        Assert.IsTrue(ExpenseAgentEnvConsumption.IsEmpty(), 'Zero model usage must not create a companion.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Zero V2 usage must not fall back to V1.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Zero model usage must not be reported.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Zero model usage must not consume trial allowance.');
        Assert.AreEqual(TrialQuota, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Zero model usage must preserve trial allowance.');
    end;

    local procedure VerifySingleModelCounterIsReported(FieldName: Text)
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
        RequestJson: JsonObject;
        ModelJson: JsonObject;
        V1Json: JsonObject;
    begin
        Initialize();
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        RequestJson := CreateZeroModelConsumptionJson();
        ModelJson := RequestJson.GetObject('model');
        ModelJson.Replace(FieldName, 1);
        RequestJson.Replace('model', ModelJson);
        V1Json := RequestJson.GetObject('v1');
        V1Json.Replace('usage', 0);
        RequestJson.Replace('v1', V1Json);

        ReportConsumptionRequest(ExpenseConsumptionHandler, RequestJson, CreateGuid());

        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Any positive model counter must be reported.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'V2 must not submit V1 usage.');
    end;

    local procedure VerifyV2NonProcessingOperationDoesNotIncrementTrial(Operation: Code[50])
    var
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ExpenseAgentQuotaMock: Codeunit "Expense Agent Quota Mock";
    begin
        Initialize();

        // [GIVEN] One expense remains in the feature trial
        ExpenseAgentQuotaMock.SetTrialQuota(1);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);

        // [WHEN] A non-processing operation is reported
        LogV2Consumption(ExpenseConsumptionHandler, CreateGuid(), Operation);

        // [THEN] Only V2 receives the operation without incrementing the trial counter
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV1ReportCount(), 'The inactive V1 pipeline must not be called.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV2ReportCount(), 'V2 must receive the non-processing operation.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetTrialReportCount(), 'Non-processing operations must not increment the trial counter.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetRemainingTrialQuota(), 'Non-processing operations must preserve trial quota.');
        VerifyLastV2Trial(ExpenseAgentQuotaMock);
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

    local procedure VerifyStoredV1BillingDescription(ConsumptionId: Guid; ExpectedDescription: Text)
    var
        UserAIConsumptionData: Record "User AI Consumption Data";
        DescriptionInStream: InStream;
        Description: Text;
    begin
        UserAIConsumptionData.GetBySystemId(ConsumptionId);
        UserAIConsumptionData.CalcFields(Description);
        UserAIConsumptionData.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        DescriptionInStream.ReadText(Description);
        Assert.AreEqual(ExpectedDescription, Description, 'The V1 fixture must persist the full billing description.');
    end;

    local procedure VerifyStoredV2BillingDescription(ConsumptionId: Guid; ExpectedDescription: Text)
    var
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
        DescriptionInStream: InStream;
        Description: Text;
    begin
        AIConsumptionLogEntry.GetBySystemId(ConsumptionId);
        AIConsumptionLogEntry.CalcFields(Description);
        AIConsumptionLogEntry.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        DescriptionInStream.ReadText(Description);
        Assert.AreEqual(ExpectedDescription, Description, 'The V2 fixture must persist the full billing description.');
    end;

    local procedure VerifyBillingDescription(ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption"; ExpectedDescription: Text)
    var
        Description: Text;
    begin
        Description := ExpenseAgentEnvConsumption.GetBillingDescription();
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
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(false);
        ExpenseAgentQuotaMock.SetV1RecordingEnabled(true);
        ExpenseConsumptionHandler.SetQuotaProvider(ExpenseAgentQuotaMock);
        SourceId := CreateGuid();

        FirstId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, Operation);

        Assert.IsTrue(ExpenseAgentQuotaMock.IsConsumptionLogged(ExpenseAgentQuotaMock.GetLastV1UniqueId()), 'V1 must contain the consumption before cutover.');
        Assert.AreEqual(0, ExpenseAgentQuotaMock.GetV2ReportCount(), 'Consumption recorded in V1 must not be sent to V2.');

        ExpenseAgentQuotaMock.SetV1RecordingEnabled(false);
        ExpenseAgentQuotaMock.SetV2ConsumptionActive(true);
        RepeatedId := LogV2Consumption(ExpenseConsumptionHandler, SourceId, Operation);

        Assert.AreEqual(FirstId, RepeatedId, 'A retry across cutover must reuse the companion ID.');
        Assert.AreEqual(1, ExpenseAgentQuotaMock.GetV1ReportCount(), 'Completed V1 consumption must not be resubmitted.');
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
