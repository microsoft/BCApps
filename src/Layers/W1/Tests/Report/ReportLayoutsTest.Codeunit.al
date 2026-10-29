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
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Delete the layout

        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Replace the text with new text
        ReportLayoutsTest.SetLayoutContents(AlternateLayoutTextTxt);
        ReportLayoutsPage.ReplaceLayout.Invoke();

        // Assert - Layout exists and contains new contents
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);

        TempBlob.CreateOutStream(ReplacedLayoutOutStream, TextEncoding::UTF8);
        ReportLayoutList.Layout.ExportStream(ReplacedLayoutOutStream);

        TempBlob.CreateInStream(TextEncoding::UTF8).ReadText(ReplacedLayoutText, StrLen(AlternateLayoutTextTxt));
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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Set a selection

        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        ReportLayoutsPage.DefaulLayoutSelection.Invoke();

        // Assert - Selection is added
        Assert.IsTrue(TenantReportLayoutSelection.Get(Report::TestReportLayoutsReport, CompanyName(), EmptyGuid), 'A selection should have been set but was not');
        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayoutSelection."Layout Name", 'The inserted layout name does not match the layout.');

        // Act - Edit the layout to change its name
        ReportLayoutsPage.EditLayout.Invoke();

        // Assert 
        Assert.IsTrue(TenantReportLayoutSelection.Get(Report::TestReportLayoutsReport, CompanyName(), EmptyGuid), 'A selection should have been set but was not');
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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'A layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'A layout should exist for all companies.');

        // Act - Set a selection
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act -  Validate the layout
        ReportLayoutsPage.ValidateLayout.Invoke();
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportWordLayout()
    begin
        ImportLayoutTestCore('Word', 'TestLayout.docx', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportRDLCLayout()
    begin
        ImportLayoutTestCore('RDLC', 'TestLayout.rdlc', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportRDLLayout()
    begin
        ImportLayoutTestCore('RDLC', 'TestLayout.rdl', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportExcelLayout()
    begin
        ImportLayoutTestCore('Excel', 'TestLayout.xlsx', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportExternalLayout()
    begin
        ImportLayoutTestCore('External', 'TestLayout.xml', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportExternalLayoutWithoutExtension()
    begin
        ImportLayoutTestCore('External', 'TestLayout', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportLayoutForCurrentCompany()
    begin
        ImportLayoutTestCore('Word', 'TestLayout.docx', false, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportLayoutWithUppercaseExtension()
    begin
        ImportLayoutTestCore('Word', 'TestLayout.DOCX', true, false);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestCreateBlankWordLayout()
    begin
        ImportLayoutTestCore('Word', 'EmptyLayout.docx', true, true);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestCreateBlankRDLCLayout()
    begin
        ImportLayoutTestCore('RDLC', 'EmptyLayout.rdlc', true, true);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestCreateBlankExcelLayout()
    begin
        ImportLayoutTestCore('Excel', 'EmptyLayout.xlsx', true, true);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestExternalBlankLayoutStillUploadsFile()
    begin
        ImportLayoutTestCore('External', 'TestLayout.xml', true, true);
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportWordLayoutRejectsEmptyFile()
    begin
        ImportLayoutErrorTestCore('Word', 'TestLayout.docx', true, 'is empty. Choose a file that contains a layout');
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportRDLCLayoutRejectsEmptyFile()
    begin
        ImportLayoutErrorTestCore('RDLC', 'TestLayout.rdlc', true, 'is empty. Choose a file that contains a layout');
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportExcelLayoutRejectsEmptyFile()
    begin
        ImportLayoutErrorTestCore('Excel', 'TestLayout.xlsx', true, 'is empty. Choose a file that contains a layout');
    end;

    [Test]
    [HandlerFunctions('ImportLayoutModalHandler')]
    procedure TestImportExternalLayoutRejectsEmptyFile()
    begin
        ImportLayoutErrorTestCore('External', 'TestLayout.xml', true, 'is empty. Choose a file that contains a layout');
    end;

    [Test]
    [HandlerFunctions('CancelNewLayoutModalHandler')]
    procedure TestCancelNewLayoutDoesNotUpload()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        EnsureNewLayoutsAreCleaned();
        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();

        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
        Assert.IsTrue(TenantReportLayout.IsEmpty(), 'Cancelling the dialog must not create a layout.');
        Assert.AreEqual(0, ReportLayoutsTest.GetUploadCount(), 'Cancelling the dialog must not upload a file.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceWordLayout()
    begin
        ReplaceLayoutTestCore('Word', 'Replacement.docx', true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceRDLCLayout()
    begin
        ReplaceLayoutTestCore('RDLC', 'Replacement.rdlc', true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceRDLCLayoutFromRDLFile()
    begin
        ReplaceLayoutTestCore('RDLC', 'Replacement.rdl', true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceExcelLayout()
    begin
        ReplaceLayoutTestCore('Excel', 'Replacement.xlsx', true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceExternalLayout()
    begin
        ReplaceLayoutTestCore('External', 'Replacement.json', true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceLayoutPreservesCurrentCompany()
    begin
        ReplaceLayoutTestCore('Word', 'Replacement.docx', false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestReplaceLayoutRejectsEmptyFile()
    begin
        ReplaceLayoutErrorTestCore('Word', 'Replacement.docx', true, 'is empty. Choose a file that contains a layout');
        ReplaceLayoutErrorTestCore('RDLC', 'Replacement.rdlc', true, 'is empty. Choose a file that contains a layout');
        ReplaceLayoutErrorTestCore('Excel', 'Replacement.xlsx', true, 'is empty. Choose a file that contains a layout');
        ReplaceLayoutErrorTestCore('External', 'Replacement.xml', true, 'is empty. Choose a file that contains a layout');
    end;

    [Test]
    [HandlerFunctions('DeclineReplaceConfirmHandler')]
    procedure TestCancelReplaceLayoutDoesNotUpload()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        OriginalBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        EnsureNewLayoutsAreCleaned();
        CreateLayoutBlob('Word', OriginalBlob);
        InsertLayoutForFileTest('Word', NewLayoutNameTxt, '', true, OriginalBlob, TenantReportLayout);
        BindSubscription(ReportLayoutsTest);

        OpenFileTestLayout(ReportLayoutsPage, ReportLayoutList);
        ReportLayoutsPage.ReplaceLayout.Invoke();
        ReportLayoutsPage.Close();

        AssertLayoutUnchanged(TenantReportLayout, OriginalBlob);
        Assert.AreEqual(0, ReportLayoutsTest.GetUploadCount(), 'Declining replacement must not upload a file.');
    end;

    [Test]
    procedure TestCannotReplaceExtensionLayout()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        OriginalBlob: Codeunit "Temp Blob";
        ActualBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        EnsureNewLayoutsAreCleaned();
        FindExtensionLayout(ReportLayoutList, RDLCLayoutNameLbl);
        ReportLayoutList.Layout.ExportStream(OriginalBlob.CreateOutStream(TextEncoding::UTF8));
        BindSubscription(ReportLayoutsTest);

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        asserterror ReportLayoutsPage.ReplaceLayout.Invoke();
        Assert.ExpectedError('Only user-defined layouts can be modified or removed.');
        ReportLayoutsPage.Close();

        ReportLayoutList.Get(ReportLayoutList."Report ID", ReportLayoutList.Name, ReportLayoutList."Runtime Package ID");
        ReportLayoutList.Layout.ExportStream(ActualBlob.CreateOutStream(TextEncoding::UTF8));
        AssertBlobEquals(OriginalBlob, ActualBlob);
        Assert.AreEqual(0, ReportLayoutsTest.GetUploadCount(), 'An extension layout must not be replaced.');
    end;

    [Test]
    procedure TestExportWordLayout()
    begin
        ExportLayoutTestCore('Word', NewLayoutNameTxt, '', 'NewLayout.docx', false);
        ExportLayoutTestCore('Word', 'NewLayout.docx', '', 'NewLayout.docx', false);
    end;

    [Test]
    procedure TestExportRDLCLayout()
    begin
        ExportLayoutTestCore('RDLC', NewLayoutNameTxt, '', 'NewLayout.rdl', false);
        ExportLayoutTestCore('RDLC', 'NewLayout.rdl', '', 'NewLayout.rdl', false);
    end;

    [Test]
    procedure TestExportExcelLayout()
    begin
        ExportLayoutTestCore('Excel', NewLayoutNameTxt, '', 'NewLayout.xlsx', false);
        ExportLayoutTestCore('Excel', 'NewLayout.xlsx', '', 'NewLayout.xlsx', false);
    end;

    [Test]
    procedure TestExportExternalLayout()
    begin
        ExportLayoutTestCore('External', NewLayoutNameTxt, 'reportlayout/xml', 'NewLayout.xml', false);
        ExportLayoutTestCore('External', 'NewLayout.json', 'reportlayout/json', 'NewLayout.json', false);
        ExportLayoutTestCore('External', NewLayoutNameTxt, 'reportlayout/', 'NewLayout.', false);
    end;

    [Test]
    procedure TestExportExtensionLayout()
    begin
        ExportExtensionLayoutTestCore(false);
    end;

    [Test]
    procedure TestUpdateAndExportExtensionLayout()
    begin
        ExportExtensionLayoutTestCore(true);
    end;

    local procedure ExportExtensionLayoutTestCore(UpdateLayout: Boolean)
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        OriginalBlob: Codeunit "Temp Blob";
        ExportedBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
        ExportedFileName: Text;
        WithEncoding: Boolean;
    begin
        EnsureNewLayoutsAreCleaned();
        FindExtensionLayout(ReportLayoutList, RDLCLayoutNameLbl);
        ReportLayoutList.Layout.ExportStream(OriginalBlob.CreateOutStream(TextEncoding::UTF8));
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.EnableExportCapture();

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        if UpdateLayout then
            ReportLayoutsPage.UpdateAndExportLayout.Invoke()
        else
            ReportLayoutsPage.ExportLayout.Invoke();
        ReportLayoutsPage.Close();

        ReportLayoutsTest.GetExportedLayout(ExportedBlob, ExportedFileName, WithEncoding);
        Assert.AreEqual(ReportLayoutList.Name + '.rdl', ExportedFileName, 'Incorrect extension layout export file name.');
        Assert.AreEqual(UpdateLayout, WithEncoding, 'Only an updated export must use the UTF8 export path.');
        if UpdateLayout then
            AssertLayoutCanBePrepared('RDLC', ExportedBlob)
        else
            AssertBlobEquals(OriginalBlob, ExportedBlob);
    end;

    [Test]
    procedure TestUpdateAndExportWordLayout()
    begin
        ExportLayoutTestCore('Word', NewLayoutNameTxt, '', 'NewLayout.docx', true);
    end;

    [Test]
    procedure TestUpdateAndExportRDLCLayout()
    begin
        ExportLayoutTestCore('RDLC', NewLayoutNameTxt, '', 'NewLayout.rdl', true);
    end;

    [Test]
    procedure TestUpdateAndExportExcelLayout()
    begin
        ExportLayoutTestCore('Excel', NewLayoutNameTxt, '', 'NewLayout.xlsx', true);
    end;

    [Test]
    procedure TestExportReportSchema()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        ExportedBlob: Codeunit "Temp Blob";
        ExpectedBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
        ExportedFileName: Text;
        WithEncoding: Boolean;
    begin
        EnsureNewLayoutsAreCleaned();
        FindExtensionLayout(ReportLayoutList, RDLCLayoutNameLbl);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.EnableExportCapture();

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.ExportReportSchema.Invoke();
        ReportLayoutsPage.Close();

        ReportLayoutsTest.GetExportedLayout(ExportedBlob, ExportedFileName, WithEncoding);
        Assert.AreEqual('*.xml', ExportedFileName, 'Incorrect report schema export file filter.');
        Assert.IsFalse(WithEncoding, 'The schema must be exported without changing its UTF16 encoding.');
        ExpectedBlob.CreateOutStream(TextEncoding::UTF16).WriteText(Report.WordXmlPart(Report::TestReportLayoutsReport));
        AssertBlobEquals(ExpectedBlob, ExportedBlob);
    end;

    local procedure ImportLayoutTestCore(LayoutFormat: Text; FileName: Text; AvailableInAllCompanies: Boolean; CreateBlankLayout: Boolean)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        FileManagement: Codeunit "File Management";
        UploadBlob: Codeunit "Temp Blob";
        ActualBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
        EmptyGuid: Guid;
        ExpectedCompany: Text;
    begin
        EnsureNewLayoutsAreCleaned();
        if (not CreateBlankLayout) or (LayoutFormat = 'External') then
            CreateLayoutBlob(LayoutFormat, UploadBlob);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.SetLayoutUpload(UploadBlob, FileName);

        OpenImportLayoutPage(ReportLayoutsPage, LayoutFormat, CreateBlankLayout, AvailableInAllCompanies);
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'The imported layout must exist.');
        Assert.AreEqual(LayoutFormat, GetLayoutFormatCaption(TenantReportLayout), 'Incorrect imported layout format.');
        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Description, 'Incorrect imported layout description.');
        if LayoutFormat = 'External' then
            Assert.AreEqual('reportlayout/' + FileManagement.GetExtension(FileName), TenantReportLayout."MIME Type", 'The custom MIME type must preserve the uploaded file extension.');
        if not AvailableInAllCompanies then
            ExpectedCompany := CompanyName();
        Assert.AreEqual(ExpectedCompany, TenantReportLayout."Company Name", 'Incorrect imported layout company scope.');
        TenantReportLayout.Layout.ExportStream(ActualBlob.CreateOutStream(TextEncoding::UTF8));
        if CreateBlankLayout and (LayoutFormat <> 'External') then begin
            Assert.IsTrue(ActualBlob.HasValue(), 'The generated blank layout must not be empty.');
            Assert.AreEqual(0, ReportLayoutsTest.GetUploadCount(), 'Generating a blank layout must not upload a file.');
            AssertLayoutCanBePrepared(LayoutFormat, ActualBlob);
        end else begin
            Assert.AreEqual(1, ReportLayoutsTest.GetUploadCount(), 'Creating a layout must upload exactly one file.');
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ImportLayoutErrorTestCore(LayoutFormat: Text; FileName: Text; EmptyFile: Boolean; ExpectedError: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        UploadBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        EnsureNewLayoutsAreCleaned();
        if not EmptyFile then
            CreateLayoutBlob(LayoutFormat, UploadBlob);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.SetLayoutUpload(UploadBlob, FileName);

        OpenImportLayoutPage(ReportLayoutsPage, LayoutFormat, false, true);
        asserterror ReportLayoutsPage.NewLayout.Invoke();
        Assert.ExpectedError(ExpectedError);
        ReportLayoutsPage.Close();
    end;

    local procedure ReplaceLayoutTestCore(LayoutFormat: Text; FileName: Text; AvailableInAllCompanies: Boolean)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        FileManagement: Codeunit "File Management";
        OriginalBlob: Codeunit "Temp Blob";
        ReplacementBlob: Codeunit "Temp Blob";
        ActualBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
        OriginalCompany: Text;
    begin
        EnsureNewLayoutsAreCleaned();
        CreateLayoutBlob(LayoutFormat, OriginalBlob);
        InsertLayoutForFileTest(LayoutFormat, NewLayoutNameTxt, '', AvailableInAllCompanies, OriginalBlob, TenantReportLayout);
        if LayoutFormat = 'Word' then begin
            TenantReportLayout."Layout Subtype" := TenantReportLayout."Layout Subtype"::Body;
            TenantReportLayout.Modify(true);
        end;
        OriginalCompany := TenantReportLayout."Company Name";
        CreateLayoutBlob(LayoutFormat, ReplacementBlob);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.SetLayoutUpload(ReplacementBlob, FileName);

        OpenFileTestLayout(ReportLayoutsPage, ReportLayoutList);
        ReportLayoutsPage.ReplaceLayout.Invoke();
        ReportLayoutsPage.Close();

        TenantReportLayout.Get(TenantReportLayout."Report ID", TenantReportLayout.Name, TenantReportLayout."App ID");
        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Replacement must preserve the layout name.');
        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Description, 'Replacement must preserve the description.');
        Assert.AreEqual(OriginalCompany, TenantReportLayout."Company Name", 'Replacement must preserve company scope.');
        Assert.AreEqual(LayoutFormat, GetLayoutFormatCaption(TenantReportLayout), 'Replacement must preserve the layout format.');
        Assert.AreEqual(ReportLayoutList."Layout Subtype", TenantReportLayout."Layout Subtype", 'Replacement must preserve the layout subtype.');
        Assert.AreEqual(ReportLayoutList.ExcelLayoutMultipleDataSheets, TenantReportLayout.ExcelLayoutMultipleDataSheets, 'Replacement must preserve the Excel sheet configuration.');
        if LayoutFormat = 'External' then
            Assert.AreEqual('reportlayout/' + FileManagement.GetExtension(FileName), TenantReportLayout."MIME Type", 'Replacement must update the custom MIME type.');
        TenantReportLayout.Layout.ExportStream(ActualBlob.CreateOutStream(TextEncoding::UTF8));
        if LayoutFormat = 'Excel' then
            AssertLayoutCanBePrepared(LayoutFormat, ActualBlob)
        else
            AssertBlobEquals(ReplacementBlob, ActualBlob);
        Assert.AreEqual(1, ReportLayoutsTest.GetUploadCount(), 'Replacement must upload exactly one file.');
        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
        Assert.AreEqual(1, TenantReportLayout.Count(), 'Replacement must not insert an additional layout.');
    end;

    local procedure ReplaceLayoutErrorTestCore(LayoutFormat: Text; FileName: Text; EmptyFile: Boolean; ExpectedError: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        OriginalBlob: Codeunit "Temp Blob";
        UploadBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        EnsureNewLayoutsAreCleaned();
        CreateLayoutBlob(LayoutFormat, OriginalBlob);
        InsertLayoutForFileTest(LayoutFormat, NewLayoutNameTxt, '', false, OriginalBlob, TenantReportLayout);
        if not EmptyFile then
            CreateLayoutBlob(LayoutFormat, UploadBlob);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.SetLayoutUpload(UploadBlob, FileName);

        OpenFileTestLayout(ReportLayoutsPage, ReportLayoutList);
        asserterror ReportLayoutsPage.ReplaceLayout.Invoke();
        Assert.ExpectedError(ExpectedError);
        ReportLayoutsPage.Close();

        UnbindSubscription(ReportLayoutsTest);
    end;

    local procedure ExportLayoutTestCore(LayoutFormat: Text; LayoutName: Text[250]; MimeType: Text[255]; ExpectedFileName: Text; UpdateLayout: Boolean)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsTest: Codeunit "Report Layouts Test";
        OriginalBlob: Codeunit "Temp Blob";
        ExportedBlob: Codeunit "Temp Blob";
        ReportLayoutsPage: TestPage "Report Layouts";
        ExportedFileName: Text;
        WithEncoding: Boolean;
    begin
        EnsureNewLayoutsAreCleaned();
        CreateLayoutBlob(LayoutFormat, OriginalBlob);
        InsertLayoutForFileTest(LayoutFormat, LayoutName, MimeType, true, OriginalBlob, TenantReportLayout);
        BindSubscription(ReportLayoutsTest);
        ReportLayoutsTest.EnableExportCapture();

        ReportLayoutList.Get(TenantReportLayout."Report ID", TenantReportLayout.Name, TenantReportLayout."App ID");
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        if UpdateLayout then
            ReportLayoutsPage.UpdateAndExportLayout.Invoke()
        else
            ReportLayoutsPage.ExportLayout.Invoke();
        ReportLayoutsPage.Close();

        ReportLayoutsTest.GetExportedLayout(ExportedBlob, ExportedFileName, WithEncoding);
        Assert.AreEqual(ExpectedFileName, ExportedFileName, 'Incorrect exported file name or extension.');
        Assert.AreEqual(UpdateLayout, WithEncoding, 'Only a successful update must use the UTF8 export path.');
        if UpdateLayout then begin
            Assert.IsTrue(ExportedBlob.HasValue(), 'The updated export must contain a layout.');
            AssertLayoutCanBePrepared(LayoutFormat, ExportedBlob);
        end else
            AssertBlobEquals(OriginalBlob, ExportedBlob);

        UnbindSubscription(ReportLayoutsTest);
    end;

    local procedure OpenImportLayoutPage(var ReportLayoutsPage: TestPage "Report Layouts"; LayoutFormat: Text; CreateBlankLayout: Boolean; AvailableInAllCompanies: Boolean)
    begin
        LibraryVariableStorage.Enqueue(LayoutFormat);
        LibraryVariableStorage.Enqueue(CreateBlankLayout);
        LibraryVariableStorage.Enqueue(AvailableInAllCompanies);
        ReportLayoutsPage.OpenView();
    end;

    local procedure OpenFileTestLayout(var ReportLayoutsPage: TestPage "Report Layouts"; var ReportLayoutList: Record "Report Layout List")
    var
        EmptyGuid: Guid;
    begin
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
    end;

    local procedure FindExtensionLayout(var ReportLayoutList: Record "Report Layout List"; LayoutName: Text)
    begin
        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        ReportLayoutList.SetRange(Name, LayoutName);
        Assert.IsTrue(ReportLayoutList.FindFirst(), StrSubstNo('The extension-installed test layout %1 must exist.', LayoutName));
    end;

    local procedure SetExtensionRDLCLayoutsFilter(var ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        ReportLayoutList.SetFilter(Name, '%1|%2', RDLCLayoutNameLbl, SecondRDLCLayoutNameLbl);
    end;

    local procedure CreateLayoutBlob(LayoutFormat: Text; var LayoutBlob: Codeunit "Temp Blob")
    var
        ReportLayoutList: Record "Report Layout List";
        LayoutOutStream: OutStream;
    begin
        Clear(LayoutBlob);
        LayoutOutStream := LayoutBlob.CreateOutStream(TextEncoding::UTF8);
        if LayoutFormat = 'External' then
            LayoutOutStream.WriteText(AlternateLayoutTextTxt)
        else begin
            ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
            ReportLayoutList.SetRange("User Defined", false);
            case LayoutFormat of
                'Word':
                    begin
                        ReportLayoutList.SetRange(Name, WordLayoutNameLbl);
                        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
                    end;
                'RDLC':
                    begin
                        ReportLayoutList.SetRange(Name, RDLCLayoutNameLbl);
                        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::RDLC);
                    end;
                'Excel':
                    begin
                        ReportLayoutList.SetRange(Name, ExcelLayoutNameLbl);
                        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Excel);
                    end;
                else
                    Error('Unsupported test layout format: %1.', LayoutFormat);
            end;
            Assert.IsTrue(ReportLayoutList.FindFirst(), StrSubstNo('The test report must provide a built-in %1 layout.', LayoutFormat));
            ReportLayoutList.Layout.ExportStream(LayoutOutStream);
        end;
        Assert.IsTrue(LayoutBlob.HasValue(), 'The test layout fixture must not be empty.');
    end;

    local procedure InsertLayoutForFileTest(LayoutFormat: Text; LayoutName: Text[250]; MimeType: Text[255]; AvailableInAllCompanies: Boolean; LayoutBlob: Codeunit "Temp Blob"; var TenantReportLayout: Record "Tenant Report Layout")
    begin
        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := Report::TestReportLayoutsReport;
        TenantReportLayout.Name := LayoutName;
        TenantReportLayout.Description := NewLayoutNameTxt;
        case LayoutFormat of
            'Word':
                TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
            'RDLC':
                TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::RDLC;
            'Excel':
                TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Excel;
            'External':
                TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Custom;
            else
                Error('Unsupported test layout format: %1.', LayoutFormat);
        end;
        if not AvailableInAllCompanies then
            TenantReportLayout."Company Name" := CompanyName();
        TenantReportLayout."MIME Type" := MimeType;
        TenantReportLayout.Layout.ImportStream(LayoutBlob.CreateInStream(TextEncoding::UTF8), TenantReportLayout.Description);
        TenantReportLayout.Insert(true);
    end;

    local procedure GetLayoutFormatCaption(TenantReportLayout: Record "Tenant Report Layout"): Text
    begin
        if TenantReportLayout."Layout Format" = TenantReportLayout."Layout Format"::Custom then
            exit('External');
        exit(Format(TenantReportLayout."Layout Format"));
    end;

    local procedure GetFileTestLayoutType(LayoutFormat: Text): ReportLayoutType
    begin
        case LayoutFormat of
            'Word':
                exit(ReportLayoutType::Word);
            'RDLC':
                exit(ReportLayoutType::RDLC);
            'Excel':
                exit(ReportLayoutType::Excel);
            else
                Error('Unsupported test layout format: %1.', LayoutFormat);
        end;
    end;

    local procedure AssertLayoutCanBePrepared(LayoutFormat: Text; LayoutBlob: Codeunit "Temp Blob")
    var
        PreparedStream: InStream;
        ValidationResult: Boolean;
    begin
        ValidationResult := Report.ValidateAndPrepareLayout(Report::TestReportLayoutsReport, LayoutBlob.CreateInStream(TextEncoding::UTF8), PreparedStream, GetFileTestLayoutType(LayoutFormat));
        if not ValidationResult then
            Error(LayoutCouldNotBePreparedErr, GetLastErrorText());
    end;

    local procedure AssertBlobEquals(ExpectedBlob: Codeunit "Temp Blob"; ActualBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Assert.AreEqual(ExpectedBlob.Length(), ActualBlob.Length(), 'Incorrect layout file length.');
        Assert.AreEqual(
            Base64Convert.ToBase64(ExpectedBlob.CreateInStream(TextEncoding::UTF8)),
            Base64Convert.ToBase64(ActualBlob.CreateInStream(TextEncoding::UTF8)),
            'The complete layout file contents must match.');
    end;

    local procedure AssertLayoutUnchanged(OriginalLayout: Record "Tenant Report Layout"; OriginalBlob: Codeunit "Temp Blob")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ActualBlob: Codeunit "Temp Blob";
    begin
        Assert.IsTrue(
            TenantReportLayout.Get(OriginalLayout."Report ID", OriginalLayout.Name, OriginalLayout."App ID"),
            'The original layout must still exist.');
        Assert.AreEqual(OriginalLayout.SystemId, TenantReportLayout.SystemId, 'The original layout record must not be replaced.');
        Assert.AreEqual(OriginalLayout.Description, TenantReportLayout.Description, 'The description must not change.');
        Assert.AreEqual(OriginalLayout."Company Name", TenantReportLayout."Company Name", 'The company scope must not change.');
        Assert.AreEqual(OriginalLayout."Layout Format", TenantReportLayout."Layout Format", 'The layout format must not change.');
        Assert.AreEqual(OriginalLayout."Layout Subtype", TenantReportLayout."Layout Subtype", 'The layout subtype must not change.');
        Assert.AreEqual(OriginalLayout.ExcelLayoutMultipleDataSheets, TenantReportLayout.ExcelLayoutMultipleDataSheets, 'The Excel sheet configuration must not change.');
        Assert.AreEqual(OriginalLayout."MIME Type", TenantReportLayout."MIME Type", 'The MIME type must not change.');
        TenantReportLayout.Layout.ExportStream(ActualBlob.CreateOutStream(TextEncoding::UTF8));
        AssertBlobEquals(OriginalBlob, ActualBlob);
    end;

    [ModalPageHandler]
    procedure ImportLayoutModalHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    var
        LayoutFormat: Text;
        CreateBlankLayout: Boolean;
        AvailableInAllCompanies: Boolean;
    begin
        LayoutFormat := LibraryVariableStorage.DequeueText();
        CreateBlankLayout := LibraryVariableStorage.DequeueBoolean();
        AvailableInAllCompanies := LibraryVariableStorage.DequeueBoolean();
        ReportLayoutNewDialog.ReportID.SetValue(Report::TestReportLayoutsReport);
        ReportLayoutNewDialog.LayoutName.SetValue(NewLayoutNameTxt);
        ReportLayoutNewDialog.Description.SetValue(NewLayoutNameTxt);
        ReportLayoutNewDialog."Format Options".SetValue(LayoutFormat);
        ReportLayoutNewDialog.CreateEmptyLayout.SetValue(CreateBlankLayout);
        ReportLayoutNewDialog.AvailableInAllCompanies.SetValue(AvailableInAllCompanies);
        ReportLayoutNewDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelNewLayoutModalHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.Cancel().Invoke();
    end;

    [ConfirmHandler]
    procedure DeclineReplaceConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure CannotUpdateLayoutMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    procedure SetLayoutUpload(LayoutBlob: Codeunit "Temp Blob"; FileName: Text)
    begin
        Clear(UploadedLayoutBlob);
        CopyStream(UploadedLayoutBlob.CreateOutStream(TextEncoding::UTF8), LayoutBlob.CreateInStream(TextEncoding::UTF8));
        UploadedLayoutFileName := FileName;
        UseLayoutUpload := true;
    end;

    procedure GetUploadCount(): Integer
    begin
        exit(UploadCount);
    end;

    procedure EnableExportCapture()
    begin
        CaptureExport := true;
    end;

    procedure GetExportedLayout(var LayoutBlob: Codeunit "Temp Blob"; var FileName: Text; var WithEncoding: Boolean)
    begin
        Assert.AreEqual(1, ExportCount, 'The page action must export exactly one file.');
        Clear(LayoutBlob);
        CopyStream(LayoutBlob.CreateOutStream(TextEncoding::UTF8), ExportedLayoutBlob.CreateInStream(TextEncoding::UTF8));
        FileName := ExportedLayoutFileName;
        WithEncoding := ExportedWithEncoding;
        if WithEncoding then begin
            if (ExportedEncoding <> TextEncoding::UTF8) then
                Assert.Fail('An updated layout must be exported with UTF8 encoding.');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeBlobExport', '', false, false)]
    local procedure CaptureLayoutExport(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; var IsHandled: Boolean; var Result: Text)
    begin
        if (not CaptureExport) or IsHandled then
            exit;
        StoreLayoutExport(TempBlob, Name, false);
        Result := Name;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeBlobExportWithEncoding', '', false, false)]
    local procedure CaptureLayoutExportWithEncoding(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; Encoding: TextEncoding; var Result: Text; var IsHandled: Boolean)
    begin
        if (not CaptureExport) or IsHandled then
            exit;
        StoreLayoutExport(TempBlob, Name, true);
        ExportedEncoding := Encoding;
        Result := Name;
        IsHandled := true;
    end;

    local procedure StoreLayoutExport(LayoutBlob: Codeunit "Temp Blob"; FileName: Text; WithEncoding: Boolean)
    begin
        Clear(ExportedLayoutBlob);
        CopyStream(ExportedLayoutBlob.CreateOutStream(TextEncoding::UTF8), LayoutBlob.CreateInStream(TextEncoding::UTF8));
        ExportedLayoutFileName := FileName;
        ExportedWithEncoding := WithEncoding;
        ExportCount += 1;
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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual(InitialCompanyName, TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Layout is edited

        ReportLayoutsPage.EditLayout.Invoke();

        // Assert - Layout has been changed

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, EditedLayoutNameTxt, EmptyGuid), 'Edited layout should exist');

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

        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');

        Assert.AreEqual(NewLayoutNameTxt, TenantReportLayout.Name, 'Incorrect layout name.');

        Assert.AreEqual('', TenantReportLayout."Company Name", 'Layout should exist for all companies.');

        // Act - Set a selection
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
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
        UseLayoutUpload := false;
    end;

    [ModalPageHandler]
    procedure NewLayoutModalHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.LayoutName.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog.Description.Value := NewLayoutNameTxt;
        ReportLayoutNewDialog."Format Options".Value := 'External';

        Assert.AreEqual('Yes', ReportLayoutNewDialog.AvailableInAllCompanies.Value, 'The available in all companies toggle should be on by default.');

        ReportLayoutNewDialog.ReportID.Value := format(Report::TestReportLayoutsReport);
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

        ReportLayoutNewDialog.ReportID.Value := format(Report::TestReportLayoutsReport);
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

        ReportLayoutNewDialog.ReportID.Value := format(Report::TestReportLayoutsReport);
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
        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
        TenantReportLayout.DeleteAll();

        TenantReportLayoutOverride.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        UploadCount += 1;
        if UseLayoutUpload then begin
            UploadedLayoutBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
            UploadFileName := UploadedLayoutFileName;
            AlreadyUploaded := true;
            exit;
        end;

        TempBlob.CreateOutStream(TempOutStream, TextEncoding::UTF8);
        TempOutStream.WriteText(InsertedLayoutContextTxt, StrLen(InsertedLayoutContextTxt));

        TempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);

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
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist in the Tenant Report Layout table.');
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
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set status to Approved
        ReportLayoutsPage.SetApproved.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be Approved in the tenant table
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
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
        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set status to Retired
        ReportLayoutsPage.SetRetired.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be Retired in the tenant table
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
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

        ReportLayoutList.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // Act - Set to Approved then back to Draft
        ReportLayoutsPage.SetApproved.Invoke();

        // Verify intermediate state
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayout."Layout Status",
            'Layout status should be Approved after first transition.');

        ReportLayoutsPage.SetDraft.Invoke();
        ReportLayoutsPage.Close();

        // Assert - Status should be back to Draft
        Assert.IsTrue(TenantReportLayout.Get(Report::TestReportLayoutsReport, NewLayoutNameTxt, EmptyGuid), 'Layout should exist.');
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

        // The test report (Report::TestReportLayoutsReport) ships an RDLC layout via its rendering section, so it surfaces in
        // Report Layout List as an extension-installed layout (User Defined = false).
        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created for the extension layout.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'The Override Layout Status flag should be set.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The override should carry the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'No company-specific override should have been created.');

        // ...and no copy was made into the tenant table.
        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Seed the STATUS field specifically: the table is field-granular, so scope is resolved from
        // "Override Layout Status" and a description-only row would not establish it.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'Override Layout Status should be set on the global override.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should carry the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Global row owns the STATUS...
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // ...while a company row owns only the DESCRIPTION.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should have taken the Approved status.');

        // ...and the company row still overrides only the description, with no forked status.
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'The global override should still exist.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Layout Status", 'The Override Layout Status flag should be set.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The global override should carry the Approved status.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Description", 'The existing description override must be preserved.');

        // ...and no company-specific row was created.
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'The company-specific override should still exist.');
        Assert.AreEqual(
            Enum::"Report Layout Status"::Approved,
            TenantReportLayoutOverride."Layout Status",
            'The company override should have taken the Approved status.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
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

        // Report 139595 ships two RDLC extension layouts. All-companies is now the DEFAULT scope, so mixing
        // requires giving one layout a COMPANY-SPECIFIC status override; the untouched second layout
        // resolves to global. (Seeding a global override on one would no longer create a mix — both
        // sides would be global.)
        SetExtensionRDLCLayoutsFilter(ReportLayoutList);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two RDLC extension layouts.');
        ReportLayoutList.FindFirst();

        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutOverride."Company Name"));
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - batch over BOTH extension layouts (mixed scope)
        ReportLayoutList.Reset();
        SetExtensionRDLCLayoutsFilter(ReportLayoutList);
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

        SetExtensionRDLCLayoutsFilter(ReportLayoutList);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two RDLC extension layouts.');
        ReportLayoutList.FindFirst();

        // One layout already carries a GLOBAL status override; the other has none. Both are global scope.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
        TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
        TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
        TenantReportLayoutOverride."Company Name" := '';
        TenantReportLayoutOverride."Layout Status" := Enum::"Report Layout Status"::Draft;
        TenantReportLayoutOverride."Override Layout Status" := true;
        TenantReportLayoutOverride.Insert(true);

        // Act - batch over BOTH, with SelectedCompany never set
        ReportLayoutList.Reset();
        SetExtensionRDLCLayoutsFilter(ReportLayoutList);
        UpdateCount := ReportLayoutsImpl.SetLayoutStatusBatch(ReportLayoutList, Enum::"Report Layout Status"::Approved);

        // Assert - no spurious mixed-scope error, and both layouts updated globally
        Assert.AreEqual(2, UpdateCount, 'Both layouts should have been updated; a blank company must not split the scope.');
        ReportLayoutList.FindSet();
        repeat
            Assert.IsTrue(
                TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
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

        SetExtensionRDLCLayoutsFilter(ReportLayoutList);
        Assert.AreEqual(2, ReportLayoutList.Count(), 'The test report should ship two RDLC extension layouts.');

        // Act - batch over BOTH layouts, neither of which has any override yet
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        UpdateCount := ReportLayoutsImpl.SetLayoutStatusBatch(ReportLayoutList, Enum::"Report Layout Status"::Retired);

        // Assert - both were updated...
        Assert.AreEqual(2, UpdateCount, 'Both extension layouts should have been updated.');

        // ...each through a GLOBAL override, with no company-specific rows anywhere.
        ReportLayoutList.FindSet();
        repeat
            Assert.IsTrue(
                TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
                StrSubstNo(GlobalOverrideMissingErr, ReportLayoutList."Name"));
            Assert.AreEqual(
                Enum::"Report Layout Status"::Retired,
                TenantReportLayoutOverride."Layout Status",
                StrSubstNo(GlobalOverrideRetiredErr, ReportLayoutList."Name"));
            Assert.IsFalse(
                TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Make the layout obsolete via a global override, the way the everyday edit path would.
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode)
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a GLOBAL description override exists (and no company-specific one), no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override Description", 'The Override Description flag should be set.');
        Assert.AreEqual(EditedLayoutNameTxt, TenantReportLayoutOverride.Description, 'The override should carry the edited description.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
            'An everyday edit must not create a company-specific override.');

        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Act - Edit info (override mode), mark obsolete
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        // Assert - a global obsolete override exists, no tenant copy
        Assert.IsTrue(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override record should have been created.');
        Assert.IsTrue(TenantReportLayoutOverride."Override IsObsolete", 'The Override IsObsolete flag should be set.');
        Assert.IsTrue(TenantReportLayoutOverride.IsObsolete, 'The override should mark the layout obsolete.');

        TenantReportLayout.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.EditLayout.Invoke();
        ReportLayoutsPage.Close();

        TenantReportLayoutOverride.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
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
            TenantReportLayout.Get(Report::TestReportLayoutsReport, EditedLayoutNameTxt, EmptyGuid),
            'The copy should exist in Tenant Report Layout under its new name.');
        Assert.AreEqual('', TenantReportLayout."Company Name", 'The copy should be available in all companies by default.');

        TenantReportLayoutOverride.SetRange("Report ID", Report::TestReportLayoutsReport);
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
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
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''),
            'A global override should have been written.');
        Assert.IsFalse(
            TenantReportLayoutOverride.Get(Report::TestReportLayoutsReport, ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", CompanyName()),
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

        ReportLayoutList.SetRange("Report ID", Report::TestReportLayoutsReport);
        ReportLayoutList.SetRange("User Defined", false);
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'The extension-installed test layout should be present.');

        // Make the layout resolve to obsolete, the way the everyday edit path would
        TenantReportLayoutOverride.Init();
        TenantReportLayoutOverride."Report ID" := Report::TestReportLayoutsReport;
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
            TenantReportLayout.Get(Report::TestReportLayoutsReport, EditedLayoutNameTxt, EmptyGuid),
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
        UploadedLayoutBlob: Codeunit "Temp Blob";
        ExportedLayoutBlob: Codeunit "Temp Blob";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NewLayoutNameTxt: Label 'NewLayout';
        EditedLayoutNameTxt: Label 'EditedLayout';
        SampleTextTxt: Label 'ATAKLOA, TINWTABSBATF.';
        AlternateLayoutTextTxt: Label 'IWATSTGIFLBOTG.';
        RDLCLayoutNameLbl: Label 'MYLAYOUT', Locked = true;
        SecondRDLCLayoutNameLbl: Label 'MYLAYOUT2', Locked = true;
        WordLayoutNameLbl: Label 'WordLayout', Locked = true;
        ExcelLayoutNameLbl: Label 'ExcelLayout', Locked = true;
        GlobalOverrideMissingErr: Label 'A global override should exist for layout %1.', Comment = '%1 = layout name';
        GlobalOverrideApprovedErr: Label 'The global override for %1 should carry the Approved status.', Comment = '%1 = layout name';
        GlobalOverrideRetiredErr: Label 'The global override for %1 should carry the Retired status.', Comment = '%1 = layout name';
        CompanyOverrideUnexpectedErr: Label 'No company-specific override should exist for layout %1.', Comment = '%1 = layout name';
        LayoutCouldNotBePreparedErr: Label 'The layout could not be prepared. %1', Comment = '%1 = layout validation error';
        InsertedLayoutContextTxt: Text;
        UploadedLayoutFileName: Text;
        ExportedLayoutFileName: Text;
        UseLayoutUpload: Boolean;
        CaptureExport: Boolean;
        ExportedWithEncoding: Boolean;
        ExportedEncoding: TextEncoding;
        UploadCount: Integer;
        ExportCount: Integer;
}
