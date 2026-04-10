// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Item;

page 6078 "Service Contract Line List"
{
    Caption = 'Service Contract Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service item associated with the service contract.';
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                }
                field("New Line"; Rec."New Line")
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Service &Item Card")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Item Card';
                    Image = ServiceItem;
                    RunObject = Page "Service Item Card";
                    RunPageLink = "No." = field("Service Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the service item.';
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = field("Service Item No.");
                    RunPageView = sorting("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
            }
        }
    }
}

