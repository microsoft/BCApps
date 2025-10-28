// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.QualityManagement.Document;

table 20414 "Qlty. Mgmt. Role Center Cue"
{
    Caption = 'Quality Management Role Center Cue';
    DataClassification = CustomerContent;
    InherentPermissions = RIM;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "All Open Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Open)));
            Caption = 'Open Tests (all)';
            ToolTip = 'Specifies the count of quality inspection tests that are open.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "My Open Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Open),
                                                                     "Assigned User ID" = filter('%me')));
            Caption = 'Open Tests (mine)';
            ToolTip = 'Specifies the count of quality inspection tests that are open and assigned to you.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "All Finished Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Finished)));
            Caption = 'Finished Tests (all)';
            ToolTip = 'Specifies the count of quality inspection tests that are finished.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "My Finished Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Finished),
                                                                     "Assigned User ID" = filter('%me')));
            Caption = 'Finished Tests (mine)';
            ToolTip = 'Specifies the count of quality inspection tests that are finished and assigned to you.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Unassigned Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where("Assigned User ID" = filter('''''')));
            Caption = 'Unassigned Tests';
            ToolTip = 'Specifies the count of quality inspection tests that are not assigned to any user.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "All Open and Due Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Open),
                                                                     "Planned Start Date" = filter('<=T')));
            Caption = 'Open and Due Tests (all)';
            ToolTip = 'Specifies the count of quality inspection tests that are open and due.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "My Open and Due Tests"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Test Header" where(Status = const(Open),
                                                                     "Assigned User ID" = filter('%me'),
                                                                     "Planned Start Date" = filter('<=T')));
            Caption = 'Open and Due Tests (mine)';
            ToolTip = 'Specifies the count of quality inspection tests that are open, due, and assigned to you.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
