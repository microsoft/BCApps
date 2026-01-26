// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Document;

page 12133 "Withh. Taxes-Contribution Card"
{
    Caption = 'Withh. Taxes-Contribution Card';
    DataCaptionFields = "No.";
    PageType = Card;
    SourceTable = "Purch. Withh. Contribution";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the withholding tax amounts are paid to the tax authority.';
                }
                field("Payable Amount"; Rec."Payable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of withholding tax that is payable for this purchase.';
                }
                field("Date Related"; Rec."Date Related")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the withholding tax entry.';
                }
            }
            group("Withhold Taxes")
            {
                Caption = 'Withhold Taxes';
                field("Withholding Tax Code"; Rec."Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the withholding code that is applied to this purchase. ';
                }
                field(TotalAmount; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on exclusions allowed by law.';
                }
                field("Non Taxable Amount By Treaty"; Rec."Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from withholding tax based on residency. ';
                }
                field("Non Taxable Amount %"; Rec."Non Taxable Amount %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase transaction that is not taxable due to provisions in the law.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Taxable Base"; Rec."Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax after non-taxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax %"; Rec."Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to withholding tax. ';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of withholding tax that is due for this purchase. ';
                }
                field("WHT Amount Manual"; Rec."WHT Amount Manual")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a withholding tax amount that will override the calculated amount for the purchase. If you leave this field empty, the value in the Withholding Tax Amount field will be used.';
                }
            }
            group("Social Security")
            {
                Caption = 'Social Security';
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Social Security code that is applied to this purchase.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; Rec."Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability, based on provisions in the law.';
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax, after the non-taxable amount has been subtracted.';
                }
                field("Social Security %"; Rec."Social Security %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to Social Security tax.';
                }
                field("Total Social Security Amount"; Rec."Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for this purchase.';
                }
                field("Free-Lance %"; Rec."Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Free-Lance Amount"; Rec."Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Company Amount"; Rec."Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of Social Security tax from the purchase that your company is liable for.';
                }
            }
            group(INAIL)
            {
                Caption = 'INAIL';
                field("INAIL Code"; Rec."INAIL Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                }
                field("INAIL Gross Amount"; Rec."INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL withholding tax.';
                }
                field("INAIL Non Taxable Amount"; Rec."INAIL Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the INAIL withholding tax based on provisions in the law.';

                    trigger OnValidate()
                    begin
                        if xRec."INAIL Non Taxable Amount" <> Rec."INAIL Non Taxable Amount" then
                            if Rec."INAIL Contribution Base" < 0 then
                                Error(Text1035, Rec.FieldCaption("INAIL Gross Amount"), Rec.FieldCaption("INAIL Non Taxable Amount"));
                    end;
                }
                field("INAIL Contribution Base"; Rec."INAIL Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax, after non-taxable amounts have been subtracted.';
                }
                field("INAIL Per Mil"; Rec."INAIL Per Mil")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to INAIL withholding tax for workers compensation insurance.';
                }
                field("INAIL Total Amount"; Rec."INAIL Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of Italian Workers'' Compensation Authority (INAIL) withholding tax that is due for this purchase.';
                }
                field("INAIL Free-Lance %"; Rec."INAIL Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("INAIL Free-Lance Amount"; Rec."INAIL Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("INAIL Company Amount"; Rec."INAIL Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of Italian Workers'' Compensation Authority (INAIL) tax that your company is liable for.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Calculate)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Calculate';
                Image = Calculate;
                ToolTip = 'Calculate the taxes based on the current information.';

                trigger OnAction()
                begin
                    PurchHeader.Get(Rec."Document Type", Rec."No.");
                    WithholdingSocSec.CalculateWithholdingTax(PurchHeader, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Calculate_Promoted; Calculate)
                {
                }
            }
        }
    }

    var
        PurchHeader: Record "Purchase Header";
        WithholdingSocSec: Codeunit "Withholding - Contribution";
        Text1035: Label '%1 must be greater than %2.';
}

