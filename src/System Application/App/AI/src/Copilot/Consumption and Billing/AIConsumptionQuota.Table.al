// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// A point-in-time V2 quota decision. -1 denotes unavailable credit amounts.
/// </summary>
table 7785 "AI Consumption Quota"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Can Consume"; Boolean) { }
        field(3; "Billing Enabled"; Boolean) { }
        field(4; "Credit Source"; Text[50]) { }
        field(5; "AI Credit Limit"; Decimal) { InitValue = -1; }
        field(6; "Consumed AI Credits"; Decimal) { InitValue = -1; }
        field(7; "Next Reset"; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
