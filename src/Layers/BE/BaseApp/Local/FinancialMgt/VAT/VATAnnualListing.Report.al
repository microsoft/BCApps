// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11308 "VAT Annual Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/VATAnnualListing.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Annual Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(WrongVATRegNoList; WrongVATRegNoList)
            {
            }
            column(VATAnnualList; VATAnnualList)
            {
            }
            column(AnnualListingoftheTaxLiableBuyersCaption; AnnualListoftheTaxLiableBuyersCaptionLbl)
            {
            }
            column(BufferAmountCaption; BuffAmtCaptionLbl)
            {
            }
            column(BufferBaseCaption; BuffBaseCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(CountryCaption; CountryCaptionLbl)
            {
            }
            column(MinimumCaption; MinimumCaptionLbl)
            {
            }
            column(intYearCaption; intYearCaptionLbl)
            {
            }
            column(WrongEnterpNoListCaption; WrongEnterpNoListCaptionLbl)
            {
            }
            column(BufferVATRegNoCaption; BuffVATRegNoCaptionLbl)
            {
            }
            column(BufferEntryNoCaption; BuffEntryNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Country; Country)
            {
            }
            column(intYear; intYear)
            {
            }
            column(Minimum; Minimum)
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemTableView = sorting("No.");
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(No_Cust; "No.")
                {
                }
                column(Name_Cust; Name)
                {
                }
                column(PhoneNo_Cust; "Phone No.")
                {
                }
                column(EnterpriseNo_Cust; "Enterprise No.")
                {
                }
                column(No_CustCaption; FieldCaption("No."))
                {
                }
                column(Name_CustCaption; FieldCaption(Name))
                {
                }
                column(PhoneNo_CustCaption; FieldCaption("Phone No."))
                {
                }
                column(EnterpriseNo_CustCaption; FieldCaption("Enterprise No."))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if CheckVatNo.MOD97Check("Enterprise No.") then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if not WrongVATRegNoList then
                        CurrReport.Break();

                    if IncludeCountry = IncludeCountry::Specific then
                        SetRange("Country/Region Code", Country);
                    Clear(WTotAmount);
                end;
            }
            dataitem(Customer2; Customer)
            {
                DataItemTableView = sorting("Country/Region Code") where("VAT Liable" = const(true));
                dataitem(VATloop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    dataitem("VAT Entry"; "VAT Entry")
                    {
                        DataItemTableView = sorting("Entry No.");

                        trigger OnAfterGetRecord()
                        var
                            CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
                            TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
                            CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
                            IsCreditMemo: Boolean;
                        begin
                            WBase := WBase + Base;
                            WAmount := WAmount + Amount;
                            IsCreditMemo := (Base > 0);

                            if IsCreditMemoWithAppliedInvoice then
                                CurrReport.Skip();

                            if IsCreditMemo then begin
                                CrMemoCustLedgerEntry.SetRange("Document Type", "Document Type");
                                CrMemoCustLedgerEntry.SetRange("Document No.", "Document No.");
                                CrMemoCustLedgerEntry.SetRange("Posting Date", "Posting Date");
                                CrMemoCustLedgerEntry.SetRange("Customer No.", "Bill-to/Pay-to No.");
                                if CrMemoCustLedgerEntry.FindFirst() then begin
                                    CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempAppliedCustLedgerEntry, CrMemoCustLedgerEntry."Entry No.");
                                    TempAppliedCustLedgerEntry.SetRange("Posting Date", 0D, DMY2Date(31, 12, PreviousYear));
                                    if not TempAppliedCustLedgerEntry.IsEmpty() then
                                        IsCreditMemoWithAppliedInvoice := true;
                                end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetCurrentKey(Type, "Bill-to/Pay-to No.", "Country/Region Code", "EU 3-Party Trade", "VAT Reporting Date");
                            SetRange(Type, Type::Sale);
                            SetRange("Bill-to/Pay-to No.", VATCustomer."No.");
                            SetRange("VAT Reporting Date", DMY2Date(1, 1, intYear), DMY2Date(31, 12, intYear));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if VATCustomer.Next() = 0 then
                            CurrReport.Break();
                        if VATCustomer.Mark() then
                            CurrReport.Skip();
                        if not CheckVatNo.MOD97Check(VATCustomer."Enterprise No.") then
                            CurrReport.Skip();
                        VATCustomer.Mark(true);
                    end;

                    trigger OnPostDataItem()
                    begin
                        if IsCustBalanceGreaterThanMinimum() or IsCreditMemoWithAppliedInvoice then begin
                            No := No + 1;
                            WTotBase := -WBase;
                            WTotAmount := -WAmount;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        VATCustomer."Enterprise No." := '';
                        VATCustomer.SetCurrentKey("Enterprise No.");

                        VatRegNoFilter := '@*';
                        for I := 1 to StrLen(Customer2."Enterprise No.") do
                            if Customer2."Enterprise No."[I] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9'] then
                                VatRegNoFilter := VatRegNoFilter + CopyStr(Customer2."Enterprise No.", I, 1) + '*';
                        VATCustomer.SetFilter("Enterprise No.", VatRegNoFilter);

                        if IncludeCountry = IncludeCountry::Specific then
                            VATCustomer.SetRange("Country/Region Code", Country);
                    end;
                }
                dataitem(Vatloop2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnAfterGetRecord()
                    begin
                        // Filling up buffer for printing in printloop
                        if (IsCustBalanceGreaterThanMinimum() and IsCustVATAmountNotZero()) or IsCreditMemoWithAppliedInvoice then begin
                            Buffer.Reset();
                            Buffer.SetRange("VAT Registration No.", VAT1 + ' ' + VAT2);
                            if Buffer.FindFirst() then begin
                                Buffer.Base += -WBase;
                                Buffer.Amount += -WAmount;
                                Buffer.Modify();
                            end else begin
                                Buffer.Init();
                                Buffer."Entry No." := No;
                                Buffer."VAT Registration No." := VAT1 + ' ' + VAT2;
                                Buffer.Base := -WBase;
                                Buffer.Amount := -WAmount;
                                Buffer.Insert();
                            end;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not CheckVatNo.MOD97Check("Enterprise No.") then
                        CurrReport.Skip();

                    Clear(WBase);
                    Clear(WAmount);
                    Clear(VAT1);
                    Clear(VAT2);
                    IsCreditMemoWithAppliedInvoice := false;
                    VAT1 := 'BE';
                    VAT2 := DelChr("Enterprise No.", '=', DelChr("Enterprise No.", '=', '0123456789'));
                end;

                trigger OnPreDataItem()
                begin
                    if not VATAnnualList then
                        CurrReport.Break();

                    Company.Get();
                    if not CheckVatNo.MOD97Check(Company."Enterprise No.") then
                        Error(Text001);

                    Clear(WTotBase);
                    Clear(WTotAmount);
                    Clear(No);
                    if IncludeCountry = IncludeCountry::Specific then
                        SetRange("Country/Region Code", Country);
                end;
            }
            dataitem(PrintLoop; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(BufferAmount; Buffer.Amount)
                {
                }
                column(BufferBase; Buffer.Base)
                {
                }
                column(BufferVATRegistrationNo; Buffer."VAT Registration No.")
                {
                }
                column(BufferEntryNo; Buffer."Entry No.")
                {
                }
                column(Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Buffer.FindSet()
                    else
                        Buffer.Next();
                end;

                trigger OnPreDataItem()
                begin
                    if not VATAnnualList then
                        CurrReport.Break();

                    Buffer.Reset();
                    SetRange(Number, 1, Buffer.Count);
                end;
            }
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
                    group(Print)
                    {
                        Caption = 'Print';
                        field(WrongEntrNo; WrongVATRegNoList)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Wrong Enterprise No.';
                            ToolTip = 'Specifies if you want to print the report that has erroneous enterprise numbers.';
                        }
                        field(VATAnnualList; VATAnnualList)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Annual Listing';
                            ToolTip = 'Specifies if you want to print the VAT Annual Listing report.';
                        }
                    }
                    field(Year; intYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        NotBlank = true;
                        ToolTip = 'Specifies the year of the period for which you want to print the report. You should enter the year as a 4 digit code. For example, to print a declaration for 2013, you should enter "2013" (instead of "13").';
                    }
                    field(Minimum; Minimum)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        Caption = 'Minimum Amount';
                        ToolTip = 'Specifies the minimum customer''s year balance to be included in the report. If the yearly balance of the customer is smaller than the minimum amount (and there are no negative entries), the customer will not be included in the declaration.';
                    }
                    field(IncludeCountry; IncludeCountry)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Customers From';
                        OptionCaption = 'All Countries/Regions,Specific Country/Region';
                        ToolTip = 'Specifies whether to include customers from all countries/regions or from a specific country/region in the report.';
                    }
                    field(Country; Country)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies the country/region to include in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (not WrongVATRegNoList) and (not VATAnnualList) then begin
                WrongVATRegNoList := true;
                VATAnnualList := true;
            end;

            if intYear = 0 then
                intYear := Date2DMY(WorkDate(), 3);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if intYear < 1900 then
            Error(Text002);
        PreviousYear := intYear - 1;
    end;

    var
        Text001: Label 'Enterprise number in the Company Information table is not valid.';
        Text002: Label 'Year must be at least 1900.';
        Company: Record "Company Information";
        VATCustomer: Record Customer;
        Buffer: Record "VAT Entry" temporary;
        CheckVatNo: Codeunit VATLogicalTests;
        VAT1: Text[30];
        VAT2: Text[30];
        VatRegNoFilter: Text[250];
        No: Integer;
        I: Integer;
        WBase: Decimal;
        WAmount: Decimal;
        WTotBase: Decimal;
        WTotAmount: Decimal;
        WrongEnterpNoListCaptionLbl: Label 'Wrong Enterprise No. - List';
        PageNoCaptionLbl: Label 'Page';
        CountryCaptionLbl: Label 'Country';
        MinimumCaptionLbl: Label 'Minimum Amount';
        intYearCaptionLbl: Label 'Period';
        AnnualListoftheTaxLiableBuyersCaptionLbl: Label 'Annual Listing of the Tax Liable Buyers';
        BuffAmtCaptionLbl: Label 'VAT Amount';
        BuffBaseCaptionLbl: Label 'Sales amount Excl.VAT';
        BuffVATRegNoCaptionLbl: Label 'VAT Number';
        BuffEntryNoCaptionLbl: Label 'Row';
        TotalCaptionLbl: Label 'Total';
        IsCreditMemoWithAppliedInvoice: Boolean;
        PreviousYear: Integer;

    protected var
        WrongVATRegNoList: Boolean;
        VATAnnualList: Boolean;
        intYear: Integer;
        Minimum: Decimal;
        IncludeCountry: Option All,Specific;
        Country: Code[10];

    trigger OnInitReport()
    begin
        IncludeCountry := IncludeCountry::Specific;
    end;

    local procedure IsCustBalanceGreaterThanMinimum(): Boolean
    begin
        exit(-WBase >= Minimum);
    end;

    local procedure IsCustVATAmountNotZero(): Boolean
    begin
        exit(WBase <> 0);
    end;
}

