// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

/// <summary>
/// Source codes are used to categorize the source of a transaction.
/// </summary>
/// <remarks>
/// https://learn.microsoft.com/en-us/dynamics365/business-central/finance-setup-trail-codes
/// This page is used to set up source codes that are used to categorize the source of a transaction. 
/// Each feature that introduces a new transaction source should add a field to set up a default source code.
/// </remarks>
table 242 "Source Code Setup"
{
    Caption = 'Source Code Setup';
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';

    fields
    {
        /// <summary>
        /// The primary key field of the setup record. A blank is used as default.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

