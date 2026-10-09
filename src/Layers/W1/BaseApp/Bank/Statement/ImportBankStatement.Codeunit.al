// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using System.IO;

/// <summary>
/// Handles the import and parsing of bank statement files in XML format through the data exchange framework.
/// Processes XML bank statement files and converts them into structured data exchange records.
/// </summary>
/// <remarks>
/// Parses XML bank statement files according to configured data exchange definitions.
/// Creates data exchange field records for further processing by bank statement import workflows.
/// Integrates with Data Exchange Framework for standardized file processing and error handling.
/// </remarks>
codeunit 1200 "Import Bank Statement"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        XmlDoc: XmlDocument;
        RootXmlElement: XmlElement;
        XMLStream: InStream;
        LineNo: Integer;
    begin
        Rec."File Content".CreateInStream(XMLStream);
        XmlDocument.ReadFrom(XMLStream, XmlDoc);
        XmlDoc.GetRoot(RootXmlElement);

        DataExchLineDef.Get(Rec."Data Exch. Def Code", Rec."Data Exch. Line Def Code");

        ProgressWindow.Open(ProgressMsg);
        Parse(DataExchLineDef, Rec."Entry No.", RootXmlElement.AsXmlNode(), '', '', LineNo, LineNo);
        ProgressWindow.Close();
        OnRunOnAfterRun(Rec);
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Preparing line number #1#######';
#pragma warning restore AA0470
        ProgressWindow: Dialog;

    local procedure Parse(DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; CurrentXmlNode: XmlNode; ParentPath: Text; NodeId: Text[250]; var LastGivenLineNo: Integer; CurrentLineNo: Integer)
    var
        CurrentDataExchLineDef: Record "Data Exch. Line Def";
        CurrentXmlElement: XmlElement;
        ParentXmlElement: XmlElement;
        CurrentXmlAttribute: XmlAttribute;
        ChildXmlNodeList: XmlNodeList;
        ChildXmlNode: XmlNode;
        NodeLocalName: Text;
        i: Integer;
    begin
        NodeLocalName := GetNodeLocalName(CurrentXmlNode);
        CurrentDataExchLineDef.SetRange("Data Line Tag", ParentPath + '/' + NodeLocalName);
        CurrentDataExchLineDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        if CurrentDataExchLineDef.FindFirst() then begin
            DataExchLineDef := CurrentDataExchLineDef;
            LastGivenLineNo += 1;
            CurrentLineNo := LastGivenLineNo;
            if CurrentXmlNode.IsXmlElement() then
                DataExchLineDef.ValidateNamespace(CurrentXmlNode.AsXmlElement());
        end;

        case true of
            CurrentXmlNode.IsXmlText():
                begin
                    CurrentXmlNode.GetParent(ParentXmlElement);
                    InsertColumn(ParentPath,
                      CurrentLineNo, NodeId, CurrentXmlNode.AsXmlText().Value(), ParentXmlElement.Name(),
                      DataExchLineDef, EntryNo);
                end;
            CurrentXmlNode.IsXmlCData():
                begin
                    CurrentXmlNode.GetParent(ParentXmlElement);
                    InsertColumn(ParentPath,
                      CurrentLineNo, NodeId, CurrentXmlNode.AsXmlCData().Value(), ParentXmlElement.Name(),
                      DataExchLineDef, EntryNo);
                end;
        end;

        if not CurrentXmlNode.IsXmlElement() then
            exit;

        CurrentXmlElement := CurrentXmlNode.AsXmlElement();
        foreach CurrentXmlAttribute in CurrentXmlElement.Attributes() do
            InsertColumn(ParentPath + '/' + NodeLocalName + '[@' + CurrentXmlAttribute.Name() + ']',
              CurrentLineNo, NodeId, CurrentXmlAttribute.Value(), CurrentXmlAttribute.Name(),
              DataExchLineDef, EntryNo);

        // Whitespace-only text nodes are skipped (and not counted in the node ID), as the file is parsed without preserving whitespace.
        ChildXmlNodeList := CurrentXmlElement.GetChildNodes();
        foreach ChildXmlNode in ChildXmlNodeList do
            if not IsWhitespaceTextNode(ChildXmlNode) then begin
                i += 1;
                Parse(DataExchLineDef, EntryNo, ChildXmlNode, ParentPath + '/' + NodeLocalName,
                  NodeId + Format(i, 0, '<Integer,4><Filler Char,0>'), LastGivenLineNo, CurrentLineNo);
            end;
    end;

    local procedure IsWhitespaceTextNode(CurrentXmlNode: XmlNode): Boolean
    var
        Tab: Char;
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        if not CurrentXmlNode.IsXmlText() then
            exit(false);
        Tab := 9;
        LineFeed := 10;
        CarriageReturn := 13;
        exit(DelChr(CurrentXmlNode.AsXmlText().Value(), '=', ' ' + Format(Tab) + Format(LineFeed) + Format(CarriageReturn)) = '');
    end;

    local procedure GetNodeLocalName(CurrentXmlNode: XmlNode): Text
    var
        ProcessingInstructionTarget: Text;
    begin
        case true of
            CurrentXmlNode.IsXmlElement():
                exit(CurrentXmlNode.AsXmlElement().LocalName());
            CurrentXmlNode.IsXmlText():
                exit('#text');
            CurrentXmlNode.IsXmlCData():
                exit('#cdata-section');
            CurrentXmlNode.IsXmlComment():
                exit('#comment');
            CurrentXmlNode.IsXmlProcessingInstruction():
                begin
                    CurrentXmlNode.AsXmlProcessingInstruction().GetTarget(ProcessingInstructionTarget);
                    exit(ProcessingInstructionTarget);
                end;
        end;
        exit('');
    end;

    local procedure InsertColumn(Path: Text; LineNo: Integer; NodeId: Text[250]; Value: Text; Name: Text; var DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertColumn(DataExchLineDef, EntryNo, LineNo, NodeId, Name, ProgressWindow, IsHandled, Path, Value);
        if IsHandled then
            exit;

        // Note: The Data Exch. variable is passed by reference only to improve performance.
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Path, Path);

        if DataExchColumnDef.FindFirst() then begin
            ProgressWindow.Update(1, LineNo);
            if DataExchColumnDef."Use Node Name as Value" then
                DataExchField.InsertRecXMLField(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, Name,
                  DataExchLineDef.Code)
            else
                DataExchField.InsertRecXMLField(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, Value,
                  DataExchLineDef.Code);
        end;
    end;

    /// <summary>
    /// Integration event raised after completing the bank statement import run.
    /// </summary>
    /// <param name="DataExch">The data exchange record that was processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterRun(var DataExch: Record "Data Exch.")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a column during bank statement import processing.
    /// Allows custom handling of column data before insertion into data exchange fields.
    /// </summary>
    /// <param name="DataExchLineDef">The data exchange line definition being processed.</param>
    /// <param name="EntryNo">The entry number of the data exchange record.</param>
    /// <param name="LineNo">The line number being processed.</param>
    /// <param name="NodeId">The XML node identifier.</param>
    /// <param name="Name">The column name.</param>
    /// <param name="ProgressWindow">The progress dialog window.</param>
    /// <param name="IsHandled">Set to true to skip the default column insertion processing.</param>
    /// <param name="Path">The XML path to the data.</param>
    /// <param name="Value">The column value to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertColumn(var DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; LineNo: Integer; NodeId: Text[250]; Name: Text; var ProgressWindow: Dialog; var IsHandled: Boolean; Path: Text; Value: Text)
    begin
    end;
}

