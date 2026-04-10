// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

page 6273 "Service Order Allocat. Archive"
{
    Caption = 'Service Order Allocations Archive';
    DataCaptionFields = "Document Type", "Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Order Allocat. Archive";

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                }
                field(Status; Rec.Status)
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
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
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
                field("Reason Code"; Rec."Reason Code")
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
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}