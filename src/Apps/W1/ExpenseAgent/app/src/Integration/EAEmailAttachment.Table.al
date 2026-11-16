// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

table 6942 "EA Email Attachment"
{
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; FileName; Text[250])
        {
            Caption = 'File Name';
            DataClassification = SystemMetadata;
        }
        field(3; ContentType; Text[100])
        {
            Caption = 'Content Type';
            DataClassification = SystemMetadata;
        }
        field(4; Content; Blob)
        {
            Caption = 'Content';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
