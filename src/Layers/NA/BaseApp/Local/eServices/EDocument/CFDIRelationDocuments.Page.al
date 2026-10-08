// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27006 "CFDI Relation Documents"
{
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "CFDI Relation Document";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Related Doc. Type"; Rec."Related Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related document type.';
                }
                field("Related Doc. No."; Rec."Related Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related document number.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("SAT Relation Type"; Rec."SAT Relation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relation of the CFDI document. ';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fiscal invoice number of the related document number.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(InsertRelatedCreditMemos)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Related Credit Memos';
                Image = ReturnRelated;
                ToolTip = 'Insert credit memo documents related to the current document line.';

                trigger OnAction()
                begin
                    Rec.InsertRelatedCreditMemos();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(InsertRelatedCreditMemos_Promoted; InsertRelatedCreditMemos)
                {
                }
            }
        }
    }
}

