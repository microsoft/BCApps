// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 191 "Incoming Documents Setup"
{
    AdditionalSearchTerms = 'electronic document setup,e-invoice setup,ocr setup,ecommerce setup,document exchange setup,import invoice setup';
    ApplicationArea = Suite;
    Caption = 'Incoming Documents Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Incoming Documents Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field("General Journal Template Name"; Rec."General Journal Template Name")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the general journal that new journal lines are created in when you choose the Journal Line button in the Incoming Documents window.';
            }
            field("General Journal Batch Name"; Rec."General Journal Batch Name")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the subtype of the general journal that new journal lines are created in when you choose the Journal Line button in the Incoming Documents window.';
            }
            field("Require Approval To Create"; Rec."Require Approval To Create")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies whether the incoming document line must be approved before a document or journal line can be created from the Incoming Documents window.';
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Approvers)
            {
                ApplicationArea = Suite;
                Caption = 'Approvers';
                Image = Users;
                RunObject = Page "Incoming Document Approvers";
                ToolTip = 'View or add incoming document approvers.';
                Visible = false;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Approvers_Promoted; Approvers)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

