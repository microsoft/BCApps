// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Utilities;
using System.Privacy;

codeunit 5005274 "DR Data Class. Eval. Data"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure ClassifyDeliveryReminderTables()
    var
        DummyDeliveryReminderHeader: Record "Delivery Reminder Header";
        DummyIssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        DummyDeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Header");
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Header", DummyDeliveryReminderHeader.FieldNo("User ID"));

        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Line");

        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Deliv. Reminder Header");
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Issued Deliv. Reminder Header", DummyIssuedDelivReminderHeader.FieldNo("User ID"));

        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Deliv. Reminder Line");

        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Ledger Entry");
        DataClassificationMgt.SetFieldToPersonal(DATABASE::"Delivery Reminder Ledger Entry", DummyDeliveryReminderLedgerEntry.FieldNo("User ID"));

        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Comment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Term");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Level");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Delivery Reminder Text");
    end;
}
