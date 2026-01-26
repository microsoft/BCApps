// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.Customer;

report 28028 "VAT Report - Customer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/VATReportCustomer.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Report - Customer';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "Bill-to/Pay-to No.", "Transaction No.") order(ascending) where(Type = const(Sale), Base = filter(<> 0), Amount = filter(<> 0));
            RequestFilterFields = "Bill-to/Pay-to No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(BaseAmtgoods; BaseAmtgoods)
            {
            }
            column(VATGoods; VATGoods)
            {
            }
            column(TotalBaseAmtgoods; TotalBaseAmtgoods)
            {
            }
            column(TotalVATGoods; TotalVATGoods)
            {
            }
            column(TIN; TIN)
            {
            }
            column(VAT_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(Address; Address)
            {
            }
            column(VAT_Entry__Bill_to_Pay_to_No__; "Bill-to/Pay-to No.")
            {
            }
            column(VATServices; VATServices)
            {
            }
            column(BaseAmtServices; BaseAmtServices)
            {
            }
            column(TotalVATServices; TotalVATServices)
            {
            }
            column(TotalBaseAmtServices; TotalBaseAmtServices)
            {
            }
            column(BaseAmtgoods_Control1500022; BaseAmtgoods)
            {
            }
            column(VATServices_Control1500023; VATServices)
            {
            }
            column(BaseAmtServices_Control1500024; BaseAmtServices)
            {
            }
            column(VATGoods_Control1500025; VATGoods)
            {
            }
            column(VAT_Entry_Entry_No_; "Entry No.")
            {
            }
            column(VAT_Entries___CustomerCaption; VAT_Entries___CustomerCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Bill_to_Customer_No_Caption; Bill_to_Customer_No_CaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Base_GoodsCaption; Base_GoodsCaptionLbl)
            {
            }
            column(VAT___GoodsCaption; VAT___GoodsCaptionLbl)
            {
            }
            column(AddressCaption; AddressCaptionLbl)
            {
            }
            column(TINCaption; TINCaptionLbl)
            {
            }
            column(VAT___ServicesCaption; VAT___ServicesCaptionLbl)
            {
            }
            column(Base___ServicesCaption; Base___ServicesCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Bill-to/Pay-to No." = '' then
                    CurrReport.Skip();

                if TempBillTo <> "Bill-to/Pay-to No." then begin
                    TempBillTo := "Bill-to/Pay-to No.";
                    BaseAmtgoods := 0;
                    VATGoods := 0;
                    BaseAmtServices := 0;
                    VATServices := 0;
                end;

                Cust.Get("Bill-to/Pay-to No.");
                Address := Cust.Address;
                TIN := Cust."VAT Registration No.";
                if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::Invoice] then begin
                    BaseAmtgoods := BaseAmtgoods + Base;
                    TotalBaseAmtgoods += Base;
                    VATGoods := VATGoods + Amount;
                    TotalVATGoods += Amount;
                end else begin
                    BaseAmtServices := BaseAmtServices + Base;
                    TotalBaseAmtServices += Base;
                    VATServices := VATServices + Amount;
                    TotalVATServices += Amount;
                end;
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Bill-to/Pay-to No.");
                Clear(BaseAmtgoods);
                Clear(VATGoods);
                Clear(BaseAmtServices);
                Clear(VATServices);
            end;
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

    trigger OnInitReport()
    begin
        TempBillTo := '';
        BaseAmtgoods := 0;
        VATGoods := 0;
        BaseAmtServices := 0;
        VATServices := 0;
    end;

    var
        LastFieldNo: Integer;
        Address: Text[100];
        TIN: Text[30];
        Cust: Record Customer;
        BaseAmtgoods: Decimal;
        VATGoods: Decimal;
        BaseAmtServices: Decimal;
        VATServices: Decimal;
        TotalBaseAmtgoods: Decimal;
        TotalVATGoods: Decimal;
        TotalBaseAmtServices: Decimal;
        TotalVATServices: Decimal;
        TempBillTo: Code[20];
        VAT_Entries___CustomerCaptionLbl: Label 'VAT Entries - Customer';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bill_to_Customer_No_CaptionLbl: Label 'Bill-to Customer No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Base_GoodsCaptionLbl: Label 'Base-Goods';
        VAT___GoodsCaptionLbl: Label 'VAT - Goods';
        AddressCaptionLbl: Label 'Address';
        TINCaptionLbl: Label 'TIN';
        VAT___ServicesCaptionLbl: Label 'VAT - Services';
        Base___ServicesCaptionLbl: Label 'Base - Services';
}

