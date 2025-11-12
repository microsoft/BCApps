// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 316 "Allocation Policies"
{
    PageType = List;
    ApplicationArea = Reservation;
    SourceTable = "Allocation Policy";
    Caption = 'Allocation Policy';
    PopulateAllFields = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            field(PageDescription; PageDescriptionTxt)
            {
                ToolTip = 'Specifies the description of the page.';
                ShowCaption = false;
                Editable = false;
            }
            repeater(Shortage)
            {
                field("Step No."; Rec."Line No.")
                {
                    Caption = 'Step No.';
                    ToolTip = 'Specifies the step number of the allocation policy.';
                }
                field("Name"; Rec."Allocation Rule")
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the allocation policy. Click or tap the AssistEdit button to see an example of how the allocation policy will be applied.';

                    trigger OnAssistEdit()
                    begin
                        if (Rec."Allocation Rule" <> Rec."Allocation Rule"::" ") and GuiAllowed() then
                            Message(Rec.GetAllocationPolicyDescription());
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Move Up")
            {
                Caption = 'Move Up';
                Image = MoveUp;
                ToolTip = 'Move the selected line up in the list.';

                trigger OnAction()
                var
                    AllocationPolicy: Record "Allocation Policy";
                begin
                    AllocationPolicy.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    AllocationPolicy := Rec;
                    if Rec.Find() and AllocationPolicy.Find('<') then begin
                        ExchangeLines(AllocationPolicy, Rec);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action("Move Down")
            {
                Caption = 'Move Down';
                Image = MoveDown;
                ToolTip = 'Move the selected line down in the list.';

                trigger OnAction()
                var
                    AllocationPolicy: Record "Allocation Policy";
                begin
                    AllocationPolicy.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    AllocationPolicy := Rec;
                    if Rec.Find() and AllocationPolicy.Find('>') then begin
                        ExchangeLines(AllocationPolicy, Rec);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("Move Up_Promoted"; "Move Up") { }
                actionref("Move Down_Promoted"; "Move Down") { }
            }
        }
    }

    var
        PageDescriptionTxt: Label 'Specify one or more allocation policies to control how you distribute available inventory among demands.';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Line No." := Rec.GetNextLineNo();
    end;

    local procedure ExchangeLines(var AllocationPolicy1: Record "Allocation Policy"; var AllocationPolicy2: Record "Allocation Policy")
    var
        LineNo: Integer;
    begin
        AllocationPolicy1.Delete();
        AllocationPolicy2.Delete();

        LineNo := AllocationPolicy1."Line No.";
        AllocationPolicy1."Line No." := AllocationPolicy2."Line No.";
        AllocationPolicy2."Line No." := LineNo;

        AllocationPolicy1.Insert();
        AllocationPolicy2.Insert();
    end;
}
