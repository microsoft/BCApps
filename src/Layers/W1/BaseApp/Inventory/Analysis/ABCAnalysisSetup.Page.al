// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7160 "ABC Analysis Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'ABC Analysis Setup';
    SourceTable = "ABC Analysis Setup";
    PageType = Card;
    DeleteAllowed = false;
    InsertAllowed = false;
    UsageCategory = Administration;
    AboutTitle = 'About ABC Analysis Setup';
    AboutText = 'Set up the percentage boundaries for ABC Analysis categories in the Inventory Analysis reports. Category A typically represents the most valuable items, Category B represents moderately valuable items, and Category C represents the least valuable items. The sum of the percentages for all three categories must equal 100%.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Category A"; Rec."Category A")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of total value that defines Category A items.';

                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                        UpdateNotification();
                    end;
                }
                field("Category B"; Rec."Category B")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of total value that defines Category B items.';
                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                        UpdateNotification();
                    end;
                }
                field("Category C"; Rec."Category C")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of total value that defines Category C items.';

                    trigger OnValidate()
                    begin
                        StyleExpr := GetStatusStyleExpr();
                        CalculateBoundaries();
                        UpdateNotification();
                    end;
                }
                field(Sum; Rec."Category A" + Rec."Category B" + Rec."Category C")
                {
                    ApplicationArea = All;
                    Caption = 'Sum';
                    AutoFormatType = 0;
                    Editable = false;
                    StyleExpr = StyleExpr;
                    ToolTip = 'Specifies  the total percentage of all categories. The sum must equal 100%.';
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
                    ToolTip = 'Specifies the lower bound percentage for Category A.';
                }
                field(CatAUpperBound; CatAUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                    ToolTip = 'Specifies the upper bound percentage for Category A.';
                }
            }
            group("Category B Setup")
            {
                Caption = 'Category B';
                Editable = false;

                field(CatBLowerBound; CatBLowerBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Lower Bound (%)';
                    Editable = false;
                    ToolTip = 'Specifies the lower bound percentage for Category B.';
                }
                field(CatBUpperBound; CatBUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                    ToolTip = 'Specifies the upper bound percentage for Category B.';
                }
            }
            group("Category C Setup")
            {
                Caption = 'Category C';
                Editable = false;

                field(CatCLowerBound; CatCLowerBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Lower Bound (%)';
                    Editable = false;
                    ToolTip = 'Specifies the lower bound percentage for Category C.';
                }
                field(CatCUpperBound; CatCUpperBound)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Upper Bound (%)';
                    Editable = false;
                    ToolTip = 'Specifies the upper bound percentage for Category C.';
                }
            }
        }
    }

    var
        SumNotification: Notification;
        CatALowerBound: Decimal;
        CatAUpperBound: Decimal;
        CatBLowerBound: Decimal;
        CatBUpperBound: Decimal;
        CatCLowerBound: Decimal;
        CatCUpperBound: Decimal;
        StyleExpr: Text;
        SumNotificationMsg: Label 'The total of Category A, B, and C percentages does not equal 100%. Please adjust the values before closing the page.';
        SumNotificationIdTok: Label '5a2f8c3e-1b4d-4e6a-9f0c-7d8e2a1b3c4d', Locked = true;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.InitializeValues();
            Rec.Insert();
        end;
        CalculateBoundaries();
        UpdateNotification();
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
        CatALowerBound := 0;
        CatAUpperBound := Rec."Category A";

        CatBLowerBound := CatAUpperBound;
        CatBUpperBound := CatBLowerBound + Rec."Category B";

        CatCLowerBound := CatBUpperBound;
        CatCUpperBound := CatCLowerBound + Rec."Category C";
    end;

    local procedure UpdateNotification()
    begin
        SumNotification.Id := SumNotificationIdTok;
        SumNotification.Scope := NotificationScope::LocalScope;
        if Rec."Category A" + Rec."Category B" + Rec."Category C" <> 100 then begin
            SumNotification.Message := SumNotificationMsg;
            SumNotification.Send();
        end else
            SumNotification.Recall();
    end;
}