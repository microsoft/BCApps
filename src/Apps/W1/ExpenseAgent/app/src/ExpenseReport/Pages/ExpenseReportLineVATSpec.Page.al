// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7081 "Expense Report Line VAT Spec."
{
    Caption = 'Expense Report Line VAT Specification';
    PageType = List;
    SourceTable = "Expense Report Line VAT Spec.";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Visible = false;
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    Caption = 'Expense Category Code';
                    ToolTip = 'Specifies the expense category code for this VAT row.';
                }
                field("Expense Subcategory"; Rec."Expense Subcategory")
                {
                    Caption = 'Expense Subcategory Code';
                    ToolTip = 'Specifies the expense subcategory code for this VAT row.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
                }
                field("VAT %"; Rec."VAT %")
                {
                    Caption = 'VAT %';
                }
                field(Amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                    Editable = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                    Editable = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field("VAT Base Amount (LCY)"; Rec."VAT Base Amount (LCY)")
                {
                    Caption = 'VAT Base Amount (LCY)';
                    Editable = false;
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    Caption = 'VAT Amount (LCY)';
                    Editable = false;
                }
                field("Amount (RCY)"; Rec."Amount (RCY)")
                {
                    Caption = 'Amount (RCY)';
                    Editable = false;
                }
                field("VAT Base Amount (RCY)"; Rec."VAT Base Amount (RCY)")
                {
                    Caption = 'VAT Base Amount (RCY)';
                    Editable = false;
                }
                field("VAT Amount (RCY)"; Rec."VAT Amount (RCY)")
                {
                    Caption = 'VAT Amount (RCY)';
                    Editable = false;
                }
                field(Reclaimable; Rec.Reclaimable)
                {
                    Caption = 'Reclaimable';
                }
                field("Reclaim %"; Rec."Reclaim %")
                {
                    Caption = 'Reclaim %';
                }
                field("Reclaim VAT Amount"; Rec."Reclaim VAT Amount")
                {
                    Caption = 'Reclaim VAT Amount';
                    Editable = false;
                }
                field("Reclaim VAT Amount (LCY)"; Rec."Reclaim VAT Amount (LCY)")
                {
                    Caption = 'Reclaim VAT Amount (LCY)';
                    Editable = false;
                }
                field("Reclaim VAT Amount (RCY)"; Rec."Reclaim VAT Amount (RCY)")
                {
                    Caption = 'Reclaim VAT Amount (RCY)';
                    Editable = false;
                }
                field("Reclaim Reason"; Rec."Reclaim Reason")
                {
                    Caption = 'Reclaim Reason';
                }
                field("Reclaim Status"; Rec."Reclaim Status")
                {
                    Caption = 'Reclaim Status';
                    Editable = false;
                    StyleExpr = ReclaimStatusStyle;
                    ToolTip = 'Specifies whether the VAT reclaim for this row is pending, approved, or rejected.';
                }
#if not CLEAN29
                field("Reclaim Approved"; Rec."Reclaim Approved")
                {
                    Caption = 'Reclaim Approved';
                    Editable = false;
                    Visible = false;
                    ObsoleteReason = 'Replaced by field Reclaim Status';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                }
#endif
                field("Reclaim Approved By"; Rec."Reclaim Approved By")
                {
                    Caption = 'Reclaim Approved By';
                    Editable = false;
                }
                field("Reclaim Approved At"; Rec."Reclaim Approved At")
                {
                    Caption = 'Reclaim Approved At';
                    Editable = false;
                }
                field(Source; Rec.Source)
                {
                    Caption = 'Source';
                    Editable = false;
                }
                field(Confidence; Rec.Confidence)
                {
                    Caption = 'Confidence';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ReclaimApproval)
            {
                Caption = 'Reclaim Approval';
                Image = Approval;

                action(ApproveReclaim)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve Reclaim';
                    Image = Approve;
                    ToolTip = 'Approve the VAT reclaim for the selected line.';

                    trigger OnAction()
                    begin
                        Rec.Validate("Reclaim Status", Rec."Reclaim Status"::Approved);
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                }
                action(ApproveAllReclaims)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve All Reclaims';
                    Image = Approve;
                    ToolTip = 'Approve all VAT reclaims for the selected expense report line.';

                    trigger OnAction()
                    var
                        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
                    begin
                        ExpenseReportLineVATSpec.SetRange("Document No.", Rec."Document No.");
                        ExpenseReportLineVATSpec.SetRange("Document Line No.", Rec."Document Line No.");
                        ExpenseReportLineVATSpec.SetRange("Reclaim Status", ExpenseReportLineVATSpec."Reclaim Status"::Pending);
                        if ExpenseReportLineVATSpec.FindSet(true) then
                            repeat
                                ExpenseReportLineVATSpec.Validate("Reclaim Status", Rec."Reclaim Status"::Approved);
                                ExpenseReportLineVATSpec.Modify(true);
                            until ExpenseReportLineVATSpec.Next() = 0;
                        CurrPage.Update(false);
                    end;
                }
                action(RejectReclaim)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject Reclaim';
                    Image = Reject;
                    ToolTip = 'Reject the VAT reclaim for the selected line.';

                    trigger OnAction()
                    begin
                        Rec.Validate("Reclaim Status", Rec."Reclaim Status"::Rejected);
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(ApproveReclaim_Promoted; ApproveReclaim)
                {
                }
                actionref(ApproveAllReclaims_Promoted; ApproveAllReclaims)
                {
                }
                actionref(RejectReclaim_Promoted; RejectReclaim)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec."Reclaim Status" of
            Rec."Reclaim Status"::Approved:
                ReclaimStatusStyle := 'Favorable';
            Rec."Reclaim Status"::Rejected:
                ReclaimStatusStyle := 'Unfavorable';
            else
                ReclaimStatusStyle := 'Standard';
        end;
    end;

    var
        ReclaimStatusStyle: Text;
}
