// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Address;

codeunit 5005397 "Format Adress Comfort"
{

    trigger OnRun()
    begin
    end;

    var
        AddrFormat: Codeunit "Format Address";

    procedure DelifRemindVend(var AddrArray: array[8] of Text[100]; var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
        AddrFormat.FormatAddr(
              AddrArray, DeliveryReminderHeader.Name, DeliveryReminderHeader."Name 2", DeliveryReminderHeader.Contact, DeliveryReminderHeader.Address, DeliveryReminderHeader."Address 2",
              DeliveryReminderHeader.City, DeliveryReminderHeader."Post Code", DeliveryReminderHeader.County, DeliveryReminderHeader."Country/Region Code");
    end;

    procedure IssDelivRemindVend(var AddrArray: array[8] of Text[100]; var IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        AddrFormat.FormatAddr(
              AddrArray, IssuedDeliveryReminderHeader.Name, IssuedDeliveryReminderHeader."Name 2", IssuedDeliveryReminderHeader.Contact, IssuedDeliveryReminderHeader.Address, IssuedDeliveryReminderHeader."Address 2",
              IssuedDeliveryReminderHeader.City, IssuedDeliveryReminderHeader."Post Code", IssuedDeliveryReminderHeader.County, IssuedDeliveryReminderHeader."Country/Region Code");
    end;
}

