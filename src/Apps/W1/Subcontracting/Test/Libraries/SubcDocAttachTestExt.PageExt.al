// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Attachment;

pageextension 139981 "Subc. Doc Attach Test Ext." extends "Document Attachment Details"
{
    actions
    {
        addlast(processing)
        {
            action(DeleteAttachmentForTest)
            {
                ApplicationArea = All;
                Caption = 'Delete attachment for test';
                Image = Delete;
                ToolTip = 'Deletes the current attachment for automated testing.';

                trigger OnAction()
                begin
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}