// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

page 36982 "PowerBI ABC Analysis Setup"
{
    Caption = 'ABC Analysis Setup';
    SourceTable = "PowerBI ABC Analysis Setup";
    PageType = Card;
    DeleteAllowed = false;
    InsertAllowed = false;
    AboutTitle = 'About ABC Analysis Setup';
    AboutText = 'Set up the percentage boundaries for ABC Analysis categories in the Power BI Inventory reports. Category A typically represents the most valuable items, Category B represents moderately valuable items, and Category C represents the least valuable items. The sum of the percentages for all three categories must equal 100%.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = true;

                field("Category A"; Rec."Category A")
                {
                    ApplicationArea = All;
                    Caption = 'A Category';

                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                    end;
                }
                field("Category B"; Rec."Category B")
                {
                    ApplicationArea = All;
                    Caption = 'B Category';

                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                    end;
                }
                field("Category C"; Rec."Category C")
                {
                    ApplicationArea = All;
                    Caption = 'C Category';

                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                    end;
                }
                field(Sum; Rec."Category A" + Rec."Category B" + Rec."Category C")
                {
                    ApplicationArea = All;
                    Caption = 'Sum';
                    AutoFormatType = 0;
                    Editable = false;
                    StyleExpr = StyleExpr;
                }
            }
            group("Category A Setup")
            {
                Caption = 'Category A';
                Editable = false;

                field(CatALowerBound; CatALowerBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Lower Bound (%)';
                    Editable = false;
                }
                field(CatAUpperBound; CatAUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                }
            }
            group("Category B Setup")
            {
                Caption = 'Category B';
                Editable = false;

                field(CatBLowerbound; CatBLowerbound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Lower Bound (%)';
                    Editable = false;
                }
                field(CatBUpperBound; CatBUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                }
            }
            group("Category C Setup")
            {
                Caption = 'Category C';
                Editable = false;

                field(CatCLowerbound; CatCLowerbound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Lower Bound (%)';
                    Editable = false;
                }
                field(CatCUpperBound; CatCUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                }
            }
        }
    }

    var
        CatALowerbound: Decimal;
        CatAUpperBound: Decimal;
        CatBLowerbound: Decimal;
        CatBUpperBound: Decimal;
        CatCLowerbound: Decimal;
        CatCUpperBound: Decimal;
        StyleExpr: Text;

    trigger OnOpenPage()
    begin
        CalculateBoundaries();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Rec.ValidateCategoryFields();
    end;

    trigger OnAfterGetRecord()
    begin
        StyleExpr := GetStatusStyleExpr();
    end;

    local procedure GetStatusStyleExpr(): Text
    begin
        if (Rec."Category A" + Rec."Category B" + Rec."Category C" = 100) then
            exit('Favorable');

        exit('Unfavorable');
    end;

    local procedure CalculateBoundaries()
    begin
        CatALowerbound := 0;
        CatAUpperBound := Rec."Category A";

        CatBLowerbound := CatAUpperBound;
        CatBUpperBound := CatBLowerbound + Rec."Category B";

        CatCLowerbound := CatBUpperBound;
        CatCUpperBound := CatCLowerbound + Rec."Category C";
    end;
}