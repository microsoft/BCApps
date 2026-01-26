// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

report 12103 "Summary Withholding Payment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/SummaryWithholdingPayment.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Summary Withholding Payment';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Withholding Tax Payment"; "Withholding Tax Payment")
        {
            DataItemTableView = sorting(Year, Month);
            RequestFilterFields = "Payment Date", Month, Year, "Tax Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Withholding_Tax_Payment_Month; Month)
            {
            }
            column(Withholding_Tax_Payment_Year; Year)
            {
            }
            column(Withholding_Tax_Payment__Tax_Code_; "Tax Code")
            {
            }
            column(Withholding_Tax_Payment__Total_Amount_; "Total Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Base___Excluded_Amount_; "Base - Excluded Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount_By_Treaty_; "Non Taxable Amount By Treaty")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount_; "Non Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Taxable_Amount_; "Taxable Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Withholding_Tax_Amount_; "Withholding Tax Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Payable_Amount_; "Payable Amount")
            {
                AutoFormatType = 1;
            }
            column(Withholding_Tax_Payment__Payment_Date_; Format("Payment Date"))
            {
            }
            column(Withholding_Tax_Payment__Series_Number_; "Series Number")
            {
            }
            column(Withholding_Tax_Payment__Quittance_No__; "Quittance No.")
            {
            }
            column(Withholding_Tax_Payment__C_T_; "C/T")
            {
            }
            column(Withholding_Tax_Payment__L_P_B_; "L/P/B")
            {
            }
            column(Withholding_Tax_Payment__Total_Amount__Control8; "Total Amount")
            {
            }
            column(Withholding_Tax_Payment__Base___Excluded_Amount__Control10; "Base - Excluded Amount")
            {
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount_By_Treaty__Control12; "Non Taxable Amount By Treaty")
            {
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount__Control16; "Non Taxable Amount")
            {
            }
            column(Withholding_Tax_Payment__Taxable_Amount__Control22; "Taxable Amount")
            {
            }
            column(Withholding_Tax_Payment__Withholding_Tax_Amount__Control28; "Withholding Tax Amount")
            {
            }
            column(Withholding_Tax_Payment__Payable_Amount__Control34; "Payable Amount")
            {
            }
            column(Withholding_Tax_Payment_Entry_No_; "Entry No.")
            {
            }
            column(Withholding_Tax_PaymentCaption; Withholding_Tax_PaymentCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Withholding_Tax_Payment_MonthCaption; FieldCaption(Month))
            {
            }
            column(Withholding_Tax_Payment_YearCaption; FieldCaption(Year))
            {
            }
            column(Withholding_Tax_Payment__Tax_Code_Caption; FieldCaption("Tax Code"))
            {
            }
            column(Withholding_Tax_Payment__Total_Amount_Caption; FieldCaption("Total Amount"))
            {
            }
            column(Withholding_Tax_Payment__Base___Excluded_Amount_Caption; FieldCaption("Base - Excluded Amount"))
            {
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount_By_Treaty_Caption; FieldCaption("Non Taxable Amount By Treaty"))
            {
            }
            column(Withholding_Tax_Payment__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
            {
            }
            column(Withholding_Tax_Payment__Taxable_Amount_Caption; FieldCaption("Taxable Amount"))
            {
            }
            column(Withholding_Tax_Payment__Withholding_Tax_Amount_Caption; FieldCaption("Withholding Tax Amount"))
            {
            }
            column(Withholding_Tax_Payment__Payable_Amount_Caption; FieldCaption("Payable Amount"))
            {
            }
            column(Withholding_Tax_Payment__Payment_Date_Caption; Withholding_Tax_Payment__Payment_Date_CaptionLbl)
            {
            }
            column(Withholding_Tax_Payment__Series_Number_Caption; FieldCaption("Series Number"))
            {
            }
            column(Withholding_Tax_Payment__Quittance_No__Caption; FieldCaption("Quittance No."))
            {
            }
            column(Withholding_Tax_Payment__C_T_Caption; FieldCaption("C/T"))
            {
            }
            column(Withholding_Tax_Payment__L_P_B_Caption; FieldCaption("L/P/B"))
            {
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Withholding_Tax_PaymentCaptionLbl: Label 'Withholding Tax Payment';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Withholding_Tax_Payment__Payment_Date_CaptionLbl: Label 'Payment Date';
}

