// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.DataExchange;

permissionsetextension 8415 "IC D365 BASIC - EDIT" extends "D365 Basic - Edit"
{
    Permissions =
                  tabledata "Buffer IC Comment Line" = IMD,
                  tabledata "Buffer IC Document Dimension" = IMD,
                  tabledata "Buffer IC Inbox Jnl. Line" = IMD,
                  tabledata "Buffer IC Inbox Purchase Line" = IMD,
                  tabledata "Buffer IC Inbox Purch Header" = IMD,
                  tabledata "Buffer IC Inbox Sales Header" = IMD,
                  tabledata "Buffer IC Inbox Sales Line" = IMD,
                  tabledata "Buffer IC Inbox Transaction" = IMD,
                  tabledata "Buffer IC InOut Jnl. Line Dim." = IMD,
                  tabledata "IC API Log" = IMD,
                  tabledata "IC Incoming Notification" = IMD,
                  tabledata "IC Outgoing Notification" = IMD;
}
