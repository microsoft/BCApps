// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

page 5652 "Insurance Journal Templates"
{
    ApplicationArea = FixedAssets;
    Caption = 'Insurance Journal Templates';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Insurance Journal Template";
    UsageCategory = Administration;
    AnalysisModeEnabled = false;

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
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
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
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
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
                    RunObject = Page "Insurance Journal Batches";
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

