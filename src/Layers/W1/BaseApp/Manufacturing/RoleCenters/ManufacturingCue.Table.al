// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity;

table 9056 "Manufacturing Cue"
{
    Caption = 'Manufacturing Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Planned Prod. Orders - All"; Integer)
        {
            CalcFormula = count("Production Order" where(Status = const(Planned)));
            Caption = 'Planned Prod. Orders';
            ToolTip = 'Specifies the number of planned production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(3; "Firm Plan. Prod. Orders - All"; Integer)
        {
            CalcFormula = count("Production Order" where(Status = const("Firm Planned")));
            Caption = 'Firm Plan. Prod. Orders';
            ToolTip = 'Specifies the number of firm planned production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(4; "Released Prod. Orders - All"; Integer)
        {
            CalcFormula = count("Production Order" where(Status = const(Released)));
            Caption = 'Released Prod. Orders';
            ToolTip = 'Specifies the number of released production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(5; "Prod. BOMs under Development"; Integer)
        {
            CalcFormula = count("Production BOM Header" where(Status = const("Under Development")));
            Caption = 'Prod. BOMs under Development';
            ToolTip = 'Specifies the number of production BOMs that are under development that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(6; "Routings under Development"; Integer)
        {
            CalcFormula = count("Routing Header" where(Status = const("Under Development")));
            Caption = 'Routings under Development';
            ToolTip = 'Specifies the routings under development that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(7; "Purchase Orders"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         "Assigned User ID" = field("User ID Filter")));
            Caption = 'Purchase Orders';
            ToolTip = 'Specifies the number of purchase orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(8; "Prod. Orders Routings-in Queue"; Integer)
        {
            CalcFormula = count("Prod. Order Routing Line" where("Starting Date" = field("Date Filter"),
                                                                  "Routing Status" = filter(" " | Planned),
                                                                  Status = filter(<> Finished)));
            Caption = 'Prod. Orders Routings-in Queue';
            ToolTip = 'Specifies the number of production order routings in queue that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(9; "Prod. Orders Routings-in Prog."; Integer)
        {
            CalcFormula = count("Prod. Order Routing Line" where("Ending Date" = field("Date Filter"),
                                                                  "Routing Status" = filter("In Progress"),
                                                                  Status = const(Released)));
            Caption = 'Prod. Orders Routings-in Prog.';
            ToolTip = 'Specifies the number of inactive service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(10; "Invt. Picks to Production"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = const(Pick),
                                                                   "Source Document" = const("Prod. Consumption")));
            Caption = 'Invt. Picks to Production';
            ToolTip = 'Specifies the number of inventory picks that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(11; "Invt. Put-aways from Prod."; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = const("Invt. Put-away"),
                                                                   "Source Document" = const("Prod. Output")));
            Caption = 'Invt. Put-aways from Prod.';
            ToolTip = 'Specifies the number of inventory put-always from production that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(12; "Rlsd. Prod. Orders Until Today"; Integer)
        {
            CalcFormula = count("Production Order" where(Status = const(Released),
                                                          "Starting Date" = field("Date Filter")));
            Caption = 'Rlsd. Prod. Orders Until Today';
            ToolTip = 'Specifies the number of released production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(13; "Simulated Prod. Orders"; Integer)
        {
            CalcFormula = count("Production Order" where(Status = const(Simulated)));
            Caption = 'Simulated Prod. Orders';
            ToolTip = 'Specifies the number of simulated production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
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

