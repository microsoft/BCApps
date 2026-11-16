// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

codeunit 139595 "Report Layouts Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler')]
    procedure TestReportLayoutsInsertedLayoutsCanBeFound()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        // Act - Open Page and create a new layout
        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        ReportLayoutsPage.Close();

        // Assert - Layout Exists
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should be inserted for all companies.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandlerCurrentCompany')]
    procedure TestReportLayoutsInsertedLayoutForCurrentCompanyIsOnlyForCurrentCompany()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        // Act - Open Page and create a new layout
        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        ReportLayoutsPage.Close();

        // Assert - Layout Exists for current company

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual(CompanyName(), TenantReportLayout."Company Name", 'Layout should be only for the current company.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandler')]
    procedure TestReportLayoutsEditLayoutActuallyEditsTheLayout()
    begin
        EditLayoutTestCore('', '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandlerCurrentCompany,EditLayoutModalHandler')]
    procedure TestReportLayoutsEditLayoutPreservesCompanyOnTheLayout()
    begin
        EditLayoutTestCore(CompanyName(), CompanyName());
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,ConfirmHandler')]
    procedure TestReportLayoutsReplaceLayoutReplacesLayout()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        ReplacedLayoutOutStream: OutStream;
        ReplacedLayoutText: Text;
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report and insert a new layout
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Delete the layout

        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Replace the text with new text
        ReportLayoutsTest.SetLayoutContents(AlternateLayoutTextTxt);
        ReportLayoutsPage.ReplaceLayout.Invoke();

        // Assert - Layout exists and contains new contents
        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);

        TempBlob.CreateOutStream(ReplacedLayoutOutStream);
        ReportLayoutList.Layout.ExportStream(ReplacedLayoutOutStream);

        TempBlob.CreateInStream().ReadText(ReplacedLayoutText, StrLen(AlternateLayoutTextTxt));
        Assert.AreEqual(AlternateLayoutTextTxt, ReplacedLayoutText, 'The contents of the layout were not replaced.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandler,MessageHandler')]
    procedure TestReportLayoutsSetsCorrectSelections()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report and insert a new layout
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Set a selection

        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        ReportLayoutsPage.DefaulLayoutSelection.Invoke();

        // Assert - Selection is added
        Assert.IsTrue(TenantReportLayoutSelection.Get(139595, CompanyName(), EmptyGuid), 'A selection should have been set but was not');
        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayoutSelection."Layout Name", 'The inserted layout name does not match the layout.');

        // Act - Edit the layout to change its name
        ReportLayoutsPage.EditLayout.Invoke();

        // Assert 
        Assert.IsTrue(TenantReportLayoutSelection.Get(139595, CompanyName(), EmptyGuid), 'A selection should have been set but was not');
        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayoutSelection."Layout Name", 'The inserted layout name does not match the layout.');
    end;

    [Test]
    [HandlerFunctions('NewRDLCLayoutModalHandler,MessageHandlerValidateLayout')]
    procedure TestReportLayoutsValidateLayout()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report and insert a new layout
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'A layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'A layout should exist for all companies.');

        // Act - Set a selection
        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act -  Validate the layout
        ReportLayoutsPage.ValidateLayout.Invoke();
    end;

    local procedure EditLayoutTestCore(InitialCompanyName: Text; EditedCompanyName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report and insert a new layout
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual(InitialCompanyName, TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Layout is edited

        ReportLayoutsPage.EditLayout.Invoke();

        // Assert - Layout has been changed

        Assert.IsTrue(TenantReportLayout.Get(139595, EditedLayoutNameTxt, EmptyGuid), 'Edited layout should exist');

        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayout.Description, 'Description was not edited properly.');

        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayout.Name, 'Name was not edited properly.');

        Assert.AreEqual(EditedCompanyName, TenantReportLayout."Company Name", 'The company should have been empty (available for all companies) but had a different value.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandlerCurrentCompany,EditLayoutModalHandlerNoCopyMakeAvailableAll')]
    procedure TestReportLayouts_MakePrivateLayoutPublicWithoutCopy()
    begin
        EditLayoutTestCore(CompanyName(), '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandlerCurrentCompany,EditLayoutModalHandlerCopyMakeAvailableAll')]
    procedure TestReportLayouts_MakePrivateLayoutPublicWithCopy()
    begin
        EditLayoutTestCore(CompanyName(), '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandlerNoCopyMakePrivate')]
    procedure TestReportLayouts_MakePublicLayoutPrivateWithoutCopy()
    begin
        // Note that this operation is not allowed.
        EditLayoutTestCore('', '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandlerCopyMakePrivate')]
    procedure TestReportLayouts_MakePublicLayoutPrivateWithCopy()
    begin
        EditLayoutTestCore('', CompanyName());
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandlerSetIsObsoleteTrue')]
    procedure TestReportLayouts_SetLayoutAsObsoleteTrue()
    begin
        EditLayoutTestCore('', '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,EditLayoutModalHandlerSetIsObsoleteFalse')]
    procedure TestReportLayouts_SetLayoutAsObsoleteFalse()
    begin
        EditLayoutTestCore('', '');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,MessageHandlerLayoutInfoDialog')]
    procedure TestReportLayoutsInfoDialog()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // Init - Ensure layouts are not inserted for the test report and insert a new layout
        EnsureNewLayoutsAreCleaned();

        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        Assert.IsTrue(ReportLayoutsPage.NewLayout.Enabled(), 'New layout should always be enabled.');

        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Set a selection
        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Show the info dialog
        ReportLayoutsPage.ShowInfoDialog.Invoke();
    end;

    /// <summary>
    /// Sets the contents of the layout that will be inserted by
    /// the event subscriber.
    /// </summary>
    /// <param name="WhatToInsert">The contents.</param>
    procedure SetLayoutContents(WhatToInsert: Text)
    begin
        InsertedLayoutContextTxt := WhatToInsert;
    end;

    [ModalPageHandler]
    procedure NewLayoutModalHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.LayoutName.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog.Description.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog."Format Options".Value := 'External';

        Assert.AreEqual('Yes', ReportLayoutNewDialog.AvailableInAllCompanies.Value, 'The available in all companies toggle should be on by default.');

        ReportLayoutNewDialog.ReportID.Value := '139595';
        ReportLayoutNewDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewLayoutModalHandlerCurrentCompany(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.LayoutName.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog.Description.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog."Format Options".Value := 'External';

        Assert.AreEqual('Yes', ReportLayoutNewDialog.AvailableInAllCompanies.Value, 'The available in all companies toggle should be on by default.');
        ReportLayoutNewDialog.AvailableInAllCompanies.SetValue(false);

        ReportLayoutNewDialog.ReportID.Value := '139595';
        ReportLayoutNewDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewRDLCLayoutModalHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.LayoutName.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog.Description.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog."Format Options".Value := 'RDLC';
        ReportLayoutNewDialog.CreateEmptyLayout.SetValue(true);

        Assert.AreEqual('Yes', ReportLayoutNewDialog.AvailableInAllCompanies.Value, 'The available in all companies toggle should be on by default.');

        ReportLayoutNewDialog.ReportID.Value := '139595';
        ReportLayoutNewDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerNoCopyMakeAvailableAll(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerCopyMakeAvailableAll(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.CreateCopy.SetValue(true);
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerNoCopyMakePrivate(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(false);
        ReportLayoutEditDialog.CreateCopy.SetValue(false);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerCopyMakePrivate(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(false);
        ReportLayoutEditDialog.CreateCopy.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerSetIsObsoleteTrue(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.IsObsolete.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLayoutModalHandlerSetIsObsoleteFalse(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.LayoutName.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.Description.Value := EditedLayoutNameTxt;
        ReportLayoutEditDialog.IsObsolete.SetValue(false);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    procedure MessageHandlerLayoutInfoDialog(Message: Text[1024])
    var
        MessagePattern: Text;
        Regex: DotNet Regex;
    begin
        // Arrange
        MessagePattern := '^Report ID: [0-9]+\\' +
                          'Report Name: .*\\' +
                          'Layout Name: .*\\' +
                          'Description: .*\\' +
                          'Type: .+\\' +
                          'System ID: .*\\' +
                          'Created Date: .*\\' +
                          'Created By: .*\\' +
                          'Last Modified Date: .*\\' +
                          'Last Modified By: .*$';

        // Assert
        Assert.IsTrue(Regex.IsMatch(Message, MessagePattern), 'The message must match the regex pattern.');
    end;

    [MessageHandler]
    procedure MessageHandlerValidateLayout(Message: Text[1024])
    begin
        // Assert
        Assert.AreEqual('The report layout is valid.', Message, 'The validation should return a valid message.');
    end;

    local procedure EnsureNewLayoutsAreCleaned()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
    begin
        TenantReportLayout.SetRange("Report ID", 139595);
        TenantReportLayout.DeleteAll();

        TenantReportLayoutOverride.SetRange("Report ID", 139595);
        TenantReportLayoutOverride.DeleteAll();

        // A test failing between Enqueue and Dequeue would otherwise leak into the next one.
        LibraryVariableStorage.Clear();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Layouts Impl.", 'OnBeforeUpload', '', false, false)]
    local procedure UploadHandler(var AlreadyUploaded: Boolean; var UploadFileName: Text; var FileInStream: InStream)
    var
        TempOutStream: OutStream;
    begin
        if AlreadyUploaded then
            exit;

        TempBlob.CreateOutStream(TempOutStream);
        TempOutStream.WriteText(InsertedLayoutContextTxt, StrLen(InsertedLayoutContextTxt));

        TempBlob.CreateInStream(FileInStream);

        UploadFileName := 'TestLayout';
        AlreadyUploaded := true;
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler')]
    procedure TestNewLayoutDefaultsToDraftStatus()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] A newly created layout should default to Draft status
        // Init
        EnsureNewLayoutsAreCleaned();
        BindSubscription(ReportLayoutsTest);

        // Act - Create a new layout
        ReportLayoutsPage.OpenView();
        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Layout status should be Draft
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Draft,
            TenantReportLayout."Layout Status",
            'New layout should default to Draft status.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,StatusChangedMessageHandler')]
    procedure TestSetLayoutStatusToApproved()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Setting layout status to Approved via page action updates the underlying record
        // Init
        EnsureNewLayoutsAreCleaned();
        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        // Navigate to the new layout
        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set status to Approved
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be Approved in the tenant table
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayout."Layout Status",
            'Layout status should be Approved after invoking SetApproved action.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,StatusChangedMessageHandler')]
    procedure TestSetLayoutStatusToRetired()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Setting layout status to Retired via page action updates the underlying record
        // Init
        EnsureNewLayoutsAreCleaned();
        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        // Navigate to the new layout
        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set status to Retired
        ReportLayoutsPage.SetRetired.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be Retired in the tenant table
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Retired,
            TenantReportLayout."Layout Status",
            'Layout status should be Retired after invoking SetRetired action.');
    end;

    [Test]
    [HandlerFunctions('NewLayoutModalHandler,StatusChangedMessageHandler')]
    procedure TestSetLayoutStatusCycleDraftToApprovedToDraft()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Layout status can be cycled: Draft -> Approved -> Draft
        // Init
        EnsureNewLayoutsAreCleaned();
        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        ReportLayoutsTest.SetLayoutContents(SampleTextTxt);
        ReportLayoutsPage.NewLayout.Invoke();

        ReportLayoutList.Get(139595, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set to Approved then back to Draft
        ReportLayoutsPage.SetApproved.Invoke();

        // Verify intermediate state
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayout."Layout Status",
            'Layout status should be Approved after first transition.');

        ReportLayoutsPage.SetDraft.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be back to Draft
        Assert.IsTrue(TenantReportLayout.Get(139595, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Draft,
            TenantReportLayout."Layout Status",
            'Layout status should be Draft after cycling back.');
    end;

    [Test]
    [HandlerFunctions('StatusChangedMessageHandler')]
    procedure TestSetExtensionLayoutStatusWritesOverride()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Setting the status of an extension-installed layout writes an ALL-COMPANIES
        // Tenant Report Layout Override record instead of copying the layout into the tenant table.

        // Init - remove any tenant layouts/overrides for the test report
        EnsureNewLayoutsAreCleaned();

        // The test report (139595) ships an RDLC layout via its rendering section, so it surfaces in
        // Report Layout List as an extension-installed layout (User Defined = false).
        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Set status to Approved via the page action
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        Assert.IsTrue(ReportLayoutsPage.SetApproved.Enabled(), 'Set Approved should be enabled for extension layouts.');
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a global override carries the Approved status...
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created for the extension layout.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'The Override Layout Status flag should be set.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The override should carry the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'No company-specific override should have been created.');

        // ...and no copy was made into the tenant table.
        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [MessageHandler]
    procedure StatusChangedMessageHandler(Message: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('StatusChangedMessageHandler')]
    procedure TestSetGlobalScopeExtensionLayoutStatusUpdatesGlobal()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Changing the status of an extension layout whose STATUS is already overridden
        // globally updates that global override rather than creating a company-specific one. No
        // confirmation is raised — all-companies is the normal scope, so no ConfirmHandler is
        // registered and an unexpected prompt would fail this test.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Seed the STATUS field specifically: the table is field-granular, so scope is resolved from
        // "Override Layout Status" and a description-only row would not establish it.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - Set status to Approved; scope is global and no confirmation should be raised
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the GLOBAL override carries the Approved status; no company-specific override was created
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'Override Layout Status should be set on the global override.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should carry the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'No company-specific override should have been created for a global-scope layout.');
    end;

    [Test]
    [HandlerFunctions('StatusChangedMessageHandler')]
    procedure TestCompanyDescriptionOnlyOverrideDoesNotForkGlobalStatus()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] The override table is field-granular. A company-specific row that overrides only the
        // DESCRIPTION must not make a status change company-scoped - that would silently fork layout
        // status per company. Scope is resolved from "Override Layout Status", so the change stays
        // all-companies and updates the global row.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Global row owns the STATUS...
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // ...while a company row owns only the DESCRIPTION.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutOverride."Company Name"));
        TenantReportLayoutOverride.Description := EditedLayoutNameTxt;
        TenantReportLayoutOverride."Override Description" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - Set status to Approved; scope stays all-companies and no confirmation should be raised
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the GLOBAL row took the new status...
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should have taken the Approved status.');

        // ...and the company row still overrides only the description, with no forked status.
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'The company-specific description override should still exist.');
        Assert.IsFalse(
            TenantReportLayoutOverride."Override Layout Status",
            'The status must not be forked into the company-specific override.');
    end;

    [Test]
    [HandlerFunctions('StatusChangedMessageHandler')]
    procedure TestGlobalDescriptionOnlyOverrideTakesStatusGlobally()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] A GLOBAL row that overrides only the description gains the status override on the
        // same row rather than causing a second row to be created. No confirmation is raised
        // (no ConfirmHandler is registered, so an unexpected Confirm would fail this test).
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride.Description := EditedLayoutNameTxt;
        TenantReportLayoutOverride."Override Description" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - Set status to Approved; all-companies is the default scope, no confirmation expected
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the existing GLOBAL row now carries both overrides...
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'The Override Layout Status flag should be set.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should carry the Approved status.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Description", 'The existing description override must be preserved.');

        // ...and no company-specific row was created.
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'No company-specific override should have been created.');
    end;

    [Test]
    [HandlerFunctions('StatusChangedMessageHandler')]
    procedure TestCompanyStatusOverrideKeepsStatusCompanyScoped()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Company precedence survives the move to all-companies-by-default: where this company
        // ALREADY has a status override, a further status change stays in that company and does not leak
        // into a global row. Such rows can no longer be created from the UI, but they may come from an
        // earlier version or a vendor's install codeunit — and this is the branch a future
        // company-scoped option would build on.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutOverride."Company Name"));
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the COMPANY row took the new status, and nothing went global
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'The company-specific override should still exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The company override should have taken the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'No global override should have been created when this company already owns the status.');
    end;

    [Test]
    procedure TestMixedScopeBatchStatusIsRejected()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] A batch status change spanning mixed scopes is rejected, keeping each run to a
        // single unambiguous scope.
        // Driven through the internal impl codeunit (Tests-Report is in BaseApp internalsVisibleTo)
        // because a TestPage cannot multi-select records for CurrPage.SetSelectionFilter.
        EnsureNewLayoutsAreCleaned();

        // Report 139595 ships two extension layouts. All-companies is now the DEFAULT scope, so mixing
        // requires giving one layout a COMPANY-SPECIFIC status override; the untouched second layout
        // resolves to global. (Seeding a global override on one would no longer create a mix — both
        // sides would be global.)
        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two extension layouts.');
        ReportLayoutList.FindFirst();

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutOverride."Company Name"));
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - batch over BOTH extension layouts (mixed scope)
        ReportLayoutList.Reset();
        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        asserterror ReportLayoutsImpl.SetLayoutStatusBatch(ReportLayoutList, Enum::"Report Layout Status"::Approved);

        // Assert - rejected with the mixed-scope error
        Assert.ExpectedError('different scopes');
    end;

    [Test]
    procedure TestBatchStatusResolvesScopeWithoutSetSelectedCompany()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        UpdateCount: Integer;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Scope resolution must not depend on a caller having called SetSelectedCompany first.
        // "Report Theme and Header/Footer" reaches SetLayoutStatusBatch without calling it, and a blank
        // company would make the company-row lookup probe the GLOBAL row instead: an already-overridden
        // layout would then classify as company scope while a fresh one classified as global, and this
        // batch would fail with the mixed-scope error even though both are global.
        // Note this test deliberately does NOT call SetSelectedCompany.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two extension layouts.');
        ReportLayoutList.FindFirst();

        // One layout already carries a GLOBAL status override; the other has none. Both are global scope.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - batch over BOTH, with SelectedCompany never set
        ReportLayoutList.Reset();
        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        UpdateCount := ReportLayoutsImpl.SetLayoutStatusBatch(ReportLayoutList, Enum::"Report Layout Status"::Approved);

        // Assert - no spurious mixed-scope error, and both layouts updated globally
        Assert.AreEqual(2, UpdateCount, 'Both layouts should have been updated; a blank company must not split the scope.');
        ReportLayoutList.FindSet();
        repeat
            Assert.IsTrue(
                TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
                StrSubstNo(GlobalOverrideMissingErr, ReportLayoutList."Name"));
            Assert.AreEqual(
                Enum::"Report Layout Status"::Approved,
                TenantReportLayoutOverride."Layout Status",
                StrSubstNo(GlobalOverrideApprovedErr, ReportLayoutList."Name"));
        until ReportLayoutList.Next() = 0;
    end;

    [Test]
    procedure TestBatchStatusOverAllGlobalLayoutsUpdatesEveryOne()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        UpdateCount: Integer;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] The success path of a multi-layout batch run: two fresh extension layouts both
        // resolve to all-companies scope, so the run is single-scope and applies to both. No
        // confirmation is raised — no ConfirmHandler is registered, so a prompt would fail this test,
        // which is what pins the removal of the former all-companies confirmation.
        // Driven through the internal impl codeunit because a TestPage cannot multi-select.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two extension layouts.');

        // Act - batch over BOTH layouts, neither of which has any override yet
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        UpdateCount := ReportLayoutsImpl.SetLayoutStatusBatch(ReportLayoutList, Enum::"Report Layout Status"::Retired);

        // Assert - both were updated...
        Assert.AreEqual(2, UpdateCount, 'Both extension layouts should have been updated.');

        // ...each through a GLOBAL override, with no company-specific rows anywhere.
        ReportLayoutList.FindSet();
        repeat
            Assert.IsTrue(
                TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
                StrSubstNo(GlobalOverrideMissingErr, ReportLayoutList."Name"));
            Assert.AreEqual(
                Enum::"Report Layout Status"::Retired,
                TenantReportLayoutOverride."Layout Status",
                StrSubstNo(GlobalOverrideRetiredErr, ReportLayoutList."Name"));
            Assert.IsFalse(
                TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
                StrSubstNo(CompanyOverrideUnexpectedErr, ReportLayoutList."Name"));
        until ReportLayoutList.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('EditExtensionAssertObsoleteLockedHandler')]
    procedure TestObsoleteExtensionLayoutCannotBeUnObsoleted()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] IsObsolete is ONE-WAY. Once a layout resolves to obsolete, the edit dialog must not
        // offer a way back: the field is locked, so retiring cannot be undone through the UI. This is
        // the guarantee the design leans on when treating obsoleting as a grave act.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Make the layout obsolete via a global override, the way the everyday edit path would.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride.IsObsolete := true;
        TenantReportLayoutOverride."Override IsObsolete" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - reopen Edit info; the handler records whether the obsolete field was editable
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the field was locked, and the layout is still obsolete
        Assert.IsFalse(
            LibraryVariableStorage.DequeueBoolean(),
            'Mark layout as obsolete must be locked once the layout is already obsolete.');
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global obsolete override should still exist.');
        Assert.IsTrue(TenantReportLayoutOverride.IsObsolete, 'The layout must still be obsolete.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EditExtensionOverrideDescHandler')]
    procedure TestEditExtensionLayoutWritesGlobalDescriptionOverride()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Editing an extension-installed layout's description writes an ALL-COMPANIES
        // Tenant Report Layout Override record instead of copying the layout. An extension layout is the
        // same layout in every company, so its description is overridden tenant-wide by default.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode)
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a GLOBAL description override exists (and no company-specific one), no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Description", 'The Override Description flag should be set.');
        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayoutOverride.Description, 'The override should carry the edited description.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'An everyday edit must not create a company-specific override.');

        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [Test]
    [HandlerFunctions('EditExtensionOverrideObsoleteHandler')]
    procedure TestEditExtensionLayoutWritesGlobalObsoleteOverride()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Marking an extension-installed layout obsolete writes an ALL-COMPANIES override
        // (one-way IsObsolete) instead of copying the layout.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode), mark obsolete
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a global obsolete override exists, no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override IsObsolete", 'The Override IsObsolete flag should be set.');
        Assert.IsTrue(TenantReportLayoutOverride.IsObsolete, 'The override should mark the layout obsolete.');

        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [Test]
    [HandlerFunctions('EditExtensionOverrideNoOpHandler')]
    procedure TestEditExtensionLayoutNoOpWritesNoOverride()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Edit info on an extension layout + OK with no changes writes NO override
        // (no silent global override for a no-op edit).
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        TenantReportLayoutOverride.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayoutOverride.IsEmpty(), 'A no-op edit must not create any override.');
    end;

    [ModalPageHandler]
    procedure EditExtensionOverrideDescHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.Description.SetValue(EditedLayoutNameTxt);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditExtensionOverrideObsoleteHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.IsObsolete.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditExtensionAssertObsoleteLockedHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        // Record only. The test asserts, so a mismatch cannot be swallowed by the calling UI operation.
        LibraryVariableStorage.Enqueue(ReportLayoutEditDialog.IsObsolete.Editable());
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditExtensionOverrideNoOpHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        // Change nothing, just confirm — should write no override.
        ReportLayoutEditDialog.OK().Invoke();
    end;


    [Test]
    [HandlerFunctions('EditExtensionCopyAllCompaniesHandler')]
    procedure TestCopyOfExtensionLayoutKeepsAllCompaniesScope()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Copying an extension layout ("Save Changes to a Copy") creates an ordinary tenant
        // layout whose company scope comes from "Available in All Companies" (default: all companies),
        // NOT from the override-scope control — and writes no override record.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info -> tick "Save Changes to a Copy", rename, leave availability at its default
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the dialog defaulted to all companies, the copy is a GLOBAL tenant layout, no override
        Assert.AreEqual('Yes', LibraryVariableStorage.DequeueText(), 'A copy should default to all companies.');
        Assert.IsTrue(
            TenantReportLayout.Get(139595, EditedLayoutNameTxt, EmptyGuid),
            'The copy should exist in Tenant Report Layout under its new name.');
        Assert.AreEqual('', TenantReportLayout."Company Name", 'The copy should be available in all companies by default.');

        TenantReportLayoutOverride.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayoutOverride.IsEmpty(), 'Copying must not write an override record.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EditExtensionToggleCopyOffHandler')]
    procedure TestUntickingCopyRestoresAllCompaniesScope()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Ticking "Save Changes to a Copy", choosing company-only, then unticking it must put
        // the scope back to all companies. Otherwise the field shows a read-only No while the in-place
        // edit writes an all-companies override - the dialog would contradict what is written.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - tick Copy, select company-only, untick Copy, then edit the description and save
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - the dialog showed Yes again, and the override it wrote is global
        Assert.AreEqual(
            'Yes', LibraryVariableStorage.DequeueText(),
            'Unticking Save Changes to a Copy must restore the all-companies scope shown in the dialog.');
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override should have been written.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'No company-specific override should exist.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [ModalPageHandler]
    procedure EditExtensionToggleCopyOffHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.CreateCopy.SetValue(true);
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(false);
        ReportLayoutEditDialog.CreateCopy.SetValue(false);
        LibraryVariableStorage.Enqueue(ReportLayoutEditDialog.AvailableInAllCompanies.Value);
        ReportLayoutEditDialog.Description.SetValue(EditedLayoutNameTxt);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CopyObsoleteExtensionLayoutHandler')]
    procedure TestCopyOfObsoleteExtensionLayoutCanClearObsolete()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] The one-way obsolete lock belongs to the in-place override path only. Taking a copy
        // of an obsolete extension layout must re-enable the field, because the copy is an ordinary
        // tenant layout - otherwise the copy is stuck obsolete and the old copy flow regresses.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Make the layout resolve to obsolete, the way the everyday edit path would
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride.IsObsolete := true;
        TenantReportLayoutOverride."Override IsObsolete" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - Edit info -> tick Copy; the handler records whether the obsolete field became editable
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - copy mode unlocked the field, and the copy exists
        Assert.IsTrue(
            LibraryVariableStorage.DequeueBoolean(),
            'Mark layout as obsolete must be editable again once Save Changes to a Copy is selected.');
        Assert.IsTrue(
            TenantReportLayout.Get(139595, EditedLayoutNameTxt, EmptyGuid),
            'The copy should exist in Tenant Report Layout under its new name.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [ModalPageHandler]
    procedure CopyObsoleteExtensionLayoutHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.CreateCopy.SetValue(true);
        LibraryVariableStorage.Enqueue(ReportLayoutEditDialog.IsObsolete.Editable());
        ReportLayoutEditDialog.LayoutName.SetValue(EditedLayoutNameTxt);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditExtensionCopyAllCompaniesHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.CreateCopy.SetValue(true);
        ReportLayoutEditDialog.LayoutName.SetValue(EditedLayoutNameTxt);
        // Record only; the test asserts it.
        LibraryVariableStorage.Enqueue(ReportLayoutEditDialog.AvailableInAllCompanies.Value);
        ReportLayoutEditDialog.OK().Invoke();
    end;


    var
        Assert: Codeunit Assert;
        TempBlob: Codeunit "Temp Blob";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NewLayoutNameTxt: Label 'NewLayout';
        EditedLayoutNameTxt: Label 'EditedLayout';
        SampleTextTxt: Label 'ATAKLOA, TINWTABSBATF.';
        AlternateLayoutTextTxt: Label 'IWATSTGIFLBOTG.';
        GlobalOverrideMissingErr: Label 'A global override should exist for layout %1.', Comment = '%1 = layout name';
        GlobalOverrideApprovedErr: Label 'The global override for %1 should carry the Approved status.', Comment = '%1 = layout name';
        GlobalOverrideRetiredErr: Label 'The global override for %1 should carry the Retired status.', Comment = '%1 = layout name';
        CompanyOverrideUnexpectedErr: Label 'No company-specific override should exist for layout %1.', Comment = '%1 = layout name';
        InsertedLayoutContextTxt: Text;
}
