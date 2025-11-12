// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 2158 "O365 Brand Colors"
{
    Caption = 'Email Color Schemas';
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Brand Color";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Sample Picture"; Rec."Sample Picture")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CheckCreateDefaultBrandColors();
    end;

    local procedure CheckCreateDefaultBrandColors()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if O365BrandColor.IsEmpty() then
            O365BrandColor.CreateDefaultBrandColors();
    end;
}

