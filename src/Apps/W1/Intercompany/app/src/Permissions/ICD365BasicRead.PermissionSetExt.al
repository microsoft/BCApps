// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Setup;

permissionsetextension 8402 "IC D365 BASIC - READ" extends "D365 Basic - Read"
{
    Permissions =
                  tabledata "Buffer IC Comment Line" = R,
                  tabledata "Buffer IC Document Dimension" = R,
                  tabledata "Buffer IC Inbox Jnl. Line" = R,
                  tabledata "Buffer IC Inbox Purchase Line" = R,
                  tabledata "Buffer IC Inbox Purch Header" = R,
                  tabledata "Buffer IC Inbox Sales Header" = R,
                  tabledata "Buffer IC Inbox Sales Line" = R,
                  tabledata "Buffer IC Inbox Transaction" = R,
                  tabledata "Buffer IC InOut Jnl. Line Dim." = R,
                  tabledata "IC API Log" = R,
                  tabledata "IC Incoming Notification" = R,
                  tabledata "IC Outgoing Notification" = R,
                  tabledata "IC Setup" = R;
}
