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
        QuestionnaireXML: XmlDocument;
        ToFile: Text[1024];
        FileName: Text;
        Exported: Boolean;
    begin
        QuestionnaireXML := XmlDocument.Create();

        GenerateQuestionnaireXMLDocument(QuestionnaireXML, ConfigQuestionnaire);

        Exported := true;
        if not ExportToExcel then begin
            FileName := XMLDataFile;
            ToFile := DefaultTxt + '.xml';

            if not CalledFromCode then
                FileName := FileMgt.ServerTempFileName('.xml');
            SaveXMLDocumentToFile(QuestionnaireXML, FileName);
            if not CalledFromCode then
                Exported := FileMgt.DownloadHandler(FileName, DownloadTxt, '', AllFilesTxt, ToFile);
        end else begin
            FileName := XMLDataFile;
            SaveXMLDocumentToFile(QuestionnaireXML, FileName);
        end;

        exit(Exported);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use the GenerateQuestionnaireXMLDocument overload with a native XmlDocument parameter instead.', '30.0')]
    procedure GenerateQuestionnaireXMLDocument(QuestionnaireXML: DotNet XmlDocument; var ConfigQuestionnaire: Record "Config. Questionnaire")
    var
        TempBlob: Codeunit "Temp Blob";
        NativeQuestionnaireXML: XmlDocument;
        QuestionnaireOutStream: OutStream;
        QuestionnaireInStream: InStream;
    begin
        GenerateQuestionnaireXMLDocument(NativeQuestionnaireXML, ConfigQuestionnaire);
        TempBlob.CreateOutStream(QuestionnaireOutStream);
        NativeQuestionnaireXML.WriteTo(QuestionnaireOutStream);
        TempBlob.CreateInStream(QuestionnaireInStream);
        if IsNull(QuestionnaireXML) then
            QuestionnaireXML := QuestionnaireXML.XmlDocument();
        QuestionnaireXML.Load(QuestionnaireInStream);
    end;
#endif

    /// <summary>
    /// Builds the XML document for the provided questionnaire.
    /// </summary>
    /// <param name="QuestionnaireXML">The XML document that receives the questionnaire.</param>
    /// <param name="ConfigQuestionnaire">The questionnaire to export.</param>
    [Scope('OnPrem')]
    procedure GenerateQuestionnaireXMLDocument(var QuestionnaireXML: XmlDocument; var ConfigQuestionnaire: Record "Config. Questionnaire")
    var
        ConfigQuestionArea: Record "Config. Question Area";
        RecRef: RecordRef;
        DocumentNode: XmlElement;
    begin
        XmlDocument.ReadFrom(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><Questionnaire></Questionnaire>', QuestionnaireXML);

        QuestionnaireXML.GetRoot(DocumentNode);

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
        QuestionnaireXML: XmlDocument;
    begin
        LoadXMLDocumentFromFile(XMLDataFile, QuestionnaireXML);

        exit(ImportQuestionnaireXMLDocument(QuestionnaireXML));
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use the ImportQuestionnaireXMLDocument overload with a native XmlDocument parameter instead.', '30.0')]
    procedure ImportQuestionnaireXMLDocument(QuestionnaireXML: DotNet XmlDocument): Boolean
    var
        NativeQuestionnaireXML: XmlDocument;
    begin
        XmlDocument.ReadFrom(QuestionnaireXML.OuterXml(), NativeQuestionnaireXML);
        exit(ImportQuestionnaireXMLDocument(NativeQuestionnaireXML));
    end;
#endif

    /// <summary>
    /// Imports a questionnaire from the provided XML document.
    /// </summary>
    /// <param name="QuestionnaireXML">The XML document that contains the questionnaire.</param>
    /// <returns>True if the questionnaire was imported.</returns>
    [Scope('OnPrem')]
    procedure ImportQuestionnaireXMLDocument(QuestionnaireXML: XmlDocument): Boolean
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        QuestionAreaNodes: XmlNodeList;
        QuestionAreaXmlNode: XmlNode;
        QuestionAreaNode: XmlElement;
        QuestionNodes: XmlNodeList;
        QuestionXmlNode: XmlNode;
        QuestionnaireXmlNode: XmlNode;
        QuestionnaireNode: XmlElement;
        AreaNodeCount: Integer;
        NodeCount: Integer;
    begin
        RemoveWhitespaceTextNodes(QuestionnaireXML.AsXmlNode());
        QuestionnaireXML.SelectSingleNode('//Questionnaire', QuestionnaireXmlNode);
        QuestionnaireNode := QuestionnaireXmlNode.AsXmlElement();

        UpdateInsertQuestionnaireField(ConfigQuestionnaire, QuestionnaireNode);
        QuestionnaireNode.SelectNodes('child::*[position() >= 3]', QuestionAreaNodes);

        ConfigProgressBar.Init(QuestionAreaNodes.Count, 1, ImportingQuestionnaireTxt);

        for AreaNodeCount := 1 to QuestionAreaNodes.Count do begin
            QuestionAreaNodes.Get(AreaNodeCount, QuestionAreaXmlNode);
            QuestionAreaNode := QuestionAreaXmlNode.AsXmlElement();
            ConfigProgressBar.Update(GetNodeValue(QuestionAreaNode, 'Code'));
            ConfigQuestionArea."Questionnaire Code" := ConfigQuestionnaire.Code;
            UpdateInsertQuestionAreaFields(ConfigQuestionArea, QuestionAreaNode);

            QuestionAreaNode.SelectNodes('ConfigQuestion', QuestionNodes);
            for NodeCount := 1 to QuestionNodes.Count do begin
                ConfigQuestion.Init();
                ConfigQuestion."Questionnaire Code" := ConfigQuestionArea."Questionnaire Code";
                ConfigQuestion."Question Area Code" := ConfigQuestionArea.Code;
                ConfigQuestion."Table ID" := ConfigQuestionArea."Table ID";
                QuestionNodes.Get(NodeCount, QuestionXmlNode);
                UpdateInsertQuestionFields(ConfigQuestion, QuestionXmlNode.AsXmlElement())
            end;
        end;

        ConfigProgressBar.Close();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ExportQuestionnaireToExcel(ExcelFile: Text; var ConfigQuestionnaire: Record "Config. Questionnaire"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ColumnNodes: XmlNodeList;
        MapXML: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        QuestionnaireXML: XmlDocument;
        QuestionAreaNodes: XmlNodeList;
        QuestionAreaXmlNode: XmlNode;
        QuestionAreaNode: XmlElement;
        QuestionNodes: XmlNodeList;
        QuestionnaireXmlNode: XmlNode;
        QuestionnaireNode: XmlElement;
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

        LoadXMLDocumentFromFile(TempConfigQuestionnaireFileName, QuestionnaireXML);
        QuestionnaireXML.SelectSingleNode('//Questionnaire', QuestionnaireXmlNode);
        QuestionnaireNode := QuestionnaireXmlNode.AsXmlElement();
        QuestionnaireNode.SelectNodes('child::*[position() >= 3]', QuestionAreaNodes);
        ConfigProgressBar.Init(QuestionAreaNodes.Count, 1, CreatingExcelWorksheetTxt);

        foreach QuestionAreaXmlNode in QuestionAreaNodes do begin
            QuestionAreaNode := QuestionAreaXmlNode.AsXmlElement();
            ConfigProgressBar.Update(QuestionAreaNode.Name);
            FillQuestionAreaHeader(WorksheetWriter, QuestionAreaNode);

            if QuestionAreaNode.SelectNodes('ConfigQuestion', QuestionNodes) then begin
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

    local procedure CreateQuestionNodes(var QuestionnaireXML: XmlDocument; ConfigQuestionArea: Record "Config. Question Area")
    var
        ConfigQuestion: Record "Config. Question";
        DocumentElement: XmlElement;
        QuestionAreaNode: XmlElement;
        QuestionNode: XmlElement;
        RecRef: RecordRef;
        QuestionRecRef: RecordRef;
    begin
        QuestionnaireXML.GetRoot(DocumentElement);
        QuestionAreaNode := XmlElement.Create(GetElementName(ConfigQuestionArea.Code + 'Questions'));
        DocumentElement.Add(QuestionAreaNode);

        RecRef.GetTable(ConfigQuestionArea);
        CreateFieldSubtree(RecRef, QuestionAreaNode);

        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionArea.Code);
        if ConfigQuestion.FindSet() then
            repeat
                QuestionNode := XmlElement.Create(GetElementName(ConfigQuestion.TableName));
                QuestionAreaNode.Add(QuestionNode);

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

    local procedure CreateFieldSubtree(var RecRef: RecordRef; var Node: XmlElement)
    var
        FieldRef: FieldRef;
        FieldNode: XmlElement;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if not FieldException(RecRef.Number, FieldRef.Number) then begin
                FieldNode := XmlElement.Create(GetElementName(FieldRef.Name));

                if FieldRef.Class = FieldClass::FlowField then
                    FieldRef.CalcField();
                FieldNode.Add(XmlText.Create(Format(FieldRef.Value)));

                FieldNode.SetAttribute('fieldlength', Format(FieldRef.Length));
                Node.Add(FieldNode);
            end;
        end;
    end;

    local procedure SaveXMLDocumentToFile(var QuestionnaireXML: XmlDocument; FileName: Text)
    var
        XMLFile: File;
        XMLOutStream: OutStream;
    begin
        AddEndTagIndentationToEmptyValues(QuestionnaireXML);
        XMLFile.Create(FileName);
        XMLFile.CreateOutStream(XMLOutStream);
        QuestionnaireXML.WriteTo(XMLOutStream);
        XMLFile.Close();
    end;
    // DotNet XmlDocument.Save wrote an element with an empty value as an end tag on its own indented line. Add that formatting so the saved file stays identical.
    local procedure AddEndTagIndentationToEmptyValues(var XMLDocToSave: XmlDocument)
    var
        EmptyNodes: XmlNodeList;
        EmptyNode: XmlNode;
        AncestorNodes: XmlNodeList;
        CommentNodes: XmlNodeList;
        CommentNode: XmlNode;
        NewLine: Text[2];
    begin
        if not XMLDocToSave.SelectNodes('//*[not(*) and string-length(.) = 0]', EmptyNodes) then
            exit;
        NewLine[1] := 13;
        NewLine[2] := 10;
        foreach EmptyNode in EmptyNodes do
            if not EmptyNode.AsXmlElement().IsEmpty() then begin
                EmptyNode.SelectNodes('ancestor::*', AncestorNodes);
                if EmptyNode.SelectNodes('comment()', CommentNodes) then
                    foreach CommentNode in CommentNodes do
                        CommentNode.AddBeforeSelf(XmlText.Create(NewLine + PadStr('', (AncestorNodes.Count() + 1) * 2, ' ')));
                EmptyNode.AsXmlElement().Add(XmlText.Create(NewLine + PadStr('', AncestorNodes.Count() * 2, ' ')));
            end;
    end;

    local procedure LoadXMLDocumentFromFile(FileName: Text; var LoadedXML: XmlDocument)
    var
        XMLFile: File;
        XMLInStream: InStream;
    begin
        FileMgt.IsAllowedPath(FileName, false);
        XMLFile.Open(FileName);
        XMLFile.CreateInStream(XMLInStream);
        XmlDocument.ReadFrom(XMLInStream, LoadedXML);
        XMLFile.Close();
        RemoveWhitespaceTextNodes(LoadedXML.AsXmlNode());
    end;

    // XmlDocument.ReadFrom keeps whitespace-only text nodes, which the DotNet XmlDocument dropped when loading.
    local procedure RemoveWhitespaceTextNodes(RootNode: XmlNode)
    var
        TextNodes: XmlNodeList;
        TextNode: XmlNode;
        Tab: Char;
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        if not RootNode.SelectNodes('descendant::text()', TextNodes) then
            exit;
        Tab := 9;
        LineFeed := 10;
        CarriageReturn := 13;
        foreach TextNode in TextNodes do
            if TextNode.IsXmlText() then
                if DelChr(TextNode.AsXmlText().Value(), '=', ' ' + Format(Tab) + Format(LineFeed) + Format(CarriageReturn)) = '' then
                    TextNode.Remove();
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

    local procedure FindNode(var ParentNode: XmlElement; ChildNodeName: Text; var ChildNode: XmlElement): Boolean
    var
        FoundNode: XmlNode;
    begin
        if not ParentNode.SelectSingleNode(ChildNodeName, FoundNode) then
            exit(false);
        ChildNode := FoundNode.AsXmlElement();
        exit(true);
    end;

    local procedure GetNodeValue(var RecordNode: XmlElement; FieldNodeName: Text): Text
    var
        FieldNode: XmlNode;
    begin
        RecordNode.SelectSingleNode(FieldNodeName, FieldNode);
        exit(FieldNode.AsXmlElement().InnerText);
    end;

    local procedure GetXMLNodeValue(var RecordNode: XmlElement; NodeName: Text; var xPath: Text): Text
    var
        FieldNode: XmlElement;
    begin
        if FindNode(RecordNode, GetElementName(NodeName), FieldNode) then begin
            xPath := GetXPath(FieldNode);
            exit(FieldNode.InnerText);
        end;
    end;

    local procedure GetXPath(var Node: XmlElement): Text
    var
        ParentNode: XmlElement;
        OwnerDocument: XmlDocument;
    begin
        if Node.GetParent(ParentNode) then
            exit(GetXPath(ParentNode) + '/' + Node.Name);
        if Node.GetDocument(OwnerDocument) then
            exit('/' + Node.Name);
        exit('');
    end;

    local procedure UpdateInsertQuestionnaireField(var ConfigQuestionnaire: Record "Config. Questionnaire"; RecordNode: XmlElement)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Config. Questionnaire");

        ValidateRecordFields(RecRef, RecordNode);

        RecRef.SetTable(ConfigQuestionnaire);
    end;

    local procedure UpdateInsertQuestionAreaFields(var ConfigQuestionArea: Record "Config. Question Area"; RecordNode: XmlElement)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ConfigQuestionArea);

        ValidateRecordFields(RecRef, RecordNode);

        RecRef.SetTable(ConfigQuestionArea);
    end;

    local procedure UpdateInsertQuestionFields(var ConfigQuestion: Record "Config. Question"; RecordNode: XmlElement)
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

    local procedure FieldNodeExists(var RecordNode: XmlElement; FieldNodeName: Text): Boolean
    var
        FieldNode: XmlNode;
    begin
        exit(RecordNode.SelectSingleNode(FieldNodeName, FieldNode));
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

    local procedure ValidateKeyFields(RecRef: RecordRef; RecordNode: XmlElement)
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

    local procedure ValidateFields(RecRef: RecordRef; RecordNode: XmlElement)
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

    local procedure ValidateRecordFields(RecRef: RecordRef; RecordNode: XmlElement)
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

    local procedure WriteData(var WorksheetWriter: DotNet WorksheetWriter; ColumnNodes: XmlNodeList; QuestionNodes: XmlNodeList)
    var
        ColumnNode: XmlNode;
        QuestionXmlNode: XmlNode;
        QuestionNode: XmlElement;
        ColumnNo: Integer;
        RowNo: Integer;
        Value: Text;
    begin
        RowNo := 2; // to put the first data row to the 3rd row
        foreach QuestionXmlNode in QuestionNodes do begin
            QuestionNode := QuestionXmlNode.AsXmlElement();
            RowNo += 1;
            ColumnNo := 0;
            foreach ColumnNode in ColumnNodes do begin
                ColumnNo += 1;
                Value := GetNodeValue(QuestionNode, GetAttribute('name', ColumnNode));
                WorksheetWriter.SetCellValueText(RowNo, GetXLColumnID(ColumnNo), Value, WorksheetWriter.DefaultCellDecorator);
            end;
        end;
    end;

    local procedure AddColumns(var WorksheetWriter: DotNet WorksheetWriter; "Table": DotNet Table; ColumnNodes: XmlNodeList; QuestionNodes: XmlNodeList)
    var
        FieldNode: XmlNode;
        QuestionXmlNode: XmlNode;
        QuestionNode: XmlElement;
        ColumnName: Text;
        xPathPrefix: Text;
        FieldName: Text;
        FieldType: Text;
        ColumnId: Integer;
    begin
        QuestionNodes.Get(1, QuestionXmlNode);
        QuestionNode := QuestionXmlNode.AsXmlElement();
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

    local procedure FillQuestionnaireHeader(var WorksheetWriter: DotNet WorksheetWriter; QuestionnaireNode: XmlElement)
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

    local procedure FillQuestionAreaHeader(var WorksheetWriter: DotNet WorksheetWriter; QuestionAreaNode: XmlElement)
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

    local procedure GetAttribute(AttributeName: Text; Node: XmlNode): Text[1024]
    var
        FoundAttribute: XmlAttribute;
    begin
        if not Node.AsXmlElement().Attributes().Get(AttributeName, FoundAttribute) then
            exit('');

        exit(Format(FoundAttribute.Value()));
    end;

    local procedure ReadXSDSchema(FileName: Text; var MapXML: XmlDocument; var NamespaceMgr: XmlNamespaceManager)
    begin
        LoadXMLDocumentFromFile(FileName, MapXML);
        CreateNameSpaceManager(MapXML, NamespaceMgr);
    end;

    local procedure CreateNameSpaceManager(SchemaXML: XmlDocument; var NamespaceMgr: XmlNamespaceManager)
    var
        RootElement: XmlElement;
    begin
        Clear(NamespaceMgr);

        NamespaceMgr.NameTable(SchemaXML.NameTable());
        if SchemaXML.GetRoot(RootElement) then
            PopulateNamespaceManager(RootElement, NamespaceMgr);
    end;

    local procedure PopulateNamespaceManager(RootElement: XmlElement; var NamespaceMgr: XmlNamespaceManager)
    var
        NodeAttribute: XmlAttribute;
        Prefix: Text;
    begin
        foreach NodeAttribute in RootElement.Attributes() do
            if StrPos(NodeAttribute.Name, 'xmlns') = 1 then
                if StrPos(NodeAttribute.Name, ':') > 0 then begin
                    Prefix := CopyStr(NodeAttribute.Name, StrPos(NodeAttribute.Name, ':') + 1);
                    NamespaceMgr.AddNamespace(Prefix, NodeAttribute.Value);
                end;
    end;

    local procedure GetColumnsFromSchema(MapXML: XmlDocument; NamespaceMgr: XmlNamespaceManager; QuestionAreaName: Text; var ColumnNodes: XmlNodeList)
    var
        RootElement: XmlElement;
        Node: XmlNode;
        SchemaPath: Text;
        SchemaAreaPathTok: Label 'xsd:element/%2[@name=''%1'']', Locked = true;
        SchemaQuestionColumnsPathTok: Label '%1[@name=''ConfigQuestion'']/%1', Locked = true;
    begin
        SchemaPath := 'xsd:complexType/xsd:sequence/xsd:element';
        MapXML.GetRoot(RootElement);
        RootElement.SelectSingleNode(
          StrSubstNo(SchemaAreaPathTok, QuestionAreaName, SchemaPath), NamespaceMgr, Node);
        Node.SelectNodes(StrSubstNo(SchemaQuestionColumnsPathTok, SchemaPath), NamespaceMgr, ColumnNodes);
    end;
}

