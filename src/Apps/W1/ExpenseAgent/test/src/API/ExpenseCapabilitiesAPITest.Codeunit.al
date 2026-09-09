// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148318 "Expense Capabilities API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpenseAgent: Codeunit "Library - Expense Agent";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseCapabilities', Locked = true;
        ActivityLogCapabilityNameTok: Label 'activityLog', Locked = true;
        ApprovalConversationCapabilityNameTok: Label 'approvalConversation', Locked = true;

    [Test]
    procedure CapabilitiesProjectsEnabledViaAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] When Expense Agent Setup has "Enable Project Fields" = true,
        //            the capabilities API exposes a 'projects' row with isEnabled = true.
        Initialize();
        LibraryExpenseAgent.BackupExpenseAgentSetup();

        // [GIVEN] Expense Agent Setup exists with Enable Project Fields = true.
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := true;
        ExpenseAgentSetup."Allow VAT Reclaim" := true;
        ExpenseAgentSetup."Evaluate Policies" := true;
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The Projects capability is enabled, regardless of other capability states.
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, 'projects', true),
            'Response must contain an enabled projects capability row.');
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        Commit();
    end;

    [Test]
    procedure ActivityLogCapabilityEnabledViaAPI()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The Activity Log capability is always advertised when the API is installed.
        Initialize();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] ActivityLog is present and enabled.
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, ActivityLogCapabilityNameTok, true),
            'Response must contain an enabled activityLog capability row.');
    end;

    [Test]
    procedure ApprovalConversationCapabilityEnabledViaAPI()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Approval conversation is advertised when the supporting API actions are installed.
        Initialize();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] ApprovalConversation is present and enabled.
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, ApprovalConversationCapabilityNameTok, true),
            'Response must contain an enabled approvalConversation capability row.');
    end;

    [Test]
    procedure CapabilitiesProjectsDisabledViaAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] When Expense Agent Setup has "Enable Project Fields" = false,
        //            the capabilities API exposes a 'projects' row with isEnabled = false.
        Initialize();
        LibraryExpenseAgent.BackupExpenseAgentSetup();

        // [GIVEN] Expense Agent Setup exists with Enable Project Fields = false.
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := false;
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The Projects capability is disabled.
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, 'projects', false),
            'Response must contain a disabled projects capability row.');
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        Commit();
    end;

    [Test]
    procedure CapabilitiesConsolidatedProjectsFollowsProjectFieldsViaAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The 'consolidatedAssignedProjects' capability is reported enabled when
        //            project fields are enabled (the web app uses it to detect the new endpoint).
        Initialize();
        LibraryExpenseAgent.BackupExpenseAgentSetup();

        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := true;
        ExpenseAgentSetup."Allow VAT Reclaim" := true;
        // Enable Evaluate Policies too so the aiAssistedPolicyEvaluation capability is not reported
        // disabled, keeping the "no capability disabled" assertion below valid.
        ExpenseAgentSetup."Evaluate Policies" := true;
        ExpenseAgentSetup.Modify();
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Consolidated Projects is enabled, regardless of other capability states.
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, 'consolidatedProjects', true),
            'Response must contain an enabled consolidatedProjects capability row.');
        Assert.IsTrue(
            ResponseContainsCapabilityState(ResponseText, 'aiAssistedPolicyEvaluation', true),
            'Response must contain an enabled aiAssistedPolicyEvaluation capability row.');
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        Commit();
    end;

    [Test]
    procedure CapabilitiesPolicyEvaluationEnabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCapabilitiesProvider: Codeunit "Expense Capabilities Provider";
    begin
        // [SCENARIO] When Expense Agent Setup has "Evaluate Policies" = true,
        //            the aiAssistedPolicyEvaluation capability is reported enabled.
        // The web-service serialization of this row is covered by
        // CapabilitiesConsolidatedProjectsFollowsProjectFieldsViaAPI; this test targets the
        // derivation directly to keep the codeunit's web-service round-trips within the
        // container auth limit (see ExpenseProjectsAPITest for the same provider-level pattern).
        Initialize();

        // [GIVEN] Expense Agent Setup exists with Evaluate Policies = true.
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Evaluate Policies" := true;
        ExpenseAgentSetup.Modify();

        // [THEN] The provider reports aiAssistedPolicyEvaluation as enabled.
        Assert.IsTrue(ExpenseCapabilitiesProvider.IsEnabled(Enum::"Expense Capability"::AiAssistedPolicyEvaluation),
            'aiAssistedPolicyEvaluation must be enabled when Evaluate Policies is true.');
    end;

    [Test]
    procedure CapabilitiesPolicyEvaluationDisabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCapabilitiesProvider: Codeunit "Expense Capabilities Provider";
    begin
        // [SCENARIO] When Expense Agent Setup has "Evaluate Policies" = false,
        //            the aiAssistedPolicyEvaluation capability is reported disabled.
        Initialize();

        // [GIVEN] Expense Agent Setup exists with Evaluate Policies = false.
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Evaluate Policies" := false;
        ExpenseAgentSetup.Modify();

        // [THEN] The provider reports aiAssistedPolicyEvaluation as disabled.
        Assert.IsFalse(ExpenseCapabilitiesProvider.IsEnabled(Enum::"Expense Capability"::AiAssistedPolicyEvaluation),
            'aiAssistedPolicyEvaluation must be disabled when Evaluate Policies is false.');
    end;

    local procedure Initialize()
    begin
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        Commit();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Capabilities API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Capabilities API Test");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Capabilities API Test");
    end;

    local procedure ResponseContainsCapabilityState(
        ResponseText: Text;
        CapabilityName: Text;
        ExpectedEnabled: Boolean
    ): Boolean
    var
        RootObject: JsonObject;
        CapabilityObject: JsonObject;
        ValueArray: JsonArray;
        CapabilityToken: JsonToken;
        PropertyToken: JsonToken;
        CapabilityIndex: Integer;
    begin
        RootObject.ReadFrom(ResponseText);
        if not RootObject.Get('value', PropertyToken) then
            exit(false);

        ValueArray := PropertyToken.AsArray();
        if ValueArray.Count() = 0 then
            exit(false);
        for CapabilityIndex := 0 to ValueArray.Count() - 1 do begin
            Clear(CapabilityToken);
            Clear(CapabilityObject);
            ValueArray.Get(CapabilityIndex, CapabilityToken);
            CapabilityObject := CapabilityToken.AsObject();
            Clear(PropertyToken);
            if CapabilityObject.Get('capabilityName', PropertyToken) then
                if LowerCase(PropertyToken.AsValue().AsText()) = LowerCase(CapabilityName) then begin
                    Clear(PropertyToken);
                    if not CapabilityObject.Get('isEnabled', PropertyToken) then
                        exit(false);
                    exit(PropertyToken.AsValue().AsBoolean() = ExpectedEnabled);
                end;
        end;

        exit(false);
    end;

}
