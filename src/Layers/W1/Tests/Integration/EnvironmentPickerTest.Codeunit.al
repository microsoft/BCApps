// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132677 "Environment Picker Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    var
        LibraryAssert: Codeunit "Library Assert";
        FlowServiceManagement: Codeunit "Flow Service Management";
        EnvironmentIdTxt: Label 'environment-id', Locked = true;
        EnvironmentNameTxt: Label 'environment name', Locked = true;
        MockEnvironmentLookupErr: Label 'The linked Power Platform environment lookup failed.', Locked = true;
        MockLinkedEnvironmentId: Text;
        MockLinkedEnvironmentLookup: Boolean;
        FailLinkedEnvironmentLookup: Boolean;
        ReturnEmptyEnvironmentResponse: Boolean;

    [Test]
    procedure CheckTheBasicBehaviour()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Check if environment does not exist
        LibraryAssert.isFalse(FlowServiceManagement.HasUserSelectedFlowEnvironment(), 'There are some flows assigned to this user');

        // [GIVEN] Add some environment 
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure AdminCanSetForAll()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [WHEN] Admin sets the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure CheckAdminCanOverrideForAll()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Add some environment as a user
        TempFlowUserEnvironmentBuffer."Environment ID" := 'user-choice-id';
        TempFlowUserEnvironmentBuffer."Environment Display Name" := 'user-choice-name';
        TempFlowUserEnvironmentBuffer."Linked" := false;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] Admin overrides the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure CheckUserCanOverrideDefaultChoice()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Add some environment as an admin
        TempFlowUserEnvironmentBuffer."Environment ID" := 'default-choice-id';
        TempFlowUserEnvironmentBuffer."Environment Display Name" := 'default-choice-name';
        TempFlowUserEnvironmentBuffer."Linked" := true;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [WHEN] User overrides the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');
    end;

    [Test]
    procedure CheckUserCanUseLinked()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [SETUP] A new setup company in Saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [START] Add some environment as an admin
        TempFlowUserEnvironmentBuffer."Environment ID" := 'default-choice-id';
        TempFlowUserEnvironmentBuffer."Environment Display Name" := 'default-choice-name';
        TempFlowUserEnvironmentBuffer."Linked" := false;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [WHEN] User overrides the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] User wants to use linked environment
        FlowServiceManagement.UseLinkedEnvironment();

        // [THEN] The environment is set correctly, check returned values. Please note due to the test setup we return '' for linked environment
        LibraryAssert.AreEqual('', FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual('', FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');
    end;

    [Test]
    procedure LinkedEnvironmentLookupFailureDoesNotSurface()
    var
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
        SystemActionTriggers: Codeunit "System Action Triggers";
        EnvironmentId: Text;
    begin
        FlowServiceManagement.UseLinkedEnvironment();
        EnvironmentPickerTest.SetLinkedEnvironmentLookupMock('', true);
        BindSubscription(EnvironmentPickerTest);

        SystemActionTriggers.GetPowerPlatformEnvironmentId('', EnvironmentId);

        LibraryAssert.AreEqual('', EnvironmentId, 'A failed linked environment lookup must not return an environment ID.');
    end;

    [Test]
    procedure NullGuidLinkedEnvironmentIsNotReturned()
    var
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
        SystemActionTriggers: Codeunit "System Action Triggers";
        EnvironmentId: Text;
    begin
        FlowServiceManagement.UseLinkedEnvironment();
        EnvironmentPickerTest.SetLinkedEnvironmentLookupMock('00000000-0000-0000-0000-000000000000', false);
        BindSubscription(EnvironmentPickerTest);

        SystemActionTriggers.GetPowerPlatformEnvironmentId('', EnvironmentId);

        LibraryAssert.AreEqual('', EnvironmentId, 'A null GUID must not be returned as the linked Power Platform environment ID.');
    end;

    [Test]
    procedure ValidLinkedEnvironmentIsReturned()
    var
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
        SystemActionTriggers: Codeunit "System Action Triggers";
        EnvironmentId: Text;
        LinkedEnvironmentId: Text;
    begin
        FlowServiceManagement.UseLinkedEnvironment();
        LinkedEnvironmentId := '47c7e399-8d3a-4ae4-88fe-b015a54641e9';
        EnvironmentPickerTest.SetLinkedEnvironmentLookupMock(LinkedEnvironmentId, false);
        BindSubscription(EnvironmentPickerTest);

        SystemActionTriggers.GetPowerPlatformEnvironmentId('', EnvironmentId);

        LibraryAssert.AreEqual(LinkedEnvironmentId, EnvironmentId, 'A valid linked Power Platform environment ID must be returned.');
    end;

    [Test]
    procedure EmptyEnvironmentResponseIsNotParsed()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
    begin
        EnvironmentPickerTest.SetEmptyEnvironmentResponse();
        BindSubscription(EnvironmentPickerTest);

        FlowServiceManagement.GetEnvironments(TempFlowUserEnvironmentBuffer);

        LibraryAssert.IsTrue(TempFlowUserEnvironmentBuffer.IsEmpty(), 'An empty response must result in an empty environment buffer.');
    end;

    [Test]
    [HandlerFunctions('HandleSessionSettingsChange')]
    procedure AcceptViaAssistedSetup()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
        AutomateEnvironmentPickerTestPage: TestPage "Automate Environment Picker";
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
    begin
        // [START] Add some environment as a user
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        TempFlowUserEnvironmentBuffer."Linked" := false;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] Open an assisted setup and accept from UI
        AutomateEnvironmentPickerTestPage.Trap();
        page.Run(page::"Automate Environment Picker", TempFlowUserEnvironmentBuffer);
        BindSubscription(EnvironmentPickerTest);
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.ActionChooseForMe.Invoke();
        AutomateEnvironmentPickerTestPage.ActionDone.Invoke();

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');
    end;

    [Test]
    [HandlerFunctions('HandleSessionSettingsChange')]
    procedure AcceptViaAssistedSetupWithLinkedEnvironment()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
        AutomateEnvironmentPickerTestPage: TestPage "Automate Environment Picker";
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SETUP] A new setup company in Saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [START] Add some environment as a user
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        TempFlowUserEnvironmentBuffer."Linked" := true;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] Open an assisted setup and accept from UI
        AutomateEnvironmentPickerTestPage.Trap();
        page.Run(page::"Automate Environment Picker", TempFlowUserEnvironmentBuffer);
        BindSubscription(EnvironmentPickerTest);
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.ActionDecideEnvironment.Invoke();
        AutomateEnvironmentPickerTestPage.ActionChooseForMe.Invoke();
        AutomateEnvironmentPickerTestPage.ActionDone.Invoke();

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');
    end;

    [Test]
    [HandlerFunctions('HandleSessionSettingsChange')]
    procedure AcceptLinkedEnvironmentViaAssistedSetup()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
        AutomateEnvironmentPickerTestPage: TestPage "Automate Environment Picker";
        EnvironmentPickerTest: Codeunit "Environment Picker Test";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SETUP] A new setup company in Saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [START] Add some environment as a user
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        TempFlowUserEnvironmentBuffer."Linked" := true;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] Open an assisted setup and accept from UI
        AutomateEnvironmentPickerTestPage.Trap();
        page.Run(page::"Automate Environment Picker", TempFlowUserEnvironmentBuffer);
        BindSubscription(EnvironmentPickerTest);
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.ActionNext.Invoke();
        AutomateEnvironmentPickerTestPage.UseLinkedEnvironment.SetValue(1);
        AutomateEnvironmentPickerTestPage.ActionDecideEnvironment.Invoke();
        AutomateEnvironmentPickerTestPage.ActionDone.Invoke();

        // [THEN] The environment is set correctly, check returned values. Please note due to the test setup we return '' for linked environment
        LibraryAssert.AreEqual('', FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual('', FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');
    end;

    [SessionSettingsHandler]
    procedure HandleSessionSettingsChange(var ChangedSessionSettings: SessionSettings): Boolean
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Flow Service Management", OnBeforeSendGetEnvironmentRequest, '', false, false)]
    local procedure OnBeforeSendGetEnvironmentRequest(var ResponseText: Text; var Handled: Boolean)
    begin
        if ReturnEmptyEnvironmentResponse then begin
            Handled := true;
            exit;
        end;

        ResponseText := '{"value":[{"location":"unitedstates","name":"environment-id","properties":{"displayName":"environment name","createdTime":"2022-07-13T11:45:41.6980238Z","createdBy":{"id":"SYSTEM","displayName":"SYSTEM","type":"NotSpecified"},"provisioningState":"Succeeded","environmentSku":"Default","isDefault":"false","clientUris":{"admin":"https://admin.powerplatform.microsoft.com/environments/environment/environment-id/hub","maker":"https://make.powerapps.com/environments/environment-id/home"},"retentionPeriod":"P7D","states":{"management":{"id":"Ready"},"runtime":{"id":"Enabled"}},"protectionStatus":{"keyManagedBy":"Microsoft"},"connectedGroups":[],"lifecycleOperationsEnforcement":{"allowedOperations":[{"type":{"id":"Edit"}},{"type":{"id":"Provision"}},{"type":{"id":"Enable"}},{"type":{"id":"Disable"}},{"type":{"id":"DisableGovernanceConfiguration"}}],"disallowedOperations":[{"type":{"id":"Backup"},"reason":{"message":"Backup cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Copy"},"reason":{"message":"Copy cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Promote"},"reason":{"message":"Promote cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Reset"},"reason":{"message":"Reset cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Restore"},"reason":{"message":"Restore cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Unlock"},"reason":{"message":"Unlock cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"UpdateProtectionStatus"},"reason":{"message":"UpdateProtectionStatus cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"EnableGovernanceConfiguration"},"reason":{"message":"EnableGovernanceConfiguration cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"UpdateGovernanceConfiguration"},"reason":{"message":"UpdateGovernanceConfiguration cannot be performed because there is no linked CDS instance or the CDS instance version is not supported."}},{"type":{"id":"Convert"},"reason":{"message":"Convert cannot be performed on environment of type Default."}},{"type":{"id":"Delete"},"reason":{"message":"Delete cannot be performed on environment of type Default."}},{"type":{"id":"Recover"},"reason":{"message":"Recover cannot be performed on environment of type Default."}},{"type":{"id":"NewCustomerManagedKey"},"reason":{"message":"NewCustomerManagedKey cannot be performed on environment of type Default."}},{"type":{"id":"RotateCustomerManagedKey"},"reason":{"message":"RotateCustomerManagedKey cannot be performed on environment of type Default."}},{"type":{"id":"RevertToMicrosoftKey"},"reason":{"message":"RevertToMicrosoftKey cannot be performed on environment of type Default."}},{"type":{"id":"NewNetworkInjection"},"reason":{"message":"NewNetworkInjection cannot be performed on environment of type Default."}},{"type":{"id":"SwapNetworkInjection"},"reason":{"message":"SwapNetworkInjection cannot be performed on environment of type Default."}},{"type":{"id":"RevertNetworkInjection"},"reason":{"message":"RevertNetworkInjection cannot be performed on environment of type Default."}},{"type":{"id":"NewIdentity"},"reason":{"message":"NewIdentity cannot be performed on environment of type Default."}},{"type":{"id":"SwapIdentity"},"reason":{"message":"SwapIdentity cannot be performed on environment of type Default."}},{"type":{"id":"RevertIdentity"},"reason":{"message":"RevertIdentity cannot be performed on environment of type Default."}}]},"governanceConfiguration":{"protectionLevel":"Basic"}}}]}';
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Flow Service Management", OnBeforeGetLinkedPowerPlatformEnvironmentId, '', false, false)]
    local procedure OnBeforeGetLinkedPowerPlatformEnvironmentId(var LinkedEnvironmentId: Text; var Handled: Boolean)
    begin
        if not MockLinkedEnvironmentLookup then
            exit;

        Handled := true;
        if FailLinkedEnvironmentLookup then
            Error(MockEnvironmentLookupErr);

        LinkedEnvironmentId := MockLinkedEnvironmentId;
    end;

    procedure SetLinkedEnvironmentLookupMock(LinkedEnvironmentId: Text; FailLookup: Boolean)
    begin
        MockLinkedEnvironmentId := LinkedEnvironmentId;
        FailLinkedEnvironmentLookup := FailLookup;
        MockLinkedEnvironmentLookup := true;
    end;

    procedure SetEmptyEnvironmentResponse()
    begin
        ReturnEmptyEnvironmentResponse := true;
    end;
}
