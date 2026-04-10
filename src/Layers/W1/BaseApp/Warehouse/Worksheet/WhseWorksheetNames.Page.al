// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

page 7344 "Whse. Worksheet Names"
{
    Caption = 'Whse. Worksheet Names';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Whse. Worksheet Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ShowMandatory = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
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

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewName();
    end;

    local procedure DataCaption(): Text[250]
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Worksheet Template Name") <> '' then
                if Rec.GetRangeMin("Worksheet Template Name") = Rec.GetRangeMax("Worksheet Template Name") then
                    if WhseWkshTemplate.Get(Rec.GetRangeMin("Worksheet Template Name")) then
                        exit(WhseWkshTemplate.Name + ' ' + WhseWkshTemplate.Description);
    end;
}

