// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10987 "FR E-Invoice Message API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "FR E-Invoice Message" = ri;

    /// <summary>
    /// Receives, validates, and stores a French invoice lifecycle message from an E-Document service.
    /// This is the supported production entry point for connector implementations and integration adapter apps.
    /// The connector supplies its external document and message identifiers; this app owns French parsing and history.
    /// </summary>
    /// <param name="ServiceCode">The E-Document service that received the message.</param>
    /// <param name="ExternalDocumentID">The service-specific identifier registered for the parent E-Document.</param>
    /// <param name="ExternalMessageID">The service-specific message identifier used for deduplication.</param>
    /// <param name="ReceivedAt">The source timestamp, or zero to use the current date and time.</param>
    /// <param name="TempBlob">The original lifecycle XML payload.</param>
    /// <returns>The entry number of the normalized French invoice message.</returns>
    procedure ReceiveMessage(ServiceCode: Code[20]; ExternalDocumentID: Text[250]; ExternalMessageID: Text[250]; ReceivedAt: DateTime; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageType: Enum "FR E-Invoice Message Type";
        ResponseType: Enum "E-Doc. Response Type";
        InvoiceID: Text;
        ReasonCode: Text;
        ReasonDescription: Text;
        MessageEntryNo: Integer;
    begin
        ParseMessage(TempBlob, InvoiceID, MessageType, ReasonCode, ReasonDescription);
        ResponseType := GetResponseType(MessageType);
        MessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            ServiceCode, ExternalDocumentID, ExternalMessageID, "E-Document Message Type"::"FR Invoice Lifecycle",
            ResponseType, ReceivedAt, TempBlob);

        FREInvoiceMessage.SetRange("E-Document Message Entry No.", MessageEntryNo);
        if FREInvoiceMessage.FindFirst() then
            exit(FREInvoiceMessage."Entry No.");

        EDocumentMessageAPI.GetMessageEDocument(MessageEntryNo, EDocument);
        EDocument.TestField(Direction, EDocument.Direction::Outgoing);
        if EDocument."Document No." <> InvoiceID then
            Error(InvoiceMismatchErr, InvoiceID, EDocument."Document No.");
        ValidateLifecycleTransition(EDocument."Entry No", MessageType);

        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := MessageType;
        FREInvoiceMessage."Source Occurrence ID" := CreateGuid();
        FREInvoiceMessage."Reason Code" := CopyStr(ReasonCode, 1, MaxStrLen(FREInvoiceMessage."Reason Code"));
        FREInvoiceMessage."Reason Description" := CopyStr(ReasonDescription, 1, MaxStrLen(FREInvoiceMessage."Reason Description"));
        FREInvoiceMessage."E-Document Message Entry No." := MessageEntryNo;
        FREInvoiceMessage."External Message ID" := ExternalMessageID;
        if ReceivedAt = 0DT then
            FREInvoiceMessage."Received At" := CurrentDateTime()
        else
            FREInvoiceMessage."Received At" := ReceivedAt;
        FREInvoiceMessage."Event Date" := DT2Date(FREInvoiceMessage."Received At");
        FREInvoiceMessage."Created At" := CurrentDateTime();
        FREInvoiceMessage.Insert();
        exit(FREInvoiceMessage."Entry No.");
    end;

    local procedure ValidateLifecycleTransition(EDocumentEntryNo: Integer; NewMessageType: Enum "FR E-Invoice Message Type")
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
        PreviousMessageType: Enum "FR E-Invoice Message Type";
        HasPreviousMessage: Boolean;
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocumentEntryNo);
        FREInvoiceMessage.SetFilter(Type, '%1|%2|%3|%4', FREInvoiceMessage.Type::Submitted, FREInvoiceMessage.Type::Accepted,
            FREInvoiceMessage.Type::Refused, FREInvoiceMessage.Type::"Technical Rejected");
        if FREInvoiceMessage.FindLast() then begin
            HasPreviousMessage := true;
            PreviousMessageType := FREInvoiceMessage.Type;
        end;

        case NewMessageType of
            NewMessageType::Submitted:
                if HasPreviousMessage then
                    Error(InvalidLifecycleTransitionErr, Format(PreviousMessageType), Format(NewMessageType));
            NewMessageType::Accepted,
            NewMessageType::Refused,
            NewMessageType::"Technical Rejected":
                if (not HasPreviousMessage) or (PreviousMessageType <> PreviousMessageType::Submitted) then
                    Error(InvalidLifecycleTransitionErr, GetPreviousMessageTypeText(HasPreviousMessage, PreviousMessageType), Format(NewMessageType));
        end;
    end;

    local procedure GetPreviousMessageTypeText(HasPreviousMessage: Boolean; PreviousMessageType: Enum "FR E-Invoice Message Type"): Text
    begin
        if HasPreviousMessage then
            exit(Format(PreviousMessageType));
        exit(NoPreviousStatusTok);
    end;

    local procedure ParseMessage(TempBlob: Codeunit "Temp Blob"; var InvoiceID: Text; var MessageType: Enum "FR E-Invoice Message Type"; var ReasonCode: Text; var ReasonDescription: Text)
    var
        XmlDoc: XmlDocument;
        InStream: InStream;
        StatusText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStream, XmlDoc) then
            Error(InvalidXmlErr);

        InvoiceID := GetRequiredNodeText(XmlDoc, '//*[local-name()="InvoiceID" or local-name()="IssuerAssignedID"]', InvoiceIDErr);
        StatusText := GetRequiredNodeText(XmlDoc, '//*[local-name()="ProcessConditionCode" or local-name()="ProcessCondition" or local-name()="Status"]', StatusErr);
        MessageType := MapMessageType(StatusText);
        ReasonCode := GetOptionalNodeText(XmlDoc, '//*[local-name()="ReasonCode"]');
        ReasonDescription := GetOptionalNodeText(XmlDoc, '//*[local-name()="Reason" or local-name()="ReasonDescription"]');

        if MessageType = MessageType::"Technical Rejected" then begin
            if ReasonCode = '' then
                Error(RejectedReasonCodeErr);
            if ReasonDescription = '' then
                Error(RejectedReasonDescriptionErr);
        end;
    end;

    local procedure MapMessageType(StatusText: Text): Enum "FR E-Invoice Message Type"
    var
        MessageType: Enum "FR E-Invoice Message Type";
    begin
        case UpperCase(StatusText.Trim()) of
            '200', 'SUBMITTED', 'DÉPOSÉE', 'DEPOSEE':
                exit(MessageType::Submitted);
            '205', 'ACCEPTED', 'ACCEPTÉE', 'ACCEPTEE', 'APPROUVÉE', 'APPROUVEE':
                exit(MessageType::Accepted);
            '213', 'REJECTED', 'TECHNICAL REJECTED', 'REJETÉE', 'REJETEE':
                exit(MessageType::"Technical Rejected");
            '210', 'REFUSED', 'REFUSÉE', 'REFUSEE':
                exit(MessageType::Refused);
            else
                Error(UnsupportedStatusErr, StatusText);
        end;
    end;

    local procedure GetResponseType(MessageType: Enum "FR E-Invoice Message Type"): Enum "E-Doc. Response Type"
    begin
        case MessageType of
            MessageType::Submitted:
                exit("E-Doc. Response Type"::Submitted);
            MessageType::Accepted:
                exit("E-Doc. Response Type"::Accepted);
            MessageType::"Technical Rejected":
                exit("E-Doc. Response Type"::Rejected);
            MessageType::Refused:
                exit("E-Doc. Response Type"::Refused);
            else
                Error(UnsupportedStatusErr, Format(MessageType));
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
        InvalidXmlErr: Label 'The French invoice lifecycle message is not valid XML.';
        InvoiceIDErr: Label 'The French invoice lifecycle message does not contain an invoice ID.';
        StatusErr: Label 'The French invoice lifecycle message does not contain a status.';
        UnsupportedStatusErr: Label 'French invoice lifecycle status %1 is not supported.', Comment = '%1 = lifecycle status';
        InvoiceMismatchErr: Label 'The lifecycle message invoice ID %1 does not match E-Document invoice %2.', Comment = '%1 = message invoice identifier, %2 = E-Document invoice identifier';
        InvalidLifecycleTransitionErr: Label 'French invoice lifecycle status cannot change from %1 to %2.', Comment = '%1 = previous lifecycle status, %2 = new lifecycle status';
        NoPreviousStatusTok: Label 'no previous status';
        RejectedReasonCodeErr: Label 'A technical rejection reason code is required.';
        RejectedReasonDescriptionErr: Label 'A technical rejection reason description is required.';
}