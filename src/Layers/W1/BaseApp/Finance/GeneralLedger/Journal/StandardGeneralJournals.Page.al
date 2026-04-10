// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Provides list view access to standard general journal templates for selection and management purposes.
/// Enables users to browse, select, and manage reusable journal templates for efficient journal entry creation.
/// </summary>
/// <remarks>
/// Standard journal template list for template management and selection. Provides access to all available
/// standard journal templates with options for creation, modification, and deletion of template configurations.
/// Key features: Template browsing, template selection, template management, journal line generation from templates.
/// Integration: Used for template selection during journal creation and management of reusable journal patterns.
/// </remarks>
page 750 "Standard General Journals"
{
    Caption = 'Standard General Journals';
    CardPageID = "Standard General Journal";
    DataCaptionFields = "Journal Template Name";
    PageType = List;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Standard General Journal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
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
            group("&Standard")
            {
                Caption = '&Standard';
                Image = Journal;
                action(ShowJournal)
                {
                    ApplicationArea = Suite;
                    Caption = '&Show Journal';
                    Image = Journal;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open a journal based on the journal batch that you selected.';

                    trigger OnAction()
                    var
                        StdGenJnl: Record "Standard General Journal";
                    begin
                        StdGenJnl.SetRange("Journal Template Name", Rec."Journal Template Name");
                        StdGenJnl.SetRange(Code, Rec.Code);

                        PAGE.Run(PAGE::"Standard General Journal", StdGenJnl);
                    end;
                }
            }
        }
    }
}

