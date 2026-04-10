// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;

table 5609 "FA Location"
{
    Caption = 'FA Location';
    LookupPageID = "FA Locations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a location code for the fixed asset.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the fixed asset location.';
        }
        field(12400; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(12401; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(14920; "OKATO Code"; Code[11])
        {
            Caption = 'OKATO Code';
            TableRelation = OKATO;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetName(LocationCode: Code[10]): Text[50]
    begin
        if Get(LocationCode) then
            exit(Name);
        exit('');
    end;
}

