// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10987 "FR E-Invoice Lifecycle Import"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Lifecycle Resp." = ri;

    procedure ImportResponse(var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        ResponseType: Enum "E-Doc. Response Type";
        InvoiceID: Text;
        ResponseID: Text;
        ReasonCode: Text;
        ReasonDescription: Text;
        MessageEntryNo: Integer;
    begin
        ParseResponse(TempBlob, ResponseID, InvoiceID, ResponseType, ReasonCode, ReasonDescription);
        FindOutgoingEDocument(InvoiceID, EDocument);

        FREInvoiceLifecycleResponse.SetRange("Response ID", ResponseID);
        if not FREInvoiceLifecycleResponse.IsEmpty() then
            Error(DuplicateResponseErr, ResponseID);

        MessageEntryNo := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", "E-Document Direction"::Incoming, ResponseType, TempBlob);

        FREInvoiceLifecycleResponse.Init();
        FREInvoiceLifecycleResponse."Response ID" := CopyStr(ResponseID, 1, MaxStrLen(FREInvoiceLifecycleResponse."Response ID"));
        FREInvoiceLifecycleResponse."Invoice ID" := CopyStr(InvoiceID, 1, MaxStrLen(FREInvoiceLifecycleResponse."Invoice ID"));
        FREInvoiceLifecycleResponse."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceLifecycleResponse."E-Document Message Entry No." := MessageEntryNo;
        FREInvoiceLifecycleResponse."Response Type" := ResponseType;
        FREInvoiceLifecycleResponse."Reason Code" := CopyStr(ReasonCode, 1, MaxStrLen(FREInvoiceLifecycleResponse."Reason Code"));
        FREInvoiceLifecycleResponse."Reason Description" := CopyStr(ReasonDescription, 1, MaxStrLen(FREInvoiceLifecycleResponse."Reason Description"));
        FREInvoiceLifecycleResponse."Received At" := CurrentDateTime();
        FREInvoiceLifecycleResponse.Insert();
        exit(FREInvoiceLifecycleResponse."Entry No.");
    end;

    internal procedure ParseResponse(TempBlob: Codeunit "Temp Blob"; var ResponseID: Text; var InvoiceID: Text; var ResponseType: Enum "E-Doc. Response Type"; var ReasonCode: Text; var ReasonDescription: Text)
    var
        XmlDoc: XmlDocument;
        InStream: InStream;
        StatusText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStream, XmlDoc) then
            Error(InvalidXmlErr);

        ResponseID := GetRequiredNodeText(XmlDoc, '//*[local-name()="ExchangedDocument"]/*[local-name()="ID"]', ResponseIDErr);
        InvoiceID := GetRequiredNodeText(XmlDoc, '//*[local-name()="InvoiceID" or local-name()="IssuerAssignedID"]', InvoiceIDErr);
        StatusText := GetRequiredNodeText(XmlDoc, '//*[local-name()="ProcessCondition" or local-name()="Status"]', StatusErr);
        ResponseType := MapResponseType(StatusText);
        ReasonCode := GetOptionalNodeText(XmlDoc, '//*[local-name()="ReasonCode"]');
        ReasonDescription := GetOptionalNodeText(XmlDoc, '//*[local-name()="Reason" or local-name()="ReasonDescription"]');
    end;

    local procedure FindOutgoingEDocument(InvoiceID: Text; var EDocument: Record "E-Document")
    begin
        EDocument.SetRange("Document No.", InvoiceID);
        EDocument.SetRange(Direction, EDocument.Direction::Outgoing);
        if not EDocument.FindFirst() then
            Error(InvoiceNotFoundErr, InvoiceID);
        if EDocument.Next() <> 0 then
            Error(AmbiguousInvoiceErr, InvoiceID);
    end;

    local procedure MapResponseType(StatusText: Text): Enum "E-Doc. Response Type"
    var
        ResponseType: Enum "E-Doc. Response Type";
    begin
        case UpperCase(StatusText) of
            'SUBMITTED':
                exit(ResponseType::Submitted);
            'ACCEPTED':
                exit(ResponseType::Accepted);
            'REJECTED':
                exit(ResponseType::Rejected);
            else
                Error(UnsupportedStatusErr, StatusText);
        end;
    end;

    local procedure GetRequiredNodeText(XmlDoc: XmlDocument; XPath: Text; ErrorText: Text): Text
    var
        XmlNode: XmlNode;
    begin
        if not XmlDoc.SelectSingleNode(XPath, XmlNode) then
            Error(ErrorText);
        exit(XmlNode.AsXmlElement().InnerText());
    end;

    local procedure GetOptionalNodeText(XmlDoc: XmlDocument; XPath: Text): Text
    var
        XmlNode: XmlNode;
    begin
        if XmlDoc.SelectSingleNode(XPath, XmlNode) then
            exit(XmlNode.AsXmlElement().InnerText());
    end;

    var
        InvalidXmlErr: Label 'The French invoice lifecycle response is not valid XML.';
        ResponseIDErr: Label 'The French invoice lifecycle response does not contain a response ID.';
        InvoiceIDErr: Label 'The French invoice lifecycle response does not contain an InvoiceID.';
        StatusErr: Label 'The French invoice lifecycle response does not contain a status.';
        UnsupportedStatusErr: Label 'French invoice lifecycle status %1 is not supported.', Comment = '%1 = lifecycle status';
        InvoiceNotFoundErr: Label 'No outgoing E-Document was found for InvoiceID %1.', Comment = '%1 = invoice identifier';
        AmbiguousInvoiceErr: Label 'More than one outgoing E-Document was found for InvoiceID %1.', Comment = '%1 = invoice identifier';
        DuplicateResponseErr: Label 'French invoice lifecycle response %1 has already been imported.', Comment = '%1 = response identifier';
}