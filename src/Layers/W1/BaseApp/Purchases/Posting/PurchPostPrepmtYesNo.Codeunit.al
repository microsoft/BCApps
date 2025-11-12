// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Utilities;

codeunit 445 "Purch.-Post Prepmt. (Yes/No)"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to post the prepayments for %1 %2?';
        Text001: Label 'Do you want to post a credit memo for the prepayments for %1 %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    procedure PostPrepmtInvoiceYN(var PurchHeader2: Record "Purchase Header"; Print: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchHeader.Copy(PurchHeader2);
        OnPostPrepmtInvoiceYNOnBeforeConfirmPostInvoice(PurchHeader);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text000, PurchHeader."Document Type", PurchHeader."No."), true) then
            exit;

        PostPrepmtDocument(PurchHeader, PurchHeader."Document Type"::Invoice);

        if Print then begin
            Commit();
            GetReport(PurchHeader, 0);
        end;

        OnAfterPostPrepmtInvoiceYN(PurchHeader);

        PurchHeader2 := PurchHeader;
    end;

    procedure PostPrepmtCrMemoYN(var PurchHeader2: Record "Purchase Header"; Print: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchHeader.Copy(PurchHeader2);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text001, PurchHeader."Document Type", PurchHeader."No."), true) then
            exit;

        PostPrepmtDocument(PurchHeader, PurchHeader."Document Type"::"Credit Memo");

        if Print then
            GetReport(PurchHeader, 1);

        Commit();
        OnAfterPostPrepmtCrMemoYN(PurchHeader);

        PurchHeader2 := PurchHeader;
    end;

    local procedure PostPrepmtDocument(var PurchHeader: Record "Purchase Header"; PrepmtDocumentType: Enum "Purchase Document Type")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        OnBeforePostPrepmtDocument(PurchHeader, PrepmtDocumentType.AsInteger());

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchHeader.RecordId, 0, '');
        PurchPostPrepayments.SetDocumentType(PrepmtDocumentType.AsInteger());
        Commit();
        if not PurchPostPrepayments.Run(PurchHeader) then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure Preview(var PurchHeader: Record "Purchase Header"; DocumentType: Option)
    var
        PurchPostPrepmtYesNo: Codeunit "Purch.-Post Prepmt. (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(PurchPostPrepmtYesNo);
        PurchPostPrepmtYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(PurchPostPrepmtYesNo, PurchHeader);
    end;

    procedure GetReport(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(PurchHeader, DocumentType, IsHandled);
        if IsHandled then
            exit;

        case DocumentType of
            DocumentType::Invoice:
                begin
                    PurchInvHeader."No." := PurchHeader."Last Prepayment No.";
                    PurchInvHeader.SetRecFilter();
                    PurchInvHeader.PrintRecords(false);
                end;
            DocumentType::"Credit Memo":
                begin
                    PurchCrMemoHeader."No." := PurchHeader."Last Prepmt. Cr. Memo No.";
                    PurchCrMemoHeader.SetRecFilter();
                    PurchCrMemoHeader.PrintRecords(false);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchaseHeader.Copy(RecVar);
        PurchaseHeader.Invoice := true;

        if PrepmtDocumentType in [PrepmtDocumentType::Invoice, PrepmtDocumentType::"Credit Memo"] then
            PurchasePostPrepayments.SetDocumentType(PrepmtDocumentType)
        else
            Error(UnsupportedDocTypeErr);

        PurchasePostPrepayments.SetPreviewMode(true);
        Result := PurchasePostPrepayments.Run(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var PurchaseHeader: Record "Purchase Header"; PrepmtDocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtInvoiceYNOnBeforeConfirmPostInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

