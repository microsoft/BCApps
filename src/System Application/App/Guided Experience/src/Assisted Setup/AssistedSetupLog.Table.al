#if not CLEANSCHEMA23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

table 1807 "Assisted Setup Log"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Caption = 'Assisted Setup Log';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'The logs are not used.';

    fields
    {
        field(1; "No."; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(3; "Entery No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entery No.';
            TableRelation = "Guided Experience Item"."Object ID to Run";
        }
        field(10; "Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Date Time';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

}
#endif