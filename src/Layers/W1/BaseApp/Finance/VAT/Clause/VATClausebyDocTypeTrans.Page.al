// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

/// <summary>
/// List page for managing multilingual translations of document-type-specific VAT clause descriptions.
/// Enables localized VAT clause text for specific document types across multiple languages.
/// </summary>
/// <remarks>
/// Provides translation management for document-type-specific VAT clauses supporting international operations.
/// Combines document type specialization with multilingual support for comprehensive VAT compliance.
/// </remarks>
page 735 "VAT Clause by Doc. Type Trans."
{
    Caption = 'VAT Clause by Document Type Translations';
    DataCaptionFields = "VAT Clause Code", "Document Type";
    PageType = List;
    SourceTable = "VAT Clause by Doc. Type Trans.";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
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
        }
        area(factboxes)
        {
            systempart(Control7; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control8; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

