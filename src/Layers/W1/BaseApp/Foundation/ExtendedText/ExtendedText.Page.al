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
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("All Language Codes"; Rec."All Language Codes")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text should be used for all language codes. If a language code has been chosen in the Language Code field, it will be overruled by this function.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the content of the extended item description.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date from which the text will be used on the item, account, resource or standard text.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date on which the text will no longer be used on the item, account, resource or standard text.';
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
                    ToolTip = 'Specifies whether the text will be available on sales quotes.';
                }
                field("Sales Blanket Order"; Rec."Sales Blanket Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales blanket orders.';
                }
                field("Sales Order"; Rec."Sales Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales orders.';
                }
                field("Sales Invoice"; Rec."Sales Invoice")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on sales invoices.';
                }
                field("Sales Return Order"; Rec."Sales Return Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales return orders.';
                }
                field("Sales Credit Memo"; Rec."Sales Credit Memo")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on sales credit memos.';
                }
                field(Reminder; Rec.Reminder)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the extended text will be available on reminders.';
                }
                field("Finance Charge Memo"; Rec."Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the extended text will be available on finance charge memos.';
                }
                field("Prepmt. Sales Invoice"; Rec."Prepmt. Sales Invoice")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on prepayment sales invoices.';
                }
                field("Prepmt. Sales Credit Memo"; Rec."Prepmt. Sales Credit Memo")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on prepayment sales credit memos.';
                }
                field(Job; Rec.Job)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the text will be available on projects.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase Quote"; Rec."Purchase Quote")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase quotes.';
                }
                field("Purchase Blanket Order"; Rec."Purchase Blanket Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase blanket orders.';
                }
                field("Purchase Order"; Rec."Purchase Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase orders.';
                }
                field("Purchase Invoice"; Rec."Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase invoices.';
                }
                field("Purchase Return Order"; Rec."Purchase Return Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase return orders.';
                }
                field("Purchase Credit Memo"; Rec."Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase credit memos.';
                }
                field("Prepmt. Purchase Invoice"; Rec."Prepmt. Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on prepayment purchase invoices.';
                }
                field("Prepmt. Purchase Credit Memo"; Rec."Prepmt. Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on prepayment purchase credit memos.';
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

