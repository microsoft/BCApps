// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

page 6003 "Cancelled Allocation Entries"
{
    Caption = 'Canceled Allocation Entries';
    DataCaptionFields = "Document Type", "Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Order Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reason Code"; Rec."Reason Code")
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
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Allocation Date"; Rec."Allocation Date")
                {
                    ApplicationArea = Service;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Service;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
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

