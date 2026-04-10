// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Utilities;

page 5904 "Service Line List"
{
    Caption = 'Service Line List';
    DataCaptionFields = "Fault Reason Code";
    Editable = false;
    PageType = List;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Posting Date"; Rec."Posting Date")
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
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
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
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Line Type"; Rec."Job Line Type")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Needed by Date"; Rec."Needed by Date")
                {
                    ApplicationArea = Service;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the quantity of items, resource time, costs, or general ledger account payments, expressed in base units of measure.';
                }
                field("Outstanding Qty. (Base)"; Rec."Outstanding Qty. (Base)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the quantity of registered items, resource time, costs, or payments to the general ledger account that have not been shipped.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount Type"; Rec."Line Discount Type")
                {
                    ApplicationArea = Service;
                }
                field("Spare Part Action"; Rec."Spare Part Action")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
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
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
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
                action("Show Document")
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        if ServHeader.Get(Rec."Document Type", Rec."Document No.") then
                            PageManagement.PageRun(ServHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
            }
        }
    }

    var
        ServHeader: Record "Service Header";
}

