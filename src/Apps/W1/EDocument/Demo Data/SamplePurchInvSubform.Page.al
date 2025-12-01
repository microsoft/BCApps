// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

/// <summary>
/// Subform page for managing sample purchase invoice lines.
/// </summary>
page 5424 "Sample Purch. Inv. Subform"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sample Purchase Invoice Lines';
    PageType = ListPart;
    SourceTable = "Sample Purch. Inv. Line";
    SourceTableTemporary = true;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the item or G/L account.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity.';

                    trigger OnValidate()
                    begin
                        Rec."Line Amount" := Rec.Quantity * Rec."Direct Unit Cost";
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies the unit of measure code.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ToolTip = 'Specifies the direct unit cost.';

                    trigger OnValidate()
                    begin
                        Rec."Line Amount" := Rec.Quantity * Rec."Direct Unit Cost";
                    end;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ToolTip = 'Specifies the line amount (Quantity x Direct Unit Cost).';
                    Editable = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ToolTip = 'Specifies the tax group code.';
                    Visible = false;
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ToolTip = 'Specifies the deferral code.';
                    Visible = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := Rec.Type::Item;
    end;

    /// <summary>
    /// Gets all records from the temporary table.
    /// </summary>
    /// <param name="var TempLines">Variable to receive the line records.</param>
    procedure GetRecords(var TempLines: Record "Sample Purch. Inv. Line" temporary)
    begin
        TempLines.Reset();
        TempLines.DeleteAll();
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempLines := Rec;
                TempLines.Insert();
            until Rec.Next() = 0;
    end;
}
