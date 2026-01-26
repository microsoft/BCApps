// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 12183 "Withholding Tax - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/WithholdingTax/WithholdingTaxTest.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Check data for Certifications';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Withholding_Tax_Code_; "Withholding Tax Code")
            {
            }
            column(Vendor__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(Vendor__Fiscal_Code_; "Fiscal Code")
            {
            }
            column(Vendor__Birth_Date_; Format("Date of Birth"))
            {
            }
            column(Vendor__Birth_City_; "Birth City")
            {
            }
            column(Vendor__Birth_County_; "Birth County")
            {
            }
            column(Vendor__First_Name_; "First Name")
            {
            }
            column(Vendor_Surname; "Last Name")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Verify_Withholding_Tax_DataCaption; Verify_Withholding_Tax_DataCaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(Vendor__Withholding_Tax_Code_Caption; FieldCaption("Withholding Tax Code"))
            {
            }
            column(Vendor__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(Vendor__Fiscal_Code_Caption; FieldCaption("Fiscal Code"))
            {
            }
            column(Vendor__Birth_Date_Caption; Vendor__Birth_Date_CaptionLbl)
            {
            }
            column(Vendor__Birth_City_Caption; FieldCaption("Birth City"))
            {
            }
            column(Vendor__Birth_County_Caption; FieldCaption("Birth County"))
            {
            }
            column(Vendor__First_Name_Caption; FieldCaption("First Name"))
            {
            }
            column(Vendor_SurnameCaption; FieldCaption("Last Name"))
            {
            }
            dataitem(ErrordetailsLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(ErrordetailsLoop_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }

            trigger OnAfterGetRecord()
            var
                GLSetup: Record "General Ledger Setup";
                CompanyInfo: Record "Company Information";
                VATRegNoFormat: Record "VAT Registration No. Format";
                WithholdingTax: Record "Withholding Tax";
                LocalAppMgt: Codeunit LocalApplicationManagement;
                DispError: Boolean;
            begin
                ClearErrors();
                WithholdingTax.Reset();
                WithholdingTax.SetRange("Vendor No.", "No.");
                WithholdingTax.SetRange("Posting Date", StartDate, EndDate);
                if not WithholdingTax.FindFirst() then
                    CurrReport.Skip();
                if "Individual Person" then begin
                    if "Fiscal Code" = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("Fiscal Code")))
                    else begin
                        LocalAppMgt.SkipErrorMsg(true);
                        LocalAppMgt.CheckDigit("Fiscal Code");
                        LocalAppMgt.GetErrorStatus(DispError);
                        if DispError then
                            AddError(
                              StrSubstNo(
                                Text002, FieldCaption("Fiscal Code")));
                    end;
                    if "Date of Birth" = 0D then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("Date of Birth")));
                    if "Birth City" = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("Birth City")));
                    if "Birth County" = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("Birth County")));
                    if "First Name" = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("First Name")));
                    if "Last Name" = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("Last Name")));
                end else
                    if "VAT Registration No." = '' then
                        AddError(
                          StrSubstNo(
                            Text001, FieldCaption("VAT Registration No.")))
                    else begin
                        GLSetup.Get();
                        CompanyInfo.Get();
                        VATRegNoFormat.SkipErrorMsg(true);
                        VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", "No.", DATABASE::Vendor);
                        VATRegNoFormat.GetErrorStatus(DispError);
                        if DispError then
                            AddError(
                              StrSubstNo(
                                Text002, FieldCaption("VAT Registration No.")))
                        else
                            if (("Country/Region Code" = CompanyInfo."Country/Region Code") or
                                ("Country/Region Code" = '')) and
                               GLSetup."Validate loc.VAT Reg. No."
                            then begin
                                LocalAppMgt.SkipErrorMsg(true);
                                LocalAppMgt.CheckDigitVAT("VAT Registration No.");
                                LocalAppMgt.GetErrorStatus(DispError);
                                if DispError then
                                    AddError(
                                      StrSubstNo(
                                        Text003, FieldCaption("VAT Registration No.")));
                            end;
                    end;
                CompressArray(ErrorText);
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
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date.';
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

        trigger OnOpenPage()
        var
            Date2: Record Date;
        begin
            Date2.SetRange("Period Type", Date2."Period Type"::Month);
            Date2.SetFilter("Period Start", '<=%1', WorkDate());
            Date2.SetFilter("Period End", '>=%1', WorkDate());
            if Date2.FindFirst() then begin
                StartDate := Date2."Period Start";
                EndDate := NormalDate(Date2."Period End");
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if Vendor.GetFilter("No.") = '' then
            Error(Text004, Vendor.FieldCaption("No."));
        if StartDate = 0D then
            Error(Text005);
        if EndDate = 0D then
            Error(Text007);
        if StartDate > EndDate then
            Error(Text006);
    end;

    var
        ErrorText: array[10] of Text[250];
        StartDate: Date;
        EndDate: Date;
        Text001: Label '%1 cannot be left blank.';
        Text002: Label '%1 value is not in valid format.';
        Text003: Label '%1 value doesn''t comply to local VAT Rules.';
        ErrorCounter: Integer;
        Text004: Label '%1 filter must be set before running the report.';
        Text005: Label 'Starting Date must not be blank.';
        Text006: Label 'Start Date cannot be greater than End Date.';
        Text007: Label 'Ending Date must not be blank.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Verify_Withholding_Tax_DataCaptionLbl: Label 'Verify Withholding Tax Data';
        Vendor__Birth_Date_CaptionLbl: Label 'Birth Date';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure ClearErrors()
    begin
        Clear(ErrorText);
        ErrorCounter := 0;
    end;
}

