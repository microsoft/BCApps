// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 1670 "Option Lookup List"
{
    Caption = 'Option Lookup List';
    Editable = false;
    PageType = List;
    SourceTable = "Option Lookup Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Option Caption"; Rec."Option Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction you want to make. The value in this field determines what you can select in the No. field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        OptionLookupBuffer: Record "Option Lookup Buffer";
    begin
        if Rec.GetFilter("Lookup Type") = '' then
            exit;

        Evaluate(OptionLookupBuffer."Lookup Type", Rec.GetFilter("Lookup Type"));
        Rec.FillLookupBuffer(OptionLookupBuffer."Lookup Type");
        Rec.SetCurrentKey(ID);
    end;
}

