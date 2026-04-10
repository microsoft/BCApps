// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using System.Reflection;

/// <summary>
/// Provides a list view of general journal templates for selection and basic template information display.
/// Enables users to browse available journal templates and select appropriate templates for journal creation.
/// </summary>
/// <remarks>
/// Read-only list page for journal template selection. Used primarily as a lookup page for template selection
/// during journal batch creation and configuration processes.
/// Key features: Template browsing, template information display, template selection for batch creation.
/// Integration: Used by journal batch setup processes and template lookup functions throughout the journal system.
/// </remarks>
page 250 "General Journal Template List"
{
    Caption = 'General Journal Template List';
    Editable = false;
    PageType = List;
    SourceTable = "Gen. Journal Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Force Doc. Balance"; Rec."Force Doc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether transactions that are posted in the general journal must balance by document number and document type.';
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unlink Inc. Doc On Posting"; Rec."Unlink Inc. Doc On Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the the incoming document will be unlinked from the journal when it is posted. This option can be enabled only for recurring journals.';
                    Visible = false;
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
    }
}

