// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Displays a list of standard sales codes assigned to a specific customer.
/// </summary>
page 173 "Standard Customer Sales Codes"
{
    Caption = 'Recurring Sales Lines';
    DataCaptionFields = "Customer No.";
    PageType = List;
    SourceTable = "Standard Customer Sales Code";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Valid From Date"; Rec."Valid From Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Valid To date"; Rec."Valid To date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insert Rec. Lines On Quotes"; Rec."Insert Rec. Lines On Quotes")
                {
                    ApplicationArea = Suite;
                }
                field("Insert Rec. Lines On Orders"; Rec."Insert Rec. Lines On Orders")
                {
                    ApplicationArea = Suite;
                }
                field("Insert Rec. Lines On Invoices"; Rec."Insert Rec. Lines On Invoices")
                {
                    ApplicationArea = Suite;
                }
                field("Insert Rec. Lines On Cr. Memos"; Rec."Insert Rec. Lines On Cr. Memos")
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
        area(processing)
        {
            group("&Sales")
            {
                Caption = '&Sales';
                Image = Sales;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Standard Sales Code Card";
                    RunPageLink = Code = field(Code);
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Card_Promoted; Card)
                {
                }
            }
        }
    }

    /// <summary>
    /// Gets the selected records from the page.
    /// </summary>
    /// <param name="StdCustSalesCode">Returns the selected standard customer sales code records.</param>
    procedure GetSelected(var StdCustSalesCode: Record "Standard Customer Sales Code")
    begin
        CurrPage.SetSelectionFilter(StdCustSalesCode);
    end;
}

