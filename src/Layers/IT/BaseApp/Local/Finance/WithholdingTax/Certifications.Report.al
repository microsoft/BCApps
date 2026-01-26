// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 12106 Certifications
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/Certifications.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Certifications';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(SubstituteData_NNC; SubstituteData)
            {
            }
            column(Vendor__Birth_Date_; "Date of Birth")
            {
            }
            column(Vendor__Birth_City_; "Birth City")
            {
            }
            column(CompanyInfo__REA_No__; CompanyInfo."REA No.")
            {
            }
            column(CompanyInfo__Register_Company_No__; CompanyInfo."Register Company No.")
            {
            }
            column(Vendor_Resident; Resident)
            {
            }
            column(Vendor__Fiscal_Code_; "Fiscal Code")
            {
            }
            column(CompanyInfo__Fiscal_Code_; CompanyInfo."Fiscal Code")
            {
            }
            column(CompanyInfo__FD_Post_Code_; CompanyInfo."FD Post Code")
            {
            }
            column(CompanyInfo__FD_City____CompanyInfo__FD_County_; CompanyInfo."FD City" + CompanyInfo."FD County")
            {
            }
            column(Vendor__Country_Region_Code_; "Country/Region Code")
            {
            }
            column(Country_Name; Country.Name)
            {
            }
            column(Vendor_City; City)
            {
            }
            column(CompanyInfo__FD_Address_; CompanyInfo."FD Address")
            {
            }
            column(Vendor_Address; VendorAddress)
            {
            }
            column(CompanyInfo__Post_Code_; CompanyInfo."Post Code")
            {
            }
            column(CompanyInfo_City___CompanyInfo_County; CompanyInfo.City + CompanyInfo.County)
            {
            }
            column(CompanyInfo_Address; CompanyInfo.Address)
            {
            }
            column(Name__________Name_2_; VendorName)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(CompanyInfo_Name_________CompanyInfo__Name_2_; CompanyInfo.Name + ' ' + CompanyInfo."Name 2")
            {
            }
            column(Vendor_County; County)
            {
            }
            column(Vendor__Birth_County_; "Birth County")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(INPS_NNC; INPS)
            {
            }
            column(Country_Name_Control1130038; Country.Name)
            {
            }
            column(Vendor__Birth_Date__Control1130039; "Date of Birth")
            {
            }
            column(Vendor_Resident_Control1130040; Resident)
            {
            }
            column(Vendor__Fiscal_Code__Control1130041; "Fiscal Code")
            {
            }
            column(Vendor_City_Control1130042; City)
            {
            }
            column(Vendor__Country_Region_Code__Control1130043; "Country/Region Code")
            {
            }
            column(Vendor_Address_Control1130050; Address)
            {
            }
            column(Name__________Name_2__Control1130052; Name + ' ' + "Name 2")
            {
            }
            column(Vendor__No___Control1130054; "No.")
            {
            }
            column(Vendor__Birth_County__Control1130123; "Birth County")
            {
            }
            column(Vendor__Birth_City__Control1130125; "Birth City")
            {
            }
            column(Vendor_County_Control1130126; County)
            {
            }
            column(OtherCommunications; OtherCommunications)
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(DataReporting; DataReporting)
            {
            }
            column(Vendor__Birth_Date_Caption; FieldCaption("Date of Birth"))
            {
            }
            column(Vendor__Birth_City_Caption; Vendor__Birth_City_CaptionLbl)
            {
            }
            column(CompanyInfo__REA_No__Caption; CompanyInfo__REA_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Register_Company_No__Caption; CompanyInfo__Register_Company_No__CaptionLbl)
            {
            }
            column(Vendor_ResidentCaption; FieldCaption(Resident))
            {
            }
            column(Vendor__Fiscal_Code_Caption; FieldCaption("Fiscal Code"))
            {
            }
            column(CompanyInfo__Fiscal_Code_Caption; CompanyInfo__Fiscal_Code_CaptionLbl)
            {
            }
            column(Vendor__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
            {
            }
            column(CompanyInfo__FD_City____CompanyInfo__FD_County_Caption; CompanyInfo__FD_City____CompanyInfo__FD_County_CaptionLbl)
            {
            }
            column(CompanyInfo__FD_Address_Caption; CompanyInfo__FD_Address_CaptionLbl)
            {
            }
            column(Vendor_CityCaption; Vendor_CityCaptionLbl)
            {
            }
            column(Vendor_AddressCaption; FieldCaption(Address))
            {
            }
            column(CompanyInfo_City___CompanyInfo_CountyCaption; CompanyInfo_City___CompanyInfo_CountyCaptionLbl)
            {
            }
            column(CompanyInfo_AddressCaption; CompanyInfo_AddressCaptionLbl)
            {
            }
            column(Name__________Name_2_Caption; Name__________Name_2_CaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(CompanyInfo_Name_________CompanyInfo__Name_2_Caption; CompanyInfo_Name_________CompanyInfo__Name_2_CaptionLbl)
            {
            }
            column(Vendor__Birth_Date__Control1130039Caption; FieldCaption("Date of Birth"))
            {
            }
            column(Vendor_Resident_Control1130040Caption; FieldCaption(Resident))
            {
            }
            column(Vendor__Fiscal_Code__Control1130041Caption; FieldCaption("Fiscal Code"))
            {
            }
            column(Vendor__Country_Region_Code__Control1130043Caption; FieldCaption("Country/Region Code"))
            {
            }
            column(Vendor_City_Control1130042Caption; Vendor_City_Control1130042CaptionLbl)
            {
            }
            column(Vendor_Address_Control1130050Caption; FieldCaption(Address))
            {
            }
            column(Name__________Name_2__Control1130052Caption; Name__________Name_2__Control1130052CaptionLbl)
            {
            }
            column(Vendor__No___Control1130054Caption; FieldCaption("No."))
            {
            }
            column(Vendor__Birth_City__Control1130125Caption; Vendor__Birth_City__Control1130125CaptionLbl)
            {
            }
            column(CompanyInfo_NameCaption; CompanyInfo_NameCaptionLbl)
            {
            }
            column(OtherCommunicationsCaption; OtherCommunicationsCaptionLbl)
            {
            }
            column(DataReportingCaption; DataReportingCaptionLbl)
            {
            }
            dataitem("Withholding Tax"; "Withholding Tax")
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "Source-Withholding Tax", "Recipient May Report Income", "Withholding Tax Code", "Withholding Tax %");
                column(HeaderText_1____HeaderText_2____HeaderText_3_; HeaderText[1] + HeaderText[2] + HeaderText[3])
                {
                }
                column(RecptMayReportIncome; RecptMayReportIncome)
                {
                }
                column(SrcWithHoldTax; SrcWithHoldTax)
                {
                }
                column(Descr; Descr)
                {
                }
                column(DescrWithHoldTax3; DescrWithHoldTax3)
                {
                }
                column(DescrWithHoldTax2; DescrWithHoldTax2)
                {
                }
                column(DescrWithHoldTax1; DescrWithHoldTax1)
                {
                }
                column(Withholding_Tax__Withholding_Tax_Amount_; "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_By_Treaty_; "Non Taxable Amount By Treaty")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Base___Excluded_Amount_; "Base - Excluded Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Total_Amount_; "Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Taxable_Base_; "Taxable Base")
                {
                    AutoFormatType = 1;
                }
                column(Taxable_Base___Withholding_Tax_Amount_; "Taxable Base" - "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Descr_Control1130250; Descr)
                {
                }
                column(Withholding_Tax__Withholding_Tax___; WithholdTaxPercent)
                {
                }
                column(DescrWithHoldTax4; DescrWithHoldTax4)
                {
                }
                column(DescrWithHoldTax5; DescrWithHoldTax5)
                {
                }
                column(DescrWithHoldTax6; DescrWithHoldTax6)
                {
                }
                column(DescrWithHoldTax7; DescrWithHoldTax7)
                {
                }
                column(WithholdTaxCodeDescription; WithholdTaxCode.Description)
                {
                }
                column(Taxable_Base___Withholding_Tax_Amount__Control3; "Taxable Base" - "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Withholding_Tax_Amount__Control5; "Withholding Tax Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Taxable_Base__Control11; "Taxable Base")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount__Control12; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Non_Taxable_Amount_By_Treaty__Control15; "Non Taxable Amount By Treaty")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Base___Excluded_Amount__Control17; "Base - Excluded Amount")
                {
                    AutoFormatType = 1;
                }
                column(Withholding_Tax__Total_Amount__Control18; "Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(Descr_Control1130234; Descr)
                {
                }
                column(Withholding_Tax_Entry_No_; "Entry No.")
                {
                }
                column(Withholding_Tax_Source_Withholding_Tax; "Source-Withholding Tax")
                {
                }
                column(Withholding_Tax_Recipient_May_Report_Income; "Recipient May Report Income")
                {
                }
                column(Withholding_Tax_Withholding_Tax_Code; "Withholding Tax Code")
                {
                }
                column(Withholding_Tax_Withholding_Tax__; "Withholding Tax %")
                {
                }
                column(Withholding_Tax_Vendor_No_; "Vendor No.")
                {
                }
                column(Withholding_TaxesCaption; Withholding_TaxesCaptionLbl)
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
                column(Withholding_Tax__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
                {
                }
                column(Withholding_Tax__Taxable_Base_Caption; FieldCaption("Taxable Base"))
                {
                }
                column(Withholding_Tax__Withholding_Tax___Caption; Withholding_Tax__Withholding_Tax___CaptionLbl)
                {
                }
                column(Withholding_Tax__Withholding_Tax_Amount_Caption; FieldCaption("Withholding Tax Amount"))
                {
                }
                column(Taxable_Base___Withholding_Tax_Amount_Caption; Taxable_Base___Withholding_Tax_Amount_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DescrWithHoldTax1 := Text1043;
                    DescrWithHoldTax2 := Text1044;
                    DescrWithHoldTax3 := Text1045 + Text1046;
                    DescrWithHoldTax4 := Text1047;
                    DescrWithHoldTax5 := '  ' + Format("Withholding Tax %") + '% ' + WithholdTaxCode.Description;
                    DescrWithHoldTax6 := Text1048;
                    DescrWithHoldTax7 := Text1049;

                    if not OnlyWithholdTax then
                        CurrReport.Skip();

                    if not WithholdTaxCode.Get("Withholding Tax Code") then
                        WithholdTaxCode.Init();

                    if FinalReporting and
                       not CurrReport.Preview
                    then
                        if OnlyWithholdTax then begin
                            Reported := true;
                            Modify();
                        end;

                    HeaderText[1] := Text1038 +
                      Text1039;

                    if FromRelatedDate <> 0D then
                        HeaderText[2] := Text1040 +
                          Format(FromRelatedDate, 0) + Text1041 + Format(ToRelatedDate, 0) + ',';

                    HeaderText[3] := Text1042 +
                      Format(FromPaymentDate, 0) + Text1041 + Format(ToPaymentDate, 0);

                    Descr := Text1050 + Vendor.Name;
                    WithholdTaxPercent := "Withholding Tax %";
                    if not "Source-Withholding Tax" then
                        Descr := Text1047
                    else
                        if "Recipient May Report Income" then
                            Descr := Text1048
                        else
                            Descr := Text1049;
                    INPS := true;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);
                    SetRange(Reported, false);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    INPS := false;
                end;
            }
            dataitem(Contributions; Contributions)
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "Social Security Code", "Social Security %") order(ascending);
                column(HeaderText_1___HeaderText_2____HeaderText_3_; HeaderText[1] + HeaderText[2] + HeaderText[3])
                {
                }
                column(ContribDescr; '  ' + INPSContribCode.Description + ' ' + Format("Social Security %") + '%')
                {
                }
                column(Contributions__Gross_Amount_; "Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Non_Taxable_Amount_; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Contribution_Base_; "Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Total_Social_Security_Amount_; "Total Social Security Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Free_Lance_Amount_; "Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Company_Amount_; "Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(Descr_Control1130089; Descr)
                {
                }
                column(Contributions__Gross_Amount__Control1130081; "Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Free_Lance_Amount__Control1130082; "Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Total_Social_Security_Amount__Control1130083; "Total Social Security Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Contribution_Base__Control1130084; "Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Company_Amount__Control1130085; "Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(Contributions__Non_Taxable_Amount__Control1130086; "Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(Descr_Control1130087; Descr)
                {
                }
                column(Contributions_Entry_No_; "Entry No.")
                {
                }
                column(Contributions_Social_Security_Code; "Social Security Code")
                {
                }
                column(Contributions_Social_Security__; "Social Security %")
                {
                }
                column(Contributions_Vendor_No_; "Vendor No.")
                {
                }
                column(Social_SecurityCaption; Social_SecurityCaptionLbl)
                {
                }
                column(Contributions__Gross_Amount_Caption; FieldCaption("Gross Amount"))
                {
                }
                column(Contributions__Non_Taxable_Amount_Caption; FieldCaption("Non Taxable Amount"))
                {
                }
                column(Contributions__Contribution_Base_Caption; FieldCaption("Contribution Base"))
                {
                }
                column(Contributions__Total_Social_Security_Amount_Caption; FieldCaption("Total Social Security Amount"))
                {
                }
                column(Contributions__Free_Lance_Amount_Caption; FieldCaption("Free-Lance Amount"))
                {
                }
                column(Contributions__Company_Amount_Caption; FieldCaption("Company Amount"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not OnlyINPS then
                        CurrReport.Skip();

                    if not INPSContribCode.Get("Social Security Code", INPSContribCode."Contribution Type"::INPS) then
                        INPSContribCode.Init();

                    if FinalReporting and not CurrReport.Preview and OnlyINPS then begin
                        Reported := true;
                        Modify();
                    end;

                    HeaderText[1] := Text1051 + Format(FromPaymentDate, 0) +
                      Text1041 + Format(ToPaymentDate, 0);

                    if FromRelatedDate <> 0D then
                        HeaderText[2] := Text1040 + Format(FromRelatedDate, 0) + Text1041 +
                          Format(ToRelatedDate, 0) + ',';

                    HeaderText[3] := Text1052 +
                      Text1053;

                    Descr := Text1050 + Vendor.Name;
                end;

                trigger OnPreDataItem()
                var
                    Contributions: Record Contributions;
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);
                    SetRange(Reported, false);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    if OnlyWithholdTax and OnlyINPS then
                        PageGroupNo += 1;
                    Contributions.SetRange("Vendor No.", Vendor."No.");
                    Contributions.SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);
                    Contributions.SetRange(Reported, false);
                    if Contributions.IsEmpty() then
                        INPS := false;
                end;
            }
            dataitem(INAIL; Contributions)
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "INAIL Code", "INAIL Per Mil") order(ascending);
                column(HeaderText_1___HeaderText_2____HeaderText_3__Control1130096; HeaderText[1] + HeaderText[2] + HeaderText[3])
                {
                }
                column(INAILDescr; StrSubstNo(Text1054, INPSContribCode.Description, "INAIL Per Mil"))
                {
                }
                column(INAIL__INAIL_Company_Amount_; "INAIL Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Free_Lance_Amount_; "INAIL Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Total_Amount_; "INAIL Total Amount")
                {
                    AutoFormatType = 1;
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
                column(Descr_Control1130105; Descr)
                {
                }
                column(INAIL__INAIL_Company_Amount__Control1130106; "INAIL Company Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Free_Lance_Amount__Control1130107; "INAIL Free-Lance Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Total_Amount__Control1130108; "INAIL Total Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Contribution_Base__Control1130109; "INAIL Contribution Base")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Non_Taxable_Amount__Control1130110; "INAIL Non Taxable Amount")
                {
                    AutoFormatType = 1;
                }
                column(INAIL__INAIL_Gross_Amount__Control1130111; "INAIL Gross Amount")
                {
                    AutoFormatType = 1;
                }
                column(Descr_Control1130112; Descr)
                {
                }
                column(INAIL_Entry_No_; "Entry No.")
                {
                }
                column(INAIL_INAIL_Code; "INAIL Code")
                {
                }
                column(INAIL_INAIL_Per_Mil; "INAIL Per Mil")
                {
                }
                column(INAIL_Vendor_No_; "Vendor No.")
                {
                }
                column(INAIL__INAIL_Company_Amount_Caption; INAIL__INAIL_Company_Amount_CaptionLbl)
                {
                }
                column(INAIL__INAIL_Free_Lance_Amount_Caption; FieldCaption("INAIL Free-Lance Amount"))
                {
                }
                column(INAIL__INAIL_Total_Amount_Caption; INAIL__INAIL_Total_Amount_CaptionLbl)
                {
                }
                column(INAIL__INAIL_Contribution_Base_Caption; FieldCaption("INAIL Contribution Base"))
                {
                }
                column(INAIL__INAIL_Non_Taxable_Amount_Caption; FieldCaption("INAIL Non Taxable Amount"))
                {
                }
                column(INAIL__INAIL_Gross_Amount_Caption; INAIL__INAIL_Gross_Amount_CaptionLbl)
                {
                }
                column(INAILCaption; INAILCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not OnlyINAIL then
                        CurrReport.Skip();

                    if not INPSContribCode.Get("INAIL Code", INPSContribCode."Contribution Type"::INAIL) then
                        INPSContribCode.Init();

                    if FinalReporting and not CurrReport.Preview and OnlyINAIL then begin
                        Reported := true;
                        Modify();
                    end;

                    HeaderText[1] := Text1051 + Format(FromPaymentDate, 0) +
                      Text1041 + Format(ToPaymentDate, 0);

                    if FromRelatedDate <> 0D then
                        HeaderText[2] := Text1040 + Format(FromRelatedDate, 0) + Text1041 +
                          Format(ToRelatedDate, 0) + ',';

                    HeaderText[3] := Text1052 +
                      Text1053;

                    Descr := Text1050 + Vendor.Name;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Payment Date", '%1..%2', FromPaymentDate, ToPaymentDate);
                    SetRange(Reported, false);

                    if FromRelatedDate <> 0D then
                        SetFilter("Related Date", '%1..%2', FromRelatedDate, ToRelatedDate);

                    if (OnlyWithholdTax and OnlyINAIL) or (OnlyINPS and OnlyINAIL) then
                        PageGroupNo += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not Country.Get("Country/Region Code") then
                    Country.Init();

                PageGroupNo := 1;

                if "Individual Person" then begin
                    VendorName := "First Name" + ' ' + "Last Name";
                    VendorAddress := "Residence Address";
                end else begin
                    VendorName := Name + ' ' + "Name 2";
                    VendorAddress := Address;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
            end;
        }
    }

    requestpage
    {

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
                    }
                    field(ToRelatedDate; ToRelatedDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Related Date';
                        ToolTip = 'Specifies the last related date.';
                    }
                    field(ReportingFinale; FinalReporting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Finale';
                        ToolTip = 'Specifies the reporting finale.';
                    }
                    field(PrintSubstituteData; SubstituteData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Substitute Data';
                        ToolTip = 'Specifies if you want to print substitute data.';
                    }
                    field(OnlyWithholdTax; OnlyWithholdTax)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Withholding Taxes Certification';
                        ToolTip = 'Specifies the withholding taxes certification.';
                    }
                    field(INPSCertification; OnlyINPS)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'INPS Certification';
                        ToolTip = 'Specifies if this is an INPS certification.';
                    }
                    field(INAILCertification; OnlyINAIL)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'INAIL Certification';
                        ToolTip = 'Specifies if this is an INAIL certification.';
                    }
                    field(DataReporting; DataReporting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Date';
                        ToolTip = 'Specifies the reporting date.';
                    }
                    field(OtherCommunications; OtherCommunications)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Other Information';
                        MultiLine = true;
                        ToolTip = 'Specifies other information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            DataReporting := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnlyWithholdTax := true;
        OnlyINPS := true;
        OnlyINAIL := true;
    end;

    trigger OnPreReport()
    begin
        if (not OnlyWithholdTax) and
           (not OnlyINPS) and (not OnlyINAIL)
        then
            Error(Text1033);

        if (FromPaymentDate = 0D) or
           (ToPaymentDate = 0D)
        then
            Error(Text1034);

        if ((FromRelatedDate = 0D) and (ToRelatedDate <> 0D)) or
           ((FromRelatedDate <> 0D) and (ToRelatedDate = 0D))
        then
            Error(Text1035);
    end;

    var
        Text1033: Label 'Please select at least a certification.';
        Text1034: Label 'Please enter both From Payment Date and To Payment Date.';
        Text1035: Label 'Please enter both From Related Date and To Related Date.';
        Text1038: Label 'According to the law article 7-bis of the D.P.R. 29 September 1973 ';
        Text1039: Label 'and to any of its subsequent change or integration, it is certified that the following compensation';
        Text1040: Label ', referring to period from ';
        Text1041: Label ' to ';
        Text1042: Label ' has been paid and the corresponding withholding taxes have been withheld during period from ';
        Text1043: Label 'Amounts liable to In Advance Withholding Tax.';
        Text1044: Label 'Amounts liable to Source-Withholding Tax that should not be included in income-tax return';
        Text1045: Label 'Amounts liable to Source-Withholding Tax that recipient may ask to contribute to ';
        Text1046: Label 'included in total income.';
        Text1047: Label 'IN ADVANCE WITHHOLDING TAX TOTAL';
        Text1048: Label 'SOURCE-WITHHOLDING TAX TOTAL THAT RECIPIENT MAY REPORT';
        Text1049: Label 'SOURCE-WITHHOLDING TAX TOTAL THAT RECIPIENT CAN NOT REPORT';
        Text1050: Label 'Total ';
        Text1051: Label 'It is certified that compensation referring to period from ';
        Text1052: Label ' has been subject to Social Security contribution charged to ';
        Text1053: Label 'the recipient as per the following rate.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        WithholdTaxCode: Record "Withhold Code";
        INPSContribCode: Record "Contribution Code";
        SubstituteData: Boolean;
        FinalReporting: Boolean;
        INPS: Boolean;
        OnlyWithholdTax: Boolean;
        OnlyINPS: Boolean;
        DataReporting: Date;
        FromPaymentDate: Date;
        ToPaymentDate: Date;
        FromRelatedDate: Date;
        ToRelatedDate: Date;
        OtherCommunications: Text[250];
        Descr: Text[250];
        HeaderText: array[3] of Text[250];
        OnlyINAIL: Boolean;
        DescrWithHoldTax1: Text[250];
        DescrWithHoldTax2: Text[250];
        DescrWithHoldTax3: Text[250];
        DescrWithHoldTax4: Text[250];
        DescrWithHoldTax5: Text[250];
        DescrWithHoldTax6: Text[250];
        DescrWithHoldTax7: Text[250];
        RecptMayReportIncome: Boolean;
        SrcWithHoldTax: Boolean;
        PageGroupNo: Integer;
        WithholdTaxPercent: Decimal;
        Text1054: Label '%1 %2 per mil', Comment = '%1 - ContribCode Description,%2 - "INAIL Per Mil"';
        Vendor__Birth_City_CaptionLbl: Label 'Birth City';
        CompanyInfo__REA_No__CaptionLbl: Label 'REA No.';
        CompanyInfo__Register_Company_No__CaptionLbl: Label 'Register Company No.';
        CompanyInfo__Fiscal_Code_CaptionLbl: Label 'Fiscal Code';
        CompanyInfo__FD_City____CompanyInfo__FD_County_CaptionLbl: Label 'City';
        CompanyInfo__FD_Address_CaptionLbl: Label 'Fiscal Address';
        Vendor_CityCaptionLbl: Label 'City';
        CompanyInfo_City___CompanyInfo_CountyCaptionLbl: Label 'City';
        CompanyInfo_AddressCaptionLbl: Label 'Legal Office Address';
        Name__________Name_2_CaptionLbl: Label 'Name';
        CompanyInfo_Name_________CompanyInfo__Name_2_CaptionLbl: Label 'Company Name';
        Vendor_City_Control1130042CaptionLbl: Label 'City';
        Name__________Name_2__Control1130052CaptionLbl: Label 'Name';
        Vendor__Birth_City__Control1130125CaptionLbl: Label 'Birth City';
        CompanyInfo_NameCaptionLbl: Label 'Name';
        OtherCommunicationsCaptionLbl: Label 'Other Information';
        DataReportingCaptionLbl: Label 'Reporting Date';
        Withholding_TaxesCaptionLbl: Label 'Withholding Taxes';
        Withholding_Tax__Withholding_Tax___CaptionLbl: Label 'Withholding Tax %';
        Taxable_Base___Withholding_Tax_Amount_CaptionLbl: Label 'Net Amount';
        Social_SecurityCaptionLbl: Label 'Social Security';
        INAIL__INAIL_Company_Amount_CaptionLbl: Label 'INAIL - Company Amount';
        INAIL__INAIL_Total_Amount_CaptionLbl: Label 'INAIL Contribution Total Amount';
        INAIL__INAIL_Gross_Amount_CaptionLbl: Label 'INAIL Taxable Gross Amount';
        INAILCaptionLbl: Label 'INAIL';
        VendorName: Text;
        VendorAddress: Text;
}

