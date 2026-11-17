// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Per-environment counter that tracks the number of EU VIES VAT registration number lookups performed per day.
/// Used to cap the daily lookup volume per environment (all companies in the database share one counter) so a
/// single environment cannot flood the shared, unauthenticated VIES service and get the shared outbound IP address
/// deny-listed. Holds a single row that is locked for the brief read-modify-write, so concurrent sessions
/// increment it atomically.
/// </summary>
table 243 "VAT Reg. No. Lookup Quota"
{
    Access = Internal;
    DataPerCompany = false;
    DataClassification = SystemMetadata;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Window Date"; Date)
        {
            Caption = 'Window Date';
            DataClassification = SystemMetadata;
        }
        field(3; "Daily Call Count"; Integer)
        {
            Caption = 'Daily Call Count';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
