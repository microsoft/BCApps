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

    var
        Assert: Codeunit Assert;
        LibraryExpenseAgent: Codeunit "Library - Expense Agent";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseCapabilities', Locked = true;
        ProjectsCapabilityNameTok: Label '"capabilityname":"projects"', Locked = true;
        ConsolidatedCapabilityNameTok: Label '"capabilityname":"consolidatedprojects"', Locked = true;
        ActivityLogCapabilityNameTok: Label 'activityLog', Locked = true;
        IsEnabledTrueTok: Label '"isenabled":true', Locked = true;
        IsEnabledFalseTok: Label '"isenabled":false', Locked = true;

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
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] A 'projects' row is present with isEnabled = true.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsCapabilityNameTok),
            'Response must contain a projects capability row.');
        Assert.AreNotEqual(0, StrPos(ResponseText, IsEnabledTrueTok),
            'Response must contain at least one isEnabled=true value.');
        Assert.AreEqual(0, StrPos(ResponseText, IsEnabledFalseTok),
            'Response must NOT contain any isEnabled=false value when Projects is the only capability and it is enabled.');
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
            ResponseContainsEnabledCapability(ResponseText, ActivityLogCapabilityNameTok),
            'Response must contain an enabled activityLog capability row.');
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
        ResponseText := LowerCase(ResponseText);

        // [THEN] The 'projects' row is present and isEnabled = false.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsCapabilityNameTok),
            'Response must contain a projects capability row.');
        Assert.AreNotEqual(0, StrPos(ResponseText, IsEnabledFalseTok),
            'Projects row must be reported as isEnabled = false when Enable Project Fields is false.');
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
        ExpenseAgentSetup.Modify();
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] A 'consolidatedAssignedProjects' row is present and no isEnabled=false values exist.
        Assert.AreNotEqual(0, StrPos(ResponseText, ConsolidatedCapabilityNameTok),
            'Response must contain a consolidatedAssignedProjects capability row.');
        Assert.AreEqual(0, StrPos(ResponseText, IsEnabledFalseTok),
            'No capability must be reported disabled when project fields are enabled.');
        LibraryExpenseAgent.RestoreExpenseAgentSetup();
        Commit();
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

    local procedure ResponseContainsEnabledCapability(ResponseText: Text; CapabilityName: Text): Boolean
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
            ValueArray.Get(CapabilityIndex, CapabilityToken);
            CapabilityObject := CapabilityToken.AsObject();
            if CapabilityObject.Get('capabilityName', PropertyToken) then
                if LowerCase(PropertyToken.AsValue().AsText()) = LowerCase(CapabilityName) then begin
                    if not CapabilityObject.Get('isEnabled', PropertyToken) then
                        exit(false);
                    exit(PropertyToken.AsValue().AsBoolean());
                end;
        end;

        exit(false);
    end;

}
