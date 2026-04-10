// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using System.Security.User;

page 6064 "Contract Gain/Loss Entries"
{
    Caption = 'Contract Gain/Loss Entries';
    DataCaptionFields = "Contract No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Contract Gain/Loss Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Contract Group Code"; Rec."Contract Group Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Change Date"; Rec."Change Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Service;
                }
                field("Type of Change"; Rec."Type of Change")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                    Editable = false;
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

