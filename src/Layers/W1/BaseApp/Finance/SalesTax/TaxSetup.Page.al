// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

page 485 "Tax Setup"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Tax Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Auto. Create Tax Details"; Rec."Auto. Create Tax Details")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the required tax information is created automatically.';
                }
                field("Non-Taxable Tax Group Code"; Rec."Non-Taxable Tax Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the group code for non-taxable sales.';
                }
            }
            group("Default Accounts")
            {
                Caption = 'Default Accounts';
                field("Tax Account (Sales)"; Rec."Tax Account (Sales)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated tax.';
                }
                field("Tax Account (Purchases)"; Rec."Tax Account (Purchases)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated tax.';
                }
                field("Unreal. Tax Acc. (Sales)"; Rec."Unreal. Tax Acc. (Sales)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized tax on sales transaction.';
                }
                field("Unreal. Tax Acc. (Purchases)"; Rec."Unreal. Tax Acc. (Purchases)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized tax on purchase transactions.';
                }
                field("Reverse Charge (Purchases)"; Rec."Reverse Charge (Purchases)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated reverse-charge tax on purchase transactions.';
                }
                field("Unreal. Rev. Charge (Purch.)"; Rec."Unreal. Rev. Charge (Purch.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized reverse-charge tax on purchase transactions.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

