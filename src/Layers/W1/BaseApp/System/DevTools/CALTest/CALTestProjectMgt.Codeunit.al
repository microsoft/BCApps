namespace System.TestTools.TestRunner;

using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 130404 "CAL Test Project Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        FileDialogFilterTxt: Label 'Test Project file (*.xml)|*.xml|All Files (*.*)|*.*', Locked = true;

    [Scope('OnPrem')]
    procedure Export(CALTestSuiteName: Code[10]): Boolean
    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestLine: Record "CAL Test Line";
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

        CALTestSuite.Get(CALTestSuiteName);
        DocumentElement.SetAttribute(CALTestSuite.FieldName(Name), CALTestSuite.Name);
        DocumentElement.SetAttribute(CALTestSuite.FieldName(Description), CALTestSuite.Description);

        CALTestLine.SetRange("Test Suite", CALTestSuite.Name);
        CALTestLine.SetRange("Line Type", CALTestLine."Line Type"::Codeunit);
        if CALTestLine.FindSet() then
            repeat
                TestElement := XmlElement.Create('Codeunit');
                TestElement.SetAttribute('ID', Format(CALTestLine."Test Codeunit"));
                DocumentElement.Add(TestElement);
            until CALTestLine.Next() = 0;

        XMLDataFile := FileMgt.ServerTempFileName('');
        FileMgt.IsAllowedPath(XMLDataFile, false);
        FileFilter := GetFileDialogFilter();
        ToFile := 'PROJECT.xml';
        SaveXmlDocumentToServerFile(ProjectXML, XMLDataFile);

        FileMgt.DownloadHandler(XMLDataFile, 'Download', '', FileFilter, ToFile);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Import()
    var
        CALTestSuite: Record "CAL Test Suite";
        AllObjWithCaption: Record AllObjWithCaption;
        CALTestManagement: Codeunit "CAL Test Management";
        TempBlob: Codeunit "Temp Blob";
        ProjectXML: XmlDocument;
        DocumentElement: XmlElement;
        TestNode: XmlNode;
        ProjectInStream: InStream;
        ServerFileName: Text;
        TestID: Integer;
    begin
        ServerFileName := FileMgt.ServerTempFileName('.xml');
        FileMgt.IsAllowedPath(ServerFileName, false);
        if UploadXMLPackage(ServerFileName) then begin
            FileMgt.BLOBImportFromServerFile(TempBlob, ServerFileName);
            TempBlob.CreateInStream(ProjectInStream);
            XmlDocument.ReadFrom(ProjectInStream, ProjectXML);
            ProjectXML.GetRoot(DocumentElement);

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

            foreach TestNode in DocumentElement.GetChildElements() do
                if Evaluate(TestID, Format(GetAttribute('ID', TestNode.AsXmlElement()))) then begin
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
                    AllObjWithCaption.SetRange("Object ID", TestID);
                    CALTestManagement.AddTestCodeunits(CALTestSuite, AllObjWithCaption);
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

