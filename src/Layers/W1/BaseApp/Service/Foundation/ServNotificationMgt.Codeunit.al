// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Inventory.Availability;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 6460 "Serv. Notification Mgt."
{
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCreditMemoTxt: Label 'Service Credit Memo';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Management", 'OnGetDocumentTypeAndNumber', '', false, false)]
    local procedure OnGetDocumentTypeAndNumber(var RecRef: RecordRef; var DocumentType: Text; var DocumentNo: Text)
    var
        ServiceHeader: Record "Service Header";
        FieldRef: FieldRef;
    begin
        case RecRef.Number of
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader);
                    DocumentType := ServiceHeader.GetFullDocTypeTxt();

                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocumentType := ServiceInvoiceTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentType := ServiceCreditMemoTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;

        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterServiceLineInsertSetRecId(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterServiceLineRenameUpdateRecId(var Rec: Record "Service Line"; var xRec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterServiceLineDeleteRecall(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterServiceContractHeaderInsertSetRecId(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnServiceLineUpdateTypeRecallItemNotif(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnServiceLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforeServicePost(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostWithLines', '', false, false)]
    local procedure OnAfterServicePost(var PassedServiceHeader: Record "Service Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;
}
