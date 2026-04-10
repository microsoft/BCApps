// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Reflection;

/// <summary>
/// Management interface for VAT statement templates.
/// Provides template creation, modification, and configuration for VAT statement structure and formatting.
/// </summary>
page 318 "VAT Statement Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement Templates';
    PageType = List;
    SourceTable = "VAT Statement Template";
    UsageCategory = Administration;

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
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page number.';
                }
                field("VAT Statement Report ID"; Rec."VAT Statement Report ID")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the ID of the report that you can print for the VAT statement template.';
                }
                field("VAT Stat. Export Report ID"; Rec."VAT Stat. Export Report ID")
                {
                    ApplicationArea = VAT;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the batch job that must be used to export the annual VAT communication to an ASCII file.';
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
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action("Statement Names")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statement Names';
                    Image = List;
                    RunObject = Page "VAT Statement Names";
                    RunPageLink = "Statement Template Name" = field(Name);
                    ToolTip = 'View or edit special tables to manage the tasks necessary for settling Tax and reporting to the customs and tax authorities.';
                }
            }
        }
    }
}

