// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

using System.RestClient;
using System.Utilities;

codeunit 2355 "Http Content Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    Access = Internal;

    var
        HttpContent: HttpContent;
        ContentTypeEmptyErr: Label 'The value of the Content-Type header must be specified.';
        MimeTypeTextPlainTxt: Label 'text/plain', Locked = true;
        MimeTypeTextXmlTxt: Label 'text/xml', Locked = true;
        MimeTypeApplicationOctetStreamTxt: Label 'application/octet-stream', Locked = true;
        MimeTypeApplicationJsonTxt: Label 'application/json', Locked = true;

    #region Constructors
    procedure Create(Content: Text) HttpContentImpl: Codeunit "Http Content Impl."
    begin
        HttpContentImpl := Create(Content, '');
    end;

    procedure Create(Content: SecretText) HttpContentImpl: Codeunit "Http Content Impl."
    begin
        HttpContentImpl := Create(Content, '');
    end;

    procedure Create(Content: Text; ContentType: Text): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content, ContentType);
        exit(this);
    end;

    procedure Create(Content: SecretText; ContentType: Text): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content, ContentType);
        exit(this);
    end;

    procedure Create(Content: JsonObject): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content.AsToken());
        exit(this);
    end;

    procedure Create(Content: JsonArray): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content.AsToken());
        exit(this);
    end;

    procedure Create(Content: JsonToken): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content);
        exit(this);
    end;

    procedure Create(Content: XmlDocument): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content);
        exit(this);
    end;

    procedure Create(Content: Codeunit "Temp Blob") HttpContentImpl: Codeunit "Http Content Impl."
    begin
        HttpContentImpl := Create(Content, '');
    end;

    procedure Create(Content: Codeunit "Temp Blob"; ContentType: Text): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content, ContentType);
        exit(this);
    end;

    procedure Create(Content: InStream) HttpContent: Codeunit "Http Content Impl."
    begin
        HttpContent := Create(Content, '');
    end;

    procedure Create(Content: InStream; ContentType: Text): Codeunit "Http Content Impl."
    begin
        ClearAll();
        SetContent(Content, ContentType);
        exit(this);
    end;

    procedure Create(HttpContent: HttpContent): Codeunit "Http Content Impl."
    begin
        ClearAll();
        this.SetContent(HttpContent);
        exit(this);
    end;
    #endregion

    procedure SetContentTypeHeader(ContentType: Text)
    begin
        if ContentType = '' then
            Error(ContentTypeEmptyErr);
        SetHeader('Content-Type', ContentType);
    end;

    procedure AddContentEncoding(ContentEncoding: Text)
    var
        Headers: HttpHeaders;
    begin
        if not HttpContent.GetHeaders(Headers) then begin
            HttpContent.Clear();
            HttpContent.GetHeaders(Headers);
        end;
        Headers.Add('Content-Encoding', ContentEncoding);
    end;

    procedure SetHeader(Name: Text; Value: Text)
    var
        Headers: HttpHeaders;
    begin
        if not HttpContent.GetHeaders(Headers) then begin
            HttpContent.Clear();
            HttpContent.GetHeaders(Headers);
        end;

        if Headers.Contains(Name) or Headers.ContainsSecret(Name) then
            Headers.Remove(Name);

        Headers.Add(Name, Value);
    end;

    procedure SetHeader(Name: Text; Value: SecretText)
    var
        Headers: HttpHeaders;
    begin
        if not HttpContent.GetHeaders(Headers) then begin
            HttpContent.Clear();
            HttpContent.GetHeaders(Headers);
        end;

        if Headers.Contains(Name) or Headers.ContainsSecret(Name) then
            Headers.Remove(Name);

        Headers.Add(Name, Value);
    end;

    procedure GetHttpContent() ReturnValue: HttpContent
    begin
        ReturnValue := HttpContent;
    end;

    procedure AsText() ReturnValue: Text
    begin
        HttpContent.ReadAs(ReturnValue);
    end;

    procedure AsSecretText() ReturnValue: SecretText
    begin
        HttpContent.ReadAs(ReturnValue);
    end;

    procedure AsBlob() ReturnValue: Codeunit "Temp Blob"
    var
        InStr: InStream;
        OutStr: OutStream;
    begin
        HttpContent.ReadAs(InStr);
        ReturnValue.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure AsInStream(var InStr: InStream)
    begin
        HttpContent.ReadAs(InStr);
    end;

    procedure AsXmlDocument() ReturnValue: XmlDocument
    var
        XmlReadOptions: XmlReadOptions;
    begin
        XmlReadOptions.PreserveWhitespace(false);
        if not XmlDocument.ReadFrom(AsText(), XmlReadOptions, ReturnValue) then
            ThrowInvalidXmlException();
    end;

    procedure AsJson() ReturnValue: JsonToken
    var
        Json: Text;
    begin
        Json := AsText();
        if Json <> '' then
            if not ReturnValue.ReadFrom(AsText()) then
                ThrowInvalidJsonException();
    end;

    procedure SetContent(Content: Text; ContentType: Text)
    begin
        HttpContent.Clear();
        HttpContent.WriteFrom(Content);
        if ContentType = '' then
            ContentType := MimeTypeTextPlainTxt;
        SetContentTypeHeader(ContentType);
    end;

    procedure SetContent(Content: SecretText; ContentType: Text)
    begin
        HttpContent.Clear();
        HttpContent.WriteFrom(Content);
        if ContentType = '' then
            ContentType := MimeTypeTextPlainTxt;
        SetContentTypeHeader(ContentType);
    end;

    procedure SetContent(Content: InStream; ContentType: Text)
    begin
        HttpContent.Clear();
        HttpContent.WriteFrom(Content);
        if ContentType = '' then
            ContentType := MimeTypeApplicationOctetStreamTxt;
        SetContentTypeHeader(ContentType);
    end;

    procedure SetContent(TempBlob: Codeunit "Temp Blob"; ContentType: Text)
    var
        InStream: InStream;
    begin
        InStream := TempBlob.CreateInStream(TextEncoding::UTF8);
        if ContentType = '' then
            ContentType := MimeTypeApplicationOctetStreamTxt;
        SetContent(InStream, ContentType);
    end;

    procedure SetContent(Content: XmlDocument)
    var
        Xml: Text;
        XmlWriteOptions: XmlWriteOptions;
    begin
        XmlWriteOptions.PreserveWhitespace(false);
        Content.WriteTo(XmlWriteOptions, Xml);
        SetContent(Xml, MimeTypeTextXmlTxt);
    end;

    procedure SetContent(Content: JsonToken)
    var
        Json: Text;
    begin
        Content.WriteTo(Json);
        SetContent(Json, MimeTypeApplicationJsonTxt);
    end;

    procedure SetContent(var Value: HttpContent)
    begin
        HttpContent := Value;
    end;

    local procedure ThrowInvalidJsonException()
    var
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        InvalidJsonMessageTxt: Label 'The content is not a valid JSON.';
    begin
        Error(RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::InvalidJson, InvalidJsonMessageTxt));
    end;

    local procedure ThrowInvalidXmlException()
    var
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        InvalidXmlMessageTxt: Label 'The content is not a valid XML.';
    begin
        Error(RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::InvalidXml, InvalidXmlMessageTxt));
    end;
}