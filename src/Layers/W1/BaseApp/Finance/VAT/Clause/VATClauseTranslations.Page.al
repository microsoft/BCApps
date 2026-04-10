// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

/// <summary>
/// List page for managing multilingual translations of VAT clause descriptions.
/// Enables localized VAT clause text for international business operations and regulatory requirements.
/// </summary>
/// <remarks>
/// Provides language-specific VAT clause translation management for global compliance.
/// Supports customer-specific language requirements for VAT clause display on documents.
/// </remarks>
page 748 "VAT Clause Translations"
{
    Caption = 'VAT Clause Translations';
    DataCaptionFields = "VAT Clause Code";
    PageType = List;
    SourceTable = "VAT Clause Translation";

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

