// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.ExternalFileStorage;

table 8751 "DA Internal Cleanup Entry"
{
    Access = Internal;
    Caption = 'Internal Attachment Cleanup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Attachment System ID"; Guid) { Caption = 'Attachment System ID'; }
        field(2; "Upload Generation"; Guid) { Caption = 'Upload Generation'; }
        field(3; "External File Path"; Text[2048]) { Caption = 'External File Path'; DataClassification = CustomerContent; }
        field(4; "External Upload Date"; DateTime) { Caption = 'External Upload Date'; }
        field(5; "Source Environment Hash"; Text[32]) { Caption = 'Source Environment Hash'; }
        field(6; "Account ID"; Guid) { Caption = 'Account ID'; }
        field(7; Connector; Enum "Ext. File Storage Connector") { Caption = 'Connector'; }
        field(8; "Destination Fingerprint"; Text[64]) { Caption = 'Destination Fingerprint'; }
        field(9; "Account Generation"; BigInteger) { Caption = 'Account Generation'; }
        field(10; "Source Media ID"; Guid) { Caption = 'Source Media ID'; }
        field(11; "Source Media Version"; BigInteger) { Caption = 'Source Media Version'; }
        field(12; "Provenance Valid"; Boolean) { Caption = 'Provenance Valid'; }
        field(20; Origin; Enum "DA Internal Cleanup Origin") { Caption = 'Origin'; }
        field(21; Status; Enum "DA Internal Cleanup Status") { Caption = 'Status'; }
        field(22; "Requested At"; DateTime) { Caption = 'Requested At'; }
        field(23; "Request Environment Hash"; Text[32]) { Caption = 'Request Environment Hash'; }
        field(24; "Attempt Count"; Integer) { Caption = 'Attempt Count'; }
        field(25; "Next Attempt At"; DateTime) { Caption = 'Next Attempt At'; }
        field(26; "Lease Token"; Guid) { Caption = 'Lease Token'; }
        field(27; "Lease Expires At"; DateTime) { Caption = 'Lease Expires At'; }
        field(28; "Last Verified At"; DateTime) { Caption = 'Last Verified At'; }
        field(29; "Retrieved Bytes"; BigInteger) { Caption = 'Retrieved Bytes'; }
        field(30; "Outcome"; Text[50]) { Caption = 'Outcome'; }
        field(31; "Last Error"; Text[2048]) { Caption = 'Last Error'; DataClassification = CustomerContent; }
        field(32; "Attempt Attachment Version"; BigInteger) { Caption = 'Attempt Attachment Version'; }
        field(33; "Attempt Setup Version"; BigInteger) { Caption = 'Attempt Setup Version'; }
    }

    keys
    {
        key(PK; "Attachment System ID") { Clustered = true; }
        key(Due; Status, "Next Attempt At", "Attachment System ID") { }
        key(EarliestDue; "Next Attempt At", Status, "Attachment System ID") { }
        key(Lease; Status, "Lease Expires At", "Attachment System ID") { }
    }
}
