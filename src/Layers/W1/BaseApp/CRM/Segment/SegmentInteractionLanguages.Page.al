// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

page 5155 "Segment Interaction Languages"
{
    Caption = 'Segment Interaction Languages';
    DataCaptionExpression = Rec.Caption();
    PageType = List;
    SourceTable = "Segment Interaction Language";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the Segment Interaction Language. This field will not be displayed in the Word attachment.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the subject text. The text in the field is used as the subject in e-mails and Word documents.';
                }
                field(AttachmentText; Rec.AttachmentText())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        if Rec."Attachment No." = 0 then
                            Rec.CreateAttachment()
                        else
                            Rec.OpenAttachment();

                        CurrPage.Update();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Attachment")
            {
                Caption = '&Attachment';
                Image = Attachments;
                action(Open)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Open';
                    Image = Edit;
                    ShortCutKey = 'Return';
                    ToolTip = 'Open the card for the selected record.';

                    trigger OnAction()
                    begin
                        Rec.OpenAttachment();
                    end;
                }
                action(Create)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create';
                    Ellipsis = true;
                    Image = New;
                    ToolTip = 'Create an attachment.';

                    trigger OnAction()
                    begin
                        Rec.CreateAttachment();
                    end;
                }
                action("Copy &From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Copy &From';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy from an attachment.';

                    trigger OnAction()
                    begin
                        Rec.CopyFromAttachment();
                    end;
                }
                action(Import)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an attachment.';

                    trigger OnAction()
                    begin
                        Rec.ImportAttachment();
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export an attachment.';

                    trigger OnAction()
                    begin
                        Rec.ExportAttachment();
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Remove';
                    Ellipsis = true;
                    Image = Cancel;
                    ToolTip = 'Remove an attachment.';

                    trigger OnAction()
                    begin
                        Rec.RemoveAttachment(true);
                    end;
                }
            }
        }
    }
}

