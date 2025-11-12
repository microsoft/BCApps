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
                    ToolTip = 'Specifies the name of the demand forecast to which the entry belongs.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item identification number of the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of your forecast.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant that is linked to the entry.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the location that is linked to the entry.';
                }
                field("Forecast Quantity (Base)"; Rec."Forecast Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity of the entry stated, in base units of measure.';
                }
                field("Forecast Date"; Rec."Forecast Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date of the demand forecast to which the entry belongs.';
                }
                field("Forecast Quantity"; Rec."Forecast Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantities you have entered in the demand forecast within the selected time interval.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the valid number of units that the unit of measure code represents for the demand forecast entry.';
                }
                field("Component Forecast"; Rec."Component Forecast")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies that the forecast entry is for a component item.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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

