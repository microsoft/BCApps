codeunit 132581 WebServiceReqMgtTests
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Data Conversion] [Web Service]
    end;

    var
        Assert: Codeunit Assert;
        EmptyRequestBodyErr: Label 'The request body is not set.';
        ExpectedErrorFailedErr: Label 'Assert.ExpectedError failed. Expected: %1. Actual: %2.';
        InvalidCertificateErr: Label 'Received an invalid status line: ''Secure Protocol: Tls''.';
        InvalidCredentialErr: Label '404, Wrong username and/or password (sa/main)';
        InternalErr: Label 'The remote service has returned the following error message:';
        InvalidUriErr: Label 'The URI is not valid.';
        MockServiceURLTxt: Label 'https://localhost:8080/', Locked = true;
        NonExistingServiceURLTxt: Label 'nonexistingserviceurl';
        NotFoundErr: Label 'No such host is known.';
        ServiceURLTxt: Label '\\Service URL: https://localhost:8080/.', Locked = true;
        SupportURLErr: Label '\\For more information, go to %1';
        LibraryUtility: Codeunit "Library - Utility";
        UnexpectedDataReceivedErr: Label 'The expected data was not received from the web service';
        UnsecureUriErr: Label 'The URI is not secure.';
        UriNotSetErr: Label 'The web service URI is not set.';
        WebServiceMgtRunErr: Label 'SOAPWebServiceRequestMgt.RUN was supposed to return false but returned true.';
        WrongBodyErr: Label 'Request returned an unexpected response body.';
        WrongContentErr: Label 'Unexpected value in the selected element.';

    [Test]
    [Scope('OnPrem')]
    procedure TestSoapEnvelope()
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ResponseInStream: InStream;
        BlobInStream: InStream;
        BlobOutStream: OutStream;
        XmlDoc: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
        XMLNsMgr: DotNet XmlNamespaceManager;
        Username: Text;
        Password: Text;
        Data: Text;
    begin
        // [SCENARIO 1] Test that the soap envelope is built and unwrapped correctly.
        // [GIVEN] Service URL of the MockService.
        // [GIVEN] Username and password.
        // [GIVEN] Mock Service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The MockService returns the soap request that it received.
        // [THEN] The soap envelope contains authentication elements.
        // [THEN] The response soap envelope is unwrapped correctly.

        // Pre-Setup
        Username := 'User1';
        Password := 'Password1';
        Data := '<data>ReturnRequest</data>';

        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(Data);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, MockServiceURLTxt, Username, Password);

        if not SOAPWebServiceRequestMgt.SendRequestToWebService() then
            SOAPWebServiceRequestMgt.ProcessFaultResponse('');

        SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);

        XMLDOMManagement.LoadXMLDocumentFromInStream(ResponseInStream, XmlDoc);

        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XmlDoc.NameTable);
        XMLNsMgr.AddNamespace('ns0', 'http://schemas.xmlsoap.org/soap/envelope/');
        XMLNsMgr.AddNamespace('ns1', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        XMLNsMgr.AddNamespace('ns2', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');

        XmlNodeList := XmlDoc.SelectNodes('//ns0:Envelope/ns0:Body', XMLNsMgr);
        Assert.AreEqual(1, XmlNodeList.Count, 'Unexpected number of nodes');
        Assert.AreEqual(Data, XmlNodeList.Item(0).InnerXml, WrongBodyErr);

        XmlNodeList := XmlDoc.SelectNodes('//ns0:Envelope/ns0:Header/ns1:Security/ns1:UsernameToken/ns1:Username', XMLNsMgr);
        Assert.AreEqual(1, XmlNodeList.Count, 'Unexpected number of nodes');
        Assert.AreEqual(Username, XmlNodeList.Item(0).InnerText, WrongContentErr);

        XmlNodeList := XmlDoc.SelectNodes('//ns0:Envelope/ns0:Header/ns1:Security/ns1:UsernameToken/ns1:Password', XMLNsMgr);
        Assert.AreEqual(1, XmlNodeList.Count, 'Unexpected number of nodes');
        Assert.AreEqual(Password, XmlNodeList.Item(0).InnerText, WrongContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvaidCredentialsErrorCondition()
    begin
        // [SCENARIO 2] Test that passing an invalid credentials in the soap envelope returns a response that is handled correctly.
        // [GIVEN] Service URL of the MockService.
        // [GIVEN] Username and password.
        // [GIVEN] Mock Service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The MockService returns a response that suggesting that wrong credentials are used.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditionsAlt(MockServiceURLTxt, '<data>InvalidCredentialError</data>',
          InternalErr + InvalidCredentialErr + ServiceURLTxt, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidCertificateErrorCondition()
    begin
        // [SCENARIO 3] Test that the error condition with invalid certificate is handled correctly.
        // [GIVEN] Service URL of the MockService.
        // [GIVEN] Username and password.
        // [GIVEN] Mock Service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The MockService returns a response that suggestes that the destination site's certificate is invalid.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions(MockServiceURLTxt, '<data>InvalidCertificate</data>',
          InvalidCertificateErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExpiredCertificateErrorCondition()
    begin
        // [SCENARIO 4] Test that the error condition with expired certificate is handled correctly.
        // [GIVEN] Service URL of the MockService.
        // [GIVEN] Username and password.
        // [GIVEN] Mock Service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The MockService returns a response that suggestes that the destination site's certificate has expired.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions(MockServiceURLTxt, '<data>ExpiredCertificate</data>',
          InvalidCertificateErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidUrlErrorCondition()
    begin
        // [SCENARIO 5] Test that the error condition with invalid url is handled correctly.
        // [GIVEN] An invalid service URL.
        // [GIVEN] Username and password.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions(StrSubstNo('https://%1:8080/', NonExistingServiceURLTxt), '<data>Can Be Anything</data>',
          NotFoundErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonSoapResponseErrorCondition()
    begin
        // [SCENARIO 6] Test that the error condition with non soap return data is handled correctly.
        // [GIVEN] Service URL of the MockService.
        // [GIVEN] Username and password.
        // [GIVEN] Mock Service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The MockService returns a response with an Html body and not soap.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions(MockServiceURLTxt, '<data>HtmlResponse</data>', UnexpectedDataReceivedErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWhenRequestBodyIsEmptyErrorCondition()
    begin
        // [SCENARIO 7] Test that the error condition with empty request body is handled correctly.
        // [GIVEN] Service URL of the MockService.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username, password and an empty body.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions(MockServiceURLTxt, '', EmptyRequestBodyErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWhenUriIsEmptyErrorCondition()
    begin
        // [SCENARIO 10] Test that the error condition with empty uri is handled correctly.
        // [GIVEN] Empty service URL.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username, password and an empty body.
        // [THEN] The webservice call fails with an appropriate error mesage.
        TestErrorConditions('', '<data>ReturnRequest</data>', UriNotSetErr, 'User1', 'Password1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConnectionRequestToNonsecureUrl()
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
        Data: Text;
        Username: Text;
        Password: Text;
        UnsecureUrl: Text;
    begin
        // [SCENARIO 11] Test that initiating web connection to a unsecure URL throws an exception.
        // [GIVEN] An non https URL as the web address.
        // [WHEN] Try to send a POST request to the Web service, providing the non https URL, username and password.
        // [THEN] The webservice call fails with an exception stating that the URL is not secure.
        // Setup
        Username := 'User1';
        Password := 'Password1';
        Data := '<data>HtmlResponse</data>';
        UnsecureUrl := 'http://' + LibraryUtility.GenerateGUID();

        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(Data);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, UnsecureUrl, Username, Password);

        // Excercise
        asserterror SOAPWebServiceRequestMgt.SendRequestToWebService();

        // Validation
        Assert.ExpectedError(UnsecureUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonSecureUrlUsageIsPossbile()
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
        Data: Text;
        UnsecureUrl: Text;
        Username: Text;
        Password: Text;
    begin
        // [SCENARIO 12] Test that we can disable the check for secure connections for special cases.
        // [GIVEN] An non https URL as the web address.
        // [WHEN] Disable the secure Url check we can have a connection to an unsecure address.
        // [THEN] The URL check is succesful. There are no errors thrown.
        // Setup
        Username := 'User1';
        Password := 'Password1';
        Data := '<data>HtmlResponse</data>';
        UnsecureUrl := StrSubstNo('http://%1', NonExistingServiceURLTxt);

        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(Data);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, UnsecureUrl, Username, Password);
        SOAPWebServiceRequestMgt.DisableHttpsCheck();

        // Excercise
        asserterror SOAPWebServiceRequestMgt.SendRequestToWebService();

        // Validation - No errors should occur, but it should have failed the connection attempt
        Assert.ExpectedError(NotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConnectionRequestToInvalidUrl()
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
        Data: Text;
        Username: Text;
        Password: Text;
        InvalidUrl: Text;
    begin
        // [SCENARIO 13] Test that initiating web connection to a URL that is not valid throws an exception.
        // [GIVEN] An invalid URL as the web address.
        // [WHEN] Try to send a POST request to the Web service, providing the invalid URL, username and password.
        // [THEN] The webservice call fails with an exception stating that the URL is not valid.
        // Setup
        Username := 'User1';
        Password := 'Password1';
        Data := '<data>HtmlResponse</data>';
        InvalidUrl := LibraryUtility.GenerateGUID();

        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(Data);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, InvalidUrl, Username, Password);

        // Excercise
        asserterror SOAPWebServiceRequestMgt.SendRequestToWebService();

        // Validation
        Assert.ExpectedError(InvalidUriErr);
    end;

    local procedure TestErrorConditions(Url: Text; DataToBeSent: Text; Expected: Text; Username: Text; Password: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(DataToBeSent);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, Url, Username, Password);

        if not SOAPWebServiceRequestMgt.SendRequestToWebService() then begin
            asserterror SOAPWebServiceRequestMgt.ProcessFaultResponse(StrSubstNo(SupportURLErr, 'support UTL'));
            ExpectedError(Expected);
        end else
            Error(WebServiceMgtRunErr);
    end;

    local procedure TestErrorConditionsAlt(Url: Text; DataToBeSent: Text; Expected: Text; Username: Text; Password: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
        TempBlob.CreateInStream(BlobInStream);
        BlobOutStream.WriteText(DataToBeSent);

        SOAPWebServiceRequestMgt.SetGlobals(BlobInStream, Url, Username, Password);

        if not SOAPWebServiceRequestMgt.SendRequestToWebService() then begin
            asserterror ProcessFaultResponseAMC('<syslogtype>error</syslogtype>');
            ExpectedError(Expected);
        end else
            Error(WebServiceMgtRunErr);
    end;

    local procedure ProcessFaultResponseAMC(ExpectedTag: Text)
    var
        ResponseText: Text;
        WebRequestHelper: Codeunit "Web Request Helper";
        WebException: DotNet WebException;
        ResponseInputStream: InStream;
        ErrorText: Text;
        ServiceURL: Text;
        ErrorMessageStartPos: Integer;
        ErrorMessageEndPos: Integer;
    begin
        ErrorText := WebRequestHelper.GetWebResponseError(WebException, ServiceURL);

        if ErrorText <> '' then
            Error(ErrorText);

        ResponseInputStream := WebException.Response.GetResponseStream();
        ResponseInputStream.Read(ResponseText);

        if ResponseText.Contains(ExpectedTag) then begin
            ErrorMessageStartPos := StrPos(ResponseText, '<text>');
            ErrorMessageEndPos := StrPos(ResponseText, '</text>');
            ErrorText := CopyStr(ResponseText, ErrorMessageStartPos + 6, ErrorMessageEndPos - ErrorMessageStartPos - 6);
            ErrorText := InternalErr + ErrorText + ServiceURL;
        end;
        Error(ErrorText);
    end;

    local procedure ExpectedError(Expected: Text)
    begin
        if StrPos(GetLastErrorText, Expected) = 0 then
            Error(ExpectedErrorFailedErr, Expected, GetLastErrorText);
    end;
}
