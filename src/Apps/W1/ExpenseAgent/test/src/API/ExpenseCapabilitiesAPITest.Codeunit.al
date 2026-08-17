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
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseCapabilities', Locked = true;
        ProjectsCapabilityNameTok: Label '"capabilityname":"projects"', Locked = true;
        ProjectsDisabledRowTok: Label '"capabilityname":"projects","isenabled":false', Locked = true;
        ConsolidatedCapabilityNameTok: Label '"capabilityname":"consolidatedprojects"', Locked = true;
        IsEnabledTrueTok: Label '"isenabled":true', Locked = true;
        IsEnabledFalseTok: Label '"isenabled":false', Locked = true;
        PolicyEvalEnabledRowTok: Label '"capabilityname":"aiassistedpolicyevaluation","isenabled":true', Locked = true;

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
        ResponseText := StripWhitespace(LowerCase(ResponseText));

        // [THEN] A 'projects' row is present with isEnabled = true.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsCapabilityNameTok),
            'Response must contain a projects capability row.');
        Assert.AreNotEqual(0, StrPos(ResponseText, IsEnabledTrueTok),
            'Response must contain at least one isEnabled=true value.');
        Assert.AreEqual(0, StrPos(ResponseText, IsEnabledFalseTok),
            'Response must NOT contain any isEnabled=false value when every capability is enabled.');
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
        ResponseText := StripWhitespace(LowerCase(ResponseText));

        // [THEN] The 'projects' row is present and isEnabled = false.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsCapabilityNameTok),
            'Response must contain a projects capability row.');
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsDisabledRowTok),
            'Projects row must be reported as isEnabled = false when Enable Project Fields is false.');
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
        ResponseText := StripWhitespace(LowerCase(ResponseText));

        // [THEN] A 'consolidatedAssignedProjects' row is present and no isEnabled=false values exist.
        Assert.AreNotEqual(0, StrPos(ResponseText, ConsolidatedCapabilityNameTok),
            'Response must contain a consolidatedAssignedProjects capability row.');
        Assert.AreEqual(0, StrPos(ResponseText, IsEnabledFalseTok),
            'No capability must be reported disabled when project fields are enabled.');
        // [THEN] The 'aiAssistedPolicyEvaluation' row is exposed through the API with isEnabled = true.
        Assert.AreNotEqual(0, StrPos(ResponseText, PolicyEvalEnabledRowTok),
            'aiAssistedPolicyEvaluation row must be exposed through the API as isEnabled = true when Evaluate Policies is true.');
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Capabilities API Test");
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Capabilities API Test");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Capabilities API Test");
    end;

    local procedure StripWhitespace(Source: Text): Text
    var
        Result: Text;
    begin
        Result := Source;
        Result := DelChr(Result, '=', ' ');
        Result := DelChr(Result, '=', Format(10));  // LF
        Result := DelChr(Result, '=', Format(13));  // CR
        Result := DelChr(Result, '=', Format(9));   // TAB
        exit(Result);
    end;
}
