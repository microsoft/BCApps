// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

page 1602 "Office Document Selection"
{
    Caption = 'Document Selection';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Office Document Selection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = true;
                }
                field(Series; Rec.Series)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("View Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Document';
                Image = ViewOrder;
                ShortCutKey = 'Return';
                ToolTip = 'View the selected document.';

                trigger OnAction()
                var
                    TempOfficeAddinContext: Record "Office Add-in Context" temporary;
                    OfficeMgt: Codeunit "Office Management";
                    OfficeDocumentHandler: Codeunit "Office Document Handler";
                begin
                    OfficeMgt.GetContext(TempOfficeAddinContext);
                    OfficeDocumentHandler.OpenIndividualDocument(TempOfficeAddinContext, Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("View Document_Promoted"; "View Document")
                {
                }
            }
        }
    }
}

