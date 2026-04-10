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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Service Order Status"; Rec."Service Order Status")
                {
                    ApplicationArea = Service;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                }
                field(Initial; Rec.Initial)
                {
                    ApplicationArea = Service;
                }
                field("In Process"; Rec."In Process")
                {
                    ApplicationArea = Service;
                }
                field(Finished; Rec.Finished)
                {
                    ApplicationArea = Service;
                }
                field("Partly Serviced"; Rec."Partly Serviced")
                {
                    ApplicationArea = Service;
                }
                field(Referred; Rec.Referred)
                {
                    ApplicationArea = Service;
                }
                field("Spare Part Ordered"; Rec."Spare Part Ordered")
                {
                    ApplicationArea = Service;
                }
                field("Spare Part Received"; Rec."Spare Part Received")
                {
                    ApplicationArea = Service;
                }
                field("Waiting for Customer"; Rec."Waiting for Customer")
                {
                    ApplicationArea = Service;
                }
                field("Quote Finished"; Rec."Quote Finished")
                {
                    ApplicationArea = Service;
                }
                field("Posting Allowed"; Rec."Posting Allowed")
                {
                    ApplicationArea = Service;
                }
                field("Pending Status Allowed"; Rec."Pending Status Allowed")
                {
                    ApplicationArea = Service;
                }
                field("In Process Status Allowed"; Rec."In Process Status Allowed")
                {
                    ApplicationArea = Service;
                }
                field("Finished Status Allowed"; Rec."Finished Status Allowed")
                {
                    ApplicationArea = Service;
                }
                field("On Hold Status Allowed"; Rec."On Hold Status Allowed")
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

