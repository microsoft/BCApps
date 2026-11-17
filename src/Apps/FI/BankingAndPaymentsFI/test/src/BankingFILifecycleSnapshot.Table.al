// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 148241 "Banking FI Lifecycle Snapshot"
{
    Access = Internal;
    Caption = 'Banking FI Lifecycle Snapshot';
    DataPerCompany = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Completed Target"; Boolean)
        {
            Caption = 'Completed Target';
        }
        field(2; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
        }
        field(3; "Source Field No."; Integer)
        {
            Caption = 'Source Field No.';
        }
        field(4; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(5; "Target Table ID"; Integer)
        {
            Caption = 'Target Table ID';
        }
        field(6; "Target Field No."; Integer)
        {
            Caption = 'Target Field No.';
        }
        field(7; "Captured Data Version"; Text[50])
        {
            Caption = 'Captured Data Version';
        }
        field(8; "Expected Count"; Integer)
        {
            Caption = 'Expected Count';
        }
        field(9; "Values"; Blob)
        {
            Caption = 'Values';
        }
        field(10; "Target Before"; Blob)
        {
            Caption = 'Target Before';
        }
        field(11; "Verified Data Version"; Text[50])
        {
            Caption = 'Verified Data Version';
        }
        field(12; "Expected Target Count"; Integer)
        {
            Caption = 'Expected Target Count';
        }
    }

    keys
    {
        key(PK; "Completed Target", "Source Table ID", "Source Field No.", "Source SystemId")
        {
            Clustered = true;
        }
    }
}
