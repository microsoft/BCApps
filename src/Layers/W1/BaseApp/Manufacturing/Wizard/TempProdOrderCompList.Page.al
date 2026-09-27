// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.Document;

page 99001019 "Temp Prod. Order Comp. List"
{
    PageType = ListPart;
    SourceTable = "Prod. Order Component";
    SourceTableTemporary = true;
    Caption = 'Production Order Components';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item number of the component.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ToolTip = 'Specifies the variant of the component item.';
                }
                field("Due Date-Time"; Rec."Due Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the due date and time for the component.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date for the component.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the component.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies additional description of the component.';
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the scrap percentage for the component.';
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
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the weight of the component.';
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the depth of the component.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the component are required to produce one unit of the parent item.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                    ToolTip = 'Specifies the quantity reserved for the component.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code for the component.';
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the component is calculated and handled.';
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the expected quantity of the component.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the remaining quantity of the component.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a routing link code to link the component with a specific operation.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the location from which components are consumed.';
                }
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Prod. Order No." := xRec."Prod. Order No.";
        Rec."Prod. Order Line No." := xRec."Prod. Order Line No.";
        Rec.Status := xRec.Status;
        Rec."Location Code" := xRec."Location Code";
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    /// <summary>
    /// Binds the page list to the provided temporary production order component records.
    /// </summary>
    /// <param name="TempProdOrderComponent">The temporary production order components to display and edit on the page.</param>
    internal procedure SetTempProdOrderComponent(var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        Rec.Copy(TempProdOrderComponent, true);
        CurrPage.Update(false);
    end;
}