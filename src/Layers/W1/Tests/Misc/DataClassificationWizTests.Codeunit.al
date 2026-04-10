codeunit 135152 "Data Classification Wiz. Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Data Classification] [Wizard] [UI]
    end;

    var
        LibraryAssert: Codeunit Assert;
        DataClassificationWizTests: Codeunit "Data Classification Wiz. Tests";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ReviewFieldsErr: Label 'You must review the classifications for fields before you can continue.';
        ReviewSimilarFieldsErr: Label 'You must review the classifications for similar fields before you can continue.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestExportScenario()
    var
        DataClassificationWizard: TestPage "Data Classification Wizard";
    begin
        // [SCENARIO] User can export data classifications to an Excel worksheet
        BindSubscription(DataClassificationWizTests);

        // [GIVEN] DataSensitivity table is populated with data that is not yet classified
        Initialize();

        LibraryLowerPermissions.SetO365Basic();
        VerifyFirstTwoPages(DataClassificationWizard);

        // [WHEN] An export method is selected
        DataClassificationWizard."ExportModeSelected".SetValue(true);

        // [THEN] The Next action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected enabled');

        // [WHEN] The final page displays
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] The Next action is not available
        LibraryAssert.IsFalse(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected disabled');

        // [THEN] The Finish action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionFinish.Enabled(), 'Action Finish was expected enabled');

        // [WHEN] The Back action is used
        DataClassificationWizard.ActionBack.Invoke();

        // [THEN] Display the second page
        LibraryAssert.IsTrue(DataClassificationWizard."ExportModeSelected".Visible(), 'The second page was expected to appear');

        UnbindSubscription(DataClassificationWizTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestImportScenario()
    var
        DataClassificationWizard: TestPage "Data Classification Wizard";
    begin
        // [SCENARIO] User can import data classifications from an Excel worksheet
        BindSubscription(DataClassificationWizTests);

        // [GIVEN] DataSensitivity table is populated with data that is not yet classified
        Initialize();

        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] An Excel worksheet that contains data classifications
        // Happens on the Event Subscriber OnUploadExcelSheet

        VerifyFirstTwoPages(DataClassificationWizard);

        // [WHEN] An import method is selected
        DataClassificationWizard.ImportModeSelected.SetValue(true);

        // [THEN] The Next action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected enabled');

        // [WHEN] The final page displays
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] The Next action is not available
        LibraryAssert.IsFalse(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected disabled');

        // [THEN] The Finish action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionFinish.Enabled(), 'Action Finish was expected enabled');

        // [WHEN] The Back action is used
        DataClassificationWizard.ActionBack.Invoke();

        // [THEN] Display the second page
        LibraryAssert.IsTrue(DataClassificationWizard."ExportModeSelected".Visible(), 'The second page was expected to appear');

        UnbindSubscription(DataClassificationWizTests);
    end;

    [Test]
    [HandlerFunctions('DataClassificationWorksheetHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestExpertScenario()
    var
        DataClassificationWizard: TestPage "Data Classification Wizard";
    begin
        // [SCENARIO] User can classify the sensitivity of the data in fields by using an assisted setup guide

        // [GIVEN] DataSensitivity table is populated with data that is not yet classified
        Initialize();

        LibraryLowerPermissions.SetO365Setup();

        VerifyFirstTwoPages(DataClassificationWizard);

        // [WHEN] An export method is selected
        DataClassificationWizard.ExpertModeSelected.SetValue(true);

        // [THEN] The Next action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected enabled');

        // [WHEN] The next page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] Display the page where the user can classify data based on its use
        LibraryAssert.IsTrue(DataClassificationWizard.LedgerEntriesDefaultClassification.Visible(), 'Control was expected visible');
        LibraryAssert.IsTrue(DataClassificationWizard.SetupTablesDefaultClassification.Visible(), 'Control was expected visible');
        LibraryAssert.IsTrue(DataClassificationWizard.TemplatesDefaultClassification.Visible(), 'Control was expected visible');

        // [WHEN] The next page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] Display the page where the user can choose the tables that he wants to classify
        LibraryAssert.IsTrue(DataClassificationWizard.Entity.Visible(), 'Control was expected visible');
        DataClassificationWizard.First();
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);
        DataClassificationWizard.Next();
        DataClassificationWizard.Include.SetValue(false);

        // [WHEN] The next page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] Display the page where the user can review the classifications for the data in fields
        LibraryAssert.IsTrue(DataClassificationWizard.Status.Visible(), 'Control was expected visible');

        // [WHEN] The Next  action is used
        // [THEN] An error is thrown
        asserterror DataClassificationWizard.ActionNext.Invoke();
        LibraryAssert.ExpectedError(ReviewFieldsErr);

        // [WHEN] The fields are reviewed and the user can continue to the next page in the assisted setup guide
        DataClassificationWizard.First();
        DataClassificationWizard.Fields.DrillDown();

        // [WHEN] The next page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] Display the page where the user can review the classifications for similar field
        LibraryAssert.IsTrue(DataClassificationWizard."Status 2".Visible(), 'Control was expected visible');

        // [WHEN] The Next  action is used
        // [THEN] An error is thrown
        asserterror DataClassificationWizard.ActionNext.Invoke();
        LibraryAssert.ExpectedError(ReviewSimilarFieldsErr);

        // [WHEN] The fields are reviewed and the user can continue to the next page in the assisted setup guide
        DataClassificationWizard.First();
        DataClassificationWizard."Similar Fields Label".DrillDown();

        // [WHEN] The next page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] The final page is displayed
        LibraryAssert.IsTrue(DataClassificationWizard.ActionFinish.Enabled(), 'Action Finish was expected enabled');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classif. Import/Export", 'OnOpenExcelSheet', '', false, false)]
    local procedure OnOpenExcelSheet(var ExcelBuffer: Record "Excel Buffer"; var ShouldOpenFile: Boolean)
    begin
        ShouldOpenFile := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classif. Import/Export", 'OnUploadExcelSheet', '', false, false)]
    local procedure OnUploadExcelSheet(var ExcelBuffer: Record "Excel Buffer"; var ShouldUploadFile: Boolean)
    begin
        ShouldUploadFile := false;
        FillExcelBuffer(ExcelBuffer);
    end;

    local procedure VerifyFirstTwoPages(var DataClassificationWizard: TestPage "Data Classification Wizard")
    begin
        // [WHEN] The user starts the assisted setup guide
        DataClassificationWizard.OpenEdit();

        // [THEN] The Back action is not available
        LibraryAssert.IsFalse(DataClassificationWizard.ActionBack.Enabled(), 'Action Back was expected disabled');

        // [THEN] The Finish action is not available
        LibraryAssert.IsFalse(DataClassificationWizard.ActionFinish.Enabled(), 'Action Finish was expected disabled');

        // [THEN] The Next action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected enabled');

        // [WHEN] The second page is displayed
        DataClassificationWizard.ActionNext.Invoke();

        // [THEN] The Back action is available
        LibraryAssert.IsTrue(DataClassificationWizard.ActionBack.Enabled(), 'Action Back was expected enabled');

        // [THEN] The Next action is not available
        LibraryAssert.IsFalse(DataClassificationWizard.ActionNext.Enabled(), 'Action Next was expected disabled');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataClassificationWorksheetHandler(var DataClassificationWorksheet: Page "Data Classification Worksheet"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    local procedure Initialize()
    var
        DataSensitivity: Record "Data Sensitivity";
    begin
        DataSensitivity.DeleteAll();

        DataSensitivity."Company Name" := CompanyName;
        DataSensitivity."Table No" := 13;
        DataSensitivity."Field No" := 1;
        DataSensitivity."Data Sensitivity" := DataSensitivity."Data Sensitivity"::Unclassified;
        DataSensitivity.Insert();

        DataSensitivity."Company Name" := CompanyName;
        DataSensitivity."Table No" := 13;
        DataSensitivity."Field No" := 2;
        DataSensitivity."Data Sensitivity" := DataSensitivity."Data Sensitivity"::Unclassified;
        DataSensitivity.Insert();
    end;

    [Scope('OnPrem')]
    procedure FillExcelBuffer(var ExcelBuffer: Record "Excel Buffer")
    begin
        InsertValueInExcelBuffer(ExcelBuffer, 1, 1, 'Header 1');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 2, 'Header 2');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 3, 'Header 3');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 4, 'Header 4');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 5, 'Header 5');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 6, 'Header 6');

        InsertValueInExcelBuffer(ExcelBuffer, 2, 1, '3');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 2, '1');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 3, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 4, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 5, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 6, 'Normal');

        InsertValueInExcelBuffer(ExcelBuffer, 3, 1, '3');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 2, '2');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 3, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 4, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 5, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 6, 'Personal');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InsertValueInExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColumnNo: Integer; Value: Text[250])
    begin
        ExcelBuffer."Row No." := RowNo;
        ExcelBuffer."Column No." := ColumnNo;
        ExcelBuffer."Cell Value as Text" := Value;
        ExcelBuffer.Insert();
    end;
}

