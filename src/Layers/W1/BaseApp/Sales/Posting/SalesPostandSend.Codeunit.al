// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.CRM.Outlook;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

codeunit 79 "Sales-Post and Send"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        if not Rec.Find() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        SalesHeader.Copy(Rec);
        Code();
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type';

    local procedure "Code"()
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        SalesPost: Codeunit "Sales-Post";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;

        OnBeforePostAndSend(SalesHeader, HideDialog, TempDocumentSendingProfile);
        if not HideDialog then
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice,
                  SalesHeader."Document Type"::"Credit Memo",
                  SalesHeader."Document Type"::Order:
                    if not ConfirmPostAndSend(SalesHeader, TempDocumentSendingProfile) then
                        exit;
                else
                    Error(NotSupportedDocumentTypeErr, SalesHeader."Document Type");
            end;
        OnCodeOnAfterConfirmPostAndSend(SalesHeader);

        TempDocumentSendingProfile.CheckElectronicSendingEnabled();
        ValidateElectronicFormats(TempDocumentSendingProfile);

        IsHandled := false;
        OnCodeOnBeforePostSalesHeader(SalesHeader, TempDocumentSendingProfile, HideDialog, IsHandled);
        if not IsHandled then
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                SalesHeader.Ship := false;
                SalesHeader.Invoice := false;
                SalesPostYesNo.PostAndSend(SalesHeader);
                if not (SalesHeader.Ship or SalesHeader.Invoice) then
                    exit;
            end else
                CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        OnAfterPostAndBeforeSend(SalesHeader);

        Commit();

        SalesPost.SendPostedDocumentRecord(SalesHeader, TempDocumentSendingProfile);

        OnAfterPostAndSend(SalesHeader);
    end;

    local procedure ConfirmPostAndSend(SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary) Result: Boolean
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostAndSend(SalesHeader, TempDocumentSendingProfile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Customer.Get(SalesHeader."Bill-to Customer No.");
        if OfficeMgt.IsAvailable() then
            DocumentSendingProfile.GetOfficeAddinDefault(TempDocumentSendingProfile, OfficeMgt.AttachAvailable())
        else begin
            IsHandled := false;
            OnConfirmPostAndSendOnBeforeGetDocumentSendingProfile(SalesHeader, Customer, DocumentSendingProfile, IsHandled);
            if not IsHandled then
                if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                    DocumentSendingProfile.GetDefault(DocumentSendingProfile);

            Commit();
            TempDocumentSendingProfile.Copy(DocumentSendingProfile);
            TempDocumentSendingProfile.SetDocumentUsage(SalesHeader);
            TempDocumentSendingProfile.Insert();

            IsHandled := false;
            OnBeforeConfirmAndSend(SalesHeader, TempDocumentSendingProfile, Result, IsHandled);
            if IsHandled then
                exit(Result);
            if PAGE.RunModal(PAGE::"Post and Send Confirmation", TempDocumentSendingProfile) <> ACTION::Yes then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ValidateElectronicFormats(DocumentSendingProfile: Record "Document Sending Profile")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateElectronicFormats(SalesHeader, DocumentSendingProfile, IsHandled);
        if IsHandled then
            exit;
        if (DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No) and
           (DocumentSendingProfile."E-Mail Attachment" <> DocumentSendingProfile."E-Mail Attachment"::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."E-Mail Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."E-Mail Format");
        end;

        if (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No) and
           (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."Disk Format");
        end;

        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."Electronic Format");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmAndSend(SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostAndSend(SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateElectronicFormats(SalesHeader: Record "Sales Header"; DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAndSend(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterConfirmPostAndSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostSalesHeader(var SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostAndSendOnBeforeGetDocumentSendingProfile(SalesHeader: Record "Sales Header"; Customer: Record Customer; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;
}

