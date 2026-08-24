// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

report 685 "Payment Practice"
{
    ApplicationArea = All;
    DefaultRenderingLayout = PaymentPractice_PeriodLayout;

    dataset
    {
        dataitem(PaymentPracticeHeader; "Payment Practice Header")
        {
            column(Header_Caption; TableCaption()) { }
            column(Header_No; "No.") { }
            column(Starting_Date; Format("Starting Date")) { }
            column(Starting_Date_Caption; FieldCaption("Starting Date")) { }
            column(Ending_Date; Format("Ending Date")) { }
            column(Ending_Date_Caption; FieldCaption("Ending Date")) { }
            column(Aggregation_Type; "Aggregation Type") { }
            column(Aggregation_Type_Caption; FieldCaption("Aggregation Type")) { }
            column(Header_Type; "Header Type") { }
            column(Header_Type_Caption; FieldCaption("Header Type")) { }
            column(Average_Agreed_Payment_Period; "Average Agreed Payment Period") { }
            column(Average_Agreed_Payment_Period_Caption; FieldCaption("Average Agreed Payment Period")) { }
            column(Average_Actual_Payment_Period; "Average Actual Payment Period") { }
            column(Average_Actual_Payment_Period_Caption; FieldCaption("Average Actual Payment Period")) { }
            column(Pct_Paid_on_Time; "Pct Paid on Time") { }
            column(Pct_Paid_on_Time_Caption; FieldCaption("Pct Paid on Time")) { }
            column(Mode_Payment_Time; "Mode Payment Time") { }
            column(Mode_Payment_Time_Caption; FieldCaption("Mode Payment Time")) { }
            column(Mode_Payment_Time_Min; "Mode Payment Time Min.") { }
            column(Mode_Payment_Time_Min_Caption; FieldCaption("Mode Payment Time Min.")) { }
            column(Mode_Payment_Time_Max; "Mode Payment Time Max.") { }
            column(Mode_Payment_Time_Max_Caption; FieldCaption("Mode Payment Time Max.")) { }
            column(Median_Payment_Time; "Median Payment Time") { }
            column(Median_Payment_Time_Caption; FieldCaption("Median Payment Time")) { }
            column(Percentile_80th_Payment_Time; "80th Percentile Payment Time") { }
            column(Percentile_80th_Payment_Time_Caption; FieldCaption("80th Percentile Payment Time")) { }
            column(Percentile_95th_Payment_Time; "95th Percentile Payment Time") { }
            column(Percentile_95th_Payment_Time_Caption; FieldCaption("95th Percentile Payment Time")) { }
            column(Pct_Peppol_Enabled; "Pct Peppol Enabled") { }
            column(Pct_Peppol_Enabled_Caption; FieldCaption("Pct Peppol Enabled")) { }
            column(Pct_Small_Business_Payments; "Pct Small Business Payments") { }
            column(Pct_Small_Business_Payments_Caption; FieldCaption("Pct Small Business Payments")) { }

            dataitem(PaymentPracticeLine; "Payment Practice Line")
            {
                DataItemLink = "Header No." = field("No.");
                DataItemLinkReference = PaymentPracticeHeader;
                DataItemTableView = sorting("Header No.", "Line No.");

                column(Line_Company_Size_Code; "Company Size Code") { }
                column(Line_Company_Size_Code_Caption; FieldCaption("Company Size Code")) { }
                column(Line_Source_Type; "Source Type") { }
                column(Line_Source_Type_Caption; FieldCaption("Source Type")) { }
                column(Line_Payment_Period_Code; "Payment Period Code") { }
                column(Line_Payment_Period_Code_Caption; FieldCaption("Payment Period Code")) { }
                column(Line_Average_Agreed_Payment_Period; "Average Agreed Payment Period") { }
                column(Line_Average_Agreed_Payment_Period_Caption; FieldCaption("Average Agreed Payment Period")) { }
                column(Line_Average_Actual_Payment_Period; "Average Actual Payment Period") { }
                column(Line_Average_Actual_Payment_Period_Caption; FieldCaption("Average Actual Payment Period")) { }
                column(Line_Pct_Paid_on_Time; "Pct Paid on Time") { }
                column(Line_Pct_Paid_on_Time_Caption; FieldCaption("Pct Paid on Time")) { }
                column(Line_Pct_Paid_in_Period; "Pct Paid in Period") { }
                column(Line_Pct_Paid_in_Period_Caption; FieldCaption("Pct Paid in Period")) { }
                column(Line_Pct_Paid_in_Period__Amount_; "Pct Paid in Period (Amount)") { }
                column(Line_Pct_Paid_in_Period__Amount__Caption; FieldCaption("Pct Paid in Period (Amount)")) { }
                column(Line_Payment_Period_Description; "Payment Period Description") { }
                column(Line_Payment_Period_Description_Caption; FieldCaption("Payment Period Description")) { }
            }
        }
    }

    rendering
    {
        layout(PaymentPractice_PeriodLayout)
        {
            Type = Word;
            Caption = 'Payment Practice by Period';
            Summary = 'Payment Practice by Period';
            LayoutFile = 'src/Reports/Payment Practice by Period.docx';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the Document Report Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '30.0';
        }
        layout(PaymentPractice_SmallBusinessLayout)
        {
            Type = Word;
            Caption = 'Payment Practice Small Business';
            Summary = 'Payment Practice Small Business';
            LayoutFile = 'src/Reports/Payment Practice Small Business.docx';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the Document Report Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '30.0';
        }
        layout(PaymentPractice_VendorSizeLayout)
        {
            Type = Word;
            Caption = 'Payment Practice by Vendor Size';
            Summary = 'Payment Practice by Vendor Size';
            LayoutFile = 'src/Reports/Payment Practice by Vendor Size.docx';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the Document Report Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '30.0';
        }
        layout(PaymentPractice_PeriodLayoutBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = 'src/Reports/Payment Practice by PeriodBody.docx';
            Caption = 'Body-only: Payment Practice by Period';
            Summary = 'Portrait orientated. Shows the reporting period and aggregation, the average agreed and actual payment periods, and the percentage paid on time. A line for each payment period shows the share paid and the amount.';

        }
        layout(PaymentPractice_SmallBusinessLayoutBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = 'src/Reports/Payment Practice Small BusinessBody.docx';
            Caption = 'Body-only: Payment Practice Small Business';
            Summary = 'Portrait orientated. Shows the reporting period and aggregation, the agreed and actual payment periods, the percentage paid on time, median, mode, and percentile payment times, Peppol use, and the small business share, with a line for each period.';
        }
        layout(PaymentPractice_VendorSizeLayoutBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = 'src/Reports/Payment Practice by Vendor SizeBody.docx';
            Caption = 'Body-only: Payment Practice by Vendor Size';
            Summary = 'Portrait orientated. Shows the reporting period, the aggregation, and the overall averages. A line for each company size code shows the average agreed payment period, the average actual payment period, and the percentage paid on time.';
        }
    }
}