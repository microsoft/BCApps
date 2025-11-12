// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.VAT.Ledger;

page 466 "Tax Jurisdictions"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Jurisdictions';
    PageType = List;
    SourceTable = "Tax Jurisdiction";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code you want to assign to this tax jurisdiction. You can enter up to 10 characters, both numbers and letters. It is a good idea to enter a code that is easy to remember.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a description of the tax jurisdiction. For example, if the tax jurisdiction code is ATLANTA GA, enter the description as Atlanta, Georgia.';
                }
                field("Default Sales and Use Tax"; DefaultTax)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Default Sales and Use Tax';
                    Enabled = DefaultTaxIsEnabled;
                    Style = Subordinate;
                    StyleExpr = not DefaultTaxIsEnabled;
                    ToolTip = 'Specifies the default tax in locations where the sales tax and use tax are identical.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxDetail: Record "Tax Detail";
                    begin
                        GetDefaultTaxDetail(TaxDetail);
                        PAGE.RunModal(PAGE::"Tax Details", TaxDetail);
                        DefaultTax := GetDefaultTax();
                    end;

                    trigger OnValidate()
                    begin
                        SetDefaultTax(DefaultTax);
                    end;
                }
                field("Calculate Tax on Tax"; Rec."Calculate Tax on Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to calculate the sales tax amount with the tax on tax principle.';
                    Visible = false;
                }
                field("Unrealized VAT Type"; Rec."Unrealized VAT Type")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies how to handle unrealized tax, which is tax that is calculated but not due until the invoice is paid.';
                    Visible = false;
                }
                field("Adjust for Payment Discount"; Rec."Adjust for Payment Discount")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to recalculate tax amounts when you post payments that trigger payment discounts.';
                    Visible = false;
                }
                field("Tax Account (Sales)"; Rec."Tax Account (Sales)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated tax on sales transactions.';
                }
                field("Unreal. Tax Acc. (Sales)"; Rec."Unreal. Tax Acc. (Sales)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized tax on sales transactions.';
                    Visible = false;
                }
                field("Tax Account (Purchases)"; Rec."Tax Account (Purchases)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated tax on purchase transactions.';
                }
                field("Reverse Charge (Purchases)"; Rec."Reverse Charge (Purchases)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated reverse-charge tax on purchase transactions.';
                }
                field("Unreal. Tax Acc. (Purchases)"; Rec."Unreal. Tax Acc. (Purchases)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized tax on purchase transactions.';
                    Visible = false;
                }
                field("Unreal. Rev. Charge (Purch.)"; Rec."Unreal. Rev. Charge (Purch.)")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the general ledger account you want to use for posting calculated unrealized reverse-charge tax on purchase transactions.';
                    Visible = false;
                }
                field("Report-to Jurisdiction"; Rec."Report-to Jurisdiction")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax jurisdiction you want to associate with the jurisdiction you are setting up. For example, if you are setting up a jurisdiction for Atlanta, Georgia, the report-to jurisdiction is Georgia because Georgia is the tax authority to which you report Atlanta sales tax.';
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
            group("&Jurisdiction")
            {
                Caption = '&Jurisdiction';
                Image = ViewDetails;
                action("Ledger &Entries")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Ledger &Entries';
                    Image = CustomerLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "VAT Entries";
                    RunPageLink = "Tax Jurisdiction Code" = field(Code);
                    RunPageView = sorting("Tax Jurisdiction Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View Tax entries, which result from posting transactions in journals and sales and purchase documents, and from the Calc. and Post Tax Settlement batch job.';
                }
                action(Details)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Details';
                    Image = View;
                    RunObject = Page "Tax Details";
                    RunPageLink = "Tax Jurisdiction Code" = field(Code);
                    ToolTip = 'View tax-detail entries. A tax-detail entry includes all of the information that is used to calculate the amount of tax to be charged.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Details_Promoted; Details)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DefaultTax := GetDefaultTax();
    end;

    trigger OnAfterGetRecord()
    begin
        DefaultTax := GetDefaultTax();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        DefaultTax := 0;
        DefaultTaxIsEnabled := TaxSetup."Auto. Create Tax Details";
    end;

    var
        DefaultTax: Decimal;
        DefaultTaxIsEnabled: Boolean;

    local procedure GetDefaultTax(): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        GetDefaultTaxDetail(TaxDetail);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure SetDefaultTax(NewTaxBelowMaximum: Decimal)
    var
        TaxDetail: Record "Tax Detail";
    begin
        GetDefaultTaxDetail(TaxDetail);
        TaxDetail."Tax Below Maximum" := NewTaxBelowMaximum;
        TaxDetail.Modify();
    end;

    local procedure GetDefaultTaxDetail(var TaxDetail: Record "Tax Detail")
    begin
        TaxDetail.SetRange("Tax Jurisdiction Code", Rec.Code);
        TaxDetail.SetRange("Tax Group Code", '');
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales Tax");
        if TaxDetail.FindLast() then begin
            DefaultTaxIsEnabled := true;
            TaxDetail.SetRange("Effective Date", TaxDetail."Effective Date");
            TaxDetail.FindLast();
        end else begin
            DefaultTaxIsEnabled := false;
            TaxDetail.SetRange("Effective Date");
        end;
    end;
}

