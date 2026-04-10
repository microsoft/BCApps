codeunit 139148 "UT REST"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [REST]
    end;

    var
        Assert: Codeunit Assert;
        NoContentErr: Label 'The stream is empty.';
        UnknownImageTypeErr: Label 'Unknown image type.';
        XmlDocLoadErr: Label 'A call to System.Xml.XmlDocument.Load failed';
        InvalidValueErr: Label 'Invalid returned value';
        XMLDOMMgt: Codeunit "XML DOM Management";
        InvalidTokenFormatErr: Label 'The token must be in JWS or JWE Compact Serialization Format.';
        ExampleJwtTokenTxt: Label 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJodHRwOi8vd3d3LmV4YW1wbGUuY29tIiwiaXNzIjoic2VsZiIsIm5iZiI6MTM1Mzk3NDczNiwiZXhwIjoxMzUzOTc0ODU2LCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoiUGVkcm8iLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOiJBdXRob3IifQ.a-Tu5ojQSyiGSzTb9E5QbEYxyhomywzh2wqKs4El7lc';
        UnableToParseJwtObjectErr: Label 'Unable to parse Jwt object.';
        HasJWTExpiredErr: Label 'HasJWTExpired function returns incorrect results for token expire date.';
        ExpectedImageSrcTok: Label 'data:image/%1;base64,%2', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ExpiredToken()
    var
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        AccessToken: Text;
    begin
        // [SCENARIO 227335] SOAPWebServiceRequestMgt.HasJWTExpired function returns TRUE in case of expired token

        // [GIVEN] Mock token with exprired date less than current
        AccessToken := MockTokenWithExpDate(CurrentDateTime - 1000);

        // [WHEN] Function SOAPWebServiceRequestMgt.HasJWTExpired is being run
        // [THEN] It returns TRUE
        Assert.IsTrue(SOAPWebServiceRequestMgt.HasJWTExpired(AccessToken), InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotExpiredToken()
    var
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        AccessToken: Text;
    begin
        // [SCENARIO 227335] SOAPWebServiceRequestMgt.HasJWTExpired function returns FALSE in case of not expired token

        // [GIVEN] Mock token with exprired date less than current
        AccessToken := MockTokenWithExpDate(CurrentDateTime + 1000);

        // [WHEN] Function SOAPWebServiceRequestMgt.HasJWTExpired is being run
        // [THEN] It returns TRUE
        Assert.IsFalse(SOAPWebServiceRequestMgt.HasJWTExpired(AccessToken), InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvalidTokenFormat()
    var
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        AccessToken: Text;
    begin
        // [SCENARIO 227335] SOAPWebServiceRequestMgt.HasJWTExpired function throws the error in case of invalid token format

        // [GIVEN] Mock token with invalid format
        AccessToken := Format(CreateGuid());

        // [WHEN] Function SOAPWebServiceRequestMgt.HasJWTExpired is being run
        asserterror SOAPWebServiceRequestMgt.HasJWTExpired(AccessToken);

        // [THEN] Error 'The token needs to be in JWS or JWE Compact Serialization Format.' displayed
        Assert.ExpectedError(InvalidTokenFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XmlText2JsonText()
    var
        JSONMgt: Codeunit "JSON Management";
        XmlText: Text;
        JsonText: Text;
    begin
        // [SCENARIO 227335] Function JSONMgt.XmTextlToJsonText converts XML text to Json text

        // [GIVEN] Xml as text
        XmlText := MockXMLText();

        // [WHEN] Function JSONMgt.XmTextlToJsonText is being run
        JsonText := JSONMgt.XMLTextToJSONText(XmlText);

        // [THEN] Resulted Json text has appropriate content
        VerifyJsonText(JsonText, MockJsonText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JsonText2XmlText()
    var
        JSONMgt: Codeunit "JSON Management";
        XmlText: Text;
        JsonText: Text;
    begin
        // [SCENARIO 227335] Function JSONMgt.XmTextlToJsonText converts Json text to XML text

        // [GIVEN] Xml as text
        JsonText := MockJsonText();

        // [WHEN] Function JSONMgt.JsonTextToXmlText is being run
        XmlText := JSONMgt.JSONTextToXMLText(JsonText, 'transform');

        // [THEN] Resulted XML text has appropriate content
        VerifyXMLText(XmlText, MockXMLText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJwtToken()
    var
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        ExampleJwtToken, WebTokenAsJson : Text;
    begin
        // [SCENARIO] You can retrieve token details

        // [GIVEN] A sample token
        // [WHEN] The token details are retrieved
        ExampleJwtToken := ExampleJwtTokenTxt;
        if SOAPWebServiceRequestMgt.GetTokenDetailsAsJson(ExampleJwtToken, WebTokenAsJson) then begin
            // [THEN] The correct values are retrieved
            Assert.AreEqual('http://www.example.com', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson, 'aud'), '');
            Assert.AreEqual('self', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson, 'iss'), '');
            Assert.AreEqual('1353974736', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson, 'nbf'), '');
            Assert.AreEqual('1353974856', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson, 'exp'), '');
            Assert.AreEqual('Pedro', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson,
                'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'), '');
            Assert.AreEqual('Author', SOAPWebServiceRequestMgt.GetTokenValue(WebTokenAsJson,
                'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'), '');
            Assert.IsTrue(SOAPWebServiceRequestMgt.HasJWTExpired(ExampleJwtToken), HasJWTExpiredErr);
        end else
            Error(UnableToParseJwtObjectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetHTMLImgSrc()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        ImageSrc: Text;
        ImageBase64: Text;
    begin
        // [SCENARIO] TempBlob.GetHTMLImgSrc function returns 'data:image/Jpeg;base64,[ImageBase64]' for jpeg file imported into Blob

        // [GIVEN] TempBlob with jpeg image
        CreateTempBLOBImageJpeg(TempBlob, ImageBase64);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetHTMLImgSrc is being used
        ImageSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] Returned value equal to 'data:image/Jpeg;base64,[ImageBase64]'
        Assert.AreEqual(StrSubstNo(ExpectedImageSrcTok, 'Jpeg', ImageBase64), ImageSrc, InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetHTMLImgSrcEmptyBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        ImageSrc: Text;
    begin
        // [SCENARIO] TempBlob.GetHTMLImgSrc function returns '' in case of empty Blob.

        // [GIVEN] Empty TempBlob
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetHTMLImgSrc is being used
        ImageSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] Returned value equal to ''
        Assert.AreEqual('', ImageSrc, InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetHTMLImgSrcNonImageBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        ImageSrc: Text;
    begin
        // [SCENARIO] TempBlob.GetHTMLImgSrc function returns '' in case of Blob containing non-image file

        // [GIVEN] TempBlob with XML file
        CreateTempBLOBXML(TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetHTMLImgSrc is being used
        ImageSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] Returned value equal to ''
        Assert.AreEqual('', ImageSrc, InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetImageTypeJpeg()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        ImageType: Text;
    begin
        // [SCENARIO 227335] TempBlob.GetImageType function returns 'Jpeg' for jpeg file imported into Blob
        // The rest of image types scenarios covered in the codeunit 138929

        // [GIVEN] TempBlob with jpeg image
        CreateTempBLOBImageJpeg(TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetImageType is being used
        ImageType := ImageHelpers.GetImageType(InStream);

        // [THEN] Returned value equal to 'Jpeg'
        Assert.AreEqual('Jpeg', ImageType, InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetImageTypeEmptyBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
    begin
        // [SCENARIO 227335] TempBlob.GetImageType function throws the error in case of empty Blob

        // [GIVEN] Empty TempBlob
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetImageType is being used
        asserterror ImageHelpers.GetImageType(InStream);

        // [THEN] Error 'The Blob field is empty.' displayed
        Assert.ExpectedError(NoContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetImageTypeNonImageBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
    begin
        // [SCENARIO 227335] TempBlob.GetImageType function throws the error in case of Blob containing non-image file

        // [GIVEN] TempBlob with XML file
        CreateTempBLOBXML(TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetImageType is being used
        asserterror ImageHelpers.GetImageType(InStream);

        // [THEN] Error 'Unknown image type.' displayed
        Assert.ExpectedError(UnknownImageTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetXMLAsTextSunshine()
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedXmlText: Text;
        XmlText: Text;
    begin
        // [SCENARIO 227335] TempBlob.GetXMLAsText function returns loaded XML as text

        // [GIVEN] TempBlob with XML file
        ExpectedXmlText := CreateTempBLOBXML(TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetXMLAsText is being used
        XMLDOMMgt.TryGetXMLAsText(InStream, XmlText);

        // [THEN] Return value the same with initial XML
        Assert.AreEqual(ExpectedXmlText, XmlText, InvalidValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetXMLAsTextEmptyBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlText: Text;
    begin
        // [SCENARIO 227335] TempBlob.GetXMLAsText function throws the error in case of empty Blob

        // [GIVEN] Empty TempBlob
        TempBlob.CreateInStream(InStream);

        // [WHEN] Function GetXMLAsText is being used
        asserterror XMLDOMMgt.TryGetXMLAsText(InStream, XmlText);

        // [THEN] Error 'The Blob field is empty.' displayed
        Assert.ExpectedError(NoContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetXMLAsTextNonXMLBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XMLText: Text;
    begin
        // [SCENARIO 227335] TempBlob.GetXMLAsText function throws the error in case of Blob containing non-XML file

        // [GIVEN] TempBlob with image file
        CreateTempBLOBImageJpeg(TempBlob);
        TempBlob.CreateInStream(InStream, TEXTENCODING::Windows);

        // [WHEN] Function GetXMLAsText is being used
        asserterror XMLDOMMgt.TryGetXMLAsText(InStream, XMLText);

        // [THEN] Error 'XML cannot be loaded.' displayed
        Assert.ExpectedError(XmlDocLoadErr);
    end;

    local procedure CreateTempBLOBImageJpeg(var TempBlob: Codeunit "Temp Blob"; var Base64String: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Bitmap := Bitmap.Bitmap(1, 1);
        Bitmap.Save(OutStream, ImageFormat.Jpeg);
        Bitmap.Dispose();
        TempBlob.CreateInStream(InStream);
        Base64String := Base64Convert.ToBase64(InStream);
    end;

    local procedure CreateTempBLOBImageJpeg(var TempBlob: Codeunit "Temp Blob")
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Bitmap := Bitmap.Bitmap(1, 1);
        Bitmap.Save(OutStream, ImageFormat.Jpeg);
        Bitmap.Dispose();
    end;

    local procedure CreateTempBLOBXML(var TempBlob: Codeunit "Temp Blob"): Text
    var
        OutStr: OutStream;
        Xml: Text;
    begin
        Xml := MockXMLText();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Xml);
        exit(Xml);
    end;

    local procedure MockTokenWithExpDate(ExpirationDateTime: DateTime): Text
    var
        Encoding: DotNet Encoding;
        Convert: DotNet Convert;
        Payload: Text;
    begin
        Payload :=
          StrSubstNo(
            '{"iss": "scotch.io","exp": %1,"name": "Chris Sevilleja","admin": true}',
            Format(GetUnixTime(ExpirationDateTime), 0, 9));
        exit(
          StrSubstNo(
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%1.03f329983b86f7d9a9f5fef85305880101d5e302afafa20154d094b229f75773',
            Convert.ToBase64String(
              Encoding.UTF8.GetBytes(
                Payload))));
    end;

    local procedure MockXMLText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<transform>' +
          '<record>' +
          '<username>MP123456</username>' +
          '<fullname>Ester Henderson</fullname>' +
          '</record>' +
          '<record>' +
          '<username>PK123456</username>' +
          '<fullname>Benjamin Chiu</fullname>' +
          '</record>' +
          '</transform>');
    end;

    local procedure MockJsonText(): Text
    begin
        exit(
          '{' +
          '"record": [' +
          '{' +
          '"username": "MP123456",' +
          '"fullname": "Ester Henderson"' +
          '},' +
          '{' +
          '"username": "PK123456",' +
          '"fullname": "Benjamin Chiu"' +
          '}' +
          ']' +
          '}');
    end;

    local procedure GetUnixTime(DateTimeValue: DateTime): Decimal
    var
        TypeHelper: Codeunit "Type Helper";
        TimeZoneOffset: Duration;
    begin
        if not TypeHelper.GetUserTimezoneOffset(TimeZoneOffset) then
            TimeZoneOffset := 0;
        exit(
          Round(
            (DateTimeValue - CreateDateTime(DMY2Date(1, 1, 1970), 0T) - TimeZoneOffset) / 1000,
            1));
    end;

    local procedure VerifyJsonText(JsonText: Text; ExpectedJsonText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        ExpectedJsonText := DelChr(ExpectedJsonText, '=', ' ');
        JsonText := DelChr(JsonText, '=', TypeHelper.CRLFSeparator() + ' ');
        Assert.AreEqual(ExpectedJsonText, JsonText, InvalidValueErr);
    end;

    local procedure VerifyXMLText(XMLText: Text; ExpectedXMLText: Text)
    var
        XMLRootNode: DotNet XmlNode;
    begin
        XMLDOMMgt.LoadXMLNodeFromText(ExpectedXMLText, XMLRootNode);
        ExpectedXMLText := XMLRootNode.OuterXml();
        Assert.AreEqual(ExpectedXMLText, XMLText, InvalidValueErr);
    end;
}

