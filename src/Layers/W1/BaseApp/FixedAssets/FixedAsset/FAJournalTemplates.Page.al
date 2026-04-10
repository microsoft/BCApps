// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using System.Reflection;

page 5630 "FA Journal Templates"
{
    AdditionalSearchTerms = 'fixed asset journal templates';
    ApplicationArea = FixedAssets;
    Caption = 'FA Journal Templates';
    PageType = List;
    SourceTable = "FA Journal Template";
    UsageCategory = Administration;
    AboutTitle = 'About FA Journal Template';
    AboutText = 'With the **FA Journal Template**, you can create new templates, review created templates, define the no. series and batches this will be used in different journals of fixed assets transactions.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = FixedAssets;

                    trigger OnValidate()
                    begin
                        SourceCodeOnAfterValidate();
                    end;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
                }
                field("Maint. Posting Report ID"; Rec."Maint. Posting Report ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Maint. Posting Report Caption"; Rec."Maint. Posting Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = FixedAssets;
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
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "FA Journal Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }

    local procedure SourceCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

