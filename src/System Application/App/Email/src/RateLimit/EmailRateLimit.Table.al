// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// The rate limits for email accounts.
/// </summary>
table 8912 "Email Rate Limit"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    fields
    {
        field(1; "Account Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Email Address"; Text[2048])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Rate Limit"; Integer)
        {
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(4; Connector; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Concurrency Limit"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 3;

            trigger OnValidate()
            begin
                if (Rec."Concurrency Limit" < 1) or (Rec."Concurrency Limit" > 10) then
                    Error(ConcurrencyLimitErrLbl);
            end;
        }
        field(6; "Max. Retry Limit"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 1;

            trigger OnValidate()
            begin
                if (Rec."Max. Retry Limit" < 1) or (Rec."Max. Retry Limit" > 20) then
                    Error(MaxRetryLimitErrLbl);
            end;
        }
    }

    keys
    {
        key(PK; "Account Id", Connector)
        {
            Clustered = true;
        }
        key(Name; "Email Address")
        {
            Description = 'Used for sorting by Email Address.';
        }
    }

    var
        ConcurrencyLimitErrLbl: Label 'Concurrency Limit must be between 1 and 10.';
        MaxRetryLimitErrLbl: Label 'Max. Attempt Limit must be between 1 and 20.';
}