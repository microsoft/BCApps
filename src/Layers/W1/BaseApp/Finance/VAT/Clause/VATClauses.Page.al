// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.ExtendedText;

/// <summary>
/// List page for managing VAT clauses with access to translations, document-type descriptions, and extended texts.
/// Primary interface for VAT clause administration and setup across the system.
/// </summary>
/// <remarks>
/// Provides navigation to VAT clause translations, document-type-specific descriptions, and VAT posting setup.
/// Supports multilingual VAT clause management and regulatory compliance requirements.
/// </remarks>
page 747 "VAT Clauses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Clauses';
    PageType = List;
    SourceTable = "VAT Clause";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
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
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Clause Code" = field(Code);
                ToolTip = 'View or edit combinations of VAT business posting groups and VAT product posting groups.';
            }
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                RunObject = Page "VAT Clause Translations";
                RunPageLink = "VAT Clause Code" = field(Code);
                ToolTip = 'View or edit translations for each VAT clause description in different languages.';
            }
            action("DescriptionByDocumentType")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description by document type';
                Image = Invoice;
                RunObject = Page "VAT Clauses by Doc. Type";
                RunPageLink = "VAT Clause Code" = field(Code);
                ToolTip = 'View or edit VAT clause descriptions by document type.';
            }
            action("E&xtended Texts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E&xtended Texts';
                Image = Text;
                RunObject = Page "Extended Text List";
                RunPageLink = "Table Name" = const("VAT Clause"),
                              "No." = field(Code);
                RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                ToolTip = 'View additional information that has been added to the description for the VAT clause.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
                actionref("T&ranslation_Promoted"; "T&ranslation")
                {
                }
                actionref(DescriptionByDocumentType_Promoted; DescriptionByDocumentType)
                {
                }
                actionref("E&xtended Texts_Promoted"; "E&xtended Texts")
                {
                }
            }
        }
    }
}

