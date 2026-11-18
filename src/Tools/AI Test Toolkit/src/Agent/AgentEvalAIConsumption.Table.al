// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

table 149047 "Agent Eval AI Consumption"
{
    Access = Internal;
    Caption = 'Agent Eval AI Consumption';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Agent Task ID"; BigInteger) { Caption = 'Agent Task ID'; }
        field(2; Company; Text[30]) { Caption = 'Company'; }
        field(3; "Test Suite Code"; Code[100]) { Caption = 'Eval Suite Code'; }
        field(4; "Accounting Date"; Date) { Caption = 'Accounting Date'; }
        field(5; "AI Credits"; Decimal) { Caption = 'Completed AI Credits'; AutoFormatType = 0; }
        field(6; "Pricing Pending"; Boolean) { Caption = 'Pricing Pending'; InitValue = true; }
    }

    keys
    {
        key(PK; "Agent Task ID", Company) { Clustered = true; }
        key(Attribution; "Accounting Date", "Test Suite Code", Company) { }
    }
}
