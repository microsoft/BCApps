// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

page 178 "Standard Vendor Purchase Codes"
{
    Caption = 'Recurring Purchase Lines';
    DataCaptionFields = "Vendor No.";
    PageType = List;
    SourceTable = "Standard Vendor Purchase Code";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor to which the standard purchase code is assigned.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a standard purchase code from the Standard Purchase Code table.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the standard purchase code.';
                }
                field("Insert Rec. Lines On Quotes"; Rec."Insert Rec. Lines On Quotes")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard purchase codes on purchase quotes.';
                }
                field("Insert Rec. Lines On Orders"; Rec."Insert Rec. Lines On Orders")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard purchase codes on purchase orders.';
                }
                field("Insert Rec. Lines On Invoices"; Rec."Insert Rec. Lines On Invoices")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard purchase codes on purchase invoices.';
                }
                field("Insert Rec. Lines On Cr. Memos"; Rec."Insert Rec. Lines On Cr. Memos")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to use standard purchase codes on purchase credit memos.';
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
            group("&Purchase")
            {
                Caption = '&Purchase';
                Image = Purchasing;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Standard Purchase Code Card";
                    RunPageLink = Code = field(Code);
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Specifies a standard purchase code from the Standard Purchase Code table.';
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

    procedure GetSelected(var StdVendPurchCode: Record "Standard Vendor Purchase Code")
    begin
        CurrPage.SetSelectionFilter(StdVendPurchCode);
    end;
}

