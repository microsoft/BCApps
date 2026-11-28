// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

table 149048 "Agent Eval AI Task Link"
{
    Access = Internal;
    Caption = 'Agent Eval AI Task Link';
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
        field(4; Version; Integer) { Caption = 'Version'; }
        field(5; Tag; Text[20]) { Caption = 'Tag'; DataClassification = CustomerContent; }
        field(6; "Test Method Line No."; Integer) { Caption = 'Eval Line No.'; }
        field(7; "Log Entry System ID"; Guid) { Caption = 'Log Entry System ID'; }
        field(8; "Log Entry No."; Integer) { Caption = 'Log Entry No.'; }
    }

    keys
    {
        key(PK; "Agent Task ID", Company, "Log Entry System ID") { Clustered = true; }
        key(Run; Company, "Test Suite Code", Version, Tag, "Test Method Line No.") { }
        key(Result; Company, "Log Entry No.") { }
    }
}
