// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

page 99001508 "Subc. Temp Prod Order Comp"
{
    ApplicationArea = Manufacturing;
    AutoSplitKey = true;
    Caption = 'Temporary Prod. Order Components';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Prod. Order Component";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the number of the item that is a component in the production order component list.';

                    trigger OnValidate()
                    begin
                        if (xRec."Item No." = '') and (xRec."Item No." <> Rec."Item No.") then
                            Rec.Validate("Flushing Method", xRec."Flushing Method");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the location where the component is stored.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'Specifies the bin in which the component is to be placed before it is consumed.';
                    Visible = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours.';
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ToolTip = 'Specifies the routing link code when you calculate the production order.';
                }
                field("Subcontracting Type"; Rec."Subcontracting Type")
                {
                    ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production BOM Line.';
                    trigger OnValidate()
                    begin
                        if Rec."Subcontracting Type" = Rec."Subcontracting Type"::Purchase then
                            Rec.FieldError("Subcontracting Type");

                        if (Rec."Routing Link Code" = '') and (Rec."Subcontracting Type" <> Rec."Subcontracting Type"::Empty) then begin
                            GetSubManagementSetup();
                            Rec."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
                        end;

                        if Rec."Subcontracting Type" <> Rec."Subcontracting Type"::Transfer then
                            Rec.Validate("Location Code", CopyStr(SingleInstanceDictionary.GetCode('SetSubcontractingLocationCodeFromVendor'), 1, MaxStrLen(Rec."Location Code")))
                        else
                            Rec.Validate("Location Code", Rec."Orig. Location Code");
                    end;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the date when the produced item must be available.';
                    Visible = false;
                }
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Prod. Order No." := xRec."Prod. Order No.";
        Rec."Prod. Order Line No." := xRec."Prod. Order Line No.";
        Rec.Status := xRec.Status;
        Rec."Routing Link Code" := xRec."Routing Link Code";
        Rec."Subcontracting Type" := xRec."Subcontracting Type";
        Rec."Location Code" := xRec."Location Code";
        Rec."Orig. Location Code" := xRec."Orig. Location Code";

        if PresetSubValues then begin
            GetSubManagementSetup();
            Rec."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
            Rec."Flushing Method" := SubcManagementSetup."Def. provision flushing method";
        end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    protected var
        LinesChanged: Boolean;

    var
        SubcManagementSetup: Record "Subc. Management Setup";
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
        PresetSubValues: Boolean;
        SubManagementSetupRead: Boolean;

    procedure GetLinesChanged(): Boolean
    begin
        exit(LinesChanged);
    end;

    procedure SetTemporaryRecords(var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        Rec.Copy(TempProdOrderComponent, true);
        if Rec.FindFirst() then;
    end;

    procedure SetPresetSubValues(Preset: Boolean)
    begin
        PresetSubValues := Preset;
    end;

    local procedure GetSubManagementSetup()
    begin
        if not SubManagementSetupRead then begin
            SubcManagementSetup.SetLoadFields("Rtng. Link Code Purch. Prov.", "Def. provision flushing method");
            SubcManagementSetup.Get();
            SubManagementSetupRead := true;
        end;
    end;
}