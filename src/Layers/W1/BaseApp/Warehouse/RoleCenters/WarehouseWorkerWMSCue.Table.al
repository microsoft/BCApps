// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Warehouse.Activity;

table 9058 "Warehouse Worker WMS Cue"
{
    Caption = 'Warehouse Worker WMS Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Unassigned Picks"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Pick),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Picks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "My Picks"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Pick),
                                                                   "Assigned User ID" = field("User ID Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'My Picks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Unassigned Put-aways"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Put-away"),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Put-aways';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "My Put-aways"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Put-away"),
                                                                   "Assigned User ID" = field("User ID Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'My Put-aways';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Unassigned Movements"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Movement),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Movements';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "My Movements"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Movement),
                                                                   "Assigned User ID" = field("User ID Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'My Movements';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

