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

    trigger OnRun()
    begin
        LibraryGraphMgt.BindAuthentication();
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseCapabilities', Locked = true;
        ProjectsEnabledTok: Label '"capabilityname":"projects","isenabled":true', Locked = true;
        ProjectsDisabledTok: Label '"capabilityname":"projects","isenabled":false', Locked = true;
        ConsolidatedProjectsEnabledTok: Label '"capabilityname":"consolidatedprojects","isenabled":true', Locked = true;

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
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] The expenseCapabilities collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := StripWhitespace(LowerCase(ResponseText));

        // [THEN] The 'projects' row is present with isEnabled = true.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsEnabledTok),
            'Projects row must be reported as isEnabled = true when Enable Project Fields is true.');
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

        // [THEN] The 'projects' row is present with isEnabled = false.
        Assert.AreNotEqual(0, StrPos(ResponseText, ProjectsDisabledTok),
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
        ExpenseAgentSetup.Modify();
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Capabilities API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := StripWhitespace(LowerCase(ResponseText));

        // [THEN] The 'consolidatedProjects' row is present with isEnabled = true.
        Assert.AreNotEqual(0, StrPos(ResponseText, ConsolidatedProjectsEnabledTok),
            'Consolidated projects row must be reported as isEnabled = true when project fields are enabled.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Capabilities API Test");
        if IsInitialized then
            exit;

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
