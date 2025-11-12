// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

page 734 "VAT Clauses by Doc. Type"
{
    Caption = 'VAT Clauses by Document Type';
    DataCaptionFields = "VAT Clause Code";
    PageType = List;
    SourceTable = "VAT Clause by Doc. Type";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type, which is used to provide a VAT description associated with a sales line on a sales invoice, credit memo, or other sales document.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translation of the VAT clause description. The translated version of the description is displayed as the VAT clause, based on the Language Code setting on the customer card.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translation of the additional VAT clause description.';
                }
            }
            systempart(Control6; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control7; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                RunObject = Page "VAT Clause by Doc. Type Trans.";
                RunPageLink = "VAT Clause Code" = field("VAT Clause Code"),
                              "Document Type" = field("Document Type");
                ToolTip = 'View or edit translations for each VAT clause description in different languages.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("T&ranslation_Promoted"; "T&ranslation")
                {
                }
            }
        }
    }
}

