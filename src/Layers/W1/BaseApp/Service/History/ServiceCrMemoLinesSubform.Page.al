// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 6039 "Service Cr. Memo Lines Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Cr.Memo Line";

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
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
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
                    ApplicationArea = Dimensions;
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
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Shipment No."; Rec."Shipment No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Appl.-to Service Entry"; Rec."Appl.-to Service Entry")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
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
        TempServCrMemoLine: Record "Service Cr.Memo Line" temporary;
        StyleIsStrong: Boolean;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        ServCrMemoLine: Record "Service Cr.Memo Line";
    begin
        TempServCrMemoLine.Reset();
        TempServCrMemoLine.CopyFilters(Rec);
        TempServCrMemoLine.SetRange("Document No.", Rec."Document No.");
        if not TempServCrMemoLine.FindFirst() then begin
            ServCrMemoLine.CopyFilters(Rec);
            ServCrMemoLine.SetRange("Document No.", Rec."Document No.");
            if not ServCrMemoLine.FindFirst() then
                exit(false);
            TempServCrMemoLine := ServCrMemoLine;
            TempServCrMemoLine.Insert();
        end;
        exit(Rec."Line No." = TempServCrMemoLine."Line No.");
    end;
}

