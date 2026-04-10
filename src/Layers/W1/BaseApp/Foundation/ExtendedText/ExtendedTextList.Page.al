// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

page 391 "Extended Text List"
{
    Caption = 'Extended Text List';
    CardPageID = "Extended Text";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Extended Text Header";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Suite;
                }
                field("All Language Codes"; Rec."All Language Codes")
                {
                    ApplicationArea = Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
                field("Sales Quote"; Rec."Sales Quote")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sales Invoice"; Rec."Sales Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sales Order"; Rec."Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sales Credit Memo"; Rec."Sales Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Purchase Quote"; Rec."Purchase Quote")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Purchase Invoice"; Rec."Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Purchase Order"; Rec."Purchase Order")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Purchase Credit Memo"; Rec."Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
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

