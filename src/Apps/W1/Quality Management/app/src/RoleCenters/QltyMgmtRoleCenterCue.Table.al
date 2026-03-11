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
        field(2; "All Open Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Open)));
            Caption = 'Open Inspections (all)';
            ToolTip = 'Specifies the count of quality inspections that are open.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "My Open Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Open),
                                                                "Assigned User ID" = filter('%me')));
            Caption = 'Open Inspections (mine)';
            ToolTip = 'Specifies the count of quality inspections that are open and assigned to you.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "All Finished Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Finished)));
            Caption = 'Finished Inspections (all)';
            ToolTip = 'Specifies the count of quality inspections that are finished.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "My Finished Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Finished),
                                                                "Assigned User ID" = filter('%me')));
            Caption = 'Finished Inspections (mine)';
            ToolTip = 'Specifies the count of quality inspections that are finished and assigned to you.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Unassigned Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where("Assigned User ID" = filter('''''')));
            Caption = 'Unassigned Inspections';
            ToolTip = 'Specifies the count of quality inspections that are not assigned to any user.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "All Open and Due Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Open),
                                                                "Planned Start Date" = filter('<=%NOW')));
            Caption = 'Open and Due Inspections (all)';
            ToolTip = 'Specifies the count of quality inspections that are open and due.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "My Open and Due Inspections"; Integer)
        {
            CalcFormula = count("Qlty. Inspection Header" where(Status = const(Open),
                                                                "Assigned User ID" = filter('%me'),
                                                                "Planned Start Date" = filter('<=%NOW')));
            Caption = 'Open and Due Inspections (mine)';
            ToolTip = 'Specifies the count of quality inspections that are open, due, and assigned to you.';
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
