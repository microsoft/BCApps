// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

report 12181 "VAT Exemption Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/VATExemptionRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Exemption Register';
    Permissions = TableData "VAT Entry" = rm;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Exemption"; "VAT Exemption")
        {
            DataItemTableView = sorting(Type, "No.", "VAT Exempt. Int. Registry No.");
            RequestFilterFields = Type;
            column(PrintType; PrintType)
            {
            }
            column(CompAddr5; CompAddr[5])
            {
            }
            column(CompAddr4; CompAddr[4])
            {
            }
            column(CompAddr3; CompAddr[3])
            {
            }
            column(CompAddr2; CompAddr[2])
            {
            }
            column(CompAddr1; CompAddr[1])
            {
            }
            column(StartingYearPageFormat; Format(StartingYear) + '/' + Format(StartingPage))
            {
            }
            column(StartingYear; StartingYear)
            {
            }
            column(StartingPage; StartingPage)
            {
            }
            column(StartDate; StartDate)
            {
            }
            column(EndDate; EndDate)
            {
            }
            column(VATExemptionType; Type)
            {
            }
            column(VATExemptStartingDate_VATExempt; "VAT Exempt. Starting Date")
            {
            }
            column(VATExemptNo_VATExempt; "VAT Exempt. No.")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(CustVATExemptRegCaption; CustVATExemtionRegCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(IntRegistryNoCaption; IntRegistryNoCaptionLbl)
            {
            }
            column(VATExemptNoCaption; VATExemptNoCaptionLbl)
            {
            }
            column(StartingDateCaption; StartingDateCaptionLbl)
            {
            }
            column(OfficeCaption; OfficeCaptionLbl)
            {
            }
            column(VATRegCaption; VATRegCaptionLbl)
            {
            }
            column(NameAddrCaption; NameAddrCaptionLbl)
            {
            }
            column(EndingDateCaption; EndingDateCaptionLbl)
            {
            }
            column(IntRegistryDateCaption; IntRegistryDateCaptionLbl)
            {
            }
            column(VendVATExemptRegCaption; VendVATExemtionRegCaptionLbl)
            {
            }
            column(CustVATExemptionType; VATExemptionTypeCust)
            {
            }
            column(VendVATExemptionType; VATExemptionTypeVend)
            {
            }
            column(VATExemptionTypeFilter; VATExemptionTypeFilter)
            {
            }
            dataitem(Cust; Customer)
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.");
                column(VATExemptIntRegistryNo; "VAT Exemption"."VAT Exempt. Int. Registry No.")
                {
                }
                column(VATExemptNo; "VAT Exemption".GetVATExemptNo())
                {
                }
                column(VATExemptStartingDate; "VAT Exemption"."VAT Exempt. Starting Date")
                {
                }
                column(VATExemptOffice; "VAT Exemption"."VAT Exempt. Office")
                {
                }
                column(VATRegNo_Cust; "VAT Registration No.")
                {
                }
                column(Name_Cust; Name)
                {
                }
                column(Address_Cust; Address)
                {
                }
                column(PostCodeCity_Cust; "Post Code" + City)
                {
                }
                column(VATExemptEndingDate; "VAT Exemption"."VAT Exempt. Ending Date")
                {
                }
                column(VATExemptIntRegistryDate; "VAT Exemption"."VAT Exempt. Int. Registry Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "VAT Exemption".Type <> "VAT Exemption".Type::Customer then
                        CurrReport.Skip();
                end;
            }
            dataitem(Vend; Vendor)
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.");
                column(VATExemptIntRegistryNoVend; "VAT Exemption"."VAT Exempt. Int. Registry No.")
                {
                }
                column(VATExemptOfficeVend; "VAT Exemption"."VAT Exempt. Office")
                {
                }
                column(VATRegistrationNoVend; "VAT Registration No.")
                {
                }
                column(Name_Vend; Name)
                {
                }
                column(Address_Vend; Address)
                {
                }
                column(PostCodeCity_Vend; "Post Code" + City)
                {
                }
                column(VATExemptEndingDateVend; "VAT Exemption"."VAT Exempt. Ending Date")
                {
                }
                column(VATExemptIntRegistryDateVend; "VAT Exemption"."VAT Exempt. Int. Registry Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "VAT Exemption".Type <> "VAT Exemption".Type::Vendor then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if (PrintType = PrintType::"Final Print") and (not CurrReport.Preview) then begin
                    Printed := true;
                    Modify();
                end;
                VATExemptionTypeFilter := Type;
            end;

            trigger OnPreDataItem()
            var
                VATExemption: Record "VAT Exemption";
            begin
                VATExemption.Reset();
                VATExemption.SetRange(Type, GetRangeMin(Type));
                VATExemption.SetFilter("VAT Exempt. Int. Registry Date", '<%1', StartDate);
                VATExemption.SetRange(Printed, false);
                if VATExemption.FindFirst() then
                    Error(Text12100, VATExemption.GetVATExemptNo());

                SetCurrentKey("VAT Exempt. Int. Registry No.", Type, "No.");
                SetRange("VAT Exempt. Int. Registry Date", StartDate, EndDate);
                if PrintType = PrintType::Reprint then
                    SetRange(Printed, true)
                else
                    SetRange(Printed, false)
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
                    field(ReportType; PrintType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Type';
                        ToolTip = 'Specifies the report type.';
                    }
                    field(StartingYear; StartingYear)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Starting Year';
                        ToolTip = 'Specifies the starting year.';
                    }
                    field(StartingPage; StartingPage)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Starting Page';
                        ToolTip = 'Specifies the starting page.';
                    }
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date.';

                        trigger OnValidate()
                        begin
                            CalcEndingDate();
                        end;
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if StartDate = 0D then
            Error(Text12101);
        if EndDate = 0D then
            Error(Text12104);
        if StartDate > EndDate then
            Error(Text12102);
        if (StartingYear = 0) or (StartingPage = 0) then
            Error(Text12103);

        if "VAT Exemption".GetRangeMin(Type) <> "VAT Exemption".GetRangeMax(Type) then
            Error(Text12105);

        CompanyInfo.Get();
        CompAddr[1] := CompanyInfo.Name;
        CompAddr[2] := CompanyInfo.Address;
        CompAddr[3] := CompanyInfo."Post Code";
        CompAddr[4] := CompanyInfo.City;
        CompAddr[5] := CompanyInfo."VAT Registration No.";
        CompressArray(CompAddr);

        VATExemptionTypeVend := "VAT Exemption".Type::Vendor;
        VATExemptionTypeCust := "VAT Exemption".Type::Customer;
    end;

    var
        CompanyInfo: Record "Company Information";
        PrintType: Option "Test Print","Final Print",Reprint;
        CompAddr: array[5] of Text[100];
        StartingYear: Integer;
        StartingPage: Integer;
        VATExemptionTypeVend: Integer;
        VATExemptionTypeCust: Integer;
        VATExemptionTypeFilter: Integer;
        StartDate: Date;
        EndDate: Date;
        Text12100: Label 'VAT Exemption %1 of the previous period has not been printed.';
        Text12101: Label 'Starting Date must not be blank.';
        Text12102: Label 'Start Date cannot be greater than End Date.';
        Text12103: Label 'Starting Page must not be blank.';
        Text12104: Label 'Ending Date must not be blank.';
        Text12105: Label 'You can only print report for one type at a time.';
        PageCaptionLbl: Label 'Page %1/%2', Comment = '"%1= Starting year, %2=Current page number"';
        CustVATExemtionRegCaptionLbl: Label 'CUSTOMER VAT EXEMPTION REGISTER';
        PeriodCaptionLbl: Label 'Period :';
        IntRegistryNoCaptionLbl: Label 'Int. Registry No.';
        VATExemptNoCaptionLbl: Label 'VAT Exempt. No.';
        StartingDateCaptionLbl: Label 'Starting Date';
        OfficeCaptionLbl: Label 'Office';
        VATRegCaptionLbl: Label 'VAT Registration';
        NameAddrCaptionLbl: Label 'Name/Address';
        EndingDateCaptionLbl: Label 'Ending Date';
        IntRegistryDateCaptionLbl: Label 'Int. Registry Date';
        VendVATExemtionRegCaptionLbl: Label 'VENDOR VAT EXEMPTION REGISTER';

    [Scope('OnPrem')]
    procedure CalcEndingDate()
    begin
        if StartDate = CalcDate('<-CM>', StartDate) then
            EndDate := CalcDate('<CM>', StartDate);
    end;
}

