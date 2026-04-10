namespace System.IO;

using System;
using System.Integration;
using System.Utilities;

codeunit 1237 "Get Json Structure"
{

    trigger OnRun()
    begin
    end;

    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        JsonConvert: DotNet JsonConvert;
        GLBHttpStatusCode: DotNet HttpStatusCode;
        GLBResponseHeaders: DotNet NameValueCollection;
        FileContent: Text;
        InvalidResponseErr: Label 'The response was not valid.';

    [Scope('OnPrem')]
    procedure GenerateStructure(Path: Text; var XMLBuffer: Record "XML Buffer")
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlobResponse: Codeunit "Temp Blob";
        XMLBufferWriter: Codeunit "XML Buffer Writer";
        JsonInStream: InStream;
        XMLOutStream: OutStream;
        File: File;
    begin
        if File.Open(Path) then
            File.CreateInStream(JsonInStream)
        else begin
            TempBlobResponse.CreateInStream(JsonInStream);
            Clear(HttpWebRequestMgt);
            HttpWebRequestMgt.Initialize(Path);
            HttpWebRequestMgt.SetMethod('POST');
            HttpWebRequestMgt.SetReturnType('application/json');
            HttpWebRequestMgt.SetContentType('application/x-www-form-urlencoded');
            HttpWebRequestMgt.AddHeader('Accept-Encoding', 'utf-8');
            HttpWebRequestMgt.GetResponse(JsonInStream, GLBHttpStatusCode, GLBResponseHeaders);
        end;

        TempBlob.CreateOutStream(XMLOutStream);
        if not JsonToXML(JsonInStream, XMLOutStream) then
            if not JsonToXMLCreateDefaultRoot(JsonInStream, XMLOutStream) then
                Error(InvalidResponseErr);

        XMLBufferWriter.GenerateStructure(XMLBuffer, XMLOutStream);
    end;

    [TryFunction]
    procedure JsonToXML(JsonInStream: InStream; var XMLOutStream: OutStream)
    var
        XmlDocument: DotNet XmlDocument;
        NewContent: Text;
    begin
        while not JsonInStream.EOS do begin
            JsonInStream.Read(NewContent);
            FileContent += NewContent;
        end;

        XmlDocument := JsonConvert.DeserializeXmlNode(FileContent);
        XmlDocument.Save(XMLOutStream);
    end;

    [TryFunction]
    procedure JsonToXMLCreateDefaultRoot(JsonInStream: InStream; var XMLOutStream: OutStream)
    var
        XmlDocument: DotNet XmlDocument;
        NewContent: Text;
    begin
        while not JsonInStream.EOS do begin
            JsonInStream.Read(NewContent);
            FileContent += NewContent;
        end;
        FileContent := '{"root":' + FileContent + '}';

        XmlDocument := JsonConvert.DeserializeXmlNode(FileContent, 'root');
        XmlDocument.Save(XMLOutStream);
    end;
}

