// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 12105 "Compensation Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/CompensationDetails.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Compensation Details';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(Name__________Name_2_; Name + ' ' + "Name 2")
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Address; Address)
            {
            }
            column(City_________County; City + ' ' + County)
            {
            }
            column(Vendor__Fiscal_Code_; "Fiscal Code")
            {
            }
            column(Vendor__Country_Region_Code_; "Country/Region Code")
            {
            }
            column(Country_Name; Country.Name)
            {
            }
            column(Vendor__Birth_Date_; "Date of Birth")
            {
            }
            column(Birth_City___________Birth_County_; "Birth City" + ' ' + "Birth County")
            {
            }
            column(SubjectType; SubjectType)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor_AddressCaption; FieldCaption(Address))
            {
            }
            column(Vendor__Fiscal_Code_Caption; FieldCaption("Fiscal Code"))
            {
            }
            column(Vendor__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
            {
            }
            column(Vendor__Birth_Date_Caption; FieldCaption("Date of Birth"))
            {
            }
            column(Birth_City___________Birth_County_Caption; Birth_City___________Birth_County_CaptionLbl)
            {
            }
            column(SubjectTypeCaption; SubjectTypeCaptionLbl)
            {
            }
            dataitem("Withholding Tax"; "Withholding Tax")
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "Source-Withholding Tax", "Recipient May Report Income", "Withholding Tax Code", "Withholding Tax %");
                column(Withholding_Tax__Document_No__; "Document No.")
                {
                }
                column(Withholding_Tax__External_Document_No__; "External Document No.")
                {
                }
                column(Withholding_Tax__Document_Date_; Format("Document Date"))
                {
                }
                column(Withholding_Tax__Payment_Date_; Format("Payment Date"))
                {
                }
                column(Withholding_Tax__Related_Date_; Format("Related Date"))
                {
                }
                column(Withholding_Tax_Month; Month)
                {
                }
                column(Withholding_Tax_Year; Year)
                {
                }
                column(Withholding_Tax__Tax_Code_; "Tax Code")
                {
                }
                column(Withholding_Tax__Total_Amount_; "Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Base___Excluded_Amount_; "Base - Excluded Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_By_Treaty_; "Non Taxable Amount By Treaty")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount___; "Non Taxable Amount %")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Taxable_Base_; "Taxable Base")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Withholding_Tax___; "Withholding Tax %")
                {
                }
                column(Withholding_Tax__Withholding_Tax_Amount_; "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax_Reported; Reported)
                {
                }
                column(Withholding_Tax__Withholding_Tax_Code_; "Withholding Tax Code")
                {
                }
                column(Reported_formatted; Format(Reported))
                {
                }
                column(Withholding_Tax__Withholding_Tax_Amount__Control1130018; "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount__Control1130017; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_By_Treaty__Control1130112; "Non Taxable Amount By Treaty")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Base___Excluded_Amount__Control1130111; "Base - Excluded Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Total_Amount__Control1130009; "Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Taxable_Base__Control1130057; "Taxable Base")
                {
                    AutoFormatType = 1;
                }
                column(DescrTot; DescrTot)
                {
                    AutoFormatType = 1;
                }
                column(DesctTotWithHoldTax1; DesctTotWithHoldTax1)
                {
                }
                column(DesctTotWithHoldTax2; DesctTotWithHoldTax2)
                {
                }
                column(DesctTotWithHoldTax3; DesctTotWithHoldTax3)
                {
                }
                column(DesctTotWithHoldTax4; DesctTotWithHoldTax4)
                {
                }
                column(DesctTotWithHoldTax5; DesctTotWithHoldTax5)
                {
                }
                column(DesctTotWithHoldTax6; DesctTotWithHoldTax6)
                {
                }
                column(DesctTotWithHoldTax7; DesctTotWithHoldTax7)
                {
                }
                column(RecptMayReportIncome; RecptMayReportIncome)
                {
                }
                column(SrcWithHoldTax; SrcWithHoldTax)
                {
                }
                column(Withholding_Tax_Entry_No_; "Entry No.")
                {
                }
                column(Withholding_Tax_Vendor_No_; "Vendor No.")
                {
                }
                column(Withholding_Tax_Source_Withholding_Tax; "Source-Withholding Tax")
                {
                }
                column(Withholding_Tax_Recipient_May_Report_Income; "Recipient May Report Income")
                {
                }
                column(Withholding_Tax__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Withholding_Tax__External_Document_No__Caption; FieldCaption("External Document No."))
                {
                }
                column(Withholding_Tax__Document_Date_Caption; Withholding_Tax__Document_Date_CaptionLbl)
                {
                }
                column(Withholding_Tax__Payment_Date_Caption; Withholding_Tax__Payment_Date_CaptionLbl)
                {
                }
                column(Withholding_Tax__Related_Date_Caption; Withholding_Tax__Related_Date_CaptionLbl)
                {
                }
                column(Withholding_Tax_MonthCaption; FieldCaption(Month))
                {
                }
                column(Withholding_Tax_YearCaption; FieldCaption(Year))
                {
                }
                column(Withholding_Tax__Tax_Code_Caption; FieldCaption("Tax Code"))
                {
                }
                column(Withholding_Tax__Total_Amount_Caption; FieldCaption("Total Amount"))
                {
                }
                column(Withholding_Tax__Base___Excluded_Amount_Caption; FieldCaption("Base - Excluded Amount"))
                {
                }
                column(Withholding_Tax__Non_Taxable_Amount_By_Treaty_Caption; FieldCaption("Non Taxable Amount By Treaty"))
                {
                }
                column(Withholding_Tax__Non_Taxable_Amount___Caption; FieldCaption("Non Taxable Amount %"))
                {
                }
                column(Withholding_Tax__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
                {
                }
                column(Withholding_Tax__Taxable_Base_Caption; FieldCaption("Taxable Base"))
                {
                }
                column(Withholding_Tax__Withholding_Tax___Caption; FieldCaption("Withholding Tax %"))
                {
                }
                column(Withholding_Tax__Withholding_Tax_Amount_Caption; FieldCaption("Withholding Tax Amount"))
                {
                }
                column(Withholding_Tax_ReportedCaption; FieldCaption(Reported))
                {
                }
                column(Withholding_TaxCaption; Withholding_TaxCaptionLbl)
                {
                }
                column(Withholding_Tax__Withholding_Tax_Code_Caption; FieldCaption("Withholding Tax Code"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DesctTotWithHoldTax1 := Text1037 + "Withholding Tax Code" + ' ' + Format("Withholding Tax %") + '%';
                    DesctTotWithHoldTax2 := Text1037 + "Withholding Tax Code";
                    DesctTotWithHoldTax3 := Text1037 + FieldCaption("Recipient May Report Income");
                    DesctTotWithHoldTax4 := Text1038;
                    DesctTotWithHoldTax5 := Text1037 + FieldCaption("Source-Withholding Tax");
                    DesctTotWithHoldTax6 := Text1037 + Text1039;
                    DesctTotWithHoldTax7 := Text1040;
                    RecptMayReportIncome := "Recipient May Report Income";
                    SrcWithHoldTax := "Source-Withholding Tax";
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    if not Certified then
                        SetRange(Reported, false);
                end;
            }
            dataitem(INPS; Contributions)
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "Social Security Code") order(ascending);
                column(INPS__Document_No__; "Document No.")
                {
                }
                column(INPS__External_Document_No__; "External Document No.")
                {
                }
                column(INPS__Document_Date_; Format("Document Date"))
                {
                }
                column(INPS__Payment_Date_; Format("Payment Date"))
                {
                }
                column(INPS__Related_Date_; Format("Related Date"))
                {
                }
                column(INPS_Month; Month)
                {
                }
                column(INPS_Year; Year)
                {
                }
                column(INPS__Gross_Amount_; "Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Non_Taxable_Amount_; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Contribution_Base_; "Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Social_Security___; "Social Security %")
                {
                }
                column(INPS__Total_Social_Security_Amount_; "Total Social Security Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Free_Lance_Amount___; "Free-Lance Amount %")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Free_Lance_Amount_; "Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Company_Amount_; "Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS_Reported; Reported)
                {
                }
                column(INPS__Social_Security_Code_; "Social Security Code")
                {
                }
                column(Reported_formatted_INPS; Format(Reported))
                {
                }
                column(INPS__Gross_Amount__Control1130103; "Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Non_Taxable_Amount__Control1130104; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Contribution_Base__Control1130105; "Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Total_Social_Security_Amount__Control1130106; "Total Social Security Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Free_Lance_Amount__Control1130107; "Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INPS__Company_Amount__Control1130108; "Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(DescrTot_Control1130117; DescrTot)
                {
                    AutoFormatType = 1;
                }
                column(DescTotINAIL2; DescTotINAIL2)
                {
                }
                column(DescTotINAIL1; DescTotINAIL1)
                {
                }
                column(INPS_Entry_No_; "Entry No.")
                {
                }
                column(INPS_Vendor_No_; "Vendor No.")
                {
                }
                column(INPS__Related_Date_Caption; INPS__Related_Date_CaptionLbl)
                {
                }
                column(INPS__Payment_Date_Caption; INPS__Payment_Date_CaptionLbl)
                {
                }
                column(INPS__Document_Date_Caption; INPS__Document_Date_CaptionLbl)
                {
                }
                column(INPS__External_Document_No__Caption; FieldCaption("External Document No."))
                {
                }
                column(INPS__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(INPS_YearCaption; FieldCaption(Year))
                {
                }
                column(INPS_MonthCaption; FieldCaption(Month))
                {
                }
                column(INPS__Gross_Amount_Caption; FieldCaption("Gross Amount"))
                {
                }
                column(INPS__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
                {
                }
                column(INPS__Contribution_Base_Caption; FieldCaption("Contribution Base"))
                {
                }
                column(INPS__Social_Security___Caption; FieldCaption("Social Security %"))
                {
                }
                column(INPS__Total_Social_Security_Amount_Caption; FieldCaption("Total Social Security Amount"))
                {
                }
                column(INPS__Free_Lance_Amount___Caption; FieldCaption("Free-Lance Amount %"))
                {
                }
                column(INPS__Free_Lance_Amount_Caption; FieldCaption("Free-Lance Amount"))
                {
                }
                column(INPS__Company_Amount_Caption; FieldCaption("Company Amount"))
                {
                }
                column(INPS_ReportedCaption; FieldCaption(Reported))
                {
                }
                column(INPS__Social_Security_Code_Caption; FieldCaption("Social Security Code"))
                {
                }
                column(Social_SecurityCaption; Social_SecurityCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DescTotINAIL1 := Text1041;
                    DescTotINAIL2 := Text1037 + "Social Security Code";
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    if not Certified then
                        SetRange(Reported, false);
                end;
            }
            dataitem(INAIL; Contributions)
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "INAIL Code", "INAIL Per Mil") order(ascending);
                column(INAIL__INAIL_Company_Amount_; "INAIL Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL_Reported; Reported)
                {
                }
                column(INAIL__INAIL_Free_Lance_Amount_; "INAIL Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Free_Lance___; "INAIL Free-Lance %")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Total_Amount_; "INAIL Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL___; "INAIL Per Mil")
                {
                }
                column(INAIL__INAIL_Contribution_Base_; "INAIL Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Non_Taxable_Amount_; "INAIL Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Gross_Amount_; "INAIL Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL_Year; Year)
                {
                }
                column(INAIL_Month; Month)
                {
                }
                column(INAIL__Related_Date_; Format("Related Date"))
                {
                }
                column(INAIL__Payment_Date_; Format("Payment Date"))
                {
                }
                column(INAIL__Document_Date_; Format("Document Date"))
                {
                }
                column(INAIL__External_Document_No__; "External Document No.")
                {
                }
                column(INAIL__Document_No__; "Document No.")
                {
                }
                column(INAIL__INAIL_Code_; "INAIL Code")
                {
                }
                column(Reported_formatted_INAIL; Format(Reported))
                {
                }
                column(DescrTot_Control1130145; DescrTot)
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Gross_Amount__Control1130146; "INAIL Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Non_Taxable_Amount__Control1130147; "INAIL Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Contribution_Base__Control1130148; "INAIL Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Total_Amount__Control1130149; "INAIL Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Free_Lance_Amount__Control1130150; "INAIL Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Company_Amount__Control1130151; "INAIL Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(DescTotINAIL3; DescTotINAIL3)
                {
                }
                column(DescTotINAIL4; DescTotINAIL4)
                {
                }
                column(INAIL_Entry_No_; "Entry No.")
                {
                }
                column(INAIL_Vendor_No_; "Vendor No.")
                {
                }
                column(INAIL_ReportedCaption; FieldCaption(Reported))
                {
                }
                column(INAIL__INAIL_Company_Amount_Caption; FieldCaption("INAIL Company Amount"))
                {
                }
                column(INAIL__INAIL_Free_Lance_Amount_Caption; FieldCaption("INAIL Free-Lance Amount"))
                {
                }
                column(INAIL__INAIL_Free_Lance___Caption; FieldCaption("INAIL Free-Lance %"))
                {
                }
                column(INAIL__INAIL_Total_Amount_Caption; FieldCaption("INAIL Total Amount"))
                {
                }
                column(INAIL__INAIL___Caption; FieldCaption("INAIL Per Mil"))
                {
                }
                column(INAIL__INAIL_Contribution_Base_Caption; FieldCaption("INAIL Contribution Base"))
                {
                }
                column(INAIL__INAIL_Non_Taxable_Amount_Caption; FieldCaption("INAIL Non Taxable Amount"))
                {
                }
                column(INAIL__INAIL_Gross_Amount_Caption; FieldCaption("INAIL Gross Amount"))
                {
                }
                column(INAIL_YearCaption; FieldCaption(Year))
                {
                }
                column(INAIL_MonthCaption; FieldCaption(Month))
                {
                }
                column(INAIL__Related_Date_Caption; INAIL__Related_Date_CaptionLbl)
                {
                }
                column(INAIL__Payment_Date_Caption; INAIL__Payment_Date_CaptionLbl)
                {
                }
                column(INAIL__Document_Date_Caption; INAIL__Document_Date_CaptionLbl)
                {
                }
                column(INAIL__External_Document_No__Caption; FieldCaption("External Document No."))
                {
                }
                column(INAIL__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(INAIL__INAIL_Code_Caption; FieldCaption("INAIL Code"))
                {
                }
                column(INAILCaption; INAILCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DescTotINAIL3 := Text1042;
                    DescTotINAIL4 := Text1037 + "INAIL Code";
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    if not Certified then
                        SetRange(Reported, false);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOneForPage then
                    GroupNo += 1;

                if Resident = Resident::Resident then
                    SubjectType := Text1035
                else
                    SubjectType := Text1036;

                if not Country.Get("Country/Region Code") then
                    Country.Init();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FromPaymentDate; FromPaymentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Payment Date';
                        ToolTip = 'Specifies the start date of the payment date range.';

                        trigger OnValidate()
                        begin
                            ToPaymentDate := SuggDate(FromPaymentDate);
                        end;
                    }
                    field(ToPaymentDate; ToPaymentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Payment Date';
                        ToolTip = 'Specifies the last payment date.';
                    }
                    field(FromRelatedDate; FromRelatedDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Related Date';
                        ToolTip = 'Specifies the start date of the related date range.';

                        trigger OnValidate()
                        begin
                            // IF EVALUATE(TmpDate, PaymentDate) THEN;
                            // PaymentDate := FORMAT(PaymentDate,0);

                            ToRelatedDate := SuggDate(FromRelatedDate);
                        end;
                    }
                    field(ToRelatedDate; ToRelatedDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Related Date';
                        ToolTip = 'Specifies the last related date.';
                    }
                    field(Certified; Certified)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Compensation Reported';
                        ToolTip = 'Specifies if the report includes compensation.';
                    }
                    field(PrintOnlyOneForPage; PrintOnlyOneForPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print one section for page';
                        ToolTip = 'Specifies if you want to print one section for page.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PrintOnlyOneForPage := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (FromPaymentDate = 0D) or
           (ToPaymentDate = 0D)
        then
            Error(Text1033);

        if ((FromRelatedDate = 0D) and (ToRelatedDate <> 0D)) or
           ((FromRelatedDate <> 0D) and (ToRelatedDate = 0D))
        then
            Error(Text1034);
    end;

    var
        Text1033: Label 'From Payment Date and To Payment Date must be filled.';
        Text1034: Label 'From Related Date and To Related Date must be filled.';
        Text1035: Label 'Resident';
        Text1036: Label 'Not Resident';
        Text1037: Label 'Total ';
        Text1038: Label 'Total Recipient cannot Report Income';
        Text1039: Label 'Withholding Tax in advance';
        Text1040: Label 'Total Withholding Tax';
        Text1041: Label 'Total Social Security';
        Country: Record "Country/Region";
        Certified: Boolean;
        PrintOnlyOneForPage: Boolean;
        SubjectType: Text[30];
        FromPaymentDate: Date;
        ToPaymentDate: Date;
        FromRelatedDate: Date;
        ToRelatedDate: Date;
        DescrTot: Text[50];
        DesctTotWithHoldTax1: Text[50];
        DesctTotWithHoldTax2: Text[50];
        DesctTotWithHoldTax3: Text[50];
        DesctTotWithHoldTax4: Text[50];
        DesctTotWithHoldTax5: Text[50];
        DesctTotWithHoldTax6: Text[50];
        DesctTotWithHoldTax7: Text[50];
        DescTotINAIL1: Text[50];
        DescTotINAIL2: Text[50];
        RecptMayReportIncome: Boolean;
        SrcWithHoldTax: Boolean;
        GroupNo: Integer;
        Text1042: Label 'Total INAIL';
        DescTotINAIL3: Text[50];
        DescTotINAIL4: Text[50];
        Birth_City___________Birth_County_CaptionLbl: Label 'Birth City';
        SubjectTypeCaptionLbl: Label 'Resident';
        Withholding_Tax__Document_Date_CaptionLbl: Label 'Document Date';
        Withholding_Tax__Payment_Date_CaptionLbl: Label 'Payment Date';
        Withholding_Tax__Related_Date_CaptionLbl: Label 'Related Date';
        Withholding_TaxCaptionLbl: Label 'Withholding Tax';
        INPS__Related_Date_CaptionLbl: Label 'Related Date';
        INPS__Payment_Date_CaptionLbl: Label 'Payment Date';
        INPS__Document_Date_CaptionLbl: Label 'Document Date';
        Social_SecurityCaptionLbl: Label 'Social Security';
        INAIL__Related_Date_CaptionLbl: Label 'Related Date';
        INAIL__Payment_Date_CaptionLbl: Label 'Payment Date';
        INAIL__Document_Date_CaptionLbl: Label 'Document Date';
        INAILCaptionLbl: Label 'INAIL', Locked = true;

    [Scope('OnPrem')]
    procedure SuggDate(DataStart: Date): Date
    var
        Date: Record Date;
    begin
        Date.Reset();

        Date."Period Type" := Date."Period Type"::Month;
        Date."Period Start" := DataStart;
        if Date.Find('>') then begin
            Date."Period Type" := Date."Period Type"::Date;
            if Date.Find('<') then
                exit(Date."Period Start");
        end;
    end;
}

