// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

page 6036 "Service Lines Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Service Line";

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
                    BlankZero = true;
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
                    BlankNumbers = DontBlank;
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
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
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
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;
                }
                field("Job Line Type"; Rec."Job Line Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of journal line that is created in the Job Planning Line table from this line.';
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
        TempServLine: Record "Service Line" temporary;
        StyleIsStrong: Boolean;
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        ServLine: Record "Service Line";
    begin
        TempServLine.Reset();
        TempServLine.CopyFilters(Rec);
        TempServLine.SetRange("Document Type", Rec."Document Type");
        TempServLine.SetRange("Document No.", Rec."Document No.");
        if not TempServLine.FindFirst() then begin
            ServLine.CopyFilters(Rec);
            ServLine.SetRange("Document Type", Rec."Document Type");
            ServLine.SetRange("Document No.", Rec."Document No.");
            if not ServLine.FindFirst() then
                exit(false);
            TempServLine := ServLine;
            TempServLine.Insert();
        end;
        if Rec."Line No." = TempServLine."Line No." then
            exit(true);
    end;
}

