codeunit 135086 "Power BI REST Tests"
{
    // PRECONDITION: Most tests will require Mock services to be started using the following enlistment command
    //   Start-AMCMockService -Configuration release -Secure
    // If you need to change any of the mock test values or logic, you have to rebuild it
    //   cd .\test\App\MockService\
    //   msbuild /t:clean
    //   msbuild /p:configuration=release
    // You might also need to rebuild some dependency
    //   cd .\test\App\MS.Nav.Test.App.Certificates\
    //   msbuild /p:configuration=release

    Subtype = Test;
    TestPermissions = Restrictive;
    EventSubscriberInstance = Manual;

    [Test]
    [Scope('OnPrem')]
    procedure GetWorkspaces_Success()
    var
        PowerBISelectionElement: Record "Power BI Selection Element";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        NullGuid: Guid;
    begin
        // [GIVEN] The user has a license and five workspaces
        Initialize();
        SubscriberPowerBIRestTests.SetMockServiceToken('MockServicePacket448');
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We retrieve the workspaces
        PowerBIWorkspaceMgt.AddSharedWorkspaces(PowerBISelectionElement);

        // [THEN] We find the 5 expected workspaces
        Assert.RecordCount(PowerBISelectionElement, 5);

        PowerBISelectionElement.Get('707926d0-016e-4fac-8be2-876956f2229b', PowerBISelectionElement.Type::Workspace);
        PowerBISelectionElement.Get('c1859e60-7554-4556-a311-9822f0960128', PowerBISelectionElement.Type::Workspace);
        PowerBISelectionElement.Get('41afaabc-aaaa-45e2-8f5e-7c35052943b9', PowerBISelectionElement.Type::Workspace);
        PowerBISelectionElement.Get('41afbabc-a25e-45e2-8f5e-7c35052943b9', PowerBISelectionElement.Type::Workspace);
        PowerBISelectionElement.Get('d4a0c957-a885-4ea6-9f79-aefb13eb34c1', PowerBISelectionElement.Type::Workspace);

        if PowerBISelectionElement.Get(NullGuid) then
            Assert.Fail('Workspace list should not contain null guid.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleWorkspaceReportSelection')]
    procedure Test_Select_Unselect()
    var
        PowerBIEmbeddedReportPart: TestPage "Power BI Embedded Report Part";
    begin
        // [GIVEN] The user has a license and five workspaces
        Initialize();
        SubscriberPowerBIRestTests.SetMockServiceToken('MockServicePacket448');
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] The user selects a couple of reports and then unselects one
        PowerBIEmbeddedReportPart.OpenEdit();

        LibraryVariableStorage.Enqueue(true); // Select
        // TODO: ideally, the following line should be PowerBIEmbeddedReportPart."Select Report".Invoke(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        PowerBIEmbeddedReportPart.SelectReportsLink.Drilldown();

        LibraryVariableStorage.Enqueue(false); // Unselect
        // TODO: ideally, the following line should be PowerBIEmbeddedReportPart."Select Report".Invoke(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        PowerBIEmbeddedReportPart.SelectReportsLink.Drilldown();

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetWorkspaces_Unauthorized_Emptylist()
    var
        PowerBISelectionElement: Record "Power BI Selection Element";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
    begin
        // [GIVEN] The user has a license
        Initialize();
        SubscriberPowerBIRestTests.SetMockServiceToken('MockServicePacket440');
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We retrieve the workspaces and get an unauthorized status code
        PowerBIWorkspaceMgt.AddSharedWorkspaces(PowerBISelectionElement);

        // [THEN] We find no workspace, but no error is thrown (for backwards compatibility)
        Assert.RecordIsEmpty(PowerBISelectionElement);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetWorkspaces_Empty_Emptylist()
    var
        PowerBISelectionElement: Record "Power BI Selection Element";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
    begin
        // [GIVEN] The user has a license
        Initialize();
        SubscriberPowerBIRestTests.SetMockServiceToken('MockServicePacket441');
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We retrieve the workspaces and get an empty list
        PowerBIWorkspaceMgt.AddSharedWorkspaces(PowerBISelectionElement);

        // [THEN] We find no workspace, but no error is thrown (for backwards compatibility)
        Assert.RecordIsEmpty(PowerBISelectionElement);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReports_MultipleWorkspaces_Success()
    var
        PowerBIWSReportSelection: Page "Power BI WS Report Selection";
        TestPowerBIWSReportSelection: TestPage "Power BI WS Report Selection";
        NullGuid: Guid;
    begin
        // [GIVEN] The user has a license and five workspaces
        Initialize();
        SubscriberPowerBIRestTests.SetMockServiceToken('MockServicePacket448');
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] We retrieve the reports for report selection
        PowerBIWSReportSelection.SetContext('irrelevant for this test');
        TestPowerBIWSReportSelection.Trap();
        PowerBIWSReportSelection.Run();

        // [THEN] We find the 6 expected reports, no error occurred even if one workspace is empty and another one unauthorized
        // Personal workspace with one report
        Assert.IsTrue(TestPowerBIWSReportSelection.First(), 'Should have found My Workspace as the first record.');
        TestPowerBIWSReportSelection.ID.AssertEquals(NullGuid);
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals(NullGuid);
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('My Workspace');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('My Workspace');
        TestPowerBIWSReportSelection.Expand(true);

        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the first report in MyWorkspace.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{6f290f66-b7ab-43a6-a80b-1e5af36b614e}');
        TestPowerBIWSReportSelection.Type.AssertEquals('Report');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals(NullGuid);
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('My Workspace');

        // Then Crocodile workspace
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the Crocodile workspace.');
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('Crocodile');
        TestPowerBIWSReportSelection.ID.AssertEquals('{41afbabc-a25e-45e2-8f5e-7c35052943b9}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{41afbabc-a25e-45e2-8f5e-7c35052943b9}'); // Necessary for sorting
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('Crocodile');
        TestPowerBIWSReportSelection.Expand(true);

        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the first report in the Crocodile workspace.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{e4e4e574-b9a8-44f4-9713-942ebd2400b1}');
        TestPowerBIWSReportSelection.Type.AssertEquals('Report');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{41afbabc-a25e-45e2-8f5e-7c35052943b9}');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('Crocodile');

        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the second report in the Crocodile workspace.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{31c74e37-d125-4b4d-9784-bebd8008e0e7}');
        TestPowerBIWSReportSelection.Type.AssertEquals('Report');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{41afbabc-a25e-45e2-8f5e-7c35052943b9}');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('Crocodile');

        // Then Elephant workspace (unauthorized)
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the Elephant workspace.');
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('Elephant');
        TestPowerBIWSReportSelection.ID.AssertEquals('{41afaabc-aaaa-45e2-8f5e-7c35052943b9}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{41afaabc-aaaa-45e2-8f5e-7c35052943b9}'); // Necessary for sorting
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('Elephant');
        TestPowerBIWSReportSelection.Expand(true);

        // Another Crocodile workspace should not cause problems (empty workspace)
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the second Crocodile workspace.');
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('Crocodile');
        TestPowerBIWSReportSelection.ID.AssertEquals('{707926d0-016e-4fac-8be2-876956f2229b}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{707926d0-016e-4fac-8be2-876956f2229b}'); // Necessary for sorting
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('Crocodile');
        TestPowerBIWSReportSelection.Expand(true);

        // Then workspace with a long name
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the workspace with a long name.');
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('A big and widely used workspace for my company, that contains a lot of amazing and useful reports, which provide invaluable insights over my business data, but most of all has a name longer than two h');
        TestPowerBIWSReportSelection.ID.AssertEquals('{c1859e60-7554-4556-a311-9822f0960128}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{c1859e60-7554-4556-a311-9822f0960128}'); // Necessary for sorting
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('A big and widely used workspace for my company, that contains a lot of amazing and useful reports, which provide invaluable insights over my business data, but most of all has a name longer than two h');
        TestPowerBIWSReportSelection.Expand(true);

        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the first report in the workspace with a long name.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{38d777f3-8e33-4ccd-b7d0-61a785ea76ad}');
        TestPowerBIWSReportSelection.Type.AssertEquals('Report');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{c1859e60-7554-4556-a311-9822f0960128}');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('A big and widely used workspace for my company, that contains a lot of amazing and useful reports, which provide invaluable insights over my business data, but most of all has a name longer than two h');

        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the second report in the workspace with a long name.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{57ac3ad5-2e7f-42c0-8659-22b06e6b165c}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{c1859e60-7554-4556-a311-9822f0960128}');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('A big and widely used workspace for my company, that contains a lot of amazing and useful reports, which provide invaluable insights over my business data, but most of all has a name longer than two h');

        // The following report appears in two workspaces. That should not really happen, but you never know, we should not fail.
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the third report in the workspace with a long name.');
        TestPowerBIWSReportSelection.ID.AssertEquals('{982d6386-4e1b-4aea-b4ae-915f201e1a7f}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{c1859e60-7554-4556-a311-9822f0960128}');
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('A big and widely used workspace for my company, that contains a lot of amazing and useful reports, which provide invaluable insights over my business data, but most of all has a name longer than two h');

        // This workspace has only a duplicate report, so it should show as empty
        Assert.IsTrue(TestPowerBIWSReportSelection.Next(), 'Should have found the last workspace (finance).');
        TestPowerBIWSReportSelection.Type.AssertEquals('Workspace');
        TestPowerBIWSReportSelection.Name.AssertEquals('MicrosoftDynamics365BusinessCentral-Finance');
        TestPowerBIWSReportSelection.ID.AssertEquals('{d4a0c957-a885-4ea6-9f79-aefb13eb34c1}');
        TestPowerBIWSReportSelection.WorkspaceID.AssertEquals('{d4a0c957-a885-4ea6-9f79-aefb13eb34c1}'); // Necessary for sorting
        TestPowerBIWSReportSelection.WorkspaceName.AssertEquals('MicrosoftDynamics365BusinessCentral-Finance');
        TestPowerBIWSReportSelection.Expand(true);

        Assert.IsFalse(TestPowerBIWSReportSelection.Next(), 'Should not have found the next record.');
    end;

    local procedure Initialize()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryVariableStorage.AssertEmpty();

        if IsInitialized then
            exit;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        PowerBIUrlMgt.SetBaseApiUrl('https://localhost:8080/');

        if not AzureADMgtSetup.Get() then begin
            AzureADMgtSetup.Init();
            AzureADMgtSetup.Insert();
        end;

        AzureADMgtSetup."Auth Flow Codeunit ID" := 0;
        AzureADMgtSetup.Modify();
        if BindSubscription(SubscriberPowerBIRestTests) then;

        Isinitialized := true;
    end;

    // Handlers

    [ModalPageHandler]
    procedure HandleWorkspaceReportSelection(var PowerBIWSReportSelection: TestPage "Power BI WS Report Selection")
    var
        AddToSelection: Boolean;
    begin
        AddToSelection := LibraryVariableStorage.DequeueBoolean();

        if AddToSelection then
            EnableReports(PowerBIWSReportSelection)
        else
            DisableFirstReport(PowerBIWSReportSelection);
    end;

    local procedure EnableReports(var PowerBIWSReportSelection: TestPage "Power BI WS Report Selection")
    begin
        PowerBIWSReportSelection.First();
        PowerBIWSReportSelection.Expand(true);

        PowerBIWSReportSelection.Next();
        Assert.IsTrue(PowerBIWSReportSelection.EnableReport.Visible() and PowerBIWSReportSelection.EnableReport.Enabled(), 'Enabling first report is not allowed.');
        Assert.IsFalse(PowerBIWSReportSelection.Enabled.AsBoolean(), 'First report is enabled.');
        PowerBIWSReportSelection.EnableReport.Invoke();

        PowerBIWSReportSelection.Next();
        PowerBIWSReportSelection.Expand(true);

        PowerBIWSReportSelection.Next();
        Assert.IsTrue(PowerBIWSReportSelection.EnableReport.Visible() and PowerBIWSReportSelection.EnableReport.Enabled(), 'Enabling second report is not allowed.');
        Assert.IsFalse(PowerBIWSReportSelection.Enabled.AsBoolean(), 'Second report is enabled.');
        PowerBIWSReportSelection.EnableReport.Invoke();

        PowerBIWSReportSelection.OK().Invoke();
    end;

    local procedure DisableFirstReport(var PowerBIWSReportSelection: TestPage "Power BI WS Report Selection")
    begin
        PowerBIWSReportSelection.First();
        PowerBIWSReportSelection.Expand(true);

        PowerBIWSReportSelection.Next();
        Assert.IsTrue(PowerBIWSReportSelection.Enabled.AsBoolean(), 'Report is not enabled.');
        PowerBIWSReportSelection.DisableReport.Invoke();

        PowerBIWSReportSelection.OK().Invoke();
    end;

    // Event subscribers and related functions

    [Scope('OnPrem')]
    procedure SetMockServiceToken(NewMockServiceToken: Text)
    begin
        MockServiceToken := NewMockServiceToken;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCache', '', false, false)]
    local procedure InjectAccessTokenCache(ResourceName: Text; var AccessToken: Text)
    begin
        if ResourceName <> 'https://api.fabric.microsoft.com' then
            Error('Unexpected resource name.');

        if MockServiceToken = '' then
            Error('Detect string is not set.');

        AccessToken := 'thistokenissecure' + MockServiceToken + 'extremelysecure';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure CheckProvider(var Result: Boolean)
    begin
        Result := true;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        SubscriberPowerBIRestTests: Codeunit "Power BI REST Tests";
        IsInitialized: Boolean;
        MockServiceToken: Text;
}