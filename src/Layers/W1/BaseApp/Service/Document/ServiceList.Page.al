// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Utilities;

page 5901 "Service List"
{
    Caption = 'Service List';
    DataCaptionFields = "Document Type", "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Header";

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
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Visible = ResponseDateVisible;
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    Visible = ResponseTimeVisible;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
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
                action(ShowDocument)
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        ResponseTimeVisible := true;
        ResponseDateVisible := true;
    end;

    trigger OnOpenPage()
    begin
        if Rec."Document Type" = Rec."Document Type"::Order then begin
            ResponseDateVisible := true;
            ResponseTimeVisible := true;
        end else begin
            ResponseDateVisible := false;
            ResponseTimeVisible := false;
        end;

        Rec.CopyCustomerFilter();
    end;

    var
        ResponseDateVisible: Boolean;
        ResponseTimeVisible: Boolean;
}

