// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;

page 99001506 "Subc. Temp BOM Lines"
{
    ApplicationArea = Manufacturing;
    AutoSplitKey = true;
    Caption = 'Temporary Production BOM Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Production BOM Line";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(BOMLines)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number for the production BOM line.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the type of the production BOM line.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the item or resource.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the item or resource.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies additional description of the item or resource.';
                    Visible = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies how each unit of the item or resource is measured.';
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ToolTip = 'Specifies the date from which this production BOM line is valid.';
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ToolTip = 'Specifies the date until which this production BOM line is valid.';
                    Visible = false;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ToolTip = 'Specifies the routing link code.';
                }
                field("Component Supply Method"; Rec."Component Supply Method")
                {
                    ToolTip = 'Specifies how components are supplied to the subcontractor for the production BOM line.';
                    ApplicationArea = Manufacturing;
                    trigger OnValidate()
                    begin
                        if Rec."Component Supply Method" = Rec."Component Supply Method"::VendorSupplied then
                            Rec.FieldError("Component Supply Method");

                        if (Rec."Routing Link Code" = '') and (Rec."Component Supply Method" <> Rec."Component Supply Method"::Empty) then begin
                            GetManufacturingSetup();
                            Rec."Routing Link Code" := ManufacturingSetup."Rtng. Link Code Purch. Prov.";
                        end;
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Production BOM No." := xRec."Production BOM No.";
        Rec."Version Code" := xRec."Version Code";
        Rec."Routing Link Code" := xRec."Routing Link Code";
        Rec."Component Supply Method" := xRec."Component Supply Method";
        GetManufacturingSetup();
        Rec."Routing Link Code" := ManufacturingSetup."Rtng. Link Code Purch. Prov.";
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRead: Boolean;

    procedure SetTemporaryRecords(var TempProductionBOMLine: Record "Production BOM Line" temporary)
    begin
        Rec.Copy(TempProductionBOMLine, true);
    end;

    local procedure GetManufacturingSetup()
    begin
        if not ManufacturingSetupRead then begin
            ManufacturingSetup.SetLoadFields("Rtng. Link Code Purch. Prov.");
            ManufacturingSetup.Get();
            ManufacturingSetupRead := true;
        end;
    end;
}
