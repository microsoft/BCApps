// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using System.Security.User;

page 7319 "Warehouse Journal Lines"
{
    Caption = 'Warehouse Journal Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("From Zone Code"; Rec."From Zone Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Absolute, Base)"; Rec."Qty. (Absolute, Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity expressed as an absolute (positive) number, in the base unit of measure.';
                    Visible = false;
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field(Cubage; Rec.Cubage)
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
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

