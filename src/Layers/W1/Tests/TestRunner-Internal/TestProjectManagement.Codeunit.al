codeunit 130024 "Test Project Management"
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        FileDialogFilterTxt: Label 'Test Project file (*.xml)|*.xml|All Files (*.*)|*.*', Locked = true;

    [Scope('OnPrem')]
    procedure Export(TestSuiteName: Code[10]): Boolean
    var
        TestSuite: Record "Test Suite";
        TestLine: Record "Test Line";
        ProjectXML: XmlDocument;
        DocumentElement: XmlElement;
        TestElement: XmlElement;
        XMLDataFile: Text;
        FileFilter: Text;
        ToFile: Text;
    begin
        ProjectXML := XmlDocument.Create();
        ProjectXML.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-16', 'yes'));
        DocumentElement := XmlElement.Create('CALTests');
        ProjectXML.Add(DocumentElement);

        TestSuite.Get(TestSuiteName);
        DocumentElement.SetAttribute(TestSuite.FieldName(Name), TestSuite.Name);
        DocumentElement.SetAttribute(TestSuite.FieldName(Description), TestSuite.Description);

        TestLine.SetRange("Test Suite", TestSuite.Name);
        TestLine.SetRange("Line Type", TestLine."Line Type"::Codeunit);
        if TestLine.FindSet() then
            repeat
                TestElement := XmlElement.Create('Codeunit');
                TestElement.SetAttribute('ID', Format(TestLine."Test Codeunit"));
                DocumentElement.Add(TestElement);
            until TestLine.Next() = 0;

        XMLDataFile := FileMgt.ServerTempFileName('');
        FileFilter := GetFileDialogFilter();
        ToFile := 'PROJECT.xml';
        SaveXmlDocumentToServerFile(ProjectXML, XMLDataFile);

        FileMgt.DownloadHandler(XMLDataFile, 'Download', '', FileFilter, ToFile);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Import()
    var
        TestSuite: Record "Test Suite";
        AllObjWithCaption: Record AllObjWithCaption;
        TestManagement: Codeunit "Test Management";
        TempBlob: Codeunit "Temp Blob";
        ProjectXML: XmlDocument;
        DocumentElement: XmlElement;
        TestNode: XmlNode;
        ProjectInStream: InStream;
        ServerFileName: Text;
        TestID: Integer;
    begin
        ServerFileName := FileMgt.ServerTempFileName('.xml');
        if UploadXMLPackage(ServerFileName) then begin
            FileMgt.BLOBImportFromServerFile(TempBlob, ServerFileName);
            TempBlob.CreateInStream(ProjectInStream);
            XmlDocument.ReadFrom(ProjectInStream, ProjectXML);
            ProjectXML.GetRoot(DocumentElement);

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

            foreach TestNode in DocumentElement.GetChildElements() do
                if Evaluate(TestID, Format(GetAttribute('ID', TestNode.AsXmlElement()))) then begin
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
                    AllObjWithCaption.SetRange("Object ID", TestID);
                    TestManagement.AddTestCodeunits(TestSuite, AllObjWithCaption);
                end;
        end;
    end;

    local procedure GetAttribute(AttributeName: Text; ParentXmlElement: XmlElement): Text
    var
        FoundXmlAttribute: XmlAttribute;
    begin
        if not ParentXmlElement.Attributes().Get(AttributeName, FoundXmlAttribute) then
            exit('');
        exit(Format(FoundXmlAttribute.Value()));
    end;

    local procedure SaveXmlDocumentToServerFile(ProjectXML: XmlDocument; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ProjectFile: File;
        BlobOutStream: OutStream;
        FileOutStream: OutStream;
        BlobInStream: InStream;
        ByteOrderMark: Char;
        ProjectXMLText: Text;
    begin
        ProjectXML.WriteTo(ProjectXMLText);
        ByteOrderMark := 65279;
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF16);
        BlobOutStream.WriteText(Format(ByteOrderMark) + ProjectXMLText);

        ProjectFile.WriteMode(true);
        ProjectFile.Create(FileName);
        ProjectFile.CreateOutStream(FileOutStream);
        TempBlob.CreateInStream(BlobInStream);
        CopyStream(FileOutStream, BlobInStream);
        ProjectFile.Close();
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

