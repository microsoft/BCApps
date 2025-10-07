// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.MCP;

using System.MCP;
using System.TestLibraries.MCP;
using System.TestLibraries.Utilities;
using System.Reflection;

codeunit 130130 "MCP Config Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        Assert: Codeunit "Library Assert";
        MCPConfig: Codeunit "MCP Config";
        MCPConfigTestLibrary: Codeunit "MCP Config Test Library";

    [Test]
    procedure TestCreateConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
        Name: Text[100];
        Description: Text[250];
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration properties
        Name := CopyStr(Any.AlphabeticText(100), 1, 100);
        Description := CopyStr(Any.AlphabeticText(250), 1, 250);

        // [WHEN] Create configuration is called
        ConfigId := MCPConfig.CreateConfiguration(Name, Description);

        // [THEN] Configuration is created
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.AreEqual(Name, MCPConfiguration.Name, 'Name mismatch');
        Assert.AreEqual(Description, MCPConfiguration.Description, 'Description mismatch');
    end;

    [Test]
    procedure TestActivateConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, true, false);

        // [WHEN] Activate configuration is called
        MCPConfig.ActivateConfiguration(ConfigId, true);

        // [THEN] Configuration is activated
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsTrue(MCPConfiguration.Active, 'Configuration is not active');
    end;

    [Test]
    procedure TestDeactivateConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(true, false, true, false);

        // [WHEN] Deactivate configuration is called
        MCPConfig.ActivateConfiguration(ConfigId, false);

        // [THEN] Configuration is deactivated
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsFalse(MCPConfiguration.Active, 'Configuration is not deactivated');
    end;

    [Test]
    procedure TestEnableDynamicToolMode()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, true, false);

        // [WHEN] Enable tool search mode is called
        MCPConfig.EnableDynamicToolMode(ConfigId, true);

        // [THEN] Dynamic tool mode is enabled
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsTrue(MCPConfiguration.EnableDynamicToolMode, 'Dynamic tool mode is not enabled');
    end;

    [Test]
    procedure TestDisableDynamicToolMode()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, true, true, false);

        // [WHEN] Disable dynamic tool mode is called
        MCPConfig.EnableDynamicToolMode(ConfigId, false);

        // [THEN] Dynamic tool mode is disabled
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsFalse(MCPConfiguration.EnableDynamicToolMode, 'Dynamic tool mode is not disabled');
    end;

    [Test]
    procedure TestDisableDynamicToolModeDisablesDiscoverReadOnlyObjects()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, true, true, true);

        // [WHEN] Disable dynamic tool mode is called
        MCPConfig.EnableDynamicToolMode(ConfigId, false);

        // [THEN] Dynamic tool mode is disabled
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsFalse(MCPConfiguration.EnableDynamicToolMode, 'Dynamic tool mode is not disabled');
        Assert.IsFalse(MCPConfiguration.DiscoverReadOnlyObjects, 'Access to all read-only objects is not disabled');
    end;

    [Test]
    procedure TestEnableDiscoverReadOnlyObjects()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, true, false, false);

        // [WHEN] Enable access to all read-only objects is called
        MCPConfig.EnableDiscoverReadOnlyObjects(ConfigId, true);

        // [THEN] Access to all read-only objects is enabled
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsTrue(MCPConfiguration.DiscoverReadOnlyObjects, 'Access to all read-only objects is not enabled');
    end;

    [Test]
    procedure TestDisableDiscoverReadOnlyObjects()
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, true, false, true);

        // [WHEN] Disable access to all read-only objects is called
        MCPConfig.EnableDiscoverReadOnlyObjects(ConfigId, false);

        // [THEN] Access to all read-only objects is disabled
        MCPConfiguration.GetBySystemId(ConfigId);
        Assert.IsFalse(MCPConfiguration.DiscoverReadOnlyObjects, 'Access to all read-only objects is not disabled');
    end;

    [Test]
    procedure TestEnableDiscoverReadOnlyObjectsWithoutDynamicToolMode()
    var
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, false, false);

        // [WHEN] Enable access to all read-only objects is called
        asserterror MCPConfig.EnableDiscoverReadOnlyObjects(ConfigId, true);

        // [THEN] Error message is returned
        Assert.ExpectedError('Dynamic tool mode needs to be enabled to discover read-only objects.');
    end;

    [Test]
    procedure TestAllowProdChanges()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ConfigId: Guid;
        ToolId: Guid;
    begin
        // [GIVEN] Configuration and tool is created
        ConfigId := CreateMCPConfig(false, false, false, false);
        ToolId := CreateMCPConfigTool(ConfigId);
        Commit();

        // [WHEN] Allow create is called
        asserterror MCPConfig.AllowCreate(ToolId, true);

        // [THEN] Error message is returned
        Assert.ExpectedError('Production changes are not allowed for this MCP configuration.');

        // [GIVEN] Production changes are allowed
        MCPConfig.AllowProdChanges(ConfigId, true);

        // [WHEN] Allow create is called
        MCPConfig.AllowCreate(ToolId, true);

        // [THEN] Allow create is set to true
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsTrue(MCPConfigurationTool."Allow Create", 'Allow Create is not true');
    end;

    [Test]
    procedure TestCreateAPITool()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ConfigId: Guid;
        ToolId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, true, true, false);

        // [WHEN] Create API tool is called
        ToolId := MCPConfig.CreateAPITool(ConfigId, Page::"Mock API");

        // [THEN] API tool is created
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.AreEqual(ConfigId, MCPConfigurationTool.ID, 'ConfigId mismatch');
        Assert.AreEqual(Page::"Mock API", MCPConfigurationTool."Object Id", 'PageId mismatch');
        Assert.AreEqual(MCPConfigurationTool."Object Type"::Page, MCPConfigurationTool."Object Type", 'Object Type mismatch');
        Assert.AreEqual(MCPConfigurationTool."Allow Read", true, 'Allow Read mismatch');
        Assert.AreEqual(MCPConfigurationTool."Allow Create", false, 'Allow Create mismatch');
        Assert.AreEqual(MCPConfigurationTool."Allow Modify", false, 'Allow Modify mismatch');
        Assert.AreEqual(MCPConfigurationTool."Allow Delete", false, 'Allow Delete mismatch');
        Assert.AreEqual(MCPConfigurationTool."Allow Bound Actions", false, 'Allow Bound Actions mismatch');
    end;

    [Test]
    procedure TestCreateInvalidAPITool()
    var
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, true, false);

        // [WHEN] Create API tool is called with non API page
        asserterror MCPConfig.CreateAPITool(ConfigId, Page::"Mock Card");

        // [THEN] Error message is returned
        Assert.ExpectedError('Only API pages are supported.');
    end;

    [Test]
    procedure TestAllowRead()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ToolId: Guid;
    begin
        // [GIVEN] Configuration tool is created
        ToolId := CreateMCPConfigTool(CreateMCPConfig(false, false, true, false));

        // [WHEN] Allow Read is set to false
        MCPConfig.AllowRead(ToolId, false);

        // [THEN] Allow Read is false
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsFalse(MCPConfigurationTool."Allow Read", 'Allow Read is not false');
    end;

    [Test]
    procedure TestAllowCreate()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ToolId: Guid;
    begin
        // [GIVEN] Configuration tool is created
        ToolId := CreateMCPConfigTool(CreateMCPConfig(false, false, true, false));

        // [WHEN] Allow Create is set to true
        MCPConfig.AllowCreate(ToolId, true);

        // [THEN] Allow Create is true
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsTrue(MCPConfigurationTool."Allow Create", 'Allow Create is not true');
    end;

    [Test]
    procedure TestAllowModify()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ToolId: Guid;
    begin
        // [GIVEN] Configuration tool is created
        ToolId := CreateMCPConfigTool(CreateMCPConfig(false, false, true, false));

        // [WHEN] Allow Modify is set to true
        MCPConfig.AllowModify(ToolId, true);

        // [THEN] Allow Modify is true
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsTrue(MCPConfigurationTool."Allow Modify", 'Allow Modify is not true');
    end;

    [Test]
    procedure TestAllowDelete()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ToolId: Guid;
    begin
        // [GIVEN] Configuration tool is created
        ToolId := CreateMCPConfigTool(CreateMCPConfig(false, false, true, false));

        // [WHEN] Allow Delete is set to true
        MCPConfig.AllowDelete(ToolId, true);

        // [THEN] Allow Delete is true
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsTrue(MCPConfigurationTool."Allow Delete", 'Allow Delete is not true');
    end;

    [Test]
    procedure TestAllowBoundActions()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ToolId: Guid;
    begin
        // [GIVEN] Configuration tool is created
        ToolId := CreateMCPConfigTool(CreateMCPConfig(false, false, true, false));

        // [WHEN] Allow Bound Actions is set to true
        MCPConfig.AllowBoundActions(ToolId, true);

        // [THEN] Allow Bound Actions is true
        MCPConfigurationTool.GetBySystemId(ToolId);
        Assert.IsTrue(MCPConfigurationTool."Allow Bound Actions", 'Allow Bound Actions is not true');
    end;

    [Test]
    [HandlerFunctions('LookupAPIToolsOKHandler')]
    procedure TestLookupAPITools()
    var
        PageMetadata: Record "Page Metadata";
        Result: Boolean;
    begin
        // [GIVEN] No preselected page

        // [WHEN] Lookup API tools is called and a page is selected
        Result := MCPConfigTestLibrary.LookupAPITools(PageMetadata);

        // [THEN] Correct page is selected
        Assert.IsTrue(Result, 'Result is not true');
        PageMetadata.FindFirst();
        Assert.AreEqual(Page::"Mock API", PageMetadata.ID, 'PageId mismatch');
    end;

    [Test]
    [HandlerFunctions('AddToolsByAPIGroupOKHandler')]
    procedure TestAddToolsByAPIGroup()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, true, false);

        // [WHEN] Tools are added by API group
        MCPConfigTestLibrary.AddToolsByAPIGroup(ConfigId);

        // [THEN] Tools are added successfully
        MCPConfigurationTool.Get(ConfigId, MCPConfigurationTool."Object Type"::Page, Page::"Mock API");
        Assert.IsTrue(MCPConfigurationTool."Allow Read", 'Allow Read is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Create", 'Allow Create is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Modify", 'Allow Modify is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Delete", 'Allow Delete is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Bound Actions", 'Allow Bound Actions is not true');
    end;

    [Test]
    procedure TestAddStandardAPITools()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ConfigId: Guid;
    begin
        // [GIVEN] Configuration is created
        ConfigId := CreateMCPConfig(false, false, true, false);

        // [WHEN] Standard API tools are added
        MCPConfigTestLibrary.AddStandardAPITools(ConfigId);

        // [THEN] Standard API tools are added successfully
        MCPConfigurationTool.Get(ConfigId, MCPConfigurationTool."Object Type"::Page, Page::"Mock APIV2");
        Assert.IsTrue(MCPConfigurationTool."Allow Read", 'Allow Read is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Create", 'Allow Create is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Modify", 'Allow Modify is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Delete", 'Allow Delete is not true');
        Assert.IsFalse(MCPConfigurationTool."Allow Bound Actions", 'Allow Bound Actions is not true');
    end;

    [Test]
    procedure TestCopyConfiguration()
    var
        SourceMCPConfiguration: Record "MCP Configuration";
        NewMCPConfiguration: Record "MCP Configuration";
        SourceMCPConfigurationTool: Record "MCP Configuration Tool";
        NewMCPConfigurationTool: Record "MCP Configuration Tool";
        SourceConfigId: Guid;
        SourceConfigToolId: Guid;
        NewConfigId: Guid;
    begin
        // [GIVEN] Source configuration and tool are created
        SourceConfigId := CreateMCPConfig(true, true, true, false);
        SourceConfigToolId := CreateMCPConfigTool(SourceConfigId);

        // [WHEN] Configuration is copied
        SourceMCPConfiguration.GetBySystemId(SourceConfigId);
        SourceMCPConfigurationTool.GetBySystemId(SourceConfigToolId);
        NewConfigId := MCPConfig.CopyConfiguration(SourceConfigId, CopyStr('Copy of ' + SourceMCPConfiguration.Name, 1, 100), CopyStr('Copy of ' + SourceMCPConfiguration.Description, 1, 250));

        // [THEN] New configuration is created with the same properties and tools
        NewMCPConfiguration.GetBySystemId(NewConfigId);
        Assert.AreEqual(NewMCPConfiguration.Name, 'Copy of ' + SourceMCPConfiguration.Name, 'Name mismatch');
        Assert.AreEqual(NewMCPConfiguration.Description, 'Copy of ' + SourceMCPConfiguration.Description, 'Description mismatch');
        Assert.AreEqual(NewMCPConfiguration.Active, SourceMCPConfiguration.Active, 'Active is not true');
        Assert.AreEqual(NewMCPConfiguration.EnableDynamicToolMode, SourceMCPConfiguration.EnableDynamicToolMode, 'EnableDynamicToolMode is not true');
        Assert.AreEqual(NewMCPConfiguration.AllowProdChanges, SourceMCPConfiguration.AllowProdChanges, 'AllowProdChanges is not true');

        NewMCPConfigurationTool.SetRange(ID, NewConfigId);
        NewMCPConfigurationTool.FindFirst();
        Assert.AreEqual(NewMCPConfigurationTool."Object Id", SourceMCPConfigurationTool."Object Id", 'Object Id mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Object Type", SourceMCPConfigurationTool."Object Type", 'Object Type mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Allow Read", SourceMCPConfigurationTool."Allow Read", 'Allow Read mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Allow Create", SourceMCPConfigurationTool."Allow Create", 'Allow Create mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Allow Modify", SourceMCPConfigurationTool."Allow Modify", 'Allow Modify mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Allow Delete", SourceMCPConfigurationTool."Allow Delete", 'Allow Delete mismatch');
        Assert.AreEqual(NewMCPConfigurationTool."Allow Bound Actions", SourceMCPConfigurationTool."Allow Bound Actions", 'Allow Bound Actions mismatch');
    end;

    [Test]
    procedure TestDefaultConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        // [GIVEN] Default configuration is created during setup

        // [WHEN] Get default configuration is called
        MCPConfiguration.Get();

        // [THEN] Default configuration is active, dynamic tool mode and access to all read-only objects are enabled
        Assert.IsTrue(MCPConfiguration.Active, 'Default configuration is not active');
        Assert.IsTrue(MCPConfiguration.EnableDynamicToolMode, 'Dynamic tool mode is not enabled');
        // Assert.IsTrue(MCPConfiguration.EnableDiscoverReadOnlyObjects, 'Access to all read-only objects is not enabled');
    end;

    [Test]
    procedure TestDeleteDefaultConfiguration()
    begin
        // [GIVEN] Default configuration is created during setup

        // [WHEN] Delete default configuration is called
        asserterror MCPConfig.DeleteConfiguration(MCPConfig.GetConfigurationIdByName(''));

        // [THEN] Error message is returned
        Assert.ExpectedError('The default configuration cannot be deleted.');
    end;

    [Test]
    procedure TestDisableFeaturesOnDefaultConfiguration()
    var
        ConfigId: Guid;
    begin
        // [GIVEN] Default configuration is created during setup
        ConfigId := MCPConfig.GetConfigurationIdByName('');

        // [WHEN] Disable access to all read-only objects is called
        asserterror MCPConfig.EnableDiscoverReadOnlyObjects(ConfigId, false);

        // [THEN] Error message is returned
        Assert.ExpectedError('Access to all read-only objects cannot be disabled for the default configuration.');

        // [WHEN] Disable dynamic tool mode is called
        asserterror MCPConfig.EnableDynamicToolMode(ConfigId, false);

        // [THEN] Error message is returned
        Assert.ExpectedError('Dynamic tool mode cannot be disabled for the default configuration.');

        // [WHEN] Deactivate configuration is called
        asserterror MCPConfig.ActivateConfiguration(ConfigId, false);

        // [THEN] Error message is returned
        Assert.ExpectedError('The default configuration cannot be deactivated.');

        // [WHEN] Create API tool is called
        asserterror MCPConfig.CreateAPITool(ConfigId, Page::"Mock API");

        // [THEN] Error message is returned
        Assert.ExpectedError('Tools cannot be added to the default configuration.');
    end;

    [Test]
    procedure TestDefaultConfigurationPage()
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigCard: TestPage "MCP Config Card";
    begin
        // [GIVEN] Default configuration is created during setup
        MCPConfiguration.Get('');

        // [WHEN] Default configuration page is opened
        MCPConfigCard.OpenEdit();
        MCPConfigCard.GoToRecord(MCPConfiguration);

        // [THEN] All fields are not editable and tool list is not visible
        Assert.IsFalse(MCPConfigCard.Name.Editable(), 'Name field is editable');
        Assert.IsFalse(MCPConfigCard.Description.Editable(), 'Description field is editable');
        Assert.IsFalse(MCPConfigCard.Active.Editable(), 'Active field is editable');
        Assert.IsFalse(MCPConfigCard.EnableDynamicToolMode.Editable(), 'EnableDynamicToolMode field is editable');
        Assert.IsFalse(MCPConfigCard.DiscoverReadOnlyObjects.Editable(), 'DiscoverReadOnlyObjects field is editable');
        Assert.IsFalse(MCPConfigCard.ToolList.Visible(), 'ToolList is visible');
    end;

    local procedure CreateMCPConfig(Active: Boolean; DynamicToolMode: Boolean; AllowProdChanges: Boolean; DiscoverReadOnlyObjects: Boolean): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.Name := CopyStr(Format(CreateGuid()), 1, 100);
        MCPConfiguration.Description := CopyStr(Any.AlphabeticText(100), 1, 100);
        MCPConfiguration.Active := Active;
        MCPConfiguration.EnableDynamicToolMode := DynamicToolMode;
        MCPConfiguration.AllowProdChanges := AllowProdChanges;
        MCPConfiguration.DiscoverReadOnlyObjects := DiscoverReadOnlyObjects;
        MCPConfiguration.Insert();
        exit(MCPConfiguration.SystemId);
    end;

    local procedure CreateMCPConfigTool(ConfigId: Guid): Guid
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Id" := Any.IntegerInRange(1, 100);
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        MCPConfigurationTool."Allow Read" := true;
        MCPConfigurationTool."Allow Create" := false;
        MCPConfigurationTool."Allow Modify" := false;
        MCPConfigurationTool."Allow Delete" := false;
        MCPConfigurationTool."Allow Bound Actions" := false;
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
    end;

    [ModalPageHandler]
    procedure LookupAPIToolsOKHandler(var MCPAPIConfigToolLookup: TestPage "MCP API Config Tool Lookup")
    begin
        MCPAPIConfigToolLookup.GoToKey(Page::"Mock API");
        MCPAPIConfigToolLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddToolsByAPIGroupOKHandler(var MCPToolsByAPIGroup: TestPage "MCP Tools By API Group")
    begin
        MCPToolsByAPIGroup.APIPublisher.SetValue('mock');
        MCPToolsByAPIGroup.APIGroup.SetValue('mcp');
        MCPToolsByAPIGroup.OK().Invoke();
    end;
}