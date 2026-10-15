// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

/// <summary>
/// Where a Payables Agent v2 task came from. Holds only references; the source content is read live from its owning module.
/// </summary>
table 3329 "Payables Agent Task Source"
{
    Caption = 'Payables Agent Task Source';
    Access = Internal;
    DataClassification = SystemMetadata;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        #region Email
        // The Email Inbox row is the Email module's record of a received email: it holds sender, received time,
        // account, connector and the external (Outlook) message id, and points to the Email Message payload
        // (subject, body, headers) through "Message Id". Read all of these live; do not copy them here.
        field(10; "Email Inbox Id"; BigInteger)
        {
            Caption = 'Email Inbox Id';
            DataClassification = SystemMetadata;
            TableRelation = "Email Inbox".Id;
        }
        #endregion
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
