namespace System.IO;

using System.Utilities;
using System.Xml;

codeunit 1203 "Import XML File to Data Exch."
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    begin
        StartTime := CurrentDateTime;
        UpdateProgressWindow(0);

        ParseParentChildDocument(Rec);

        if GuiAllowed and WindowOpen then
            ProgressWindow.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Preparing line number #1#######';
#pragma warning restore AA0470
        ProgressWindow: Dialog;
        WindowOpen: Boolean;
        StartTime: DateTime;

    local procedure ParseParentChildDocument(DataExch: Record "Data Exch.")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        XmlNodeList: XmlNodeList;
        XmlNamespaceManager: XmlNamespaceManager;
        CurrentXmlNode: XmlNode;
        XmlStream: InStream;
        CurrentLineNo: Integer;
        NodeID: Text[250];
    begin
        DataExchDef.Get(DataExch."Data Exch. Def Code");
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Parent Code", '');
        if not DataExchLineDef.FindSet() then
            exit;

        DataExch."File Content".CreateInStream(XmlStream);
        XmlDocument.ReadFrom(XmlStream, XmlDoc);
        XmlDoc.GetRoot(RootElement);
        RemoveWhitespaceNodes(RootElement);
        DataExchLineDef.ValidateNamespace(RootElement);
        AddNamespaces(XmlNamespaceManager, XmlDoc, RootElement);

        repeat
            XmlDoc.SelectNodes(EscapeMissingNamespacePrefix(DataExchLineDef."Data Line Tag"), XmlNamespaceManager, XmlNodeList);
            CurrentLineNo := 1;
            foreach CurrentXmlNode in XmlNodeList do begin
                NodeID := IncreaseNodeID('', CurrentLineNo);
                ParseParentChildLine(
                  CurrentXmlNode, NodeID, '', CurrentLineNo, DataExchLineDef, DataExch."Entry No.", XmlNamespaceManager);
                CurrentLineNo += 1;
            end;
        until DataExchLineDef.Next() = 0;
    end;

    local procedure AddNamespaces(var XmlNamespaceManager: XmlNamespaceManager; XmlDoc: XmlDocument; RootElement: XmlElement)
    var
        XmlAttribute: XmlAttribute;
    begin
        XmlNamespaceManager.NameTable(XmlDoc.NameTable());

        if RootElement.NamespaceUri() <> '' then
            XmlNamespaceManager.AddNamespace('', RootElement.NamespaceUri());

        foreach XmlAttribute in RootElement.Attributes() do
            if XmlAttribute.IsNamespaceDeclaration() and (XmlAttribute.NamespaceUri() <> '') then // xmlns:prefix="..."
                XmlNamespaceManager.AddNamespace(XmlAttribute.LocalName(), XmlAttribute.Value());
    end;

    local procedure RemoveWhitespaceNodes(ParentXmlElement: XmlElement)
    var
        ChildNodes: XmlNodeList;
        ChildNode: XmlNode;
        XmlSpaceAttribute: XmlAttribute;
        Whitespace: Text;
        Tab: Char;
        LineFeed: Char;
        CarriageReturn: Char;
        i: Integer;
    begin
        // Like the .NET XmlDocument with PreserveWhitespace = false, drop insignificant whitespace unless xml:space="preserve"
        if ParentXmlElement.Attributes().Get('space', 'http://www.w3.org/XML/1998/namespace', XmlSpaceAttribute) then
            if XmlSpaceAttribute.Value() = 'preserve' then
                exit;
        Tab := 9;
        LineFeed := 10;
        CarriageReturn := 13;
        Whitespace := ' ' + Format(Tab) + Format(LineFeed) + Format(CarriageReturn);
        ChildNodes := ParentXmlElement.GetChildNodes();
        for i := ChildNodes.Count() downto 1 do begin
            ChildNodes.Get(i, ChildNode);
            if ChildNode.IsXmlText() then begin
                if DelChr(ChildNode.AsXmlText().Value(), '=', Whitespace) = '' then
                    ChildNode.Remove();
            end else
                if ChildNode.IsXmlElement() then
                    RemoveWhitespaceNodes(ChildNode.AsXmlElement());
        end;
    end;

    local procedure ParseParentChildLine(CurrentXmlNode: XmlNode; NodeID: Text[250]; ParentNodeID: Text[250]; CurrentLineNo: Integer; CurrentDataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; XmlNamespaceManager: XmlNamespaceManager)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchField: Record "Data Exch. Field";
        XmlNodeList: XmlNodeList;
        FoundXmlNode: XmlNode;
        CurrentIndex: Integer;
        CurrentNodeID: Text[250];
        InnerText: Text;
        InnerXml: Text;
        OuterXml: Text;
        LastLineNo: Integer;
    begin
        DataExchField.InsertRecXMLFieldDefinition(EntryNo, CurrentLineNo, NodeID, ParentNodeID, '', CurrentDataExchLineDef.Code);

        // Insert Attributes and values
        DataExchColumnDef.SetRange("Data Exch. Def Code", CurrentDataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", CurrentDataExchLineDef.Code);
        DataExchColumnDef.SetFilter(Path, '<>%1', '');

        CurrentIndex := 1;

        if DataExchColumnDef.FindSet() then
            repeat
                CurrentXmlNode.SelectNodes(
                  GetRelativePath(DataExchColumnDef.Path, CurrentDataExchLineDef."Data Line Tag"),
                  XmlNamespaceManager,
                  XmlNodeList);

                foreach FoundXmlNode in XmlNodeList do begin
                    CurrentNodeID := IncreaseNodeID(NodeID, CurrentIndex);
                    CurrentIndex += 1;
                    InnerText := GetNodeInnerText(FoundXmlNode);
                    GetNodeXml(FoundXmlNode, InnerXml, OuterXml);
                    OnParseParentChildLineOnBeforeInsertColumn(InnerText, InnerXml, OuterXml, DataExchColumnDef);
                    InsertColumn(
                      DataExchColumnDef."Column No.", CurrentLineNo, CurrentNodeID, ParentNodeID, GetNodeName(FoundXmlNode),
                      InnerText, CurrentDataExchLineDef, EntryNo);
                end;
            until DataExchColumnDef.Next() = 0;

        // insert Constant values
        DataExchColumnDef.SetFilter(Path, '%1', '');
        DataExchColumnDef.SetFilter(Constant, '<>%1', '');
        if DataExchColumnDef.FindSet() then
            repeat
                CurrentNodeID := IncreaseNodeID(NodeID, CurrentIndex);
                CurrentIndex += 1;
                DataExchField.InsertRecXMLFieldWithParentNodeID(EntryNo, CurrentLineNo, DataExchColumnDef."Column No.",
                  CurrentNodeID, ParentNodeID, DataExchColumnDef.Constant, CurrentDataExchLineDef.Code);
            until DataExchColumnDef.Next() = 0;

        // Insert Children
        DataExchLineDef.SetRange("Data Exch. Def Code", CurrentDataExchLineDef."Data Exch. Def Code");
        DataExchLineDef.SetRange("Parent Code", CurrentDataExchLineDef.Code);

        if DataExchLineDef.FindSet() then
            repeat
                CurrentXmlNode.SelectNodes(
                  GetRelativePath(DataExchLineDef."Data Line Tag", CurrentDataExchLineDef."Data Line Tag"),
                  XmlNamespaceManager,
                  XmlNodeList);

                DataExchField.SetRange("Data Exch. No.", EntryNo);
                DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                LastLineNo := 1;
                if DataExchField.FindLast() then
                    LastLineNo := DataExchField."Line No." + 1;

                foreach FoundXmlNode in XmlNodeList do begin
                    CurrentNodeID := IncreaseNodeID(NodeID, CurrentIndex);
                    ParseParentChildLine(
                      FoundXmlNode, CurrentNodeID, NodeID, LastLineNo, DataExchLineDef, EntryNo, XmlNamespaceManager);
                    CurrentIndex += 1;
                    LastLineNo += 1;
                end;
            until DataExchLineDef.Next() = 0;
    end;

    local procedure GetNodeName(XmlNode: XmlNode): Text
    begin
        case true of
            XmlNode.IsXmlElement():
                exit(GetElementName(XmlNode.AsXmlElement()));
            XmlNode.IsXmlAttribute():
                exit(XmlNode.AsXmlAttribute().Name());
            XmlNode.IsXmlText():
                exit('#text');
            XmlNode.IsXmlCData():
                exit('#cdata-section');
        end;
        exit('');
    end;

    local procedure GetElementName(CurrentXmlElement: XmlElement): Text
    var
        ElementName: Text;
    begin
        // Name() returns ":LocalName" for an element in a default namespace; the qualified name has no prefix then
        ElementName := CurrentXmlElement.Name();
        if CopyStr(ElementName, 1, 1) = ':' then
            exit(CopyStr(ElementName, 2));
        exit(ElementName);
    end;

    local procedure GetNodeInnerText(XmlNode: XmlNode): Text
    begin
        case true of
            XmlNode.IsXmlElement():
                exit(XmlNode.AsXmlElement().InnerText());
            XmlNode.IsXmlAttribute():
                exit(XmlNode.AsXmlAttribute().Value());
            XmlNode.IsXmlText():
                exit(XmlNode.AsXmlText().Value());
            XmlNode.IsXmlCData():
                exit(XmlNode.AsXmlCData().Value());
        end;
        exit('');
    end;

    local procedure GetNodeXml(XmlNode: XmlNode; var InnerXml: Text; var OuterXml: Text)
    var
        XmlWriteOptions: XmlWriteOptions;
        ValueStartPos: Integer;
    begin
        InnerXml := '';
        OuterXml := '';
        // Keep the formatting of the source document, like the .NET OuterXml/InnerXml properties do
        XmlWriteOptions.PreserveWhitespace(true);
        case true of
            XmlNode.IsXmlElement():
                begin
                    InnerXml := XmlNode.AsXmlElement().InnerXml();
                    XmlNode.WriteTo(XmlWriteOptions, OuterXml);
                end;
            XmlNode.IsXmlAttribute():
                begin
                    // name="value": the inner XML of an attribute is its escaped value
                    XmlNode.WriteTo(XmlWriteOptions, OuterXml);
                    ValueStartPos := StrPos(OuterXml, '="');
                    if ValueStartPos > 0 then
                        InnerXml := CopyStr(OuterXml, ValueStartPos + 2, StrLen(OuterXml) - ValueStartPos - 2);
                end;
            else
                XmlNode.WriteTo(XmlWriteOptions, OuterXml);
        end;
    end;

    local procedure InsertColumn(ColumnNo: Integer; LineNo: Integer; NodeId: Text[250]; ParentNodeId: Text[250]; Name: Text; Value: Text; var DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
    begin
        // Note: The Data Exch. variable is passed by reference only to improve performance.
        if DataExchColumnDef.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, ColumnNo) then begin
            UpdateProgressWindow(LineNo);
            if DataExchColumnDef."Use Node Name as Value" then
                DataExchField.InsertRecXMLFieldWithParentNodeID(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, ParentNodeId, Name,
                  DataExchLineDef.Code)
            else
                DataExchField.InsertRecXMLFieldWithParentNodeID(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, ParentNodeId, Value,
                  DataExchLineDef.Code);
        end;
    end;

    local procedure GetRelativePath(ChildPath: Text[250]; ParentPath: Text[250]): Text
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        exit(EscapeMissingNamespacePrefix(XMLDOMManagement.GetRelativePath(ChildPath, ParentPath)));
    end;

    local procedure IncreaseNodeID(NodeID: Text[250]; Seed: Integer): Text[250]
    begin
        exit(NodeID + Format(Seed, 0, '<Integer,4><Filler Char,0>'))
    end;

    procedure EscapeMissingNamespacePrefix(XPath: Text): Text
    var
        Regex: Codeunit Regex;
        PositionOfFirstSlash: Integer;
        FirstXPathElement: Text;
        RestOfXPath: Text;
        RegexPattern: Text;
    begin
        // we will let the user define XPaths without the required namespace prefix
        // however, if he does that, we will only consider the XPath element as a local name
        // for example, we will turn XPath /Invoice/cac:InvoiceLine into /*[local-name() = 'Invoice']/cac:InvoiceLine
        PositionOfFirstSlash := StrPos(XPath, '/');
        case PositionOfFirstSlash of
            1:
                exit('/' + EscapeMissingNamespacePrefix(CopyStr(XPath, 2)));
            0:
                begin
                    RegexPattern := '^[a-zA-Z0-9]*$';
                    OnBeforeAssignRegexPattern(RegexPattern);
                    if (XPath = '') or (not Regex.IsMatch(XPath, RegexPattern)) then
                        exit(XPath);
                    exit(StrSubstNo('*[local-name() = ''%1'']', XPath));
                end;
            else begin
                FirstXPathElement := DelStr(XPath, PositionOfFirstSlash);
                RestOfXPath := CopyStr(XPath, PositionOfFirstSlash);
                exit(EscapeMissingNamespacePrefix(FirstXPathElement) + EscapeMissingNamespacePrefix(RestOfXPath));
            end;
        end;
    end;

    local procedure UpdateProgressWindow(LineNo: Integer)
    var
        PopupDelay: Integer;
    begin
        if not GuiAllowed then
            exit;
        PopupDelay := 1000;
        if CurrentDateTime - StartTime < PopupDelay then
            exit;

        StartTime := CurrentDateTime; // only update every PopupDelay ms

        if not WindowOpen then begin
            ProgressWindow.Open(ProgressMsg);
            WindowOpen := true;
        end;

        ProgressWindow.Update(1, LineNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignRegexPattern(var RegexPattern: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnParseParentChildLineOnBeforeInsertColumn(var InnerText: Text; InnerXML: Text; OuterXML: Text; DataExchColumnDef: Record "Data Exch. Column Def")
    begin
    end;
}

