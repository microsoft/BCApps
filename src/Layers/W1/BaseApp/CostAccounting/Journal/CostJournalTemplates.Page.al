// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

page 1107 "Cost Journal Templates"
{
    ApplicationArea = CostAccounting;
    Caption = 'Cost Journal Templates';
    PageType = List;
    SourceTable = "Cost Journal Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost journal entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost journal entry.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplates")
            {
                Caption = 'Te&mplates';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Cost Journal Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'Open the list of journal batches for the journal template. ';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }
}

