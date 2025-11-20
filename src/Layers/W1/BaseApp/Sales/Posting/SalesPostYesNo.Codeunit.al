// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 81 "Sales-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        OnBeforeOnRun(Rec);

        if not Rec.Find() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        SalesHeader.Copy(Rec);
        Code(SalesHeader, false);
        Rec := SalesHeader;
    end;

    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";

    procedure PostAndSend(var SalesHeader: Record "Sales Header")
    var
        SalesHeaderToPost: Record "Sales Header";
    begin
        SalesHeaderToPost.Copy(SalesHeader);
        Code(SalesHeaderToPost, true);
        SalesHeader := SalesHeaderToPost;
    end;

    local procedure "Code"(var SalesHeader: Record "Sales Header"; PostAndSend: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmSalesPost(SalesHeader, HideDialog, IsHandled, DefaultOption, PostAndSend);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(SalesHeader, DefaultOption) then
                exit;

        IsHandled := false;
        OnAfterConfirmPost(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if SalesSetup."Post with Job Queue" and not PostAndSend then
            SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader)
        else
            RunSalesPost(SalesHeader);

        OnAfterPost(SalesHeader, PostAndSend);
    end;

    local procedure RunSalesPost(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
        IsHandled: Boolean;
        SuppressCommit: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSalesPost(SalesHeader, IsHandled, SuppressCommit);
        if IsHandled then
            exit;

        SalesPost.SetSuppressCommit(SuppressCommit);
        SalesPost.Run(SalesHeader);
    end;

    local procedure ConfirmPost(var SalesHeader: Record "Sales Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPost(SalesHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        OnConfirmPostOnBeforeSetSelection(SalesHeader);
        Result := PostingSelectionManagement.ConfirmPostSalesDocument(SalesHeader, DefaultOption, false, false);
        if not Result then
            exit(false);

        SalesHeader."Print Posted Documents" := false;
        exit(true);
    end;

    procedure Preview(var SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(SalesPostYesNo);
        GenJnlPostPreview.Preview(SalesPostYesNo, SalesHeader);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var SalesHeaderToPreview: Record "Sales Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Sales Header");
        RecordRefToPreview.Copy(SalesHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var SalesHeader: Record "Sales Header"; PostAndSend: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunPreview(Result, RecVar, IsHandled);
        if IsHandled then
            exit;
        SalesHeader.Copy(RecVar);
        SalesHeader.Receive := SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order";
        SalesHeader.Ship := SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"];
        SalesHeader.Invoice := true;

        OnRunPreviewOnAfterSetPostingFlags(SalesHeader);

        SalesPost.SetPreviewMode(true);
        Result := SalesPost.Run(SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreviewOnAfterSetPostingFlags(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var SalesHeader: Record "Sales Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmSalesPost(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer; var PostAndSend: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSalesPost(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostOnBeforeSetSelection(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPreview(var Result: Boolean; RecVar: Variant; var IsHandled: Boolean)
    begin
    end;
}

