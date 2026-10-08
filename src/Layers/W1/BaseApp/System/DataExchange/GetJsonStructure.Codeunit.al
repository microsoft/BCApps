namespace System.IO;

using System;
using System.Utilities;

codeunit 1237 "Get Json Structure"
{

    trigger OnRun()
    begin
    end;

    var
        JsonConvert: DotNet JsonConvert;
        FileContent: Text;
        InvalidResponseErr: Label 'The response was not valid.';

    [Scope('OnPrem')]
    procedure GenerateStructure(Path: Text; var XMLBuffer: Record "XML Buffer")
    var
        TempBlob: Codeunit "Temp Blob";
        XMLBufferWriter: Codeunit "XML Buffer Writer";
        JsonInStream: InStream;
        XMLOutStream: OutStream;
        File: File;
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
    begin
        if File.Open(Path) then
            File.CreateInStream(JsonInStream)
        else begin
            HttpRequestMessage.Method('POST');
            HttpRequestMessage.SetRequestUri(Path);
            HttpRequestMessage.GetHeaders(HttpHeaders);
            HttpHeaders.Add('Accept', 'application/json');
            HttpHeaders.Add('Accept-Encoding', 'utf-8');
            HttpContent.GetHeaders(HttpHeaders);
            HttpHeaders.Remove('Content-Type');
            HttpHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
            HttpRequestMessage.Content(HttpContent);
            if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
                Error(InvalidResponseErr);
            if not HttpResponseMessage.IsSuccessStatusCode() then
                Error(InvalidResponseErr);
            HttpResponseMessage.Content.ReadAs(JsonInStream);
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
