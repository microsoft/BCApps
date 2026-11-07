// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using Microsoft.Utilities;
using System.Integration;
using System.Security.Encryption;
using System.Utilities;
using System.Xml;

codeunit 31116 "EET Service Management CZL"
{
    Access = Internal;
    Permissions = tabledata "EET Service Setup CZL" = r,
                  tabledata "EET Entry Status Log CZL" = rm;

    var
        TempErrorMessage: Record "Error Message" temporary;
        GlobalHttpRequestMessage: HttpRequestMessage;
        GlobalHttpResponseMessage: HttpResponseMessage;
        POKControlCode: Text;
        ResponseContentError: Text;
        ResponseContentErrorCode: Text;
        VerificationMode: Boolean;
        CommunicationFailed: Boolean;
        EETNamespaceTxt: Label 'http://fs.gov.cz/eet/schema/v4', Locked = true;
        SoapActionTxt: Label 'http://fs.gov.cz/eet/OdeslaniTrzby', Locked = true;
        SoapNamespaceTxt: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        ExpectedCertOrganizationTxt: Label 'Generální finanční ředitelství', Locked = true;
        OrganizationAttributeTypeTxt: Label 'O', Locked = true;
        OrganizationOidTxt: Label '2.5.4.10', Locked = true;
        OrganizationOidPrefixedTxt: Label 'OID.2.5.4.10', Locked = true;
        SecurityUtilityNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd', Locked = true;
        SecurityExtensionNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;
        SecurityEncodingTypeBase64BinaryTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary', Locked = true;
        SecurityValueTypeX509V3Txt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3', Locked = true;
        BodyPathTxt: Label '/soap:Envelope/soap:Body', Locked = true;
        BinarySecurityTokenPathTxt: Label '//wsse:BinarySecurityToken', Locked = true;
        SecurityPathTxt: Label '//wsse:Security', Locked = true;
        ErrorPathTxt: Label '//eet:Chyba', Locked = true;
        WarningPathTxt: Label '//eet:Varovani', Locked = true;
        ConfirmationPathTxt: Label '//eet:Potvrzeni', Locked = true;
        HeaderPathTxt: Label '//eet:Hlavicka', Locked = true;
        EETNamespacePrefixTxt: Label 'eet', Locked = true;
        MessageUUIDNotMatchErr: Label 'Message UUID received in response doesn''t match to Message UUID in EET Entry.';

    [TryFunction]
    procedure Send(EETEntryCZL: Record "EET Entry CZL")
    var
        IsolatedCertificate: Record "Isolated Certificate";
        RequestXmlDocument: XmlDocument;
        SoapXmlDocument: XmlDocument;
        ResponseContentXmlDocument: XmlDocument;
        ResponseXmlDocument: XmlDocument;
    begin
        Initialize();

        FindValidCertificate(EETEntryCZL.GetTaxpayerCertificateCode(), IsolatedCertificate);
        if not CheckEETEntry(EETEntryCZL, IsolatedCertificate) then
            Error('');

        CreateXmlDocument(EETEntryCZL, RequestXmlDocument);
        CreateSoapRequest(RequestXmlDocument, IsolatedCertificate, SoapXmlDocument);
        if not CheckSoapRequestSize(SoapXmlDocument) then
            Error('');
        SendSoapRequest(SoapXmlDocument, ResponseXmlDocument, ResponseContentXmlDocument);
        if HasResponseContentError(ResponseContentXmlDocument) then
            ProcessResponseContentError(ResponseContentXmlDocument);
        if HasResponseContentWarnings(ResponseContentXmlDocument) then
            ProcessResponseContentWarnings(ResponseContentXmlDocument);

        CheckResponseSecurity(ResponseXmlDocument);
        CheckResponseContentHeader(ResponseContentXmlDocument, EETEntryCZL);
        ProcessResponseContent(ResponseContentXmlDocument);
        if HasErrors() then
            Error('');
    end;

    local procedure CheckEETEntry(EETEntryCZL: Record "EET Entry CZL"; IsolatedCertificate: Record "Isolated Certificate"): Boolean
    var
        CertificateManagement: Codeunit "Certificate Management";
        CertificateSimpleName: Text;
        CertificateIssueErrorTxt: Label 'The certificate was issued to %1 but the Taxpayer ID of the EET entry is %2.', Comment = '%1=Taxpayer ID the certificate was issued to, %2=Taxpayer ID of EET Entry';
        EmptyTaxpayerIdTxt: Label 'Taxpayer ID must not be empty.';
        EmptyBusinessPremisesIdTxt: Label 'Registrating Unit Id must not be empty.';
        EmptyCashRegisterNoTxt: Label 'Cash Register No. must not be empty.';
        EmptyReceiptSerialNoTxt: Label 'Receipt Serial No. must not be empty.';
        ReceiptSerialNoTooLongErr: Label 'Receipt Serial No. must not be longer than %1 characters. The EET service does not accept longer values.', Comment = '%1 = maximum number of characters';
    begin
        CertificateSimpleName := CertificateManagement.GetCertSimpleName(IsolatedCertificate);
        if EETEntryCZL."Taxpayer ID" <> CertificateSimpleName then
            LogMessage(TempErrorMessage."Message Type"::Error, '',
              StrSubstNo(CertificateIssueErrorTxt, CertificateSimpleName, EETEntryCZL."Taxpayer ID"));
        if EETEntryCZL."Taxpayer ID" = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyTaxpayerIdTxt);
        if EETEntryCZL.GetBusinessPremisesUnitId() = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyBusinessPremisesIdTxt);
        if EETEntryCZL."Cash Register Code" = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyCashRegisterNoTxt);
        if EETEntryCZL."Receipt Serial No." = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyReceiptSerialNoTxt);
        if StrLen(EETEntryCZL."Receipt Serial No.") > GetMaxReceiptSerialNoLength() then
            LogMessage(TempErrorMessage."Message Type"::Error, '', StrSubstNo(ReceiptSerialNoTooLongErr, GetMaxReceiptSerialNoLength()));
        exit(not HasErrors());
    end;

    local procedure CheckSoapRequestSize(SoapXmlDocument: XmlDocument): Boolean
    var
        SoapTempBlob: Codeunit "Temp Blob";
        SoapOutStream: OutStream;
        MessageTooLargeErr: Label 'The size of the data message (%1 bytes) exceeds the limit of %2 bytes accepted by the EET service.', Comment = '%1 = size of the data message in bytes, %2 = maximum size in bytes';
    begin
        SoapTempBlob.CreateOutStream(SoapOutStream, TextEncoding::UTF8);
        SoapXmlDocument.WriteTo(SoapOutStream);
        if SoapTempBlob.Length() > GetMaxSoapMessageSize() then
            LogMessage(TempErrorMessage."Message Type"::Error, '', StrSubstNo(MessageTooLargeErr, SoapTempBlob.Length(), GetMaxSoapMessageSize()));
        exit(not HasErrors());
    end;

    local procedure FindValidCertificate(CertificateCode: Code[20]; var IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateCodeCZL: Record "Certificate Code CZL";
        CertificateNotExistErr: Label 'There is not valid certificate %1.', Comment = '%1 = certificate code';
    begin
        CertificateCodeCZL.Get(CertificateCode);
        if not CertificateCodeCZL.FindValidCertificate(IsolatedCertificate) then
            Error(CertificateNotExistErr, CertificateCode);
    end;

    local procedure CreateXmlDocument(EETEntryCZL: Record "EET Entry CZL"; var RequestXmlDocument: XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        SalesXmlNode: XmlNode;
        HeaderXmlNode: XmlNode;
        DataXmlNode: XmlNode;
    begin
        RequestXmlDocument := XmlDocument.Create();
        XMLDOMManagement.AddRootElementWithPrefix(RequestXmlDocument, 'Trzba', EETNamespacePrefixTxt, EETNamespaceTxt, SalesXmlNode);
        XMLDOMManagement.AddElementWithPrefix(SalesXmlNode, 'Hlavicka', '', EETNamespacePrefixTxt, EETNamespaceTxt, HeaderXmlNode);
        XMLDOMManagement.AddElementWithPrefix(SalesXmlNode, 'Data', '', EETNamespacePrefixTxt, EETNamespaceTxt, DataXmlNode);

        AddAttribute(HeaderXmlNode, 'uuid_zpravy', EETEntryCZL."Message UUID");
        AddAttribute(HeaderXmlNode, 'dat_odesl', FormatDateTime(CurrentDateTime()));
        AddAttribute(HeaderXmlNode, 'prvni_zaslani', FormatBoolean(EETEntryCZL.IsFirstSending()));
        if VerificationMode then
            AddAttribute(HeaderXmlNode, 'overeni', FormatBoolean(VerificationMode));

        AddAttribute(DataXmlNode, 'eic_popl', EETEntryCZL."Taxpayer ID");
        AddAttribute(DataXmlNode, 'eic_poverujiciho', EETEntryCZL."Authorizing Taxpayer ID");
        if EETEntryCZL."Multiple Taxpayer Auth." then
            AddAttribute(DataXmlNode, 'povereni_vice_popl', FormatBoolean(EETEntryCZL."Multiple Taxpayer Auth."));
        AddAttribute(DataXmlNode, 'id_jednotky', EETEntryCZL.GetBusinessPremisesUnitId());
        AddAttribute(DataXmlNode, 'id_pokl', EETEntryCZL."Cash Register Code");
        AddAttribute(DataXmlNode, 'porad_cis', EETEntryCZL."Receipt Serial No.");
        AddAttribute(DataXmlNode, 'dat_trzby', FormatDateTime(EETEntryCZL."Created At"));
        AddMandatoryAttribute(DataXmlNode, 'celk_trzba', FormatDecimal(EETEntryCZL."Total Sales Amount"));
        AddAttribute(DataXmlNode, 'urceno_cerp_zuct', FormatDecimal(EETEntryCZL."Amt. For Subseq. Draw/Settle"));
        AddAttribute(DataXmlNode, 'cerp_zuct', FormatDecimal(EETEntryCZL."Amt. Subseq. Drawn/Settled"));
    end;

    local procedure AddMandatoryAttribute(var ParentXmlNode: XmlNode; Name: Text; NodeValue: Text): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        exit(XMLDOMManagement.AddAttribute(ParentXmlNode, Name, NodeValue));
    end;

    local procedure AddAttribute(var ParentXmlNode: XmlNode; Name: Text; NodeValue: Text): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        if (NodeValue = '') or (NodeValue = FormatDecimal(0)) then
            exit(false);

        exit(XMLDOMManagement.AddAttribute(ParentXmlNode, Name, NodeValue));
    end;

    local procedure AddAttributeWithPrefix(var ParentXmlNode: XmlNode; Name: Text; Prefix: Text; Namespace: Text; NodeValue: Text): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        if (NodeValue = '') or (NodeValue = FormatDecimal(0)) then
            exit(false);

        exit(XMLDOMManagement.AddAttributeWithPrefix(ParentXmlNode, Name, Prefix, Namespace, NodeValue));
    end;

    local procedure CreateSoapRequest(SoapBodyContentXmlDocument: XmlDocument; IsolatedCertificate: Record "Isolated Certificate"; var SoapXmlDocument: XmlDocument)
    var
        SoapEnvelopeXmlDocument: XmlDocument;
        SoapBodyXmlNode: XmlNode;
    begin
        CreateSoapEnvelope(SoapEnvelopeXmlDocument, SoapBodyXmlNode, IsolatedCertificate);
        AddContentToSoapEnvelope(SoapBodyXmlNode, SoapBodyContentXmlDocument);
        SignXmlDocument(SoapEnvelopeXmlDocument, IsolatedCertificate, SoapXmlDocument);
    end;

    local procedure CreateSoapEnvelope(var SoapEnvelopeXmlDocument: XmlDocument; var SoapBodyXmlNode: XmlNode; IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateManagement: Codeunit "Certificate Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        EnvelopeXmlNode: XmlNode;
        HeaderXmlNode: XmlNode;
        SecurityXmlNode: XmlNode;
        BinarySecurityTokenXmlNode: XmlNode;
    begin
        SoapEnvelopeXmlDocument := XmlDocument.Create();
        XMLDOMManagement.AddRootElementWithPrefix(SoapEnvelopeXmlDocument, 'Envelope', 'soap', SoapNamespaceTxt, EnvelopeXmlNode);
        XMLDOMManagement.AddElementWithPrefix(EnvelopeXmlNode, 'Header', '', 'soap', SoapNamespaceTxt, HeaderXmlNode);
        if IsolatedCertificate.Code <> '' then begin
            XMLDOMManagement.AddElementWithPrefix(HeaderXmlNode, 'Security', '', 'wsse', SecurityExtensionNamespaceTxt, SecurityXmlNode);
            AddAttributeWithPrefix(SecurityXmlNode, 'mustUnderstand', 'soap', SoapNamespaceTxt, '1');
            XMLDOMManagement.AddNamespaceDeclaration(SecurityXmlNode, 'wsu', SecurityUtilityNamespaceTxt);
            XMLDOMManagement.AddElementWithPrefix(
                SecurityXmlNode, 'BinarySecurityToken', CertificateManagement.GetRawCertDataAsBase64String(IsolatedCertificate),
                'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode);
            AddAttributeWithPrefix(BinarySecurityTokenXmlNode, 'Id', 'wsu', SecurityUtilityNamespaceTxt, CreateXmlElementID());
            AddAttribute(BinarySecurityTokenXmlNode, 'EncodingType', SecurityEncodingTypeBase64BinaryTxt);
            AddAttribute(BinarySecurityTokenXmlNode, 'ValueType', SecurityValueTypeX509V3Txt);
        end;

        XMLDOMManagement.AddElementWithPrefix(EnvelopeXmlNode, 'Body', '', 'soap', SoapNamespaceTxt, SoapBodyXmlNode);
        AddAttribute(SoapBodyXmlNode, 'Id', CreateXmlElementID());
    end;

    local procedure AddContentToSoapEnvelope(var SoapBodyXmlNode: XmlNode; SoapBodyContentXmlDocument: XmlDocument)
    var
        SoapBodyContentXmlElement: XmlElement;
    begin
        SoapBodyContentXmlDocument.GetRoot(SoapBodyContentXmlElement);
        SoapBodyXmlNode.AsXmlElement().Add(SoapBodyContentXmlElement);
    end;

    [NonDebuggable]
    local procedure SignXmlDocument(InputXmlDocument: XmlDocument; IsolatedCertificate: Record "Isolated Certificate"; var SignedXmlDocument: XmlDocument)
    var
        DataTempBlob: Codeunit "Temp Blob";
        SignatureTempBlob: Codeunit "Temp Blob";
        EETXmlSignProviderCZL: Codeunit "EET Xml Sign. Provider CZL";
        XMLDOMManagement: Codeunit "XML DOM Management";
        SignatureXmlDocument: XmlDocument;
        SignatureXmlElement: XmlElement;
        SecurityXmlNode: XmlNode;
        BinarySecurityTokenXmlNode: XmlNode;
        SoapBodyXmlNode: XmlNode;
        SoapXmlWriteOptions: XmlWriteOptions;
        SoapBodyId: Text;
        BinarySecurityTokenId: Text;
        DataInStream: InStream;
        DataOutStream: OutStream;
        SignatureInStream: InStream;
        SignatureOutStream: OutStream;
    begin
        XMLDOMManagement.FindNodeWithNamespace(
          InputXmlDocument.AsXmlNode(), BinarySecurityTokenPathTxt, 'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode);
        BinarySecurityTokenId := XMLDOMManagement.GetAttributeValue(BinarySecurityTokenXmlNode, 'Id', SecurityUtilityNamespaceTxt);

        XMLDOMManagement.FindNodeWithNamespace(
          InputXmlDocument.AsXmlNode(), BodyPathTxt, 'soap', SoapNamespaceTxt, SoapBodyXmlNode);
        SoapBodyId := XMLDOMManagement.GetAttributeValue(SoapBodyXmlNode, 'Id');

        EETXmlSignProviderCZL.SetSoapBodyId(SoapBodyId);
        EETXmlSignProviderCZL.SetBinarySecurityTokenId(BinarySecurityTokenId);

        DataTempBlob.CreateOutStream(DataOutStream);
        DataTempBlob.CreateInStream(DataInStream);
        SignatureTempBlob.CreateOutStream(SignatureOutStream);
        SignatureTempBlob.CreateInStream(SignatureInStream);
        SoapXmlWriteOptions.PreserveWhitespace := false;
        InputXmlDocument.WriteTo(SoapXmlWriteOptions, DataOutStream);
        EETXmlSignProviderCZL.SignData(DataInStream, IsolatedCertificate, SignatureOutStream);

        XmlDocument.ReadFrom(SignatureInStream, SignatureXmlDocument);
        SignatureXmlDocument.GetRoot(SignatureXmlElement);
        SignedXmlDocument := InputXmlDocument;

        XMLDOMManagement.FindNodeWithNamespace(
          SignedXmlDocument.AsXmlNode(), SecurityPathTxt, 'wsse', SecurityExtensionNamespaceTxt, SecurityXmlNode);
        SecurityXmlNode.AsXmlElement().Add(SignatureXmlElement);
    end;

    local procedure SendSoapRequest(RequestContentXmlDocument: XmlDocument; var ResponseXmlDocument: XmlDocument; var ResponseContentXmlDocument: XmlDocument)
    var
        EETServiceSetupCZL: Record "EET Service Setup CZL";
        SOAPWSRequestManagementCZL: Codeunit "SOAP WS Request Management CZL";
        IsOk: Boolean;
        IncorrectUrlErr: Label 'The Service URL is incorrectly set up on EET Service Setup page.';
    begin
        EETServiceSetupCZL.Get();
        if (EETServiceSetupCZL."Service URL" <> GetWebServiceURLTxt()) and (EETServiceSetupCZL."Service URL" <> GetWebServicePlayGroundURLTxt()) then
            Error(IncorrectUrlErr);
        SOAPWSRequestManagementCZL.SetAction(SoapActionTxt);
        SOAPWSRequestManagementCZL.SetTimeout(EETServiceSetupCZL."Limit Response Time");
        IsOk := SOAPWSRequestManagementCZL.SendRequestToWebService(EETServiceSetupCZL."Service URL", RequestContentXmlDocument);
        GlobalHttpRequestMessage := SOAPWSRequestManagementCZL.GetHttpRequestMessage();
        GlobalHttpResponseMessage := SOAPWSRequestManagementCZL.GetHttpResponseMessage();
        if not IsOk then begin
            CommunicationFailed := true;
            SOAPWSRequestManagementCZL.ProcessFaultResponse();
            exit;
        end;
        XmlDocument.ReadFrom(SOAPWSRequestManagementCZL.GetResponseAsText(), ResponseXmlDocument);
        ResponseContentXmlDocument := SOAPWSRequestManagementCZL.GetResponseContent();
    end;

    local procedure ProcessResponseContent(ResponseContentXmlDocument: XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        AcknowledgementXmlNode: XmlNode;
        XMLFormatErr: Label 'XML Format of response is not supported.';
    begin
        if VerificationMode or (ResponseContentErrorCode <> '') then
            exit;
        if not XMLDOMManagement.FindNodeWithNamespace(
             ResponseContentXmlDocument.AsXmlNode(), ConfirmationPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, AcknowledgementXmlNode)
        then begin
            LogMessage(TempErrorMessage."Message Type"::Error, '', XMLFormatErr);
            exit;
        end;

        POKControlCode := XMLDOMManagement.GetAttributeValue(AcknowledgementXmlNode, 'pok');
    end;

    local procedure ProcessResponseContentError(ResponseContentXmlDocument: XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        ErrorXmlNode: XmlNode;
    begin
        XMLDOMManagement.FindNodeWithNamespace(
          ResponseContentXmlDocument.AsXmlNode(), ErrorPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, ErrorXmlNode);

        ResponseContentError := ErrorXmlNode.AsXmlElement().InnerXml();
        ResponseContentErrorCode := XMLDOMManagement.GetAttributeValue(ErrorXmlNode, 'kod');
        if VerificationMode and (ResponseContentErrorCode = '0') then
            exit;

        LogMessage(TempErrorMessage."Message Type"::Error, ResponseContentErrorCode, ResponseContentError);
    end;

    local procedure ProcessResponseContentWarnings(ResponseContentXmlDocument: XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        WarningXmlNodeList: XmlNodeList;
        WarningXmlNode: XmlNode;
        ResponseContentWarning: Text;
        ResponseContentWarningCode: Text;
    begin
        XMLDOMManagement.FindNodesWithNamespace(
          ResponseContentXmlDocument.AsXmlNode(), WarningPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, WarningXmlNodeList);
        foreach WarningXmlNode in WarningXmlNodeList do begin
            ResponseContentWarning := WarningXmlNode.AsXmlElement().InnerXml();
            ResponseContentWarningCode := XMLDOMManagement.GetAttributeValue(WarningXmlNode, 'kod_varov');

            LogMessage(TempErrorMessage."Message Type"::Warning, ResponseContentWarningCode, ResponseContentWarning);
        end;
    end;

    local procedure HasResponseContentError(ResponseContentXmlDocument: XmlDocument): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        ErrorXmlNode: XmlNode;
    begin
        exit(
          XMLDOMManagement.FindNodeWithNamespace(
            ResponseContentXmlDocument.AsXmlNode(), ErrorPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, ErrorXmlNode));
    end;

    local procedure HasResponseContentWarnings(ResponseContentXmlDocument: XmlDocument): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        WarningXmlNode: XmlNode;
    begin
        exit(
          XMLDOMManagement.FindNodeWithNamespace(
            ResponseContentXmlDocument.AsXmlNode(), WarningPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, WarningXmlNode));
    end;

    local procedure CheckResponseContentHeader(ResponseContentXmlDocument: XmlDocument; EETEntryCZL: Record "EET Entry CZL")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        HeaderXmlNode: XmlNode;
        MessageUUID: Text;
        LogError: Boolean;
    begin
        if not XMLDOMManagement.FindNodeWithNamespace(
             ResponseContentXmlDocument.AsXmlNode(), HeaderPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, HeaderXmlNode)
        then
            exit;

        MessageUUID := XMLDOMManagement.GetAttributeValue(HeaderXmlNode, 'uuid_zpravy');
        LogError := ResponseContentErrorCode = '' ?
            (MessageUUID <> EETEntryCZL."Message UUID") :
            (MessageUUID <> EETEntryCZL."Message UUID") and (MessageUUID <> '');
        if LogError then
            LogMessage(TempErrorMessage."Message Type"::Error, '', MessageUUIDNotMatchErr);
    end;

    local procedure CheckResponseSecurity(ResponseXmlDocument: XmlDocument)
    var
        CertificateManagement: Codeunit "Certificate Management";
        CertBase64Value: Text;
        EETCertificateNotValidErr: Label 'Certificate of EET service is not valid.';
        MissingResponseSignatureErr: Label 'The response from the EET service is not signed.';
    begin
        if VerificationMode then
            exit;
        CertBase64Value := GetResponseCertificateAsBase64(ResponseXmlDocument);
        if CertBase64Value = '' then begin
            LogMessage(TempErrorMessage."Message Type"::Error, '', MissingResponseSignatureErr);
            exit;
        end;
        if not CertificateManagement.VerifyCertFromBase64(CertBase64Value) then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EETCertificateNotValidErr);
        CheckResponseCertificateOrganization(CertBase64Value);
    end;

    local procedure CheckResponseCertificateOrganization(CertBase64Value: Text)
    var
        X509Certificate2: Codeunit X509Certificate2;
        EmptyPassword: SecretText;
        CertificateSubject: Text;
        SubjectAttributes: Dictionary of [Text, List of [Text]];
        UnexpectedOrganizationErr: Label 'The response from the EET service was signed by an unexpected organization. The subject of the signing certificate is %1.', Comment = '%1 = subject of the signing certificate';
    begin
        X509Certificate2.GetCertificateSubject(CertBase64Value, EmptyPassword, CertificateSubject);
        ParseDistinguishedName(CertificateSubject, SubjectAttributes);
        if not HasSingleAttributeValue(SubjectAttributes, OrganizationAttributeTypeTxt, ExpectedCertOrganizationTxt) then
            LogMessage(TempErrorMessage."Message Type"::Error, '', StrSubstNo(UnexpectedOrganizationErr, CertificateSubject));
    end;

    local procedure HasSingleAttributeValue(Attributes: Dictionary of [Text, List of [Text]]; AttributeType: Text; ExpectedValue: Text): Boolean
    var
        Values: List of [Text];
    begin
        if not Attributes.ContainsKey(AttributeType) then
            exit(false);

        Values := Attributes.Get(AttributeType);
        exit((Values.Count() = 1) and (Values.Get(1) = ExpectedValue));
    end;

    local procedure ParseDistinguishedName(DistinguishedName: Text; var Attributes: Dictionary of [Text, List of [Text]])
    var
        Values: List of [Text];
        Attribute: Text;
        AttributeType: Text;
        EqualSignPosition: Integer;
    begin
        Clear(Attributes);
        foreach Attribute in SplitDistinguishedName(DistinguishedName) do begin
            EqualSignPosition := StrPos(Attribute, '=');
            if EqualSignPosition > 1 then begin
                AttributeType := NormalizeAttributeType(CopyStr(Attribute, 1, EqualSignPosition - 1));
                Clear(Values);
                if Attributes.ContainsKey(AttributeType) then
                    Values := Attributes.Get(AttributeType);
                Values.Add(UnescapeAttributeValue(CopyStr(Attribute, EqualSignPosition + 1)));
                Attributes.Set(AttributeType, Values);
            end;
        end;
    end;

    local procedure SplitDistinguishedName(DistinguishedName: Text) Attributes: List of [Text]
    var
        Position: Integer;
        Character: Text[1];
        Attribute: Text;
        Escaped: Boolean;
        Quoted: Boolean;
    begin
        // The attributes are separated by a comma, plus or semicolon that is neither quoted nor escaped.
        for Position := 1 to StrLen(DistinguishedName) do begin
            Character := CopyStr(DistinguishedName, Position, 1);
            if Escaped then begin
                Attribute += '\' + Character;
                Escaped := false;
            end else
                case Character of
                    '\':
                        Escaped := true;
                    '"':
                        begin
                            Quoted := not Quoted;
                            Attribute += Character;
                        end;
                    ',', '+', ';':
                        if Quoted then
                            Attribute += Character
                        else begin
                            Attributes.Add(Attribute);
                            Attribute := '';
                        end;
                    else
                        Attribute += Character;
                end;
        end;
        Attributes.Add(Attribute);
    end;

    local procedure NormalizeAttributeType(AttributeType: Text): Text
    begin
        AttributeType := UpperCase(DelChr(AttributeType, '<>', ' '));
        if AttributeType in [OrganizationOidPrefixedTxt, OrganizationOidTxt] then
            exit(OrganizationAttributeTypeTxt);
        exit(AttributeType);
    end;

    local procedure UnescapeAttributeValue(Value: Text) Result: Text
    var
        Position: Integer;
        Character: Text[1];
        Escaped: Boolean;
    begin
        Value := DelChr(Value, '<>', ' ');
        for Position := 1 to StrLen(Value) do begin
            Character := CopyStr(Value, Position, 1);
            if Escaped then begin
                Result += Character;
                Escaped := false;
            end else
                case Character of
                    '\':
                        Escaped := true;
                    '"':
                        ;
                    else
                        Result += Character;
                end;
        end;
    end;

    local procedure GetResponseCertificateAsBase64(ResponseXmlDocument: XmlDocument): Text
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        BinarySecurityTokenXmlNode: XmlNode;
    begin
        if XMLDOMManagement.FindNodeWithNamespace(
             ResponseXmlDocument.AsXmlNode(), BinarySecurityTokenPathTxt, 'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode)
        then
            exit(BinarySecurityTokenXmlNode.AsXmlElement().InnerText());
    end;

    local procedure Initialize()
    begin
        POKControlCode := '';
        ResponseContentError := '';
        ResponseContentErrorCode := '';
        CommunicationFailed := false;
        Clear(GlobalHttpRequestMessage);
        Clear(GlobalHttpResponseMessage);

        TempErrorMessage.ClearLog();
        ClearLastError();
    end;

    local procedure CreateXmlElementID(): Text
    var
        EETManagementCZL: Codeunit "EET Management CZL";
    begin
        exit('uuid-' + EETManagementCZL.CreateUUID());
    end;

    procedure FormatDecimal(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    procedure FormatBoolean(BooleanValue: Boolean): Text
    begin
        exit(Format(BooleanValue, 0, 9));
    end;

    procedure FormatDateTime(DateTimeValue: DateTime): Text
    begin
        exit(Format(RoundDateTime(DateTimeValue), 0, 9));
    end;

    local procedure IsVerificationModeOK(): Boolean
    begin
        exit(VerificationMode and (ResponseContentErrorCode = '0'));
    end;

    local procedure LogMessage(MessageType: Option; MessageCode: Text; MessageText: Text)
    var
        ErrorCodeTxt: Label 'Error Code: %1', Comment = '%1 = error code';
        WarningCodeTxt: Label 'Warning Code: %1', Comment = '%1 = warning code';
    begin
        TempErrorMessage.LogSimpleMessage(MessageType, MessageText);
        if MessageType = TempErrorMessage."Message Type"::Information then
            exit;
        if MessageType = TempErrorMessage."Message Type"::Warning then
            TempErrorMessage.Validate("Additional Information", StrSubstNo(WarningCodeTxt, MessageCode))
        else
            TempErrorMessage.Validate("Additional Information", StrSubstNo(ErrorCodeTxt, MessageCode));

        TempErrorMessage.Modify();
    end;

    procedure HasErrors(): Boolean
    begin
        exit(TempErrorMessage.HasErrors(false));
    end;

    procedure HasWarnings(): Boolean
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Warning);
        exit(not TempErrorMessage.IsEmpty);
    end;

    procedure GetWebServiceURLTxt(): Text[250]
    var
        WebServiceURLTxt: Label 'https://trzbyeet.gov.cz/eet/services/EETServiceSOAP/v4', Locked = true;
    begin
        exit(WebServiceURLTxt);
    end;

    procedure GetWebServicePlayGroundURLTxt(): Text[250]
    var
        WebServicePGURLTxt: Label 'https://pg.trzbyeet.gov.cz/eet/services/EETServiceSOAP/v4', Locked = true;
    begin
        exit(WebServicePGURLTxt);
    end;

    procedure GetPOKControlCode(): Text[39]
    begin
        exit(CopyStr(POKControlCode, 1, 39));
    end;

    procedure IsRetryableFailure() RetryableFailure: Boolean
    var
        EETManagement: Codeunit "EET Management CZL";
    begin
        // The EET service recommends sending the message again only after the error codes -1 (temporary error) and 8.
        // A failed communication is also temporary. Other errors, for example incorrect data or a missing certificate, are not solved by sending again.
        RetryableFailure := CommunicationFailed or (ResponseContentErrorCode in [TemporaryTechnicalErrorCode(), TechnicalErrorCode()]);
        EETManagement.OnIsRetryableFailure(CommunicationFailed, ResponseContentErrorCode, GlobalHttpResponseMessage, RetryableFailure);
    end;

    procedure GetHttpRequestMessage(): HttpRequestMessage
    begin
        exit(GlobalHttpRequestMessage);
    end;

    procedure GetHttpResponseMessage(): HttpResponseMessage
    begin
        exit(GlobalHttpResponseMessage);
    end;

    procedure GetResponseText(): Text
    begin
        if IsVerificationModeOK() then
            exit(ResponseContentError);
        if GetLastErrorText() <> '' then
            exit(GetLastErrorText);

        TempErrorMessage.Reset();
        TempErrorMessage.FindFirst();
        exit(TempErrorMessage."Message");
    end;

    procedure SetVerificationMode(NewVerificationMode: Boolean)
    begin
        VerificationMode := NewVerificationMode;
    end;

    procedure SetURLToDefault(var EETServiceSetupCZL: Record "EET Service Setup CZL")
    begin
        EETServiceSetupCZL."Service URL" := GetWebServicePlayGroundURLTxt();
    end;

    procedure CopyErrorMessageToTemp(var TempDestinationErrorMessage: Record "Error Message" temporary)
    begin
        if (GetLastErrorText <> ResponseContentError) and (GetLastErrorText <> '') then
            LogMessage(TempErrorMessage."Message Type"::Error, GetLastErrorCode, GetLastErrorText);

        TempErrorMessage.Reset();
        TempErrorMessage.CopyToTemp(TempDestinationErrorMessage);
    end;

    local procedure GetMaxReceiptSerialNoLength(): Integer
    begin
        exit(25);
    end;

    local procedure GetMaxSoapMessageSize(): Integer
    begin
        exit(12288);
    end;

    local procedure TemporaryTechnicalErrorCode(): Text
    begin
        exit('-1'); // Temporary technical error in processing - please re-send the data message later
    end;

    local procedure TechnicalErrorCode(): Text
    begin
        exit('8'); // The data message was not processed because of a technical error or a data error
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", OnRegisterServiceConnection, '', false, false)]
    local procedure HandleEETRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        EETServiceSetupCZL: Record "EET Service Setup CZL";
        PageEETServiceSetupCZL: Page "EET Service Setup CZL";
        EETServiceSetupRecordRef: RecordRef;
    begin
        if not EETServiceSetupCZL.Get() then begin
            EETServiceSetupCZL.Init();
            EETServiceSetupCZL.Insert(true);
        end;
        EETServiceSetupRecordRef.GetTable(EETServiceSetupCZL);
        if EETServiceSetupCZL.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
            ServiceConnection, EETServiceSetupRecordRef.RecordId, PageEETServiceSetupCZL.Caption(), EETServiceSetupCZL."Service URL", PAGE::"EET Service Setup CZL");
    end;
}

