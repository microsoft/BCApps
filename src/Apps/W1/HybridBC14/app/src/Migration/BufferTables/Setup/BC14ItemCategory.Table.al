// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46915 "BC14 Item Category"
{
    Caption = 'Item Category Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Parent Category"; Code[20]) { Caption = 'Parent Category'; }
        field(4; "Presentation Order"; Integer) { Caption = 'Presentation Order'; }
        field(5; Indentation; Integer) { Caption = 'Indentation'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
