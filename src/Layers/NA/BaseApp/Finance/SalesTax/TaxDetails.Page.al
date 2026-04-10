// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Configuration page for detailed tax rate settings by jurisdiction and tax group.
/// Provides interface for setting tax percentages, thresholds, and effective dates.
/// </summary>
page 468 "Tax Details"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Details';
    DataCaptionFields = "Tax Jurisdiction Code", "Tax Group Code";
    PageType = List;
    SourceTable = "Tax Detail";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Type"; Rec."Tax Type")
                {
                    ApplicationArea = SalesTax;
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Below Maximum"; Rec."Tax Below Maximum")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                }
                field("Maximum Amount/Qty."; Rec."Maximum Amount/Qty.")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                }
                field("Tax Above Maximum"; Rec."Tax Above Maximum")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                }
                field("Expense/Capitalize"; Rec."Expense/Capitalize")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if you want to expense or capitalize unrecoverable taxes that have been paid on purchases. The tax amount will be expensed or capitalized to the purchase debit account based on the value in the Type field on the purchase order lines. The debit will impact the purchase account (inventory), asset acquisition account (fixed asset), or other expense accounts (general ledger). The amount payable to the vendor will include the additional liability for the sales tax being charged. Therefore, when the vendor is paid for the accounts payable balance, the amount will include the amount of the goods in addition to the amount of the tax on those goods.';
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
            group("&Detail")
            {
                Caption = '&Detail';
                Image = View;
                action("Ledger &Entries")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Ledger &Entries';
                    Image = VATLedger;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View Tax entries, which result from posting transactions in journals and sales and purchase documents, and from the Calc. and Post Tax Settlement batch job.';

                    trigger OnAction()
                    var
                        VATEntry: Record "VAT Entry";
                    begin
                        VATEntry.SetCurrentKey("Tax Jurisdiction Code", "Tax Group Used", "Tax Type", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", Rec."Tax Jurisdiction Code");
                        VATEntry.SetRange("Tax Group Used", Rec."Tax Group Code");
                        VATEntry.SetRange("Tax Type", Rec."Tax Type");
                        PAGE.Run(PAGE::"VAT Entries", VATEntry);
                    end;
                }
            }
        }
        area(Promoted)
        {
        }
    }
}

