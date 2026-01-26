// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 12178 "Vendor Bill Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/VendorBillReport.rdlc';
    Caption = 'Vendor Bill List';
    Permissions = TableData "Vendor Ledger Entry" = rimd;

    dataset
    {
        dataitem("Vendor Bill Header"; "Vendor Bill Header")
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(BillReference; BillReference)
            {
            }
            column(ReportHdr_VendBillHdr; "Report Header")
            {
            }
            column(VendBillLineVendBillNoCaption; "Vendor Bill Line".FieldCaption("Vendor Bill No.") + '   ' + "No.")
            {
            }
            column(CompanyInfoPostCodeCity; CompanyInfo."Post Code" + ' ' + CompanyInfo.City)
            {
            }
            column(CompanyInfoAddr; CompanyInfo.Address)
            {
            }
            column(CompanyInfoName; CompanyInfo.Name)
            {
            }
            column(No_VendBillHdr; "No.")
            {
            }
            column(VendorBillListCaption; VendorBillListCaptionLbl)
            {
            }
            dataitem("Vendor Bill Line"; "Vendor Bill Line")
            {
                DataItemLink = "Vendor Bill List No." = field("No.");
                DataItemTableView = sorting("Vendor No.", "External Document No.", "Document Date") order(ascending);
                column(VendPostCodeCity; VendInfo[3] + ' ' + VendInfo[4])
                {
                }
                column(VendAddr; VendInfo[2])
                {
                }
                column(VendName; VendInfo[1])
                {
                }
                column(VendNo_VendBillLine; "Vendor No.")
                {
                }
                column(VendABICAB; VendABICAB)
                {
                }
                column(GetCurrCode; GetCurrCode())
                {
                }
                column(BeneficiaryValDateFormat_VendBillLine; Format("Beneficiary Value Date"))
                {
                }
                column(VendBillListNo_VendBillLine; "Vendor Bill List No.")
                {
                }
                column(DocNo_VendBillLine; "Document No.")
                {
                }
                column(ExternalDocNo_VendBillLine; "External Document No.")
                {
                }
                column(DocDateFormat_VendBillLine; Format("Document Date"))
                {
                }
                column(AmtToPay_VendBillLine; "Amount to Pay")
                {
                }
                column(DueDateFormat_VendorBillLine; Format("Due Date"))
                {
                }
                column(VendBankAccNo_VendBillLine; "Vendor Bank Acc. No.")
                {
                }
                column(TotalForVendNo; Text001 + FieldCaption("Vendor No.") + ' ' + "Vendor No.")
                {
                }
                column(TotalForVendBillNo; Text001 + FieldCaption("Vendor Bill No.") + ' ' + "Vendor Bill No.")
                {
                }
                column(LineNo_VendBillLine; "Line No.")
                {
                }
                column(ABICABCaption; ABICABCaptionLbl)
                {
                }
                column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                {
                }
                column(BeneficiaryValDateCaption; BeneficiaryValDateCaptionLbl)
                {
                }
                column(VendBillListNoCaption_VendBillLine; FieldCaption("Vendor Bill List No."))
                {
                }
                column(DocNoCaption_VendBillLine; FieldCaption("Document No."))
                {
                }
                column(ExternalDocNoCaption_VendBillLine; FieldCaption("External Document No."))
                {
                }
                column(DocDateCaption; DocDateCaptionLbl)
                {
                }
                column(AmtToPayCaption_VendBillLine; FieldCaption("Amount to Pay"))
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(VendBankAccNoCaption_VendBillLine; FieldCaption("Vendor Bank Acc. No."))
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

                if "List Status" = "List Status"::Open then
                    BillReference := Text000
                else
                    BillReference := "Vendor Bill List No.";
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
        Text000: Label 'TEMPORARY';
        Text001: Label 'Total for ';
        GLSetup: Record "General Ledger Setup";
        Vend: Record Vendor;
        VendBankAcc: Record "Vendor Bank Account";
        CompanyInfo: Record "Company Information";
        VendInfo: array[4] of Text[100];
        VendABICAB: Text[30];
        BillReference: Text[30];
        CurrencyCode: Code[10];
        VendorBillListCaptionLbl: Label 'Vendor Bill List';
        ABICABCaptionLbl: Label 'ABI/CAB';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        BeneficiaryValDateCaptionLbl: Label 'Beneficiary Value Date';
        DocDateCaptionLbl: Label 'Document Date';
        DueDateCaptionLbl: Label 'Due Date';
}

