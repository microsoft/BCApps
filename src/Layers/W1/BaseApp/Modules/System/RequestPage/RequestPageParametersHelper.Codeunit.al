namespace System.Automation;

using System;
using System.Reflection;
using System.Utilities;
using System.Xml;

codeunit 1530 "Request Page Parameters Helper"
{
    var
        DataItemPathTxt: Label '/ReportParameters/DataItems/DataItem', Locked = true;
        OptionPathTxt: Label '/ReportParameters/Options/Field', Locked = true;
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
        FoundXmlNodeList: DotNet XmlNodeList;
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

    local procedure FindNodes(var FoundXmlNodeList: DotNet XmlNodeList; Parameters: Text; NodePath: Text) Result: Boolean
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ParametersXmlDoc: DotNet XmlDocument;
        ShowNotFoundError: Boolean;
    begin
        if not XMLDOMMgt.LoadXMLDocumentFromText(Parameters, ParametersXmlDoc) then
            exit(false);

        if IsNull(ParametersXmlDoc.DocumentElement) then
            exit(false);

        ShowNotFoundError := not XMLDOMMgt.FindNodes(ParametersXmlDoc.DocumentElement, NodePath, FoundXmlNodeList);
        OnFindNodesOnAfterCalcShowNotFoundError(ShowNotFoundError);
        if ShowNotFoundError then
            Error(XmlNodesNotFoundErr, NodePath, ParametersXmlDoc.DocumentElement.InnerXml);

        Result := true;
        OnAfterFindNodes(Result);
    end;

    local procedure GetFiltersForTable(RecRef: RecordRef; FoundXmlNodeList: DotNet XmlNodeList): Boolean
    var
        FoundXmlNode: DotNet XmlNode;
    begin
        foreach FoundXmlNode in FoundXmlNodeList do
            if DoesRecRefExactlyCorrespondToXMLNode(RecRef, FoundXmlNode.Attributes.ItemOf('name').Value) then begin
                RecRef.SetView(FoundXmlNode.InnerText);
                exit(true);
            end;

        foreach FoundXmlNode in FoundXmlNodeList do
            if DoesRecRefCorrespondToXMLNode(RecRef, FoundXmlNode.Attributes.ItemOf('name').Value) then begin
                RecRef.SetView(FoundXmlNode.InnerText);
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
        FoundXmlNodeList: DotNet XmlNodeList;
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
        XMLDOMMgt: Codeunit "XML DOM Management";
        DataItemXmlNode: DotNet XmlNode;
        DataItemsXmlNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
        ReportParametersXmlNode: DotNet XmlNode;
        TableFilter: DotNet GenericKeyValuePair2;
    begin
        XmlDoc := XmlDoc.XmlDocument();

        XMLDOMMgt.AddRootElement(XmlDoc, 'ReportParameters', ReportParametersXmlNode);
        XMLDOMMgt.AddDeclaration(XmlDoc, '1.0', 'utf-8', 'yes');

        XMLDOMMgt.AddElement(ReportParametersXmlNode, 'DataItems', '', '', DataItemsXmlNode);
        foreach TableFilter in TableFilterDictionary do begin
            XMLDOMMgt.AddElement(DataItemsXmlNode, 'DataItem', TableFilter.Value, '', DataItemXmlNode);
            XMLDOMMgt.AddAttribute(DataItemXmlNode, 'name', StrSubstNo('Table%1', TableFilter.Key));
        end;

        exit(XmlDoc.InnerXml);
    end;

    procedure GetRequestPageOptionValue(OptionName: Text; Parameters: Text): Text
    var
        FoundXmlNodeList: DotNet XmlNodeList;
        FoundXmlNode: DotNet XmlNode;
        TempValue: Text;
    begin
        if not FindNodes(FoundXmlNodeList, Parameters, OptionPathTxt) then
            exit('');

        foreach FoundXmlNode in FoundXmlNodeList do begin
            TempValue := FoundXmlNode.Attributes.ItemOf('name').Value();
            if Format(TempValue) = Format(OptionName) then
                exit(FoundXmlNode.InnerText);
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

