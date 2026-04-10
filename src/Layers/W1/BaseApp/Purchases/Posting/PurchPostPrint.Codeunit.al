// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;

codeunit 92 "Purch.-Post + Print"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
    begin
        OnBeforeOnRun(PurchHeader, Rec);
        PurchHeader.Copy(Rec);
        Code(PurchHeader);
        Rec := PurchHeader;
    end;

    local procedure "Code"(var PurchHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(PurchHeader, HideDialog, IsHandled, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(PurchHeader, DefaultOption) then
                exit;

        IsHandled := false;
        OnAfterConfirmPost(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if PurchSetup."Post & Print with Job Queue" then
            PurchasePostViaJobQueue.EnqueuePurchDoc(PurchHeader)
        else begin
            RunPurchPost(PurchHeader);
            GetReport(PurchHeader);
        end;

        OnAfterPost(PurchHeader);
    end;

    local procedure RunPurchPost(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunPurchPost(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        Codeunit.Run(Codeunit::"Purch.-Post", PurchHeader);
    end;

    local procedure ConfirmPost(var PurchHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostProcedure(PurchHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit;

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                if not SelectPostOrderOption(PurchHeader, DefaultOption) then
                    exit(false);
            PurchHeader."Document Type"::"Return Order":
                if not SelectPostReturnOrderOption(PurchHeader, DefaultOption) then
                    exit(false);
            else
                if not PostingSelectionManagement.ConfirmPostPurchaseDocument(PurchHeader, DefaultOption, true, false) then
                    exit(false);
        end;
        PurchHeader."Print Posted Documents" := true;
        exit(true);
    end;

    local procedure SelectPostOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectPostOrderOption(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostPurchaseDocument(PurchaseHeader, DefaultOption, false, false);
        exit(Result);
    end;

    local procedure SelectPostReturnOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectPostReturnOrderOption(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostPurchaseDocument(PurchaseHeader, DefaultOption, false, false);
        exit(Result);
    end;

    procedure GetReport(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                begin
                    if PurchHeader.Receive then
                        PrintReceive(PurchHeader);
                    if PurchHeader.Invoice then
                        PrintInvoice(PurchHeader);
                end;
            PurchHeader."Document Type"::Invoice:
                PrintInvoice(PurchHeader);
            PurchHeader."Document Type"::"Return Order":
                begin
                    if PurchHeader.Ship then
                        PrintShip(PurchHeader);
                    if PurchHeader.Invoice then
                        PrintCrMemo(PurchHeader);
                end;
            PurchHeader."Document Type"::"Credit Memo":
                PrintCrMemo(PurchHeader);
        end;
    end;

    procedure PrintReceive(PurchHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceive(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchRcptHeader."No." := PurchHeader."Last Receiving No.";
        PurchRcptHeader.SetRecFilter();
        PurchRcptHeader.PrintRecords(false);
    end;

    procedure PrintInvoice(PurchHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvoice(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Last Posting No." = '' then
            PurchInvHeader."No." := PurchHeader."No."
        else
            PurchInvHeader."No." := PurchHeader."Last Posting No.";
        PurchInvHeader.SetRecFilter();
        PurchInvHeader.PrintRecords(false);
    end;

    procedure PrintShip(PurchHeader: Record "Purchase Header")
    var
        ReturnShptHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShip(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        ReturnShptHeader."No." := PurchHeader."Last Return Shipment No.";
        ReturnShptHeader.SetRecFilter();
        ReturnShptHeader.PrintRecords(false);
    end;

    procedure PrintCrMemo(PurchHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintCrMemo(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Last Posting No." = '' then
            PurchCrMemoHdr."No." := PurchHeader."No."
        else
            PurchCrMemoHdr."No." := PurchHeader."Last Posting No.";
        PurchCrMemoHdr.SetRecFilter();
        PurchCrMemoHdr.PrintRecords(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var PurchaseHeader: Record "Purchase Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostProcedure(var PurchHeader: Record "Purchase Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeaderRec: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvoice(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCrMemo(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceive(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShip(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPurchPost(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectPostOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectPostReturnOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

