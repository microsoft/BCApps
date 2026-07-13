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
        // [SCENARIO] Setting the status of an extension-installed layout writes a Tenant Report Layout
        // Override record instead of copying the layout into the tenant table.

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

        // Assert - a company-specific override carries the Approved status...
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'An override record should have been created for the extension layout.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'The Override Layout Status flag should be set.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The override should carry the Approved status.');

        // ...and no copy was made into the tenant table.
        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [MessageHandler]
    procedure StatusChangedMessageHandler(Message: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,StatusChangedMessageHandler')]
    procedure TestSetGlobalScopeExtensionLayoutStatusConfirmsAndUpdatesGlobal()
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Changing the status of an extension layout that already has a GLOBAL override
        // prompts for confirmation and updates the global override, not a company-specific one.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Establish global scope by seeding a global override for the layout.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride.Description := EditedLayoutNameTxt;
        TenantReportLayoutOverride."Override Description" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - Set status to Approved; scope is global, so a confirmation is expected (ConfirmHandler = Yes)
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
    procedure TestMixedScopeBatchStatusIsRejected()
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] A batch status change spanning mixed scopes (one global, one company-default
        // extension layout) is rejected, keeping each run to a single unambiguous scope.
        // Driven through the internal impl codeunit (Tests-Report is in BaseApp internalsVisibleTo)
        // because a TestPage cannot multi-select records for CurrPage.SetSelectionFilter.
        EnsureNewLayoutsAreCleaned();

        // Report 139595 ships two extension layouts; make the first global-scope, leave the second
        // at company-default scope.
        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two extension layouts.');
        ReportLayoutList.FindFirst();

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := 139595;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
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
    [HandlerFunctions('EditExtensionOverrideGlobalDescHandler')]
    procedure TestEditExtensionLayoutWritesGlobalDescriptionOverride()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Editing an extension-installed layout's description writes a global
        // Tenant Report Layout Override record instead of copying the layout.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode), global scope
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a global description override exists, no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Description", 'The Override Description flag should be set.');
        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayoutOverride.Description, 'The override should carry the edited description.');

        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [Test]
    [HandlerFunctions('EditExtensionOverrideCompanyObsoleteHandler')]
    procedure TestEditExtensionLayoutWritesCompanyObsoleteOverride()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO] Marking an extension-installed layout obsolete for the current company writes a
        // company-specific override (one-way IsObsolete) instead of copying the layout.
        EnsureNewLayoutsAreCleaned();

        ReportLayoutList.SetRange("Report ID", 139595);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode), company scope, mark obsolete
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a company-specific obsolete override exists, no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(139595, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'A company-specific override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override IsObsolete", 'The Override IsObsolete flag should be set.');
        Assert.IsTrue(TenantReportLayoutOverride.IsObsolete, 'The override should mark the layout obsolete.');

        TenantReportLayout.SetRange("Report ID", 139595);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'No copy should have been created in Tenant Report Layout.');
    end;

    [ModalPageHandler]
    procedure EditExtensionOverrideGlobalDescHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.Description.SetValue(EditedLayoutNameTxt);
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditExtensionOverrideCompanyObsoleteHandler(var ReportLayoutEditDialog: TestPage "Report Layout Edit Dialog")
    begin
        ReportLayoutEditDialog.AvailableInAllCompanies.SetValue(false);
        ReportLayoutEditDialog.IsObsolete.SetValue(true);
        ReportLayoutEditDialog.OK().Invoke();
    end;

    var
        Assert: Codeunit Assert;
        TempBlob: Codeunit "Temp Blob";
        NewLayoutNameTxt: Label 'NewLayout';
        EditedLayoutNameTxt: Label 'EditedLayout';
        SampleTextTxt: Label 'ATAKLOA, TINWTABSBATF.';
        AlternateLayoutTextTxt: Label 'IWATSTGIFLBOTG.';
        InsertedLayoutContextTxt: Text;
}
