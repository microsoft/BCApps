// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12455 "Posted Service Credit Memos IT" extends "Posted Service Credit Memos"
{
    actions
    {
        addafter(ActivityLog)
        {
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServCrMemoUpdate: Page "Posted Serv. Cr. Memo - Update";
                begin
                    PostedServCrMemoUpdate.LookupMode := true;
                    PostedServCrMemoUpdate.SetRec(Rec);
                    PostedServCrMemoUpdate.RunModal();
                end;
            }
        }
        addbefore(Category_CategoryPrint)
        {
            actionref("Update Document_Promoted"; "Update Document")
            {
            }
        }
    }
}