// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Utilities;

codeunit 91 "Purch.-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        OnBeforeOnRun(Rec);

        if not Rec.Find() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        PurchaseHeader.Copy(Rec);
        Code(PurchaseHeader);
        Rec := PurchaseHeader;
    end;

    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";

    local procedure "Code"(var PurchaseHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchPostViaJobQueue: Codeunit "Purchase Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(PurchaseHeader, HideDialog, IsHandled, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(PurchaseHeader, DefaultOption) then
                exit;

        IsHandled := false;
        OnAfterConfirmPost(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if PurchSetup."Post with Job Queue" then
            PurchPostViaJobQueue.EnqueuePurchDoc(PurchaseHeader)
        else begin
            OnBeforeRunPurchPost(PurchaseHeader);
            CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        end;

        OnAfterPost(PurchaseHeader);
    end;

    local procedure ConfirmPost(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostProcedure(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                if not SelectPostOrderOption(PurchaseHeader, DefaultOption) then
                    exit(false);
            PurchaseHeader."Document Type"::"Return Order":
                if not SelectPostReturnOrderOption(PurchaseHeader, DefaultOption) then
                    exit(false);
            else
                if not PostingSelectionManagement.ConfirmPostPurchaseDocument(PurchaseHeader, DefaultOption, false, false) then
                    exit(false);
        end;
        PurchaseHeader."Print Posted Documents" := false;
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

    procedure Preview(var PurchaseHeader: Record "Purchase Header")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        BindSubscription(PurchPostYesNo);
        GenJnlPostPreview.Preview(PurchPostYesNo, PurchaseHeader);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var PurchaseHeaderToPreview: Record "Purchase Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Purchase Header");
        RecordRefToPreview.Copy(PurchaseHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunPreview(Result, RecVar, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader.Copy(RecVar);
        PurchaseHeader.Ship := PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order";
        PurchaseHeader.Receive := PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Invoice := true;
        OnRunPreviewOnBeforePurchPostRun(PurchaseHeader);
        PurchPost.SetPreviewMode(true);
        Result := PurchPost.Run(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var PurchaseHeader: Record "Purchase Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostProcedure(var PurchaseHeader: Record "Purchase Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPurchPost(var PurchaseHeader: Record "Purchase Header")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPreview(var Result: Boolean; RecVar: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreviewOnBeforePurchPostRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

