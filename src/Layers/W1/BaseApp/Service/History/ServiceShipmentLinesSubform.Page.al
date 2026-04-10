// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 6037 "Service Shipment Lines Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Lookup = false;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
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
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := IsFirstDocLine();
        DocumentNoHideValue := not IsFirstDocLine();
    end;

    var
        TempServShptLine: Record "Service Shipment Line" temporary;
        StyleIsStrong: Boolean;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        ServShptLine: Record "Service Shipment Line";
    begin
        TempServShptLine.Reset();
        TempServShptLine.CopyFilters(Rec);
        TempServShptLine.SetRange("Document No.", Rec."Document No.");
        if not TempServShptLine.FindFirst() then begin
            ServShptLine.CopyFilters(Rec);
            ServShptLine.SetRange("Document No.", Rec."Document No.");
            if not ServShptLine.FindFirst() then
                exit(false);
            TempServShptLine := ServShptLine;
            TempServShptLine.Insert();
        end;
        if Rec."Line No." = TempServShptLine."Line No." then
            exit(true);
    end;
}

