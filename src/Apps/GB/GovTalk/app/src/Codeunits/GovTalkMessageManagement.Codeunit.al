// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Company;
using System;
using System.Integration;
using System.Threading;
using System.Utilities;

codeunit 10569 "GovTalk Message Management"
{
    trigger OnRun()
    begin
    end;

    var
        GovTalkSetup: Record "Gov Talk Setup";
        CompanyInformation: Record "Company Information";
        GovTalkXMLHelper: Codeunit "GovTalk XML Helper";
        GovTalkNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/envelope', Locked = true;
        VATDeclarationMessageClassTxt: Label 'HMRC-VAT-DEC', Locked = true;
        ECSLDeclarationMessageClassTxt: Label 'HMCE-ECSL-ORG-V101', Locked = true;
        ErrorResponseNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/errorresponse', Locked = true;
        SuccessResponseNameSpaceTxt: Label 'http://www.inlandrevenue.gov.uk/SuccessResponse', Locked = true;
        VATDeclarationNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/vatdeclaration/2', Locked = true;
        ECSLDeclarationNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/europeansalesdeclaration/1', Locked = true;
        VATCoreNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/core/1', Locked = true;
        InvalidGovTalkMessagePartIDErr: Label 'The XML part id is invalid.';
        MessageClassTxt: Label '%1-TIL', Comment = '%1 = message class';
        NotificationTxt: Label 'Line No. %1 Acknowledged', Comment = '%1 = response node';
        ErrorTxt: Label 'Line No. %1 failed with error: %2', Comment = '%1 = response node, %2 = status node';


#if not CLEAN30
    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Use CreateBlankGovTalkXmlMessage with XmlElement parameters instead.', '30.0')]
    procedure CreateBlankGovTalkXmlMessage(var GovTalkMessageXMLNode: DotNet XmlNode; var BodyXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header"; Qualifier: Text; Fn: Text; IncludeSenderDetails: Boolean): Boolean
    var
        GovTalkMessageXmlElement: XmlElement;
        BodyXmlElement: XmlElement;
    begin
        if not CreateBlankGovTalkXmlMessage(GovTalkMessageXmlElement, BodyXmlElement, VATReportHeader, Qualifier, Fn, IncludeSenderDetails) then
            exit(false);
        ConvertToDotNetXmlNode(GovTalkMessageXmlElement, GovTalkMessageXMLNode);
        BodyXMLNode := GovTalkMessageXMLNode.LastChild;
        exit(true);
    end;
#endif

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure CreateBlankGovTalkXmlMessage(var GovTalkMessageXmlElement: XmlElement; var BodyXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header"; Qualifier: Text; Fn: Text; IncludeSenderDetails: Boolean): Boolean
    var
        GovTalkMessage: Record "GovTalk Message";
        GovTalkVATReportValidate: Codeunit "GovTalk Validate VAT Report";
        HeaderXmlElement: XmlElement;
        MessageDetailsXmlElement: XmlElement;
        SenderDetailsXmlElement: XmlElement;
        IDAuthenticationXmlElement: XmlElement;
        AuthenticationXmlElement: XmlElement;
        GovTalkDetailsXmlElement: XmlElement;
        KeysXmlElement: XmlElement;
        VATRegNoXmlElement: XmlElement;
        BranchNoXmlElement: XmlElement;
        PostCodeXmlElement: XmlElement;
        ChannelRoutingXmlElement: XmlElement;
        ChannelXmlElement: XmlElement;
        DummyXmlElement: XmlElement;
    begin
        if not GovTalkVATReportValidate.ValidateGovTalkPrerequisites(VATReportHeader) then
            exit(false);

        GovTalkSetup.FindFirst();
        CompanyInformation.Get();

        if not GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.") then
            InitGovTalkMessage(GovTalkMessage, VATReportHeader);

        // QUCIK XML SCHEMA BREIF
        // GovTalkMessage
        // -EnvelopeVersion
        // -Header
        // --MessageDetails
        // ---Class
        // ---Qualifier
        // ---Function
        // ---CorrelationID
        // ---Transformation
        // --SenderDetails
        // ---IDAuthentication
        // ----SenderID
        // ----Authentication
        // -----Method
        // -----Value
        // -GovTalkDetails
        // --Keys
        // ---Key (Type=VATRegNo)
        // --ChannelRouting
        // ---Channel
        // ----URI (VendorID)
        // -Body
        GovTalkXMLHelper.CreateDocumentWithRootElement('GovTalkMessage', GovTalkNameSpaceTxt, GovTalkMessageXmlElement);
        GovTalkXMLHelper.AddElement(GovTalkMessageXmlElement, 'EnvelopeVersion', '2.0', GovTalkNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(GovTalkMessageXmlElement, 'Header', '', GovTalkNameSpaceTxt, HeaderXmlElement);
        GovTalkXMLHelper.AddElement(GovTalkMessageXmlElement, 'GovTalkDetails', '', GovTalkNameSpaceTxt, GovTalkDetailsXmlElement);
        GovTalkXMLHelper.AddElement(GovTalkMessageXmlElement, 'Body', '', GovTalkNameSpaceTxt, BodyXmlElement);

        GovTalkXMLHelper.AddElement(HeaderXmlElement, 'MessageDetails', '', GovTalkNameSpaceTxt, MessageDetailsXmlElement);

        if GovTalkSetup."Test Mode" then
            GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'Class',
              StrSubstNo(MessageClassTxt, GovTalkMessage."Message Class"), GovTalkNameSpaceTxt, DummyXmlElement)
        else
            GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'Class', GovTalkMessage."Message Class", GovTalkNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'Qualifier', Qualifier, GovTalkNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'Function', Fn, GovTalkNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'CorrelationID', VATReportHeader."Message Id", GovTalkNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(MessageDetailsXmlElement, 'Transformation', 'XML', GovTalkNameSpaceTxt, DummyXmlElement);

        if IncludeSenderDetails then begin
            GovTalkXMLHelper.AddElement(HeaderXmlElement, 'SenderDetails', '', GovTalkNameSpaceTxt, SenderDetailsXmlElement);
            GovTalkXMLHelper.AddElement(SenderDetailsXmlElement, 'IDAuthentication', '', GovTalkNameSpaceTxt, IDAuthenticationXmlElement);
            GovTalkXMLHelper.AddElement(IDAuthenticationXmlElement, 'SenderID', GovTalkSetup.Username, GovTalkNameSpaceTxt, DummyXmlElement);
            GovTalkXMLHelper.AddElement(IDAuthenticationXmlElement, 'Authentication', '', GovTalkNameSpaceTxt, AuthenticationXmlElement);
            GovTalkXMLHelper.AddElement(AuthenticationXmlElement, 'Method', 'clear', GovTalkNameSpaceTxt, DummyXmlElement);
            GovTalkXMLHelper.AddElement(AuthenticationXmlElement, 'Value', GovTalkSetup.GetPassword(), GovTalkNameSpaceTxt, DummyXmlElement);
        end;

        GovTalkXMLHelper.AddElement(GovTalkDetailsXmlElement, 'Keys', '', GovTalkNameSpaceTxt, KeysXmlElement);
        if IncludeSenderDetails then begin
            // EC Sales List specifics
            if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"EC Sales List" then begin
                GovTalkXMLHelper.AddElement(KeysXmlElement, 'Key', CompanyInformation."Branch Number GB", GovTalkNameSpaceTxt, BranchNoXmlElement);
                BranchNoXmlElement.SetAttribute('Type', 'BranchNo');
                GovTalkXMLHelper.AddElement(KeysXmlElement, 'Key', DelChr(CompanyInformation."Post Code", '=', '- '), GovTalkNameSpaceTxt, PostCodeXmlElement);
                PostCodeXmlElement.SetAttribute('Type', 'Postcode');
            end;
            GovTalkXMLHelper.AddElement(KeysXmlElement, 'Key',
              FormatVATRegNo(CompanyInformation."Country/Region Code", CompanyInformation."VAT Registration No."),
              GovTalkNameSpaceTxt, VATRegNoXmlElement);
            VATRegNoXmlElement.SetAttribute('Type', 'VATRegNo');
        end;
        GovTalkXMLHelper.AddElement(GovTalkDetailsXmlElement, 'ChannelRouting', '', GovTalkNameSpaceTxt, ChannelRoutingXmlElement);
        GovTalkXMLHelper.AddElement(ChannelRoutingXmlElement, 'Channel', '', GovTalkNameSpaceTxt, ChannelXmlElement);
        GovTalkXMLHelper.AddElement(ChannelXmlElement, 'URI', GovTalkSetup.GetVendorID(), GovTalkNameSpaceTxt, DummyXmlElement);

        exit(true);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use CreateGovTalkPollMessage with an XmlElement parameter instead.', '30.0')]
    procedure CreateGovTalkPollMessage(var GovTalkMessageXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header")
    var
        DummyXMLNode: DotNet XmlNode;
    begin
        CreateBlankGovTalkXmlMessage(GovTalkMessageXMLNode, DummyXMLNode, VATReportHeader, 'poll', 'submit', false);
    end;
#endif

    [Scope('OnPrem')]
    procedure CreateGovTalkPollMessage(var GovTalkMessageXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header")
    var
        DummyXmlElement: XmlElement;
    begin
        CreateBlankGovTalkXmlMessage(GovTalkMessageXmlElement, DummyXmlElement, VATReportHeader, 'poll', 'submit', false);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Use CreateGovTalkDeleteMessage with an XmlElement parameter instead.', '30.0')]
    procedure CreateGovTalkDeleteMessage(var GovTalkMessageXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header")
    var
        DummyXMLNode: DotNet XmlNode;
    begin
        CreateBlankGovTalkXmlMessage(GovTalkMessageXMLNode, DummyXMLNode, VATReportHeader, 'request', 'delete', false);
    end;
#endif

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure CreateGovTalkDeleteMessage(var GovTalkMessageXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header")
    var
        DummyXmlElement: XmlElement;
    begin
        CreateBlankGovTalkXmlMessage(GovTalkMessageXmlElement, DummyXmlElement, VATReportHeader, 'request', 'delete', false);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use SendHttpRequest with XmlElement parameters instead.', '30.0')]
    procedure SendHttpRequest(var GovTalkMessageXMLNode: DotNet XmlNode; SubmitURL: Text; var SubmitResponseXMLNode: DotNet XmlNode): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        GovTalkMessageXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
        XmlDoc: DotNet XmlDocument;
        ResponseInStream: InStream;
    begin
        ConvertFromDotNetXmlNode(GovTalkMessageXMLNode, GovTalkMessageXmlElement, PreserveWhitespace);
        if not SendHttpRequest(GovTalkMessageXmlElement, PreserveWhitespace, SubmitURL, TempBlob) then
            exit(false);
        TempBlob.CreateInStream(ResponseInStream);
        if TryLoadDotNetXmlDocument(ResponseInStream, XmlDoc) then
            SubmitResponseXMLNode := XmlDoc.DocumentElement;
        exit(true);
    end;

    [TryFunction]
    local procedure TryLoadDotNetXmlDocument(XmlInStream: InStream; var XmlDoc: DotNet XmlDocument)
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.Load(XmlInStream);
    end;

    local procedure ConvertToDotNetXmlNode(GovTalkMessageXmlElement: XmlElement; var GovTalkMessageXMLNode: DotNet XmlNode)
    var
        XmlDoc: DotNet XmlDocument;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.LoadXml(GovTalkXMLHelper.GetXmlAsText(GovTalkMessageXmlElement));
        GovTalkMessageXMLNode := XmlDoc.DocumentElement;
    end;

    local procedure ConvertFromDotNetXmlNode(GovTalkMessageXMLNode: DotNet XmlNode; var GovTalkMessageXmlElement: XmlElement; var PreserveWhitespace: Boolean)
    var
        GovTalkXmlDocument: XmlDocument;
        XmlReadOptions: XmlReadOptions;
    begin
        PreserveWhitespace := GovTalkMessageXMLNode.OwnerDocument.PreserveWhitespace;
        XmlReadOptions.PreserveWhitespace(true);
        XmlDocument.ReadFrom(GovTalkMessageXMLNode.OwnerDocument.OuterXml, XmlReadOptions, GovTalkXmlDocument);
        GovTalkXmlDocument.GetRoot(GovTalkMessageXmlElement);
    end;
#endif

    [Scope('OnPrem')]
    procedure SendHttpRequest(GovTalkMessageXmlElement: XmlElement; SubmitURL: Text; var SubmitResponseXmlElement: XmlElement): Boolean
    begin
        exit(SendHttpRequest(GovTalkMessageXmlElement, false, SubmitURL, SubmitResponseXmlElement));
    end;

    local procedure SendHttpRequest(GovTalkMessageXmlElement: XmlElement; PreserveWhitespace: Boolean; SubmitURL: Text; var SubmitResponseXmlElement: XmlElement): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
    begin
        if not SendHttpRequest(GovTalkMessageXmlElement, PreserveWhitespace, SubmitURL, TempBlob) then
            exit(false);
        TempBlob.CreateInStream(ResponseInStream);
        GovTalkXMLHelper.LoadXmlFromInStream(ResponseInStream, SubmitResponseXmlElement);
        exit(true);
    end;

    local procedure SendHttpRequest(GovTalkMessageXmlElement: XmlElement; PreserveWhitespace: Boolean; SubmitURL: Text; var ResponseTempBlob: Codeunit "Temp Blob"): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebRequest: DotNet HttpWebRequest;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        HttpWebResponse: DotNet HttpWebResponse;
        RequestOutStream: OutStream;
        ResponseInStream: InStream;
    begin
        HttpWebRequest := HttpWebRequest.Create(SubmitURL);
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.AllowAutoRedirect := true;
        HttpWebRequest.ContentType := 'text/xml';
        HttpWebRequest.Headers.Add('Accept-Encoding', 'utf-8');

        ResponseTempBlob.CreateInStream(ResponseInStream);
        RequestOutStream := HttpWebRequest.GetRequestStream();
        GovTalkXMLHelper.CopyXmlToOutStream(GovTalkMessageXmlElement, PreserveWhitespace, RequestOutStream);
        if WebRequestHelper.GetWebResponse(HttpWebRequest, HttpWebResponse, ResponseInStream,
             HttpStatusCode, ResponseHeaders, true)
        then
            exit(HttpStatusCode.Equals(HttpStatusCode.OK));
        exit(false);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use ReadGatewayErrors with an XmlElement parameter instead.', '30.0')]
    procedure ReadGatewayErrors(var VATReportHeader: Record "VAT Report Header"; SubmitResponseXMLNode: DotNet XmlNode)
    var
        SubmitResponseXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(SubmitResponseXMLNode, SubmitResponseXmlElement, PreserveWhitespace);
        ReadGatewayErrors(VATReportHeader, SubmitResponseXmlElement);
    end;
#endif

    [Scope('OnPrem')]
    procedure ReadGatewayErrors(var VATReportHeader: Record "VAT Report Header"; SubmitResponseXmlElement: XmlElement)
    var
        GovTalkMessageParts: Record "GovTalk Msg. Parts";
        ErrorsXmlElement: XmlElement;
        CorrelationXmlElement: XmlElement;
        ChildXmlNode: XmlNode;
        BusinessErrorExists: Boolean;
    begin
        if
           GovTalkXMLHelper.FindElement(SubmitResponseXmlElement, '//x:GovTalkErrors', 'x', GovTalkNameSpaceTxt, ErrorsXmlElement)
        then begin
            foreach ChildXmlNode in ErrorsXmlElement.GetChildNodes() do
                if LowerCase(
                     GovTalkXMLHelper.FindNodeText(ChildXmlNode, 'x:RaisedBy', 'x', GovTalkNameSpaceTxt)) = 'department'
                then
                    BusinessErrorExists := true
                else
                    LogErrorEntry(VATReportHeader, GovTalkXMLHelper.FindNodeText(
                        ChildXmlNode, 'x:Text', 'x', GovTalkNameSpaceTxt));
            if BusinessErrorExists then
                ReadBusinessErrors(VATReportHeader, SubmitResponseXmlElement);

            if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"EC Sales List" then begin
                if not GovTalkXMLHelper.FindElement(
                     SubmitResponseXmlElement, '//x:CorrelationID', 'x', GovTalkNameSpaceTxt, CorrelationXmlElement)
                then
                    Error('');
                SetPartStatus(CorrelationXmlElement.InnerText(), GovTalkMessageParts.Status::Rejected);
                UpdateVATReportStatus(VATReportHeader);
            end else begin
                VATReportHeader.Validate(Status, VATReportHeader.Status::Rejected);
                VATReportHeader.Modify(true);
            end;
        end;
    end;

    local procedure ReadBusinessErrors(VATReportHeader: Record "VAT Report Header"; SubmitResponseXmlElement: XmlElement)
    var
        ErrorsXmlElement: XmlElement;
        ChildXmlNodes: XmlNodeList;
        ChildXmlNode: XmlNode;
    begin
        if GovTalkXMLHelper.FindElement(SubmitResponseXmlElement, '//x:ErrorResponse', 'x', ErrorResponseNameSpaceTxt, ErrorsXmlElement) then begin
            GovTalkXMLHelper.FindNodes(ErrorsXmlElement, 'x:Error', 'x', ErrorResponseNameSpaceTxt, ChildXmlNodes);
            foreach ChildXmlNode in ChildXmlNodes do
                LogErrorEntry(VATReportHeader, GovTalkXMLHelper.FindNodeText(
                    ChildXmlNode, 'x:Text', 'x', ErrorResponseNameSpaceTxt));
            ReadECSLDeclarationResponse(VATReportHeader, ErrorsXmlElement);
        end;
    end;

    local procedure LogErrorEntry(VATReportHeader: Record "VAT Report Header"; ErrorText: Text)
    var
        ErrorMessageLog: Record "Error Message";
    begin
        ErrorMessageLog.LockTable();
        ErrorMessageLog.SetContext(VATReportHeader);
        ErrorMessageLog.LogMessage(VATReportHeader, VATReportHeader.FieldNo("No."), ErrorMessageLog."Message Type"::Error, ErrorText);
    end;

    local procedure LogNotificationEntry(VATReportHeader: Record "VAT Report Header"; NotificationText: Text)
    var
        ErrorMessageLog: Record "Error Message";
    begin
        ErrorMessageLog.LockTable();
        ErrorMessageLog.SetContext(VATReportHeader);
        ErrorMessageLog.LogMessage(VATReportHeader,
          VATReportHeader.FieldNo("No."), ErrorMessageLog."Message Type"::Information, NotificationText);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use ReadSuccessResponse with an XmlElement parameter instead.', '30.0')]
    procedure ReadSuccessResponse(var VATReportHeader: Record "VAT Report Header"; SubmitResponseXMLNode: DotNet XmlNode)
    var
        SubmitResponseXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(SubmitResponseXMLNode, SubmitResponseXmlElement, PreserveWhitespace);
        ReadSuccessResponse(VATReportHeader, SubmitResponseXmlElement);
    end;
#endif

    [Scope('OnPrem')]
    procedure ReadSuccessResponse(var VATReportHeader: Record "VAT Report Header"; SubmitResponseXmlElement: XmlElement)
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        SuccessResponseXmlElement: XmlElement;
        CorrelationXmlElement: XmlElement;
    begin
        if GovTalkXMLHelper.FindElement(
             SubmitResponseXmlElement, '//suc:SuccessResponse', 'suc', SuccessResponseNameSpaceTxt, SuccessResponseXmlElement)
        then begin
            ReadVATDeclarationResponse(VATReportHeader, SuccessResponseXmlElement);
            ReadECSLDeclarationResponse(VATReportHeader, SuccessResponseXmlElement);
            if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"VAT Return" then begin
                VATReportHeader.Validate(Status, VATReportHeader.Status::Accepted);
                VATReportHeader.Modify(true);
            end else begin
                if not GovTalkXMLHelper.FindElement(
                     SuccessResponseXmlElement, '//x:CorrelationID', 'x', GovTalkNameSpaceTxt, CorrelationXmlElement)
                then
                    Error('');
                SetPartStatus(CorrelationXmlElement.InnerText(), VATReportHeader.Status::Accepted.AsInteger());
                UpdateVATReportStatus(VATReportHeader);
            end;
            if VATReportsConfiguration.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."VAT Report Version") then
                if VATReportsConfiguration."Response Handler Codeunit ID" <> 0 then
                    CODEUNIT.Run(VATReportsConfiguration."Response Handler Codeunit ID");
        end;
    end;

    local procedure ReadVATDeclarationResponse(VATReportHeader: Record "VAT Report Header"; SuccessResponseXmlElement: XmlElement)
    var
        PaymentNotificationXmlElement: XmlElement;
        InformationNotificationXmlNodes: XmlNodeList;
        InformationNotificationXmlNode: XmlNode;
    begin
        if GovTalkXMLHelper.FindElement(
             SuccessResponseXmlElement, '//x:PaymentNotification', 'x', VATDeclarationNameSpaceTxt, PaymentNotificationXmlElement)
        then
            LogNotificationEntry(VATReportHeader, GovTalkXMLHelper.FindNodeText(
                PaymentNotificationXmlElement, 'x:Narrative', 'x', VATDeclarationNameSpaceTxt));
        GovTalkXMLHelper.FindNodes(SuccessResponseXmlElement,
          '//x:InformationNotification', 'x', VATDeclarationNameSpaceTxt, InformationNotificationXmlNodes);
        foreach InformationNotificationXmlNode in InformationNotificationXmlNodes do
            LogNotificationEntry(VATReportHeader, GovTalkXMLHelper.FindNodeText(
                InformationNotificationXmlNode, 'x:Narrative', 'x', VATDeclarationNameSpaceTxt));
    end;

    local procedure ReadECSLDeclarationResponse(VATReportHeader: Record "VAT Report Header"; SuccessResponseXmlElement: XmlElement)
    var
        EuropeanSaleResponseXmlNodes: XmlNodeList;
        EuropeanSaleResponseXmlNode: XmlNode;
        LineResponseXmlElement: XmlElement;
        LineStatusXmlElement: XmlElement;
        DummyXmlElement: XmlElement;
    begin
        if GovTalkXMLHelper.FindNodes(
                 SuccessResponseXmlElement, '//ns:EuropeanSaleResponse', 'ns', ECSLDeclarationNameSpaceTxt, EuropeanSaleResponseXmlNodes)
            then
            foreach EuropeanSaleResponseXmlNode in EuropeanSaleResponseXmlNodes do
                if GovTalkXMLHelper.FindElement(EuropeanSaleResponseXmlNode.AsXmlElement(),
                     'ns1:EuropeanSale', 'ns1', VATCoreNameSpaceTxt, LineResponseXmlElement) and
                   GovTalkXMLHelper.FindElement(EuropeanSaleResponseXmlNode.AsXmlElement(), 'ns1:Status', 'ns1', VATCoreNameSpaceTxt, LineStatusXmlElement)
                then
                    if GovTalkXMLHelper.FindElement(LineStatusXmlElement, 'ns1:Acknowledged', 'ns1', VATCoreNameSpaceTxt, DummyXmlElement) then
                        LogNotificationEntry(VATReportHeader, StrSubstNo(
                            NotificationTxt,
                            GovTalkXMLHelper.FindNodeText(LineResponseXmlElement, 'ns1:SubmittersReference', 'ns1', VATCoreNameSpaceTxt)))
                    else
                        LogErrorEntry(VATReportHeader, StrSubstNo(ErrorTxt,
                            GovTalkXMLHelper.FindNodeText(LineResponseXmlElement, 'ns1:SubmittersReference', 'ns1', VATCoreNameSpaceTxt),
                            GovTalkXMLHelper.FindNodeText(LineStatusXmlElement, 'ns1:Error', 'ns1', VATCoreNameSpaceTxt)));
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use SubmitGovTalkRequest with an XmlElement parameter instead.', '30.0')]
    procedure SubmitGovTalkRequest(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXMLNode: DotNet XmlNode): Boolean
    var
        GovTalkMessageXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(GovTalkMessageXMLNode, GovTalkMessageXmlElement, PreserveWhitespace);
        exit(SubmitGovTalkRequest(VATReportHeader, GovTalkMessageXmlElement, PreserveWhitespace));
    end;
#endif

    [Scope('OnPrem')]
    procedure SubmitGovTalkRequest(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXmlElement: XmlElement): Boolean
    begin
        exit(SubmitGovTalkRequest(VATReportHeader, GovTalkMessageXmlElement, false));
    end;

    /// <summary>
    /// Submits a GovTalk message. When PreserveWhitespace is true, the message is sent and archived without indentation,
    /// which is required for messages that carry an IRmark.
    /// </summary>
    internal procedure SubmitGovTalkRequest(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXmlElement: XmlElement; PreserveWhitespace: Boolean): Boolean
    var
        DummyGuid: Guid;
    begin
        GovTalkSetup.FindFirst();
        ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, PreserveWhitespace, 0, DummyGuid);
        exit(ProcessGovTalkSubmission(VATReportHeader, GovTalkSetup.Endpoint, GovTalkMessageXmlElement, PreserveWhitespace, true, true, DummyGuid));
    end;

    [Scope('OnPrem')]
    procedure SubmitGovTalkCancelRequest(var VATReportHeader: Record "VAT Report Header")
    begin
        if SubmitGovTalkDeleteRequest(VATReportHeader, true) then begin
            VATReportHeader.Validate(Status, VATReportHeader.Status::Canceled);
            VATReportHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure RegisterGovTalkPolling(var VATReportHeader: Record "VAT Report Header"; XMLPartID: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
        GovTalkMessage: Record "GovTalk Message";
    begin
        GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.");
        if GovTalkMessage."Polling Count" = 0 then begin
            VATReportHeader.Status := VATReportHeader.Status::Rejected;
            VATReportHeader.Modify();
            exit;
        end;
        GovTalkMessage."Polling Count" -= 1;
        GovTalkMessage.Modify();

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"HMRC GovTalk Msg. Scheduler";
        JobQueueEntry."Record ID to Process" := VATReportHeader.RecordId;
        JobQueueEntry."Parameter String" := Format(XMLPartID);
        JobQueueEntry."Rerun Delay (sec.)" := GovTalkMessage.PollInterval;
        JobQueueEntry."Maximum No. of Attempts to Run" := 100;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + (GovTalkMessage.PollInterval * 1000);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SubmitGovTalkDeleteRequest(var VATReportHeader: Record "VAT Report Header"; LogMessage: Boolean): Boolean
    var
        GovTalkMessage: Record "GovTalk Message";
        GovTalkMessageXmlElement: XmlElement;
        DummyGuid: Guid;
    begin
        if VATReportHeader."Message Id" = '' then
            exit(true);
        CreateGovTalkDeleteMessage(GovTalkMessageXmlElement, VATReportHeader);
        if GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.") then begin
            if GovTalkMessage.ResponseEndPoint = '' then
                exit(false);
            if LogMessage then
                ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, 0, DummyGuid);
            if ProcessGovTalkSubmission(VATReportHeader, GovTalkMessage.ResponseEndPoint, GovTalkMessageXmlElement, LogMessage, false, DummyGuid) then begin
                VATReportHeader."Message Id" := '';
                VATReportHeader.Modify(true);
                exit(true);
            end;
        end;
        exit(false);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use ArchiveXMLMessage with an XmlElement parameter instead.', '30.0')]
    procedure ArchiveXMLMessage(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXMLNode: DotNet XmlNode; MessageType: Option Submission,Response; XMLPartID: Guid)
    var
        GovTalkMessageXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(GovTalkMessageXMLNode, GovTalkMessageXmlElement, PreserveWhitespace);
        ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, PreserveWhitespace, MessageType, XMLPartID);
    end;
#endif

    [Scope('OnPrem')]
    procedure ArchiveXMLMessage(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXmlElement: XmlElement; MessageType: Option Submission,Response; XMLPartID: Guid)
    begin
        ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, false, MessageType, XMLPartID);
    end;

    local procedure ArchiveXMLMessage(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXmlElement: XmlElement; PreserveWhitespace: Boolean; MessageType: Option Submission,Response; XMLPartID: Guid)
    var
        VATReportArchive: Record "VAT Report Archive";
        TempBlob: Codeunit "Temp Blob";
    begin
        GovTalkXMLHelper.WriteXmlToTempBlob(GovTalkMessageXmlElement, PreserveWhitespace, TempBlob);
#if not CLEAN27
#pragma warning disable AL0432
        if MessageType = MessageType::Submission then
            VATReportArchive.ArchiveSubmissionMessage(
                VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.", TempBlob, XMLPartID)
        else
            VATReportArchive.ArchiveResponseMessage(
                VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.", TempBlob, XMLPartID);
#else
        if VATReportArchive.Get(VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.", XMLPartID) then
            if MessageType = MessageType::Submission then begin
                VATReportArchive.SetXMLPartID(XMLPartID);
                VATReportArchive.ArchiveSubmissionMessage(
                    VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.", TempBlob)
            end else
                VATReportArchive.ArchiveResponseMessage(
                    VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.", TempBlob);
#pragma warning restore AL0432                    
#endif
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use ProcessGovTalkSubmission with an XmlElement parameter instead.', '30.0')]
    procedure ProcessGovTalkSubmission(var VATReportHeader: Record "VAT Report Header"; SubmissionEndPoint: Text; GovTalkMessageXMLNode: DotNet XmlNode; LogResponse: Boolean; FlushGateway: Boolean; XMlPartId: Guid): Boolean
    var
        GovTalkMessageXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(GovTalkMessageXMLNode, GovTalkMessageXmlElement, PreserveWhitespace);
        exit(ProcessGovTalkSubmission(VATReportHeader, SubmissionEndPoint, GovTalkMessageXmlElement, PreserveWhitespace, LogResponse, FlushGateway, XMlPartId));
    end;
#endif

    [Scope('OnPrem')]
    procedure ProcessGovTalkSubmission(var VATReportHeader: Record "VAT Report Header"; SubmissionEndPoint: Text; GovTalkMessageXmlElement: XmlElement; LogResponse: Boolean; FlushGateway: Boolean; XMlPartId: Guid): Boolean
    begin
        exit(ProcessGovTalkSubmission(VATReportHeader, SubmissionEndPoint, GovTalkMessageXmlElement, false, LogResponse, FlushGateway, XMlPartId));
    end;

    local procedure ProcessGovTalkSubmission(var VATReportHeader: Record "VAT Report Header"; SubmissionEndPoint: Text; GovTalkMessageXmlElement: XmlElement; PreserveWhitespace: Boolean; LogResponse: Boolean; FlushGateway: Boolean; XMlPartId: Guid): Boolean
    var
        GovTalkMessage: Record "GovTalk Message";
        SubmitResponseXmlElement: XmlElement;
        ResponseQualifierXmlElement: XmlElement;
        CorrelationIDXmlElement: XmlElement;
        ResponseEndPointXmlElement: XmlElement;
        PollIntervalXmlAttribute: XmlAttribute;
        CorrelationXmlElement: XmlElement;
        PollInterval: Integer;
    begin
        if SendHttpRequest(GovTalkMessageXmlElement, PreserveWhitespace, SubmissionEndPoint, SubmitResponseXmlElement) then begin
            if LogResponse then
                ArchiveXMLMessage(VATReportHeader, SubmitResponseXmlElement, false, 1, XMlPartId);
            if GovTalkXMLHelper.FindElement(
                 SubmitResponseXmlElement, '//x:CorrelationID', 'x', GovTalkNameSpaceTxt, CorrelationIDXmlElement)
            then
                PersistCorrelationID(VATReportHeader, XMlPartId, CopyStr(CorrelationIDXmlElement.InnerText(), 1, 250));

            if GovTalkXMLHelper.FindElement(
                 SubmitResponseXmlElement, '//x:ResponseEndPoint', 'x', GovTalkNameSpaceTxt, ResponseEndPointXmlElement)
            then begin
                ResponseEndPointXmlElement.Attributes().Get('PollInterval', PollIntervalXmlAttribute);
                Evaluate(PollInterval, PollIntervalXmlAttribute.Value());
                if GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.") then begin
                    GovTalkMessage.Validate(ResponseEndPoint, CopyStr(ResponseEndPointXmlElement.InnerText(), 1, MaxStrLen(GovTalkMessage.ResponseEndPoint)));
                    GovTalkMessage.Validate(PollInterval, PollInterval);
                    GovTalkMessage.Modify();
                end;
            end;
            if GovTalkXMLHelper.FindElement(
                 SubmitResponseXmlElement, '//x:Qualifier', 'x', GovTalkNameSpaceTxt, ResponseQualifierXmlElement)
            then
                if (ResponseQualifierXmlElement.InnerText() = 'error') and
                   (FlushGateway = true)
                then begin
                    ReadGatewayErrors(VATReportHeader, SubmitResponseXmlElement);
                    SubmitGovTalkDeleteRequest(VATReportHeader, false);
                end else
                    if (ResponseQualifierXmlElement.InnerText() = 'response') and
                       (FlushGateway = true)
                    then begin
                        ReadSuccessResponse(VATReportHeader, SubmitResponseXmlElement);
                        SubmitGovTalkDeleteRequest(VATReportHeader, false);
                    end else
                        if ResponseQualifierXmlElement.InnerText() = 'acknowledgement' then begin
                            if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"EC Sales List" then begin
                                if not GovTalkXMLHelper.FindElement(
                                     SubmitResponseXmlElement, '//x:CorrelationID', 'x', GovTalkNameSpaceTxt, CorrelationXmlElement)
                                then
                                    Error('');
                                SetPartStatus(CorrelationXmlElement.InnerText(), VATReportHeader.Status::Submitted.AsInteger());
                                UpdateVATReportStatus(VATReportHeader);
                            end else begin
                                VATReportHeader.Validate(Status, VATReportHeader.Status::Submitted);
                                VATReportHeader.Modify(true);
                            end;
                            RegisterGovTalkPolling(VATReportHeader, XMlPartId);
                        end;
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InitGovTalkMessage(var GovTalkMessage: Record "GovTalk Message"; VATReportHeader: Record "VAT Report Header")
    begin
        GovTalkMessage.ReportConfigCode := VATReportHeader."VAT Report Config. Code".AsInteger();
        GovTalkMessage.ReportNo := VATReportHeader."No.";
        GovTalkMessage.PeriodID := GetPeriodID(VATReportHeader."End Date");
        GovTalkMessage.PeriodStart := VATReportHeader."Start Date";
        GovTalkMessage.PeriodEnd := VATReportHeader."End Date";
        GovTalkMessage."Polling Count" := 1000;
        if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"VAT Return" then
            GovTalkMessage."Message Class" := VATDeclarationMessageClassTxt
        else
            GovTalkMessage."Message Class" := ECSLDeclarationMessageClassTxt;
        GovTalkMessage.Insert();
    end;

    local procedure GetPeriodID(PeriodEnd: Date): Code[10]
    begin
        exit(Format(PeriodEnd, 0, '<Year4>-<Month,2>'));
    end;

    [Scope('OnPrem')]
    procedure FormatVATRegNo(CountryCode: Code[10]; VATRegNo: Text): Text
    begin
        if StrPos(VATRegNo, CountryCode) = 1 then
            exit(DelStr(VATRegNo, 1, StrLen(CountryCode)));
        exit(VATRegNo);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use SubmitECSLGovTalkRequest with an XmlElement parameter instead.', '30.0')]
    procedure SubmitECSLGovTalkRequest(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXMLNode: DotNet XmlNode; XMLPartID: Guid)
    var
        GovTalkMessageXmlElement: XmlElement;
        PreserveWhitespace: Boolean;
    begin
        ConvertFromDotNetXmlNode(GovTalkMessageXMLNode, GovTalkMessageXmlElement, PreserveWhitespace);
        GovTalkSetup.FindFirst();
        ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, PreserveWhitespace, 0, XMLPartID);
        ProcessGovTalkSubmission(VATReportHeader, GovTalkSetup.Endpoint, GovTalkMessageXmlElement, PreserveWhitespace, true, true, XMLPartID)
    end;
#endif

    [Scope('OnPrem')]
    procedure SubmitECSLGovTalkRequest(var VATReportHeader: Record "VAT Report Header"; GovTalkMessageXmlElement: XmlElement; XMLPartID: Guid)
    begin
        GovTalkSetup.FindFirst();
        ArchiveXMLMessage(VATReportHeader, GovTalkMessageXmlElement, 0, XMLPartID);
        ProcessGovTalkSubmission(VATReportHeader, GovTalkSetup.Endpoint, GovTalkMessageXmlElement, true, true, XMLPartID)
    end;

    local procedure PersistCorrelationID(var VATReportHeader: Record "VAT Report Header"; XmlPartID: Guid; CorrelationID: Text[250])
    var
        GovTalkMessageParts: Record "GovTalk Msg. Parts";
    begin
        if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"VAT Return" then begin
            VATReportHeader."Message Id" := CorrelationID;
            VATReportHeader.Modify();
            exit;
        end;

        if not GovTalkMessageParts.Get(XmlPartID) then
            Error(InvalidGovTalkMessagePartIDErr);

        GovTalkMessageParts.TestField("Report No.", VATReportHeader."No.");
        GovTalkMessageParts.TestField("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"EC Sales List");

        GovTalkMessageParts."Correlation Id" := CorrelationID;
        GovTalkMessageParts.Modify();
    end;

    local procedure SetPartStatus(CorrelationId: Text; NewStatus: Option)
    var
        GovTalkMessageParts: Record "GovTalk Msg. Parts";
    begin
        GovTalkMessageParts.SetFilter("Correlation Id", CorrelationId);
        if not GovTalkMessageParts.FindFirst() then
            Error('');
        GovTalkMessageParts.Validate(Status, NewStatus);
        GovTalkMessageParts.Modify(true);
    end;

    local procedure UpdateVATReportStatus(var VATReportHeader: Record "VAT Report Header")
    var
        GovTalkMessageParts: Record "GovTalk Msg. Parts";
        PartsCount: Integer;
    begin
        GovTalkMessageParts.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        GovTalkMessageParts.SetRange("Report No.", VATReportHeader."No.");
        PartsCount := GovTalkMessageParts.Count();

        GovTalkMessageParts.SetFilter(Status, '<>%1', GovTalkMessageParts.Status::Released);
        if not (GovTalkMessageParts.Count = PartsCount) then
            exit;

        if ConditionalUpdateVATRepStatus(
             VATReportHeader, GovTalkMessageParts.Status::Submitted, VATReportHeader.Status::Submitted.AsInteger(), PartsCount)
        then
            exit;
        if ConditionalUpdateVATRepStatus(
             VATReportHeader, GovTalkMessageParts.Status::Accepted, VATReportHeader.Status::Accepted.AsInteger(), PartsCount)
        then
            exit;
        if ConditionalUpdateVATRepStatus(
             VATReportHeader, GovTalkMessageParts.Status::Rejected, VATReportHeader.Status::Rejected.AsInteger(), PartsCount)
        then
            exit;

        GovTalkMessageParts.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        GovTalkMessageParts.SetRange("Report No.", VATReportHeader."No.");
        GovTalkMessageParts.SetRange(Status, VATReportHeader.Status::Accepted);
        if GovTalkMessageParts.Count > 0 then begin
            VATReportHeader.Validate(Status, VATReportHeader.Status::"Part. Accepted");
            VATReportHeader.Modify(true);
            exit;
        end;
    end;

    local procedure ConditionalUpdateVATRepStatus(var VATReportHeader: Record "VAT Report Header"; ExpectedPartStatus: Option; UpdateToStatus: Option; TotalPartCount: Integer): Boolean
    var
        GovTalkMessageParts: Record "GovTalk Msg. Parts";
    begin
        GovTalkMessageParts.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        GovTalkMessageParts.SetRange("Report No.", VATReportHeader."No.");
        GovTalkMessageParts.SetRange(Status, ExpectedPartStatus);

        if GovTalkMessageParts.Count = TotalPartCount then begin
            VATReportHeader.Validate(Status, UpdateToStatus);
            VATReportHeader.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Report", 'OnAfterInitPageControllers', '', false, false)]
    local procedure OnAfterInitPageControllers(VATReportHeader: Record "VAT Report Header"; var SubmitControllerStatus: Boolean; var MarkAsSubmitControllerStatus: Boolean)
    var
        GovSetup: Record "Gov Talk Setup";
    begin
        if not IsGovTalk(VATReportHeader) then
            exit;

        if GovSetup.IsConfigured() then begin
            SubmitControllerStatus := VATReportHeader.Status = VATReportHeader.Status::Released;
            MarkAsSubmitControllerStatus := false;
        end else begin
            MarkAsSubmitControllerStatus := VATReportHeader.Status = VATReportHeader.Status::Released;
            SubmitControllerStatus := false;
        end;
    end;

    local procedure IsGovTalk(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        if not VATReportsConfiguration.Get(VATReportHeader."VAT Report Config. Code", VATReportsConfiguration."VAT Report Version") then
            exit(false);

        exit(VATReportsConfiguration."Submission Codeunit ID" = CODEUNIT::"Submit VAT Declaration Req.")
    end;
}

