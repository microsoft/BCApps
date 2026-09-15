codeunit 132580 "Web Service Req./Resp."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Data Conversion] [Web Service]
    end;

    var
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BankListRequestBodyTxt: Label '<bankSoapList xmlns="%1"><productdimgroup xmlns=""/></bankSoapList>', Locked = true;
        MockServiceURLTxt: Label 'https://localhost:8080/', Locked = true;
        EmptyBodyErr: Label 'Request returned an empty response body.';
        WrongBodyErr: Label 'Request returned an unexpected response body.';
        DemoFileLine01Txt: Label '<paymentExportBank xmlns="%1"><amcpaymentreq xmlns=''''><banktransjournal>', Locked = true;
        DemoFileLine02Txt: Label '<journalname>200106</journalname><journalnumber>journal-02</journalnumber><transmissionref1>01</transmissionref1><uniqueid>DE-01</uniqueid>', Locked = true;
        DemoFileLine03Txt: Label '<banktransus><countryoforigin>DE</countryoforigin><uniqueid>DE01US</uniqueid><ownaddress><address1>Grundtvigsvej 29</address1>', Locked = true;
        DemoFileLine04Txt: Label '<address2></address2><city></city><countryiso>DK</countryiso><name>AMC</name></ownaddress>', Locked = true;
        DemoFileLine05Txt: Label '<banktransthem><uniqueid>DE01TH</uniqueid><receiversaddress><countryiso>DE</countryiso><name>Tysk kreditor 1</name></receiversaddress>', Locked = true;
        DemoFileLine06Txt: Label '<paymenttype>DomAcc2Acc</paymenttype><costs>Shared</costs>', Locked = true;
        DemoFileLine07Txt: Label '<banktransspec><discountused>0.0</discountused><invoiceref>6541695</invoiceref><uniqueid>DE01SP</uniqueid><amountdetails><payamount>0.08</payamount>', Locked = true;
        DemoFileLine08Txt: Label '<paycurrency>EUR</paycurrency><paydate>%1</paydate></amountdetails></banktransspec>', Locked = true;
        DemoFileLine09Txt: Label '<banktransspec><discountused>0.0</discountused><invoiceref>6541654</invoiceref><uniqueid>DE02SP</uniqueid><amountdetails><payamount>0.02</payamount>', Locked = true;
        DemoFileLine10Txt: Label '<paycurrency>EUR</paycurrency><paydate>%1</paydate></amountdetails></banktransspec>', Locked = true;
        DemoFileLine11Txt: Label '<amountdetails><payamount>0.10</payamount><paycurrency>EUR</paycurrency><paydate>2014-05-29</paydate></amountdetails><receiversbankaccount>', Locked = true;
        DemoFileLine12Txt: Label '<bankaccount>0011350044</bankaccount><intregno>51420600</intregno><intregnotype>GermanBankleitzahl</intregnotype></receiversbankaccount></banktransthem>', Locked = true;
        DemoFileLine13Txt: Label '<bankaccountident><bankaccount>0011350034</bankaccount><swiftcode>HANDDEFF</swiftcode></bankaccountident>', Locked = true;
        DemoFileLine14Txt: Label '</banktransus></banktransjournal></amcpaymentreq><bank xmlns=''''>Handels EDI DE</bank><language xmlns=''''>ENU</language></paymentExportBank>', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankListRequestResponse()
    var
        //           BankDataConvServiceSetup: Record "Bank Data Conv. Service Setup";
        BodyTempBlob: Codeunit "Temp Blob";
        //         BankDataConvServMgt: Codeunit "Bank Data Conv. Serv. Mgt.";
        ResponseInStream: InStream;
        BodyInStream: InStream;
        BodyOutStream: OutStream;
        ResponseText: Text;
        DummyPassword: Text;
    begin
        // [SCENARIO 1] Get the bank names.
        // [GIVEN] Service URL on Bank Data Conv. Setup table.
        // [GIVEN] Username and password on Bank Data Conv. Setup table.
        // [GIVEN] Web service is running.
        // [WHEN] Send a POST request to the Web service, providing the Service URL, username and password.
        // [THEN] The bank names are returned as a stream.
        // [THEN] The stream is not empty.

        // Setup
        BodyTempBlob.CreateOutStream(BodyOutStream);
        BodyOutStream.WriteText(StrSubstNo(BankListRequestBodyTxt, 'http://Nav02.soap.xml.link.amc.dk/'));

        // Exercise
        BodyTempBlob.CreateInStream(BodyInStream);
        //           BankDataConvServiceSetup.Get();
        DummyPassword := 'DemoPassword';
        SOAPWebServiceRequestMgt.SetGlobals(BodyInStream,
          MockServiceURLTxt, 'DemoUser', DummyPassword);

        if not SOAPWebServiceRequestMgt.SendRequestToWebService() then
            SOAPWebServiceRequestMgt.ProcessFaultResponse('');

        SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);
        ResponseInStream.Read(ResponseText);

        // Verify
        if StrPos(ResponseText, '<countryoforigin>NL</countryoforigin>') = 0 then
            Error(WrongBodyErr);

        if StrPos(ResponseText, '<bankname>ABN AMRO</bankname>') = 0 then
            Error(WrongBodyErr);

        if StrLen(ResponseText) <= 0 then
            Error(EmptyBodyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentRequestResponse()
    var
        BodyTempBlob: Codeunit "Temp Blob";
        ResponseTempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        BodyInStream: InStream;
        ResponseInStream: InStream;
        ResponseText: Text;
        DummyPassword: Text;
    begin
        // [SCENARIO 2] Get a payment export data response.
        // [GIVEN] Sample data for a sample AMC bank.
        // [GIVEN] AMC test Web service URL and access credentials.
        // [WHEN] Run the Web service management functions to handle the request / response.
        // [THEN] Payment file in the sample AMC format is saved to a CDATA section in the response.
        // [THEN] The SOAP response is saved within a BLOB.

        // Pre-Setup
        PrepareAMCDemoBody(BodyTempBlob);

        // Setup
        BodyTempBlob.CreateInStream(BodyInStream);
        DummyPassword := 'DemoPassword';
        SOAPWebServiceRequestMgt.SetGlobals(BodyInStream,
            MockServiceURLTxt, 'DemoUser', DummyPassword);
        //                 BankDataConvServiceSetup."Service URL", BankDataConvServiceSetup."User Name", BankDataConvServiceSetup.GetPassword());

        // Exercise
        if not SOAPWebServiceRequestMgt.SendRequestToWebService() then
            SOAPWebServiceRequestMgt.ProcessFaultResponse('');

        // Pre-Verify
        ResponseTempBlob.CreateInStream(ResponseInStream);
        SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);
        ResponseInStream.Read(ResponseText);

        // Verify
        if StrPos(ResponseText, '<journalnumber>journal-02</journalnumber>') = 0 then
            Error(WrongBodyErr);

        if StrLen(ResponseText) <= 0 then
            Error(EmptyBodyErr);
    end;

    procedure PrepareAMCDemoBody(var BodyTempBlob: Codeunit "Temp Blob")
    var
        BodyOutputStream: OutStream;
    begin
        BodyTempBlob.CreateOutStream(BodyOutputStream, TEXTENCODING::UTF8);
        BodyOutputStream.WriteText(StrSubstNo(DemoFileLine01Txt, 'AMCBankServMgt.GetNamespace()'));
        BodyOutputStream.WriteText(DemoFileLine02Txt);
        BodyOutputStream.WriteText(DemoFileLine03Txt);
        BodyOutputStream.WriteText(DemoFileLine04Txt);
        BodyOutputStream.WriteText(DemoFileLine05Txt);
        BodyOutputStream.WriteText(DemoFileLine06Txt);
        BodyOutputStream.WriteText(DemoFileLine07Txt);
        BodyOutputStream.WriteText(StrSubstNo(DemoFileLine08Txt, Format(Today(), 0, 9)));
        BodyOutputStream.WriteText(DemoFileLine09Txt);
        BodyOutputStream.WriteText(StrSubstNo(DemoFileLine10Txt, Format(Today(), 0, 9)));
        BodyOutputStream.WriteText(DemoFileLine11Txt);
        BodyOutputStream.WriteText(DemoFileLine12Txt);
        BodyOutputStream.WriteText(DemoFileLine13Txt);
        BodyOutputStream.WriteText(DemoFileLine14Txt);
    end;

}

