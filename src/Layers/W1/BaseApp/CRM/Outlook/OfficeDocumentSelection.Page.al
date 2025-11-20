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
                    ToolTip = 'Specifies the document type that the entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = true;
                    ToolTip = 'Specifies the number of the involved document.';
                }
                field(Series; Rec.Series)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the series of the involved document, such as Purchasing or Sales.';
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the involved document has been posted.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
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

