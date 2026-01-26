// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;

page 35493 "INAIL Contribution List"
{
    Caption = 'Contribution List';
    CardPageID = "Contribution Card";
    Editable = false;
    PageType = List;
    SourceTable = Contributions;
    SourceTableView = sorting("INAIL Code", "Vendor No.")
                      where("INAIL Code" = filter(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Month; Rec.Month)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the month of the contribution entry in numeric format.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the contribution entry in numeric format. ';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the contribution entry is posted.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the contribution entry.';
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
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification number of the vendor who is related to the contribution entry.';
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
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Social Security code that is applied to this purchase.';
                    Visible = "Social Security CodeVisible";
                }
                field("INAIL Code"; Rec."INAIL Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                    Visible = "INAIL CodeVisible";
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("INAIL Gross Amount"; Rec."INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL withholding tax.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability based on provisions in the law.';
                    Visible = "Non Taxable AmountVisible";
                }
                field("INAIL Non Taxable Amount"; Rec."INAIL Non Taxable Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the INAIL withholding tax based on provisions in the law.';
                    Visible = INAILNonTaxableAmountVisible;
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax, after the nontaxable amount has been subtracted.';
                    Visible = "Contribution BaseVisible";
                }
                field("INAIL Contribution Base"; Rec."INAIL Contribution Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax after non-taxable amounts have been subtracted.';
                    Visible = "INAIL Contribution BaseVisible";
                }
                field("Social Security %"; Rec."Social Security %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to Social Security tax.';
                    Visible = "Social Security %Visible";
                }
                field("INAIL Per Mil"; Rec."INAIL Per Mil")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to the INAIL withholding tax for workers compensation insurance.';
                    Visible = "INAIL Per Mil Visible";
                }
                field("Free-Lance Amount %"; Rec."Free-Lance Amount %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "Free-Lance Amount %Visible";
                }
                field("INAIL Free-Lance %"; Rec."INAIL Free-Lance %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "INAIL Free-Lance %Visible";
                }
                field("Total Social Security Amount"; Rec."Total Social Security Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the purchase.';
                    Visible = TotalSocialSecurityAmountVisib;
                }
                field("INAIL Total Amount"; Rec."INAIL Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the INAIL withholding tax that is due for this purchase.';
                    Visible = "INAIL Total AmountVisible";
                }
                field("Free-Lance Amount"; Rec."Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "Free-Lance AmountVisible";
                }
                field("INAIL Free-Lance Amount"; Rec."INAIL Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "INAIL Free-Lance AmountVisible";
                }
                field("INAIL Company Amount"; Rec."INAIL Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                    Visible = "INAIL Company AmountVisible";
                }
                field("Company Amount"; Rec."Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of Social Security tax from the purchase that your company is liable for.';
                    Visible = "Company AmountVisible";
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Social Security")
            {
                Caption = '&Social Security';
                Image = SocialSecurity;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Contribution List";
                    ToolTip = 'Open the card.';
                }
            }
        }
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
                    Rec.Navigate();
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

    trigger OnInit()
    begin
        "INAIL Company AmountVisible" := true;
        "Company AmountVisible" := true;
        "Free-Lance AmountVisible" := true;
        "INAIL Free-Lance AmountVisible" := true;
        "INAIL Free-Lance %Visible" := true;
        "Free-Lance Amount %Visible" := true;
        TotalSocialSecurityAmountVisib := true;
        "INAIL Total AmountVisible" := true;
        "INAIL Per Mil Visible" := true;
        "Social Security %Visible" := true;
        "INAIL Contribution BaseVisible" := true;
        "Contribution BaseVisible" := true;
        INAILNonTaxableAmountVisible := true;
        "Non Taxable AmountVisible" := true;
        "Social Security CodeVisible" := true;
        "INAIL CodeVisible" := true;
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Social Security Code") <> '' then begin
            "INAIL CodeVisible" := false;
            "Social Security CodeVisible" := true;
            "Non Taxable AmountVisible" := true;
            INAILNonTaxableAmountVisible := false;
            "Contribution BaseVisible" := true;
            "INAIL Contribution BaseVisible" := false;
            "Social Security %Visible" := true;
            "INAIL Per Mil Visible" := false;
            "INAIL Total AmountVisible" := false;
            TotalSocialSecurityAmountVisib := true;
            "Free-Lance Amount %Visible" := true;
            "INAIL Free-Lance %Visible" := false;
            "INAIL Free-Lance AmountVisible" := false;
            "Free-Lance AmountVisible" := true;
            "Company AmountVisible" := true;
            "INAIL Company AmountVisible" := false;
        end;

        if Rec.GetFilter("INAIL Code") <> '' then begin
            "Social Security CodeVisible" := false;
            "INAIL CodeVisible" := true;
            "Non Taxable AmountVisible" := false;
            INAILNonTaxableAmountVisible := true;
            "Contribution BaseVisible" := false;
            "INAIL Contribution BaseVisible" := true;
            "Social Security %Visible" := false;
            "INAIL Per Mil Visible" := true;
            "INAIL Total AmountVisible" := true;
            TotalSocialSecurityAmountVisib := false;
            "Free-Lance Amount %Visible" := false;
            "INAIL Free-Lance %Visible" := true;
            "INAIL Free-Lance AmountVisible" := true;
            "Free-Lance AmountVisible" := false;
            "Company AmountVisible" := false;
            "INAIL Company AmountVisible" := true;
        end;
    end;

    var
        "INAIL CodeVisible": Boolean;
        "Social Security CodeVisible": Boolean;
        "Non Taxable AmountVisible": Boolean;
        INAILNonTaxableAmountVisible: Boolean;
        "Contribution BaseVisible": Boolean;
        "INAIL Contribution BaseVisible": Boolean;
        "Social Security %Visible": Boolean;
        "INAIL Per Mil Visible": Boolean;
        "INAIL Total AmountVisible": Boolean;
        TotalSocialSecurityAmountVisib: Boolean;
        "Free-Lance Amount %Visible": Boolean;
        "INAIL Free-Lance %Visible": Boolean;
        "INAIL Free-Lance AmountVisible": Boolean;
        "Free-Lance AmountVisible": Boolean;
        "Company AmountVisible": Boolean;
        "INAIL Company AmountVisible": Boolean;
}

