// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Utilities;
using System.Utilities;

report 12108 "VAT Register Grouped"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/VATRegisterGrouped.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Fiscal Register Grouped';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyInformation_1_; CompanyInformation[1])
            {
            }
            column(CompanyInformation_2_; CompanyInformation[2])
            {
            }
            column(CompanyInformation_3_; CompanyInformation[3])
            {
            }
            column(CompanyInformation_7_; CompanyInformation[7])
            {
            }
            column(CompanyInformation_4_; CompanyInformation[4])
            {
            }
            column(CompanyInformation_6_; CompanyInformation[6])
            {
            }
            column(CompanyInformation_5_; CompanyInformation[5])
            {
            }
            column(StartingDate; Format(StartingDate))
            {
            }
            column(EndingDate; Format(EndingDate))
            {
            }
            column(PrintCompanyInformations; PrintCompanyInformations)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Register_Company_No_Caption; Register_Company_No_CaptionLbl)
            {
            }
            column(CompanyInformation_6_Caption; CompanyInformation_6_CaptionLbl)
            {
            }
            column(CompanyInformation_5_Caption; CompanyInformation_5_CaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not PrintCompanyInformations then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                for i := 1 to 6 do
                    if CompanyInformation[i] = '' then
                        Error(Text1049);
                AccPeriod.Reset();
                AccPeriod.SetRange("New Fiscal Year", true);
                AccPeriod.SetFilter("Starting Date", '<=%1', StartingDate);
                AccPeriod.FindLast();
            end;
        }
        dataitem(ForCode; "VAT Register - Buffer")
        {
            DataItemTableView = sorting("VAT Register Code") order(ascending);
            column(Text10381; Text10381Lbl)
            {
            }
            column(PrintCompanyInformations1; PrintCompanyInformations)
            {
            }
            column(CompanyInformation_1_Control1130214; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + Text1046 + CompanyInformation[5])
            {
            }
            column(CompanyInformation_6__Control1130211; CompanyInformation[6])
            {
            }
            column(Text000___VATRegister_Description; Text000 + VATRegister.Description)
            {
            }
            column(Unrealized_Amount____Signum; "Unrealized Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Unrealized_Base____Signum; "Unrealized Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Amount____Signum; "Nondeductible Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Base____Signum; "Nondeductible Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Amount___Signum; Amount * Signum)
            {
                AutoFormatType = 1;
            }
            column(Base___Signum; Base * Signum)
            {
                AutoFormatType = 1;
            }
            column(ForCode__VAT___; "VAT %")
            {
            }
            column(ForCode__VAT_Deductible___; "VAT Deductible %")
            {
            }
            column(ForCode__VAT_Identifier_; "VAT Identifier")
            {
            }
            column(Unrealized_Amount____Signum_Control1130056; "Unrealized Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Unrealized_Base____Signum_Control1130057; "Unrealized Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Amount____Signum_Control1130058; "Nondeductible Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Base____Signum_Control1130059; "Nondeductible Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Amount___Signum_Control1130060; Amount * Signum)
            {
                AutoFormatType = 1;
            }
            column(Base___Signum_Control1130061; Base * Signum)
            {
                AutoFormatType = 1;
            }
            column(Text001____VAT_Register_Code_; Text001 + "VAT Register Code")
            {
            }
            column(ForCode_Period_Start_Date; "Period Start Date")
            {
            }
            column(ForCode_Period_End_Date; "Period End Date")
            {
            }
            column(ForCode_VAT_Register_Code; "VAT Register Code")
            {
            }
            column(ForCode_Register_Type; "Register Type")
            {
            }
            column(ForCode_VAT_Prod__Posting_Group; "VAT Prod. Posting Group")
            {
            }
            column(CompanyInformation_6__Control1130211Caption; CompanyInformation_6__Control1130211CaptionLbl)
            {
            }
            column(Unrealized_Amount____Signum_Control1130026Caption; Unrealized_Amount____Signum_Control1130026CaptionLbl)
            {
            }
            column(Unrealized_Base____Signum_Control1130029Caption; Unrealized_Base____Signum_Control1130029CaptionLbl)
            {
            }
            column(Nondeductible_Amount____Signum_Control1130033Caption; Nondeductible_Amount____Signum_Control1130033CaptionLbl)
            {
            }
            column(Nondeductible_Base____Signum_Control1130035Caption; Nondeductible_Base____Signum_Control1130035CaptionLbl)
            {
            }
            column(Amount___Signum_Control1130038Caption; Amount___Signum_Control1130038CaptionLbl)
            {
            }
            column(Base___Signum_Control1130041Caption; Base___Signum_Control1130041CaptionLbl)
            {
            }
            column(ForType__VAT___Caption; ForType.FieldCaption("VAT %"))
            {
            }
            column(ForType__VAT_Deductible___Caption; ForType.FieldCaption("VAT Deductible %"))
            {
            }
            column(ForType__VAT_Identifier_Caption; ForType.FieldCaption("VAT Identifier"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if VATRegister.Get("VAT Register Code") then;

                if "Register Type" = "Register Type"::Sale then
                    Signum := -1
                else
                    Signum := 1;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Period Start Date", '>=%1', StartingDate);
                SetFilter("Period End Date", '<=%1', EndingDate);
            end;
        }
        dataitem(ForType; "VAT Register - Buffer")
        {
            DataItemTableView = sorting("Register Type", "VAT Prod. Posting Group", "VAT Identifier", "VAT %", "VAT Deductible %") order(ascending);
            column(PrintCompanyInformations2; PrintCompanyInformations)
            {
            }
            column(Text10382; Text10381Lbl)
            {
            }
            column(CompanyInformation_1_Control1130209; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + Text1046 + CompanyInformation[5])
            {
            }
            column(CompanyInformation_6__Control1130212; CompanyInformation[6])
            {
            }
            column(IsHeader1; "Register Type" = "Register Type"::Purchase)
            {
            }
            column(IsHeader2; "Register Type" = "Register Type"::Sale)
            {
            }
            column(Unrealized_Amount____Signum_Control1130026; "Unrealized Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Unrealized_Base____Signum_Control1130029; "Unrealized Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Amount____Signum_Control1130033; "Nondeductible Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Base____Signum_Control1130035; "Nondeductible Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Amount___Signum_Control1130038; Amount * Signum)
            {
                AutoFormatType = 1;
            }
            column(Base___Signum_Control1130041; Base * Signum)
            {
                AutoFormatType = 1;
            }
            column(ForType__VAT___; "VAT %")
            {
            }
            column(ForType__VAT_Deductible___; "VAT Deductible %")
            {
            }
            column(ForType__VAT_Identifier_; "VAT Identifier")
            {
            }
            column(Signum; Signum)
            {
            }
            column(Unrealized_Amount____Signum_Control1130019; "Unrealized Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Unrealized_Base____Signum_Control1130020; "Unrealized Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Amount____Signum_Control1130021; "Nondeductible Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Base____Signum_Control1130022; "Nondeductible Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Amount___Signum_Control1130023; Amount * Signum)
            {
                AutoFormatType = 1;
            }
            column(Base___Signum_Control1130024; Base * Signum)
            {
                AutoFormatType = 1;
            }
            column(IsFooter2; "Register Type" = "Register Type"::Sale)
            {
            }
            column(Unrealized_Amount____Signum_Control1130011; "Unrealized Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Unrealized_Base____Signum_Control1130012; "Unrealized Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Amount____Signum_Control1130013; "Nondeductible Amount" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Nondeductible_Base____Signum_Control1130014; "Nondeductible Base" * Signum)
            {
                AutoFormatType = 1;
            }
            column(Amount___Signum_Control1130016; Amount * Signum)
            {
                AutoFormatType = 1;
            }
            column(Base___Signum_Control1130017; Base * Signum)
            {
                AutoFormatType = 1;
            }
            column(IsFooter1; "Register Type" = "Register Type"::Purchase)
            {
            }
            column(ForType_Period_Start_Date; "Period Start Date")
            {
            }
            column(ForType_Period_End_Date; "Period End Date")
            {
            }
            column(ForType_VAT_Register_Code; "VAT Register Code")
            {
            }
            column(ForType_Register_Type; "Register Type")
            {
            }
            column(ForType_VAT_Prod__Posting_Group; "VAT Prod. Posting Group")
            {
            }
            column(CompanyInformation_6__Control1130212Caption; CompanyInformation_6__Control1130212CaptionLbl)
            {
            }
            column(Purchase_VAT_Register_SummaryCaption; Purchase_VAT_Register_SummaryCaptionLbl)
            {
            }
            column(Unrealized_Amount____Signum_Control1130026Caption_Control1130028; Unrealized_Amount____Signum_Control1130026Caption_Control1130028Lbl)
            {
            }
            column(Unrealized_Base____Signum_Control1130029Caption_Control1130031; Unrealized_Base____Signum_Control1130029Caption_Control1130031Lbl)
            {
            }
            column(Nondeductible_Amount____Signum_Control1130033Caption_Control1130034; Nondeductible_Amount____Signum_Control1130033Caption_Control1130034Lbl)
            {
            }
            column(Nondeductible_Base____Signum_Control1130035Caption_Control1130037; Nondeductible_Base____Signum_Control1130035Caption_Control1130037Lbl)
            {
            }
            column(Amount___Signum_Control1130038Caption_Control1130040; Amount___Signum_Control1130038Caption_Control1130040Lbl)
            {
            }
            column(Base___Signum_Control1130041Caption_Control1130043; Base___Signum_Control1130041Caption_Control1130043Lbl)
            {
            }
            column(ForType__VAT___Caption_Control1130046; FieldCaption("VAT %"))
            {
            }
            column(ForType__VAT_Deductible___Caption_Control1130052; FieldCaption("VAT Deductible %"))
            {
            }
            column(ForType__VAT_Identifier_Caption_Control1130055; FieldCaption("VAT Identifier"))
            {
            }
            column(Sales_VAT_Register_SummaryCaption; Sales_VAT_Register_SummaryCaptionLbl)
            {
            }
            column(Unrealized_Amount____Signum_Control1130026Caption_Control1130027; Unrealized_Amount____Signum_Control1130026Caption_Control1130027Lbl)
            {
            }
            column(Unrealized_Base____Signum_Control1130029Caption_Control1130030; Unrealized_Base____Signum_Control1130029Caption_Control1130030Lbl)
            {
            }
            column(Nondeductible_Amount____Signum_Control1130033Caption_Control1130032; Nondeductible_Amount____Signum_Control1130033Caption_Control1130032Lbl)
            {
            }
            column(Nondeductible_Base____Signum_Control1130035Caption_Control1130036; Nondeductible_Base____Signum_Control1130035Caption_Control1130036Lbl)
            {
            }
            column(Amount___Signum_Control1130038Caption_Control1130039; Amount___Signum_Control1130038Caption_Control1130039Lbl)
            {
            }
            column(Base___Signum_Control1130041Caption_Control1130042; Base___Signum_Control1130041Caption_Control1130042Lbl)
            {
            }
            column(ForType__VAT___Caption_Control1130045; FieldCaption("VAT %"))
            {
            }
            column(ForType__VAT_Deductible___Caption_Control1130051; FieldCaption("VAT Deductible %"))
            {
            }
            column(ForType__VAT_Identifier_Caption_Control1130054; FieldCaption("VAT Identifier"))
            {
            }
            column(Totals_for_salesCaption; Totals_for_salesCaptionLbl)
            {
            }
            column(Totals_for_purchaseCaption; Totals_for_purchaseCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Register Type" = "Register Type"::Sale then
                    Signum := -1
                else
                    Signum := 1;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Period Start Date", '>=%1', StartingDate);
                SetFilter("Period End Date", '<=%1', EndingDate);
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
                    field(PeriodStartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';
                        ToolTip = 'Specifies the period starting date.';
                    }
                    field(PeriodEndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                        ToolTip = 'Specifies the period ending date.';
                    }
                    field(PrintCompanyInformations; PrintCompanyInformations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Informations';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print your company information.';
                    }
                    field(Name; CompanyInformation[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name.';
                    }
                    field(Address; CompanyInformation[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the company''s address.';
                    }
                    field(PostCodeCityCounty; CompanyInformation[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code  City  County';
                        ToolTip = 'Specifies the post code, city, and county.';
                    }
                    field(RegisterCompanyNo; CompanyInformation[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Register Company No.';
                        ToolTip = 'Specifies the register company number.';
                    }
                    field(VATRegistrationNo; CompanyInformation[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                    }
                    field(FiscalCode; CompanyInformation[6])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Code';
                        ToolTip = 'Specifies the fiscal code.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PrintCompanyInformations := true;
            CompInfo.Get();
            CompanyInformation[1] := CompInfo.Name;
            CompanyInformation[2] := CompInfo.Address;
            CompanyInformation[3] := CompInfo."Post Code" + '  ' + CompInfo.City + '  ' + CompInfo.County;
            CompanyInformation[4] := CompInfo."Register Company No.";
            CompanyInformation[5] := CompInfo."VAT Registration No.";
            CompanyInformation[6] := CompInfo."Fiscal Code";
            CompanyInformation[7] := Text000;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        ITReportManagement.CheckSalesDocNoGaps(EndingDate, true, false);
        ITReportManagement.CheckPurchDocNoGaps(EndingDate, true, false);
    end;

    var
        Text000: Label 'Register Summary ';
        Text001: Label 'Totals for register ';
        VATRegister: Record "VAT Register";
        CompInfo: Record "Company Information";
        AccPeriod: Record "Accounting Period";
        StartingDate: Date;
        EndingDate: Date;
        Signum: Integer;
        PrintCompanyInformations: Boolean;
        CompanyInformation: array[7] of Text[100];
        Text1046: Label 'VAT Reg. No. ';
        Text1049: Label 'All Company Information related fields should be filled in on the request form.';
        i: Integer;
        Register_Company_No_CaptionLbl: Label 'Register Company No.';
        CompanyInformation_6_CaptionLbl: Label 'Fiscal Code';
        CompanyInformation_5_CaptionLbl: Label 'VAT Reg. No.';
        PeriodCaptionLbl: Label 'Period';
        Text10381Lbl: Label 'Page %1';
        CompanyInformation_6__Control1130211CaptionLbl: Label 'Fiscal Code';
        Unrealized_Amount____Signum_Control1130026CaptionLbl: Label 'Unrealized Amount';
        Unrealized_Base____Signum_Control1130029CaptionLbl: Label 'Unrealized Base';
        Nondeductible_Amount____Signum_Control1130033CaptionLbl: Label 'Nondeductible Amount';
        Nondeductible_Base____Signum_Control1130035CaptionLbl: Label 'Nondeductible Base';
        Amount___Signum_Control1130038CaptionLbl: Label 'Amount';
        Base___Signum_Control1130041CaptionLbl: Label 'Base';
        CompanyInformation_6__Control1130212CaptionLbl: Label 'Fiscal Code';
        Purchase_VAT_Register_SummaryCaptionLbl: Label 'Purchase VAT Register Summary';
        Unrealized_Amount____Signum_Control1130026Caption_Control1130028Lbl: Label 'Unrealized Amount';
        Unrealized_Base____Signum_Control1130029Caption_Control1130031Lbl: Label 'Unrealized Base';
        Nondeductible_Amount____Signum_Control1130033Caption_Control1130034Lbl: Label 'Nondeductible Amount';
        Nondeductible_Base____Signum_Control1130035Caption_Control1130037Lbl: Label 'Nondeductible Base';
        Amount___Signum_Control1130038Caption_Control1130040Lbl: Label 'Amount';
        Base___Signum_Control1130041Caption_Control1130043Lbl: Label 'Base';
        Sales_VAT_Register_SummaryCaptionLbl: Label 'Sales VAT Register Summary';
        Unrealized_Amount____Signum_Control1130026Caption_Control1130027Lbl: Label 'Unrealized Amount';
        Unrealized_Base____Signum_Control1130029Caption_Control1130030Lbl: Label 'Unrealized Base';
        Nondeductible_Amount____Signum_Control1130033Caption_Control1130032Lbl: Label 'Nondeductible Amount';
        Nondeductible_Base____Signum_Control1130035Caption_Control1130036Lbl: Label 'Nondeductible Base';
        Amount___Signum_Control1130038Caption_Control1130039Lbl: Label 'Amount';
        Base___Signum_Control1130041Caption_Control1130042Lbl: Label 'Base';
        Totals_for_salesCaptionLbl: Label 'Totals for sales';
        Totals_for_purchaseCaptionLbl: Label 'Totals for purchase';
}

