// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;

codeunit 7323 "Whse.-Act.-Post (Yes/No)"
{
    TableNo = "Warehouse Activity Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(IsPreview);
        WhseActivLine.Copy(Rec);
        Code();
        Rec.Copy(WhseActivLine);

        OnAfterOnRun(Rec);
    end;

    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        Selection: Integer;
        PrintDoc: Boolean;
        DefaultOption: Integer;
        IsPreview: Boolean;
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        HideDialog := false;
        DefaultOption := 2;
        OnBeforeConfirmPost(WhseActivLine, HideDialog, Selection, DefaultOption, IsHandled, PrintDoc);
        if IsHandled then
            exit;

        if (DefaultOption < 1) or (DefaultOption > 2) then
            DefaultOption := 2;

        if not HideDialog then
            if not IsPreview then
                case WhseActivLine."Activity Type" of
                    WhseActivLine."Activity Type"::"Invt. Put-away":
                        if not SelectForPutAway() then
                            exit;
                    else
                        if not SelectForOtherTypes() then
                            exit;
                end;

        SetParamsAndRunWhseActivityPost(HideDialog);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        IsPreview := NewPreviewMode;
    end;

    procedure Preview(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WhseActPostYesNo: Codeunit "Whse.-Act.-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(WhseActPostYesNo);
        GenJnlPostPreview.Preview(WhseActPostYesNo, WarehouseActivityLine);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var WarehouseActivityHeaderToPreview: Record "Warehouse Activity Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Warehouse Activity Header");
        RecordRefToPreview.Copy(WarehouseActivityHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActPostYesNo: Codeunit "Whse.-Act.-Post (Yes/No)";
    begin
        WarehouseActivityLine.Copy(RecVar);
        WhseActPostYesNo.SetPreviewMode(true);
        Result := WhseActPostYesNo.Run(WarehouseActivityLine);
    end;

    local procedure SetParamsAndRunWhseActivityPost(HideDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetParamsAndRunWhseActivityPost(WhseActivLine, HideDialog, PrintDoc, Selection, IsHandled);
        if IsHandled then
            exit;

        WhseActivityPost.SetInvoiceSourceDoc(Selection = 2);
        WhseActivityPost.PrintDocument(PrintDoc);
        WhseActivityPost.SetSuppressCommit(SuppressCommit);
        WhseActivityPost.ShowHideDialog(HideDialog);
        WhseActivityPost.SetIsPreview(IsPreview);
        WhseActivityPost.Run(WhseActivLine);
        Clear(WhseActivityPost);

        OnAfterSetParamsAndRunWhseActivityPost(WhseActivLine, HideDialog, PrintDoc, Selection);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetParamsAndRunWhseActivityPost(var WarehouseActivityLine: Record "Warehouse Activity Line"; HideDialog: Boolean; PrintDoc: Boolean; Selection: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure PrintDocument(SetPrint: Boolean)
    begin
        PrintDoc := SetPrint;
    end;

    local procedure SelectForPutAway() Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectForPutAway(WhseActivLine, Result, IsHandled, Selection);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostWarehouseActivity(WhseActivLine, Selection, DefaultOption, false);

        exit(Result);
    end;

    local procedure SelectForOtherTypes() Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectForOtherTypes(WhseActivLine, Result, IsHandled, Selection);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostWarehouseActivity(WhseActivLine, Selection, DefaultOption, false);

        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var WhseActivLine: Record "Warehouse Activity Line"; var HideDialog: Boolean; var Selection: Integer; var DefaultOption: Integer; var IsHandled: Boolean; var PrintDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectForPutAway(var WhseActivLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectForOtherTypes(var WhseActivLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetParamsAndRunWhseActivityPost(var WarehouseActivityLine: Record "Warehouse Activity Line"; HideDialog: Boolean; PrintDoc: Boolean; Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

