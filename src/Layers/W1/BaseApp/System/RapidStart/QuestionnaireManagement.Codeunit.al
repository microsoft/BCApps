namespace System.IO;

using System;
using System.Reflection;
using System.Utilities;
using System.Xml;

codeunit 8610 "Questionnaire Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        KeyFieldMissingErr: Label 'The value of the key field %1 has not been filled in for questionnaire %2.';
#pragma warning restore AA0470
        OpenXMLManagement: Codeunit "OpenXML Management";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        FileMgt: Codeunit "File Management";
        ExportingQuestionnaireTxt: Label 'Exporting questionnaire';
        ImportingQuestionnaireTxt: Label 'Importing questionnaire';
        XMLSchemaCreationErr: Label 'Could not create the XML schema.';
        ApplyingAnswersTxt: Label 'Applying answers';
        UpdatingQuestionnaireTxt: Label 'Updating questionnaire';
        TypeHelper: Codeunit "Type Helper";
        WrkBkWriter: DotNet WorkbookWriter;
        FieldNameCaptionList: Text;
        ExportToExcel: Boolean;
        CreatingExcelWorksheetTxt: Label 'Creating Excel worksheet';
        DownloadTxt: Label 'Download';
        AllFilesTxt: Label '*.*|*.*';
        DefaultTxt: Label 'Default';
        CalledFromCode: Boolean;
        ImportFileTxt: Label 'Import File';
        XMLFileFilterTxt: Label 'XML file (*.xml)|*.xml', Comment = 'Only translate ''XML Files'' {Split=r"[\|\(]\*\.[^ |)]*[|) ]?"}';
        CreateWrkBkFailedErr: Label 'Could not create the Excel workbook.';

    procedure UpdateQuestions(ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        "Field": Record "Field";
        NextQuestionNo: Integer;
    begin
        if ConfigQuestionArea."Table ID" = 0 then
            exit;

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        if ConfigQuestion.FindLast() then
            NextQuestionNo := ConfigQuestion."No." + 1
        else
            NextQuestionNo := 1;

        ConfigPackageMgt.SetFieldFilter(Field, ConfigQuestionArea."Table ID", 0);
        if Field.FindSet() then
            repeat
                ConfigQuestion.Init();
                ConfigQuestion."Questionnaire Code" := ConfigQuestionArea."Questionnaire Code";
                ConfigQuestion."Question Area Code" := ConfigQuestionArea.Code;
                ConfigQuestion."No." := NextQuestionNo;
                ConfigQuestion."Table ID" := ConfigQuestionArea."Table ID";
                ConfigQuestion."Field ID" := Field."No.";
                if not QuestionExist(ConfigQuestion) then begin
                    UpdateQuestion(ConfigQuestion);
                    ConfigQuestion."Answer Option" := BuildAnswerOption(ConfigQuestionArea."Table ID", Field."No.");
                    ConfigQuestion.Insert();
                    NextQuestionNo := NextQuestionNo + 1;
                end;
            until Field.Next() = 0;
    end;

    local procedure UpdateQuestion(var ConfigQuestion: Record "Config. Question")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if ConfigQuestion.Question <> '' then
            exit;
        if ConfigQuestion."Table ID" = 0 then
            exit;
        RecRef.Open(ConfigQuestion."Table ID");
        FieldRef := RecRef.Field(ConfigQuestion."Field ID");
        ConfigQuestion.Question := FieldRef.Caption + '?';
    end;

    procedure UpdateQuestionnaire(ConfigQuestionnaire: Record "Config. Questionnaire"): Boolean
    var
        ConfigQuestionArea: Record "Config. Question Area";
    begin
        if ConfigQuestionnaire.Code = '' then
            exit;

        ConfigQuestionArea.Reset();
        ConfigQuestionArea.SetRange("Questionnaire Code", ConfigQuestionnaire.Code);
        if ConfigQuestionArea.FindSet() then begin
            ConfigProgressBar.Init(ConfigQuestionArea.Count, 1, UpdatingQuestionnaireTxt);
            repeat
                ConfigProgressBar.Update(ConfigQuestionArea.Code);
                UpdateQuestions(ConfigQuestionArea);
            until ConfigQuestionArea.Next() = 0;
            ConfigProgressBar.Close();
            exit(true);
        end;
        exit(false);
    end;

    local procedure QuestionExist(ConfigQuestion: Record "Config. Question"): Boolean
    var
        ConfigQuestion2: Record "Config. Question";
    begin
        ConfigQuestion2.Reset();
        ConfigQuestion2.SetCurrentKey("Questionnaire Code", "Question Area Code", "Field ID");
        ConfigQuestion2.SetRange("Questionnaire Code", ConfigQuestion."Questionnaire Code");
        ConfigQuestion2.SetRange("Question Area Code", ConfigQuestion."Question Area Code");
        ConfigQuestion2.SetRange("Field ID", ConfigQuestion."Field ID");
        exit(not ConfigQuestion2.IsEmpty);
    end;

    procedure BuildAnswerOption(TableID: Integer; FieldID: Integer): Text[250]
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        BooleanText: Text[30];
    begin
        if not TypeHelper.GetField(TableID, FieldID, Field) then
            exit;

        case Field.Type of
            Field.Type::Option:
                begin
                    RecRef.Open(Field.TableNo);
                    FieldRef := RecRef.Field(Field."No.");
                    exit(FieldRef.OptionCaption);
                end;
            Field.Type::Boolean:
                begin
                    BooleanText := Format(true) + ',' + Format(false);
                    exit(BooleanText)
                end;
            else
                exit(Format(Field.Type));
        end;
    end;

    procedure ApplyAnswers(ConfigQuestionnaire: Record "Config. Questionnaire"): Boolean
    var
        ConfigQuestionArea: Record "Config. Question Area";
    begin
        ConfigQuestionArea.Reset();
        ConfigQuestionArea.SetRange("Questionnaire Code", ConfigQuestionnaire.Code);
        if ConfigQuestionArea.FindSet() then begin
            ConfigProgressBar.Init(ConfigQuestionArea.Count, 1, ApplyingAnswersTxt);
            repeat
                ConfigProgressBar.Update(ConfigQuestionArea.Code);
                ApplyAnswer(ConfigQuestionArea);
            until ConfigQuestionArea.Next() = 0;
            ConfigProgressBar.Close();
            exit(true);
        end;
        exit(false);
    end;

    procedure ApplyAnswer(ConfigQuestionArea: Record "Config. Question Area")
    var
        RecRef: RecordRef;
    begin
        if ConfigQuestionArea."Table ID" = 0 then
            exit;

        RecRef.Open(ConfigQuestionArea."Table ID");
        RecRef.Init();

        InsertRecordWithKeyFields(RecRef, ConfigQuestionArea);
        ModifyRecordWithOtherFields(RecRef, ConfigQuestionArea);
    end;

    local procedure InsertRecordWithKeyFields(var RecRef: RecordRef; ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        RecRef1: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyFieldCount: Integer;
    begin
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);

        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            ConfigQuestion.SetRange("Field ID", FieldRef.Number);
            if ConfigQuestion.FindFirst() then
                ConfigValidateMgt.ValidateFieldValue(RecRef, FieldRef, ConfigQuestion.Answer, false, GlobalLanguage)
            else
                if KeyRef.FieldCount <> 1 then
                    Error(KeyFieldMissingErr, FieldRef.Name, ConfigQuestionArea.Code);
        end;

        RecRef1 := RecRef.Duplicate();

        if RecRef1.Find() then begin
            RecRef := RecRef1;
            exit
        end;

        RecRef.Insert(true);
    end;

    local procedure ModifyRecordWithOtherFields(var RecRef: RecordRef; ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        TempConfigPackageField: Record "Config. Package Field" temporary;
        ConfigPackageManagement: Codeunit "Config. Package Management";
        FieldRef: FieldRef;
        ErrorText: Text[250];
    begin
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);

        if ConfigQuestion.FindSet() then
            repeat
                TempConfigPackageField.DeleteAll();
                if ConfigQuestion.Answer <> '' then begin
                    FieldRef := RecRef.Field(ConfigQuestion."Field ID");
                    ConfigValidateMgt.ValidateFieldValue(RecRef, FieldRef, ConfigQuestion.Answer, false, GlobalLanguage);
                    ConfigPackageManagement.GetFieldsOrder(RecRef, '', TempConfigPackageField);
                    ErrorText := ConfigPackageManagement.ValidateFieldRefRelationAgainstCompanyData(FieldRef, TempConfigPackageField);
                    if ErrorText <> '' then
                        Error(ErrorText);
                end;
            until ConfigQuestion.Next() = 0;
        RecRef.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ExportQuestionnaireAsXML(XMLDataFile: Text; var ConfigQuestionnaire: Record "Config. Questionnaire"): Boolean
    var
        QuestionnaireXML: DotNet XmlDocument;
        ToFile: Text[1024];
        FileName: Text;
        Exported: Boolean;
    begin
        QuestionnaireXML := QuestionnaireXML.XmlDocument();

        GenerateQuestionnaireXMLDocument(QuestionnaireXML, ConfigQuestionnaire);

        Exported := true;
        if not ExportToExcel then begin
            FileName := XMLDataFile;
            ToFile := DefaultTxt + '.xml';

            if not CalledFromCode then
                FileName := FileMgt.ServerTempFileName('.xml');
            QuestionnaireXML.Save(FileName);
            if not CalledFromCode then
                Exported := FileMgt.DownloadHandler(FileName, DownloadTxt, '', AllFilesTxt, ToFile);
        end else begin
            FileName := XMLDataFile;
            QuestionnaireXML.Save(FileName);
        end;

        exit(Exported);
    end;

    [Scope('OnPrem')]
    procedure GenerateQuestionnaireXMLDocument(QuestionnaireXML: DotNet XmlDocument; var ConfigQuestionnaire: Record "Config. Questionnaire")
    var
        ConfigQuestionArea: Record "Config. Question Area";
        RecRef: RecordRef;
        DocumentNode: DotNet XmlNode;
    begin
        XMLDOMMgt.LoadXMLDocumentFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><Questionnaire></Questionnaire>', QuestionnaireXML);

        DocumentNode := QuestionnaireXML.DocumentElement;

        RecRef.GetTable(ConfigQuestionnaire);
        CreateFieldSubtree(RecRef, DocumentNode);

        ConfigQuestionArea.SetRange("Questionnaire Code", ConfigQuestionnaire.Code);
        if ConfigQuestionArea.FindSet() then begin
            ConfigProgressBar.Init(ConfigQuestionArea.Count, 1, ExportingQuestionnaireTxt);
            repeat
                ConfigProgressBar.Update(ConfigQuestionArea.Code);
                CreateQuestionNodes(QuestionnaireXML, ConfigQuestionArea);
            until ConfigQuestionArea.Next() = 0;
            ConfigProgressBar.Close();
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportQuestionnaireAsXMLFromClient(): Boolean
    var
        ServerFileName: Text;
    begin
        ServerFileName := FileMgt.ServerTempFileName('.xml');
        if Upload(ImportFileTxt, '', XMLFileFilterTxt, '', ServerFileName) then
            exit(ImportQuestionnaireAsXML(ServerFileName));

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ImportQuestionnaireAsXML(XMLDataFile: Text): Boolean
    var
        QuestionnaireXML: DotNet XmlDocument;
    begin
        XMLDOMMgt.LoadXMLDocumentFromFile(XMLDataFile, QuestionnaireXML);

        exit(ImportQuestionnaireXMLDocument(QuestionnaireXML));
    end;

    [Scope('OnPrem')]
    procedure ImportQuestionnaireXMLDocument(QuestionnaireXML: DotNet XmlDocument): Boolean
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionAreaNodes: DotNet XmlNodeList;
        QuestionAreaNode: DotNet XmlNode;
        QuestionNodes: DotNet XmlNodeList;
        QuestionnaireNode: DotNet XmlNode;
        AreaNodeCount: Integer;
        NodeCount: Integer;
    begin
        QuestionnaireNode := QuestionnaireXML.SelectSingleNode('//Questionnaire');

        UpdateInsertQuestionnaireField(ConfigQuestionnaire, QuestionnaireNode);
        QuestionAreaNodes := QuestionnaireNode.SelectNodes('child::*[position() >= 3]');

        ConfigProgressBar.Init(QuestionAreaNodes.Count, 1, ImportingQuestionnaireTxt);

        for AreaNodeCount := 0 to QuestionAreaNodes.Count - 1 do begin
            QuestionAreaNode := QuestionAreaNodes.Item(AreaNodeCount);
            ConfigProgressBar.Update(GetNodeValue(QuestionAreaNode, 'Code'));
            ConfigQuestionArea."Questionnaire Code" := ConfigQuestionnaire.Code;
            UpdateInsertQuestionAreaFields(ConfigQuestionArea, QuestionAreaNode);

            QuestionNodes := QuestionAreaNode.SelectNodes('ConfigQuestion');
            for NodeCount := 0 to QuestionNodes.Count - 1 do begin
                ConfigQuestion.Init();
                ConfigQuestion."Questionnaire Code" := ConfigQuestionArea."Questionnaire Code";
                ConfigQuestion."Question Area Code" := ConfigQuestionArea.Code;
                ConfigQuestion."Table ID" := ConfigQuestionArea."Table ID";
                UpdateInsertQuestionFields(ConfigQuestion, QuestionNodes.Item(NodeCount))
            end;
        end;

        ConfigProgressBar.Close();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ExportQuestionnaireToExcel(ExcelFile: Text; var ConfigQuestionnaire: Record "Config. Questionnaire"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ColumnNodes: DotNet XmlNodeList;
        MapXML: DotNet XmlDocument;
        NamespaceMgr: DotNet XmlNamespaceManager;
        QuestionnaireXML: DotNet XmlDocument;
        QuestionAreaNodes: DotNet XmlNodeList;
        QuestionAreaNode: DotNet XmlNode;
        QuestionNodes: DotNet XmlNodeList;
        QuestionnaireNode: DotNet XmlNode;
        "Table": DotNet Table;
        WorksheetWriter: DotNet WorksheetWriter;
        RootElementName: Text;
        TempConfigQuestionnaireFileName: Text;
        TempSchemaFileName: Text;
    begin
        CreateFieldNameCaptionList(DATABASE::"Config. Question");
        CreateEmptyBook(TempBlob);

        TempSchemaFileName := CreateSchemaFile(ConfigQuestionnaire, RootElementName);
        OpenXMLManagement.ImportSchema(WrkBkWriter, TempSchemaFileName, 1, RootElementName);
        OpenXMLManagement.CleanMapInfo(WrkBkWriter.Workbook.WorkbookPart.CustomXmlMappingsPart.MapInfo);

        TempConfigQuestionnaireFileName := CreateConfigQuestionnaireXMLFile(ConfigQuestionnaire);
        OpenXMLManagement.CreateSchemaConnection(WrkBkWriter, TempConfigQuestionnaireFileName);

        OpenXMLManagement.CreateTableStyles(WrkBkWriter.Workbook);
        ReadXSDSchema(TempSchemaFileName, MapXML, NamespaceMgr);

        XMLDOMMgt.LoadXMLDocumentFromFile(TempConfigQuestionnaireFileName, QuestionnaireXML);
        QuestionnaireNode := QuestionnaireXML.SelectSingleNode('//Questionnaire');
        QuestionAreaNodes := QuestionnaireNode.SelectNodes('child::*[position() >= 3]');
        ConfigProgressBar.Init(QuestionAreaNodes.Count, 1, CreatingExcelWorksheetTxt);

        foreach QuestionAreaNode in QuestionAreaNodes do begin
            ConfigProgressBar.Update(QuestionAreaNode.Name);
            FillQuestionAreaHeader(WorksheetWriter, QuestionAreaNode);

            QuestionNodes := QuestionAreaNode.SelectNodes('ConfigQuestion');
            if not IsNull(QuestionNodes) then begin
                GetColumnsFromSchema(MapXML, NamespaceMgr, QuestionAreaNode.Name, ColumnNodes);
                OpenXMLManagement.AddTable(WorksheetWriter, 2, ColumnNodes.Count, QuestionNodes.Count, Table);
                AddColumns(WorksheetWriter, Table, ColumnNodes, QuestionNodes);
                WriteData(WorksheetWriter, ColumnNodes, QuestionNodes);
            end;
        end;
        FillQuestionnaireHeader(WorksheetWriter, QuestionnaireNode);

        WrkBkWriter.Workbook.Save();
        WrkBkWriter.Close();
        Clear(WrkBkWriter);

        ConfigProgressBar.Close();

        if ExcelFile = '' then
            ExcelFile := ConfigQuestionnaire.Code;
        if FileMgt.GetExtension(ExcelFile) = '' then
            ExcelFile += '.xlsx';
        FileMgt.BLOBExport(TempBlob, ExcelFile, true);

        FILE.Erase(TempSchemaFileName);
        FILE.Erase(TempConfigQuestionnaireFileName);

        exit(true);
    end;

    local procedure CreateQuestionNodes(QuestionnaireXML: DotNet XmlDocument; ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        DocumentElement: DotNet XmlElement;
        QuestionAreaNode: DotNet XmlNode;
        QuestionNode: DotNet XmlNode;
        RecRef: RecordRef;
        QuestionRecRef: RecordRef;
    begin
        DocumentElement := QuestionnaireXML.DocumentElement;
        QuestionAreaNode := QuestionnaireXML.CreateElement(GetElementName(ConfigQuestionArea.Code + 'Questions'));
        DocumentElement.AppendChild(QuestionAreaNode);

        RecRef.GetTable(ConfigQuestionArea);
        CreateFieldSubtree(RecRef, QuestionAreaNode);

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        if ConfigQuestion.FindSet() then
            repeat
                QuestionNode := QuestionnaireXML.CreateElement(GetElementName(ConfigQuestion.TableName));
                QuestionAreaNode.AppendChild(QuestionNode);

                QuestionRecRef.GetTable(ConfigQuestion);
                CreateFieldSubtree(QuestionRecRef, QuestionNode);
            until ConfigQuestion.Next() = 0;
    end;

    procedure GetElementName(NameIn: Text): Text
    begin
        NameIn := DelChr(NameIn, '=', '?''`');
        NameIn := ConvertStr(NameIn, '<>,./\+&()%:', '            ');
        NameIn := ConvertStr(NameIn, '-', '_');
        NameIn := DelChr(NameIn, '=', ' ');
        exit(NameIn);
    end;

    local procedure CreateFieldSubtree(var RecRef: RecordRef; var Node: DotNet XmlElement)
    var
        FieldRef: FieldRef;
        FieldNode: DotNet XmlNode;
        XmlDom: DotNet XmlDocument;
        i: Integer;
    begin
        XmlDom := Node.OwnerDocument;
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if not FieldException(RecRef.Number, FieldRef.Number) then begin
                FieldNode := XmlDom.CreateElement(GetElementName(FieldRef.Name));

                if FieldRef.Class = FieldClass::FlowField then
                    FieldRef.CalcField();
                FieldNode.InnerText := Format(FieldRef.Value);

                XMLDOMMgt.AddAttribute(FieldNode, 'fieldlength', Format(FieldRef.Length));
                Node.AppendChild(FieldNode);
            end;
        end;
    end;

    local procedure CreateFieldNameCaptionList(TableID: Integer)
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
        i: Integer;
    begin
        FieldNameCaptionList := '';
        RecRef.Open(TableID);
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            FieldNameCaptionList += StrSubstNo('[%1]%2;', GetElementName(FieldRef.Name), FieldRef.Caption);
        end;
        RecRef.Close();
    end;

    local procedure GetCaptionByXMLFieldName(XMLFieldName: Text) Caption: Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(FieldNameCaptionList, StrSubstNo('[%1]', XMLFieldName));
        if Pos = 0 then
            exit(XMLFieldName);
        Caption := CopyStr(FieldNameCaptionList, Pos + StrLen(XMLFieldName) + 2);
        Caption := CopyStr(Caption, 1, StrPos(Caption, ';') - 1);
    end;

    local procedure FindNode(var ParentNode: DotNet XmlNode; ChildNodeName: Text; var ChildNode: DotNet XmlNode): Boolean
    begin
        ChildNode := ParentNode.SelectSingleNode(ChildNodeName);
        exit(not IsNull(ChildNode));
    end;

    local procedure GetNodeValue(var RecordNode: DotNet XmlNode; FieldNodeName: Text): Text
    var
        FieldNode: DotNet XmlNode;
    begin
        FieldNode := RecordNode.SelectSingleNode(FieldNodeName);
        exit(FieldNode.InnerText);
    end;

    local procedure GetXMLNodeValue(var RecordNode: DotNet XmlNode; NodeName: Text; var xPath: Text): Text
    var
        FieldNode: DotNet XmlNode;
    begin
        if FindNode(RecordNode, GetElementName(NodeName), FieldNode) then begin
            xPath := GetXPath(FieldNode);
            exit(FieldNode.InnerText);
        end;
    end;

    local procedure GetXPath(var XMLNode: DotNet XmlNode): Text
    var
        ParentXMLNode: DotNet XmlNode;
    begin
        if IsNull(XMLNode.ParentNode) then
            exit('');
        ParentXMLNode := XMLNode.ParentNode;
        exit(GetXPath(ParentXMLNode) + '/' + XMLNode.Name);
    end;

    local procedure UpdateInsertQuestionnaireField(var ConfigQuestionnaire: Record "Config. Questionnaire"; RecordNode: DotNet XmlNode)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Config. Questionnaire");

        ValidateRecordFields(RecRef, RecordNode);

        RecRef.SetTable(ConfigQuestionnaire);
    end;

    local procedure UpdateInsertQuestionAreaFields(var ConfigQuestionArea: Record "Config. Question Area"; RecordNode: DotNet XmlNode)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ConfigQuestionArea);

        ValidateRecordFields(RecRef, RecordNode);

        RecRef.SetTable(ConfigQuestionArea);
    end;

    local procedure UpdateInsertQuestionFields(var ConfigQuestion: Record "Config. Question"; RecordNode: DotNet XmlNode)
    var
        "Field": Record "Field";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ConfigQuestion);

        ValidateRecordFields(RecRef, RecordNode);

        RecRef.SetTable(ConfigQuestion);

        if TypeHelper.GetField(ConfigQuestion."Table ID", ConfigQuestion."Field ID", Field) then
            ModifyConfigQuestionAnswer(ConfigQuestion, Field);
    end;

    local procedure FieldNodeExists(var RecordNode: DotNet XmlNode; FieldNodeName: Text): Boolean
    var
        FieldNode: DotNet XmlNode;
    begin
        FieldNode := RecordNode.SelectSingleNode(FieldNodeName);
        if not IsNull(FieldNode) then
            exit(true);
    end;

    local procedure GetXLColumnID(ColumnNo: Integer): Text[10]
    var
        ExcelBuf: Record "Excel Buffer";
    begin
        ExcelBuf.Init();
        ExcelBuf.Validate("Column No.", ColumnNo);
        exit(ExcelBuf.xlColID);
    end;

    local procedure FieldException(TableID: Integer; FieldID: Integer): Boolean
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
    begin
        case TableID of
            DATABASE::"Config. Questionnaire":
                exit(false);
            DATABASE::"Config. Question Area":
                exit(FieldID in [ConfigQuestionArea.FieldNo("Questionnaire Code"),
                                 ConfigQuestionArea.FieldNo("Table Name")]);
            DATABASE::"Config. Question":
                exit(FieldID in [ConfigQuestion.FieldNo("Questionnaire Code"),
                                 ConfigQuestion.FieldNo("Question Area Code"),
                                 ConfigQuestion.FieldNo("Table ID")]);
        end;
    end;

    procedure SetCalledFromCode()
    begin
        CalledFromCode := true;
    end;

    local procedure ValidateKeyFields(RecRef: RecordRef; RecordNode: DotNet XmlNode)
    var
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyFieldCount: Integer;
    begin
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            if FieldNodeExists(RecordNode, GetElementName(FieldRef.Name)) then
                ConfigValidateMgt.ValidateFieldValue(
                  RecRef, FieldRef, GetNodeValue(RecordNode, GetElementName(FieldRef.Name)), false, GlobalLanguage);
        end;
    end;

    local procedure ValidateFields(RecRef: RecordRef; RecordNode: DotNet XmlNode)
    var
        "Field": Record "Field";
        FieldRef: FieldRef;
    begin
        ConfigPackageMgt.SetFieldFilter(Field, RecRef.Number, 0);
        if Field.FindSet() then
            repeat
                FieldRef := RecRef.Field(Field."No.");
                if FieldNodeExists(RecordNode, GetElementName(FieldRef.Name)) then
                    ConfigValidateMgt.ValidateFieldValue(
                      RecRef, FieldRef, GetNodeValue(RecordNode, GetElementName(FieldRef.Name)), false, GlobalLanguage)
            until Field.Next() = 0;
    end;

    local procedure ValidateRecordFields(RecRef: RecordRef; RecordNode: DotNet XmlNode)
    var
        RecRef1: RecordRef;
    begin
        ValidateKeyFields(RecRef, RecordNode);

        RecRef1 := RecRef.Duplicate();
        if not RecRef1.Find() then
            RecRef.Insert(true);

        ValidateFields(RecRef, RecordNode);

        RecRef.Modify(true);
    end;

    procedure ModifyConfigQuestionAnswer(var ConfigQuestion: Record "Config. Question"; FieldRec: Record "Field")
    var
        DateFormula: DateFormula;
        OptionInt: Integer;
    begin
        case FieldRec.Type of
            FieldRec.Type::Option,
            FieldRec.Type::Boolean:
                begin
                    if ConfigQuestion.Answer <> '' then begin
                        OptionInt := TypeHelper.GetOptionNo(ConfigQuestion.Answer, ConfigQuestion."Answer Option");
                        ConfigQuestion."Answer Option" :=
                          BuildAnswerOption(ConfigQuestion."Table ID", ConfigQuestion."Field ID");
                        if OptionInt <> -1 then
                            ConfigQuestion.Answer := SelectStr(OptionInt + 1, ConfigQuestion."Answer Option");
                    end else begin
                        ConfigQuestion.Answer := '';
                        ConfigQuestion."Answer Option" :=
                          BuildAnswerOption(ConfigQuestion."Table ID", ConfigQuestion."Field ID");
                    end;
                    ConfigQuestion.Modify();
                end;
            FieldRec.Type::DateFormula:
                begin
                    Evaluate(DateFormula, ConfigQuestion.Answer);
                    ConfigQuestion.Answer := Format(DateFormula);
                    ConfigQuestion.Modify();
                end;
        end;
    end;

    local procedure CreateSchemaFile(ConfigQuestionnaire: Record "Config. Questionnaire"; var RootElementName: Text) FileName: Text
    var
        ConfigQuestionnaireSchema: XMLport "Config. Questionnaire Schema";
        OStream: OutStream;
        TempSchemaFile: File;
    begin
        FileName := FileMgt.ServerTempFileName('xsd');
        TempSchemaFile.Create(FileName);
        TempSchemaFile.CreateOutStream(OStream);

        ConfigQuestionnaire.SetRecFilter();
        RootElementName := ConfigQuestionnaireSchema.GetRootElementName();
        ConfigQuestionnaireSchema.SetTableView(ConfigQuestionnaire);
        ConfigQuestionnaireSchema.SetDestination(OStream);
        if not ConfigQuestionnaireSchema.Export() then
            Error(XMLSchemaCreationErr);

        TempSchemaFile.Close();
    end;

    local procedure CreateConfigQuestionnaireXMLFile(ConfigQuestionnaire: Record "Config. Questionnaire") FileName: Text
    begin
        ExportToExcel := true;
        CalledFromCode := true;
        FileName := FileMgt.ServerTempFileName('xml');
        ExportQuestionnaireAsXML(FileName, ConfigQuestionnaire);
        ExportToExcel := false;
    end;

    local procedure CreateEmptyBook(var TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        WrkBkWriter := WrkBkWriter.Create(InStream);
        if IsNull(WrkBkWriter) then
            Error(CreateWrkBkFailedErr);

        WrkBkWriter.DeleteWorksheet(WrkBkWriter.FirstWorksheet.Name);
    end;

    local procedure WriteData(var WorksheetWriter: DotNet WorksheetWriter; ColumnNodes: DotNet XmlNodeList; QuestionNodes: DotNet XmlNodeList)
    var
        ColumnNode: DotNet XmlNode;
        QuestionNode: DotNet XmlNode;
        ColumnNo: Integer;
        RowNo: Integer;
        Value: Text;
    begin
        RowNo := 2; // to put the first data row to the 3rd row
        foreach QuestionNode in QuestionNodes do begin
            RowNo += 1;
            ColumnNo := 0;
            foreach ColumnNode in ColumnNodes do begin
                ColumnNo += 1;
                Value := GetNodeValue(QuestionNode, GetAttribute('name', ColumnNode));
                WorksheetWriter.SetCellValueText(RowNo, GetXLColumnID(ColumnNo), Value, WorksheetWriter.DefaultCellDecorator);
            end;
        end;
    end;

    local procedure AddColumns(var WorksheetWriter: DotNet WorksheetWriter; "Table": DotNet Table; ColumnNodes: DotNet XmlNodeList; QuestionNodes: DotNet XmlNodeList)
    var
        FieldNode: DotNet XmlNode;
        QuestionNode: DotNet XmlNode;
        ColumnName: Text;
        xPathPrefix: Text;
        FieldName: Text;
        FieldType: Text;
        ColumnId: Integer;
    begin
        QuestionNode := QuestionNodes.Item(0);
        xPathPrefix := GetXPath(QuestionNode) + '/';
        ColumnId := 0;
        foreach FieldNode in ColumnNodes do begin
            ColumnId += 1;
            FieldName := GetAttribute('name', FieldNode);
            ColumnName := GetCaptionByXMLFieldName(FieldName);
            FieldType := GetAttribute('type', FieldNode);
            OpenXMLManagement.AddColumnHeaderWithXPath(
              WorksheetWriter, Table, ColumnId, ColumnName, FieldType, xPathPrefix + FieldName);
            WorksheetWriter.SetCellValueText(2, GetXLColumnID(ColumnId), ColumnName, WorksheetWriter.DefaultCellDecorator);
        end;
    end;

    local procedure FillQuestionnaireHeader(var WorksheetWriter: DotNet WorksheetWriter; QuestionnaireNode: DotNet XmlNode)
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        SingleXMLCells: DotNet SingleXmlCells;
        Description: array[2] of Text;
        XPath: array[2] of Text;
    begin
        Description[2] := GetXMLNodeValue(QuestionnaireNode, ConfigQuestionnaire.FieldName(Description), XPath[2]);
        if Description[2] <> '' then begin
            Description[1] := GetXMLNodeValue(QuestionnaireNode, ConfigQuestionnaire.FieldName(Code), XPath[1]);

            WorksheetWriter := WrkBkWriter.AddWorksheet(Description[2]);
            AddSingleXMLCells(WorksheetWriter, SingleXMLCells);

            OpenXMLManagement.SetSingleCellValue(WorksheetWriter, SingleXMLCells, 1, 'A', Description[1], XPath[1]);
            OpenXMLManagement.SetSingleCellValue(WorksheetWriter, SingleXMLCells, 1, 'B', Description[2], XPath[2]);
        end;
    end;

    local procedure FillQuestionAreaHeader(var WorksheetWriter: DotNet WorksheetWriter; QuestionAreaNode: DotNet XmlNode)
    var
        ConfigQuestionArea: Record "Config. Question Area";
        SingleXMLCells: DotNet SingleXmlCells;
        Description: array[3] of Text;
        XPath: array[3] of Text;
        i: Integer;
    begin
        Description[1] := GetXMLNodeValue(QuestionAreaNode, ConfigQuestionArea.FieldName(Code), XPath[1]);
        Description[2] := GetXMLNodeValue(QuestionAreaNode, ConfigQuestionArea.FieldName(Description), XPath[2]);
        if Description[2] = '' then
            Description[2] := Description[1];
        Description[3] := GetXMLNodeValue(QuestionAreaNode, ConfigQuestionArea.FieldName("Table ID"), XPath[3]);

        WorksheetWriter := WrkBkWriter.AddWorksheet(Description[2]);
        AddSingleXMLCells(WorksheetWriter, SingleXMLCells);

        for i := 1 to ArrayLen(Description) do
            OpenXMLManagement.SetSingleCellValue(WorksheetWriter, SingleXMLCells, 1, GetXLColumnID(i), Description[i], XPath[i]);
    end;

    local procedure AddSingleXMLCells(var WrkShtWriter: DotNet WorksheetWriter; var SingleXMLCells: DotNet SingleXmlCells)
    begin
        WrkShtWriter.AddSingleCellTablePart();
        SingleXMLCells := SingleXMLCells.SingleXmlCells();
        WrkShtWriter.Worksheet.WorksheetPart.SingleCellTablePart.SingleXmlCells := SingleXMLCells;
    end;

    local procedure GetAttribute(AttributeName: Text; XMLNode: DotNet XmlNode): Text[1024]
    var
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributeNode := XMLNode.Attributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');

        exit(Format(XMLAttributeNode.InnerText));
    end;

    local procedure ReadXSDSchema(FileName: Text; var MapXML: DotNet XmlDocument; var NamespaceMgr: DotNet XmlNamespaceManager)
    begin
        XMLDOMMgt.LoadXMLDocumentFromFile(FileName, MapXML);
        CreateNameSpaceManager(MapXML, NamespaceMgr);
    end;

    local procedure CreateNameSpaceManager(XmlDocument: DotNet XmlDocument; var NamespaceMgr: DotNet XmlNamespaceManager)
    begin
        if not IsNull(NamespaceMgr) then
            Clear(NamespaceMgr);

        NamespaceMgr := NamespaceMgr.XmlNamespaceManager(XmlDocument.NameTable);
        PopulateNamespaceManager(XmlDocument.DocumentElement, NamespaceMgr);
    end;

    local procedure PopulateNamespaceManager(XmlNode: DotNet XmlNode; var NamespaceMgr: DotNet XmlNamespaceManager)
    var
        Attribute: DotNet XmlAttribute;
        Attributes: DotNet XmlAttributeCollection;
        i: Integer;
        Prefix: Text;
    begin
        if not IsNull(XmlNode) then begin
            Attributes := XmlNode.Attributes;
            for i := 0 to Attributes.Count - 1 do begin
                Attribute := Attributes.Item(i);
                if StrPos(Attribute.Name, 'xmlns') = 1 then
                    if StrPos(Attribute.Name, ':') > 0 then begin
                        Prefix := CopyStr(Attribute.Name, StrPos(Attribute.Name, ':') + 1);
                        NamespaceMgr.AddNamespace(Prefix, Attribute.Value);
                    end;
            end;
        end;
    end;

    local procedure GetColumnsFromSchema(MapXML: DotNet XmlDocument; NamespaceMgr: DotNet XmlNamespaceManager; QuestionAreaName: Text; var ColumnNodes: DotNet XmlNodeList)
    var
        Node: DotNet XmlNode;
        SchemaPath: Text;
    begin
        SchemaPath := 'xsd:complexType/xsd:sequence/xsd:element';
        Node :=
          MapXML.DocumentElement.SelectSingleNode(
            StrSubstNo('xsd:element/%2[@name=''%1'']', QuestionAreaName, SchemaPath), NamespaceMgr);
        ColumnNodes := Node.SelectNodes(StrSubstNo('%1[@name=''ConfigQuestion'']/%1', SchemaPath), NamespaceMgr);
    end;
}

