// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

using Microsoft.CostAccounting.Posting;

page 1135 "Cost Journal Batches"
{
    Caption = 'Cost Journal Batches';
    PageType = List;
    SourceTable = "Cost Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost journal batch.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost journal batch.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Bal. Cost Type No."; Rec."Bal. Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the type that a balancing entry for the journal line is posted to.';
                }
                field("Bal. Cost Center Code"; Rec."Bal. Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the cost center that a balancing entry for the journal line is posted to.';
                }
                field("Bal. Cost Object Code"; Rec."Bal. Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the cost center that a balancing entry for the journal line is posted to.';
                }
                field("Delete after Posting"; Rec."Delete after Posting")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if the posted journal lines are deleted. If the check box is not selected, you can use the posted journal lines again. After the posting, only the posting date is deleted. You can use the option for monthly recurring cost entries.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Edit Journal")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Enable editing of the cost journal.';

                trigger OnAction()
                begin
                    CostJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            action("P&ost")
            {
                ApplicationArea = CostAccounting;
                Caption = 'P&ost';
                Image = PostOrder;
                RunObject = Codeunit "CA Jnl.-B. Post";
                ShortCutKey = 'F9';
                ToolTip = 'Post information in the journal to the related cost register, such as pure cost entries, internal charges between cost centers, manual allocations, and corrective entries between cost types, cost centers, and cost objects.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Journal Template Name");
    end;

    trigger OnOpenPage()
    begin
        CostJnlMgt.OpenJnlBatch(Rec);
    end;

    var
        CostJnlMgt: Codeunit CostJnlManagement;
}

