// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

page 386 "Extended Text"
{
    Caption = 'Extended Text';
    DataCaptionExpression = Rec.GetCaption();
    PageType = ListPlus;
    PopulateAllFields = true;
    SourceTable = "Extended Text Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Suite;
                }
                field("All Language Codes"; Rec."All Language Codes")
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
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
            }
            part(Control25; "Extended Text Lines")
            {
                ApplicationArea = Suite;
                SubPageLink = "Table Name" = field("Table Name"),
                              "No." = field("No."),
                              "Language Code" = field("Language Code"),
                              "Text No." = field("Text No.");
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales Quote"; Rec."Sales Quote")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Sales Blanket Order"; Rec."Sales Blanket Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Sales Order"; Rec."Sales Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Sales Invoice"; Rec."Sales Invoice")
                {
                    ApplicationArea = Suite;
                }
                field("Sales Return Order"; Rec."Sales Return Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                }
                field("Sales Credit Memo"; Rec."Sales Credit Memo")
                {
                    ApplicationArea = Suite;
                }
                field(Reminder; Rec.Reminder)
                {
                    ApplicationArea = Suite;
                }
                field("Finance Charge Memo"; Rec."Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                }
                field("Prepmt. Sales Invoice"; Rec."Prepmt. Sales Invoice")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Prepmt. Sales Credit Memo"; Rec."Prepmt. Sales Credit Memo")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field(Job; Rec.Job)
                {
                    ApplicationArea = Jobs;
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase Quote"; Rec."Purchase Quote")
                {
                    ApplicationArea = Suite;
                }
                field("Purchase Blanket Order"; Rec."Purchase Blanket Order")
                {
                    ApplicationArea = Suite;
                }
                field("Purchase Order"; Rec."Purchase Order")
                {
                    ApplicationArea = Suite;
                }
                field("Purchase Invoice"; Rec."Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purchase Return Order"; Rec."Purchase Return Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purchase Credit Memo"; Rec."Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Prepmt. Purchase Invoice"; Rec."Prepmt. Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Prepmt. Purchase Credit Memo"; Rec."Prepmt. Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
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

