codeunit 130024 "Test Project Management"
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        FileDialogFilterTxt: Label 'Test Project file (*.xml)|*.xml|All Files (*.*)|*.*', Locked = true;
        XMLDOMMgt: Codeunit "XML DOM Management";

    [Scope('OnPrem')]
    procedure Export(TestSuiteName: Code[10]): Boolean
    var
        TestSuite: Record "Test Suite";
        TestLine: Record "Test Line";
        ProjectXML: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
        TestNode: DotNet XmlNode;
        XMLDataFile: Text;
        FileFilter: Text;
        ToFile: Text;
        XmlText: Text;
    begin
        XmlText := StrSubstNo('<?xml version="1.0" encoding="UTF-16" standalone="yes"?><%1></%1>', 'CALTests');
        XMLDOMMgt.LoadXMLDocumentFromText(XmlText, ProjectXML);
        DocumentElement := ProjectXML.DocumentElement;

        TestSuite.Get(TestSuiteName);
        XMLDOMMgt.AddAttribute(DocumentElement, TestSuite.FieldName(Name), TestSuite.Name);
        XMLDOMMgt.AddAttribute(DocumentElement, TestSuite.FieldName(Description), TestSuite.Description);

        TestLine.SetRange("Test Suite", TestSuite.Name);
        TestLine.SetRange("Line Type", TestLine."Line Type"::Codeunit);
        if TestLine.FindSet() then
            repeat
                TestNode := ProjectXML.CreateElement('Codeunit');
                XMLDOMMgt.AddAttribute(TestNode, 'ID', Format(TestLine."Test Codeunit"));
                DocumentElement.AppendChild(TestNode);
            until TestLine.Next() = 0;

        XMLDataFile := FileMgt.ServerTempFileName('');
        FileFilter := GetFileDialogFilter();
        ToFile := 'PROJECT.xml';
        ProjectXML.Save(XMLDataFile);

        FileMgt.DownloadHandler(XMLDataFile, 'Download', '', FileFilter, ToFile);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Import()
    var
        TestSuite: Record "Test Suite";
        AllObjWithCaption: Record AllObjWithCaption;
        TestManagement: Codeunit "Test Management";
        ProjectXML: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
        TestNode: DotNet XmlNode;
        TestNodes: DotNet XmlNodeList;
        ServerFileName: Text;
        NodeCount: Integer;
        TestID: Integer;
    begin
        ServerFileName := FileMgt.ServerTempFileName('.xml');
        if UploadXMLPackage(ServerFileName) then begin
            XMLDOMMgt.LoadXMLDocumentFromFile(ServerFileName, ProjectXML);
            DocumentElement := ProjectXML.DocumentElement;

            TestSuite.Name :=
              CopyStr(
                GetAttribute(GetElementName(TestSuite.FieldName(Name)), DocumentElement), 1,
                MaxStrLen(TestSuite.Name));
            TestSuite.Description :=
              CopyStr(
                GetAttribute(GetElementName(TestSuite.FieldName(Description)), DocumentElement), 1,
                MaxStrLen(TestSuite.Description));
            if not TestSuite.Get(TestSuite.Name) then
                TestSuite.Insert();

            TestNodes := DocumentElement.ChildNodes;
            for NodeCount := 0 to (TestNodes.Count - 1) do begin
                TestNode := TestNodes.Item(NodeCount);
                if Evaluate(TestID, Format(GetAttribute('ID', TestNode))) then begin
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
                    AllObjWithCaption.SetRange("Object ID", TestID);
                    TestManagement.AddTestCodeunits(TestSuite, AllObjWithCaption);
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
        NameIn := DelChr(NameIn, '=', '´''`');
        NameIn := DelChr(ConvertStr(NameIn, '<>,./\+-&()%:', '             '), '=', ' ');
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

