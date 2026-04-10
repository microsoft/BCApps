// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

page 99000922 "Demand Forecast Entries"
{
    Caption = 'Demand Forecast Entries';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Production Forecast Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Production Forecast Name"; Rec."Production Forecast Name")
                {
                    ApplicationArea = Planning;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                }
                field("Forecast Quantity (Base)"; Rec."Forecast Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity of the entry stated, in base units of measure.';
                }
                field("Forecast Date"; Rec."Forecast Date")
                {
                    ApplicationArea = Planning;
                }
                field("Forecast Quantity"; Rec."Forecast Quantity")
                {
                    ApplicationArea = Planning;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Visible = false;
                }
                field("Component Forecast"; Rec."Component Forecast")
                {
                    ApplicationArea = Planning;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Visible = false;
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

    trigger OnOpenPage()
    begin
        if CurrentClientType in [ClientType::ODataV4, ClientType::API] then
            exit;

        CurrentForecastName := Rec.GetFilter("Production Forecast Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if CurrentForecastName <> '' then
            Rec."Production Forecast Name" := CopyStr(CurrentForecastName, 1, MaxStrLen(Rec."Production Forecast Name"))
        else
            Rec."Production Forecast Name" := xRec."Production Forecast Name";
            if GUIAllowed() then begin
            Rec."Item No." := xRec."Item No.";
            Rec."Unit of Measure Code" := xRec."Unit of Measure Code";
            Rec."Qty. per Unit of Measure" := xRec."Qty. per Unit of Measure";
            Rec."Forecast Date" := xRec."Forecast Date";
        end;
    end;

    var
        CurrentForecastName: Text;
}

