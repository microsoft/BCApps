// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 12179 "Issued Vendor Bill List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/IssuedVendorBillList.rdlc';
    Caption = 'Issued Vendor Bill List';
    Permissions = TableData "Vendor Ledger Entry" = rimd;

    dataset
    {
        dataitem("Posted Vendor Bill Header"; "Posted Vendor Bill Header")
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyInfoName; CompanyInfo.Name)
            {
            }
            column(VendorBillNoCaptionPostedVendorBillLineNo; "Posted Vendor Bill Line".FieldCaption("Vendor Bill No.") + '   ' + "No.")
            {
            }
            column(CompInfoPostCodeCompInfoCity; CompanyInfo."Post Code" + ' ' + CompanyInfo.City)
            {
            }
            column(CompanyInfoAddress; CompanyInfo.Address)
            {
            }
            column(ReportHdr_PostedVendBillHdr; "Report Header")
            {
            }
            column(No_PostedVendBillHdr; "No.")
            {
            }
            column(CopyCaption; CopyCaptionLbl)
            {
            }
            dataitem("Posted Vendor Bill Line"; "Posted Vendor Bill Line")
            {
                DataItemLink = "Vendor Bill No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "External Document No.", "Document Date") order(ascending);
                column(VendInfo3VendInfo4; VendInfo[3] + ' ' + VendInfo[4])
                {
                }
                column(VendInfo2; VendInfo[2])
                {
                }
                column(VendNo_PostedVendBillLine; "Vendor No.")
                {
                }
                column(VendInfo1; VendInfo[1])
                {
                }
                column(VendBillNo_PostedVendBillLine; "Vendor Bill No.")
                {
                }
                column(DocNo_PostedVendBillLine; "Document No.")
                {
                }
                column(ExternalDocNo_PostedVendBillLine; "External Document No.")
                {
                }
                column(DocDateFormat_PostedVendBillLine; Format("Document Date"))
                {
                }
                column(AmtToPay_PostedVendBillLine; "Amount to Pay")
                {
                }
                column(DueDateFormat_PostedVendBillLine; Format("Due Date"))
                {
                }
                column(VendBankAccNo_PostedVendBillLine; "Vendor Bank Acc. No.")
                {
                }
                column(VendABICAB; VendABICAB)
                {
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                column(BeneficiaryValDateFormat_PostedVendBillLine; Format("Beneficiary Value Date"))
                {
                }
                column(TotalForVendNoCaptionVendNo; StrSubstNo(Text001, "Vendor No."))
                {
                }
                column(TotalForVendBillNoCaptionVendBillNo; StrSubstNo(Text002, "Vendor Bill No."))
                {
                }
                column(VendBillNoCaption_PostedVendBillLine; FieldCaption("Vendor Bill No."))
                {
                }
                column(DocNoCaption_PostedVendBillLine; FieldCaption("Document No."))
                {
                }
                column(ExternalDocNoCaption_PostedVendBillLine; FieldCaption("External Document No."))
                {
                }
                column(AmtToPayCaption_PostedVendBillLine; FieldCaption("Amount to Pay"))
                {
                }
                column(VendBankAccNoCaption_PostedVendBillLine; FieldCaption("Vendor Bank Acc. No."))
                {
                }
                column(VendABICABCaption; VendABICABCaptionLbl)
                {
                }
                column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                {
                }
                column(DocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(BeneficiaryValueDateCaption; BeneficiaryValueDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    VendABICAB := '';

                    if VendBankAcc.Get("Vendor No.", "Vendor Bank Acc. No.") then
                        VendABICAB := VendBankAcc.ABI + '/' + VendBankAcc.CAB;

                    if "Vendor No." <> '' then begin
                        Vend.Get("Vendor No.");
                        VendInfo[1] := Vend.Name;
                        VendInfo[2] := Vend.Address;
                        VendInfo[3] := Vend."Post Code";
                        VendInfo[4] := Vend.City;
                        CompressArray(VendInfo);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Currency Code" = '' then
                    CurrencyCode := GLSetup."LCY Code"
                else
                    CurrencyCode := "Currency Code";
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

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        VendBankAcc: Record "Vendor Bank Account";
        CompanyInfo: Record "Company Information";
        VendInfo: array[4] of Text[100];
        VendABICAB: Text[30];
        CurrencyCode: Code[10];
        Text001: Label 'Total for Vendor No. %1', Comment = '%1 = Vendor No.';
        Text002: Label 'Total for Vendor Bill No. %1', Comment = '%1 = Vendor Bill No.';
        CopyCaptionLbl: Label 'Copy';
        DocumentDateCaptionLbl: Label 'Document Date';
        DueDateCaptionLbl: Label 'Due Date';
        VendABICABCaptionLbl: Label 'ABI/CAB';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        BeneficiaryValueDateCaptionLbl: Label 'Beneficiary Value Date';
}

