// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5941 "Repair Status Setup"
{
    ApplicationArea = Service;
    Caption = 'Repair Status Setup';
    PageType = List;
    SourceTable = "Repair Status";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the repair status.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the repair status.';
                }
                field("Service Order Status"; Rec."Service Order Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status that is linked to this repair status.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order status.';
                }
                field(Initial; Rec.Initial)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that no service has been performed.';
                }
                field("In Process"; Rec."In Process")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item is in process.';
                }
                field(Finished; Rec.Finished)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item has been finished.';
                }
                field("Partly Serviced"; Rec."Partly Serviced")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service item has been partly serviced. Further work is needed.';
                }
                field(Referred; Rec.Referred)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service of the item has been referred to another resource. No service has been performed on the service item.';
                }
                field("Spare Part Ordered"; Rec."Spare Part Ordered")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a spare part has been ordered for the service item.';
                }
                field("Spare Part Received"; Rec."Spare Part Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a spare part has been received for the service item.';
                }
                field("Waiting for Customer"; Rec."Waiting for Customer")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you are waiting for a customer response.';
                }
                field("Quote Finished"; Rec."Quote Finished")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that quoting work on the service item is finished.';
                }
                field("Posting Allowed"; Rec."Posting Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can post a service order, if it includes a service item with this repair status.';
                }
                field("Pending Status Allowed"; Rec."Pending Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to Pending, if it includes a service item with this repair status.';
                }
                field("In Process Status Allowed"; Rec."In Process Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to In Process, if it includes a service item with this repair status.';
                }
                field("Finished Status Allowed"; Rec."Finished Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to Finished, if it includes a service item with this repair status.';
                }
                field("On Hold Status Allowed"; Rec."On Hold Status Allowed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can manually change the Status of a service order to On Hold, if it includes a service item with this repair status.';
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

