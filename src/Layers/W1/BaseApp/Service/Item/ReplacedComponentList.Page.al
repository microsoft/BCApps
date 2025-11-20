// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Service.History;

page 5987 "Replaced Component List"
{
    AutoSplitKey = true;
    Caption = 'Replaced Component List';
    DataCaptionFields = "Parent Service Item No.", "Line No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Item Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Active; Rec.Active)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the component is in use.';
                }
                field("Parent Service Item No."; Rec."Parent Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item in which the component is included.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the component type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the component.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the component.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditSerialNo();
                    end;
                }
                field("Date Installed"; Rec."Date Installed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the component was installed.';
                }
                field("Service Order No."; Rec."Service Order No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order under which this component was replaced.';
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
        area(navigation)
        {
            group("&Component")
            {
                Caption = '&Component';
                Image = Components;
                action(Shipment)
                {
                    ApplicationArea = Service;
                    Caption = 'Shipment';
                    Image = Shipment;
                    RunObject = Page "Posted Service Shipments";
                    RunPageLink = "Order No." = field("Service Order No.");
                    ToolTip = 'View related posted service shipments.';
                }
            }
        }
    }
}

