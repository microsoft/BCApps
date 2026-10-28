// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Email;
using System.Threading;

permissionset 3304 "Payables Ag. - Adm."
{
    Caption = 'Payables Agent - Administration', Comment = 'Payables Agent is a term, and should not be translated.';
    Assignable = true;
    IncludedPermissionSets =
        "Payables Ag. - Read",
        "Email - Admin",
        M365EDocConnEdit;
    Permissions =
        tabledata "Payables Agent Setup" = IM,
        tabledata "PA Known Sender" = IMD,
        // Email Inbox duplicate cleanup mitigation
        tabledata "PA Email Cleanup Setup" = RIMD,
        tabledata "Email Inbox" = Rd, // Read to detect duplicates, Delete to remove the redundant copies (cascades into message, attachments and media)
        tabledata "Job Queue Entry" = RIMD; // Schedule, inspect and cancel the background cleanup job
}