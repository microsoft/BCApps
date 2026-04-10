namespace System.IO;

using System;
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
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
        XmlNamespaceManager: DotNet XmlNamespaceManager;
        XmlStream: InStream;
        CurrentLineNo: Integer;
        NodeID: Text[250];
        I: Integer;
        NodeCount: Integer;
    begin
        DataExchDef.Get(DataExch."Data Exch. Def Code");
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Parent Code", '');
        if not DataExchLineDef.FindSet() then
            exit;

        DataExch."File Content".CreateInStream(XmlStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(XmlStream, XmlDocument);
        DataExchLineDef.ValidateNamespace(XmlDocument.DocumentElement);
        XMLDOMManagement.AddNamespaces(XmlNamespaceManager, XmlDocument);

        repeat
            XMLDOMManagement.FindNodesWithNamespaceManager(
              XmlDocument, EscapeMissingNamespacePrefix(DataExchLineDef."Data Line Tag"), XmlNamespaceManager, XmlNodeList);
            CurrentLineNo := 1;
            NodeCount := XmlNodeList.Count();
            for I := 1 to NodeCount do begin
                NodeID := IncreaseNodeID('', CurrentLineNo);
                ParseParentChildLine(
                  XmlNodeList.ItemOf(I - 1), NodeID, '', CurrentLineNo, DataExchLineDef, DataExch."Entry No.", XmlNamespaceManager);
                CurrentLineNo += 1;
            end;
        until DataExchLineDef.Next() = 0;
    end;

    local procedure ParseParentChildLine(CurrentXmlNode: DotNet XmlNode; NodeID: Text[250]; ParentNodeID: Text[250]; CurrentLineNo: Integer; CurrentDataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; XmlNamespaceManager: DotNet XmlNamespaceManager)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchField: Record "Data Exch. Field";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNodeList: DotNet XmlNodeList;
        CurrentIndex: Integer;
        CurrentNodeID: Text[250];
        InnerText: Text;
        LastLineNo: Integer;
        I: Integer;
        NodeCount: Integer;
    begin
        DataExchField.InsertRecXMLFieldDefinition(EntryNo, CurrentLineNo, NodeID, ParentNodeID, '', CurrentDataExchLineDef.Code);

        // Insert Attributes and values
        DataExchColumnDef.SetRange("Data Exch. Def Code", CurrentDataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", CurrentDataExchLineDef.Code);
        DataExchColumnDef.SetFilter(Path, '<>%1', '');

        CurrentIndex := 1;

        if DataExchColumnDef.FindSet() then
            repeat
                XMLDOMManagement.FindNodesWithNamespaceManager(
                  CurrentXmlNode,
                  GetRelativePath(DataExchColumnDef.Path, CurrentDataExchLineDef."Data Line Tag"),
                  XmlNamespaceManager,
                  XmlNodeList);

                NodeCount := XmlNodeList.Count();
                for I := 1 to NodeCount do begin
                    CurrentNodeID := IncreaseNodeID(NodeID, CurrentIndex);
                    CurrentIndex += 1;
                    InnerText := XmlNodeList.ItemOf(I - 1).InnerText;
                    OnParseParentChildLineOnBeforeInsertColumn(InnerText, XmlNodeList.ItemOf(I - 1).InnerXml, XmlNodeList.ItemOf(I - 1).OuterXML, DataExchColumnDef);
                    InsertColumn(
                      DataExchColumnDef."Column No.", CurrentLineNo, CurrentNodeID, ParentNodeID, XmlNodeList.ItemOf(I - 1).Name,
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
                XMLDOMManagement.FindNodesWithNamespaceManager(
                  CurrentXmlNode,
                  GetRelativePath(DataExchLineDef."Data Line Tag", CurrentDataExchLineDef."Data Line Tag"),
                  XmlNamespaceManager,
                  XmlNodeList);

                DataExchField.SetRange("Data Exch. No.", EntryNo);
                DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                LastLineNo := 1;
                if DataExchField.FindLast() then
                    LastLineNo := DataExchField."Line No." + 1;

                NodeCount := XmlNodeList.Count();
                for I := 1 to NodeCount do begin
                    CurrentNodeID := IncreaseNodeID(NodeID, CurrentIndex);
                    ParseParentChildLine(
                      XmlNodeList.ItemOf(I - 1), CurrentNodeID, NodeID, LastLineNo, DataExchLineDef, EntryNo, XmlNamespaceManager);
                    CurrentIndex += 1;
                    LastLineNo += 1;
                end;
            until DataExchLineDef.Next() = 0;
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

