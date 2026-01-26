// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Foundation.Navigate;

page 12141 "VAT Book Entries"
{
    Caption = 'VAT Book Entries';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Book Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number of the VAT transaction.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product group that is assigned to the VAT entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT book entry''s posting date.';
                }
                field("Official Date"; Rec."Official Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the official date of the VAT entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the transaction that is the source of the VAT entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the document that is the source of the VAT entry.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique document number, such as the source document from your customer or vendor.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the type of document that is the source of the VAT entry.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the origin of the VAT entry.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage that is applied to this entry.';
                }
                field("Deductible %"; Rec."Deductible %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the transaction Amount that applies to VAT.';
                }
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT codes that are available.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry that the VAT amount is calculated from.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field("Nondeductible Base"; Rec."Nondeductible Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied due to the type of goods or services purchased.';
                }
                field("Nondeductible Amount"; Rec."Nondeductible Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a manually entered VAT amount.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount of this entry.';
                    Visible = false;
                }
                field("Additional-Currency Base"; Rec."Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount that is used to calculate the Additional-Currency Amount.';
                    Visible = false;
                }
                field("Add. Curr. Nondeductible Amt."; Rec."Add. Curr. Nondeductible Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is not deducted, due to the type of goods or services purchased.';
                    Visible = false;
                }
                field("Add. Curr. Nondeductible Base"; Rec."Add. Curr. Nondeductible Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount that is not deducted, due to the type of goods or services purchased.';
                    Visible = false;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the code for the number series to which the document number on this entry belongs.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT calculation type of the entry.';
                }
                field("Sell-to/Buy-from No."; Rec."Sell-to/Buy-from No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the customer or vendor number that is associated with this VAT entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}

