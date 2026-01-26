// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10714 "AutoInvoices List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/AutoInvoicesList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'AutoInvoices List';
    UsageCategory = ReportsAndAnalysis;
    UseRequestPage = true;

    dataset
    {
        dataitem(VATEntry; "VAT Entry")
        {
            DataItemTableView = sorting("Document Type", "No. Series", "Posting Date") where(Type = const(Purchase));
            RequestFilterFields = "Posting Date", "Document Type", "Document No.";
            column(CompanyAddr_7_; CompanyAddr[7])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(USERID; UserId)
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(VATEntry_GETFILTERS; GetFilters)
            {
            }
            column(VarNotBaseReverse___VarNotAmountReverse; VarNotBaseReverse + VarNotAmountReverse)
            {
            }
            column(VarNotAmountReverse; VarNotAmountReverse)
            {
            }
            column(VarNotBaseReverse; VarNotBaseReverse)
            {
            }
            column(VATEntry__Document_Type_; "Document Type")
            {
            }
            column(No_SeriesAux_; NoSeriesAux)
            {
            }
            column(No_SeriesAux__Control1100105; NoSeriesAux)
            {
            }
            column(NotBaseReverse; NotBaseReverse)
            {
            }
            column(NotAmountReverse; NotAmountReverse)
            {
            }
            column(NotBaseReverse___NotAmountReverse; NotBaseReverse + NotAmountReverse)
            {
            }
            column(VarNotBaseReverse_Control17; VarNotBaseReverse)
            {
            }
            column(VarNotAmountReverse_Control22; VarNotAmountReverse)
            {
            }
            column(VarNotBaseReverse___VarNotAmountReverse_Control24; VarNotBaseReverse + VarNotAmountReverse)
            {
            }
            column(VATEntry_Entry_No_; "Entry No.")
            {
            }
            column(VATEntry_Type; Type)
            {
            }
            column(VATEntry_Posting_Date; "Posting Date")
            {
            }
            column(VATEntry_Document_No_; "Document No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(AutoInvoices_ListCaption; AutoInvoices_ListCaptionLbl)
            {
            }
            column(VATBuffer2_Base_VATBuffer2_AmountCaption; VATBuffer2_Base_VATBuffer2_AmountCaptionLbl)
            {
            }
            column(VATBuffer2__VAT___Caption; VATBuffer2__VAT___CaptionLbl)
            {
            }
            column(VATBuffer2__EC___Caption; VATBuffer2__EC___CaptionLbl)
            {
            }
            column(VATBuffer2_AmountCaption; VATBuffer2_AmountCaptionLbl)
            {
            }
            column(VATBuffer2_BaseCaption; VATBuffer2_BaseCaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(VATEntry2__Posting_Date_Caption; VATEntry2__Posting_Date_CaptionLbl)
            {
            }
            column(CompanyInfo_NameCaption; CompanyInfo_NameCaptionLbl)
            {
            }
            column(AutoDoc__No_Caption; AutoDoc__No_CaptionLbl)
            {
            }
            column(ContinuedCaption; ContinuedCaptionLbl)
            {
            }
            column(No_SerieCaption; No_SerieCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(No_SerieCaption_Control1100104; No_SerieCaption_Control1100104Lbl)
            {
            }
            column(ContinuedCaption_Control18; ContinuedCaption_Control18Lbl)
            {
            }
            column(NonDeductibleVAT_Caption; NonDeductibleVATCaptionLbl)
            {
            }
            column(NonDeductibleVATBase_Caption; NonDeductibleVATBaseCaptionLbl)
            {
            }
            column(NonDeductibleVATAmt_Caption; NonDeductibleVATAmtCaptionLbl)
            {
            }
            dataitem(VATEntry2; "VAT Entry")
            {
                DataItemLink = Type = field(Type), "Posting Date" = field("Posting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
                DataItemTableView = sorting("No. Series", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    VATBuffer."VAT %" := "VAT %";
                    VATBuffer."EC %" := "EC %";
                    VATBuffer."Non-Deductible VAT %" := "Non-Deductible VAT %";

                    if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                        if not PrintAmountsInAddCurrency then
                            if VATBuffer.Find() then begin
                                VarBase2 := Base;
                                VarAmount2 := Amount;
                                VATBuffer.Base := VATBuffer.Base + Base;
                                VATBuffer.Amount := VATBuffer.Amount + Amount;
                                VATBuffer."Non-Deductible VAT Base" := VATBuffer."Non-Deductible VAT Base" + "Non-Deductible VAT Base";
                                VATBuffer."Non-Deductible VAT Amount" := VATBuffer."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount";
                                VATBuffer.Modify();
                            end else begin
                                VarBase2 := Base;
                                VarAmount2 := Amount;
                                VATBuffer.Base := Base;
                                VATBuffer.Amount := Amount;
                                VATBuffer."Non-Deductible VAT Base" := "Non-Deductible VAT Base";
                                VATBuffer."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount";
                                VATBuffer.Insert();
                            end
                        else
                            if VATBuffer.Find() then begin
                                VATBuffer.Base := VATBuffer.Base + "Additional-Currency Base";
                                VATBuffer.Amount := VATBuffer.Amount + "Additional-Currency Amount";
                                VATBuffer."Non-Deductible VAT Base" := VATBuffer."Non-Deductible VAT Base" + "Non-Deductible VAT Base ACY";
                                VATBuffer."Non-Deductible VAT Amount" := VATBuffer."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount ACY";
                                VATBuffer.Modify();
                            end else begin
                                VATBuffer.Base := "Additional-Currency Base";
                                VATBuffer.Amount := "Additional-Currency Amount";
                                VATBuffer."Non-Deductible VAT Base" := "Non-Deductible VAT Base ACY";
                                VATBuffer."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount ACY";
                                VATBuffer.Insert();
                            end;

                    if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                        if not PrintAmountsInAddCurrency then begin
                            NotBaseReverse := NotBaseReverse + VarBase2;
                            NotAmountReverse := NotAmountReverse + VarAmount2;
                        end else begin
                            NotBaseReverse := NotBaseReverse + VATBuffer.Base;
                            NotAmountReverse := NotAmountReverse + VATBuffer.Amount;
                        end;
                end;

                trigger OnPostDataItem()
                begin
                    VATEntry := VATEntry2;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PurchCrMemoHeader);
                    Clear(PurchInvHeader);
                    Clear(Vendor);

                    VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                    case VATEntry."Document Type" of
                        "Document Type"::"Credit Memo":
                            if PurchCrMemoHeader.Get(VATEntry."Document No.") then begin
                                Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                VendLedgEntry.SetRange("Document No.", VATEntry."Document No.");
                                VendLedgEntry.SetRange("Document Type", "Document Type"::"Credit Memo");
                                if VendLedgEntry.FindFirst() then
                                    AutoDocNo := VendLedgEntry."Autodocument No.";
                                exit;
                            end;
                        "Document Type"::Invoice:
                            if PurchInvHeader.Get(VATEntry."Document No.") then begin
                                Vendor.Name := PurchInvHeader."Pay-to Name";
                                Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                VendLedgEntry.SetRange("Document No.", VATEntry."Document No.");
                                VendLedgEntry.SetRange("Document Type", "Document Type"::Invoice);
                                if VendLedgEntry.FindFirst() then
                                    AutoDocNo := VendLedgEntry."Autodocument No.";
                                exit;
                            end;
                    end;

                    if not Vendor.Get(VATEntry."Bill-to/Pay-to No.") then
                        Vendor.Name := Text1100003;
                    VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                    VendLedgEntry.SetRange("Document No.", VATEntry."Document No.");
                    VendLedgEntry.SetFilter("Document Type", Text1100004);
                    if VendLedgEntry.FindFirst() then;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(VATEntry2__Document_No__; VATEntry2."Document No.")
                {
                }
                column(VATBuffer2_Base; VATBuffer2.Base)
                {
                }
                column(VATBuffer2__VAT___; VATBuffer2."VAT %")
                {
                }
                column(VATBuffer2__VAT___NonDeductibleVAT___; VATBuffer2."Non-Deductible VAT %")
                {
                }
                column(VATEntry2__Posting_Date_; Format(VATEntry2."Posting Date"))
                {
                }
                column(CompanyInfo_Name; CompanyInfo.Name)
                {
                }
                column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                {
                }
                column(VATEntry2__Document_Type_; VATEntry2."Document Type")
                {
                }
                column(VATBuffer2__EC___; VATBuffer2."EC %")
                {
                }
                column(VATBuffer2_Amount; VATBuffer2.Amount)
                {
                }
                column(VATBuffer2_Base_VATBuffer2_Amount; VATBuffer2.Base + VATBuffer2.Amount + VATBuffer2."Non-Deductible VAT Base" + VATBuffer2."Non-Deductible VAT Amount")
                {
                }
                column(AutoDocNo; AutoDocNo)
                {
                }
                column(VATBuffer2_Base_VATBuffer2_Amount_Control53; VATBuffer2.Base + VATBuffer2.Amount + VATBuffer2."Non-Deductible VAT Base" + VATBuffer2."Non-Deductible VAT Amount")
                {
                }
                column(VATBuffer2_Amount_Control58; VATBuffer2.Amount)
                {
                }
                column(VATBuffer2__EC____Control59; VATBuffer2."EC %")
                {
                }
                column(VATBuffer2__VAT____Control60; VATBuffer2."VAT %")
                {
                }
                column(VATBuffer2_Base_Control61; VATBuffer2.Base)
                {
                }
                column(LineNo; LineNo)
                {
                }
                column(VATBuffer2_Base_Control62; VATBuffer2.Base)
                {
                }
                column(VATBuffer2_Amount_Control63; VATBuffer2.Amount)
                {
                }
                column(VATBuffer2_Base_VATBuffer2_Amount_Control64; VATBuffer2.Base + VATBuffer2.Amount + VATBuffer2."Non-Deductible VAT Base" + VATBuffer2."Non-Deductible VAT Amount")
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(TotalCaption_Control26; TotalCaption_Control26Lbl)
                {
                }
                column(VATBuffer2_Non_DeductibleVAT_Control101; VATBuffer2."Non-Deductible VAT %")
                {
                }
                column(VATBuffer2_NonDeductibleVATBase; VATBuffer2."Non-Deductible VAT Base")
                {
                }
                column(VATBuffer2_NonDeductibleVATAmt; VATBuffer2."Non-Deductible VAT Amount")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Fin then
                        CurrReport.Break();
                    VATBuffer2 := VATBuffer;
                    Fin := VATBuffer.Next() = 0;

                    if VATBuffer2.Amount = 0 then begin
                        VATBuffer2."VAT %" := 0;
                        VATBuffer2."EC %" := 0;
                    end;

                    LineNo := LineNo + 1;
                    if LineNo <> 1 then begin
                        VarNotBaseReverse := VarNotBaseReverse + VATBuffer2.Base;
                        VarNotAmountReverse := VarNotAmountReverse + VATBuffer2.Amount;
                    end;

                    if LineNo = 1 then begin
                        VarNotBaseReverse := VarNotBaseReverse + VATBuffer2.Base;
                        VarNotAmountReverse := VarNotAmountReverse + VATBuffer2.Amount;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    LineNo := 0;
                end;

                trigger OnPreDataItem()
                begin
                    VATBuffer.Find('-');
                    Fin := false;
                    LineNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VATBuffer.DeleteAll();
                NoSeriesAuxPrev := NoSeriesAux;
                GLSetUp.Get();
                if "Document Type" = "Document Type"::"Credit Memo" then
                    NoSeriesAux := GLSetUp."Autocredit Memo Nos.";
                if "Document Type" = "Document Type"::Invoice then
                    NoSeriesAux := GLSetUp."Autoinvoice Nos.";
                if NoSeriesAux <> NoSeriesAuxPrev then begin
                    NotBaseReverse := 0;
                    NotAmountReverse := 0;
                    VarNotBaseReverse := 0;
                    VarNotAmountReverse := 0;
                end;

                GLSetUp.Get();
                if PrintAmountsInAddCurrency then
                    HeaderText := StrSubstNo(Text1100002, GLSetUp."Additional Reporting Currency")
                else begin
                    GLSetUp.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1100002, GLSetUp."LCY Code");
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompanyAddr[1] := CompanyInfo.Name;
                CompanyAddr[2] := CompanyInfo."Name 2";
                CompanyAddr[3] := CompanyInfo.Address;
                CompanyAddr[4] := CompanyInfo."Address 2";
                CompanyAddr[5] := CompanyInfo.City;
                CompanyAddr[6] := CompanyInfo."Post Code" + ' ' + CompanyInfo.County;
                if CompanyInfo."VAT Registration No." <> '' then
                    CompanyAddr[7] := Text1100000 + CompanyInfo."VAT Registration No."
                else
                    Error(Text1100001);
                CompressArray(CompanyAddr);
                SetRange("Generated Autodocument", true);
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
                    field(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
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

    var
        Text1100000: Label 'VAT Registration No.: ';
        Text1100001: Label 'Please, specify the VAT registration Nº of your Company in the Company information Window';
        Text1100002: Label 'All Amounts are in %1';
        Text1100003: Label 'UNKNOWN';
        Text1100004: Label 'Invoice|Credit Memo';
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        VATBuffer: Record "Sales/Purch. Book VAT Buffer" temporary;
        GLSetUp: Record "General Ledger Setup";
        VATBuffer2: Record "Sales/Purch. Book VAT Buffer";
        VendLedgEntry: Record "Vendor Ledger Entry";
        HeaderText: Text[50];
        CompanyAddr: array[7] of Text[100];
        LineNo: Decimal;
        Fin: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        AutoDocNo: Code[20];
        NoSeriesAux: Code[20];
        NotBaseReverse: Decimal;
        NotAmountReverse: Decimal;
        NoSeriesAuxPrev: Code[20];
        VarBase2: Decimal;
        VarAmount2: Decimal;
        VarNotBaseReverse: Decimal;
        VarNotAmountReverse: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        AutoInvoices_ListCaptionLbl: Label 'AutoInvoices List';
        VATBuffer2_Base_VATBuffer2_AmountCaptionLbl: Label 'Total';
        VATBuffer2__VAT___CaptionLbl: Label 'VAT %';
        VATBuffer2__EC___CaptionLbl: Label 'EC %';
        VATBuffer2_AmountCaptionLbl: Label 'Amount';
        VATBuffer2_BaseCaptionLbl: Label 'Base';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Registration No.';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        VATEntry2__Posting_Date_CaptionLbl: Label 'Posting Date';
        CompanyInfo_NameCaptionLbl: Label 'Name';
        AutoDoc__No_CaptionLbl: Label 'AutoDoc. No.';
        ContinuedCaptionLbl: Label 'Continued';
        No_SerieCaptionLbl: Label 'No.Serie';
        TotalCaptionLbl: Label 'Total';
        No_SerieCaption_Control1100104Lbl: Label 'No.Serie';
        ContinuedCaption_Control18Lbl: Label 'Continued';
        TotalCaption_Control26Lbl: Label 'Total';
        NonDeductibleVATCaptionLbl: Label 'Non-Ded. VAT%';
        NonDeductibleVATBaseCaptionLbl: Label 'Non-Ded. VAT Base';
        NonDeductibleVATAmtCaptionLbl: Label 'Non-Ded. VAT Amount';
}

