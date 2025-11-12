// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

report 32 "VAT Registration No. Check"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Registration/VATRegistrationNoCheck.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Batch VAT Registration No. Check';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VAT_Registration_No__CheckCaption; VAT_Registration_No__CheckCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Format_ErrorsCaption; Format_ErrorsCaptionLbl)
                {
                }
                dataitem(Customer; Customer)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    column(Customer__No__; "No.")
                    {
                    }
                    column(Customer_Name; Name)
                    {
                    }
                    column(Customer__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Customer__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(CustomersCaption; CustomersCaptionLbl)
                    {
                    }
                    column(Customer__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Customer_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(Customer__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(Customer__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CheckFormat("VAT Registration No.", "Country/Region Code");
                    end;
                }
                dataitem(Vendor; Vendor)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    column(Vendor__No__; "No.")
                    {
                    }
                    column(Vendor_Name; Name)
                    {
                    }
                    column(Vendor__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Vendor__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(VendorsCaption; VendorsCaptionLbl)
                    {
                    }
                    column(Vendor__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Vendor_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(Vendor__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(Vendor__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CheckFormat("VAT Registration No.", "Country/Region Code");
                    end;
                }
                dataitem(Contact; Contact)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    column(Contact__No__; "No.")
                    {
                    }
                    column(Contact_Name; Name)
                    {
                    }
                    column(Contact__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Contact__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(Contact__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Contact_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(Contact__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(Contact__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                    {
                    }
                    column(ContactsCaption; ContactsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CheckFormat("VAT Registration No.", "Country/Region Code");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not FormatCheck
                    then
                        CurrReport.Break();
                end;
            }
            dataitem(Integer3; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(DuplicatesCaption; DuplicatesCaptionLbl)
                {
                }
                dataitem(Customer2; Customer)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    PrintOnlyIfDetail = true;
                    column(Customer2__No__; "No.")
                    {
                    }
                    column(Customer2_Name; Name)
                    {
                    }
                    column(Customer2__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Customer2__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(VAT_Registration_No_Caption; VAT_Registration_No_CaptionLbl)
                    {
                    }
                    column(Customer2__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(NameCaption; NameCaptionLbl)
                    {
                    }
                    column(No_Caption; No_CaptionLbl)
                    {
                    }
                    column(CustomersCaption_Control50; CustomersCaption_Control50Lbl)
                    {
                    }
                    dataitem(Customer3; Customer)
                    {
                        DataItemLink = "VAT Registration No." = field("VAT Registration No.");
                        DataItemTableView = sorting("VAT Registration No.") where("VAT Registration No." = filter(<> ''));
                        column(Customer3__No__; "No.")
                        {
                        }
                        column(Customer3_Name; Name)
                        {
                        }
                        column(Customer3__Country_Region_Code_; "Country/Region Code")
                        {
                        }
                        column(Customer3__VAT_Registration_No__; "VAT Registration No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Customer2."No." = "No." then
                                CurrReport.Skip();
                            if Customer2."No." > "No." then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(Customer);
                    end;
                }
                dataitem(Vendor2; Vendor)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    PrintOnlyIfDetail = true;
                    column(Vendor2__No__; "No.")
                    {
                    }
                    column(Vendor2_Name; Name)
                    {
                    }
                    column(Vendor2__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Vendor2__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(VendorsCaption_Control51; VendorsCaption_Control51Lbl)
                    {
                    }
                    column(Vendor2__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Vendor2_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(Vendor2__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(Vendor2__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                    {
                    }
                    dataitem(Vendor3; Vendor)
                    {
                        DataItemLink = "VAT Registration No." = field("VAT Registration No.");
                        DataItemTableView = sorting("VAT Registration No.") where("VAT Registration No." = filter(<> ''));
                        column(Vendor3__No__; "No.")
                        {
                        }
                        column(Vendor3_Name; Name)
                        {
                        }
                        column(Vendor3__Country_Region_Code_; "Country/Region Code")
                        {
                        }
                        column(Vendor3__VAT_Registration_No__; "VAT Registration No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Vendor2."No." = "No." then
                                CurrReport.Skip();
                            if Vendor2."No." > "No." then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(Vendor);
                    end;
                }
                dataitem(Contact2; Contact)
                {
                    DataItemTableView = sorting("No.") where("VAT Registration No." = filter(<> ''));
                    PrintOnlyIfDetail = true;
                    column(Contact2__No__; "No.")
                    {
                    }
                    column(Contact2_Name; Name)
                    {
                    }
                    column(Contact2__Country_Region_Code_; "Country/Region Code")
                    {
                    }
                    column(Contact2__VAT_Registration_No__; "VAT Registration No.")
                    {
                    }
                    column(ContactsCaption_Control68; ContactsCaption_Control68Lbl)
                    {
                    }
                    column(Contact2__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Contact2_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(Contact2__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                    {
                    }
                    column(Contact2__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                    {
                    }
                    dataitem(Contact3; Contact)
                    {
                        DataItemLink = "VAT Registration No." = field("VAT Registration No.");
                        DataItemTableView = sorting("VAT Registration No.") where("VAT Registration No." = filter(<> ''));
                        column(Contact3__No__; "No.")
                        {
                        }
                        column(Contact3_Name; Name)
                        {
                        }
                        column(Contact3__Country_Region_Code_; "Country/Region Code")
                        {
                        }
                        column(Contact3__VAT_Registration_No__; "VAT Registration No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Contact2."No." = "No." then
                                CurrReport.Skip();
                            if Contact2."No." > "No." then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(Contact);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not DuplicateCheck then
                        CurrReport.Break();
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About VAT Registration No. Check';
        AboutText = 'The **VAT Registration No. Check** report verifies the validity of VAT numbers for customers and vendors by cross-checking them against the EU VAT Information Exchange System (VIES). Use it for validating VAT registration numbers before submitting EU sales reports to ensure compliance and avoid issues with cross-border transactions.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FormatCheck; FormatCheck)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format Check';
                        ToolTip = 'Specifies that you want to print a list of all customers, vendors, and contacts whose VAT registration numbers do not correspond to the prescribed VAT registration number format for the country/region of origin.';
                    }
                    field(DuplicateCheck; DuplicateCheck)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Duplicate Check';
                        ToolTip = 'Specifies that you want to print all customers, vendors, and contacts whose VAT registration number has been duplicated for more than one customer, vendor, or contact.';
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

    trigger OnInitReport()
    begin
        if not FormatCheck and not DuplicateCheck then begin
            FormatCheck := true;
            DuplicateCheck := true;
        end;
    end;

    var
        FormatCheck: Boolean;
        DuplicateCheck: Boolean;
        VAT_Registration_No__CheckCaptionLbl: Label 'VAT Registration No. Check';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Format_ErrorsCaptionLbl: Label 'Format Errors';
        CustomersCaptionLbl: Label 'Customers';
        VendorsCaptionLbl: Label 'Vendors';
        ContactsCaptionLbl: Label 'Contacts';
        DuplicatesCaptionLbl: Label 'Duplicates';
        VAT_Registration_No_CaptionLbl: Label 'VAT Registration No.';
        NameCaptionLbl: Label 'Name';
        No_CaptionLbl: Label 'No.';
        CustomersCaption_Control50Lbl: Label 'Customers';
        VendorsCaption_Control51Lbl: Label 'Vendors';
        ContactsCaption_Control68Lbl: Label 'Contacts';

    local procedure CheckFormat(VATRegNo: Text[20]; CountryCode: Code[10])
    var
        CompanyInfo: Record "Company Information";
        VATRegNoFormat: Record "VAT Registration No. Format";
        Check: Boolean;
    begin
        if CountryCode = '' then begin
            CompanyInfo.Get();
            VATRegNoFormat.SetRange("Country/Region Code", CompanyInfo."Country/Region Code");
        end else
            VATRegNoFormat.SetRange("Country/Region Code", CountryCode);
        VATRegNoFormat.SetFilter(Format, '<>%1', '');
        if VATRegNoFormat.Find('-') then
            repeat
                if VATRegNoFormat.Compare(VATRegNo, VATRegNoFormat.Format) = true then
                    CurrReport.Skip();
            until Check or (VATRegNoFormat.Next() = 0)
        else
            CurrReport.Skip();
    end;
}

