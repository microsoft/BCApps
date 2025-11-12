// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Setup;

table 5958 "Resource Service Zone"
{
    Caption = 'Resource Service Zone';
    LookupPageID = "Resource Service Zones";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            NotBlank = true;
            TableRelation = Resource;
        }
        field(2; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            NotBlank = true;
            TableRelation = "Service Zone";
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Resource No.", "Service Zone Code", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Service Zone Code", "Starting Date", "Resource No.")
        {
        }
    }

    fieldgroups
    {
    }
}

