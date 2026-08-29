// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.Finance.Dimension;

page 6154 "E-Doc. Sales Draft Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    InsertAllowed = false;
    LinksAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "E-Document Sales Line";

    layout
    {
        area(Content)
        {
            repeater(DocumentLines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Line Type"; Rec."[BC] Sales Line Type")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."[BC] Sales Line No.")
                {
                    ApplicationArea = All;
                    Lookup = true;
                    ShowMandatory = true;
                }
                field("Unit Of Measure"; Rec."[BC] Unit of Measure")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Line Amount"; Rec."Line Extension Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the line extension amount.';
                    Editable = false;
                }
                field("VAT Rate"; Rec."VAT Rate")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the VAT rate of this line.';
                }
                field("Shortcut Dimension 1 Code"; Rec."[BC] Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."[BC] Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
            }
        }
    }

    var
        DimVisible1, DimVisible2 : Boolean;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
        DimOther: Boolean;
    begin
        DimMgt.UseShortcutDims(DimVisible1, DimVisible2, DimOther, DimOther, DimOther, DimOther, DimOther, DimOther);
    end;
}
