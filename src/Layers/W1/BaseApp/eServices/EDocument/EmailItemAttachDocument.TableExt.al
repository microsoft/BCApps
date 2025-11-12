// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Email;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

tableextension 9900 "Email Item Attach Document" extends "Email Item"
{

    [Scope('OnPrem')]
    procedure AttachIncomingDocuments(SalesInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        InStr: InStream;
        IsPostedDocument: Boolean;
        CorrectAttachment: Boolean;
    begin
        if SalesInvoiceNo = '' then
            exit;
        IsPostedDocument := true;
        if not SalesInvoiceHeader.Get(SalesInvoiceNo) then begin
            SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Invoice);
            SalesHeader.SetRange("No.", SalesInvoiceNo);
            if not SalesHeader.FindFirst() then
                exit;
            if SalesHeader."Incoming Document Entry No." = 0 then
                exit;
            IsPostedDocument := false;
        end;

        if IsPostedDocument then begin
            IncomingDocumentAttachment.SetRange("Document No.", SalesInvoiceNo);
            IncomingDocumentAttachment.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        end else
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", SalesHeader."Incoming Document Entry No.");

        OnAttachIncomingDocumentsOnAfterSetFilter(IncomingDocumentAttachment);

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        if IncomingDocumentAttachment.FindSet() then
            repeat
                CorrectAttachment := true;
                if IsPostedDocument then begin
                    CorrectAttachment := false;
                    if IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
                        if (IncomingDocument."Document Type" = IncomingDocument."Document Type"::"Sales Invoice") and IncomingDocument.Posted then
                            CorrectAttachment := true;
                end;
                if CorrectAttachment then
                    if IncomingDocumentAttachment.Content.HasValue() then begin
                        IncomingDocumentAttachment.Content.CreateInStream(InStr);
                        // To ensure that Attachment file name has . followed by extension in the email item
                        Rec.AddAttachment(InStr, StrSubstNo('%1.%2', IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension"));
                    end;
            until IncomingDocumentAttachment.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAttachIncomingDocumentsOnAfterSetFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
    end;
}