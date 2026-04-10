// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

page 5924 "Loaner Entries"
{
    ApplicationArea = Service;
    Caption = 'Loaner Entries';
    DataCaptionFields = "Loaner No.";
    Editable = false;
    PageType = List;
    SourceTable = "Loaner Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Date Lent"; Rec."Date Lent")
                {
                    ApplicationArea = Service;
                }
                field("Time Lent"; Rec."Time Lent")
                {
                    ApplicationArea = Service;
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Service;
                }
                field("Time Received"; Rec."Time Received")
                {
                    ApplicationArea = Service;
                }
                field(Lent; Rec.Lent)
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

