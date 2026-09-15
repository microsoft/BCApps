// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

page 1115 "Cost Budget Entries"
{
    Caption = 'Cost Budget Entries';
    DataCaptionFields = "Cost Type No.", "Budget Name";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Cost Budget Entry";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost budget that the entry belongs to.';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the date of the cost budget entry.';
                }
                field("Cost Type No."; Rec."Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the subtype of the cost center. This is an information field and is not used for any other purposes. Choose the field to select the cost subtype.';
                }
                field("Cost Center Code"; Rec."Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; Rec."Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of the cost budget entries.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost budget entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("System-Created Entry"; Rec."System-Created Entry")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry created by the system for the cost budget entry.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Allocation ID"; Rec."Allocation ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the allocation key that the cost budget entry comes from.';
                }
                field(Allocated; Rec.Allocated)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the cost entry has been allocated.';
                }
                field("Allocated with Journal No."; Rec."Allocated with Journal No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost journal was used to allocate the cost budget.';
                }
                field("Allocation Description"; Rec."Allocation Description")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description that explains the allocation level and shares.';
                }
                field("Last Modified By User"; Rec."Last Modified By User")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the user who made the last change to the cost budget.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.SetCostBudgetRegNo(CurrRegNo);
        Rec.Insert(true);
        CurrRegNo := Rec.GetCostBudgetRegNo();
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Budget Name" := CostBudgetName.Name;
        if CostBudgetName.Name <> Rec."Budget Name" then
            CostBudgetName.Get(Rec."Budget Name");
        if Rec.GetFilter("Cost Type No.") <> '' then
            Rec."Cost Type No." := Rec.GetFirstCostType(Rec.GetFilter("Cost Type No."));
        if Rec.GetFilter("Cost Center Code") <> '' then
            Rec."Cost Center Code" := Rec.GetFirstCostCenter(Rec.GetFilter("Cost Center Code"));
        if Rec.GetFilter("Cost Object Code") <> '' then
            Rec."Cost Object Code" := Rec.GetFirstCostObject(Rec.GetFilter("Cost Object Code"));
        Rec.Date := Rec.GetFirstDate(Rec.GetFilter(Date));
        Rec."Last Modified By User" := UserId();
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Budget Name") = '' then
            CostBudgetName.Init()
        else begin
            Rec.CopyFilter("Budget Name", CostBudgetName.Name);
            CostBudgetName.FindFirst();
        end;
    end;

    var
        CostBudgetName: Record "Cost Budget Name";
        CurrRegNo: Integer;

    procedure SetCurrRegNo(RegNo: Integer)
    begin
        CurrRegNo := RegNo;
    end;

    procedure GetCurrRegNo(): Integer
    begin
        exit(CurrRegNo);
    end;
}

