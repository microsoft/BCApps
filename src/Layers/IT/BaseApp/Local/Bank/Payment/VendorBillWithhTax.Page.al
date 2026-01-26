// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12198 "Vendor Bill Withh. Tax"
{
    Caption = 'Vendor Bill Withh. Tax';
    PageType = Card;
    SourceTable = "Vendor Bill Withholding Tax";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Related Date"; Rec."Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the vendor bill.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the vendor bill withholding taxes are paid to the tax authority.';
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code.';
                }
            }
            group("Withholding Tax")
            {
                Caption = 'Withholding Tax';
                field("Withholding Tax Code"; Rec."Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding code that is applied to the vendor bill. ';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original transaction that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original transaction that is excluded from the withholding tax calculation based on exclusions allowed by law.';
                }
                field("Non Taxable Amount By Treaty"; Rec."Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original transaction that is excluded from the withholding tax calculation based on residency. ';
                }
                field("Non Taxable %"; Rec."Non Taxable %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase that is not taxable because of provisions in the law.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original transaction that is not taxable because of provisions in the law.';
                }
                field("Taxable Base"; Rec."Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the vendor bill that is subject to withholding tax, after nontaxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax %"; Rec."Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the vendor bill that is subject to withholding tax. ';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of withholding tax that is due for the vendor bill. ';
                }
            }
            group("Social Security")
            {
                Caption = 'Social Security';
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security code that is applied to the vendor bill.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the vendor bill that is subject to Social Security withholding tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; Rec."Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the vendor bill that is excluded from Social Security tax based on provisions in the law.';
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the vendor bill that is subject to Social Security tax after the nontaxable amount has been subtracted.';
                }
                field("Social Security %"; Rec."Social Security %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the vendor bill that is subject to Social Security tax.';
                }
                field("Total Social Security Amount"; Rec."Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the vendor bill.';
                }
                field("Free-Lance %"; Rec."Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the Social Security tax that is the responsibility of the independent contractor or vendor.';
                }
                field("Free-Lance Amount"; Rec."Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax that is the responsibility of the vendor.';
                }
                field("Company Amount"; Rec."Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of Social Security tax from the vendor bill that your company is liable for.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateForm();
    end;

    trigger OnOpenPage()
    begin
        UpdateForm();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
    end;

    var
        Open: Boolean;
        Text11200: Label 'Vendor Bill Withh. Tax ';
        Text11201: Label 'Open';
        Text11202: Label 'Sent';

    [Scope('OnPrem')]
    procedure SetValues(OpenPara: Boolean)
    begin
        Open := OpenPara;
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        CurrPage.Editable := Open;
        CurrPage.Caption := Text11200;
        if Open then
            CurrPage.Caption := CurrPage.Caption + Text11201
        else
            CurrPage.Caption := CurrPage.Caption + Text11202;
    end;

    local procedure OKOnPush()
    var
        VendBillLine: Record "Vendor Bill Line";
    begin
        if Open then
            if VendBillLine.Get(Rec."Vendor Bill List No.", Rec."Line No.") then begin
                VendBillLine.Validate("Amount to Pay", VendBillLine."Remaining Amount" - Rec."Withholding Tax Amount" - Rec."Free-Lance Amount");
                VendBillLine."Withholding Tax Amount" := Rec."Withholding Tax Amount";
                VendBillLine."Social Security Amount" := Rec."Total Social Security Amount";
                VendBillLine.Modify();
                Rec."Old Free-Lance Amount" := Rec."Free-Lance Amount";
                Rec.Modify();
            end;
    end;
}

