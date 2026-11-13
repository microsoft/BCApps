namespace System.Automation;

using System;
using System.Reflection;
using System.Utilities;

codeunit 1530 "Request Page Parameters Helper"
{
    var
        DataItemPathTxt: Label '/ReportParameters/DataItems/DataItem', Locked = true;
        OptionPathTxt: Label '/ReportParameters/Options/Field', Locked = true;
        DataItemTableNameTxt: Label 'Table%1', Comment = '%1 = table number', Locked = true;
#pragma warning disable AA0470
        XmlNodesNotFoundErr: Label 'The XML Nodes at %1 cannot be found in the XML Document %2.';
#pragma warning restore AA0470

    [Scope('OnPrem')]
    procedure ShowRequestPageAndGetFilters(var NewFilters: Text; ExistingFilters: Text; EntityName: Code[20]; TableNum: Integer; PageCaption: Text) FiltersSet: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, TableNum) then
            exit(false);

        if ExistingFilters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(
                 FilterPageBuilder, ExistingFilters, EntityName, TableNum)
            then
                exit(false);

        FilterPageBuilder.PageCaption := PageCaption;
        if not FilterPageBuilder.RunModal() then
            exit(false);

        NewFilters :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, TableNum);

        FiltersSet := true;
    end;

    procedure OpenPageToGetFilter(MainRecordRef: RecordRef; var SelectionFilterOutStream: OutStream; ExistingFilters: Text): Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RequestFilterPageBuilder: FilterPageBuilder;
        RequestPageView: Text;
    begin
        RequestPageParametersHelper.BuildDynamicRequestPage(RequestFilterPageBuilder, CopyStr(MainRecordRef.Caption(), 1, 20), MainRecordRef.Number);
        if ExistingFilters <> '' then
            RequestPageParametersHelper.SetViewOnDynamicRequestPage(RequestFilterPageBuilder, ExistingFilters, CopyStr(MainRecordRef.Caption(), 1, 20), MainRecordRef.Number);

        if not RequestFilterPageBuilder.RunModal() then
            exit(false);

        RequestPageView := RequestPageParametersHelper.GetViewFromDynamicRequestPage(RequestFilterPageBuilder, CopyStr(MainRecordRef.Caption(), 1, 20), MainRecordRef.Number);

        SelectionFilterOutStream.WriteText(RequestPageView);
        exit(true);
    end;

    procedure GetFilterDisplayText(MainRecord: Variant; TargetTableId: Integer; FilterFieldNumber: Integer): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        MainRecordRef: RecordRef;
    begin
        TempBlob.FromRecord(MainRecord, FilterFieldNumber);
        MainRecordRef.Open(TargetTableId, true);
        RequestPageParametersHelper.ConvertParametersToFilters(MainRecordRef, TempBlob, TextEncoding::UTF16);
        exit(MainRecordRef.GetFilters());
    end;

    procedure GetFilterViewFilters(MainRecord: Variant; TargetTableId: Integer; FilterFieldNumber: Integer): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        MainRecordRef: RecordRef;
    begin
        TempBlob.FromRecord(MainRecord, FilterFieldNumber);
        MainRecordRef.Open(TargetTableId, true);
        RequestPageParametersHelper.ConvertParametersToFilters(MainRecordRef, TempBlob, TextEncoding::UTF16);
        exit(MainRecordRef.GetView(false));
    end;

    procedure ConvertParametersToFilters(RecRef: RecordRef; TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(ConvertParametersToFilters(RecRef, TempBlob, TextEncoding::UTF8));
    end;

    procedure ConvertParametersToFilters(RecRef: RecordRef; TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding): Boolean
    var
        TableMetadata: Record "Table Metadata";
        FoundXmlNodeList: XmlNodeList;
    begin
        if not TableMetadata.Get(RecRef.Number) then
            exit(false);

        if not FindNodes(FoundXmlNodeList, ReadParameters(TempBlob, Encoding), DataItemPathTxt) then
            exit(false);

        exit(GetFiltersForTable(RecRef, FoundXmlNodeList));
    end;

    local procedure ReadParameters(TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding) Parameters: Text
    var
        ParametersInStream: InStream;
    begin
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(ParametersInStream, Encoding);
            ParametersInStream.ReadText(Parameters);
        end;
    end;

    local procedure FindNodes(var FoundXmlNodeList: XmlNodeList; Parameters: Text; NodePath: Text) Result: Boolean
    var
        ParametersXmlDoc: XmlDocument;
        DocumentElement: XmlElement;
        ShowNotFoundError: Boolean;
    begin
        RemoveByteOrderMark(Parameters);
        if not XmlDocument.ReadFrom(Parameters, ParametersXmlDoc) then
            exit(false);

        if not ParametersXmlDoc.GetRoot(DocumentElement) then
            exit(false);

        ShowNotFoundError := true;
        if DocumentElement.SelectNodes(NodePath, FoundXmlNodeList) then
            ShowNotFoundError := FoundXmlNodeList.Count() = 0;
        OnFindNodesOnAfterCalcShowNotFoundError(ShowNotFoundError);
        if ShowNotFoundError then
            Error(XmlNodesNotFoundErr, NodePath, GetInnerXml(DocumentElement));

        Result := true;
        OnAfterFindNodes(Result);
    end;

    local procedure RemoveByteOrderMark(var XmlText: Text)
    var
        ByteOrderMark: Char;
    begin
        ByteOrderMark := 65279;
        if XmlText <> '' then
            if XmlText[1] = ByteOrderMark then
                XmlText := CopyStr(XmlText, 2);
    end;

    local procedure GetInnerXml(ParentXmlElement: XmlElement) InnerXml: Text
    var
        ChildXmlNode: XmlNode;
        UnformattedXmlWriteOptions: XmlWriteOptions;
        ChildXml: Text;
    begin
        RemoveWhitespaceXmlText(ParentXmlElement);
        UnformattedXmlWriteOptions.PreserveWhitespace := true;
        foreach ChildXmlNode in ParentXmlElement.GetChildNodes() do begin
            ChildXmlNode.WriteTo(UnformattedXmlWriteOptions, ChildXml);
            InnerXml += ChildXml;
        end;
    end;

    local procedure RemoveWhitespaceXmlText(ParentXmlElement: XmlElement)
    var
        DescendantXmlNode: XmlNode;
        WhitespaceXmlNode: XmlNode;
        WhitespaceFound: Boolean;
    begin
        repeat
            WhitespaceFound := false;
            foreach DescendantXmlNode in ParentXmlElement.GetDescendantNodes() do
                if not WhitespaceFound then
                    if IsWhitespaceXmlText(DescendantXmlNode) then begin
                        WhitespaceXmlNode := DescendantXmlNode;
                        WhitespaceFound := true;
                    end;
            if WhitespaceFound then
                WhitespaceXmlNode.Remove();
        until not WhitespaceFound;
    end;

    local procedure IsWhitespaceXmlText(CheckXmlNode: XmlNode): Boolean
    var
        Whitespace: Text[4];
    begin
        if not CheckXmlNode.IsXmlText() then
            exit(false);
        Whitespace[1] := 9;
        Whitespace[2] := 10;
        Whitespace[3] := 13;
        Whitespace[4] := 32;
        exit(DelChr(CheckXmlNode.AsXmlText().Value(), '=', Whitespace) = '');
    end;

    local procedure GetNameAttributeValue(FoundXmlNode: XmlNode): Text
    var
        NameXmlAttribute: XmlAttribute;
    begin
        if FoundXmlNode.AsXmlElement().Attributes().Get('name', NameXmlAttribute) then
            exit(NameXmlAttribute.Value());
    end;

    local procedure GetFiltersForTable(RecRef: RecordRef; FoundXmlNodeList: XmlNodeList): Boolean
    var
        FoundXmlNode: XmlNode;
    begin
        foreach FoundXmlNode in FoundXmlNodeList do
            if DoesRecRefExactlyCorrespondToXMLNode(RecRef, GetNameAttributeValue(FoundXmlNode)) then begin
                RecRef.SetView(FoundXmlNode.AsXmlElement().InnerText());
                exit(true);
            end;

        foreach FoundXmlNode in FoundXmlNodeList do
            if DoesRecRefCorrespondToXMLNode(RecRef, GetNameAttributeValue(FoundXmlNode)) then begin
                RecRef.SetView(FoundXmlNode.AsXmlElement().InnerText());
                exit(true);
            end;

        exit(false);
    end;

    local procedure DoesRecRefExactlyCorrespondToXMLNode(RecRef: RecordRef; XmlTableName: Text): Boolean
    var
        TableName: Text;
        TableCaption: Text;
        TableNumber: Text;
        XmlTableNameUpperCase: Text;
    begin
        XmlTableNameUpperCase := UpperCase(XmlTableName);
        TableCaption := UpperCase(GetTableCaption(RecRef.Number()));
        TableName := UpperCase(GetTableName(RecRef.Number()));
        TableNumber := StrSubstNo('TABLE%1', RecRef.Number());

        case XmlTableNameUpperCase of
            TableCaption, TableName, TableNumber:
                exit(true);
        end;
    end;

    local procedure DoesRecRefCorrespondToXMLNode(RecRef: RecordRef; XmlTableName: Text): Boolean
    var
        TableName: Text;
        TableCaption: Text;
        XmlTableNameUpperCase: Text;
    begin
        XmlTableNameUpperCase := UpperCase(XmlTableName);
        TableCaption := UpperCase(GetTableCaption(RecRef.Number()));
        TableName := UpperCase(GetTableName(RecRef.Number()));

        // if there is no table named XmlTableName, check if it's a substing of the provided RecRef table
        // e. g. data items named "Header" for the "Sales Header" table
        exit((StrPos(TableCaption, XmlTableNameUpperCase) <> 0) or
             (StrPos(TableName, XmlTableNameUpperCase) <> 0))
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.Caption);
    end;

    local procedure GetTableName(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.Name);
    end;

    procedure BuildDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; EntityName: Code[20]; TableID: Integer): Boolean
    var
        TableList: DotNet ArrayList;
        Name: Text;
        "Table": Integer;
    begin
        if not GetDataItems(TableList, EntityName, TableID) then
            exit(false);

        foreach Table in TableList do begin
            Name := FilterPageBuilder.AddTable(GetTableCaption(Table), Table);
            AddFields(FilterPageBuilder, Name, Table);
        end;

        exit(true);
    end;

    local procedure GetDataItems(var TableList: DotNet ArrayList; EntityName: Code[20]; TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        if not TableMetadata.Get(TableID) then
            exit(false);

        TableList := TableList.ArrayList();
        TableList.Add(TableID);

        DynamicRequestPageEntity.SetRange(Name, EntityName);
        DynamicRequestPageEntity.SetRange("Table ID", TableID);
        if DynamicRequestPageEntity.FindSet() then
            repeat
                if not TableList.Contains(DynamicRequestPageEntity."Related Table ID") then
                    TableList.Add(DynamicRequestPageEntity."Related Table ID");
            until DynamicRequestPageEntity.Next() = 0;

        exit(true);
    end;

    local procedure AddFields(var FilterPageBuilder: FilterPageBuilder; Name: Text; TableID: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        DynamicRequestPageField.SetRange("Table ID", TableID);
        if DynamicRequestPageField.FindSet() then
            repeat
                FilterPageBuilder.AddFieldNo(Name, DynamicRequestPageField."Field ID");
            until DynamicRequestPageField.Next() = 0;
    end;

    procedure SetViewOnDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; Filters: Text; EntityName: Code[20]; TableID: Integer): Boolean
    var
        RecRef: RecordRef;
        FoundXmlNodeList: XmlNodeList;
        TableList: DotNet ArrayList;
        "Table": Integer;
    begin
        if not FindNodes(FoundXmlNodeList, Filters, DataItemPathTxt) then
            exit(false);

        if not GetDataItems(TableList, EntityName, TableID) then
            exit(false);

        foreach Table in TableList do begin
            RecRef.Open(Table);
            GetFiltersForTable(RecRef, FoundXmlNodeList);
            FilterPageBuilder.SetView(GetTableCaption(Table), RecRef.GetView(false));
            RecRef.Close();
            Clear(RecRef);
        end;

        exit(true);
    end;

    procedure GetViewFromDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; EntityName: Code[20]; TableID: Integer): Text
    var
        TableList: DotNet ArrayList;
        TableFilterDictionary: DotNet GenericDictionary2;
        "Table": Integer;
    begin
        if not GetDataItems(TableList, EntityName, TableID) then
            exit('');

        TableFilterDictionary := TableFilterDictionary.Dictionary(TableList.Count);

        foreach Table in TableList do
            if not TableFilterDictionary.ContainsKey(Table) then
                TableFilterDictionary.Add(Table, FilterPageBuilder.GetView(GetTableCaption(Table), false));

        exit(ConvertFiltersToParameters(TableFilterDictionary));
    end;

    local procedure ConvertFiltersToParameters(TableFilterDictionary: DotNet GenericDictionary2): Text
    var
        XmlDoc: XmlDocument;
        ReportParametersXmlElement: XmlElement;
        DataItemsXmlElement: XmlElement;
        DataItemXmlElement: XmlElement;
        TableFilter: DotNet GenericKeyValuePair2;
        UnformattedXmlWriteOptions: XmlWriteOptions;
        TableView: Text;
        ParametersXml: Text;
    begin
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        ReportParametersXmlElement := XmlElement.Create('ReportParameters');
        XmlDoc.Add(ReportParametersXmlElement);

        DataItemsXmlElement := XmlElement.Create('DataItems');
        ReportParametersXmlElement.Add(DataItemsXmlElement);
        foreach TableFilter in TableFilterDictionary do begin
            DataItemXmlElement := XmlElement.Create('DataItem');
            TableView := TableFilter.Value;
            if TableView <> '' then
                DataItemXmlElement.Add(XmlText.Create(TableView));
            DataItemXmlElement.SetAttribute('name', StrSubstNo(DataItemTableNameTxt, TableFilter.Key));
            DataItemsXmlElement.Add(DataItemXmlElement);
        end;

        UnformattedXmlWriteOptions.PreserveWhitespace := true;
        XmlDoc.WriteTo(UnformattedXmlWriteOptions, ParametersXml);
        exit(ParametersXml);
    end;

    procedure GetRequestPageOptionValue(OptionName: Text; Parameters: Text): Text
    var
        FoundXmlNodeList: XmlNodeList;
        FoundXmlNode: XmlNode;
        TempValue: Text;
    begin
        if not FindNodes(FoundXmlNodeList, Parameters, OptionPathTxt) then
            exit('');

        foreach FoundXmlNode in FoundXmlNodeList do begin
            TempValue := GetNameAttributeValue(FoundXmlNode);
            if Format(TempValue) = Format(OptionName) then
                exit(FoundXmlNode.AsXmlElement().InnerText());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNodes(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNodesOnAfterCalcShowNotFoundError(var ShowNotFoundError: Boolean)
    begin
    end;
}

