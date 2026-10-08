// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Purchases.Document;

permissionsetextension 5005271 "DR LOCAL READ" extends "LOCAL READ"
{
    Permissions = tabledata "Delivery Reminder Comment Line" = R,
                  tabledata "Delivery Reminder Header" = R,
                  tabledata "Delivery Reminder Ledger Entry" = R,
                  tabledata "Delivery Reminder Level" = R,
                  tabledata "Delivery Reminder Line" = R,
                  tabledata "Delivery Reminder Term" = R,
                  tabledata "Delivery Reminder Text" = R,
                  tabledata "Issued Deliv. Reminder Header" = R,
                  tabledata "Issued Deliv. Reminder Line" = R;
}
