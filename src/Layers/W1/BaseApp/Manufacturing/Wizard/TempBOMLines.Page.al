// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.ProductionBOM;
page 99001029 "Temp BOM Lines"
{
    PageType = ListPart;
    SourceTable = "Production BOM Line";
    SourceTableTemporary = true;
    Caption = 'Production BOM Lines';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of the BOM line (Item or Production BOM).';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the component item or sub-assembly.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ToolTip = 'Specifies the variant of the item on the BOM line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the BOM line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies additional description of the BOM line.';
                }
                field("Calculation Formula"; Rec."Calculation Formula")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies how to calculate the Quantity per field.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the length of the component.';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the width of the component.';
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the depth of the component.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the weight of the component.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the component are required per unit of the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the BOM line.';
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap percentage for the component.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code to link this component to a routing operation.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the position of the component.';
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the second position reference of the component.';
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the third position reference of the component.';
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the lead-time offset for the component.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the date from which the BOM line is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the last date on which the BOM line is valid.';
                }
            }
        }
    }

    var
        LinesChanged: Boolean;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        LinesChanged := true;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        LinesChanged := true;
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        LinesChanged := true;
        exit(true);
    end;

    /// <summary>
    /// Binds the page list to the provided temporary BOM line records.
    /// </summary>
    /// <param name="TempBOMLine">The temporary BOM lines to display and edit on the page.</param>
    internal procedure SetTemporaryRecords(var TempBOMLine: Record "Production BOM Line" temporary)
    begin
        Rec.Copy(TempBOMLine, true);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Returns the current temporary BOM line records from the page by copying them into the provided variable.
    /// </summary>
    /// <param name="TempBOMLine">The variable to receive the temporary BOM lines.</param>
    internal procedure GetTemporaryRecords(var TempBOMLine: Record "Production BOM Line" temporary)
    begin
        TempBOMLine.Copy(Rec, true);
    end;
}