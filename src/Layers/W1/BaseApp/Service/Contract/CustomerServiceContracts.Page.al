// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6065 "Customer Service Contracts"
{
    Caption = 'Customer Service Contracts';
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Header";
    SourceTableView = where("Contract Type" = filter(Contract));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Expiration Date"; Rec."Expiration Date")
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
            group("&Contract")
            {
                Caption = '&Contract';
                Image = Agreement;
                action("&Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Service Contract";
                    RunPageLink = "Contract Type" = field("Contract Type"),
                                  "Contract No." = field("Contract No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the service contract.';
                }
            }
        }
    }
}

