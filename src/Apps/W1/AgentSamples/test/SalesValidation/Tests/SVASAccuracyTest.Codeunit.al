// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents.Designer.AgentSamples.SalesValidation;

using System.Agents;
using System.Agents.Designer.CustomAgent;
using System.Test.Agents.Designer.AgentSamples;
using System.TestLibraries.Agents;
using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 133740 "SV-AS Accuracy Test"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    local procedure Initialize()
    var
        AgentTestContext: Codeunit "Agent Test Context";
        SampleAgentUtilities: Codeunit "Sample Agents Utilities";
    begin
        if not Initialized then begin
            AgentTestContext.GetAgentUserSecurityID(AgentUserSecurityId);
            if IsNullGuid(AgentUserSecurityId) then
                AgentUserSecurityId := SampleAgentUtilities.EnableSampleAgent(Enum::"Custom Agent Sample"::"Sales Validation");

            SetupPerSuiteTestData();
            Initialized := true;

            Commit();
        end;

        LibraryAgent.EnsureAgentIsActive(AgentUserSecurityId);
        SVASTestLibrary.DeleteAllSalesOrders();
        ClearGlobals();
        Commit();
    end;

    [Test]
    procedure TestAccuracy()
    var
        AgentTask: Record "Agent Task";
        SVAEventHandler: Codeunit "SV-AS Event Handler";
        TurnSuccessful: Boolean;
        ErrorReason: Text;
        ContinueWithNextTurn: Boolean;
        AgentStatusErr: Label 'The agent task did not complete successfully. Task status: %1.', Comment = '%1 = task status';
    begin
        BindSubscription(SVAEventHandler);
        Initialize();

        repeat
            Clear(ErrorReason);
            SetupTurnData();

            TurnSuccessful := LibraryAgent.RunTurnAndWait(AgentUserSecurityId, AgentTask);

            if TurnSuccessful then
                TurnSuccessful := SVASTestLibrary.ValidateSalesOrdersReleased(ExpectedReleasedOrders, ExpectedNonReleasedOrders, ErrorReason)
            else
                ErrorReason := StrSubstNo(AgentStatusErr, AgentTask.Status);

            ContinueWithNextTurn := LibraryAgent.FinalizeTurn(AgentTask, TurnSuccessful, ErrorReason);
        until not ContinueWithNextTurn;

        Assert.IsTrue(TurnSuccessful, ErrorReason);
    end;

    local procedure SetupTurnData()
    var
        TurnSetup: Codeunit "Test Input Json";
        TurnSetupExists: Boolean;
    begin
        TurnSetupExists := AITTestContext.GetTurnSetup(TurnSetup);
        if not TurnSetupExists then
            exit;

        SVASTestLibrary.CreateSalesOrderTestData(TurnSetup, ExpectedReleasedOrders, ExpectedNonReleasedOrders);
    end;

    local procedure SetupPerSuiteTestData()
    var
        SuiteTestSetup: Codeunit "Test Input Json";
    begin
        if AITTestContext.IsSuiteSetupDone() then
            exit;

        SuiteTestSetup := AITTestContext.GetEvalSuiteSetupDataInput();

        SVASTestLibrary.CreateLocation(SuiteTestSetup);
        SVASTestLibrary.CreateCustomers(SuiteTestSetup);

        AITTestContext.SetEvalSuiteSetupCompleted();
    end;

    local procedure ClearGlobals()
    begin
        Clear(ExpectedReleasedOrders);
        Clear(ExpectedNonReleasedOrders);
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryAgent: Codeunit "Library - Agent";
        SVASTestLibrary: Codeunit "SV-AS Test Library";
        AITTestContext: Codeunit "AIT Test Context";
        ExpectedReleasedOrders, ExpectedNonReleasedOrders : List of [Code[20]];
        AgentUserSecurityId: Guid;
        Initialized: Boolean;
}
