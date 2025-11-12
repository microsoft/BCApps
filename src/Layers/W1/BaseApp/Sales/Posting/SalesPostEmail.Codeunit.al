// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 89 "Sales-Post + Email"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code();
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        HideMailDialog: Boolean;
#pragma warning disable AA0470
        PostAndSaveInvoiceQst: Label 'Do you want to post and save the %1?';
        NotSupportedDocumentTypeSavingErr: Label 'The %1 is not posted because saving document of type %1 is not supported.';
#pragma warning restore AA0470

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsHandled := false;
        OnBeforePostAndEMail(SalesHeader, HideDialog, IsHandled, HideMailDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice,
                  SalesHeader."Document Type"::"Credit Memo":
                    if not ConfirmPostAndDistribute(SalesHeader) then
                        exit;
                else
                    ErrorPostAndDistribute(SalesHeader);
            end;

        OnAfterConfirmPost(SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        OnAfterPostAndBeforeSend(SalesHeader);
        Commit();
        SendDocumentReport(SalesHeader);

        OnAfterPostAndSend(SalesHeader);
    end;

    local procedure SendDocumentReport(var SalesHeader: Record "Sales Header")
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                begin
                    OnSendDocumentReportOnBeforeSendInvoice(SalesInvHeader);
                    if SalesHeader."Last Posting No." = '' then
                        SalesInvHeader."No." := SalesHeader."No."
                    else
                        SalesInvHeader."No." := SalesHeader."Last Posting No.";
                    SalesInvHeader.Find();
                    SalesInvHeader.SetRecFilter();
                    SalesInvHeader.EmailRecords(not HideMailDialog);
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    if SalesHeader."Last Posting No." = '' then
                        SalesCrMemoHeader."No." := SalesHeader."No."
                    else
                        SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
                    SalesCrMemoHeader.Find();
                    SalesCrMemoHeader.SetRecFilter();
                    SalesCrMemoHeader.EmailRecords(not HideMailDialog);
                end
        end
    end;

    procedure InitializeFrom(NewHideMailDialog: Boolean)
    begin
        HideMailDialog := NewHideMailDialog;
    end;

    local procedure ConfirmPostAndDistribute(var SalesHeader: Record "Sales Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        exit(
          ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(PostAndSaveInvoiceQst, SalesHeader."Document Type"), true));
    end;

    local procedure ErrorPostAndDistribute(var SalesHeader: Record "Sales Header")
    var
        NotSupportedDocumentType: Text;
    begin
        NotSupportedDocumentType := NotSupportedDocumentTypeSavingErr;

        Error(NotSupportedDocumentType, SalesHeader."Document Type");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAndEMail(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var IsHandled: Boolean; var HideMailDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendDocumentReportOnBeforeSendInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

