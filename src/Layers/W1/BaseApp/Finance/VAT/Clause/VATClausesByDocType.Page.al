// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

/// <summary>
/// List page for managing document-type-specific VAT clause descriptions with translation access.
/// Enables configuration of specialized VAT clause text for different document types.
/// </summary>
/// <remarks>
/// Provides document-type-specific VAT clause management for invoices, credit memos, reminders, and finance charges.
/// Supports multilingual translations and regulatory compliance for document-specific VAT requirements.
/// </remarks>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
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

