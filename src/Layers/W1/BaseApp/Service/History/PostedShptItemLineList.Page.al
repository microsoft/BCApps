// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 5950 "Posted Shpt. Item Line List"
{
    Caption = 'Posted Service Shpt. Item Line List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Service Shipment Item Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the spare parts warranty expires for this service item.';
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the labor warranty expires on the posted service item.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the warranty starts on the service item spare parts.';
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the labor warranty for the posted service item starts.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

