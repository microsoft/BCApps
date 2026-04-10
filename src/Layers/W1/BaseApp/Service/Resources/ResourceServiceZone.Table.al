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
            ToolTip = 'Specifies the title of the resource located in the service zone.';
            NotBlank = true;
            TableRelation = Resource;
        }
        field(2; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            ToolTip = 'Specifies the code of the service zone where the resource will be located. A resource can be located in more than one zone at a time.';
            NotBlank = true;
            TableRelation = "Service Zone";
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the starting date when the resource is located in the service zone.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the resource''s assignment to the service zone.';
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

