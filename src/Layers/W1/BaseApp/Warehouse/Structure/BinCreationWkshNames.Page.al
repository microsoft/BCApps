// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7369 "Bin Creation Wksh. Names"
{
    Caption = 'Bin Creation Wksh. Names';
    DataCaptionExpression = DataCaption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Creation Wksh. Name";

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
                    ToolTip = 'Specifies a name for the worksheet.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description for the worksheet.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for which the worksheet should be used.';
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

    local procedure DataCaption(): Text[250]
    var
        BinCreateWkshTmpl: Record "Bin Creation Wksh. Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Worksheet Template Name") <> '' then
                if Rec.GetRangeMin("Worksheet Template Name") = Rec.GetRangeMax("Worksheet Template Name") then
                    if BinCreateWkshTmpl.Get(Rec.GetRangeMin("Worksheet Template Name")) then
                        exit(BinCreateWkshTmpl.Name + ' ' + BinCreateWkshTmpl.Description);
    end;
}

