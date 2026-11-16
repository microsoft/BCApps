// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7083 "Posted Exp.Rep.Line VAT Spec"
{
    Caption = 'Posted Expense Report Line VAT Specification';
    PageType = List;
    SourceTable = "Posted Exp. Rep. Line VAT Spec";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

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
                    Editable = false;
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
                field("Reclaim Reason"; Rec."Reclaim Reason")
                {
                    Caption = 'Reclaim Reason';
                }
                field("Reclaim Status"; Rec."Reclaim Status")
                {
                    Caption = 'Reclaim Status';
                    Editable = false;
                }
#if not CLEAN29
                field("Reclaim Approved"; Rec."Reclaim Approved")
                {
                    Caption = 'Reclaim Approved';
                    Editable = false;
                    ObsoleteReason = 'Replaced by field REclaim Status';
                    ObsoleteState = pending;
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
}
