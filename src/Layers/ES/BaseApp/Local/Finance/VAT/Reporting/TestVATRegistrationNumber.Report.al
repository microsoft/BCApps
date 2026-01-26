// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.CRM.Contact;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

report 10742 "Test VAT Registration Number"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/TestVATRegistrationNumber.rdlc';
    Caption = 'Test VAT Registration Number';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FormatToday; Format(Today, 0, 4))
            {
            }
            column(TestVATRegNoCaption; TestVATRegistrationNoCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            dataitem(Customer; Customer)
            {
                column(TableCaption_Customer; TableCaption)
                {
                }
                column(No_Customer; "No.")
                {
                }
                column(Name_Customer; Name)
                {
                }
                column(VATRegNo_Customer; "VAT Registration No.")
                {
                }
                column(ErrorText_Customer; ErrorText)
                {
                }
                column(NoCaption_Customer; FieldCaption("No."))
                {
                }
                column(NameCaption_Customer; FieldCaption(Name))
                {
                }
                column(VATRegNoCaption_Customer; FieldCaption("VAT Registration No."))
                {
                }
                column(ErrorTextCaption_Customer; ErrortextCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ErrorText := '';
                    Check := true;
                    CheckVATRegistrationNo := false;
                    if "VAT Registration No." = '' then begin
                        Check := false;
                        ErrorText := Text1100000;
                    end;

                    if Check = true then begin
                        Check := false;
                        if "Country/Region Code" = '' then
                            VATRegistrationNoFormat.SetRange("Country/Region Code", CountryRegionCode)
                        else
                            VATRegistrationNoFormat.SetRange("Country/Region Code", Customer."Country/Region Code");
                        VATRegistrationNoFormat.SetFilter(Format, '<> %1', '');
                        if VATRegistrationNoFormat.Find('-') then
                            repeat
                                if VATRegistrationNoFormat."Check VAT Registration No." = true then
                                    CheckVATRegistrationNo := true;
                                if VATRegistrationNoFormat.Compare(Customer."VAT Registration No.", VATRegistrationNoFormat.Format) then
                                    Check := true;
                            until VATRegistrationNoFormat.Next() = 0;

                        if Check = false then
                            ErrorText := Text1100001
                        else
                            if CheckVATRegistrationNo = true then begin
                                if VATRegistrationNoFormat.ValidateVATRegNo(Customer."VAT Registration No.", ErrorText) then
                                    CurrReport.Skip();
                            end else
                                CurrReport.Skip();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not CheckCustomers then
                        CurrReport.Break();
                end;
            }
            dataitem(Vendor; Vendor)
            {
                column(TableCaption_Vendor; TableCaption)
                {
                }
                column(No_Vendor; "No.")
                {
                }
                column(Name_Vendor; Name)
                {
                }
                column(VATRegNo_Vendor; "VAT Registration No.")
                {
                }
                column(ErrorText_Vendor; ErrorText)
                {
                }
                column(NoCaption_Vendor; FieldCaption("No."))
                {
                }
                column(NameCaption_Vendor; FieldCaption(Name))
                {
                }
                column(VATRegNoCaption_Vendor; FieldCaption("VAT Registration No."))
                {
                }
                column(ErrorTextCaption_Vendor; ErrortextCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ErrorText := '';
                    Check := true;
                    CheckVATRegistrationNo := false;
                    if "VAT Registration No." = '' then begin
                        Check := false;
                        ErrorText := Text1100000;
                    end;

                    if Check = true then begin
                        Check := false;
                        if "Country/Region Code" = '' then
                            VATRegistrationNoFormat.SetRange("Country/Region Code", CountryRegionCode)
                        else
                            VATRegistrationNoFormat.SetRange("Country/Region Code", Vendor."Country/Region Code");
                        VATRegistrationNoFormat.SetFilter(Format, '<> %1', '');
                        if VATRegistrationNoFormat.Find('-') then
                            repeat
                                if VATRegistrationNoFormat."Check VAT Registration No." = true then
                                    CheckVATRegistrationNo := true;
                                if VATRegistrationNoFormat.Compare(Vendor."VAT Registration No.", VATRegistrationNoFormat.Format) then
                                    Check := true;
                            until VATRegistrationNoFormat.Next() = 0;

                        if Check = false then
                            ErrorText := Text1100001
                        else
                            if CheckVATRegistrationNo = true then begin
                                if VATRegistrationNoFormat.ValidateVATRegNo(Vendor."VAT Registration No.", ErrorText) then
                                    CurrReport.Skip();
                            end else
                                CurrReport.Skip();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not CheckVendors then
                        CurrReport.Break();
                end;
            }
            dataitem(Contact; Contact)
            {
                column(TableCaption_Contact; TableCaption)
                {
                }
                column(No_Contact; "No.")
                {
                }
                column(Name_Contact; Name)
                {
                }
                column(VATRegNo_Contact; "VAT Registration No.")
                {
                }
                column(ErrorText_Contact; ErrorText)
                {
                }
                column(NoCaption_Contact; FieldCaption("No."))
                {
                }
                column(NameCaption_Contact; FieldCaption(Name))
                {
                }
                column(VATRegNoCaption_Contact; FieldCaption("VAT Registration No."))
                {
                }
                column(ErrorTextCaption_Contact; ErrortextCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ErrorText := '';
                    Check := true;
                    CheckVATRegistrationNo := false;
                    if "VAT Registration No." = '' then begin
                        Check := false;
                        ErrorText := Text1100000;
                    end;

                    if Check = true then begin
                        Check := false;
                        if "Country/Region Code" = '' then
                            VATRegistrationNoFormat.SetRange("Country/Region Code", CountryRegionCode)
                        else
                            VATRegistrationNoFormat.SetRange("Country/Region Code", Contact."Country/Region Code");
                        VATRegistrationNoFormat.SetFilter(Format, '<> %1', '');
                        if VATRegistrationNoFormat.Find('-') then
                            repeat
                                if VATRegistrationNoFormat."Check VAT Registration No." = true then
                                    CheckVATRegistrationNo := true;
                                if VATRegistrationNoFormat.Compare(Contact."VAT Registration No.", VATRegistrationNoFormat.Format) then
                                    Check := true;
                            until VATRegistrationNoFormat.Next() = 0;

                        if Check = false then
                            ErrorText := Text1100001
                        else
                            if CheckVATRegistrationNo = true then begin
                                if VATRegistrationNoFormat.ValidateVATRegNo(Contact."VAT Registration No.", ErrorText) then
                                    CurrReport.Skip();
                            end else
                                CurrReport.Skip();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not CheckContacts then
                        CurrReport.Break();
                end;
            }
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
                    field(ShowCustomers; CheckCustomers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Customers';
                        ToolTip = 'Specifies if the VAT registration numbers will be checked for customers.';
                    }
                    field(ShowVendors; CheckVendors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Vendors';
                        ToolTip = 'Specifies if the VAT registration numbers will be checked for vendors.';
                    }
                    field(ShowContacts; CheckContacts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Contacts';
                        ToolTip = 'Specifies if the VAT registration numbers will be checked for contacts.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CheckCustomers := false;
            CheckVendors := false;
            CheckContacts := false;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CountryRegionCode := CompanyInfo."Country/Region Code";
    end;

    var
        Text1100000: Label 'VAT Registration No. is blank.';
        Text1100001: Label 'The number is not in agreement with the format specified for Country/Region Code.';
        CompanyInfo: Record "Company Information";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        ErrorText: Text[120];
        CountryRegionCode: Code[10];
        Check: Boolean;
        CheckCustomers: Boolean;
        CheckVendors: Boolean;
        CheckContacts: Boolean;
        CheckVATRegistrationNo: Boolean;
        TestVATRegistrationNoCaptionLbl: Label 'Test VAT Registration No.';
        PageCaptionLbl: Label 'Page';
        ErrortextCaptionLbl: Label 'Error text';
}

