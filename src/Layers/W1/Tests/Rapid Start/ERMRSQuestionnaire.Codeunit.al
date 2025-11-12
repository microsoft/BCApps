codeunit 136600 "ERM RS Questionnaire"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Questionnaire]
        isInitialized := false;
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        FileMgt: Codeunit "File Management";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        isInitialized: Boolean;
        CustomerMustMatchError: Label 'Number of %1 must match.';
        QuestionnaireError: Label 'The record in table %1 already exists. Identification fields and values:';
        QuestionnaireRenameError: Label 'You cannot rename a configuration questionnaire.';
        MustNotExistError: Label 'Record %1 in %2 must not exist.';
        ValueMustEqualError: Label '%1 in %2 must equal to %3.';
        RecordNotImportedError: Label '%1 was not imported.';
        AnswerNotAppliedError: Label 'The answer was not applied.';
        XMLCodeNotGeneratedError: Label '%1 was not generated in XML document.';
        SimpleXMLNotImportedError: Label 'Simple XML that contains only Config. Questionnaire definition was not imported.';
        QuestionAreaRenameError: Label 'You cannot rename a question area.';
        ExcelControlVisibilityErr: Label 'Wrong Excel control visibility';

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireExcelImportExportWindowsClientUI()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ConfigQuestionnairePage: TestPage "Config. Questionnaire";
    begin
        // [FEATURE] [Windows Client] [Excel] [UI]
        // [SCENARIO 216173] Excel/XML Import/Export controls are visible in Windows client
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);

        ConfigQuestionnairePage.OpenEdit();
        ConfigQuestionnairePage.GotoRecord(ConfigQuestionnaire);
        Assert.IsTrue(ConfigQuestionnairePage.ExportToExcel.Visible(), ExcelControlVisibilityErr);
        Assert.IsTrue(ConfigQuestionnairePage.ExportToXML.Visible(), ExcelControlVisibilityErr);
        Assert.IsTrue(ConfigQuestionnairePage.ImportFromXML.Visible(), ExcelControlVisibilityErr);
        ConfigQuestionnairePage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireExcelImportExportWebClientUI()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ConfigQuestionnairePage: TestPage "Config. Questionnaire";
    begin
        // [FEATURE] [Web Client] [Excel] [UI]
        // [SCENARIO 216173] Excel/XML Import/Export controls are visible in Web client
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);

        ConfigQuestionnairePage.OpenEdit();
        ConfigQuestionnairePage.GotoRecord(ConfigQuestionnaire);
        Assert.IsTrue(ConfigQuestionnairePage.ExportToExcel.Visible(), ExcelControlVisibilityErr);
        Assert.IsTrue(ConfigQuestionnairePage.ExportToXML.Visible(), ExcelControlVisibilityErr);
        Assert.IsTrue(ConfigQuestionnairePage.ImportFromXML.Visible(), ExcelControlVisibilityErr);
        ConfigQuestionnairePage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireSetupExportXML()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        FilePath: Text;
    begin
        // [SCENARIO] Questionnaire Setup can be exported to XML.

        // [GIVEN] Create new Config. Questionnaire, Question Area, update Questions and input Comments.
        SetupQuestionnaireTestScenarioWithComments(ConfigQuestionnaire, ConfigQuestionArea, FindTable());

        // [WHEN] Export Questionnaire to XML.
        QuestionnaireManagement.SetCalledFromCode();
        FilePath := FileMgt.ServerTempFileName('xml');
        QuestionnaireManagement.ExportQuestionnaireAsXML(FilePath, ConfigQuestionnaire);

        // [THEN] Check the Questionnaire Setup is exported to XML.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        Erase(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireSetupImportXML()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        TempConfigQuestion: Record "Config. Question" temporary;
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        FilePath: Text;
    begin
        // [SCENARIO] Questionnaire Setup can be imported from XML.

        // [GIVEN] Create new Config. Questionnaire, Question Area, update Questions and input Comments.
        // [GIVEN] Copy Question in temporary record, export Questionnaire to XML and delete it.
        SetupQuestionnaireTestScenarioWithComments(ConfigQuestionnaire, ConfigQuestionArea, FindTable());
        CopyQuestion(TempConfigQuestion, ConfigQuestionArea);

        QuestionnaireManagement.SetCalledFromCode();
        FilePath := FileMgt.ServerTempFileName('xml');
        QuestionnaireManagement.ExportQuestionnaireAsXML(CopyStr(FilePath, 1, 250), ConfigQuestionnaire);
        ConfigQuestionnaire.Delete(true);

        // [WHEN] Import Questionnaire from XML.
        QuestionnaireManagement.ImportQuestionnaireAsXML(CopyStr(FilePath, 1, 250));

        // [THEN] Check the Questionnaire Setup imported from XML.
        ConfigQuestionnaire.Get(ConfigQuestionnaire.Code);
        ConfigQuestionArea.Get(ConfigQuestionArea."Questionnaire Code", ConfigQuestionArea.Code);
        VerifyQuestionsImported(TempConfigQuestion);

        Erase(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAnswersQuestionnaireSetup()
    var
        Customer: Record Customer;
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        CustomerCount: Integer;
    begin
        // [SCENARIO] Setups are updated using Apply Answers from Config. Questionnaires.

        // [GIVEN] Create new Config. Questionnaire, Question Area for Customer table, update Questions.
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, DATABASE::Customer);
        CustomerCount := Customer.Count();

        // [WHEN] Input random Answer for Name field of Customer table and Apply Answers.
        ConfigQuestion.SetRange(Question, Customer.FieldCaption(Name) + '?');  // Every Question has a ? symbol at the end.
        FindQuestion(ConfigQuestion, ConfigQuestionArea);
        InputAnswer(ConfigQuestion);
        QuestionnaireManagement.ApplyAnswers(ConfigQuestionnaire);

        // [THEN] Check that new Customer is created having Name as Answer inputted.
        Assert.AreEqual(CustomerCount + 1, Customer.Count, StrSubstNo(CustomerMustMatchError, Customer.TableCaption()));
        Customer.SetRange(Name, ConfigQuestion.Answer);
        Assert.IsTrue(Customer.FindFirst(), AnswerNotAppliedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateConfigQuestionnaire()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        // [SCENARIO] a new Config. Questionnaire can be created.

        // 1. Setup.
        Initialize();

        // [WHEN] Create new Config. Questionnaire.
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        // [THEN] Check the Config. Questionnaire has been created.
        ConfigQuestionnaire.Get(ConfigQuestionnaire.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigQuestionnaireExistsError()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        // [SCENARIO] the application generates an error on inserting Config. Questionnaire with existing code.

        // [GIVEN] Create new Config. Questionnaire.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        // [WHEN] Try to insert another Config. Questionnaire with the same code.
        asserterror InsertQuestionnaireSameCode(ConfigQuestionnaire.Code);

        // [THEN] Check the application generates an error as: "The Config. Questionnaire already exists.".
        Assert.ExpectedError(StrSubstNo(QuestionnaireError, ConfigQuestionnaire.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameConfigQuestionnaireError()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        // [SCENARIO] the application generates an error on renaming a Config. Questionnaire.

        // [GIVEN] Create new Config. Questionnaire.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        // [WHEN] Try to rename the Config. Questionnaire.
        asserterror ConfigQuestionnaire.Rename(
            CopyStr(
              LibraryUtility.GenerateRandomCode(ConfigQuestionnaire.FieldNo(Code), DATABASE::"Config. Questionnaire"),
              1,
              LibraryUtility.GetFieldLength(DATABASE::"Config. Questionnaire", ConfigQuestionnaire.FieldNo(Code))));

        // [THEN] Check the application generates an error as: "You cannot rename a Config. Questionnaire".
        Assert.ExpectedError(QuestionnaireRenameError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyConfigQuestionnaire()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        NewDescription: Text[30];
    begin
        // [SCENARIO] a Config. Questionnaire can be modified.

        // [GIVEN] Create new Config. Questionnaire.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        // [WHEN] Modify the Config. Questionnaire.
        NewDescription := CopyStr(
            LibraryUtility.GenerateRandomCode(ConfigQuestionnaire.FieldNo(Description), DATABASE::"Config. Questionnaire"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Config. Questionnaire", ConfigQuestionnaire.FieldNo(Description)));
        ModifyDescriptionQuestionnaire(ConfigQuestionnaire, NewDescription);

        // [THEN] Check that the Description was modified correctly.
        ConfigQuestionnaire.Get(ConfigQuestionnaire.Code);
        ConfigQuestionnaire.TestField(Description, NewDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteConfigQuestionnaire()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireCode: Code[10];
        QuestionAreaCode: Code[10];
    begin
        // [SCENARIO] a Config. Questionnaire can be deleted.

        // [GIVEN] Create new Config. Questionnaire, Question Area, update Questions.
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, FindTable());

        // [WHEN] Delete Config. Questionnaire.
        QuestionnaireCode := ConfigQuestionnaire.Code;
        QuestionAreaCode := ConfigQuestionArea.Code;
        ConfigQuestionnaire.Delete(true);

        // [THEN] Check the Config. Questionnaire gets deleted along with related tables records.
        Assert.IsFalse(
          ConfigQuestionnaire.Get(QuestionnaireCode),
          StrSubstNo(MustNotExistError, QuestionnaireCode, ConfigQuestionnaire.TableCaption()));
        Assert.IsFalse(
          ConfigQuestionArea.Get(QuestionnaireCode, QuestionAreaCode),
          StrSubstNo(MustNotExistError, QuestionAreaCode, ConfigQuestionArea.TableCaption()));

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        Assert.IsFalse(
          ConfigQuestion.FindFirst(),
          StrSubstNo(MustNotExistError, QuestionAreaCode, ConfigQuestion.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAnswerForFieldNotExisting()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
    begin
        // [SCENARIO] answer can be applied for a field that does not exist.

        // [GIVEN] Create new Config. Questionnaire, Question Area, Question.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());
        LibraryRapidStart.CreateQuestion(ConfigQuestion, ConfigQuestionArea);

        // [WHEN] Input and apply answer.
        InputAnswer(ConfigQuestion);
        asserterror QuestionnaireManagement.ApplyAnswers(ConfigQuestionnaire);

        // [THEN] Check that the application generates an error on applying answers for a field that does not exist.
        Assert.ExpectedErrorCannotFind(Database::Field);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAnswerHavingWrongType()
    var
        Customer: Record Customer;
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        CustomerCount: Integer;
    begin
        // [SCENARIO] the Setup table is updated if Answer is not one of the Answer Options or wrong type.

        // [GIVEN] Create new Config. Questionnaire, Question Area for Customer table, update Questions.
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, DATABASE::Customer);
        CustomerCount := Customer.Count();

        // [WHEN] Input Answer having wrong type for Print Statements Boolean field of Customer table and apply.
        ConfigQuestion.SetRange(Question, Customer.FieldCaption("Print Statements") + '?');  // Every Question has a ? symbol at the end.
        FindQuestion(ConfigQuestion, ConfigQuestionArea);
        InputAnswerOption(ConfigQuestion, ConfigQuestion."Questionnaire Code");

        QuestionnaireManagement.ApplyAnswers(ConfigQuestionnaire);

        // [THEN] Check that new Customer is created.
        Assert.AreEqual(CustomerCount + 1, Customer.Count, StrSubstNo(CustomerMustMatchError, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyOptionAnswer()
    var
        GLAccount: Record "G/L Account";
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] the answer in an option field can be applied

        // [GIVEN] Create new Config. Questionnaire, Question Area for G/L Account table, update Questions.
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, DATABASE::"G/L Account");

        // [WHEN] Set the account as Posting and the answer to be applies to this account as Heading.
        CreatePostingGLAccount(GLAccount);
        GLAccountNo := GLAccount."No.";

        InputAnswerValue(ConfigQuestion, ConfigQuestionnaire.Code, ConfigQuestionArea.Code, GLAccount.FieldNo("No."), GLAccount."No.");
        InputAnswerValue(
          ConfigQuestion, ConfigQuestionnaire.Code, ConfigQuestionArea.Code, GLAccount.FieldNo("Account Type"),
          Format(GLAccount."Account Type"::Heading));

        QuestionnaireManagement.ApplyAnswers(ConfigQuestionnaire);

        // [THEN] Check that the answer is applied and the account type is changed
        GLAccount.Get(GLAccountNo);
        Assert.AreEqual(GLAccount."Account Type"::Heading, GLAccount."Account Type", AnswerNotAppliedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutogenerateQuestionsForFields()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestionArea2: Record "Config. Question Area";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
    begin
        // [SCENARIO] autogeneration of questions for the fields not mentioned in the Question Area.

        // [GIVEN] Create new Config. Questionnaire, two new Question Areas.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());
        CreateQuestionAreaWithTableID(ConfigQuestionArea2, ConfigQuestionnaire.Code, FindNextTable(ConfigQuestionArea."Table ID"));

        // [WHEN] Update Questionnaire.
        QuestionnaireManagement.UpdateQuestionnaire(ConfigQuestionnaire);

        // [THEN] Check that the Questions have been auto-generated properly.
        VerifyAutogeneratedQuestions(ConfigQuestionArea);
        VerifyAutogeneratedQuestions(ConfigQuestionArea2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateQuestionsForQuestionArea()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
    begin
        // [SCENARIO] Update questions works properly for selected Question Area.

        // [GIVEN] Create new Config. Questionnaire, a new Question Area.
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, FindTable());

        // 2. Verify: Check that the Questions have been auto-generated properly.
        VerifyAutogeneratedQuestions(ConfigQuestionArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleXMLImport_XMLQuestionnaireWithValidCode_Ok()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RootXmlNode: DotNet XmlNode;
        QuestionnaireCode: Code[10];
        XMLText: Text[1024];
    begin
        Initialize();

        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        QuestionnaireCode := ConfigQuestionnaire.Code;

        CreateQuestionnaireXML(XMLText, ConfigQuestionnaire);

        XMLDOMManagement.LoadXMLNodeFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?>' + XMLText, RootXmlNode);

        ConfigQuestionnaire.Delete();
        QuestionnaireManagement.ImportQuestionnaireXMLDocument(RootXmlNode.OwnerDocument);

        Assert.IsTrue(ConfigQuestionnaire.Get(QuestionnaireCode), SimpleXMLNotImportedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLImport_QuestionnaireWithQuestion_Ok()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RootXmlNode: DotNet XmlNode;
        QuestionnaireCode: Code[10];
        QuestionAreaCode: Code[10];
        QuestionNo: Integer;
        XMLText: Text[1024];
    begin
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, FindTable());

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionnaire.Code);
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        ConfigQuestion.FindFirst();

        QuestionnaireCode := ConfigQuestionnaire.Code;
        QuestionAreaCode := ConfigQuestionArea.Code;
        QuestionNo := ConfigQuestion."No.";

        CreateQuestionXML(XMLText, ConfigQuestion, true);
        CreateQuestionAreaXML(XMLText, ConfigQuestionArea, true);
        CreateQuestionnaireXML(XMLText, ConfigQuestionnaire);

        XMLDOMManagement.LoadXMLNodeFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?>' + XMLText, RootXmlNode);

        ConfigQuestionnaire.Delete(true);

        ConfigQuestion.Reset();
        QuestionnaireManagement.ImportQuestionnaireXMLDocument(RootXmlNode.OwnerDocument);

        Assert.IsTrue(
          ConfigQuestion.Get(QuestionnaireCode, QuestionAreaCode, QuestionNo), StrSubstNo(RecordNotImportedError, ConfigQuestion.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLImport_QuestionnaireWithOption_Ok()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestion: Record "Config. Question";
        Customer: Record Customer;
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        QuestionnaireXML: DotNet XmlDocument;
        QuestionnaireCode: Code[10];
        QuestionAreaCode: Code[10];
        QuestionNo: Integer;
    begin
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, DATABASE::Customer);

        InputAnswerValue(
          ConfigQuestion, ConfigQuestionnaire.Code, ConfigQuestionArea.Code, Customer.FieldNo(Blocked), Format(Customer.Blocked::All));

        QuestionnaireCode := ConfigQuestionnaire.Code;
        QuestionAreaCode := ConfigQuestionArea.Code;
        QuestionNo := ConfigQuestion."No.";

        QuestionnaireXML := QuestionnaireXML.XmlDocument();
        QuestionnaireManagement.GenerateQuestionnaireXMLDocument(QuestionnaireXML, ConfigQuestionnaire);

        ConfigQuestion.Reset();
        ConfigQuestion.DeleteAll();
        QuestionnaireManagement.ImportQuestionnaireXMLDocument(QuestionnaireXML);

        ConfigQuestion.Get(QuestionnaireCode, QuestionAreaCode, QuestionNo);
        Assert.AreEqual(Format(Customer.Blocked::All), ConfigQuestion.Answer, AnswerNotAppliedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleQuestionnaireXMLGenerate_XMLDocContainsValidCode_Ok()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        XMLDocument: DotNet XmlDocument;
        XMLQuestionnaireCode: Code[20];
    begin
        Initialize();

        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);

        XMLDocument := XMLDocument.XmlDocument();
        QuestionnaireManagement.GenerateQuestionnaireXMLDocument(XMLDocument, ConfigQuestionnaire);

        XMLQuestionnaireCode := GetXMLNodeText(XMLDocument, ConfigQuestionnaire.FieldName(Code));

        Assert.AreEqual(
          XMLQuestionnaireCode, ConfigQuestionnaire.Code, StrSubstNo(XMLCodeNotGeneratedError, ConfigQuestionnaire.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireXMLGenerate_QuestionnaireWithQuestionArea_Ok()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        XMLDocument: DotNet XmlDocument;
        XMLQuestionAreaCode: Code[20];
    begin
        Initialize();

        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());

        XMLDocument := XMLDocument.XmlDocument();
        QuestionnaireManagement.GenerateQuestionnaireXMLDocument(XMLDocument, ConfigQuestionnaire);

        XMLQuestionAreaCode :=
          GetXMLQuestionnaireChildNodeText(XMLDocument, QuestionnaireManagement.GetElementName(ConfigQuestionArea.FieldName(Code)));

        Assert.AreEqual(
          XMLQuestionAreaCode, ConfigQuestionArea.Code, StrSubstNo(XMLCodeNotGeneratedError, ConfigQuestionArea.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireXMLGenerate_QuestionnaireWithQuestions_Ok()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        XMLDocument: DotNet XmlDocument;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        QuestionnaireCode: Code[10];
        QuestionAreaCode: Code[10];
        InnerText: Text;
    begin
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, FindTable());

        XMLDocument := XMLDocument.XmlDocument();
        QuestionnaireManagement.GenerateQuestionnaireXMLDocument(XMLDocument, ConfigQuestionnaire);

        QuestionnaireCode := CopyStr(GetXMLNodeText(XMLDocument, ConfigQuestionnaire.FieldName(Code)), 1, MaxStrLen(QuestionnaireCode));

        GetXMLQuestionnaireChildNodes(XMLDocument, XMLNodes);
        QuestionAreaCode :=
          CopyStr(
            GetXMLChildNodeText(XMLNodes, QuestionnaireManagement.GetElementName(ConfigQuestionArea.FieldName(Code))), 1,
            MaxStrLen(QuestionAreaCode));

        XMLNode := XMLNodes.Item(0);
        XMLNodes := XMLNode.SelectNodes('ConfigQuestion');
        XMLNode := XMLNodes.Item(0);
        XMLNode := XMLNode.SelectSingleNode(QuestionnaireManagement.GetElementName(ConfigQuestion.FieldName("No.")));

        InnerText := XMLNode.InnerText;
        Assert.IsTrue(
          ConfigQuestion.Get(QuestionnaireCode, QuestionAreaCode, InnerText),
          StrSubstNo(XMLCodeNotGeneratedError, ConfigQuestion.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteConfigQuestionArea()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionnaireManagement: Codeunit "Questionnaire Management";
        QuestionAreaCode: Code[10];
    begin
        // [SCENARIO] a Config. Question Area can be deleted.

        // [GIVEN] Create new Config. Questionnaire, Question Area, update Questions.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());
        QuestionnaireManagement.UpdateQuestions(ConfigQuestionArea);

        // [WHEN] Delete Config. Question Area.
        QuestionAreaCode := ConfigQuestionArea.Code;
        ConfigQuestionArea.Delete(true);

        // [THEN] Check the Config. Question Area gets deleted along with related tables records.
        Assert.IsFalse(
          ConfigQuestionArea.Get(ConfigQuestionnaire.Code, QuestionAreaCode),
          StrSubstNo(MustNotExistError, ConfigQuestionArea.TableCaption(), QuestionAreaCode));

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        Assert.IsFalse(
          ConfigQuestion.FindFirst(),
          StrSubstNo(MustNotExistError, ConfigQuestion.TableName, QuestionAreaCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameConfigQuestionAreaError()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
    begin
        // [SCENARIO] the application generates an error on renaming a Config. Question Area.

        // [GIVEN] Create new Config. Questionnaire.
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());

        // [WHEN] Try to rename the Config. Question Area.
        asserterror ConfigQuestionArea.Rename(ConfigQuestionnaire.Code,
            LibraryUtility.GenerateRandomCode(ConfigQuestionArea.FieldNo(Code), DATABASE::"Config. Question Area"));

        // [THEN] Check the application generates an error as: "You cannot rename a Question Area.".
        Assert.ExpectedError(QuestionAreaRenameError);
    end;

    local procedure CopyQuestion(var ConfigQuestionOld: Record "Config. Question"; ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
    begin
        FindQuestion(ConfigQuestion, ConfigQuestionArea);
        repeat
            ConfigQuestionOld.Init();
            ConfigQuestionOld := ConfigQuestion;
            ConfigQuestionOld.Insert();
        until ConfigQuestion.Next() = 0;
    end;

    local procedure CreateQuestionAreaWithTableID(var ConfigQuestionArea: Record "Config. Question Area"; QuestionnaireCode: Code[10]; TableID: Integer)
    begin
        LibraryRapidStart.CreateQuestionArea(ConfigQuestionArea, QuestionnaireCode);
        ConfigQuestionArea.Validate("Table ID", TableID);
        ConfigQuestionArea.Modify(true);
    end;

    local procedure FindTable(): Integer
    var
        AllObj: Record AllObj;
    begin
        // Find the first table of the database. Random cannot be used as some tables have only one field.
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.FindFirst();
        exit(AllObj."Object ID");
    end;

    local procedure FindNextTable(ID: Integer): Integer
    var
        AllObj: Record AllObj;
    begin
        // Find the first table of the database. Random cannot be used as some tables have only one field.
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetFilter("Object ID", '<>%1', ID);
        AllObj.FindFirst();
        exit(AllObj."Object ID");
    end;

    local procedure FindQuestion(var ConfigQuestion: Record "Config. Question"; ConfigQuestionArea: Record "Config. Question Area")
    begin
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        ConfigQuestion.FindSet();
    end;

    local procedure InputAnswerValue(var ConfigQuestion: Record "Config. Question"; QuestionnaireCode: Code[10]; QuestionAreaCode: Code[10]; FieldID: Integer; AnswerValue: Text[250])
    begin
        ConfigQuestion.SetRange("Questionnaire Code", QuestionnaireCode);
        ConfigQuestion.SetRange("Question Area Code", QuestionAreaCode);
        ConfigQuestion.SetRange("Field ID", FieldID);
        ConfigQuestion.FindFirst();

        ConfigQuestion.Validate(Answer, AnswerValue);
        ConfigQuestion.Modify(true);
    end;

    local procedure InputAnswer(var ConfigQuestion: Record "Config. Question")
    begin
        // Validating Primary Key as Answer as value is not important.
        ConfigQuestion.Validate(
          Answer, ConfigQuestion."Questionnaire Code" + ConfigQuestion."Question Area Code" + Format(ConfigQuestion."No."));
        ConfigQuestion.Modify(true);
    end;

    local procedure InputAnswerOption(ConfigQuestion: Record "Config. Question"; AnswerOption: Text[250])
    begin
        ConfigQuestion.Validate("Answer Option", AnswerOption);
        ConfigQuestion.Modify(true);
    end;

    local procedure InputComments(ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
    begin
        FindQuestion(ConfigQuestion, ConfigQuestionArea);
        repeat
            // Validating Primary Key as comment as value is not important.
            ConfigQuestion.Validate(
              Reference, ConfigQuestion."Questionnaire Code" + ConfigQuestion."Question Area Code" + Format(ConfigQuestion."No."));
            ConfigQuestion.Modify(true);
        until ConfigQuestion.Next() = 0;
    end;

    local procedure SetupQuestionnaireTestScenario(var ConfigQuestionnaire: Record "Config. Questionnaire"; var ConfigQuestionArea: Record "Config. Question Area"; TableID: Integer)
    begin
        Initialize();
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, TableID);
        QuestionnaireManagement.UpdateQuestions(ConfigQuestionArea);
    end;

    local procedure SetupQuestionnaireTestScenarioWithComments(var ConfigQuestionnaire: Record "Config. Questionnaire"; var ConfigQuestionArea: Record "Config. Question Area"; TableID: Integer)
    begin
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, TableID);
        InputComments(ConfigQuestionArea);
    end;

    local procedure InsertQuestionnaireSameCode("Code": Code[10])
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        ConfigQuestionnaire.Init();
        ConfigQuestionnaire.Validate(Code, Code);
        ConfigQuestionnaire.Insert(true);  // Cannot be done through Library as we need same code.
        Commit();  // Commit is required by the test case.
    end;

    local procedure ModifyDescriptionQuestionnaire(ConfigQuestionnaire: Record "Config. Questionnaire"; Description: Text[30])
    begin
        ConfigQuestionnaire.Validate(Description, Description);
        ConfigQuestionnaire.Modify(true);
    end;

    local procedure VerifyQuestionsImported(var ConfigQuestionOld: Record "Config. Question")
    var
        ConfigQuestion: Record "Config. Question";
    begin
        ConfigQuestionOld.FindSet();
        repeat
            Assert.IsTrue(
              ConfigQuestion.Get(ConfigQuestionOld."Questionnaire Code", ConfigQuestionOld."Question Area Code", ConfigQuestionOld."No."),
              StrSubstNo(RecordNotImportedError, ConfigQuestion.TableCaption()));

            Assert.AreEqual(
              ConfigQuestion.Question,
              ConfigQuestionOld.Question,
              StrSubstNo(ValueMustEqualError, ConfigQuestion.FieldCaption(Question), ConfigQuestion.TableCaption(), ConfigQuestionOld.Question));

            Assert.AreEqual(
              ConfigQuestion."Answer Option",
              ConfigQuestionOld."Answer Option",
              StrSubstNo(
                ValueMustEqualError, ConfigQuestion.FieldCaption("Answer Option"), ConfigQuestion.TableCaption(),
                ConfigQuestionOld."Answer Option"));

            Assert.AreEqual(
              ConfigQuestion.Reference,
              ConfigQuestionOld.Reference,
              StrSubstNo(ValueMustEqualError, ConfigQuestion.FieldCaption(Reference), ConfigQuestion.TableCaption(), ConfigQuestionOld.Reference));
        until ConfigQuestionOld.Next() = 0;
    end;

    local procedure VerifyAutogeneratedQuestions(ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        "Field": Record "Field";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);

        ConfigPackageMgt.SetFieldFilter(Field, ConfigQuestionArea."Table ID", 0);
        if Field.FindSet() then
            repeat
                ConfigQuestion.SetRange("Field ID", Field."No.");
                ConfigQuestion.FindFirst();
                Assert.AreEqual(
                  ConfigQuestion."Table ID",
                  ConfigQuestionArea."Table ID",
                  StrSubstNo(
                    ValueMustEqualError, ConfigQuestion.FieldCaption("Table ID"), ConfigQuestion.TableCaption(), ConfigQuestionArea."Table ID"));
            until Field.Next() = 0;
    end;

    local procedure CreateQuestionAreaXML(var XMLText: Text[1024]; ConfigQuestionArea: Record "Config. Question Area"; InsertXMLText: Boolean)
    var
        XMLNodeText: Text[1024];
    begin
        XMLNodeText :=
          '<Code fieldlength="10">' + ConfigQuestionArea.Code + '</Code>' +
          '<Description fieldlength="50">' + ConfigQuestionArea.Description + '</Description>' +
          '<TableID fieldlength="4">' + Format(ConfigQuestionArea."Table ID") + '</TableID>' +
          '<TableCaption fieldlength="250">' + ConfigQuestionArea."Table Caption" + '</TableCaption>';

        CreateXMLNode(XMLText, 'Q1Questions', XMLNodeText, InsertXMLText);
    end;

    local procedure CreateQuestionXML(var XMLText: Text[1024]; ConfigQuestion: Record "Config. Question"; InsertXMLText: Boolean)
    var
        XMLNodeText: Text[1024];
    begin
        XMLNodeText :=
          '<No fieldlength="4">' + Format(ConfigQuestion."No.") + '</No>' +
          '<Question fieldlength="250">' + ConfigQuestion.Question + '</Question>';

        CreateXMLNode(XMLText, 'ConfigQuestion', XMLNodeText, InsertXMLText);
    end;

    local procedure CreateQuestionnaireXML(var XMLText: Text[1024]; ConfigQuestionnaire: Record "Config. Questionnaire")
    var
        XMLNodeText: Text[1024];
    begin
        XMLNodeText :=
          '<Code fieldlength="10">' + ConfigQuestionnaire.Code + '</Code>' +
          '<Description fieldlength="50">' + ConfigQuestionnaire.Description + '</Description>';

        CreateXMLNode(XMLText, 'Questionnaire', XMLNodeText, true);
    end;

    local procedure CreateXMLNode(var XMLText: Text[1024]; XMLNodeName: Text[50]; XMLNodeText: Text[1024]; InsertXMLText: Boolean)
    begin
        if InsertXMLText then
            XMLText := CopyStr('<' + XMLNodeName + '>' + XMLNodeText + XMLText + '</' + XMLNodeName + '>', 1, 1024)
        else
            XMLText += CopyStr('<' + XMLNodeName + '>' + XMLNodeText + '</' + XMLNodeName + '>', 1, 1024);
    end;

    local procedure GetXMLNodeText(var XMLDocument: DotNet XmlDocument; XMLNodeName: Text): Text[20]
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLDocument.SelectSingleNode('//Questionnaire');
        XMLNode := XMLNode.SelectSingleNode(XMLNodeName);
        exit(XMLNode.InnerText);
    end;

    local procedure GetXMLChildNodeText(var XMLNodes: DotNet XmlNodeList; XMLNodeName: Text): Text[20]
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLNodes.Item(0);
        XMLNode := XMLNode.SelectSingleNode(XMLNodeName);
        exit(XMLNode.InnerText);
    end;

    local procedure GetXMLQuestionnaireChildNodes(var XMLDocument: DotNet XmlDocument; var XMLNodes: DotNet XmlNodeList)
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLDocument.SelectSingleNode('//Questionnaire');
        XMLNodes := XMLNode.SelectNodes('child::*[position() >= 3]');
    end;

    local procedure GetXMLQuestionnaireChildNodeText(var XMLDocument: DotNet XmlDocument; XMLNodeName: Text): Text[20]
    var
        XMLNodes: DotNet XmlNodeList;
    begin
        GetXMLQuestionnaireChildNodes(XMLDocument, XMLNodes);
        exit(GetXMLChildNodeText(XMLNodes, XMLNodeName));
    end;

    local procedure InitConfigQuestion(ConfigQuestionnaireCode: Code[10]; ConfigQuestionAreaCode: Code[10]; var ConfigQuestion: Record "Config. Question")
    begin
        ConfigQuestion.Init();
        ConfigQuestion.Validate("Questionnaire Code", ConfigQuestionnaireCode);
        ConfigQuestion.Validate("Question Area Code", ConfigQuestionAreaCode);
        ConfigQuestion.Validate("No.", 1);
    end;

    local procedure CreatePostingGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", GenerateGLAccountNoFromGUID());
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Insert(true);
    end;

    local procedure GenerateGLAccountNoFromGUID() GeneratedCode: Code[20]
    begin
        // Some localized versions require G/L Account to start with a digit other than 0
        GeneratedCode := LibraryUtility.GenerateGUID();
        while StrLen(GeneratedCode) < MaxStrLen(GeneratedCode) do
            GeneratedCode := '1' + GeneratedCode;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldListLookupHandler(var FieldsLookup: TestPage "Fields Lookup")
    begin
        FieldsLookup.First();
        FieldsLookup.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FieldListLookupHandler')]
    [Scope('OnPrem')]
    procedure QuestionnaireFieldLookup()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        "Field": Record "Field";
    begin
        Initialize();

        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        CreateQuestionAreaWithTableID(ConfigQuestionArea, ConfigQuestionnaire.Code, FindTable());

        InitConfigQuestion(ConfigQuestionnaire.Code, ConfigQuestionArea.Code, ConfigQuestion);
        ConfigQuestion.FieldLookup();

        Field.SetRange(TableNo, ConfigQuestionArea."Table ID");
        Field.FindFirst();

        Assert.AreEqual(
          Field."No.", ConfigQuestion."Field ID",
          StrSubstNo(ValueMustEqualError, ConfigQuestion.FieldCaption("Field ID"), ConfigQuestion.TableCaption(), Field."No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PackageDataLookupHandler(var ConfigPackageDataPage: Page "Config. Package Data"; var Response: Action)
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageDataPage.SetTableView(ConfigPackageData);
        ConfigPackageData.FindFirst();
        ConfigPackageDataPage.SetRecord(ConfigPackageData);
        Response := ACTION::LookupOK;
    end;

    local procedure InitQuestionnaireAnswerScenario(var ConfigQuestionArea: Record "Config. Question Area"; var ConfigQuestion: Record "Config. Question"; var ConfigPackage: Record "Config. Package")
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigPackageTable: Record "Config. Package Table";
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        // Creating question
        SetupQuestionnaireTestScenario(ConfigQuestionnaire, ConfigQuestionArea, DATABASE::Currency);

        // Initializing answers list
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Account");

        LibraryERM.FindGLAccount(GLAccount);
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"G/L Account",
          GLAccount.FieldNo("No."),
          GLAccount."No.",
          1);

        // Positioning on a new question line
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionnaire.Code);
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        ConfigQuestion.SetRange("Table ID", DATABASE::Currency);
        ConfigQuestion.SetRange("Field ID", Currency.FieldNo("Unrealized Gains Acc."));
        ConfigQuestion.FindFirst();
    end;

    local procedure VerifyConfigQuestionAnswer(ExpectedValue: Variant; var ConfigQuestion: Record "Config. Question")
    begin
        ConfigQuestion.FindFirst();
        Assert.AreEqual(
          ExpectedValue,
          ConfigQuestion.Answer,
          StrSubstNo(ValueMustEqualError, ConfigQuestion.FieldCaption(Answer), ConfigQuestion.TableCaption(), ExpectedValue));
    end;

    [Test]
    [HandlerFunctions('PackageDataLookupHandler')]
    [Scope('OnPrem')]
    procedure QuestionnaireAnswerLookup()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        GLAccount: Record "G/L Account";
        ConfigQuestionAreaPage: TestPage "Config. Question Area";
    begin
        Initialize();
        ConfigQuestion.DeleteAll(true);
        ConfigPackageData.DeleteAll(true);

        InitQuestionnaireAnswerScenario(ConfigQuestionArea, ConfigQuestion, ConfigPackage);

        ConfigQuestionAreaPage.OpenEdit();
        ConfigQuestionAreaPage.GotoRecord(ConfigQuestionArea);
        ConfigQuestionAreaPage.ConfigQuestionSubform.GotoRecord(ConfigQuestion);
        ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.Lookup();
        ConfigQuestionAreaPage.OK().Invoke();

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"G/L Account", 1, GLAccount.FieldNo("No."));
        VerifyConfigQuestionAnswer(ConfigPackageData.Value, ConfigQuestion);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuestionnaireAnswerValidate()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        GLAccount: Record "G/L Account";
        ConfigQuestionAreaPage: TestPage "Config. Question Area";
    begin
        Initialize();

        InitQuestionnaireAnswerScenario(ConfigQuestionArea, ConfigQuestion, ConfigPackage);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"G/L Account", 1, GLAccount.FieldNo("No."));

        ConfigQuestionAreaPage.OpenEdit();
        ConfigQuestionAreaPage.GotoRecord(ConfigQuestionArea);
        ConfigQuestionAreaPage.ConfigQuestionSubform.GotoRecord(ConfigQuestion);

        ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.SetValue(ConfigPackageData.Value);
        ConfigQuestionAreaPage.OK().Invoke();

        VerifyConfigQuestionAnswer(ConfigPackageData.Value, ConfigQuestion);
    end;
}
