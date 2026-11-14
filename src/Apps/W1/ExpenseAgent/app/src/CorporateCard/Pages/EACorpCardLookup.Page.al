// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7450 "EA Corp Card Lookup"
{
    Caption = 'Select Corporate Card';
    PageType = List;
    SourceTable = "EA Corp Card";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Cards)
            {
                field(CorporateCard; CorpCardSelectionMgt.GetCardDisplay(Rec, Rec."Provider Short Name"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Corporate Card';
                    ToolTip = 'Specifies the provider short name followed by the last four digits of the corporate card.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider code to distinguish providers with the same name.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Card Id"; Rec."Card Id")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }

        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Provider Short Name");
    end;

    var
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
}
