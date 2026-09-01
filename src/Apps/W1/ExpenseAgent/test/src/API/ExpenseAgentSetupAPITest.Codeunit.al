// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Agents;
using System.AI;
using System.Globalization;
using System.Privacy;
using System.TestLibraries.AI;

codeunit 148333 "Expense Agent Setup API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CopilotTestLibrary: Codeunit "Copilot Test Library";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ExpenseAgentAppIdTok: Label '66efe10c-8033-403b-a86d-77c0887178ba', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;
        ServiceNameTok: Label 'expenseAgentSetup', Locked = true;
        AgentLanguageCodeTok: Label 'agentLanguageCode', Locked = true;
        EmailAddressTok: Label 'emailAddress', Locked = true;

    [Test]
    procedure EmailAddressFieldIsExposedThroughAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
        ExpectedEmailValue: Text;
    begin
        // [SCENARIO] Service-side flows (notably the welcome notification) need
        // the inbound receipts email address that admins configure on the
        // Expense Agent Setup. Page 6942 "Expense Agent Setup API" must surface
        // it as ``emailAddress`` so the connector can pull it.
        // Issue: https://microsoft.ghe.com/bic/BC-ExpenseAgent/issues/1677
        Initialize();

        // [GIVEN] an Email Address is configured on the singleton setup record
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Email Address" := 'receipts@contoso.com';
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] the setup is fetched through the API
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Agent Setup API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] the response carries the ``emailAddress`` field with the
        //        configured value (rather than omitting it as before).
        Assert.AreNotEqual(0, StrPos(ResponseText, EmailAddressTok),
            'The Expense Agent Setup API response should include the emailAddress field.');
        ExpectedEmailValue := StrSubstNo('"%1":"%2"', EmailAddressTok, ExpenseAgentSetup."Email Address");
        Assert.AreNotEqual(0, StrPos(ResponseText, ExpectedEmailValue),
            'The emailAddress field should carry the value configured on the Expense Agent Setup record.');
    end;

    [Test]
    procedure AgentLanguageCodeIsExposedWithApplicationPermissions()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Language: Codeunit Language;
        TargetURL: Text;
        ResponseText: Text;
        ExpectedLanguageCode: Code[10];
        AgentUserSecurityID: Guid;
        LanguageID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The application can read the configured agent language through the setup API.
        Initialize();

        // [GIVEN] An Expense Agent configured with a language.
        LanguageID := 1033;
        EnableExpenseAgentCapability();
        AgentUserSecurityID := CreateAgent(LanguageID);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."User Security ID" := AgentUserSecurityID;
        ExpenseAgentSetup.Modify();
        ExpectedLanguageCode := Language.GetLanguageCode(LanguageID);
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Agent Setup API", ServiceNameTok);
        LibraryLowerPermissions.SetExactPermissionSet(ExpenseAgentPermissionSetTok);

        // [WHEN] The setup is fetched through the API with the application permission sets.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        RestoreFullPermissions();

        // [THEN] The response contains the configured agent language.
        Assert.AreNotEqual(0, StrPos(ResponseText, AgentLanguageCodeTok),
            'The Expense Agent Setup API response should include the agentLanguageCode field.');
        Assert.AreNotEqual(
            0,
            StrPos(ResponseText, StrSubstNo('"%1":"%2"', AgentLanguageCodeTok, ExpectedLanguageCode)),
            'The agentLanguageCode field should carry the language configured for the agent.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Agent Setup API Test");
        RestoreFullPermissions();
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
    end;

    local procedure CreateAgent(LanguageID: Integer): Guid
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
        AgentUserName: Code[50];
        AgentUserSecurityID: Guid;
    begin
        AgentUserName := CopyStr(Format(CreateGuid()), 1, MaxStrLen(AgentUserName));
        AgentUserSecurityID :=
            Agent.Create("Agent Metadata Provider"::"Expense Agent", AgentUserName, AgentUserName, TempAgentAccessControl);
        Agent.UpdateLocalizationSettings(AgentUserSecurityID, LanguageID, 1033, 'UTC');
        exit(AgentUserSecurityID);
    end;

    local procedure EnableExpenseAgentCapability()
    var
        ExpPrivacyNoticeReg: Codeunit "Exp. Privacy Notice Reg.";
        PrivacyNotice: Codeunit "Privacy Notice";
        ExpenseAgentAppId: Guid;
        AzureOpenAITok: Label 'Azure OpenAI', Locked = true;
    begin
        Evaluate(ExpenseAgentAppId, ExpenseAgentAppIdTok);
        CopilotTestLibrary.SetCopilotStatus(
            Enum::"Copilot Capability"::"Expense Agent", ExpenseAgentAppId, Enum::"Copilot Status"::Active);
        PrivacyNotice.SetApprovalState(AzureOpenAITok, Enum::"Privacy Notice Approval State"::Agreed);
        PrivacyNotice.SetApprovalState(
            ExpPrivacyNoticeReg.GetExpenseAgentPrivacyNoticeId(), Enum::"Privacy Notice Approval State"::Agreed);
    end;

    local procedure RestoreFullPermissions()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;
}
