// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

table 242 "Source Code Setup"
{
    Caption = 'Source Code Setup';
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';

    fields
    {
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

