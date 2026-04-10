namespace System.TestTools.TestRunner;

using System;
using System.IO;
using System.Reflection;
using System.Xml;

codeunit 130404 "CAL Test Project Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        XMLDOMMgt: Codeunit "XML DOM Management";
        FileDialogFilterTxt: Label 'Test Project file (*.xml)|*.xml|All Files (*.*)|*.*', Locked = true;

    [Scope('OnPrem')]
    procedure Export(CALTestSuiteName: Code[10]): Boolean
    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestLine: Record "CAL Test Line";
        ProjectXML: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
        TestNode: DotNet XmlNode;
        XMLDataFile: Text;
        FileFilter: Text;
        ToFile: Text;
    begin
        XMLDOMMgt.LoadXMLDocumentFromText(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><%1></%1>', 'CALTests'),
          ProjectXML);

        CALTestSuite.Get(CALTestSuiteName);
        DocumentElement := ProjectXML.DocumentElement;
        XMLDOMMgt.AddAttribute(DocumentElement, CALTestSuite.FieldName(Name), CALTestSuite.Name);
        XMLDOMMgt.AddAttribute(DocumentElement, CALTestSuite.FieldName(Description), CALTestSuite.Description);

        CALTestLine.SetRange("Test Suite", CALTestSuite.Name);
        CALTestLine.SetRange("Line Type", CALTestLine."Line Type"::Codeunit);
        if CALTestLine.FindSet() then
            repeat
                TestNode := ProjectXML.CreateElement('Codeunit');
                XMLDOMMgt.AddAttribute(TestNode, 'ID', Format(CALTestLine."Test Codeunit"));
                DocumentElement.AppendChild(TestNode);
            until CALTestLine.Next() = 0;

        XMLDataFile := FileMgt.ServerTempFileName('');
        FileMgt.IsAllowedPath(XMLDataFile, false);
        FileFilter := GetFileDialogFilter();
        ToFile := 'PROJECT.xml';
        ProjectXML.Save(XMLDataFile);

        FileMgt.DownloadHandler(XMLDataFile, 'Download', '', FileFilter, ToFile);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Import()
    var
        CALTestSuite: Record "CAL Test Suite";
        AllObjWithCaption: Record AllObjWithCaption;
        CALTestManagement: Codeunit "CAL Test Management";
        ProjectXML: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
        TestNode: DotNet XmlNode;
        TestNodes: DotNet XmlNodeList;
        ServerFileName: Text;
        NodeCount: Integer;
        TestID: Integer;
    begin
        ServerFileName := FileMgt.ServerTempFileName('.xml');
        FileMgt.IsAllowedPath(ServerFileName, false);
        if UploadXMLPackage(ServerFileName) then begin
            XMLDOMMgt.LoadXMLDocumentFromFile(ServerFileName, ProjectXML);
            DocumentElement := ProjectXML.DocumentElement;

            CALTestSuite.Name :=
              CopyStr(
                GetAttribute(GetElementName(CALTestSuite.FieldName(Name)), DocumentElement), 1,
                MaxStrLen(CALTestSuite.Name));
            CALTestSuite.Description :=
              CopyStr(
                GetAttribute(GetElementName(CALTestSuite.FieldName(Description)), DocumentElement), 1,
                MaxStrLen(CALTestSuite.Description));
            if not CALTestSuite.Get(CALTestSuite.Name) then
                CALTestSuite.Insert();

            TestNodes := DocumentElement.ChildNodes;
            for NodeCount := 0 to (TestNodes.Count - 1) do begin
                TestNode := TestNodes.Item(NodeCount);
                if Evaluate(TestID, Format(GetAttribute('ID', TestNode))) then begin
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
                    AllObjWithCaption.SetRange("Object ID", TestID);
                    CALTestManagement.AddTestCodeunits(CALTestSuite, AllObjWithCaption);
                end;
            end;
        end;
    end;

    local procedure GetAttribute(AttributeName: Text; var XMLNode: DotNet XmlNode): Text
    var
        XMLAttributes: DotNet XmlNamedNodeMap;
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributes := XMLNode.Attributes;
        XMLAttributeNode := XMLAttributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');
        exit(Format(XMLAttributeNode.InnerText));
    end;

    local procedure GetElementName(NameIn: Text): Text
    begin
        NameIn := DelChr(NameIn, '=', 'Ž»''`');
        NameIn := ConvertStr(NameIn, '<>,./\+&()%:', '            ');
        NameIn := ConvertStr(NameIn, '-', '_');
        NameIn := DelChr(NameIn, '=', ' ');
        if NameIn[1] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] then
            NameIn := '_' + NameIn;
        exit(NameIn);
    end;

    local procedure GetFileDialogFilter(): Text
    begin
        exit(FileDialogFilterTxt);
    end;

    local procedure UploadXMLPackage(ServerFileName: Text): Boolean
    begin
        exit(Upload('Import project', '', GetFileDialogFilter(), '', ServerFileName));
    end;
}

