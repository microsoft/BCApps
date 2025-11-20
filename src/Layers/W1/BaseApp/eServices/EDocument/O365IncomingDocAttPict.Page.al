// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 2123 "O365 Incoming Doc. Att. Pict."
{
    Caption = 'Attachment Picture';
    DataCaptionExpression = Rec.Name;
    Editable = false;
    PageType = Card;
    SourceTable = "Incoming Document Attachment";
    SourceTableView = where(Type = const(Image));

    layout
    {
        area(content)
        {
            field(AttachmentContent; Rec.Content)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the content of the attachment. ';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteLine)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Remove attachment';
                Image = Delete;

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst, true) then
                        exit;
                    Rec.Delete();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(DeleteLine_Promoted; DeleteLine)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not IncomingDocumentAttachment.Get(Rec."Incoming Document Entry No.", Rec."Line No.") then
            IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.CalcFields(Content);
        Rec.SetRecFilter();
    end;

    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DeleteQst: Label 'Are you sure?';
}