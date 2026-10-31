// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Entity;
using System.Agents;
using System.Diagnostics;
using System.Email;
using System.Security.AccessControl;
using System.Utilities;

permissionset 3346 "Payables Agent - Run"
{
    Caption = 'Payables Agent - Run (v2)', Comment = 'Payables Agent is a term, and should not be translated.';
    Assignable = true;
    IncludedPermissionSets =
        // Basic permissions to access the system
        "D365 Basic - Read",
        "D365 READ",
        "LOCAL",
        // Permissions to create purchase documents and vendors
        "D365 PURCH DOC, EDIT",
        "D365 VENDOR, EDIT";

    Permissions =
        // Missing permissions to create purchase documents
        tabledata "Error Message" = IMD,
        tabledata "Purch. Inv. Entity Aggregate" = IMD,
        tabledata "Document Attachment" = IMD,
        tabledata "Deferral Header" = IMD,
        tabledata "Deferral Line" = IMD,
        tabledata "Dimension Set Entry" = im,
        tabledata "Dimension Set Tree Node" = im,
        // Missing permissions for vendor creation
        tabledata "VAT Registration Log" = i, // Validating VAT Registration No. on the vendor card writes an audit entry to the VAT Registration Log
                                              // Change Log
        tabledata "Change Log Entry" = i, // Needed when the customer has Change Log or Monitor Sensitive Fields enabled for tables the agent writes to (e.g. User Environment Login on login)
                                          // Payables Agent tasks: "Payables Agent Task" carries inherent permissions.
        tabledata "Email Inbox" = R, // Read the source email (sender, subject, body) through the Email module
                                     // Other
        tabledata "Agent Task Message" = R, // Needed to resolve the task the current session works on
        tabledata "Agent Task" = RM, // Needed to read the agent task status and update the agent task title
        tabledata "PA Known Sender" = RI; // Read for dedup check + insert on agent-driven processing steps. Modify/Delete reserved for admins.

    ExcludedPermissionSets =
        // Permissions that are not needed for the agent to perform their tasks
        "Payables Ag. - Excl.";
}
