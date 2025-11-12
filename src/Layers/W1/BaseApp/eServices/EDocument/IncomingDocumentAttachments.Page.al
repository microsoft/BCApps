// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 194 "Incoming Document Attachments"
{
    AutoSplitKey = true;
    Caption = 'Files';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Inc. Doc. Attachment Overview";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationControls = Name;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the name of the record.';

                    trigger OnDrillDown()
                    begin
                        Rec.NameDrillDown();
                    end;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the file type of the attached file.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the attached file.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the incoming document line was created.';
                    Visible = false;
                }
                field("Created By User Name"; Rec."Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user who created the incoming document line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View File';
                Enabled = Rec."Line No." <> 0;
                Image = Document;
                Scope = Repeater;
                ToolTip = 'View the file that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    Rec.NameDrillDown();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.GetStyleTxt();
    end;

    var
        StyleTxt: Text;

    procedure LoadDataIntoPart(IncomingDocument: Record "Incoming Document")
    begin
        Rec.DeleteAll();
        Rec.InsertSupportingAttachmentsFromIncomingDocument(IncomingDocument, Rec);
        CurrPage.Update(false);
    end;
}

