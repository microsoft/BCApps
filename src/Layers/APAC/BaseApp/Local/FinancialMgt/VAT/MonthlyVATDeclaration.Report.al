// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Utilities;

report 16631 "Monthly VAT Declaration"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/MonthlyVATDeclaration.rdlc';
    Caption = 'Monthly VAT Declaration';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Text004; Text004Lbl)
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(CompanyInfo__Industrial_Classification_; CompanyInfo."Industrial Classification")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfo__Post_Code_; CompanyInfo."Post Code")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo__RDO_Code_; CompanyInfo."RDO Code")
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Telephone_NoCaption; Telephone_NoCaptionLbl)
            {
            }
            column(Zip_CodeCaption; Zip_CodeCaptionLbl)
            {
            }
            column(Line_of_BusinessCaption; Line_of_BusinessCaptionLbl)
            {
            }
            column(TIN_No_Caption; TIN_No_CaptionLbl)
            {
            }
            column(AddressCaption; AddressCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(RDO_CodeCaption; RDO_CodeCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") order(ascending) where(Amount = filter(<> 0));
                RequestFilterFields = "VAT Reporting Date", "Bill-to/Pay-to No.";
                column(VAT_Entry_Type; "VAT Entry".Type)
                {
                }
                column(VAT_Entry_Country; "VAT Entry"."Country/Region Code")
                {
                }
                column(VAT_Entry_VAT_Registration_No; "VAT Entry"."VAT Registration No.")
                {
                }
                column(Amount; -Amount)
                {
                }
                column(Base; -Base)
                {
                }
                column(VAT_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
                {
                }
                column(VAT_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
                {
                }
                column(Amount_Control1410025; -Amount)
                {
                }
                column(Refund; AmtPurchases)
                {
                }
                column(AmtPurchases; AmtPurchases)
                {
                }
                column(AmtPurchases_Control1410028; AmtPurchases)
                {
                }
                column(Base_Control1410031; -Base)
                {
                }
                column(Amount_AmtPurchases; -Amount - AmtPurchases)
                {
                }
                column(VAT_Entry_Entry_No_; "Entry No.")
                {
                }
                column(BaseCaption; BaseCaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(Transaction___Industry_ClassificationCaption; Transaction___Industry_ClassificationCaptionLbl)
                {
                }
                column(ATC_CodeCaption; ATC_CodeCaptionLbl)
                {
                }
                column(Total_Realized_Input_TaxCaption; Total_Realized_Input_TaxCaptionLbl)
                {
                }
                column(Total_Available_Input_TaxCaption; Total_Available_Input_TaxCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(Net_Creditable_Input_TaxCaption; Net_Creditable_Input_TaxCaptionLbl)
                {
                }
                column(Vat_PayableCaption; Vat_PayableCaptionLbl)
                {
                }

                trigger OnPostDataItem()
                begin
                    REPORT.RunModal(28027, false, false, VATEntry);
                    REPORT.RunModal(28028, false, false, "VAT Entry");
                end;

                trigger OnPreDataItem()
                begin
                    VATEntry.CopyFilters("VAT Entry");
                    VATEntry.SetRange(Type, Type::Purchase);
                    VATEntry.SetFilter(Amount, '<>0');
                    if VATEntry.Find('-') then
                        repeat
                            AmtPurchases := AmtPurchases + VATEntry.Amount;
                        until VATEntry.Next() = 0;

                    SetRange(Type, Type::Sale);
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
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

    var
        CompanyInfo: Record "Company Information";
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        AmtPurchases: Decimal;
        VATEntry: Record "VAT Entry";
        Text004Lbl: Label 'Value Added Tax Declaration';
        Telephone_NoCaptionLbl: Label 'Telephone No';
        Zip_CodeCaptionLbl: Label 'Zip Code';
        Line_of_BusinessCaptionLbl: Label 'Line of Business';
        TIN_No_CaptionLbl: Label 'TIN No.';
        AddressCaptionLbl: Label 'Address';
        NameCaptionLbl: Label 'Name';
        RDO_CodeCaptionLbl: Label 'RDO Code';
        BaseCaptionLbl: Label 'Base';
        AmountCaptionLbl: Label 'VAT Amount';
        Transaction___Industry_ClassificationCaptionLbl: Label 'Transaction / Industry Classification';
        ATC_CodeCaptionLbl: Label 'ATC Code';
        Total_Realized_Input_TaxCaptionLbl: Label 'Total Realized Input Tax';
        Total_Available_Input_TaxCaptionLbl: Label 'Total Available Input Tax';
        TotalCaptionLbl: Label 'Total';
        Net_Creditable_Input_TaxCaptionLbl: Label 'Net Creditable Input Tax';
        Vat_PayableCaptionLbl: Label 'Vat Payable';
}

