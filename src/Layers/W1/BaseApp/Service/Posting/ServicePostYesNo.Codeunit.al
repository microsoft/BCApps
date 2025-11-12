// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.NoSeries;
using Microsoft.Service.Document;
using Microsoft.Utilities;

codeunit 5981 "Service-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Service Line";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        Code(Rec, GlobalServiceHeader);
    end;

    var
        GlobalServiceHeader: Record "Service Header";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        PreviewMode: Boolean;

    local procedure "Code"(var PassedServLine: Record "Service Line"; var PassedServiceHeader: Record "Service Header")
    var
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        if not PassedServiceHeader.Find() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmServPost(PassedServiceHeader, HideDialog, Ship, Consume, Invoice, IsHandled, PreviewMode, PassedServLine);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(PassedServiceHeader, Ship, Consume, Invoice, DefaultOption) then
                exit;

        OnAfterConfirmPost(PassedServiceHeader, Ship, Consume, Invoice);

        ServicePost.SetPreviewMode(PreviewMode);
        ServicePost.PostWithLines(PassedServiceHeader, PassedServLine, Ship, Consume, Invoice);
        GlobalServiceHeader.Copy(PassedServiceHeader);


        OnAfterPost(PassedServiceHeader);
    end;

    procedure PostDocument(var ServiceHeaderSource: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
    begin
        OnBeforePostDocument(ServiceHeaderSource, TempServiceLine);
        PostDocumentWithLines(ServiceHeaderSource, TempServiceLine);
    end;

    procedure PostDocumentWithLines(var ServiceHeaderSource: Record "Service Header"; var PassedServLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        OnBeforePostDocumentWithLines(ServiceHeaderSource, PassedServLine);
        ServiceHeader.Copy(ServiceHeaderSource);
        Code(PassedServLine, ServiceHeader);
        ServiceHeaderSource := ServiceHeader;
    end;

    procedure PreviewDocument(var ServHeader: Record "Service Header")
    var
        TempServLine: Record "Service Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePreviewDocument(ServHeader, IsHandled);
        if IsHandled then
            exit;

        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetGlobalServiceHeader(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, TempServLine);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var ServiceHeaderToPreview: Record "Service Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Service Header");
        RecordRefToPreview.Copy(ServiceHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    procedure PreviewDocumentWithLines(var ServHeader: Record "Service Header"; var PassedServLine: Record "Service Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetGlobalServiceHeader(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, PassedServLine);
    end;

    procedure SetGlobalServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        GlobalServiceHeader.Copy(ServiceHeader);
    end;

    procedure GetGlobalServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Copy(GlobalServiceHeader);
    end;

    local procedure ConfirmPost(var ServiceHeader: Record "Service Header"; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; DefaultOption: Integer) Result: Boolean
    var
        ServPostingSelectionMgt: Codeunit "Serv. Posting Selection Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPost(ServiceHeader, Ship, Consume, Invoice, DefaultOption, PreviewMode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ServPostingSelectionMgt.ConfirmPostServiceDocument(ServiceHeader, Ship, Consume, Invoice, DefaultOption, false, false, PreviewMode);
        if not Result then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var ServiceHeader: Record "Service Header"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PassedServiceHeader: Record "Service Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        ServicePostYesNo := Subscriber;
        PreviewMode := true;
        Result := ServicePostYesNo.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmServPost(var ServiceHeader: Record "Service Header"; var HideDialog: Boolean; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var IsHandled: Boolean; PreviewMode: Boolean; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDocumentWithLines(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreviewDocument(var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var ServiceHeader: Record "Service Header"; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var DefaultOption: Integer; PreviewMode: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

