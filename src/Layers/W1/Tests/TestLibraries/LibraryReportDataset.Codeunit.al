codeunit 131007 "Library - Report Dataset"
{
    // This library is used to verify the data output of a report
    // There are 2 possible layouts:
    // Old layout - Created by TestRequestPage.SaveAsXML - this one is serializing the output of report previewer (will be deprecated in the future)
    // New layout - Created by REPORT.SaveAs or REPORT.SaveAsXML - this one should be used for new tests
    // For new layout the functions with Tag in the name cannot be used, since the schema does not use tags


    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        InvalidRowErr: Label 'Row does not exist.';
        InvalidFieldErr: Label 'Field ''%1'' does not exist.', Locked = true;
        RowNotFoundErr: Label 'No row found where Field ''%1'' = <%2>.', Locked = true;
        RowFoundErr: Label 'Row is found where Field ''%1'' = <%2>.', Locked = true;
        CurrentRowErr: Label 'Current row does not have Field ''%1'' = <%2>.', Locked = true;
        ElementNotFoundInScemaErr: Label 'Field ''%1'' was not found in the embedded xml schema.', Locked = true;
        RowIndexErr: Label 'Invalid row index: %1', Locked = true;
        ElementNameErr: Label 'Element with name ''%1'' was not found', Locked = true;
        RowIndexNotFoundErr: Label 'Could not find row with index %1 in report dataset', Locked = true;
        NameTagTxt: Label 'Name', Locked = true;
        StringTagTxt: Label 'string', Locked = true;
        XmlDoc: XmlDocument;
        SchemaNodeList: XmlNodeList;
        Rows: XmlNodeList;
        XMLSchemaType: Option ReportPreview,XML;
        FunctionNotSupportedForXMLErr: Label 'The function is not supported for XML Dataset. Functions with Tag cannot be used, use the functions named Element.';
        DataSetFileName: Text;
        ParametersFileName: Text;
        CurrentRowIndex: Integer;
        SearchPatternColumnByNameTxt: Label './/Column[@name="%1"]', Locked = true;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure AssertElementTagExists(ElementTag: Text)
    begin
        VerifyTagIsSupported();
        SetXmlNodeList(ElementTag);
        Assert.IsTrue(
          FindRowWithTagNoValue(ElementTag) <> -1,
          StrSubstNo(RowNotFoundErr, ElementTag, ''))
    end;


    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure AssertElementTagWithValueExists(ElementTag: Text; ExpectedValue: Variant)
    begin
        VerifyTagIsSupported();
        SetXmlNodeList(ElementTag);
        Assert.IsTrue(
          SearchForElementTagByValue(ElementTag, ExpectedValue),
          StrSubstNo(RowNotFoundErr, ElementTag, ExpectedValue))
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure AssertElementTagWithValueNotExist(ElementTag: Text; ExpectedValue: Variant)
    begin
        VerifyTagIsSupported();
        SetXmlNodeList(ElementTag);
        Assert.IsFalse(
          SearchForElementTagByValue(ElementTag, ExpectedValue),
          StrSubstNo(RowNotFoundErr, ElementTag, ExpectedValue))
    end;

    procedure AssertElementWithValueExists(ElementName: Text; ExpectedValue: Variant)
    begin
        AssertValueInElement(ElementName, ExpectedValue);
    end;

    procedure AssertValueInElement(ElementName: Text; ExpectedValue: Variant)
    var
        Row: XmlNode;
        SearchPattern: Text;
        ErrorMessageTxt: Text;
        ActualValue: Variant;
        FoundValue: Variant;
    begin
        FoundValue := false;
        foreach Row in Rows do
            if ElementName <> '' then begin
                case XMLSchemaType of
                    XMLSchemaType::ReportPreview:
                        SearchPattern := ElementName;
                    XMLSchemaType::XML:
                        SearchPattern := StrSubstNo(SearchPatternColumnByNameTxt, ElementName)
                end;
                ActualValue := false;
                if CheckingInRow(SearchPattern, Row, ExpectedValue, ActualValue) then
                    exit;
                if not ActualValue.IsBoolean() then
                    FoundValue := ActualValue
            end;
        ErrorMessageTxt := StrSubstNo(RowNotFoundErr, ElementName, ExpectedValue);
        if not FoundValue.IsBoolean() then
            ErrorMessageTxt += StrSubstNo(RowFoundErr, ElementName, FoundValue);
        Assert.Fail(ErrorMessageTxt);
    end;

    local procedure CheckingInRow(SearchPattern: Text; Row: XmlNode; ExpectedValue: Variant; var ActualValue: Variant): Boolean
    var
        SearchResults: XmlNodeList;
        Result: XmlNode;
    begin
        if Row.SelectNodes(SearchPattern, SearchResults) then
            foreach Result in SearchResults do begin
                ActualValue := Result.AsXmlElement().InnerText();
                if XMLSchemaType = XMLSchemaType::ReportPreview then
                    EvaluateActualValue(SearchPattern, ActualValue, ActualValue);
                if CompareValues(ExpectedValue, ActualValue) then
                    exit(true);
            end;
        exit(false);
    end;

    local procedure CompareValues(ExpectedValue: Variant; ActualValue: Variant): Boolean
    begin
        ConvertValue(ExpectedValue, ActualValue);
        exit(Assert.Compare(ExpectedValue, ActualValue));
    end;

    procedure AssertElementWithValueNotExist(ElementName: Text; ExpectedValue: Variant)
    begin
        Assert.IsFalse(
          SearchForElementByValue(ElementName, ExpectedValue),
          StrSubstNo(RowFoundErr, ElementName, ExpectedValue))
    end;

    procedure AssertCurrentRowValueEquals(ElementName: Text; ExpectedValue: Variant)
    var
        Value: Variant;
    begin
        FindCurrentRowValue(ElementName, Value);
        ConvertValue(ExpectedValue, Value);
        Assert.AreEqual(ExpectedValue, Value,
          StrSubstNo(CurrentRowErr, ElementName, ExpectedValue));
    end;

    procedure AssertCurrentRowValueNotEquals(ElementName: Text; ExpectedValue: Variant)
    var
        Value: Variant;
    begin
        FindCurrentRowValue(ElementName, Value);
        ConvertValue(ExpectedValue, Value);
        Assert.AreNotEqual(ExpectedValue, Value,
          StrSubstNo(CurrentRowErr, ElementName, ExpectedValue));
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure AssertParameterValueExists(ParameterName: Text; ExpectedValue: Text)
    var
        ParameterNameRow: Integer;
        ValueNameRow: Integer;
    begin
        SetXmlNodeList(NameTagTxt);
        ParameterNameRow := FindRowWithTag(NameTagTxt, ParameterName);
        Assert.IsTrue(
          ParameterNameRow <> -1,
          StrSubstNo(RowNotFoundErr, NameTagTxt, ParameterName));

        SetXmlNodeList(StringTagTxt);
        ValueNameRow := FindRowWithTag(StringTagTxt, ExpectedValue);
        Assert.IsTrue(
          ValueNameRow <> -1,
          StrSubstNo(RowNotFoundErr, StringTagTxt, ExpectedValue));

        while (ValueNameRow <> -1) and (ValueNameRow < ParameterNameRow) do begin
            MoveToRow(ValueNameRow + 1);
            ValueNameRow := FindRowWithTag(StringTagTxt, ExpectedValue);
        end;

        Assert.IsTrue(
          ParameterNameRow = ValueNameRow,
          StrSubstNo(RowNotFoundErr, ParameterName, ExpectedValue))
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure CurrentRowHasElementTag(ElementName: Text): Boolean
    var
        Row: XmlNode;
    begin
        Rows.Get(CurrentRowIndex, Row);
        exit(Row.AsXmlElement().Name() = ElementName);
    end;

    procedure CurrentRowHasElement(ElementName: Text): Boolean
    var
        Row: XmlNode;
        Element: XmlNode;
    begin
        Rows.Get(CurrentRowIndex, Row);

        if ElementName = '' then
            exit(false);

        case XMLSchemaType of
            XMLSchemaType::ReportPreview:
                exit(Row.SelectSingleNode(ElementName, Element));
            XMLSchemaType::XML:
                exit(NameAttributeMatchesValue(Row, ElementName));
        end;
        exit(false);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure FindCurrentRowTagValue(ElementTag: Text; var Value: Variant)
    var
        Row: XmlNode;
        ElementText: Text;
    begin
        VerifyTagIsSupported();

        if CurrentRowIndex = 0 then
            Error(InvalidRowErr);

        Rows.Get(CurrentRowIndex, Row);

        if not CurrentRowHasElementTag(ElementTag) then
            Error(InvalidFieldErr, ElementTag);

        ElementText := Row.AsXmlElement().InnerText();
        Value := ElementText;
    end;

    procedure FindCurrentRowValue(ElementName: Text; var Value: Variant)
    var
        Row: XmlNode;
        Element: XmlNode;
        Column: XmlNode;
        ElementText: Text;
    begin
        if CurrentRowIndex = 0 then
            Error(InvalidRowErr);

        Rows.Get(CurrentRowIndex, Row);
        if not CurrentRowHasElement(ElementName) then
            Error(InvalidFieldErr, ElementName);

        if XMLSchemaType = XMLSchemaType::XML then begin
            Row.SelectSingleNode(StrSubstNo(SearchPatternColumnByNameTxt, ElementName), Column);
            Value := Column.AsXmlElement().InnerText();
            exit;
        end;

        Row.AsXmlElement().SelectSingleNode(ElementName, Element);
        ElementText := Element.AsXmlElement().InnerText();
        EvaluateActualValue(ElementName, ElementText, Value);
    end;

    local procedure EvaluateActualValue(ElementName: Text; ElementText: Text; var Value: Variant)
    var
        Decimal: Decimal;
        "Integer": Integer;
        Boolean: Boolean;
    begin
        case GetElementSchemaType(ElementName) of
            'xs:boolean':
                begin
                    Evaluate(Boolean, ElementText, 9);
                    Value := Boolean;
                end;
            'xs:int':
                begin
                    Evaluate(Integer, ElementText, 9);
                    Value := Integer;
                end;
            'xs:decimal':
                begin
                    Evaluate(Decimal, ElementText, 9);
                    Value := Decimal;
                end;
            else
                Value := ElementText;
        end;
    end;

    local procedure GetElementSchemaType(ElementName: Text): Text
    var
        xmlNode: XmlNode;
        xmlAttribute: XmlAttribute;
        i: Integer;
    begin
        for i := 1 to SchemaNodeList.Count() do begin
            SchemaNodeList.Get(i, xmlNode);
            xmlNode.AsXmlElement().Attributes().Get('name', xmlAttribute);
            if xmlAttribute.Value() = ElementName then
                if xmlNode.AsXmlElement().Attributes().Get('type', xmlAttribute) then
                    exit(xmlAttribute.Value());
        end;
        Error(ElementNotFoundInScemaErr, ElementName);
    end;

    procedure "Sum"(ElementName: Text) TotalValue: Decimal
    var
        ValueVar: Variant;
        Value: Decimal;
    begin
        while GetNextRow() do
            if CurrentRowHasElement(ElementName) then begin
                FindCurrentRowValue(ElementName, ValueVar);
                Value := ValueVar;
                TotalValue += Value;
            end;

        CurrentRowIndex := 0
    end;

    procedure GetNextRow(): Boolean
    begin
        if CurrentRowIndex < RowCount() then begin
            CurrentRowIndex += 1;
            exit(true);
        end;
        exit(false)
    end;

    procedure MoveToRow(RowIndex: Integer)
    begin
        CurrentRowIndex := 0;
        while GetNextRow() and (CurrentRowIndex <> RowIndex) do;
        if not ((CurrentRowIndex = RowIndex) and (CurrentRowIndex > 0)) then
            Error(RowIndexNotFoundErr, RowIndex);
    end;

    procedure GetFileName(): Text[1024]
    begin
        DataSetFileName := FileManagement.ServerTempFileName('.xml');
        exit(DataSetFileName)
    end;

    procedure SetFileName(FileName: Text)
    begin
        DataSetFileName := FileName;
    end;

    procedure GetParametersFileName(): Text
    begin
        ParametersFileName := FileManagement.ServerTempFileName('.xml');
        exit(ParametersFileName)
    end;

    procedure RunReportAndLoad(ReportID: Integer; RecordVariant: Variant; RequestPageParametersXML: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        DataTypeManagement: Codeunit "Data Type Management";
        ReportRecordRef: RecordRef;
        ReportOutStream: OutStream;
        ReportInStream: InStream;
    begin
        TempBlob.CreateOutStream(ReportOutStream);

        if DataTypeManagement.GetRecordRef(RecordVariant, ReportRecordRef) then
            REPORT.SaveAs(ReportID, RequestPageParametersXML, REPORTFORMAT::Xml, ReportOutStream, ReportRecordRef)
        else
            REPORT.SaveAs(ReportID, RequestPageParametersXML, REPORTFORMAT::Xml, ReportOutStream);

        TempBlob.CreateInStream(ReportInStream, TextEncoding::UTF8);

        LoadFromInStream(ReportInStream);
    end;

    procedure LoadFromInStream(DataSetInStream: InStream)
    var
        DatasetXMLText: Text;
        XMLStartIndex: Integer;
    begin
        DataSetInStream.Read(DatasetXMLText);
        // Remove junk characters
        XMLStartIndex := StrPos(DatasetXMLText, '<?xml');
        if XMLStartIndex > 0 then
            DatasetXMLText := CopyStr(DatasetXMLText, XMLStartIndex);

        XMLSchemaType := XMLSchemaType::XML;
        XmlDocument.ReadFrom(DatasetXMLText, XmlDoc);
        InitializeGlobals(false);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure LoadDataSetFileWithNoSchema()
    begin
        LoadXMLFile(DataSetFileName, false);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure LoadDataSetFile()
    begin
        LoadXMLFile(DataSetFileName, true);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure LoadParametersFile()
    begin
        LoadXMLFile(ParametersFileName, false);
    end;

    local procedure LoadXMLFile(FileName: Text; "Schema": Boolean)
    begin
        LoadXMLDocumentFromFile(FileName, XmlDoc);
        InitializeGlobals(Schema);
    end;

    local procedure InitializeGlobals("Schema": Boolean)
    var
        xmlNamespace: XmlNamespaceManager;
    begin
        CurrentRowIndex := 0;

        if Schema then begin
            XmlNamespace.NameTable(XmlDoc.NameTable);
            XmlNamespace.AddNamespace('xs', 'http://www.w3.org/2001/XMLSchema');
            XmlDoc.SelectNodes('//xs:element', XmlNamespace, SchemaNodeList)
        end else
            Clear(SchemaNodeList);

        GetResultRows();

        // Clear filename to avoid consecutive tests to validate pre-existing data
        DataSetFileName := '';
        ParametersFileName := '';
    end;

    procedure SetRange(ElementName: Text; Value: Variant)
    begin
        SetRangeWithTrimmedValues(ElementName, Value, false)
    end;

    procedure Reset()
    begin
        GetResultRows();
        CurrentRowIndex := 0
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    local procedure GetResultRows()
    begin
        Clear(Rows);
        case XMLSchemaType of
            XMLSchemaType::ReportPreview:
                XmlDoc.SelectNodes('DataSet/Result', Rows);
            XMLSchemaType::XML:
                XmlDoc.SelectNodes('ReportDataSet/DataItems/DataItem', Rows);
        end;
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    local procedure SearchForElementTagByValue(ElementTag: Text; ElementValue: Variant): Boolean
    begin
        exit(FindRowWithTag(ElementTag, ElementValue) <> -1);
    end;

    procedure SearchForElementByValue(ElementName: Text; ElementValue: Variant): Boolean
    begin
        exit(FindRow(ElementName, ElementValue) <> -1);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure FindRowWithTagNoValue(ElementTag: Text) Result: Integer
    begin
        while GetNextRow() do
            if CurrentRowHasElementTag(ElementTag) then begin
                Result := CurrentRowIndex - 1;
                CurrentRowIndex := 0;
                exit(Result);
            end;

        CurrentRowIndex := 0;
        Result := -1;
        exit(Result);
    end;

    /// <summary>
    /// IMPORTANT - Do not use this function. Instead, use in memory report testing functions - RunReportAndLoad
    /// </summary>
    procedure FindRowWithTag(ElementTag: Text; ElementValue: Variant) Result: Integer
    var
        CurrentValue: Variant;
    begin
        while GetNextRow() do
            if CurrentRowHasElementTag(ElementTag) then begin
                FindCurrentRowTagValue(ElementTag, CurrentValue);
                if Assert.Compare(CurrentValue, ElementValue) then begin
                    Result := CurrentRowIndex - 1;
                    CurrentRowIndex := 0;
                    exit(Result);
                end;
            end;

        CurrentRowIndex := 0;
        Result := -1;
        exit(Result);
    end;

    procedure FindRow(ElementName: Text; ElementValue: Variant) Result: Integer
    var
        CurrentValue: Variant;
    begin
        while GetNextRow() do
            if CurrentRowHasElement(ElementName) then begin
                FindCurrentRowValue(ElementName, CurrentValue);
                ConvertValue(ElementValue, CurrentValue);
                if Assert.Compare(CurrentValue, ElementValue) then begin
                    Result := CurrentRowIndex - 1;
                    CurrentRowIndex := 0;
                    exit(Result);
                end;
            end;

        CurrentRowIndex := 0;
        Result := -1;
        exit(Result);
    end;

    procedure GetElementValueInCurrentRow(ElementName: Text; var Result: Variant)
    begin
        Assert.IsTrue(CurrentRowIndex > 0, StrSubstNo(RowIndexErr, CurrentRowIndex));
        Assert.IsTrue(CurrentRowHasElement(ElementName), StrSubstNo(ElementNameErr, ElementName));
        FindCurrentRowValue(ElementName, Result);
    end;

    procedure SetRangeWithTrimmedValues(ElementName: Text; Value: Variant; TrimSpacesInValue: Boolean)
    var
        dataSet: XmlNode;
    begin
        // Validate that the element exists in the dataset
        GetElementSchemaType(ElementName);
        XmlDoc.GetChildElements('DataSet').Get(1, dataSet);
        if TrimSpacesInValue = false then
            dataSet.SelectNodes(StrSubstNo('//*/*[%1="%2"]', ElementName, Format(Value, 0, 9)), Rows)
        else
            dataSet.SelectNodes(StrSubstNo('//*/*[normalize-space(%1)="%2"]', ElementName, Format(Value, 0, 9)), Rows);
        CurrentRowIndex := 0
    end;

    procedure SetXmlNodeList(value: Text)
    begin
        XmlDoc.SelectNodes(StrSubstNo('//%1', value), Rows);
    end;

    procedure GetLastRow()
    begin
        CurrentRowIndex := RowCount();
    end;

    local procedure NameAttributeMatchesValue(var XmlNode: XmlNode; AttributeName: Text): Boolean
    var
        Column: XmlNode;
    begin
        exit(XmlNode.SelectSingleNode(StrSubstNo(SearchPatternColumnByNameTxt, AttributeName), Column));
    end;

    local procedure ConvertValue(var ExpectedValue: Variant; var ActualValue: Variant)
    begin
        if XMLSchemaType <> XMLSchemaType::XML then
            exit;
        ConvertValues(ExpectedValue, ActualValue);
    end;

    local procedure ConvertValues(var ExpectedValue: Variant; var ActualValue: Variant)
    var
        ConvertedDecimal: Decimal;
        ConvertedInteger: Integer;
        ConvertedBoolean: Boolean;
    begin
        if ExpectedValue.IsDecimal() then begin
            Evaluate(ConvertedDecimal, ActualValue);
            ActualValue := ConvertedDecimal;
            exit;
        end;

        if ExpectedValue.IsInteger() then begin
            Evaluate(ConvertedInteger, ActualValue);
            ActualValue := ConvertedInteger;
            exit;
        end;

        if ExpectedValue.IsBoolean() then begin
            Evaluate(ConvertedBoolean, ActualValue);
            ActualValue := ConvertedBoolean;
            exit;
        end;
    end;

    local procedure VerifyTagIsSupported()
    begin
        if XMLSchemaType = XMLSchemaType::XML then
            Error(FunctionNotSupportedForXMLErr);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadXMLDocumentFromText(XmlText: Text; var XmlDocument: XmlDocument)
    var
        XmlReadOptions: XmlReadOptions;
    begin
        LoadXmlDocFromText(XmlText, XmlDocument, XmlReadOptions);
    end;

    [Scope('OnPrem')]
    procedure LoadXMLDocumentFromFile(FileName: Text; var XmlDocument: XmlDocument)
    var
        FileManagement: Codeunit "File Management";
        File: DotNet File;
    begin
        FileManagement.IsAllowedPath(FileName, false);
        if not File.Exists(FileName) then
            Error('Report Dataset file does not exist.');
        LoadXMLDocumentFromText(FileManagement.GetFileContents(FileName), XmlDocument);
    end;

    local procedure LoadXmlDocFromText(XmlText: Text; var xmlDoc: XmlDocument; xmlReadOptions: XmlReadOptions)
    begin
        if XmlText = '' then
            exit;

        ClearUTF8BOMSymbols(XmlText);
        XmlDocument.ReadFrom(XmlText, xmlReadOptions, xmlDoc);
    end;

    local procedure ClearUTF8BOMSymbols(var XmlText: Text)
    var
        UTF8Encoding: DotNet UTF8Encoding;
        ByteOrderMarkUtf8: Text;
    begin
        UTF8Encoding := UTF8Encoding.UTF8Encoding();
        ByteOrderMarkUtf8 := UTF8Encoding.GetString(UTF8Encoding.GetPreamble());
        if StrPos(XmlText, ByteOrderMarkUtf8) = 1 then
            XmlText := DelStr(XmlText, 1, StrLen(ByteOrderMarkUtf8));
    end;
}

