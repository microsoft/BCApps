// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Vendor;

page 12114 "Contribution Card"
{
    Caption = 'Contribution Card';
    PageType = Card;
    SourceTable = Contributions;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the contribution entry is posted.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification number of the vendor who is related to the contribution entry.';

                    trigger OnValidate()
                    begin
                        if Vendor.Get(Rec."Vendor No.") then;
                    end;
                }
                field("Vendor.Name"; Vendor.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor name.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the contribution entry.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number that links the vendor''s source document to the contribution entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the contribution entry.';
                }
                field("Related Date"; Rec."Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the contribution entry.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the contribution amount was paid to the tax authority.';
                }
                field(Month; Rec.Month)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the month of the contribution entry in numeric format.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the year of the contribution entry in numeric format. ';
                }
                field("INPS Paid"; Rec."INPS Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Social Security tax amount for this entry has been paid to the Instituto Nazionale Previdenza Sociale (INPS).';
                }
                field("INAIL Paid"; Rec."INAIL Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the workers'' compensation tax amount for this entry has been paid to the INAIL.';
                }
                field(Reported; Rec.Reported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the contribution amounts for this entry have been reported to the appropriate tax authorities.';
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
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability based on provisions in the law.';
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax, after the nontaxable amount has been subtracted.';
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
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the purchase.';
                }
                field("Free-Lance Amount %"; Rec."Free-Lance Amount %")
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
                    Importance = Promoted;
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
                }
                field("INAIL Contribution Base"; Rec."INAIL Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax after non-taxable amounts have been subtracted.';
                }
                field("INAIL Per Mil"; Rec."INAIL Per Mil")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to the INAIL withholding tax for workers compensation insurance.';
                }
                field("INAIL Total Amount"; Rec."INAIL Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the INAIL withholding tax that is due for this purchase.';
                }
                field("INAIL Free-Lance %"; Rec."INAIL Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&INPS")
            {
                Caption = '&INPS';
                Image = SocialSecurity;
                action(ListINPS)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List INPS';
                    Image = SocialSecurity;
                    ToolTip = 'View a list of contribution lines for social security tax.';

                    trigger OnAction()
                    begin
                        Contributi.Reset();
                        Contributi.SetFilter("Social Security Code", '<>%1', '');
                        PAGE.RunModal(PAGE::"Contribution List", Contributi);
                    end;
                }
                action(ListINAIL)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List INAIL';
                    Image = Union;
                    ToolTip = 'View a list of workers’ compensation taxes that have been applied to purchase invoices from independent contractors or consultants.';

                    trigger OnAction()
                    begin
                        Contributi.Reset();
                        Contributi.SetFilter("INAIL Code", '<>%1', '');
                        PAGE.RunModal(PAGE::"Contribution List", Contributi);
                    end;
                }
            }
        }
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Vendor.Get(Rec."Vendor No.") then;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Vendor.Init();
    end;

    var
        Vendor: Record Vendor;
        Contributi: Record Contributions;
}

