// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;

codeunit 148350 "Expense Consumption Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Expense Agent Env. Consumption" = rimd;

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
    procedure LoggingConsumptionCreatesEnvironmentConsumption()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseUser: Record "Expense User";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ConsumptionSourceSystemId: Guid;
        ConsumptionId: Guid;
        ExpectedUniqueId: Text[1024];
        Operation: Code[50];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging consumption creates an environment consumption record
        Initialize();

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
        ExpectedUniqueId := UpperCase(StrSubstNo('6968-1-%1-%2', Format(ConsumptionSourceSystemId, 0, 9), Format(Operation, 0, 9)));
        VerifyEnvironmentConsumption(
            ExpenseAgentEnvConsumption, ExpectedUniqueId, ExpenseUser."No.", ConsumptionSourceSystemId, Operation);
    end;

    [Test]
    procedure LoggingSameConsumptionTwiceIsIdempotent()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ExpenseUser: Record "Expense User";
        ExpenseConsumptionHandler: Codeunit "Expense Consumption Handler";
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
        Operation: Code[50];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging the same consumption twice returns the existing record
        Initialize();

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
        ConsumptionSourceSystemId: Guid;
        FirstConsumptionId: Guid;
        SecondConsumptionId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Logging different operations for one source creates distinct records
        Initialize();

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

    local procedure Initialize()
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Consumption Test");
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
        AiConsumptionRequestJson.Add('usage', 1);
        AiConsumptionRequestJson.Add('usageType', 'Autonomous Action');
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
